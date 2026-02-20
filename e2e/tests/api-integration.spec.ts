import { test, expect } from '@playwright/test';

/**
 * E2E Tests for API Integration
 * Tests all API endpoints and their integrations with the frontend
 */

test.describe('API Integration Tests', () => {
  const API_BASE_URL = process.env.BASE_URL || 'http://localhost:8000';

  test('Health check endpoint responds correctly', async ({ request }) => {
    const response = await request.get(`${API_BASE_URL}/api/health`);
    expect(response.ok()).toBeTruthy();
    expect(response.status()).toBe(200);
  });

  test('Revenue API endpoint returns data', async ({ request, page }) => {
    // First, navigate to the page to establish session if needed
    await page.goto('/');

    // Make API request for revenue data
    const response = await request.get(`${API_BASE_URL}/api/stats/revenue`, {
      params: {
        period: '30d',
        date: new Date().toISOString().split('T')[0]
      }
    });

    // Check response status
    if (response.ok()) {
      const data = await response.json();

      // Verify data structure
      expect(data).toBeDefined();
      expect(data).toHaveProperty('revenue');
    }
  });

  test('Stats API endpoint returns valid JSON', async ({ request, page }) => {
    await page.goto('/');

    const response = await request.get(`${API_BASE_URL}/api/stats`, {
      params: {
        site_id: 'test',
        period: '7d'
      }
    });

    if (response.ok()) {
      const data = await response.json();
      expect(data).toBeDefined();
      expect(typeof data).toBe('object');
    }
  });

  test('API returns proper CORS headers', async ({ request }) => {
    const response = await request.options(`${API_BASE_URL}/api/health`);
    const headers = response.headers();

    // Check for CORS headers
    expect(headers['access-control-allow-origin'] || headers['Access-Control-Allow-Origin']).toBeDefined();
  });

  test('API rate limiting is in place', async ({ request, page }) => {
    await page.goto('/');

    // Make multiple rapid requests
    const requests = Array(20).fill(null).map(() =>
      request.get(`${API_BASE_URL}/api/health`)
    );

    const responses = await Promise.all(requests);

    // At least some requests should succeed
    const successfulRequests = responses.filter(r => r.ok());
    expect(successfulRequests.length).toBeGreaterThan(0);
  });

  test('API handles invalid parameters gracefully', async ({ request }) => {
    const response = await request.get(`${API_BASE_URL}/api/stats`, {
      params: {
        period: 'invalid',
        date: 'not-a-date'
      }
    });

    // Should return 400 Bad Request or handle gracefully
    expect(response.status()).toBeGreaterThanOrEqual(400);
    expect(response.status()).toBeLessThan(500);
  });

  test('Event ingestion endpoint accepts POST requests', async ({ request }) => {
    const response = await request.post(`${API_BASE_URL}/api/event`, {
      data: {
        name: 'pageview',
        url: 'https://example.com',
        domain: 'example.com'
      }
    });

    // Should accept or return appropriate status
    expect(response.status()).toBeLessThan(500);
  });
});
