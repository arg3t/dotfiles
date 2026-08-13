import { focusedWorkspace, herdr, slugify } from "./herdr";
import { fastCreate } from "./fast-create";

// Create a workstream from a Jira ticket. Two modes:
//   - `from-jira ES-1234` (arg): no network needed, branch = ES-1234
//   - interactive (no arg): prompts for a ticket key inside the popup, then
//     optionally a title slug.
// Ticket listing via the Jira REST API needs credentials we can't assume, so
// the key entry flow is the reliable path; the almanac plugin resolves the
// ticket title/URL afterwards from the branch name.

export async function fromJira(ticketArg?: string, titleArg?: string): Promise<void> {
  const focused = await focusedWorkspace();
  if (!focused) throw new Error("no focused workspace");

  let key = ticketArg?.trim().toUpperCase() ?? "";
  if (!key) {
    process.stdout.write("Ticket key (e.g. ES-1234): ");
    key = ((await readLine()) ?? "").trim().toUpperCase();
  }
  if (!/^[A-Z][A-Z0-9]+-[0-9]+$/.test(key)) {
    throw new Error(`invalid ticket key: ${key || "(empty)"}`);
  }

  let title = titleArg?.trim() ?? "";
  if (!title && !ticketArg) {
    process.stdout.write("Short title (optional, for the branch slug): ");
    title = ((await readLine()) ?? "").trim();
  }

  const branch = title ? `${key.toLowerCase()}-${slugify(title)}` : key.toLowerCase();
  const label = title ? `${key} ${slugify(title, 24)}` : key;
  const result = await fastCreate({ workspaceId: focused.workspace_id, branch, label });
  await herdr([
    "workspace", "report-metadata", result.workspaceId,
    "--source", "workstream",
    "--token", `jira=${key}`,
  ]);
  console.log(`Opened ${key} in workspace ${label} (${result.mode} worktree)`);
}

async function readLine(): Promise<string | null> {
  const buf: Uint8Array[] = [];
  const reader = Bun.stdin.stream().getReader();
  for (;;) {
    const { done, value } = await reader.read();
    if (done) break;
    buf.push(value);
    if (value.includes(0x0a)) break;
  }
  if (buf.length === 0) return null;
  return Buffer.concat(buf).toString("utf8").split("\n")[0];
}
