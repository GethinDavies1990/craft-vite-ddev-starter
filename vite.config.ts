// vite.config.ts
import { defineConfig } from "vite";
import tailwindcss from "@tailwindcss/vite";
import ViteRestart from "vite-plugin-restart";
import viteCompression from "vite-plugin-compression";
import checker from "vite-plugin-checker";

// Auto-detect the project URL from DDEV (inside container) or .env fallback
// DDEV sets: DDEV_PRIMARY_URL = https://<project>.ddev.site
const primaryUrl =
    process.env.DDEV_PRIMARY_URL ||
    process.env.PRIMARY_SITE_URL ||
    "https://projectname.ddev.site";

const { hostname } = new URL(primaryUrl);
const DEV_PORT = 5173;

export default defineConfig(({ command }) => ({
    base: command === "serve" ? "/" : "/dist",

    plugins: [
        checker({
            stylelint: { lintCommand: 'stylelint "src/**/*.css"' },
            eslint: {
                lintCommand: 'eslint "src/**/*.js"',
                useFlatConfig: true,
                dev: { overrideConfig: { cache: true } },
            },
        }),
        tailwindcss(),
        ViteRestart({ restart: ["./templates/**/*"] }),
        viteCompression({ filter: /\.(js|mjs|json|css|map)$/i }),
    ],

    build: {
        manifest: true,
        rollupOptions: { input: { app: "src/js/app.js" } },
        outDir: "web/dist",
    },

    server: {
        // Vite serves HTTP inside the container; DDEV router exposes HTTPS externally
        https: false,
        host: "0.0.0.0",
        port: DEV_PORT,
        strictPort: true,
        cors: true,

        // Point asset/HMR URLs to your current DDEV site automatically
        origin: `${primaryUrl}:${DEV_PORT}`, // e.g. https://futur-craft.ddev.site:5173
        hmr: {
            host: hostname, // e.g. futur-craft.ddev.site (no protocol)
            protocol: "wss", // page is https, so use wss
            port: DEV_PORT,
        },

        watch: { ignored: ["./storage/**", "./vendor/**", "./web/**"] },
    },
}));
