import {describe, it} from "vitest";
import {RuleTester} from "oxlint/plugins-dev";
import plugin from "./oxlint-plugin.js";

RuleTester.describe = describe;
RuleTester.it = it;

const ruleTester = new RuleTester({languageOptions: {parserOptions: {lang: "tsx"}}});

const MESSAGE = "Do not add prose comments to code; use names, structure, and tests.";

ruleTester.run("no-prose-comments", plugin.rules["no-prose-comments"], {
  valid: [
    `// eslint-disable-next-line @typescript-eslint/no-explicit-any
const value: any = compute();`,
    `// oxlint-disable-next-line import/no-unassigned-import
import "./styles.css";`,
    `// @ts-expect-error a stale partial response can omit this field at runtime
const value = response.maybeMissing;`,
    `// oxfmt-ignore
const uglyMatrix = [1, 0, 0, 0, 1, 0, 0, 0, 1];`,
    `/* v8 ignore next */
function untestedBranch() {}`,
    `function LazyImage() {
  return <img src={/* @vite-ignore */ dynamicPath} />;
}`,
  ],
  invalid: [
    {
      code: `// This explains what the function does.
function helper() {}`,
      errors: [{message: MESSAGE, line: 1}],
    },
    {
      code: `const value = compute(); // explain the computation`,
      errors: [{message: MESSAGE, line: 1}],
    },
    {
      code: `/* Explains what this component renders. */
function Widget() {
  return <div />;
}`,
      errors: [{message: MESSAGE, line: 1}],
    },
    {
      code: `function Parent() {
  return (
    <div>
      {/* JSX comment: deliberate prose */}
      <span />
    </div>
  );
}`,
      errors: [{message: MESSAGE, line: 4}],
    },
    {
      code: `// TODO: refactor this
function helper() {}`,
      errors: [{message: MESSAGE, line: 1}],
    },
    {
      code: `// ts-expect-error missing the @
const value = response.maybeMissing;`,
      errors: [{message: MESSAGE, line: 1}],
    },
    {
      code: `// noprose: explanation of why this needs a comment
function helper() {}`,
      errors: [{message: MESSAGE, line: 1}],
    },
  ],
});
