#!/usr/bin/env bun
// MCP server over stdio (JSON-RPC 2.0, newline-delimited). Agents configured
// with this server get tools to read the almanac and orchestrate herdr
// workspaces — create, send prompts, read output, wait for state.
import { searchRefs, addRef, jiraKeysFromBranch, type RefKind } from "../src/almanac";
import { herdr, listWorkspaces } from "../src/herdr";

interface JsonRpcRequest {
  jsonrpc: "2.0";
  id?: number | string;
  method: string;
  params?: Record<string, unknown>;
}

interface ToolDef {
  name: string;
  description: string;
  inputSchema: Record<string, unknown>;
}

const TOOLS: ToolDef[] = [
  {
    name: "almanac_search",
    description: "Search linked references (Jira tickets, docs, URLs, people, PRs) across all herdr workspaces.",
    inputSchema: {
      type: "object",
      properties: { query: { type: "string", description: "Substring to match against refs and workspace keys" } },
      required: ["query"],
      additionalProperties: false,
    },
  },
  {
    name: "almanac_attach",
    description: "Attach a reference (jira/url/doc/person/pr) to a workspace key (usually its branch).",
    inputSchema: {
      type: "object",
      properties: {
        key: { type: "string" },
        kind: { type: "string", enum: ["jira", "url", "doc", "person", "pr"] },
        id: { type: "string" },
        title: { type: "string" },
      },
      required: ["key", "kind", "id"],
      additionalProperties: false,
    },
  },
  {
    name: "workstream_list",
    description: "List herdr workspaces with their labels, branches, and focus state.",
    inputSchema: { type: "object", properties: {}, additionalProperties: false },
  },
  {
    name: "workstream_send",
    description: "Send a prompt to the agent running in a workspace (by workspace id like w2, or by label).",
    inputSchema: {
      type: "object",
      properties: {
        workspace: { type: "string", description: "Workspace id (w2) or label" },
        text: { type: "string", description: "Prompt text to submit to the agent" },
      },
      required: ["workspace", "text"],
      additionalProperties: false,
    },
  },
  {
    name: "workstream_read",
    description: "Read recent terminal output of a workspace's focused pane.",
    inputSchema: {
      type: "object",
      properties: {
        workspace: { type: "string" },
        lines: { type: "number", description: "Number of lines from the end (default 50)" },
      },
      required: ["workspace"],
      additionalProperties: false,
    },
  },
  {
    name: "workstream_wait",
    description: "Block until the agent in a workspace reaches a state (idle, working, blocked, done).",
    inputSchema: {
      type: "object",
      properties: {
        workspace: { type: "string" },
        until: { type: "string", enum: ["idle", "working", "blocked", "done"] },
        timeout_ms: { type: "number" },
      },
      required: ["workspace", "until"],
      additionalProperties: false,
    },
  },
];

function ok(id: number | string | undefined, result: unknown): string {
  return JSON.stringify({ jsonrpc: "2.0", id: id ?? null, result });
}

function rpcError(id: number | string | undefined, code: number, message: string): string {
  return JSON.stringify({ jsonrpc: "2.0", id: id ?? null, error: { code, message } });
}

function text(value: unknown): { content: Array<{ type: "text"; text: string }> } {
  return { content: [{ type: "text", text: typeof value === "string" ? value : JSON.stringify(value, null, 2) }] };
}

// Resolve a workspace argument ("w2" or a label) to its id.
async function resolveWorkspaceId(arg: string): Promise<string> {
  if (/^w\d+$/.test(arg)) return arg;
  const ws = await listWorkspaces();
  const hit = ws.find((w) => w.label === arg);
  if (!hit) throw new Error(`no workspace with label ${arg}`);
  return hit.workspace_id;
}

interface AgentRow {
  name: string;
  workspace_id?: string;
}

// `agent list` is global (no --workspace filter); find the first agent whose
// workspace matches.
async function firstAgentIn(workspaceId: string): Promise<string> {
  const res = await herdr<{ agents?: AgentRow[] }>(["agent", "list"]);
  const target = (res.agents ?? []).find((a) => a.workspace_id === workspaceId);
  if (!target) throw new Error(`no agent in workspace ${workspaceId}`);
  return target.name;
}

async function callTool(name: string, args: Record<string, unknown>): Promise<unknown> {
  switch (name) {
    case "almanac_search":
      return text(searchRefs(String(args.query ?? "")));
    case "almanac_attach": {
      addRef(String(args.key), { kind: args.kind as RefKind, id: String(args.id), title: args.title as string | undefined });
      return text("attached");
    }
    case "workstream_list": {
      const ws = await listWorkspaces();
      return text(ws.map((w) => ({ id: w.workspace_id, label: w.label, branch: w.worktree?.branch, focused: w.focused ?? false, tokens: w.tokens ?? {} })));
    }
    case "workstream_send": {
      const id = await resolveWorkspaceId(String(args.workspace));
      const target = await firstAgentIn(id);
      await herdr(["agent", "prompt", target, String(args.text)]);
      return text(`sent to ${target}`);
    }
    case "workstream_read": {
      const id = await resolveWorkspaceId(String(args.workspace));
      const target = await firstAgentIn(id);
      const lines = Number(args.lines ?? 50);
      const res = await herdr<{ output?: string }>(["agent", "read", target, "--lines", String(lines)]);
      return text(res.output ?? "");
    }
    case "workstream_wait": {
      const id = await resolveWorkspaceId(String(args.workspace));
      const target = await firstAgentIn(id);
      const waitArgs = ["agent", "wait", target, "--until", String(args.until)];
      if (args.timeout_ms) waitArgs.push("--timeout", String(args.timeout_ms));
      await herdr(waitArgs);
      return text(`reached ${args.until}`);
    }
    default:
      throw new Error(`unknown tool ${name}`);
  }
}

// stdio loop: newline-delimited JSON-RPC, per the MCP stdio transport.
const decoder = new TextDecoder();
let buffer = "";
const reader = Bun.stdin.stream().getReader();

function write(line: string): void {
  process.stdout.write(line + "\n");
}

for (;;) {
  const { done, value } = await reader.read();
  if (done) break;
  buffer += decoder.decode(value, { stream: true });
  let idx: number;
  while ((idx = buffer.indexOf("\n")) >= 0) {
    const line = buffer.slice(0, idx).trim();
    buffer = buffer.slice(idx + 1);
    if (!line) continue;
    let req: JsonRpcRequest;
    try {
      req = JSON.parse(line) as JsonRpcRequest;
    } catch {
      write(rpcError(undefined, -32700, "parse error"));
      continue;
    }
    try {
      switch (req.method) {
        case "initialize":
          write(ok(req.id, {
            protocolVersion: "2024-11-05",
            capabilities: { tools: {} },
            serverInfo: { name: "herdr-flow", version: "0.1.0" },
          }));
          break;
        case "notifications/initialized":
        case "initialized":
          break; // notification, no response
        case "tools/list":
          write(ok(req.id, { tools: TOOLS }));
          break;
        case "tools/call": {
          const params = (req.params ?? {}) as { name?: string; arguments?: Record<string, unknown> };
          const result = await callTool(String(params.name), params.arguments ?? {});
          write(ok(req.id, result));
          break;
        }
        case "ping":
          write(ok(req.id, {}));
          break;
        default:
          if (req.id !== undefined) write(rpcError(req.id, -32601, `method not found: ${req.method}`));
      }
    } catch (err) {
      write(ok(req.id, { content: [{ type: "text", text: `error: ${(err as Error).message}` }], isError: true }));
    }
  }
}
