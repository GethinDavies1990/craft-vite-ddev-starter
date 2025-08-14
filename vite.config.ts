import { defineConfig } from "vite";
import tailwindcss from "@tailwindcss/vite";
import ViteRestart from "vite-plugin-restart";
import viteCompression from "vite-plugin-compression";
import checker from "vite-plugin-checker";

export default defineConfig(({ command }) => ({
    base: command === "serve" ? "/" : "/dist",
    plugins: [
        checker({
            stylelint: {
                lintCommand: 'stylelint "src/**/*.css"',
            },
            eslint: {
                lintCommand: 'eslint "src/**/*.js"',
                useFlatConfig: true,
                dev: {
                    overrideConfig: {
                        cache: true,
                    },
                },
            },
        }),
        tailwindcss(),
        ViteRestart({
            restart: ["./templates/**/*"],
        }),
        viteCompression({
            filter: /\.(js|mjs|json|css|map)$/i,
        }),
    ],
    build: {
        manifest: true,
        rollupOptions: { input: { app: "src/js/app.js" } },
        outDir: "web/dist",
    },
    server: {
        https: false, // <-- Vite serves HTTP internally
        host: "0.0.0.0",
        port: 5173, // <-- must match container_port
        strictPort: true,
        cors: true, // <-- unblock CORS
        origin: "//https://futur-craft.ddev.site/:5173", // <-- use DDEV HTTPS port
        hmr: {
            host: "https://futur-craft.ddev.site/",
            protocol: "wss",
            port: 5173,
        },
        watch: { ignored: ["./storage/**", "./vendor/**", "./web/**"] },
    },
}));
