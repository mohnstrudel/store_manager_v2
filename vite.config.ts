import { defineConfig } from "vite";
import RubyPlugin from "vite-plugin-ruby";
import react from "@vitejs/plugin-react";
import { fileURLToPath, URL } from "node:url";

export default defineConfig({
  plugins: [RubyPlugin(), react()],
  resolve: {
    alias: {
      "@": fileURLToPath(new URL("app/frontend", import.meta.url)),
    },
  },
});
