import { herdr, focusedWorkspace, workspaceInfo } from "./herdr";

// Workflow phases. Stored as a workspace metadata
// token so it renders in the sidebar via `$phase` and survives pause/restore
// (the workstream plugin re-applies tokens on restore).

export interface Phase {
  id: string;
  name: string;
  icon: string;
}

export const PHASES: readonly Phase[] = [
  { id: "drafting", name: "Drafting", icon: "·" },
  { id: "building", name: "Building", icon: "▸" },
  { id: "in_review", name: "In Review", icon: "◇" },
  { id: "shipped", name: "Shipped", icon: "↥" },
  { id: "verifying", name: "Verifying", icon: "✓" },
  { id: "blocked", name: "Blocked", icon: "!" },
];

export function phaseTokenValue(phaseId: string): string {
  const phase = PHASES.find((p) => p.id === phaseId);
  return phase ? `${phase.icon} ${phase.name}` : phaseId;
}

// Current phase id for a workspace, reverse-parsed from its token.
export function currentPhaseId(tokens: Record<string, string> | undefined): string | null {
  const value = tokens?.phase;
  if (!value) return null;
  const phase = PHASES.find((p) => value === `${p.icon} ${p.name}`);
  return phase?.id ?? null;
}

export async function setPhase(workspaceId: string, phaseId: string): Promise<void> {
  if (!PHASES.some((p) => p.id === phaseId)) {
    throw new Error(`unknown phase ${phaseId} — pick from ${PHASES.map((p) => p.id).join(", ")}`);
  }
  await herdr([
    "workspace", "report-metadata", workspaceId,
    "--source", "flow",
    "--token", `phase=${phaseTokenValue(phaseId)}`,
  ]);
}

export async function clearPhase(workspaceId: string): Promise<void> {
  await herdr(["workspace", "report-metadata", workspaceId, "--source", "flow", "--clear-token", "phase"]);
}

// Advance to the next phase in the pipeline (blocked is a side state, not in
// the rotation). Used by a keybind for quick flips without the picker.
export async function cyclePhase(workspaceId: string): Promise<void> {
  const ws = await workspaceInfo(workspaceId);
  const current = currentPhaseId(ws.tokens);
  const pipeline = PHASES.filter((p) => p.id !== "blocked");
  const idx = pipeline.findIndex((p) => p.id === current);
  const next = pipeline[(idx + 1) % pipeline.length];
  await setPhase(workspaceId, next.id);
  console.log(`${ws.label}: ${next.icon} ${next.name}`);
}

// Interactive picker path for the popup pane.
export async function pickPhase(): Promise<void> {
  const focused = await focusedWorkspace();
  if (!focused) throw new Error("no focused workspace");
  const lines = PHASES.map((p) => `${p.icon} ${p.name}\t${p.id}`);
  const proc = Bun.spawn(["fzf", "--prompt", "phase> ", "--with-nth", "1", "--delimiter", "\t"], {
    stdin: "pipe",
    stdout: "pipe",
    stderr: "inherit",
  });
  proc.stdin.write(lines.join("\n"));
  proc.stdin.end();
  const out = await new Response(proc.stdout).text();
  if ((await proc.exited) !== 0 || !out.trim()) return;
  const id = out.trim().split("\t").pop() ?? "";
  if (id) {
    await setPhase(focused.workspace_id, id);
    console.log(`phase → ${id}`);
  }
}
