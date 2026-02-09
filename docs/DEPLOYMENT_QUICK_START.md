# Deployment Quick Start Guide

## Overview

This guide provides the essential steps to get the CI/CD pipeline and deployment system operational.

## Current Status

✅ **CI/CD Pipeline:** Configured and active
✅ **Security Scanning:** Enabled (mix_audit, sobelow)
✅ **Branch Protection:** Configured for master and develop branches
⏳ **Deployment Secrets:** Need to be added
⏳ **Server Setup:** Required for deployment (see Task 4.1-4.3 in work plan)

## Quick Setup Steps

### 1. Add GitHub Deployment Secrets

Run the interactive setup script:

```bash
./scripts/setup-github-secrets.sh
```

Or add secrets manually via GitHub CLI:

```bash
# Staging secrets
gh secret set STAGING_DEPLOY_HOST --repo Qusto-io/qusto-analytics
gh secret set STAGING_DEPLOY_USER --repo Qusto-io/qusto-analytics
gh secret set STAGING_DEPLOY_SSH_KEY --repo Qusto-io/qusto-analytics

# Production secrets
gh secret set PRODUCTION_DEPLOY_HOST --repo Qusto-io/qusto-analytics
gh secret set PRODUCTION_DEPLOY_USER --repo Qusto-io/qusto-analytics
gh secret set PRODUCTION_DEPLOY_SSH_KEY --repo Qusto-io/qusto-analytics
```

Or via GitHub UI:
1. Go to: https://github.com/Qusto-io/qusto-analytics/settings/secrets/actions
2. Click "New repository secret"
3. Add each secret with its value

### 2. Verify Branch Protection

Check branch protection rules:

```bash
# Master branch
gh api repos/Qusto-io/qusto-analytics/branches/master/protection

# Develop branch
gh api repos/Qusto-io/qusto-analytics/branches/develop/protection
```

**Current Configuration:**

**Master Branch:**
- ✅ Requires 1 PR review
- ✅ Requires status checks: `static`, `security`, `build`
- ✅ Linear history enforced
- ✅ Admin enforcement enabled
- ✅ Force push blocked
- ✅ Deletion blocked

**Develop Branch:**
- ✅ Requires status checks: `static`, `security`, `build`
- ✅ Force push blocked
- ✅ Deletion blocked

### 3. Test the CI Pipeline

Create a test branch and PR:

```bash
# Create test branch
git checkout -b test/ci-pipeline

# Make a small change
echo "# CI Test" >> README.md

# Commit and push
git add README.md
git commit -m "test: verify CI pipeline"
git push origin test/ci-pipeline

# Create PR via GitHub CLI
gh pr create --title "Test: CI Pipeline" --body "Testing CI/CD setup"
```

**Expected Behavior:**
- GitHub Actions automatically run
- Three jobs execute: `build`, `static`, `security`
- All checks must pass before merging
- PR requires 1 approval (for master)

### 4. Monitor CI Runs

View workflow runs:

```bash
# List recent workflow runs
gh run list --repo Qusto-io/qusto-analytics

# Watch a specific run
gh run watch <run-id>

# View logs
gh run view <run-id> --log
```

Or via GitHub UI:
https://github.com/Qusto-io/qusto-analytics/actions

### 5. Prepare Servers for Deployment

Before deployment can work, servers must be configured (Week 4, Tasks 4.1-4.3):

**Staging Server:**
- Provision Hetzner server
- Install dependencies (Elixir, PostgreSQL, ClickHouse, Redis)
- Configure SSH access
- Set up systemd service: `qusto-staging`
- Create directory: `/var/www/qusto/staging/`

**Production Server:**
- Provision Hetzner server
- Install dependencies
- Configure SSH access
- Set up systemd service: `qusto`
- Create directory: `/var/www/qusto/production/`

See: [CI_CD_SETUP.md](./CI_CD_SETUP.md) for detailed server requirements

### 6. Test Deployment (After Server Setup)

Once servers are ready and secrets are added:

