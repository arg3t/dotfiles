import { $ } from "bun";

export const SOURCE = "gh-pr";

// PR icon map. The workspace sidebar token carries the full
// review + CI picture, not just a check rollup.
export type PrState = "OPEN" | "CLOSED" | "MERGED";
export type CiRollup = "pass" | "fail" | "pending" | "none";
export type Review =
  | "approved" // approved, no pending reviewers
  | "approved_pending" // approved but reviewers still pending
  | "changes_requested"
  | "none";

export interface PrInfo {
  number: number;
  state: PrState;
  review: Review;
  url: string;
}

export interface Check {
  bucket: "pass" | "fail" | "pending" | "skipping" | "cancel";
}

export function rollupChecks(checks: Check[]): CiRollup {
  if (checks.length === 0) return "none";
  const buckets = new Set(checks.map((c) => c.bucket));
  if (buckets.has("fail") || buckets.has("cancel")) return "fail";
  if (buckets.has("pending")) return "pending";
  return "pass";
}

// Compose the sidebar token value:
//   merged → ✓ (herdr tokens have no color, so state is glyph-only)
//   closed unmerged → ✗
//   open + changes requested → △
//   open + approved, no pending reviewers → ✓
//   open + approved, pending reviewers → ✓~
//   open + CI pass/fail/pending → ● / ●! / ◐
//   no checks yet → ◌
export function composeIcon(pr: PrInfo, ci: CiRollup): string {
  if (pr.state === "MERGED") return `#${pr.number} ✓`;
  if (pr.state === "CLOSED") return `#${pr.number} ✗`;
  if (pr.review === "changes_requested") return `#${pr.number} △`;
  if (pr.review === "approved") return `#${pr.number} ✓`;
  if (pr.review === "approved_pending") return `#${pr.number} ✓~`;
  switch (ci) {
    case "pass":
      return `#${pr.number} ●`;
    case "fail":
      return `#${pr.number} ●!`;
    case "pending":
      return `#${pr.number} ◐`;
    default:
      return `#${pr.number} ◌`;
  }
}

export interface WorkspaceRow {
  workspace_id: string;
  label: string;
  focused?: boolean;
  worktree?: { checkout_path?: string; branch?: string };
  tokens?: Record<string, string>;
}

interface WorkspaceListResponse {
  result?: { workspaces?: WorkspaceRow[] };
}

interface GhPrView {
  number?: number;
  state?: PrState;
  reviewDecision?: string;
  reviewRequests?: unknown[];
  url?: string;
}

export async function listWorkspaces(): Promise<WorkspaceRow[]> {
  const out = await $`herdr workspace list`.quiet().text();
  const parsed = JSON.parse(out) as WorkspaceListResponse;
  return parsed.result?.workspaces ?? [];
}

export async function currentBranch(cwd: string): Promise<string | null> {
  const branch = await $`git -C ${cwd} branch --show-current`.nothrow().quiet().text();
  const trimmed = branch.trim();
  return trimmed.length > 0 ? trimmed : null;
}

// Single gh call for PR identity + review decision. reviewDecision is
// GitHub's rollup: APPROVED / CHANGES_REQUESTED / REVIEW_REQUIRED / "".
export async function prInfo(cwd: string, branch: string): Promise<PrInfo | null> {
  const out =
    await $`gh pr view ${branch} --json number,state,reviewDecision,reviews,reviewRequests,url`
      .cwd(cwd)
      .nothrow()
      .quiet()
      .text();
  let parsed: GhPrView;
  try {
    parsed = JSON.parse(out) as GhPrView;
  } catch {
    return null;
  }
  if (!parsed.number || !parsed.state || !parsed.url) return null;
  const pendingReviewers = (parsed.reviewRequests ?? []).length > 0;
  let review: Review = "none";
  if (parsed.reviewDecision === "CHANGES_REQUESTED") review = "changes_requested";
  else if (parsed.reviewDecision === "APPROVED")
    review = pendingReviewers ? "approved_pending" : "approved";
  return { number: parsed.number, state: parsed.state, review, url: parsed.url };
}

export async function prChecks(cwd: string, branch: string): Promise<Check[]> {
  // gh pr checks exits non-zero on failing/pending checks; parse regardless.
  const out = await $`gh pr checks ${branch} --json bucket`.cwd(cwd).nothrow().quiet().text();
  try {
    const parsed = JSON.parse(out);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

async function setToken(workspaceId: string, value: string): Promise<void> {
  await $`herdr workspace report-metadata ${workspaceId} --source ${SOURCE} --token pr_status=${value}`
    .nothrow()
    .quiet();
}

async function clearToken(workspaceId: string): Promise<void> {
  await $`herdr workspace report-metadata ${workspaceId} --source ${SOURCE} --clear-token pr_status`
    .nothrow()
    .quiet();
}

// Update one workspace's token from its worktree checkout. Workspaces without
// a worktree or without a PR get their token cleared so stale icons never linger.
export async function updateWorkspace(ws: WorkspaceRow): Promise<void> {
  const cwd = ws.worktree?.checkout_path;
  if (!cwd) return clearToken(ws.workspace_id);
  const branch = ws.worktree?.branch ?? (await currentBranch(cwd));
  if (!branch) return clearToken(ws.workspace_id);
  const pr = await prInfo(cwd, branch);
  if (!pr) return clearToken(ws.workspace_id);
  const checks = await prChecks(cwd, branch);
  await setToken(ws.workspace_id, composeIcon(pr, rollupChecks(checks)));
}

// Refresh every workspace. Called by the event hooks and the manual refresh
// action; each update is independent so one bad repo never blocks the rest.
export async function refreshAll(): Promise<void> {
  const workspaces = await listWorkspaces();
  await Promise.allSettled(workspaces.map(updateWorkspace));
}

// Open the focused workspace's PR in the browser.
export async function openPr(): Promise<void> {
  const workspaces = await listWorkspaces();
  const focused = workspaces.find((w) => w.focused) ?? workspaces[0];
  if (!focused?.worktree?.checkout_path) return;
  const cwd = focused.worktree.checkout_path;
  const branch = focused.worktree.branch ?? (await currentBranch(cwd));
  if (!branch) return;
  await $`gh pr view ${branch} --web`.cwd(cwd).nothrow().quiet();
}
