#!/bin/bash
set -e

# GitHub Secrets Setup Script for Qusto Analytics
# This script helps you add the required deployment secrets to GitHub
#
# Prerequisites:
# - GitHub CLI (gh) installed and authenticated
# - Repository: Qusto-io/qusto-analytics
# - Required permissions: Admin access to repository

REPO="Qusto-io/qusto-analytics"

echo "=========================================="
echo "GitHub Secrets Setup for Qusto Analytics"
echo "=========================================="
echo ""
echo "This script will help you add deployment secrets to the repository."
echo "You will be prompted to enter each secret value."
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ Error: GitHub CLI (gh) is not installed."
    echo "Install it from: https://cli.github.com/"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Error: Not authenticated with GitHub CLI."
    echo "Run: gh auth login"
    exit 1
fi

echo "✅ GitHub CLI is installed and authenticated"
echo ""

# Function to add a secret
add_secret() {
    local secret_name=$1
    local secret_description=$2

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Setting: $secret_name"
    echo "Description: $secret_description"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Check if secret already exists
    if gh secret list --repo "$REPO" | grep -q "^$secret_name"; then
        echo "⚠️  Secret already exists. Do you want to overwrite it? (y/n)"
        read -r overwrite
        if [[ "$overwrite" != "y" && "$overwrite" != "Y" ]]; then
            echo "⏭️  Skipping $secret_name"
            echo ""
            return
        fi
    fi

    echo "Enter the value for $secret_name:"
    echo "(The input will be hidden for security)"
    read -rs secret_value

    if [ -z "$secret_value" ]; then
        echo "⚠️  Empty value provided. Skipping."
        echo ""
        return
    fi

    # Add the secret
    echo "$secret_value" | gh secret set "$secret_name" --repo "$REPO"

    if [ $? -eq 0 ]; then
        echo "✅ Secret $secret_name added successfully"
    else
        echo "❌ Failed to add secret $secret_name"
    fi
    echo ""
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STAGING ENVIRONMENT SECRETS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

add_secret "STAGING_DEPLOY_HOST" "Staging server hostname or IP address (e.g., staging.qusto.io or 192.168.1.100)"
add_secret "STAGING_DEPLOY_USER" "SSH username for staging server (e.g., deploy or qusto)"
add_secret "STAGING_DEPLOY_SSH_KEY" "Private SSH key for staging server authentication (paste entire key including -----BEGIN and -----END)"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PRODUCTION ENVIRONMENT SECRETS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

add_secret "PRODUCTION_DEPLOY_HOST" "Production server hostname or IP address (e.g., qusto.io or 192.168.1.101)"
add_secret "PRODUCTION_DEPLOY_USER" "SSH username for production server (e.g., deploy or qusto)"
add_secret "PRODUCTION_DEPLOY_SSH_KEY" "Private SSH key for production server authentication (paste entire key including -----BEGIN and -----END)"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Verify your secrets:"
echo "  gh secret list --repo $REPO"
echo ""
echo "You can also view them in GitHub:"
echo "  https://github.com/$REPO/settings/secrets/actions"
echo ""
echo "Next steps:"
echo "  1. Test the deployment workflow by creating a PR to develop"
echo "  2. Monitor the GitHub Actions runs"
echo "  3. Check deployment logs for any issues"
echo ""
