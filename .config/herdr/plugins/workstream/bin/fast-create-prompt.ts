#!/usr/bin/env bun
// Interactive fast-create: prompt for a branch name, then create the
// worktree. Runs inside the popup pane (has a TTY).
import { fastCreate } from "../src/fast-create";
import { focusedWorkspace } from "../src/herdr";

process.stdout.write("Branch name: ");
const reader = Bun.stdin.stream().getReader();
const chunks: Uint8Array[] = [];
for (;;) {
  const { done, value } = await reader.read();
  if (done) break;
  chunks.push(value);
  if (value.includes(0x0a)) break;
}
const branch = Buffer.concat(chunks).toString("utf8").split("\n")[0].trim();

if (!branch) {
  console.error("no branch given");
  process.exit(1);
}

const focused = await focusedWorkspace();
if (!focused) {
  console.error("no focused workspace");
  process.exit(1);
}

try {
  const result = await fastCreate({ workspaceId: focused.workspace_id, branch });
  console.log(`Created ${branch} (${result.mode} worktree)`);
} catch (err) {
  console.error(`[workstream] ${(err as Error).message}`);
  process.exit(1);
}
