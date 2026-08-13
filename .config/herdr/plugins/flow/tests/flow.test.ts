import { describe, expect, test, beforeEach } from "bun:test";
import { mkdtempSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

// Point the store at a temp dir before importing the module under test.
const stateDir = mkdtempSync(join(tmpdir(), "flow-test-"));
process.env.HERDR_PLUGIN_STATE_DIR = stateDir;

const almanac = await import("../src/almanac");
const phases = await import("../src/phases");

describe("jiraKeysFromBranch", () => {
  test("parses ticket prefix", () => {
    expect(almanac.jiraKeysFromBranch("es-1234-fix-login".toUpperCase())).toEqual(["ES-1234"]);
  });
  test("parses multiple keys", () => {
    expect(almanac.jiraKeysFromBranch("feat/ES-12-and-DB-345-work")).toEqual(["ES-12", "DB-345"]);
  });
  test("no key", () => {
    expect(almanac.jiraKeysFromBranch("feat-plain")).toEqual([]);
  });
  test("undefined branch", () => {
    expect(almanac.jiraKeysFromBranch(undefined)).toEqual([]);
  });
});

describe("almanac store", () => {
  beforeEach(() => almanac.saveStore({}));

  test("add dedupes same kind+id", () => {
    almanac.addRef("br", { kind: "jira", id: "ES-1" });
    almanac.addRef("br", { kind: "jira", id: "ES-1" });
    almanac.addRef("br", { kind: "url", id: "ES-1" }); // different kind: kept
    expect(almanac.loadStore()["br"]).toHaveLength(2);
  });

  test("removeRef filters by kind and id", () => {
    almanac.addRef("br", { kind: "jira", id: "ES-1" });
    almanac.addRef("br", { kind: "url", id: "ES-1" });
    almanac.removeRef("br", "jira", "ES-1");
    expect(almanac.loadStore()["br"]).toEqual([{ kind: "url", id: "ES-1" }]);
  });

  test("search matches key, id, and title", () => {
    almanac.addRef("feat-auth", { kind: "jira", id: "ES-9", title: "Login revamp" });
    expect(almanac.searchRefs("auth")).toHaveLength(1);
    expect(almanac.searchRefs("es-9")).toHaveLength(1);
    expect(almanac.searchRefs("revamp")).toHaveLength(1);
    expect(almanac.searchRefs("nomatch")).toHaveLength(0);
  });
});

describe("phases", () => {
  test("token value round-trips to phase id", () => {
    for (const p of phases.PHASES) {
      expect(phases.currentPhaseId({ phase: phases.phaseTokenValue(p.id) })).toBe(p.id);
    }
  });
  test("unknown token yields null", () => {
    expect(phases.currentPhaseId({ phase: "garbage" })).toBeNull();
    expect(phases.currentPhaseId(undefined)).toBeNull();
  });
});
