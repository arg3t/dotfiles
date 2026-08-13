import { $ } from "bun";

// Shared herdr CLI helpers + typed response shapes for the workstream plugin.

export interface WorktreeInfo {
  checkout_path?: string;
  repo_root?: string;
  repo_name?: string;
  branch?: string;
}

export interface WorkspaceRow {
  workspace_id: string;
  label: string;
  focused?: boolean;
  worktree?: WorktreeInfo;
  tokens?: Record<string, string>;
}

export interface TabRow {
  tab_id: string;
  workspace_id: string;
  label: string;
}

export interface PaneRow {
  pane_id: string;
  tab_id: string;
  workspace_id: string;
  agent_status?: string;
}

interface Envelope<T> {
  result?: T;
  error?: { code?: string; message?: string };
}

// Run a herdr CLI command and unwrap the JSON envelope. Throws with the
// server's error message on failure so callers get actionable text.
export async function herdr<T>(args: string[]): Promise<T> {
  const out = await $`herdr ${args}`.nothrow().quiet();
  const text = out.stdout.toString().trim();
  let parsed: Envelope<T>;
  try {
    parsed = JSON.parse(text) as Envelope<T>;
  } catch {
    throw new Error(`herdr ${args.join(" ")}: non-JSON output (exit ${out.exitCode}): ${text.slice(0, 200)}`);
  }
  if (parsed.error || out.exitCode !== 0) {
    throw new Error(`herdr ${args.join(" ")}: ${parsed.error?.message ?? `exit ${out.exitCode}`}`);
  }
  return parsed.result as T;
}

export async function listWorkspaces(): Promise<WorkspaceRow[]> {
  const res = await herdr<{ workspaces?: WorkspaceRow[] }>(["workspace", "list"]);
  return res.workspaces ?? [];
}

export async function workspaceInfo(id: string): Promise<WorkspaceRow> {
  const res = await herdr<{ workspace: WorkspaceRow }>(["workspace", "get", id]);
  return res.workspace;
}

export async function listTabs(workspaceId: string): Promise<TabRow[]> {
  const res = await herdr<{ tabs?: TabRow[] }>(["tab", "list", "--workspace", workspaceId]);
  return res.tabs ?? [];
}

export async function listPanes(workspaceId: string): Promise<PaneRow[]> {
  const res = await herdr<{ panes?: PaneRow[] }>(["pane", "list", "--workspace", workspaceId]);
  return res.panes ?? [];
}

// The focused workspace, or null when nothing has focus (e.g. called from a
// detached event hook).
export async function focusedWorkspace(): Promise<WorkspaceRow | null> {
  const list = await listWorkspaces();
  return list.find((w) => w.focused) ?? null;
}

// `workspace list` omits worktree info; `workspace get` includes it. Resolve
// a workspace row that is guaranteed to carry .worktree when one exists.
export async function workspaceWithWorktree(id: string): Promise<WorkspaceRow> {
  return workspaceInfo(id);
}

// Branch slugs: lowercase, dashes, no leading/trailing dash. Matches
// Branch slugs keep ticket prefixes readable (ES-1234-fix-login).
export function slugify(text: string, maxLen = 40): string {
  const slug = text
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, maxLen)
    .replace(/-+$/g, "");
  return slug || "work";
}
