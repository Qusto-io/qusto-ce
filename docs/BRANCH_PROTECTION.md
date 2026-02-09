# GitHub Branch Protection Configuration

## Overview

This guide provides step-by-step instructions for configuring branch protection rules for the Qusto Analytics repository. Branch protection ensures code quality by requiring CI checks to pass and pull request reviews before merging.

## Prerequisites

- Repository admin access
- CI/CD pipelines configured and running (see [CI_CD_SETUP.md](./CI_CD_SETUP.md))

## Protected Branches

The following branches require protection:
- `main` (or `master`) - Production releases
- `develop` - Staging/development branch
- `stable` - Stable releases

## Configuration Steps

### Step 1: Access Repository Settings

1. Navigate to the repository on GitHub
2. Click **Settings** tab
3. Click **Branches** in the left sidebar
4. Click **Add branch protection rule**

### Step 2: Configure Main/Master Branch

**Branch name pattern:** `main` (or `master`)

#### Protect matching branches

Enable these settings:

✅ **Require a pull request before merging**
- Require approvals: **1**
- ✅ Dismiss stale pull request approvals when new commits are pushed
- ✅ Require review from Code Owners (if CODEOWNERS file exists)
- ❌ Require approval of the most recent reviewable push
- ❌ Require conversation resolution before merging

✅ **Require status checks to pass before merging**
- ✅ Require branches to be up to date before merging

**Required status checks:**
Select these status checks to require before merging:

From `Elixir CI` workflow:
- `build (test, postgres:18, 1)` through `build (test, postgres:18, 6)` (all 6 partitions)
- `build (ce_test, postgres:18, 1)` through `build (ce_test, postgres:18, 6)` (all 6 partitions)
- `static`
- `security`

From `NPM CI` workflow:
- `build`

> **Note:** Status checks appear after the first run. Run the workflows once, then return to add them as required checks.

✅ **Require conversation resolution before merging**
- Ensures all review comments are addressed

✅ **Require signed commits**
- Optional but recommended for security

✅ **Require linear history**
- Prevents merge commits, enforces rebase or squash

✅ **Require deployments to succeed before merging**
- Optional: Can require staging deployment to succeed

#### Rules applied to administrators

❌ **Do not allow bypassing the above settings**
- Administrators must follow the same rules (recommended)

#### Restrict who can push to matching branches

❌ **Restrict pushes that create matching branches**
- Leave unchecked to allow creating the branch

#### Block force pushes

✅ **Block force pushes**
- Prevent force pushes to maintain history

#### Allow deletions

❌ **Allow deletions**
- Prevent accidental branch deletion

### Step 3: Configure Develop Branch

**Branch name pattern:** `develop`

Apply similar settings as main branch:

✅ **Require status checks to pass before merging**
- ✅ Require branches to be up to date before merging
- Add all required status checks (same as main)

✅ **Require linear history**

✅ **Block force pushes**

❌ **Allow deletions**

**Differences from main:**
- **Pull request reviews:** Optional (can be 0 for faster development)
- **Signed commits:** Optional

### Step 4: Configure Stable Branch

**Branch name pattern:** `stable`

Apply same settings as main branch (see Step 2).

### Step 5: Save and Verify

1. Click **Create** or **Save changes**
2. Test by creating a pull request
3. Verify required checks appear and block merging until passing

## Verification Checklist

After configuring branch protection, verify:

- [ ] Create a test pull request to `main`
- [ ] Verify CI checks run automatically
- [ ] Verify pull request cannot be merged until checks pass
- [ ] Verify pull request requires approval
- [ ] Try force pushing to protected branch (should fail)
- [ ] Try deleting protected branch (should fail)

## GitHub CLI Configuration (Alternative)

You can also configure branch protection using the GitHub CLI:

```bash
# Install GitHub CLI
brew install gh

# Authenticate
gh auth login

# Configure main branch protection
gh api repos/qusto-io/qusto-analytics/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["build (test, postgres:18, 1)","build (test, postgres:18, 2)","build (test, postgres:18, 3)","build (test, postgres:18, 4)","build (test, postgres:18, 5)","build (test, postgres:18, 6)","build (ce_test, postgres:18, 1)","build (ce_test, postgres:18, 2)","build (ce_test, postgres:18, 3)","build (ce_test, postgres:18, 4)","build (ce_test, postgres:18, 5)","build (ce_test, postgres:18, 6)","static","security","build"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"dismiss_stale_reviews":true,"require_code_owner_reviews":true,"required_approving_review_count":1}' \
  --field restrictions=null \
  --field required_linear_history=true \
  --field allow_force_pushes=false \
  --field allow_deletions=false

# Configure develop branch protection
gh api repos/qusto-io/qusto-analytics/branches/develop/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["build (test, postgres:18, 1)","build (test, postgres:18, 2)","build (test, postgres:18, 3)","build (test, postgres:18, 4)","build (test, postgres:18, 5)","build (test, postgres:18, 6)","build (ce_test, postgres:18, 1)","build (ce_test, postgres:18, 2)","build (ce_test, postgres:18, 3)","build (ce_test, postgres:18, 4)","build (ce_test, postgres:18, 5)","build (ce_test, postgres:18, 6)","static","security","build"]}' \
  --field enforce_admins=false \
  --field required_pull_request_reviews=null \
  --field restrictions=null \
  --field required_linear_history=true \
  --field allow_force_pushes=false \
  --field allow_deletions=false
```

