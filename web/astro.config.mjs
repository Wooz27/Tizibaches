// Configuración de Astro para la web pública.
import node from "@astrojs/node";
import react from "@astrojs/react";
import tailwindcss from "@tailwindcss/vite";
import { defineConfig } from "astro/config";

export default defineConfig({
  output: "server",
  adapter: node({ mode: "standalone" }),
  integrations: [react()],
  devToolbar: { enabled: false },
  server: {
    host: true,
    port: 4321,
  },
  vite: {
    plugins: [tailwindcss()],
    // MapLibre se empaqueta en el cliente; el SSR no debe resolver su entrada CJS.
    ssr: {
      noExternal: ["maplibre-gl"],
    },
  },
});
