import { describe, expect, test } from "bun:test";
import { slugify } from "../src/herdr";

describe("slugify", () => {
  test("basic", () => expect(slugify("Fix Login Bug")).toBe("fix-login-bug"));
  test("strips punctuation", () => expect(slugify("feat: auth (v2)!")).toBe("feat-auth-v2"));
  test("collapses dashes", () => expect(slugify("a -- b__c")).toBe("a-b-c"));
  test("respects max length without trailing dash", () =>
    expect(slugify("aaaa bbbb cccc dddd", 10)).toBe("aaaa-bbbb"));
  test("fallback for symbols-only", () => expect(slugify("!!!")).toBe("work"));
});
