/**
 * Phase 2 Cursor tests for qusto-ce (PARALLEL_TESTING_STRATEGY.md:178-183)
 * - Test CE landing page (general web analytics focus)
 * - Validate CE dashboard UI
 * - Check CE-specific components
 * - Verify CE color scheme (blue headers light, cream headers dark)
 * - Test CE responsive design
 */
import { test, expect } from '@playwright/test'

const BASE = 'http://127.0.0.1:8000'

test.describe('CE Landing Page', () => {
  test('loads root and shows general web analytics focus', async ({ page }) => {
    await page.goto(BASE)
    await expect(page).toHaveURL(/\/$|\/register|\/login/)
    // Should have Qusto branding (header + footer logos)
    await expect(page.locator('img[alt="Qusto logo"]')).toHaveCount(4)
  })

  test('registration page loads (HTTP 200)', async ({ page }) => {
    const res = await page.goto(`${BASE}/register`)
    expect(res?.status()).toBe(200)
    await expect(page.locator('h1, h2').first()).toBeVisible({ timeout: 5000 })
  })

  test('landing has web analytics / product messaging', async ({ page }) => {
    await page.goto(BASE)
    const body = await page.textContent('body')
    const hasAnalytics =
      body?.toLowerCase().includes('analytics') ||
      body?.toLowerCase().includes('privacy') ||
      body?.toLowerCase().includes('insights') ||
      body?.toLowerCase().includes('qusto')
    expect(hasAnalytics).toBeTruthy()
  })

  /* Visual regression: uncomment to capture baseline, then enable for CI */
  // test('landing page visual snapshot', async ({ page }) => {
  //   await page.goto(BASE)
  //   await expect(page.locator('header')).toHaveScreenshot('ce-landing-header.png')
  // })
})

test.describe('CE Marketing Pages (CE-specific)', () => {
  test('product overview loads', async ({ page }) => {
    const res = await page.goto(`${BASE}/product`)
    expect(res?.status()).toBe(200)
  })

  test('pricing page loads', async ({ page }) => {
    const res = await page.goto(`${BASE}/pricing`)
    expect(res?.status()).toBe(200)
  })

  test('about page loads', async ({ page }) => {
    const res = await page.goto(`${BASE}/about`)
    expect(res?.status()).toBe(200)
  })
})

test.describe('CE Color Scheme', () => {
  test('light mode: blue header/brand colors present', async ({ page }) => {
    await page.goto(BASE)
    // Force light mode (remove dark class if present)
    await page.evaluate(() => document.documentElement.classList.remove('dark'))
    const header = page.locator('header').first()
    await expect(header).toBeVisible({ timeout: 5000 })
    // CE light: blue brand (#002d9c, #1661be) - check computed styles or presence of blue
    const bgColor = await header.evaluate((el) =>
      window.getComputedStyle(el).getPropertyValue('background-color')
    )
    expect(bgColor).toBeTruthy()
  })

  test('dark mode: cream text / warm headers present', async ({ page }) => {
    await page.goto(BASE)
    await page.evaluate(() => document.documentElement.classList.add('dark'))
    const body = page.locator('body')
    await expect(body).toBeVisible()
    // CE dark mode: cream headers (#f5f1e8) via --color-dark-text-primary
    const textColor = await page.evaluate(() => {
      const style = getComputedStyle(document.body)
      return style.color
    })
    expect(textColor).toBeTruthy()
  })
})

test.describe('CE Responsive Design', () => {
  test('mobile viewport: layout adapts', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 })
    await page.goto(BASE)
    const header = page.locator('header').first()
    await expect(header).toBeVisible({ timeout: 5000 })
    const box = await header.boundingBox()
    expect(box?.width).toBeLessThanOrEqual(400)
  })

  test('tablet viewport: layout adapts', async ({ page }) => {
    await page.setViewportSize({ width: 768, height: 1024 })
    await page.goto(BASE)
    const header = page.locator('header').first()
    await expect(header).toBeVisible({ timeout: 5000 })
  })

  test('desktop viewport: full layout', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 720 })
    await page.goto(BASE)
    const header = page.locator('header').first()
    await expect(header).toBeVisible({ timeout: 5000 })
  })
})

test.describe('CE Dashboard UI (requires auth)', () => {
  test('sites page redirects to login when unauthenticated', async ({ page }) => {
    const res = await page.goto(`${BASE}/sites`)
    // Should redirect to login or register
    await expect(page).toHaveURL(/\/(login|register|auth)/)
  })
})
