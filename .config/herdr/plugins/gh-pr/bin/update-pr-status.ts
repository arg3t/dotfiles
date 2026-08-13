#!/usr/bin/env bun
import { refreshAll } from "../src/main";

// Event hook + manual refresh entry. Never fail loudly — a noisy hook would
// spam every focus change.
refreshAll().catch((err) => {
  console.error(`[gh-pr] refresh failed: ${err}`);
});
