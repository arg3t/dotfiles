import { existsSync, mkdirSync, readFileSync, readdirSync, unlinkSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { herdr, listPanes, listTabs, workspaceInfo, type WorkspaceRow } from "./herdr";

// Pause/restore lifecycle (minimize/pause states). Herdr has no
// suspend, so pause records the workspace's layout + worktree in the plugin
// state dir, then closes the workspace — the worktree stays on disk.
// Restore re-opens the worktree, rebuilds tabs, and re-applies metadata
// tokens (pr/jira/phase survive the pause). Agent panes return as shells.

interface PausedPane {
  tab_index: number;
  cwd: string;
}

interface PausedRecord {
  workspace_label: string;
  repo_root?: string;
  checkout_path?: string;
  branch?: string;
  tabs: string[];
  panes: PausedPane[];
  tokens: Record<string, string>;
  paused_at: string;
}

function stateDir(): string {
  const dir =
    process.env.HERDR_PLUGIN_STATE_DIR ??
    join(process.env.HOME ?? "~", ".local", "state", "herdr", "plugins", "workstream");
  mkdirSync(dir, { recursive: true });
  return dir;
}

function recordPath(key: string): string {
  return join(stateDir(), `paused-${key.replace(/[^a-zA-Z0-9_.-]/g, "_")}.json`);
}

export async function pause(workspaceId: string): Promise<void> {
  const ws = await workspaceInfo(workspaceId);
  const tabs = await listTabs(workspaceId);
  const panes = await listPanes(workspaceId);

  const record: PausedRecord = {
    workspace_label: ws.label,
    repo_root: ws.worktree?.repo_root,
    checkout_path: ws.worktree?.checkout_path,
    branch: ws.worktree?.branch,
    tabs: tabs.map((t) => t.label),
    panes: panes.map((p) => ({
      tab_index: Math.max(0, tabs.findIndex((t) => t.tab_id === p.tab_id)),
      cwd: "",
    })),
    tokens: ws.tokens ?? {},
    paused_at: new Date().toISOString(),
  };
  const key = ws.worktree?.branch ?? ws.label;
  writeFileSync(recordPath(key), JSON.stringify(record, null, 2));
  await herdr(["workspace", "close", workspaceId]);
  console.log(`Paused ${ws.label} — worktree kept at ${record.checkout_path ?? "n/a"}.`);
}

export async function listPaused(): Promise<Array<{ key: string; record: PausedRecord }>> {
  const dir = stateDir();
  return readdirSync(dir)
    .filter((f) => f.startsWith("paused-") && f.endsWith(".json"))
    .map((f) => ({
      key: f.slice("paused-".length, -".json".length),
      record: JSON.parse(readFileSync(join(dir, f), "utf8")) as PausedRecord,
    }))
    .sort((a, b) => b.record.paused_at.localeCompare(a.record.paused_at));
}

export async function restore(key: string): Promise<void> {
  const path = recordPath(key);
  if (!existsSync(path)) throw new Error(`no paused workspace recorded as ${key}`);
  const record = JSON.parse(readFileSync(path, "utf8")) as PausedRecord;
  if (!record.repo_root || !record.checkout_path) throw new Error("record has no worktree");
  if (!existsSync(record.checkout_path)) {
    throw new Error(`worktree ${record.checkout_path} is gone — cannot restore`);
  }

  const res = await herdr<{ workspace: WorkspaceRow }>([
    "worktree", "open",
    "--cwd", record.repo_root,
    "--path", record.checkout_path,
    "--label", record.workspace_label,
    "--focus",
  ]);
  const wsId = res.workspace.workspace_id;

  // Recreate extra tabs beyond the default first one.
  for (let i = 1; i < record.tabs.length; i++) {
    await herdr(["tab", "create", "--workspace", wsId, "--label", record.tabs[i]]);
  }

  // Re-apply metadata tokens (pr/jira/phase survive the pause).
  for (const [name, value] of Object.entries(record.tokens)) {
    await herdr(["workspace", "report-metadata", wsId, "--source", "workstream", "--token", `${name}=${value}`]);
  }

  unlinkSync(path);
  console.log(`Restored ${record.workspace_label} (${record.tabs.length} tab(s))`);
}
