#!/usr/bin/env bun
// Action router: herdr invokes bin/action.ts <action> [args...] for every
// manifest action so argument parsing lives in one place.
import { fastCreate } from "../src/fast-create";
import { fromJira } from "../src/from-jira";
import { fromPr } from "../src/from-pr";
import { focusedWorkspace } from "../src/herdr";
import { listPaused, pause, restore } from "../src/lifecycle";

const [action, ...args] = process.argv.slice(2);

async function main(): Promise<void> {
  switch (action) {
    case "from-pr":
      await fromPr();
      break;
    case "from-jira":
      await fromJira(args[0], args[1]);
      break;
    case "fast-create": {
      const branch = args[0];
      if (!branch) throw new Error("usage: fast-create <branch>");
      const focused = await focusedWorkspace();
      if (!focused) throw new Error("no focused workspace");
      const result = await fastCreate({ workspaceId: focused.workspace_id, branch });
      console.log(`Created ${branch} (${result.mode} worktree)`);
      break;
    }    case "pause": {
      const focused = await focusedWorkspace();
      if (!focused) throw new Error("no focused workspace");
      await pause(focused.workspace_id);
      break;
    }
    case "restore": {
      if (args[0]) {
        await restore(args[0]);
        break;
      }
      const paused = await listPaused();
      if (paused.length === 0) {
        console.log("No paused workspaces.");
        break;
      }
      if (paused.length === 1) {
        await restore(paused[0].key);
        break;
      }
      // Interactive pick among several paused workspaces.
      const lines = paused.map(
        (p) => `${p.record.workspace_label}  (paused ${p.record.paused_at.slice(0, 16)})\t${p.key}`,
      );
      const proc = Bun.spawn(["fzf", "--prompt", "restore> ", "--with-nth", "1", "--delimiter", "\t"], {
        stdin: "pipe",
        stdout: "pipe",
        stderr: "inherit",
      });
      proc.stdin.write(lines.join("\n"));
      proc.stdin.end();
      const out = await new Response(proc.stdout).text();
      if ((await proc.exited) === 0 && out.trim()) {
        const key = out.trim().split("\t").pop() ?? "";
        if (key) await restore(key);
      }
      break;
    }
    case "paused-list": {
      for (const p of await listPaused()) {
        console.log(`${p.key}\t${p.record.workspace_label}\t${p.record.paused_at}`);
      }
      break;
    }
    default:
      throw new Error(`unknown action: ${action ?? "(none)"}`);
  }
}

main().catch((err) => {
  console.error(`[workstream] ${err.message ?? err}`);
  process.exit(1);
});
