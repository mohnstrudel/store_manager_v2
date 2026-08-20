import { defineConfig, mergeConfig } from "vitest/config";
import react from "@vitejs/plugin-react";
import path from "path";

export default mergeConfig(
  defineConfig({
    plugins: [react()],
    resolve: {
      alias: {
        "@": path.resolve(import.meta.dirname, "app/frontend"),
        // Global Inertia mock — every test file gets the shared double without
        // needing vi.mock("@inertiajs/react", …). See app/frontend/test/mocks/inertia.tsx.
        "@inertiajs/react": path.resolve(import.meta.dirname, "app/frontend/test/mocks/inertia.tsx"),
      },
    },
  }),
  defineConfig({
    test: {
      environment: "jsdom",
      globals: true,
      mockReset: true,
      setupFiles: ["app/frontend/test/setup.ts"],
      include: ["app/frontend/**/*.test.{ts,tsx}"],
      coverage: {
        provider: "v8",
        include: ["app/frontend/**"],
        exclude: ["app/frontend/api/**", "app/frontend/test/**", "app/frontend/entrypoints/**"],
      },
    },
  }),
);
