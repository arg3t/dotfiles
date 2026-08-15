#!/usr/bin/env bun
// Interactive almanac search: fzf over all refs, Enter opens the URL/ticket
// in the browser when it is a link. Runs inside the popup pane (has a TTY).
import { loadStore } from "../src/almanac";
import { $ } from "bun";

const query = process.argv[2] ?? "";

const all: Array<{ key: string; kind: string; id: string; title?: string }> = [];
for (const [key, refs] of Object.entries(loadStore())) {
  for (const r of refs) all.push({ key, kind: r.kind, id: r.id, title: r.title });
}

if (all.length === 0) {
  console.log("Almanac is empty. Attach refs with the almanac-attach action.");
  process.exit(0);
}

const lines = all.map(
  (r) => `${r.key}  ${r.kind}:${r.id}${r.title ? `  ${r.title}` : ""}\t${r.id}`,
);

const proc = Bun.spawn(
  ["fzf", "--prompt", "almanac> ", "--with-nth", "1", "--delimiter", "\t", ...(query ? ["--query", query] : [])],
  { stdin: "pipe", stdout: "pipe", stderr: "inherit" },
);
proc.stdin.write(lines.join("\n"));
proc.stdin.end();
const out = await new Response(proc.stdout).text();
if ((await proc.exited) !== 0 || !out.trim()) process.exit(0);

const id = out.trim().split("\t").pop() ?? "";
// Open http(s) links in the browser; Jira keys just print (no URL configured).
if (/^https?:\/\//.test(id)) {
  const opener = process.platform === "darwin" ? "open" : "xdg-open";
  await $`${opener} ${id}`.nothrow().quiet();
} else {
  console.log(id);
}
