import { defineConfig } from "vite";
import RubyPlugin from "vite-plugin-ruby";
import inertia from "@inertiajs/vite";
import tailwindcss from "@tailwindcss/vite";
import { fileURLToPath, URL } from "node:url";

export default defineConfig({
  plugins: [RubyPlugin(), inertia({ ssr: { entry: "entrypoints/ssr.ts" } }), tailwindcss()],
  resolve: {
    alias: {
      "@": fileURLToPath(new URL("app/frontend", import.meta.url)),
    },
  },
});
