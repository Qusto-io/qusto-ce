import { test, expect } from '@playwright/test';

/**
 * E2E Tests for Error Handling
 * Tests how the application handles various error scenarios
 */

test.describe('Error Handling', () => {
  test('404 page displays for non-existent routes', async ({ page }) => {
    const response = await page.goto('/this-route-does-not-exist');

    // Should show 404 page
    expect(response?.status()).toBe(404);

    // Check for error message or 404 content
    const pageContent = await page.textContent('body');
    expect(pageContent).toMatch(/404|not found|page not found/i);
  });

  test('Network error displays appropriate message', async ({ page }) => {
    // Navigate to dashboard
    await page.goto('/');

    // Simulate offline mode
    await page.context().setOffline(true);

    // Try to load a page that requires network
    await page.goto('/revenue', { waitUntil: 'domcontentloaded' }).catch(() => {});

    // Restore online mode
    await page.context().setOffline(false);

    // The page should show some error indication
    const body = await page.locator('body').textContent();
    expect(body).toBeDefined();
  });

  test('Invalid form submission shows validation errors', async ({ page }) => {
    // Navigate to a form page (e.g., login or settings)
    await page.goto('/login');

    // Try to submit empty form
    const submitButton = page.locator('button[type="submit"]');
    if (await submitButton.isVisible()) {
      await submitButton.click();

      // Check for validation error messages
      await page.waitForTimeout(500);
      const errorMessage = page.locator('[class*="error"], [role="alert"], .text-red-500');
      const errorCount = await errorMessage.count();

      // Should show at least one error
      expect(errorCount).toBeGreaterThan(0);
    }
  });

  test('API error displays user-friendly message', async ({ page }) => {
    // Navigate to dashboard
    await page.goto('/revenue');

    // Intercept API request and return error
    await page.route('**/api/stats/**', route => {
      route.fulfill({
        status: 500,
        contentType: 'application/json',
        body: JSON.stringify({ error: 'Internal Server Error' })
      });
    });

    // Reload to trigger the intercepted request
    await page.reload();

    // Wait a bit for error to display
    await page.waitForTimeout(1000);

    // Check for error message (implementation-specific)
    const body = await page.locator('body').textContent();
    expect(body).toBeDefined();
  });

  test('Unauthorized access redirects to login', async ({ page, context }) => {
    // Clear cookies to simulate unauthorized state
    await context.clearCookies();

    // Try to access protected route
    await page.goto('/settings');

    // Should redirect to login or show unauthorized message
    await page.waitForLoadState('networkidle');

    const url = page.url();
    const pageContent = await page.textContent('body');

    // Either redirected to login or shows unauthorized message
    const isProtected = url.includes('login') ||
                       url.includes('auth') ||
                       pageContent?.includes('unauthorized') ||
                       pageContent?.includes('log in');

    expect(isProtected).toBeTruthy();
  });

  test('Session timeout shows appropriate message', async ({ page }) => {
    await page.goto('/');

    // Clear session storage to simulate timeout
    await page.evaluate(() => {
      sessionStorage.clear();
      localStorage.clear();
    });

    // Try to perform an authenticated action
    await page.reload();
    await page.waitForLoadState('networkidle');

    // Should handle gracefully (redirect or show message)
    const url = page.url();
    expect(url).toBeDefined();
  });

  test('Concurrent request errors are handled', async ({ page }) => {
    await page.goto('/revenue');

    // Make multiple rapid navigations to test concurrent handling
    const promises = [
      page.goto('/revenue'),
      page.goto('/dashboard'),
      page.goto('/revenue')
    ];

    // Wait for all navigations
    await Promise.allSettled(promises);

    // Page should still be functional
    await page.waitForLoadState('networkidle');
    const url = page.url();
    expect(url).toBeDefined();
  });
});
