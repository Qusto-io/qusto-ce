import { expectQustoInAction } from './support/test-utils'
import { test, expect } from '@playwright/test'

// G8 (CONSENT-MODES): before analytics consent, qusto.js loads this tracker
// with event-consent="false" (aggregate mode). In that mode the tracker must
// not access device storage at all — not even to read the owner's
// localStorage.qusto_ignore flag (ePrivacy art. 5(3) covers reads too).
// After consent, and on every install without the attribute, the flag still
// excludes the owner's own visits.

// Counts every access to window.localStorage before any page script runs.
async function spyOnLocalStorage(page) {
  await page.addInitScript(() => {
    const real = window.localStorage
    window.__lsReads = 0
    Object.defineProperty(window, 'localStorage', {
      configurable: true,
      get() {
        window.__lsReads++
        return real
      }
    })
  })
}

test.describe('consent and device storage', () => {
  test('event-consent="false": pageview is sent and localStorage is never read', async ({
    page
  }) => {
    await spyOnLocalStorage(page)
    await expectQustoInAction(page, {
      action: () => page.goto('/consent-false-pageview-props.html'),
      expectedRequests: [{ n: 'pageview', p: { consent: 'false' } }]
    })
    expect(await page.evaluate(() => window.__lsReads)).toBe(0)
  })

  test('event-consent="true": the owner ignore flag is still honoured', async ({
    page
  }) => {
    await page.addInitScript(() => {
      window.localStorage.setItem('qusto_ignore', 'true')
    })
    await expectQustoInAction(page, {
      action: () => page.goto('/consent-true-pageview-props.html'),
      expectedRequests: [],
      refutedRequests: [{ n: 'pageview' }]
    })
  })

  test('no event-consent attribute: behaviour unchanged, the flag is read', async ({
    page
  }) => {
    await spyOnLocalStorage(page)
    await expectQustoInAction(page, {
      action: () => page.goto('/legacy-pageview-properties.html'),
      expectedRequests: [{ n: 'pageview' }]
    })
    expect(await page.evaluate(() => window.__lsReads)).toBeGreaterThan(0)
  })
})
