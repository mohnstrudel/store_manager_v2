import {describe, expect, it} from "vitest";
import {isGeneratedPath, isTestPath, selectJsTargets} from "./cli.js";

describe("isGeneratedPath", () => {
  it("flags the generated api directory", () => {
    expect(isGeneratedPath("app/frontend/api/products.ts")).toBe(true);
  });

  it("accepts ordinary source paths", () => {
    expect(isGeneratedPath("app/frontend/components/Widget.tsx")).toBe(false);
  });
});

describe("isTestPath", () => {
  it("flags *.test.ts and *.test.tsx files", () => {
    expect(isTestPath("app/frontend/components/Widget.test.tsx")).toBe(true);
    expect(isTestPath("app/frontend/utils/rowNavigation.test.ts")).toBe(true);
  });

  it("flags files under the shared test directory", () => {
    expect(isTestPath("app/frontend/test/mocks/inertia.tsx")).toBe(true);
    expect(isTestPath("app/frontend/test/setup.ts")).toBe(true);
  });

  it("flags page-local test factories nested under a page's own test directory", () => {
    expect(isTestPath("app/frontend/pages/Products/test/factories.ts")).toBe(true);
  });

  it("accepts ordinary runtime source paths", () => {
    expect(isTestPath("app/frontend/components/Widget.tsx")).toBe(false);
  });
});

describe("selectJsTargets", () => {
  const files = [
    "app/frontend/components/Widget.tsx",
    "app/frontend/components/Widget.test.tsx",
    "app/frontend/test/mocks/inertia.tsx",
    "app/frontend/api/products.ts",
  ];

  it("excludes the generated api directory in every mode", () => {
    expect(selectJsTargets(files, {})).not.toContain("app/frontend/api/products.ts");
  });

  it("selects only non-test files for --runtime-files", () => {
    expect(selectJsTargets(files, {runtimeOnly: true})).toEqual(["app/frontend/components/Widget.tsx"]);
  });

  it("selects only test files and the shared test directory for --test-files", () => {
    expect(selectJsTargets(files, {testOnly: true})).toEqual([
      "app/frontend/components/Widget.test.tsx",
      "app/frontend/test/mocks/inertia.tsx",
    ]);
  });

  it("selects every non-generated file by default", () => {
    expect(selectJsTargets(files, {})).toEqual([
      "app/frontend/components/Widget.tsx",
      "app/frontend/components/Widget.test.tsx",
      "app/frontend/test/mocks/inertia.tsx",
    ]);
  });
});
