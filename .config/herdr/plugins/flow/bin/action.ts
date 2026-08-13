#!/usr/bin/env bun
// Action router: bin/action.ts <action> [args...]
import { addRef, removeRef, searchRefs, syncWorkspace, type RefKind } from "../src/almanac";
import { focusedWorkspace, workspaceInfo } from "../src/herdr";
import { clearPhase, cyclePhase, PHASES, pickPhase, setPhase } from "../src/phases";

const [action, ...args] = process.argv.slice(2);

async function requireFocused(): Promise<string> {
  const focused = await focusedWorkspace();
  if (!focused) throw new Error("no focused workspace");
  return focused.workspace_id;
}

async function main(): Promise<void> {
  switch (action) {
    case "set-phase": {
      const id = args[0];
      if (!id) throw new Error(`usage: set-phase <${PHASES.map((p) => p.id).join("|")}>`);
      await setPhase(await requireFocused(), id);
      break;
    }
    case "cycle-phase":
      await cyclePhase(await requireFocused());
      break;
    case "clear-phase":
      await clearPhase(await requireFocused());
      break;
    case "pick-phase":
      await pickPhase();
      break;
    case "almanac-attach": {
      const [kind, id, ...titleParts] = args;
      if (!kind || !id) throw new Error("usage: almanac-attach <jira|url|doc|person|pr> <id> [title]");
      const wsId = await requireFocused();
      const ws = await workspaceInfo(wsId);
      const key = ws.worktree?.branch ?? ws.label;
      addRef(key, { kind: kind as RefKind, id, title: titleParts.join(" ") || undefined });
      await syncWorkspace(wsId);
      console.log(`attached ${kind}:${id} to ${key}`);
      break;
    }
    case "almanac-detach": {
      const [kind, id] = args;
      if (!kind || !id) throw new Error("usage: almanac-detach <kind> <id>");
      const wsId = await requireFocused();
      const ws = await workspaceInfo(wsId);
      removeRef(ws.worktree?.branch ?? ws.label, kind as RefKind, id);
      await syncWorkspace(wsId);
      break;
    }
    case "almanac-search": {
      const query = args.join(" ");
      for (const hit of searchRefs(query)) {
        console.log(`${hit.key}\t${hit.ref.kind}:${hit.ref.id}${hit.ref.title ? `\t${hit.ref.title}` : ""}`);
      }
      break;
    }
    case "almanac-sync":
      // Refresh the focused workspace's sidebar token (auto-attaches Jira refs).
      await syncWorkspace(await requireFocused());
      break;
    default:
      throw new Error(`unknown action: ${action ?? "(none)"}`);
  }
}

main().catch((err) => {
  console.error(`[flow] ${err.message ?? err}`);
  process.exit(1);
});
