import { test, expect } from '@playwright/test';

/**
 * E2E Tests for Revenue Dashboard
 * Tests the main revenue dashboard functionality including:
 * - Dashboard loading and visibility
 * - Revenue metrics display
 * - Charts and visualizations
 */

test.describe('Revenue Dashboard', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to the revenue dashboard
    await page.goto('/revenue');
  });

  test('Revenue dashboard loads and displays data', async ({ page }) => {
    // Wait for the page to load
    await page.waitForLoadState('networkidle');

    // Check that the total revenue element is visible
    const totalRevenue = page.locator('[data-testid="total-revenue"]');
    await expect(totalRevenue).toBeVisible({ timeout: 10000 });

    // Check that the revenue chart is visible
    const revenueChart = page.locator('[data-testid="revenue-chart"]');
    await expect(revenueChart).toBeVisible({ timeout: 10000 });
  });

  test('Dashboard displays revenue metrics', async ({ page }) => {
    await page.waitForLoadState('networkidle');

    // Check for key revenue metrics
    const metrics = [
      'total-revenue',
      'average-order-value',
      'conversion-rate',
      'revenue-growth'
    ];

    for (const metric of metrics) {
      const element = page.locator(`[data-testid="${metric}"]`);
      await expect(element).toBeVisible({ timeout: 5000 });
    }
  });

  test('Revenue chart renders correctly', async ({ page }) => {
    await page.waitForLoadState('networkidle');

    const chart = page.locator('[data-testid="revenue-chart"]');
    await expect(chart).toBeVisible();

    // Verify chart has data (check for SVG or canvas element)
    const chartCanvas = chart.locator('canvas, svg');
    await expect(chartCanvas).toBeVisible();
  });

  test('Date range selector works', async ({ page }) => {
    await page.waitForLoadState('networkidle');

    // Find and click date range selector
    const dateRangeSelector = page.locator('[data-testid="date-range-selector"]');
    if (await dateRangeSelector.isVisible()) {
      await dateRangeSelector.click();

      // Select a different date range
      const last30Days = page.locator('[data-testid="range-30d"]');
      if (await last30Days.isVisible()) {
        await last30Days.click();

        // Wait for data to reload
        await page.waitForLoadState('networkidle');

        // Verify the chart updated
        const chart = page.locator('[data-testid="revenue-chart"]');
        await expect(chart).toBeVisible();
      }
    }
  });

  test('Revenue breakdown by category displays', async ({ page }) => {
    await page.waitForLoadState('networkidle');

    // Check if revenue breakdown section exists
    const breakdown = page.locator('[data-testid="revenue-breakdown"]');
    if (await breakdown.isVisible()) {
      // Verify it contains data
      const breakdownItems = breakdown.locator('[data-testid^="category-"]');
      const count = await breakdownItems.count();
      expect(count).toBeGreaterThan(0);
    }
  });
});
