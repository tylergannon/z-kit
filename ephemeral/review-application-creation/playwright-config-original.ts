import { defineConfig } from "@playwright/test";

export default defineConfig({
  webServer: {
    command: "cd .. && zig build dev",
    url: "http://127.0.0.1:5173",
  },
  testMatch: "**/*.e2e.{ts,js}",
  use: { baseURL: "http://127.0.0.1:5173" },
});
