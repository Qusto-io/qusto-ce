import { defineConfig, devices } from '@playwright/test'

/**
 * CE Dashboard E2E tests - targets http://127.0.0.1:8000
 * Run with: npx playwright test (from qusto-ce root)
 */
export default defineConfig({
  testDir: './',
  timeout: 15_000,
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  reporter: 'list',
  use: {
    baseURL: 'http://127.0.0.1:8000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    /* Visual testing: use expect(page).toHaveScreenshot() in tests */
    viewport: { width: 1280, height: 720 },
  },
  /* Visual regression: toHaveScreenshot() snapshots */
  expect: {
    toHaveScreenshot: { maxDiffPixels: 100 },
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'Mobile Chrome', use: { ...devices['Pixel 5'] } },
  ],
  webServer: process.env.CI
    ? {
        command: 'echo "Server should be running at http://127.0.0.1:8000"',
        port: 8000,
        reuseExistingServer: true,
      }
    : undefined,
})
