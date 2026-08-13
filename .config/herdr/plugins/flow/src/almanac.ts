import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { herdr, workspaceInfo } from "./herdr";

// Almanac: per-workspace linked references — Jira tickets (auto-parsed from
// the branch name), URLs, docs, people, PRs. The list renders as an
// `$almanac` sidebar token and is searchable from agents through the MCP
// server in mcp-server.ts.

export type RefKind = "jira" | "url" | "doc" | "person" | "pr";

export interface AlmanacRef {
  kind: RefKind;
  id: string; // ES-1234, URL, doc slug, email, #42
  title?: string;
}

interface AlmanacStore {
  // keyed by repo branch, falling back to workspace label
  [key: string]: AlmanacRef[];
}

const JIRA_RE = /\b([A-Z][A-Z0-9]+-[0-9]+)\b/g;

function storePath(): string {
  const dir =
    process.env.HERDR_PLUGIN_STATE_DIR ??
    join(process.env.HOME ?? "~", ".local", "state", "herdr", "plugins", "flow");
  mkdirSync(dir, { recursive: true });
  return join(dir, "almanac.json");
}

export function loadStore(): AlmanacStore {
  const path = storePath();
  if (!existsSync(path)) return {};
  try {
    return JSON.parse(readFileSync(path, "utf8")) as AlmanacStore;
  } catch {
    return {};
  }
}

export function saveStore(store: AlmanacStore): void {
  writeFileSync(storePath(), JSON.stringify(store, null, 2));
}

// Jira keys parsed from a branch name — the auto-attach behavior.
export function jiraKeysFromBranch(branch: string | undefined): string[] {
  if (!branch) return [];
  return [...branch.matchAll(JIRA_RE)].map((m) => m[1]);
}

export function addRef(key: string, ref: AlmanacRef): void {
  const store = loadStore();
  const refs = store[key] ?? [];
  if (!refs.some((r) => r.kind === ref.kind && r.id === ref.id)) refs.push(ref);
  store[key] = refs;
  saveStore(store);
}

export function removeRef(key: string, kind: RefKind, id: string): void {
  const store = loadStore();
  store[key] = (store[key] ?? []).filter((r) => !(r.kind === kind && r.id === id));
  saveStore(store);
}

export function searchRefs(query: string): Array<{ key: string; ref: AlmanacRef }> {
  const q = query.toLowerCase();
  const out: Array<{ key: string; ref: AlmanacRef }> = [];
  for (const [key, refs] of Object.entries(loadStore())) {
    for (const ref of refs) {
      if (
        key.toLowerCase().includes(q) ||
        ref.id.toLowerCase().includes(q) ||
        (ref.title ?? "").toLowerCase().includes(q)
      ) {
        out.push({ key, ref });
      }
    }
  }
  return out;
}

// Push the workspace's almanac summary into its sidebar token, auto-attaching
// Jira refs parsed from its branch first.
export async function syncWorkspace(workspaceId: string): Promise<void> {
  const ws = await workspaceInfo(workspaceId);
  const key = ws.worktree?.branch ?? ws.label;
  const store = loadStore();
  const refs = store[key] ?? [];

  for (const jira of jiraKeysFromBranch(ws.worktree?.branch)) {
    if (!refs.some((r) => r.kind === "jira" && r.id === jira)) {
      refs.push({ kind: "jira", id: jira });
    }
  }
  store[key] = refs;
  saveStore(store);

  const value = refs.map((r) => r.id).join(" ");
  if (value) {
    await herdr(["workspace", "report-metadata", workspaceId, "--source", "flow", "--token", `almanac=${value}`]);
  } else {
    await herdr(["workspace", "report-metadata", workspaceId, "--source", "flow", "--clear-token", "almanac"]);
  }
}
