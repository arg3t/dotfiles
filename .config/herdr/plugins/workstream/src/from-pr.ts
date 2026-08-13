import { $ } from "bun";
import { fastCreate } from "./fast-create";
import { focusedWorkspace, herdr, slugify, workspaceInfo } from "./herdr";

// Create a workstream from a GitHub PR: fuzzy-pick a PR (default: review
// requests to @me), then fast-create a workspace on its head branch.

interface GhPrSummary {
  number: number;
  title: string;
  headRefName: string;
  baseRefName?: string;
  author?: { login?: string };
  repository?: { nameWithOwner?: string };
}

// fzf picker over lines "display\tid". Returns the chosen id, or null when
// the user cancels (fzf exit 130). Runs interactively inside the plugin
// popup pane, so stdio inherits the terminal.
async function pick(lines: string[], prompt: string): Promise<string | null> {
  const proc = Bun.spawn(["fzf", "--prompt", prompt, "--with-nth", "1", "--delimiter", "\t"], {
    stdin: "pipe",
    stdout: "pipe",
    stderr: "inherit",
  });
  proc.stdin.write(lines.join("\n"));
  proc.stdin.end();
  const out = await new Response(proc.stdout).text();
  const code = await proc.exited;
  if (code !== 0 || !out.trim()) return null;
  const id = out.trim().split("\t").pop() ?? "";
  return id || null;
}

async function listPrs(repoRoot: string): Promise<GhPrSummary[]> {
  const out =
    await $`gh search prs --review-requested=@me --state open --json number,title,repository,url --limit 30`
      .cwd(repoRoot)
      .nothrow()
      .quiet()
      .text();
  try {
    const parsed = JSON.parse(out) as Array<GhPrSummary & { repository?: { nameWithOwner?: string } }>;
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

async function prDetail(repoRoot: string, number: number): Promise<GhPrSummary | null> {
  const out = await $`gh pr view ${number} --json number,title,headRefName,baseRefName,author`
    .cwd(repoRoot)
    .nothrow()
    .quiet()
    .text();
  try {
    return JSON.parse(out) as GhPrSummary;
  } catch {
    return null;
  }
}

export async function fromPr(): Promise<void> {
  const focusedRow = await focusedWorkspace();
  if (!focusedRow) throw new Error("no focused workspace");
  const focused = await workspaceInfo(focusedRow.workspace_id);
  const repoRoot = focused.worktree?.repo_root ?? focused.worktree?.checkout_path;
  if (!repoRoot) throw new Error("focused workspace has no repo");

  const prs = await listPrs(repoRoot);
  if (prs.length === 0) {
    console.log("No open PRs requesting your review.");
    return;
  }
  const lines = prs.map(
    (p) => `#${p.number}  ${p.title}${p.repository?.nameWithOwner ? `  (${p.repository.nameWithOwner})` : ""}\t${p.number}`,
  );
  const chosen = await pick(lines, "PR> ");
  if (!chosen) return;

  const detail = await prDetail(repoRoot, Number(chosen));
  if (!detail?.headRefName) throw new Error(`cannot read PR #${chosen}`);

  // Fetch the PR head so the new branch has the right start point.
  await $`git fetch origin ${detail.headRefName}`.cwd(repoRoot).nothrow().quiet();
  const branch = detail.headRefName;
  const label = `#${detail.number} ${slugify(detail.title, 24)}`;
  const result = await fastCreate({ workspaceId: focused.workspace_id, branch, label });

  // Point the new checkout at the PR head, not the default branch.
  if (result.checkoutPath) {
    await $`git reset --hard origin/${detail.headRefName}`.cwd(result.checkoutPath).nothrow().quiet();
  }
  await herdr([
    "workspace", "report-metadata", result.workspaceId,
    "--source", "workstream",
    "--token", `pr=#${detail.number}`,
  ]);
  console.log(`Opened PR #${detail.number} in workspace ${label} (${result.mode} worktree)`);
}
