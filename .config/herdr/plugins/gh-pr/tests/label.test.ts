import { describe, expect, test } from "bun:test";
import { composeIcon, rollupChecks } from "../src/main";

describe("composeIcon", () => {
  const base = { number: 42, url: "https://example/pr/42" };

  test("merged", () => {
    expect(composeIcon({ ...base, state: "MERGED", review: "none" }, "none")).toBe("#42 ✓");
  });
  test("closed unmerged", () => {
    expect(composeIcon({ ...base, state: "CLOSED", review: "none" }, "pass")).toBe("#42 ✗");
  });
  test("changes requested beats CI", () => {
    expect(composeIcon({ ...base, state: "OPEN", review: "changes_requested" }, "fail")).toBe(
      "#42 △",
    );
  });
  test("approved without pending reviewers", () => {
    expect(composeIcon({ ...base, state: "OPEN", review: "approved" }, "pending")).toBe("#42 ✓");
  });
  test("approved with pending reviewers", () => {
    expect(composeIcon({ ...base, state: "OPEN", review: "approved_pending" }, "pass")).toBe(
      "#42 ✓~",
    );
  });
  test("no review: CI pass / fail / pending / none", () => {
    expect(composeIcon({ ...base, state: "OPEN", review: "none" }, "pass")).toBe("#42 ●");
    expect(composeIcon({ ...base, state: "OPEN", review: "none" }, "fail")).toBe("#42 ●!");
    expect(composeIcon({ ...base, state: "OPEN", review: "none" }, "pending")).toBe("#42 ◐");
    expect(composeIcon({ ...base, state: "OPEN", review: "none" }, "none")).toBe("#42 ◌");
  });
});

describe("rollupChecks", () => {
  test("empty is none", () => expect(rollupChecks([])).toBe("none"));
  test("fail wins over pending and pass", () => {
    expect(rollupChecks([{ bucket: "pass" }, { bucket: "pending" }, { bucket: "fail" }])).toBe(
      "fail",
    );
  });
  test("cancel counts as fail", () => {
    expect(rollupChecks([{ bucket: "pass" }, { bucket: "cancel" }])).toBe("fail");
  });
  test("pending beats pass", () => {
    expect(rollupChecks([{ bucket: "pass" }, { bucket: "pending" }])).toBe("pending");
  });
  test("skipping alone passes", () => {
    expect(rollupChecks([{ bucket: "skipping" }])).toBe("pass");
  });
});