**Automatic Staging Deployment:**
```bash
# Push to develop branch
git checkout develop
git pull origin develop
git merge your-feature-branch
git push origin develop

# Deployment workflow triggers automatically
# Monitor: https://github.com/Qusto-io/qusto-analytics/actions/workflows/deploy.yml
```

**Manual Production Deployment:**
```bash
# Via GitHub UI
1. Go to: https://github.com/Qusto-io/qusto-analytics/actions/workflows/deploy.yml
2. Click "Run workflow"
3. Select branch: main
4. Choose environment: production
5. Click "Run workflow"
6. Approve deployment when prompted

# Via GitHub CLI
gh workflow run deploy.yml --ref main
```

## CI/CD Workflow Summary

### Automated Checks on Every PR

1. **Build & Test** (Elixir CI)
   - Compiles application
   - Runs full test suite (6 partitions)
   - Tests both `test` and `ce_test` environments
   - Validates against PostgreSQL 18 and ClickHouse

2. **Static Analysis**
   - Code formatting (`mix format`)
   - Code quality (`mix credo`)
   - Type checking (`mix dialyzer`)
   - Unused dependencies check

3. **Security Scans**
   - Dependency vulnerabilities (`mix deps.audit`)
   - Elixir security issues (`mix sobelow`)

4. **Node/Frontend** (NPM CI)
   - TypeScript type checking
   - ESLint linting
   - Prettier format checking
   - Jest testing
   - Tracker build

### Deployment Process

**Staging (Automatic on `develop` push):**
1. Build production release
2. Backup current release
3. Upload new release
4. Stop service
5. Run migrations
6. Update symlink
7. Start service
8. Health check
9. Rollback if failed

**Production (Manual approval required):**
- Same process as staging
- Requires GitHub environment approval
- Triggered from `main` branch

## Troubleshooting

### CI Failures

**Test failures:**
```bash
# Run tests locally
mix test

# Run specific test
mix test test/path/to/test.exs:line_number
```

**Format issues:**
```bash
# Format code
mix format

# Check formatting
mix format --check-formatted
```

**Security scan failures:**
```bash
# Check dependencies
mix deps.audit

# Run security scan
mix sobelow --config
```

### Deployment Failures

**SSH connection issues:**
- Verify server is accessible: `ssh user@host`
- Check SSH key is correct
- Ensure key is added to server's `~/.ssh/authorized_keys`

**Health check failures:**
- Check application logs: `journalctl -u qusto -n 100`
- Verify database connections
- Check if migrations succeeded

**Rollback needed:**
```bash
# SSH to server
ssh deploy@your-server

# Manual rollback
sudo systemctl stop qusto
ln -sfn /var/www/qusto/backups/production/release_TIMESTAMP /var/www/qusto/production/current
sudo systemctl start qusto
```

## Documentation References

- **Comprehensive CI/CD Guide:** [CI_CD_SETUP.md](./CI_CD_SETUP.md)
- **Branch Protection Details:** [BRANCH_PROTECTION.md](./BRANCH_PROTECTION.md)
- **Deployment Workflow:** [.github/workflows/deploy.yml](../.github/workflows/deploy.yml)
- **Security Configuration:** [.sobelow-conf](../.sobelow-conf)

## Support

For issues or questions:
1. Check workflow logs in GitHub Actions
2. Review [CI_CD_SETUP.md](./CI_CD_SETUP.md)
3. Check server logs: `journalctl -u qusto -n 100`
4. Review this quick start guide

## Next Steps

- [ ] Add deployment secrets (run `./scripts/setup-github-secrets.sh`)
- [ ] Set up staging server (Week 4, Task 4.1-4.3)
- [ ] Set up production server (Week 4, Task 4.1-4.3)
- [ ] Test deployment to staging
- [ ] Configure monitoring and alerts
- [ ] Review and address Sobelow security findings

## Success Checklist

- [x] CI pipeline running on all PRs
- [x] Tests automated
- [x] Linting automated
- [x] Security scans automated
- [x] Branch protection enabled on master
- [x] Branch protection enabled on develop
- [ ] Deployment secrets configured
- [ ] Staging server ready
- [ ] Production server ready
- [ ] Successful test deployment to staging
- [ ] Monitoring configured