## Terraform Configuration (Alternative)

For infrastructure-as-code approach:

```hcl
# terraform/github_branch_protection.tf

resource "github_branch_protection" "main" {
  repository_id = github_repository.qusto_analytics.node_id
  pattern       = "main"

  required_status_checks {
    strict   = true
    contexts = [
      "build (test, postgres:18, 1)",
      "build (test, postgres:18, 2)",
      "build (test, postgres:18, 3)",
      "build (test, postgres:18, 4)",
      "build (test, postgres:18, 5)",
      "build (test, postgres:18, 6)",
      "build (ce_test, postgres:18, 1)",
      "build (ce_test, postgres:18, 2)",
      "build (ce_test, postgres:18, 3)",
      "build (ce_test, postgres:18, 4)",
      "build (ce_test, postgres:18, 5)",
      "build (ce_test, postgres:18, 6)",
      "static",
      "security",
      "build", # Node CI
    ]
  }

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = true
    required_approving_review_count = 1
  }

  enforce_admins        = true
  require_signed_commits = true
  require_linear_history = true

  allows_deletions    = false
  allows_force_pushes = false
}

resource "github_branch_protection" "develop" {
  repository_id = github_repository.qusto_analytics.node_id
  pattern       = "develop"

  required_status_checks {
    strict   = true
    contexts = [
      "build (test, postgres:18, 1)",
      "build (test, postgres:18, 2)",
      "build (test, postgres:18, 3)",
      "build (test, postgres:18, 4)",
      "build (test, postgres:18, 5)",
      "build (test, postgres:18, 6)",
      "build (ce_test, postgres:18, 1)",
      "build (ce_test, postgres:18, 2)",
      "build (ce_test, postgres:18, 3)",
      "build (ce_test, postgres:18, 4)",
      "build (ce_test, postgres:18, 5)",
      "build (ce_test, postgres:18, 6)",
      "static",
      "security",
      "build",
    ]
  }

  enforce_admins         = false
  require_linear_history = true

  allows_deletions    = false
  allows_force_pushes = false
}
```

## Common Issues and Troubleshooting

### Issue: Status checks not appearing

**Solution:**
1. Push code to trigger workflows
2. Wait for workflows to complete
3. Return to branch protection settings
4. Status checks should now appear in the dropdown

### Issue: Cannot merge even though checks pass

**Possible causes:**
- Branch is not up to date with base branch
- Required reviewers haven't approved
- Conversations not resolved

**Solution:**
1. Update branch: `git pull origin main && git push`
2. Request review from code owners
3. Resolve all review comments

### Issue: Administrators cannot bypass protection

**Solution:**
- Temporarily disable "Do not allow bypassing the above settings"
- Make necessary changes
- Re-enable protection

### Issue: Too many required status checks

**Solution:**
- Review and remove non-essential checks
- Combine checks where possible
- Use workflow-level checks instead of job-level

## Best Practices

1. **Start strict, relax if needed**
   - Begin with all protections enabled
   - Relax rules only if they hinder productivity

2. **Regular reviews**
   - Review protection rules quarterly
   - Update as CI/CD pipeline evolves

3. **Document exceptions**
   - Document why certain checks are not required
   - Keep this document updated

4. **Monitor compliance**
   - Track force push attempts
   - Review admin bypass actions
   - Audit branch protection changes

5. **Team training**
   - Ensure all contributors understand rules
   - Document common workflows (rebase, squash, etc.)
   - Provide troubleshooting guides

## Environment-Specific Protection

### Development Environments

For development/feature branches, consider lighter protection:
- No required reviews
- Optional status checks
- Allow force pushes (for rebasing)

### Release Branches

Pattern: `release/*`

Apply strict protection:
- Require all checks
- Require multiple reviewers (2+)
- No force pushes
- No deletions

## Rollout Strategy

**Phase 1: Staging (Week 1)**
- Enable on `develop` branch only
- Monitor impact on development velocity
- Gather team feedback

**Phase 2: Production (Week 2)**
- Enable on `main` branch
- Apply strict rules
- Document any issues

**Phase 3: Refinement (Week 3-4)**
- Adjust based on feedback
- Add/remove status checks as needed
- Update documentation

## Success Criteria

Branch protection is properly configured when:

- ✅ No direct pushes to `main` or `develop`
- ✅ All PRs require CI checks to pass
- ✅ Code review process enforced
- ✅ Force pushes blocked
- ✅ Branch deletions blocked
- ✅ Commit history maintained (linear)
- ✅ Security scans required
- ✅ Test coverage maintained

## References

- [GitHub Branch Protection Documentation](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/defining-the-mergeability-of-pull-requests/about-protected-branches)
- [GitHub CLI Reference](https://cli.github.com/manual/gh_api)
- [Terraform GitHub Provider](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/branch_protection)

## Support

For questions or issues:
1. Check [CI_CD_SETUP.md](./CI_CD_SETUP.md)
2. Contact DevOps team
3. Create issue in repository
