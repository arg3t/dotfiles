import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

// Minimum interval between gh API checks for a single pane on the automatic
// (focus/worktree) path. Manual refreshes bypass this.
export const THROTTLE_WINDOW_MS = 30_000;

// Pure: has the throttle window elapsed since the last check?
export function throttleElapsed(lastMs: number, nowMs: number, windowMs: number): boolean {
  return nowMs - lastMs >= windowMs;
}

// Per-pane timestamp files live under the plugin state dir (set by herdr for
// hooks/actions), with a tmpdir fallback for direct CLI runs.
function checkDir(): string {
  const base = process.env.HERDR_PLUGIN_STATE_DIR ?? join(tmpdir(), "herdr-gh-pr");
  return join(base, "last-check");
}

function fileFor(paneId: string): string {
  return join(checkDir(), paneId.replace(/[^A-Za-z0-9._-]/g, "_"));
}

// Epoch ms of the last recorded check for a pane, or 0 if never checked.
export function lastCheckMs(paneId: string): number {
  try {
    return Number(readFileSync(fileFor(paneId), "utf8").trim()) || 0;
  } catch {
    return 0;
  }
}

export function recordCheck(paneId: string, nowMs: number): void {
  try {
    mkdirSync(checkDir(), { recursive: true });
    writeFileSync(fileFor(paneId), String(nowMs));
  } catch {
    // Best effort: if we cannot persist, the pane just re-checks next time.
  }
}
