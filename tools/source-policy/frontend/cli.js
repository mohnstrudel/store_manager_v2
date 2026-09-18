import {globSync, readFileSync} from "node:fs";
import {spawnSync} from "node:child_process";
import path from "node:path";
import {fileURLToPath} from "node:url";
import {scanCssComments} from "./css-comments.js";

const TOOL_DIR = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(TOOL_DIR, "../../..");
const GENERATED_PREFIX = "app/frontend/api/";
const TEST_FILE_RE = /\.test\.tsx?$/;
const TEST_DIR_RE = /(^|\/)test\//;

export function isGeneratedPath(relativePath) {
  return relativePath.startsWith(GENERATED_PREFIX);
}

export function isTestPath(relativePath) {
  return TEST_FILE_RE.test(relativePath) || TEST_DIR_RE.test(relativePath);
}

export function selectJsTargets(allFiles, {runtimeOnly, testOnly}) {
  return allFiles.filter((file) => {
    if (isGeneratedPath(file)) return false;
    if (runtimeOnly) return !isTestPath(file);
    if (testOnly) return isTestPath(file);
    return true;
  });
}

function runOxlint(targets) {
  if (targets.length === 0) return 0;

  const configPath = path.join(TOOL_DIR, "oxlint.config.json");
  const result = spawnSync("pnpm", ["exec", "oxlint", "--config", configPath, ...targets], {
    cwd: REPO_ROOT,
    stdio: "inherit",
  });

  return result.status ?? 1;
}

function runCssScan() {
  const cssFiles = globSync("app/frontend/**/*.css", {cwd: REPO_ROOT});
  let exitCode = 0;

  for (const relativePath of cssFiles) {
    const source = readFileSync(path.join(REPO_ROOT, relativePath), "utf8");
    for (const violation of scanCssComments(source)) {
      console.error(`${relativePath}:${violation.line}:${violation.column + 1}: ${violation.message}`);
      exitCode = 1;
    }
  }

  return exitCode;
}

export function run(argv) {
  const runtimeOnly = argv.includes("--runtime-files");
  const testOnly = argv.includes("--test-files");
  const cssOnly = argv.includes("--css-only");

  const allFiles = globSync("app/frontend/**/*.{js,jsx,ts,tsx}", {cwd: REPO_ROOT});
  const jsTargets = selectJsTargets(allFiles, {runtimeOnly, testOnly});

  const jsExitCode = cssOnly ? 0 : runOxlint(jsTargets);
  const cssExitCode = testOnly ? 0 : runCssScan();

  return jsExitCode !== 0 || cssExitCode !== 0 ? 1 : 0;
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  process.exit(run(process.argv.slice(2)));
}
