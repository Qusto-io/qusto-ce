# CI/CD Pipeline Setup

## Overview

The Qusto Analytics CI/CD pipeline ensures code quality, security, and automated deployments. This document describes the setup, configuration, and usage of the CI/CD system.

## Pipeline Architecture

### Workflows

1. **Elixir CI** ([`.github/workflows/elixir.yml`](../.github/workflows/elixir.yml))
   - Runs on: Pull requests, pushes to `master`/`stable`, merge groups
   - Jobs: Build & Test, Static Analysis, Security Scans

2. **Node CI** ([`.github/workflows/node.yml`](../.github/workflows/node.yml))
   - Runs on: Pull requests, pushes to `master`/`stable`, merge groups
   - Jobs: Build, Type checking, Linting, Testing

3. **Deployment** ([`.github/workflows/deploy.yml`](../.github/workflows/deploy.yml))
   - Runs on: Pushes to `develop` (staging), `main` (production), manual trigger
   - Jobs: Deploy to Staging, Deploy to Production

## CI Pipeline Jobs

### Build and Test

**Purpose:** Compile the application and run the full test suite

**Key Steps:**
- Set up Elixir, Erlang, and Node.js from `.tool-versions`
- Cache dependencies for faster builds
- Build tracker script
- Compile Elixir code with warnings as errors
- Run database migrations
- Execute test suite with coverage
- Run tests in parallel across 6 partitions

**Environment Matrix:**
- Test environments: `test`, `ce_test`
- PostgreSQL version: 18
- ClickHouse version: 24.12.2.29-alpine

**Success Criteria:**
- All tests pass
- No compilation warnings
- Test coverage meets threshold

### Static Analysis

**Purpose:** Enforce code quality standards

**Checks:**
- **Format:** `mix format --check-formatted` - Ensures consistent code formatting
- **Credo:** `mix credo diff` - Runs static code analysis for code quality
- **Dialyzer:** `mix dialyzer` - Performs static type analysis
- **Unused deps:** `mix deps.unlock --check-unused` - Detects unused dependencies

**Success Criteria:**
- Code is properly formatted
- No Credo warnings
- No Dialyzer errors
- No unused dependencies

### Security Scans

**Purpose:** Identify security vulnerabilities

**Tools:**
- **mix_audit:** Scans dependencies for known vulnerabilities (CVEs)
- **Sobelow:** Scans Elixir code for security issues (XSS, SQL injection, etc.)

**Configuration:**
- Sobelow config: [`.sobelow-conf`](../.sobelow-conf)
- Exit on high-severity issues

**Success Criteria:**
- No high-severity vulnerabilities in dependencies
- No security issues detected by Sobelow

## Deployment Pipeline

### Staging Deployment

**Trigger:** Automatic on push to `develop` branch

**Process:**
1. Build application release
2. Create backup of current release
3. Upload new release to staging server
4. Stop current service
5. Run database migrations (unless skipped)
6. Update symlink to new release
7. Start service
8. Run health check
9. Rollback if health check fails

**Environment:** `staging`
**URL:** https://staging.qusto.io

### Production Deployment

**Trigger:**
- Push to `main` branch (requires manual approval)
- Manual workflow dispatch

**Process:** Same as staging with production-specific configuration

**Environment:** `production`
**URL:** https://qusto.io

### Deployment Secrets

Required GitHub Secrets:

**Staging:**
- `STAGING_DEPLOY_HOST` - Staging server hostname/IP
- `STAGING_DEPLOY_USER` - SSH username
- `STAGING_DEPLOY_SSH_KEY` - Private SSH key for authentication

**Production:**
- `PRODUCTION_DEPLOY_HOST` - Production server hostname/IP
- `PRODUCTION_DEPLOY_USER` - SSH username
- `PRODUCTION_DEPLOY_SSH_KEY` - Private SSH key for authentication

**Setting Secrets:**
1. Go to repository Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Add each secret with its value

### Manual Deployment

Trigger a deployment manually:

1. Go to Actions tab in GitHub
2. Select "Deploy" workflow
3. Click "Run workflow"
4. Choose:
   - Branch to deploy from
   - Environment (staging/production)
   - Whether to skip migrations
5. Click "Run workflow"

### Rollback Procedure

If a deployment fails:

