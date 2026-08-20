import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";
import { randomUUID } from "node:crypto";
import { spawn } from "node:child_process";
import { connect } from "node:net";
import { resolve } from "node:path";

interface CommandContext {
	cwd: string;
	isIdle(): boolean;
	ui: { notify(message: string, type?: "info" | "warning" | "error"): void };
	sessionManager: { getSessionFile(): string | undefined };
}

interface Tab { id: string; label: string; workspaceID: string }
interface Agent { paneID: string; sessionPath?: string }

function run(command: string, args: readonly string[]): Promise<string> {
	const completion = Promise.withResolvers<string>();
	const child = spawn(command, [...args], { stdio: ["ignore", "pipe", "pipe"] });
	let stdout = "";
	let stderr = "";
	child.stdout.on("data", chunk => { stdout += String(chunk); });
	child.stderr.on("data", chunk => { stderr += String(chunk); });
	child.on("error", completion.reject);
	child.on("close", code => code === 0 ? completion.resolve(stdout) : completion.reject(new Error(`${command} ${args[0] ?? ""} failed: ${stderr.trim()}`)));
	return completion.promise;
}

function object(value: unknown): Record<string, unknown> {
	if (!value || typeof value !== "object") throw new Error("fork-in: unexpected Herdr response");
	return value;
}

async function herdr(args: readonly string[]): Promise<Record<string, unknown>> {
	const parsed: unknown = JSON.parse(await run("herdr", args));
	const envelope = object(parsed);
	if ("error" in envelope && envelope.error) throw new Error(`fork-in: ${String(envelope.error)}`);
	return object(envelope.result);
}

function property(record: Record<string, unknown>, name: string): string {
	const value = record[name];
	if (typeof value !== "string" || value.length === 0) throw new Error(`fork-in: Herdr response has no ${name}`);
	return value;
}

async function moveTab(tabID: string, insertIndex: number): Promise<void> {
	const socketPath = process.env.HERDR_SOCKET_PATH;
	if (!socketPath) throw new Error("fork-in-herdr: HERDR_SOCKET_PATH is unset");
	const completion = Promise.withResolvers<void>();
	const socket = connect(socketPath);
	let buffer = "";
	socket.on("connect", () => socket.write(`${JSON.stringify({ id: `fork-in:${randomUUID()}`, method: "tab.move", params: { tab_id: tabID, insert_index: insertIndex } })}\n`));
	socket.on("data", chunk => { buffer += String(chunk); if (!buffer.includes("\n")) return; socket.end(); completion.resolve(); });
	socket.on("error", completion.reject);
	await completion.promise;
}

function forkLabel(label: string, labels: readonly string[]): string {
	for (let number = 1; ; number += 1) {
		const candidate = `${label}f${number}`;
		if (!labels.includes(candidate)) return candidate;
	}
}

function ompOverlays(): string[] {
	const valueFlags: Record<string, true> = { "--profile": true, "--config": true, "--session-dir": true };
	const overlays: string[] = [];
	for (let index = 2; index < process.argv.length; index += 1) {
		const arg = process.argv[index] ?? "";
		const flag = arg.split("=", 1)[0] ?? arg;
		if (valueFlags[flag] !== true) continue;
		overlays.push(arg);
		if (!arg.includes("=") && process.argv[index + 1]) overlays.push(process.argv[++index] ?? "");
	}
	return overlays;
}

async function forkInHerdr(ctx: CommandContext): Promise<void> {
	if (!ctx.isIdle()) throw new Error("fork-in-herdr: wait for the current turn to finish");
	const session = ctx.sessionManager.getSessionFile();
	if (!session) throw new Error("fork-in-herdr: send a message before forking so OMP has a session file");
	const workspaceID = process.env.HERDR_WORKSPACE_ID;
	const tabID = process.env.HERDR_TAB_ID;
	if (!process.env.HERDR_ENV || !workspaceID || !tabID) throw new Error("fork-in-herdr: not running inside Herdr");
	const current = object((await herdr(["tab", "get", tabID])).tab);
	const tabsResult = await herdr(["tab", "list", "--workspace", workspaceID]);
	const tabRows = Array.isArray(tabsResult.tabs) ? tabsResult.tabs.map(object) : [];
	const label = forkLabel(property(current, "label"), tabRows.map(tab => property(tab, "label")));
	const created = await herdr(["tab", "create", "--workspace", workspaceID, "--cwd", ctx.cwd, "--label", label, "--no-focus"]);
	const rootPane = object(created.root_pane);
	const newTabID = property(rootPane, "tab_id");
	const paneID = property(rootPane, "pane_id");
	const sourceIndex = tabRows.findIndex(tab => property(tab, "tab_id") === tabID);
	if (sourceIndex >= 0) await moveTab(newTabID, sourceIndex + 1);
	const started = await herdr(["agent", "start", `fork-${workspaceID}-${label}`.replace(/[^a-z0-9_-]/gi, "").slice(0, 32), "--kind", "omp", "--pane", paneID, "--", ...ompOverlays(), "--fork", resolve(session)]);
	const agent = object(started.agent);
	const agentSession = "agent_session" in agent && agent.agent_session && typeof agent.agent_session === "object" ? agent.agent_session : undefined;
	const path = agentSession && "value" in agentSession && typeof agentSession.value === "string" ? agentSession.value : undefined;
	if (!path || path === resolve(session)) throw new Error("fork-in-herdr: Herdr did not start a matching child session");
	ctx.ui.notify(`fork-in-herdr: forked to ${label}`, "info");
}

async function forkInTmux(ctx: CommandContext): Promise<void> {
	if (!ctx.isIdle()) throw new Error("fork-in-tmux: wait for the current turn to finish");
	const session = ctx.sessionManager.getSessionFile();
	if (!session) throw new Error("fork-in-tmux: send a message before forking so OMP has a session file");
	const pane = process.env.TMUX_PANE;
	if (!process.env.TMUX || !pane) throw new Error("fork-in-tmux: not running inside tmux");
	const source = (await run("tmux", ["display-message", "-p", "-t", pane, "-F", "#{session_id} #{window_id} #{window_name}"])).trim().split(" ");
	if (source.length !== 3 || !source[0] || !source[1] || !source[2]) throw new Error("fork-in-tmux: could not resolve source window");
	const labels = (await run("tmux", ["list-windows", "-t", source[0], "-F", "#{window_name}"])).trim().split("\n");
	const label = forkLabel(source[2], labels);
	await run("tmux", ["new-window", "-d", "-a", "-t", `${source[0]}:${source[1]}`, "-c", ctx.cwd, "-n", label, "omp", ...ompOverlays(), "--fork", resolve(session)]);
	ctx.ui.notify(`fork-in-tmux: forked to ${label}`, "info");
}

export default function forkIn(pi: ExtensionAPI): void {
	pi.registerCommand("fork-in-herdr", { description: "Fork this OMP session into an adjacent Herdr tab", handler: async (args, ctx) => { if (args.trim()) throw new Error("fork-in-herdr takes no arguments"); await forkInHerdr(ctx); } });
	pi.registerCommand("fork-in-tmux", { description: "Fork this OMP session into an adjacent tmux window", handler: async (args, ctx) => { if (args.trim()) throw new Error("fork-in-tmux takes no arguments"); await forkInTmux(ctx); } });
}
