import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";
import { randomUUID } from "node:crypto";
import { spawn } from "node:child_process";
import { basename, dirname, resolve } from "node:path";

interface CommandContext {
	cwd: string;
	isIdle(): boolean;
	ui: { notify(message: string, type?: "info" | "warning" | "error"): void };
	sessionManager: { getSessionFile(): string | undefined; getSessionName?(): string | undefined };
}

interface HandoffOptions {
	host: string;
	copy: boolean;
	cwd: string;
	session: string;
}

function run(command: string, args: readonly string[]): Promise<string> {
	const completion = Promise.withResolvers<string>();
	const child = spawn(command, [...args], { stdio: ["ignore", "pipe", "pipe"] });
	let stdout = "";
	let stderr = "";
	child.stdout.on("data", chunk => { stdout += String(chunk); });
	child.stderr.on("data", chunk => { stderr += String(chunk); });
	child.on("error", completion.reject);
	child.on("close", code => {
		if (code === 0) completion.resolve(stdout);
		else completion.reject(new Error(`${command} failed: ${[stderr.trim(), stdout.trim()].filter(Boolean).join("\n") || `exit ${code}`}`));
	});
	return completion.promise;
}

function shellQuote(value: string): string {
	const quote = String.fromCharCode(39);
	return `${quote}${value.replace(/'/g, `${quote}"${quote}"${quote}`)}${quote}`;
}

function object(value: unknown): Record<string, unknown> {
	if (!value || typeof value !== "object") throw new Error("handoff-remote: unexpected Herdr response");
	return value;
}

function property(record: Record<string, unknown>, name: string): string {
	const value = record[name];
	if (typeof value !== "string" || value.length === 0) throw new Error(`handoff-remote: Herdr response has no ${name}`);
	return value;
}

async function remote(host: string, command: readonly string[]): Promise<string> {
	const script = `PATH="$HOME/.nix-profile/bin:$HOME/.local/bin:$HOME/bin:$PATH"; export PATH; exec ${command.map(shellQuote).join(" ")}`;
	return run("ssh", [host, script]);
}

function remoteTarget(host: string, path: string): string {
	return `${host}:${shellQuote(path)}`;
}

function remotePath(path: string, home: string): string {
	if (path === "~") return home;
	if (path.startsWith("~/")) return `${home}/${path.slice(2)}`;
	if (!path.startsWith("/")) throw new Error("handoff-remote: --cwd must be an absolute path or start with ~/");
	return path;
}

export function parseHandoffArgs(input: string, cwd: string): HandoffOptions {
	const args = input.trim().split(/\s+/).filter(Boolean);
	const host = args.shift();
	if (!host || !/^[A-Za-z0-9_.@:-]+$/.test(host)) throw new Error("usage: /handoff-remote <ssh-host> [--copy] [--cwd PATH] [--session NAME]");
	const options: HandoffOptions = { host, copy: false, cwd: resolve(cwd), session: "default" };
	while (args.length) {
		const option = args.shift();
		if (option === "--copy") options.copy = true;
		else if (option === "--cwd") {
			const value = args.shift();
			if (!value) throw new Error("handoff-remote: --cwd requires a path");
			options.cwd = value;
		} else if (option === "--session") {
			const value = args.shift();
			if (!value || !/^[A-Za-z0-9_-]+$/.test(value)) throw new Error("handoff-remote: --session requires letters, numbers, _ or -");
			options.session = value;
		} else throw new Error(`handoff-remote: unknown option ${option}`);
	}
	return options;
}

async function handoff(ctx: CommandContext, input: string): Promise<void> {
	if (!ctx.isIdle()) throw new Error("handoff-remote: wait for the current turn to finish");
	const session = ctx.sessionManager.getSessionFile();
	if (!session) throw new Error("handoff-remote: send a message before the handoff so OMP has a session file");
	const options = parseHandoffArgs(input, ctx.cwd);
	let step = `connect to ${options.host}`;
	try {
		ctx.ui.notify(`handoff-remote: ${step}`, "info");
		const home = (await remote(options.host, ["sh", "-lc", "printf %s \"$HOME\""])).trim();
		if (!home.startsWith("/")) throw new Error("the remote home path is invalid");
		const remoteCwd = remotePath(options.cwd, home);
		const remoteSession = `${home}/.omp/agent/sessions/handoffs/${randomUUID()}.jsonl`;

		step = "check remote Herdr and OMP";
		ctx.ui.notify(`handoff-remote: ${step}`, "info");
		await remote(options.host, ["sh", "-lc", "command -v herdr >/dev/null || { echo 'herdr is not on PATH' >&2; exit 127; }; command -v omp >/dev/null || { echo 'omp is not on PATH' >&2; exit 127; }"]);

		if (options.copy) {
			step = `copy ${ctx.cwd} to ${remoteCwd}`;
			ctx.ui.notify(`handoff-remote: ${step}`, "info");
			await remote(options.host, ["mkdir", "-p", "--", remoteCwd]);
			await run("rsync", ["-a", `${resolve(ctx.cwd)}/`, remoteTarget(options.host, `${remoteCwd}/`)]);
		} else {
			step = `check ${remoteCwd}`;
			ctx.ui.notify(`handoff-remote: ${step}`, "info");
			await remote(options.host, ["test", "-d", remoteCwd]);
		}
		step = "prepare the remote session storage";
		ctx.ui.notify(`handoff-remote: ${step}`, "info");
		await remote(options.host, ["mkdir", "-p", "--", dirname(remoteSession)]);
		step = "copy the OMP session";
		ctx.ui.notify(`handoff-remote: ${step}`, "info");
		await run("rsync", ["-a", resolve(session), remoteTarget(options.host, remoteSession)]);

		step = "create the remote Herdr workspace";
		ctx.ui.notify(`handoff-remote: ${step}`, "info");
		const label = ctx.sessionManager.getSessionName?.() || `omp-${basename(remoteCwd)}`;
		const created = object(JSON.parse(await remote(options.host, ["herdr", "--session", options.session, "workspace", "create", "--cwd", remoteCwd, "--label", label, "--no-focus"])));
		const result = object(created.result);
		const pane = property(object(result.root_pane), "pane_id");
		const name = `handoff-${randomUUID().replace(/-/g, "").slice(0, 12)}`;
		step = "start remote OMP";
		ctx.ui.notify(`handoff-remote: ${step}`, "info");
		await remote(options.host, ["herdr", "--session", options.session, "agent", "start", name, "--kind", "omp", "--pane", pane, "--", "--cwd", remoteCwd, "--resume", remoteSession]);
		ctx.ui.notify(`handoff-remote: started ${name} on ${options.host}; attach with herdr --remote ${options.host}${options.session === "default" ? "" : ` --session ${options.session}`}`, "info");
	} catch (error) {
		const message = error instanceof Error ? error.message : String(error);
		ctx.ui.notify(`handoff-remote: ${step} failed: ${message}`, "error");
		throw new Error(`handoff-remote: ${step} failed: ${message}`);
	}
}

export default function handoffRemote(pi: ExtensionAPI): void {
	pi.registerCommand("handoff-remote", {
		description: "Resume this OMP session in Herdr on an SSH host",
		handler: async (args, ctx) => handoff(ctx as CommandContext, args),
	});
}
