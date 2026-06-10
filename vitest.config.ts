import { defineConfig, mergeConfig } from "vitest/config";
import react from "@vitejs/plugin-react";
import path from "path";

export default mergeConfig(
  defineConfig({
    plugins: [react()],
    resolve: {
      alias: {
        "@": path.resolve(__dirname, "app/frontend"),
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
    },
  }),
);
