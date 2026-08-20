// Workstreams metadata bridge. Herdr's supported OMP integration owns pane
// state. This extension only propagates OMP titles and discovered references.

import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";
import { resolve } from "node:path";

interface OmpContext {
	hasUI?: boolean;
	sessionManager?: {
		getSessionName?(): string | undefined;
		getCwd?(): string;
		getBranch?(): unknown[];
	};
}

function textOf(value: unknown): string {
	if (typeof value === "string") return value;
	if (Array.isArray(value)) return value.map(textOf).join("\n");
	if (!value || typeof value !== "object") return "";
	return [
		"text" in value ? value.text : undefined,
		"content" in value ? value.content : undefined,
		"message" in value ? value.message : undefined,
		"input" in value ? value.input : undefined,
		"details" in value ? value.details : undefined,
	].map(textOf).join("\n");
}

export default function workstreamsMetadata(pi: ExtensionAPI): void {
	let root = false;
	let lastTitle = "";

	const ingest = async (ctx: OmpContext, content: string) => {
		const cwd = ctx.sessionManager?.getCwd?.();
		const title = ctx.sessionManager?.getSessionName?.() || "";
		if (typeof cwd !== "string" || cwd.length === 0) return;
		if (title) lastTitle = title;
		try {
			const binary = resolve(import.meta.dir, "../bin/herdr-workstreams");
			const child = Bun.spawn([binary, "ingest", "--cwd", cwd, "--title", title, "--text", content.slice(0, 32768)], { stdout: "ignore", stderr: "ignore" });
			await child.exited;
		} catch {
			// Outside Herdr, no workspace owns this OMP cwd. Metadata is optional.
		}
	};

	pi.on("session_start", (_event, ctx) => {
		if (ctx.hasUI !== true) return;
		root = true;
		void ingest(ctx, textOf(ctx.sessionManager?.getBranch?.() || []));
	});
	pi.on("session_switch", (_event, ctx) => {
		if (!root || ctx.hasUI !== true) return;
		void ingest(ctx, textOf(ctx.sessionManager?.getBranch?.() || []));
	});
	pi.on("input", (event, ctx) => { if (root) void ingest(ctx, event.text || ""); });
	pi.on("message_end", (event, ctx) => { if (root) void ingest(ctx, textOf(event)); });
	pi.on("tool_result", (event, ctx) => { if (root) void ingest(ctx, `${textOf(event.input)}\n${textOf(event.content)}`); });
	pi.on("turn_end", (_event, ctx) => {
		if (!root) return;
		const title = ctx.sessionManager?.getSessionName?.() || "";
		if (title && title !== lastTitle) void ingest(ctx, "");
	});
}
