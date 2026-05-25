# Security Policy

## Supported Versions

Qusto Community Edition (CE) is a fork of [Plausible Analytics](https://github.com/plausible/analytics). We release security updates on the active `qusto/v2.x` branch. Self-hosters should pull the latest CE image or rebuild from the current branch tag.

| Version   | Supported          |
| --------- | ------------------ |
| qusto/v2.x | :white_check_mark: |
| older     | :x:                |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Report vulnerabilities by email to:

**security@qusto.io**

You should receive a response within 48 hours. If you do not, follow up to confirm we received your message.

### What to Include

- Type of vulnerability (e.g., XSS, SQL injection, authentication bypass)
- Full paths of affected source file(s)
- Location of the affected code (tag/branch/commit or direct URL)
- Step-by-step instructions to reproduce
- Proof-of-concept or exploit code (if possible)
- Impact assessment and suggested fix (if you have one)

### What to Expect

- **Initial response:** within 48 hours acknowledging receipt
- **Status update:** within 7 days with our assessment and planned fix timeline
- **Fix timeline:** critical issues within 7 days; high severity within 30 days
- **Disclosure:** we coordinate public disclosure with reporters

## Upstream Plausible

Qusto CE inherits code from Plausible Analytics (AGPL-3.0). Vulnerabilities in upstream Plausible may also affect Qusto CE. You may report upstream issues to [Plausible's disclosure program](https://plausible.io/vulnerability-disclosure-program); we monitor upstream advisories and backport fixes to Qusto CE as needed.

## Security Contact

- **Email:** security@qusto.io
- **Product:** [Qusto Community Edition](https://github.com/Qusto-io/qusto-ce)

Thank you for helping keep Qusto and our users safe.
