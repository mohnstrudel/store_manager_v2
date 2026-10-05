import {describe, expect, it} from "vitest";
import {isAllowedComment} from "./comments.js";

function line(value) {
  return {type: "Line", value};
}

function block(value) {
  return {type: "Block", value};
}

describe("isAllowedComment", () => {
  it("rejects a leading prose line comment", () => {
    expect(isAllowedComment(line(" This is a prose explanation."))).toBe(false);
  });

  it("rejects a prose block comment", () => {
    expect(isAllowedComment(block(" Explains what this component renders. "))).toBe(false);
  });

  it("rejects a JSX prose comment", () => {
    expect(isAllowedComment(block(" JSX comment: deliberate prose "))).toBe(false);
  });

  it("rejects TODO and FIXME comments", () => {
    expect(isAllowedComment(line(" TODO: refactor this"))).toBe(false);
    expect(isAllowedComment(line(" FIXME: handle edge case"))).toBe(false);
  });

  it("accepts exact TypeScript directives", () => {
    expect(isAllowedComment(line(" @ts-expect-error a stale response can omit this field"))).toBe(true);
    expect(isAllowedComment(line(" @ts-ignore"))).toBe(true);
    expect(isAllowedComment(line(" @ts-nocheck"))).toBe(true);
    expect(isAllowedComment(line(" @ts-check"))).toBe(true);
  });

  it("accepts exact ESLint and Oxlint directives", () => {
    expect(isAllowedComment(line(" eslint-disable-next-line @typescript-eslint/no-explicit-any"))).toBe(true);
    expect(isAllowedComment(line(" oxlint-disable-next-line import/no-unassigned-import"))).toBe(true);
    expect(
      isAllowedComment(
        line(" eslint-disable-next-line @typescript-eslint/no-unsafe-type-assertion -- generic params erased")
      )
    ).toBe(true);
  });

  it("accepts the exact oxfmt formatter directive", () => {
    expect(isAllowedComment(line(" oxfmt-ignore"))).toBe(true);
    expect(isAllowedComment(block(" oxfmt-ignore "))).toBe(true);
  });

  it("accepts exact v8 coverage directives", () => {
    expect(isAllowedComment(block(" v8 ignore next "))).toBe(true);
    expect(isAllowedComment(block(" v8 ignore start "))).toBe(true);
  });

  it("accepts the exact Vite bundler directive", () => {
    expect(isAllowedComment(block(" @vite-ignore "))).toBe(true);
  });

  it("rejects malformed lookalike directives", () => {
    expect(isAllowedComment(line(" ts-expect-error missing the @"))).toBe(false);
    expect(isAllowedComment(line(" eslint disable-next-line missing the dash"))).toBe(false);
    expect(isAllowedComment(line(" oxfmt-ignore-file"))).toBe(false);
  });

  it("has no general suppression escape hatch for an invented marker", () => {
    expect(isAllowedComment(line(" noprose: explanation of why this needs a comment"))).toBe(false);
  });
});