1. **Automatic Rollback:** Health check failure triggers automatic rollback
2. **Manual Rollback:** SSH to server and run:
   ```bash
   # Staging
   sudo systemctl stop qusto-staging
   ln -sfn /var/www/qusto/backups/staging/release_TIMESTAMP /var/www/qusto/staging/current
   sudo systemctl start qusto-staging

   # Production
   sudo systemctl stop qusto
   ln -sfn /var/www/qusto/backups/production/release_TIMESTAMP /var/www/qusto/production/current
   sudo systemctl start qusto
   ```

## Branch Protection Rules

### Protected Branches

**`master` / `main`:**
- Require pull request reviews (1 approver minimum)
- Require status checks to pass:
  - `build` (all matrix jobs)
  - `static` (format, credo, dialyzer)
  - `security` (deps.audit, sobelow)
  - `build` (Node CI)
- Require branches to be up to date
- Require linear history
- No force pushes
- No deletions

**`develop`:**
- Require status checks to pass (same as above)
- Require branches to be up to date
- No force pushes
- No deletions

**`stable`:**
- Same as `master` rules
- Used for stable releases

### Setting Up Branch Protection

See [BRANCH_PROTECTION.md](./BRANCH_PROTECTION.md) for detailed setup instructions.

## Local Development

### Running CI Checks Locally

Before pushing, run these commands to catch issues early:

```bash
# Install dependencies
mix deps.get
mix deps.audit

# Run tests
mix test

# Run static analysis
mix format --check-formatted
mix credo --strict
mix dialyzer

# Run security scans
mix deps.audit
mix sobelow --config

# Run Node checks
npm run typecheck --prefix ./assets
npm run lint --prefix ./assets
npm run test --prefix ./assets
```

### Pre-commit Hook

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash
set -e

echo "🔍 Running pre-commit checks..."

# Format check
echo "📝 Checking code format..."
mix format --check-formatted

# Credo
echo "🔎 Running Credo..."
mix credo --strict

# Tests
echo "🧪 Running tests..."
mix test

echo "✅ All checks passed!"
```

Make it executable:
```bash
chmod +x .git/hooks/pre-commit
```

## Monitoring and Debugging

### Viewing Workflow Runs

1. Go to Actions tab in GitHub
2. Click on a workflow run
3. Click on a job to view logs
4. Download logs for offline analysis

### Common Issues

**Dependency cache issues:**
- Clear cache by updating `CACHE_VERSION` in workflow file

**Test failures:**
- Check if services (PostgreSQL, ClickHouse, Redis) are healthy
- Review test logs for specific failure reasons

**Security scan failures:**
- Review vulnerability details
- Update dependencies: `mix deps.update <package>`
- Add exceptions to `.sobelow-conf` if false positive

**Deployment failures:**
- Check server connectivity
- Verify SSH keys are correct
- Check server disk space
- Review deployment logs

## Performance Optimization

### Caching Strategy

The pipeline uses aggressive caching:
- Dependencies (`deps`, `_build`)
- Node modules (`tracker/node_modules`)
- Compiled assets (`priv/tracker/js`)
- Dialyzer PLT files (`priv/plts`)

Cache keys include:
- Environment (`MIX_ENV`)
- Cache version
- Branch name
- `mix.lock` hash

### Parallel Execution

Tests run in parallel:
- 6 partitions for faster execution
- Matrix strategy for multiple environments

### Dependency Installation Optimization

Tracker build is cached and only rebuilt when `tracker/**` files change.

## Security Considerations

### Secret Management

- Never commit secrets to the repository
- Use GitHub Secrets for sensitive values
- Rotate SSH keys regularly
- Use separate keys for staging and production

### Audit Trail

All deployments are logged:
- GitHub Actions logs
- Server deployment logs
- Rollback history

### Access Control

- Limit repository admin access
- Require 2FA for all contributors
- Use CODEOWNERS for critical files

## Maintenance

### Regular Tasks

**Weekly:**
- Review failed workflow runs
- Update dependencies with security patches

**Monthly:**
- Review and update branch protection rules
- Audit GitHub Actions usage/costs
- Review deployment logs

**Quarterly:**
- Update GitHub Actions to latest versions
- Review and optimize cache strategy
- Security audit of CI/CD pipeline

## Support and Troubleshooting

For issues or questions:
1. Check workflow logs in GitHub Actions
2. Review this documentation
3. Check server logs: `journalctl -u qusto -n 100`
4. Contact DevOps team

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Elixir CI Best Practices](https://hexdocs.pm/phoenix/testing.html)
- [Mix Tasks Reference](https://hexdocs.pm/mix/Mix.html)
- [Sobelow Security Scanner](https://github.com/nccgroup/sobelow)
