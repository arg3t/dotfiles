#!/usr/bin/env bun
import { refreshAll } from "../src/main";

// Long-running poll loop spawned once per server start. PR review and CI
// state change server-side without any local event, so timer polling is the
// only way to keep icons current. gh rate limits are generous for this
// cadence: 2 gh calls per workspace per interval.
const INTERVAL_MS = Number(process.env.GH_PR_POLL_MS ?? 60_000);

async function loop(): Promise<void> {
  for (;;) {
    await refreshAll().catch((err) => console.error(`[gh-pr] poll failed: ${err}`));
    await Bun.sleep(INTERVAL_MS);
  }
}

await loop();
