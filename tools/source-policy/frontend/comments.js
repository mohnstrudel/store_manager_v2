const TS_DIRECTIVE_RE = /^@ts-(?:expect-error|ignore|nocheck|check)\b.*$/;
const ESLINT_OXLINT_DIRECTIVE_RE = /^(?:eslint|oxlint)-(?:disable(?:-next-line|-line)?|enable)\b.*$/;
const FORMATTER_DIRECTIVE_RE = /^oxfmt-ignore$/;
const COVERAGE_DIRECTIVE_RE = /^v8 ignore (?:next|start|stop)\b.*$/;
const BUNDLER_DIRECTIVE_RE = /^@vite-ignore$/;

export function isAllowedComment(comment) {
  const text = comment.value.trim();

  return (
    TS_DIRECTIVE_RE.test(text) ||
    ESLINT_OXLINT_DIRECTIVE_RE.test(text) ||
    FORMATTER_DIRECTIVE_RE.test(text) ||
    COVERAGE_DIRECTIVE_RE.test(text) ||
    BUNDLER_DIRECTIVE_RE.test(text)
  );
}
