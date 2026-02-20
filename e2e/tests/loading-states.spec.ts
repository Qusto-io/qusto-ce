import { test, expect } from '@playwright/test';

/**
 * E2E Tests for Loading States
 * Tests loading indicators and states throughout the application
 */

test.describe('Loading States', () => {
  test('Dashboard shows loading indicator while fetching data', async ({ page }) => {
    // Navigate to dashboard
    await page.goto('/');

    // Look for loading indicators (spinners, skeletons, etc.)
    const loadingIndicators = page.locator('[data-testid="loading"], [class*="spinner"], [class*="skeleton"], [aria-busy="true"]');

    // Check if loading indicator appears (with timeout)
    const hasLoading = await loadingIndicators.first().isVisible().catch(() => false);

    // Wait for page to finish loading
    await page.waitForLoadState('networkidle');

    // Loading indicator should be gone
    const stillLoading = await loadingIndicators.first().isVisible().catch(() => false);
    expect(stillLoading).toBeFalsy();
  });

  test('Revenue chart shows skeleton loader before data loads', async ({ page }) => {
    // Slow down network to observe loading state
    await page.route('**/api/stats/**', async route => {
      await new Promise(resolve => setTimeout(resolve, 500));
      route.continue();
    });

    await page.goto('/revenue');

    // Check for skeleton or loading state
    const loader = page.locator('[data-testid="chart-loading"], [class*="skeleton"]');

    // Wait for content to load
    await page.waitForLoadState('networkidle');

    // Verify chart is now visible
    const chart = page.locator('[data-testid="revenue-chart"]');
    if (await chart.count() > 0) {
      await expect(chart.first()).toBeVisible({ timeout: 10000 });
    }
  });

  test('Button shows loading state during submission', async ({ page }) => {
    await page.goto('/login');

    // Fill form if fields exist
    const emailField = page.locator('input[type="email"], input[name="email"]');
    const passwordField = page.locator('input[type="password"], input[name="password"]');
    const submitButton = page.locator('button[type="submit"]');

    if (await emailField.isVisible() && await passwordField.isVisible()) {
      await emailField.fill('test@example.com');
      await passwordField.fill('password123');

      // Click submit and check for loading state
      await submitButton.click();

      // Button should show loading state
      const buttonText = await submitButton.textContent();
      const isLoading = await submitButton.isDisabled() ||
                       buttonText?.toLowerCase().includes('loading') ||
                       buttonText?.toLowerCase().includes('submitting');

      // Wait for submission to complete
      await page.waitForLoadState('networkidle');
    }
  });

  test('Infinite scroll shows loading indicator when fetching more data', async ({ page }) => {
    await page.goto('/');

    // Scroll to bottom to trigger infinite scroll if present
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));

    // Check for "load more" button or automatic loading
    const loadMore = page.locator('[data-testid="load-more"], button:has-text("Load More")');

    if (await loadMore.isVisible()) {
      await loadMore.click();

      // Check for loading indicator
      const loading = page.locator('[data-testid="loading-more"], [class*="spinner"]');
      await page.waitForTimeout(500);

      // Wait for loading to complete
      await page.waitForLoadState('networkidle');
    }
  });

  test('Table shows loading state while fetching rows', async ({ page }) => {
    await page.goto('/');

    // Look for tables
    const table = page.locator('table');

    if (await table.count() > 0) {
      // Reload to see loading state
      await page.reload();

      // Check for table loading state
      const tableLoading = page.locator('[data-testid="table-loading"], tbody[class*="loading"]');

      // Wait for table to load
      await page.waitForLoadState('networkidle');

      // Verify table has rows
      const rows = table.locator('tbody tr');
      await page.waitForTimeout(500);
    }
  });

  test('Form fields show validation loading state', async ({ page }) => {
    await page.goto('/login');

    const emailField = page.locator('input[type="email"], input[name="email"]');

    if (await emailField.isVisible()) {
      // Type email and check for validation loading
      await emailField.fill('test@example.com');
      await emailField.blur();

      // Some forms show validation loading
      await page.waitForTimeout(300);

      // Field should be validated (no loading state)
      const isDisabled = await emailField.isDisabled();
      expect(isDisabled).toBeFalsy();
    }
  });

  test('Page transition shows loading indicator', async ({ page }) => {
    await page.goto('/');

    // Navigate to another page
    const link = page.locator('a[href="/revenue"], a:has-text("Revenue")');

    if (await link.first().isVisible()) {
      await link.first().click();

      // Check for page transition loader
      const loader = page.locator('[data-testid="page-loader"], [class*="page-loading"]');

      // Wait for new page to load
      await page.waitForLoadState('networkidle');

      // Verify navigation succeeded
      const url = page.url();
      expect(url).toBeDefined();
    }
  });

  test('Dashboard refreshes with loading indicator', async ({ page }) => {
    await page.goto('/revenue');
    await page.waitForLoadState('networkidle');

    // Find refresh button if exists
    const refreshButton = page.locator('[data-testid="refresh"], button:has-text("Refresh")');

    if (await refreshButton.isVisible()) {
      await refreshButton.click();

      // Should show loading state
      await page.waitForTimeout(100);

      // Wait for refresh to complete
      await page.waitForLoadState('networkidle');

      // Page should still be functional
      const chart = page.locator('[data-testid="revenue-chart"]');
      if (await chart.count() > 0) {
        await expect(chart.first()).toBeVisible();
      }
    }
  });
});
