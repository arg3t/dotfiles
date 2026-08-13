#!/usr/bin/env bun
import { openPr } from "../src/main";

openPr().catch((err) => {
  console.error(`[gh-pr] open failed: ${err}`);
});
