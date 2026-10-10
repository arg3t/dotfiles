// References travel through the host's plugin data directory, not Tern's KV file.
import { randomUUID } from "node:crypto";
import { promises as fs } from "node:fs";
import { homedir } from "node:os";
import { join, isAbsolute } from "node:path";
import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

interface OmpContext {
	hasUI?: boolean;
	sessionManager?: { getCwd?(): string; getBranch?(): unknown[] };
}

interface Reference {
	kind: "jira" | "pr" | "url";
	id: string;
	url: string;
	discovered: string;
}

const MAX_TEXT = 32768;
const MAX_REFS = 128;
const MAX_FILE_REFS = 16;
const MAX_URL = 2048;
const jiraRE = /\b([A-Z][A-Z0-9]+-[0-9]+)\b/g;
const prRE = /https?:\/\/github\.com\/[^/\s]+\/[^/\s]+\/pull\/([0-9]+)\b/g;
const urlRE = /https?:\/\/[^\s<>()\[\]{}]+/g;
const textFields = ["text", "content", "message", "input", "details"] as const;

function pluginData(): string {
	if (process.env.TERN_CONFIG_DIR) return join(process.env.TERN_CONFIG_DIR, "plugin-data", "workstreams");
	if (process.platform === "darwin") return join(homedir(), "Library", "Application Support", "Tern", "plugin-data", "workstreams");
	return join(process.env.XDG_STATE_HOME || join(homedir(), ".local", "state"), "tern", "plugin-data", "workstreams");
}

// Walk OMP's message shapes without retaining arbitrary user or tool text.
function scan(value: unknown, add: (kind: Reference["kind"], id: string, url: string) => void, remaining: { count: number }, depth = 0): void {
	if (remaining.count === 0 || depth > 8) return;
	if (typeof value === "string") {
		const text = value.slice(0, remaining.count);
		remaining.count -= text.length;
		for (const match of text.matchAll(jiraRE)) add("jira", match[1], "");
		for (const match of text.matchAll(prRE)) add("pr", match[1], match[0]);
		for (const match of text.matchAll(urlRE)) {
			if (match[0].length > MAX_URL) continue;
			try {
				const url = new URL(match[0]);
				if (url.hostname === "github.com" && /^\/[^/]+\/[^/]+\/pull\/[0-9]+\/?$/.test(url.pathname)) continue;
				// Credentials, query strings and fragments can contain bearer secrets.
				url.username = "";
				url.password = "";
				url.search = "";
				url.hash = "";
				const safe = url.toString();
				add("url", safe, safe);
			} catch {
				// Ignore malformed links rather than putting them into the host store.
			}
		}
		return;
	}
	if (Array.isArray(value)) {
		for (const part of value) {
			if (remaining.count === 0) break;
			scan(part, add, remaining, depth + 1);
		}
		return;
	}
	if (value === null || typeof value !== "object") return;
	for (const field of textFields) {
		if (remaining.count === 0) break;
		if (field in value) scan(value[field], add, remaining, depth + 1);
	}
}

export default function ternWorkstreamRefs(pi: ExtensionAPI): void {
	if (!process.env.TERN_PANE) return;
	const inbox = join(pluginData(), "refs-inbox");
	const processId = randomUUID();
	const seen = new Map<string, Set<string>>();
	let total = 0;
	let sequence = 0;
	let root = false;
	let pending = Promise.resolve();

	function ingest(ctx: OmpContext, value: unknown): void {
		if (total >= MAX_REFS) return;
		const cwd = ctx.sessionManager?.getCwd?.();
		if (typeof cwd !== "string" || !isAbsolute(cwd)) return;
		let seenForCwd = seen.get(cwd);
		const batch: Reference[] = [];
		const discovered = new Date().toISOString();
		const add = (kind: Reference["kind"], id: string, url: string) => {
			if (!id || id.length > MAX_URL || url.length > MAX_URL || total >= MAX_REFS) return;
			const key = `${kind}:${id}`;
			if (seenForCwd?.has(key)) return;
			if (!seenForCwd) {
				seenForCwd = new Set();
				seen.set(cwd, seenForCwd);
			}
			seenForCwd.add(key);
			batch.push({ kind, id, url, discovered });
			total++;
		};
		scan(value, add, { count: MAX_TEXT });
		if (batch.length === 0) return;
		// Files never change after publication: the host can unlink a processed file
		// without racing an OMP write to the same name. Small batches bound file size.
		for (let offset = 0; offset < batch.length; offset += MAX_FILE_REFS) {
			const group = batch.slice(offset, offset + MAX_FILE_REFS);
			const destination = join(inbox, `${processId}-${String(++sequence).padStart(6, "0")}.json`);
			pending = pending.then(async () => {
				await fs.mkdir(inbox, { recursive: true, mode: 0o700 });
				const temporary = join(inbox, `.${randomUUID()}.tmp`);
				try {
					await fs.writeFile(temporary, JSON.stringify({ cwd, refs: group }), { mode: 0o600 });
					await fs.rename(temporary, destination);
				} catch (error) {
					await fs.rm(temporary, { force: true });
					throw error;
				}
			}).catch((error) => {
				for (const ref of group) seenForCwd?.delete(`${ref.kind}:${ref.id}`);
				total -= group.length;
				console.error("Tern workstreams: unable to save references", error);
			});
		}
	}

	pi.on("session_start", (_event, ctx) => {
		if (ctx.hasUI !== true) return;
		root = true;
		ingest(ctx, ctx.sessionManager?.getBranch?.() || []);
	});
	pi.on("session_switch", (_event, ctx) => {
		if (root && ctx.hasUI === true) ingest(ctx, ctx.sessionManager?.getBranch?.() || []);
	});
	pi.on("input", (event, ctx) => { if (root) ingest(ctx, event.text || ""); });
	pi.on("message_end", (event, ctx) => { if (root) ingest(ctx, event); });
	pi.on("tool_result", (event, ctx) => {
		if (root) ingest(ctx, [event.input, event.content]);
	});
}

if (import.meta.main) {
	const found = new Map<string, string>();
	scan("PROJ-17 https://github.com/acme/repo/pull/42?token=x https://example.com/a?token=x", (kind, id, url) => {
		found.set(`${kind}:${id}`, url);
	}, { count: MAX_TEXT });
	if (found.size !== 3 || found.get("jira:PROJ-17") !== "" ||
		found.get("pr:42") !== "https://github.com/acme/repo/pull/42" ||
		found.get("url:https://example.com/a") !== "https://example.com/a") {
		throw new Error("Reference scan exposed a token or duplicated a pull request");
	}
}
