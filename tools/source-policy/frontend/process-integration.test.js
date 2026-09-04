import { spawnSync } from "node:child_process";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { afterEach, beforeEach, describe, expect, it } from "vitest";

const TOOL_DIR = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(TOOL_DIR, "../../..");
const CONFIG_PATH = path.join(TOOL_DIR, "oxlint.config.json");
const ORDINARY_CONFIG_PATH = path.join(REPO_ROOT, ".oxlintrc.json");

let fixtureDir;

beforeEach(() => {
  fixtureDir = mkdtempSync(path.join(tmpdir(), "source-policy-fixture-"));
});

afterEach(() => {
  rmSync(fixtureDir, { recursive: true, force: true });
});

function runOxlintOn(fixturePath, configPath = CONFIG_PATH) {
  return spawnSync("pnpm", ["exec", "oxlint", "--config", configPath, fixturePath], {
    cwd: REPO_ROOT,
    encoding: "utf8",
  });
}

describe("source-policy oxlint adapter", () => {
  it("reports both an ordering and a comment diagnostic with a nonzero exit", () => {
    const fixturePath = path.join(fixtureDir, "fixture.tsx");
    writeFileSync(
      fixturePath,
      [
        "// prose explanation of this helper",
        "function entry() {",
        "  helper();",
        "  return 1;",
        "}",
        "",
        "function callee() {}",
        "",
        "function helper() {",
        "  callee();",
        "  return 2;",
        "}",
        "",
      ].join("\n"),
    );

    const result = runOxlintOn(fixturePath);

    expect(result.status).not.toBe(0);
    expect(result.stdout).toContain("source-policy(ordering)");
    expect(result.stdout).toContain("source-policy(no-prose-comments)");
  });

  it("reports a violation through ordinary frontend lint configuration", () => {
    const fixturePath = path.join(fixtureDir, "ordinary-fixture.tsx");
    writeFileSync(
      fixturePath,
      [
        "function helper() {",
        "  return 1;",
        "}",
        "",
        "function entry() {",
        "  return helper();",
        "}",
        "",
      ].join("\n"),
    );

    const result = runOxlintOn(fixturePath, ORDINARY_CONFIG_PATH);

    expect(result.status).not.toBe(0);
    expect(result.stdout).toContain("source-policy(ordering)");
  });

  it("exits zero on a clean fixture", () => {
    const fixturePath = path.join(fixtureDir, "clean.tsx");
    writeFileSync(
      fixturePath,
      [
        "function entry() {",
        "  return helper();",
        "}",
        "",
        "function helper() {",
        "  return 1;",
        "}",
        "",
      ].join("\n"),
    );

    const result = runOxlintOn(fixturePath);

    expect(result.status).toBe(0);
  });
});
