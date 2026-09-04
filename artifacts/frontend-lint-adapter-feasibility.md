# Frontend lint adapter feasibility (ticket 01)

## Question

Can the pinned Oxlint 1.69 JS plugin API implement the approved frontend source-policy
contract (depth-first call order plus no-prose-comments) without losing required AST or
comment information?

## Commands

```
mise exec -- pnpm exec oxlint --version
mise exec -- pnpm exec oxlint --config /private/tmp/source-policy-oxlint.json /private/tmp/source-policy-fixture.tsx
```

`oxlint --version` reported `Version: 1.69.0`, matching the version pinned in `package.json`
(`oxlint": "^1.69.0"`).

## Probe

A disposable plugin (`/private/tmp/source-policy-probe/plugin.js`, outside the repository,
not committed) registered a single rule that visits `Program`, `FunctionDeclaration`,
`VariableDeclarator`, `ClassDeclaration`, `MethodDefinition`, `CallExpression`, and
`JSXElement`, and reads `context.sourceCode.getAllComments()`. It was run through
`mise exec -- pnpm exec oxlint --config /private/tmp/source-policy-oxlint.json
/private/tmp/source-policy-fixture.tsx` against a disposable fixture
(`/private/tmp/source-policy-fixture.tsx`, outside the repository, not committed) containing a
top-level function with a nested function, a variable-bound arrow function, a class with two
methods calling each other via `this`, two JSX-returning function components (one referencing
the other by JSX tag), a leading line comment, a leading block comment, and a `{/* JSX */}`
comment.

## Observed API shape

- `FunctionDeclaration` nodes are visited in source order, including nested declarations
  inside another function's body (`outer` at line 5, `nested` at line 6).
- `VariableDeclarator` nodes whose `init` is an `ArrowFunctionExpression` or
  `FunctionExpression` are visited and expose the bound identifier (`arrowHelper`).
- `ClassDeclaration` and `MethodDefinition` are visited separately; `this.method()` calls
  inside a method body are reachable as `CallExpression` nodes whose `callee` is a
  `MemberExpression` over a `ThisExpression`.
- Plain identifier calls (`CallExpression` with an `Identifier` callee) are visited and expose
  the callee name, sufficient to build same-owner call edges.
- `JSXElement` nodes expose `openingElement.name`; a capitalized `JSXIdentifier` (`Child`)
  is distinguishable from a lowercase intrinsic tag (`div`), which is what the contract needs
  to detect JSX references to locally defined components.
- `context.sourceCode.getAllComments()` returns every comment in the file, each with a
  `type` of `Line` or `Block` and its trimmed `value`. The `{/* JSX comment */}` was returned
  as an ordinary `Block` comment, so JSX comments do not need special-case extraction — they
  are visible through the same `SourceCode` API as line/block comments.
- Every reported node carries `loc`, so source order and enclosing-scope relationships (e.g.
  nested function inside outer) are directly derivable from the AST shape already visited.

## Result

```
$ mise exec -- pnpm exec oxlint --config /private/tmp/source-policy-oxlint.json /private/tmp/source-policy-fixture.tsx
...
/private/tmp/source-policy-fixture.tsx:3:1: error source-policy-probe(probe): program-comments: Line:"line comment: deliberate prose comment for probe detection" | Block:"block comment: deliberate prose comment for probe detection" | Block:"JSX comment: deliberate prose comment for probe detection"
/private/tmp/source-policy-fixture.tsx:5:1: error source-policy-probe(probe): function-declaration: outer
/private/tmp/source-policy-fixture.tsx:6:3: error source-policy-probe(probe): function-declaration: nested
/private/tmp/source-policy-fixture.tsx:9:10: error source-policy-probe(probe): call: nested
/private/tmp/source-policy-fixture.tsx:12:7: error source-policy-probe(probe): variable-bound-function: arrowHelper
/private/tmp/source-policy-fixture.tsx:16:1: error source-policy-probe(probe): class-declaration: Widget
/private/tmp/source-policy-fixture.tsx:17:3: error source-policy-probe(probe): class-method: render
/private/tmp/source-policy-fixture.tsx:18:12: error source-policy-probe(probe): this-call: helper
/private/tmp/source-policy-fixture.tsx:21:3: error source-policy-probe(probe): class-method: helper
/private/tmp/source-policy-fixture.tsx:26:1: error source-policy-probe(probe): function-declaration: Child
/private/tmp/source-policy-fixture.tsx:27:10: error source-policy-probe(probe): jsx-element: div
/private/tmp/source-policy-fixture.tsx:30:1: error source-policy-probe(probe): function-declaration: Parent
/private/tmp/source-policy-fixture.tsx:32:5: error source-policy-probe(probe): jsx-element: div
/private/tmp/source-policy-fixture.tsx:34:7: error source-policy-probe(probe): jsx-element: Child
/private/tmp/source-policy-fixture.tsx:39:1: error source-policy-probe(probe): call: outer
/private/tmp/source-policy-fixture.tsx:40:1: error source-policy-probe(probe): call: arrowHelper
EXIT: 1
```

The command exited nonzero (`1`) through the repository's Node 24 / pnpm toolchain, confirming
Oxlint JS-plugin diagnostics fail the process the same way built-in rules do.

## CSS coverage

Oxlint 1.69 lints JavaScript/JSX/TypeScript/TSX only; it has no CSS parser or rule API, so it
cannot inspect `.css` files at all (confirmed by `oxlint --help`, which lists only JS/TS/Vue
plugin toggles, and by the absence of any CSS file-extension handling in `oxlint --help`).
CSS comment enforcement is out of Oxlint's scope regardless of plugin API maturity and must be
a separate standalone check.

## Blockers

None material. The JS plugin API is alpha (per the Oxlint docs), and the ESLint-compatible
`create` API re-invokes the plugin per file, but every AST and comment surface the frontend
contract needs (function declarations, variable-bound functions/arrows, nested lexical scopes,
class methods, direct identifier and `this.method()` calls, JSX component references, source
order via `loc`, and line/block/JSX comments via `getAllComments()`) is present and
observable today.

## Decision

Use the thin Oxlint JS-plugin adapter for JavaScript/JSX/TypeScript/TSX ordering and comment
checks (ticket 03), per the spec's preference for the adapter when feasible. CSS comment
checking cannot go through Oxlint's JS rule API and must use the approved standalone local
Node check, run from the same `pnpm lint` command, matching the Frontend Contract's
compatibility clause.

## Repository impact

None. No `.oxlintrc.json`, dependency, or production file was changed. The probe plugin,
fixture, and config live under `/private/tmp` and are not part of this repository.
