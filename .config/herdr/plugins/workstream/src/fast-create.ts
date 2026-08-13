import { $ } from "bun";
import { existsSync } from "node:fs";
import { join } from "node:path";
import { herdr, workspaceInfo, slugify, type WorkspaceRow } from "./herdr";

// Fast worktree creation via git-ns copy-on-write overlays, then adoption by
// herdr. Overlays come up in ~1s vs plain `git worktree add`, which re-checks
// out the full tree. The base layer is created once per repo at
// `<worktrees-dir>/.base-<repo>` and reused for every branch.

export interface FastCreateOptions {
  workspaceId: string;
  branch: string;
  worktreesDir?: string;
  label?: string;
}

export interface CreateResult {
  workspaceId: string;
  checkoutPath: string;
  branch: string;
  mode: "overlay" | "git";
}

function defaultWorktreesDir(): string {
  return process.env.HERDR_WORKTREES_DIR ?? join(process.env.HOME ?? "~", ".herdr", "worktrees");
}

// True when git-ns overlays are usable on this machine. `git ns worktree
// check` exits 0 when fuse-overlayfs is present (it self-downloads on Linux).
async function overlaysAvailable(): Promise<boolean> {
  const probe = await $`git ns worktree check`.nothrow().quiet();
  return probe.exitCode === 0;
}

async function ensureBaseLayer(repoRoot: string, basePath: string): Promise<void> {
  if (existsSync(basePath)) return;
  const res = await $`git ns worktree setup ${basePath}`.cwd(repoRoot).nothrow().quiet();
  if (res.exitCode !== 0) {
    throw new Error(`git ns worktree setup failed: ${res.stderr.toString().trim()}`);
  }
}

// Create an overlay checkout for `branch` under worktreesDir and register it
// in git so herdr (and plain git tooling) sees a normal branch checkout.
async function createOverlayCheckout(
  repoRoot: string,
  repoName: string,
  branch: string,
  worktreesDir: string,
): Promise<string> {
  const basePath = join(worktreesDir, `.base-${repoName}`);
  await ensureBaseLayer(repoRoot, basePath);
  const checkoutPath = join(worktreesDir, repoName, slugify(branch, 60));
  const created = await $`git ns worktree create --base ${basePath} ${checkoutPath}`
    .cwd(repoRoot)
    .nothrow()
    .quiet();
  if (created.exitCode !== 0) {
    throw new Error(`git ns worktree create failed: ${created.stderr.toString().trim()}`);
  }
  // Overlay checkouts start detached; materialize the branch in place so
  // commits land on it and the gh-pr plugin picks it up.
  const checkout = await $`git checkout -b ${branch}`.cwd(checkoutPath).nothrow().quiet();
  if (checkout.exitCode !== 0) {
    // Branch may already exist (e.g. re-running fast-create) — attach to it.
    const attach = await $`git checkout ${branch}`.cwd(checkoutPath).nothrow().quiet();
    if (attach.exitCode !== 0) {
      throw new Error(`cannot create or attach branch ${branch}: ${attach.stderr.toString().trim()}`);
    }
  }
  return checkoutPath;
}

// Hand the new checkout to herdr. `worktree open` adopts any registered git
// worktree path; verified against overlay checkouts (they register in
// `git worktree list` like normal ones).
async function adoptIntoHerdr(
  repoRoot: string,
  checkoutPath: string,
  branch: string,
  label?: string,
): Promise<string> {
  const args = ["worktree", "open", "--cwd", repoRoot, "--path", checkoutPath, "--focus"];
  if (label) args.push("--label", label);
  const res = await herdr<{ workspace: WorkspaceRow }>(args);
  return res.workspace.workspace_id;
}

// Entry point for the fast-create action. Falls back to herdr's native
// (slower) `worktree create` when overlays are unavailable so the action
// never hard-fails on machines without fuse-overlayfs.
export async function fastCreate(opts: FastCreateOptions): Promise<CreateResult> {
  // workspaceInfo = `workspace get`, which (unlike list) includes worktree info.
  const ws = await workspaceInfo(opts.workspaceId);
  const repoRoot = ws.worktree?.repo_root ?? ws.worktree?.checkout_path;
  const repoName = ws.worktree?.repo_name ?? "repo";
  if (!repoRoot) throw new Error(`workspace ${opts.workspaceId} has no repo worktree`);
  const worktreesDir = opts.worktreesDir ?? defaultWorktreesDir();

  if (await overlaysAvailable()) {
    const checkoutPath = await createOverlayCheckout(repoRoot, repoName, opts.branch, worktreesDir);
    const workspaceId = await adoptIntoHerdr(repoRoot, checkoutPath, opts.branch, opts.label);
    return { workspaceId, checkoutPath, branch: opts.branch, mode: "overlay" };
  }

  const args = ["worktree", "create", "--cwd", repoRoot, "--branch", opts.branch, "--focus"];
  if (opts.label) args.push("--label", opts.label);
  const res = await herdr<{ workspace: WorkspaceRow }>(args);
  const checkoutPath = (await workspaceInfo(res.workspace.workspace_id)).worktree?.checkout_path ?? "";
  return { workspaceId: res.workspace.workspace_id, checkoutPath, branch: opts.branch, mode: "git" };
}
