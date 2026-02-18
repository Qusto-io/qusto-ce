# CE Dashboard E2E Tests

Phase 2 Cursor tests (PARALLEL_TESTING_STRATEGY.md:178-183).

## Prerequisites

- Server running at http://127.0.0.1:8000
- Playwright: `npm install -g playwright` or use `npx`

## Run Tests

```bash
# From qusto-ce root
cd 03-development/qusto-ce
npx playwright test e2e/ce-dashboard.spec.ts --config=e2e/playwright.config.ts
```

## Test Coverage

| Test | Description |
|------|-------------|
| CE Landing Page | Root, registration, web analytics messaging |
| CE Marketing Pages | /product, /pricing, /about |
| CE Color Scheme | Light: blue headers; Dark: cream headers |
| CE Responsive Design | Mobile (375px), tablet (768px), desktop (1280px) |
| CE Dashboard UI | Auth redirect for /sites |
