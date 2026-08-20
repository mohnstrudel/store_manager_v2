import { fileURLToPath, URL } from "node:url";

import inertia from "@inertiajs/vite";
import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";
import RubyPlugin from "vite-plugin-ruby";

export default defineConfig({
  plugins: [
    RubyPlugin(),
    react(),
    inertia({ ssr: { entry: "entrypoints/ssr.ts" } }),
    tailwindcss(),
  ],
  resolve: {
    alias: {
      "@": fileURLToPath(new URL("app/frontend", import.meta.url)),
    },
  },
  server: {
    // With skipProxy:true the browser fetches CSS from the Vite dev server directly.
    // Absolute url("/fonts/…") and url("/images/…") paths in CSS resolve against the
    // Vite port, not the Rails port, so proxy them back to Rails.
    // Rails port is hardcoded here to match Procfile.dev (bin/rails server -p 3000).
    // process.env.PORT cannot be used here: foreman assigns it per-process
    // (web=3000, worker=3001, vite=3002), so inside the Vite process it equals 3002.
    proxy: {
      "/fonts": "http://localhost:3000",
      "/images": "http://localhost:3000",
    },
  },
});
