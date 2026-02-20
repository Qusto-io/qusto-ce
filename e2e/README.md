# CE Dashboard E2E Tests

Phase 2 Cursor tests (PARALLEL_TESTING_STRATEGY.md:178-183).

## Prerequisites

- Server running at http://127.0.0.1:8000
- Playwright: `cd e2e && npm install` (or use `npx`)

## Start / Stop CE Server

```bash
# Rebuild assets first (required for branding/ee-alignment; MIX_ENV=ce has no watchers)
cd 03-development/qusto-ce
mix assets.deploy

# Start (from qusto-ce root)
BASE_URL=http://localhost:8000 MIX_ENV=ce mix phx.server

# Alternative: ce_dev has live reload (no manual rebuild)
BASE_URL=http://localhost:8000 MIX_ENV=ce_dev mix phx.server

# Stop (kill Phoenix server on port 8000)
pkill -f "mix phx.server"
# Or find PID: lsof -ti :8000 | xargs kill
```

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
