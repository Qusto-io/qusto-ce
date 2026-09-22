import { test, expect } from '@playwright/test'
import {
  setupSite,
  logout,
  makeSitePublic,
  populateStats,
  createSharedLink
} from '../fixtures'
import {
  expectDashboardTopStat,
  expectSiteDomainSwitcher,
  gotoSiteDashboard,
  tabButton
} from '../test-utils'

test.describe.configure({ timeout: process.env.CI ? 60_000 : 30_000 })

test('dashboard renders for logged in user', async ({ page, request }) => {
  const { domain } = await setupSite({ page, request })
  await populateStats({ request, domain, events: [{ name: 'pageview' }] })

  await gotoSiteDashboard(page, domain)

  await expect(page).toHaveTitle(/Qusto/)

  await expectSiteDomainSwitcher(page, domain)
})

test('dashboard renders for anonymous viewer', async ({ page, request }) => {
  const { domain } = await setupSite({ page, request })
  await makeSitePublic({ page, domain })
  await populateStats({ request, domain, events: [{ name: 'pageview' }] })
  await logout(page)

  await gotoSiteDashboard(page, domain)

  await expect(page).toHaveTitle(/Qusto/)

  await expectSiteDomainSwitcher(page, domain)
})

test('dashboard renders via shared link', async ({ page, request }) => {
  const { domain } = await setupSite({ page, request })
  await populateStats({ request, domain, events: [{ name: 'pageview' }] })
  const link = await createSharedLink({ page, domain, name: 'public_link' })
  const passwordLink = await createSharedLink({
    page,
    domain,
    name: 'password_link',
    password: 'secret'
  })
  await logout(page)

  await test.step('public link', async () => {
    await page.goto(link, { waitUntil: 'commit' })

    await expectSiteDomainSwitcher(page, domain)

    await expectDashboardTopStat(page, '#visitors', '1')
  })

  await test.step('password protected link', async () => {
    await page.goto(passwordLink, { waitUntil: 'commit' })

    await page.locator('input#password').fill('secret')

    await page.getByRole('button', { name: 'Continue' }).click()

    await expectSiteDomainSwitcher(page, domain)

    await expectDashboardTopStat(page, '#visitors', '1')
  })
})

test('dashboard renders with imported data', async ({ page, request }) => {
  const { domain } = await setupSite({ page, request })
  await populateStats({
    request,
    domain,
    events: [
      { name: 'pageview' },
      {
        type: 'imported_visitors',
        visitors: 3,
        visits: 4,
        pageviews: 6,
        bounces: 1
      }
    ]
  })

  await gotoSiteDashboard(page, domain)

  await test.step('with imported data included', async () => {
    await expectDashboardTopStat(page, '#visitors', '4')
    await expectDashboardTopStat(page, '#visits', '5')
    await expectDashboardTopStat(page, '#pageviews', '7')
    await expectDashboardTopStat(page, '#bounce_rate', '40%')
  })

  await test.step('with imported data excluded', async () => {
    await page.getByTestId('import-switch').click()

    await expect(page).toHaveURL(/with_imported=false/)

    await expectDashboardTopStat(page, '#visitors', '1')
    await expectDashboardTopStat(page, '#visits', '1')
    await expectDashboardTopStat(page, '#pageviews', '1')
    await expectDashboardTopStat(page, '#bounce_rate', '100%')
  })
})

test('tab selection user preferences are preserved across reloads', async ({
  page,
  request
}) => {
  const { domain } = await setupSite({ page, request })
  await populateStats({ request, domain, events: [{ name: 'pageview' }] })

  await gotoSiteDashboard(page, domain)

  const entryPagesTab = tabButton(page, 'Entry pages')
  await expect(entryPagesTab).toBeVisible()
  await entryPagesTab.click()

  await gotoSiteDashboard(page, domain)

  let currentTab = await page.evaluate(
    (domain) => localStorage.getItem('pageTab__' + domain),
    domain
  )

  expect(currentTab).toEqual('entry-pages')

  const exitPagesTab = tabButton(page, 'Exit pages')
  await expect(exitPagesTab).toBeVisible()
  await exitPagesTab.click()

  await gotoSiteDashboard(page, domain)

  currentTab = await page.evaluate(
    (domain) => localStorage.getItem('pageTab__' + domain),
    domain
  )

  expect(currentTab).toEqual('exit-pages')
})

test('back navigation closes the modal', async ({ page, request, baseURL }) => {
  const { domain } = await setupSite({ page, request })
  await populateStats({
    request,
    domain,
    events: [{ name: 'pageview' }]
  })

  await gotoSiteDashboard(page, domain)

  await page.getByRole('button', { name: 'Filter' }).click()

  await page.getByRole('link', { name: 'Page' }).click()

  await expect(page).toHaveURL(baseURL + '/' + domain + '/filter/page')

  await page.goBack()

  await expect(page).toHaveURL(baseURL + '/' + domain)
})
