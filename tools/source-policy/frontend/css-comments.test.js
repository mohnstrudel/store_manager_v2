import {describe, expect, it} from "vitest";
import {scanCssComments} from "./css-comments.js";

describe("scanCssComments", () => {
  it("accepts CSS with no comments", () => {
    expect(scanCssComments(".foo { color: red; }\n")).toEqual([]);
  });

  it("rejects an ordinary section-header block comment", () => {
    const source = "/* Buttons */\n.btn { color: red; }\n";

    const violations = scanCssComments(source);

    expect(violations).toEqual([
      {
        line: 1,
        column: 0,
        length: 13,
        message: "Do not add prose comments to code; use names, structure, and tests.",
      },
    ]);
  });

  it("rejects a multi-line prose comment and reports its starting line", () => {
    const source = ".card {\n  /* Product economics snapshot above\n     the tabs */\n  color: red;\n}\n";

    const violations = scanCssComments(source);

    expect(violations).toHaveLength(1);
    expect(violations[0].line).toBe(2);
  });

  it("accepts an exact bang-prefixed legal or generated directive comment", () => {
    const source = "/*! Copyright Acme Inc. All rights reserved. */\n.foo { color: red; }\n";

    expect(scanCssComments(source)).toEqual([]);
  });

  it("does not mistake a comment-like sequence inside a string literal for a comment", () => {
    const source = ".foo { content: \"/* not a comment */\"; }\n";

    expect(scanCssComments(source)).toEqual([]);
  });
});
