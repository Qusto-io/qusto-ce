#!/bin/bash
################################################################################
# Week 5 Validation Framework
# Comprehensive validation checkpoints for Tasks 5.1-5.4
#
# Usage:
#   ./validate.sh --checkpoint css-variables
#   ./validate.sh --checkpoint color-migration
#   ./validate.sh --checkpoint logos
#   ./validate.sh --checkpoint text
#   ./validate.sh --checkpoint production-ready
#   ./validate.sh --all
#
# Version: 1.0
# Date: February 3, 2026
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

PASSED=0
FAILED=0
WARNINGS=0

################################################################################
# Helper Functions
################################################################################

pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

################################################################################
# Checkpoint 1: CSS Variables
################################################################################

validate_css_variables() {
    echo -e "${BLUE}=== Checkpoint 1: CSS Variables ===${NC}"
    echo ""

    local css_file="$PROJECT_ROOT/assets/css/app.css"

    # Check if CSS file exists
    if [ ! -f "$css_file" ]; then
        fail "CSS file not found: $css_file"
        return
    fi
    pass "CSS file exists"

    # Check for Qusto variables
    if grep -q "qusto-primary" "$css_file"; then
        pass "Qusto primary color variable present"
    else
        fail "Qusto primary color variable missing"
    fi

    if grep -q "qusto-accent" "$css_file"; then
        pass "Qusto accent color variable present"
    else
        fail "Qusto accent color variable missing"
    fi

    if grep -q "qusto-font-heading" "$css_file"; then
        pass "Qusto font variables present"
    else
        fail "Qusto font variables missing"
    fi

    # Check for dark mode support
    if grep -q "prefers-color-scheme: dark" "$css_file"; then
        pass "Dark mode support present"
    else
        warn "Dark mode support not found"
    fi

    # Try to compile assets
    info "Compiling assets..."
    cd "$PROJECT_ROOT/assets"
    if npm run build > /dev/null 2>&1; then
        pass "Asset compilation successful"
    else
        fail "Asset compilation failed"
    fi

    # Check bundle size
    local css_bundle="$PROJECT_ROOT/priv/static/assets/app.css"
    if [ -f "$css_bundle" ]; then
        local size=$(wc -c < "$css_bundle" | tr -d ' ')
        local size_kb=$((size / 1024))
        if [ $size_kb -lt 100 ]; then
            pass "CSS bundle size acceptable (${size_kb}KB)"
        else
            warn "CSS bundle size large (${size_kb}KB)"
        fi
    fi

    echo ""
}

################################################################################
# Checkpoint 2: Color Migration
################################################################################

validate_color_migration() {
    echo -e "${BLUE}=== Checkpoint 2: Color Migration ===${NC}"
    echo ""

    # Check for remaining indigo references
    info "Scanning for remaining indigo color references..."

    local css_indigo=$(git grep -n 'indigo-[0-9]' -- '*.css' 2>/dev/null | wc -l | tr -d ' ')
    local tsx_indigo=$(git grep -n 'indigo-[0-9]' -- '*.tsx' '*.ts' '*.jsx' '*.js' 2>/dev/null | wc -l | tr -d ' ')
    local template_indigo=$(git grep -n 'indigo-[0-9]' -- '*.heex' '*.eex' 2>/dev/null | wc -l | tr -d ' ')

    if [ "$css_indigo" -eq 0 ]; then
        pass "No indigo references in CSS files"
    else
        fail "Found $css_indigo indigo references in CSS files"
    fi

    if [ "$tsx_indigo" -eq 0 ]; then
        pass "No indigo references in JS/TS files"
    else
        warn "Found $tsx_indigo indigo references in JS/TS files (may be acceptable in tests/comments)"
    fi

    if [ "$template_indigo" -eq 0 ]; then
        pass "No indigo references in template files"
    else
        fail "Found $template_indigo indigo references in template files"
    fi

    # Check for hardcoded hex values
    info "Checking for hardcoded Plausible hex values..."

    local hex_refs=$(git grep -n '#6366f1\|#4f46e5\|#4338ca' -- '*.tsx' '*.ts' '*.js' '*.css' '*.heex' 2>/dev/null | wc -l | tr -d ' ')

    if [ "$hex_refs" -eq 0 ]; then
        pass "No hardcoded Plausible hex values found"
    else
        fail "Found $hex_refs hardcoded Plausible hex values"
        git grep -n '#6366f1\|#4f46e5\|#4338ca' -- '*.tsx' '*.ts' '*.js' '*.css' '*.heex' 2>/dev/null | head -5
    fi

    # Check for Qusto color usage
    if git grep -q "qusto-blue\|qusto-orange" -- '*.css' 2>/dev/null; then
        pass "Qusto colors being used in CSS"
    else
        warn "Qusto colors may not be actively used yet"
    fi

    echo ""
}

################################################################################
# Checkpoint 3: Logos
################################################################################

validate_logos() {
    echo -e "${BLUE}=== Checkpoint 3: Logo Assets ===${NC}"
    echo ""

    local logo_dir_ce="$PROJECT_ROOT/priv/static/images/ce"
    local logo_dir_ee="$PROJECT_ROOT/priv/static/images/ee"

    # Check CE logos
    if [ -f "$logo_dir_ce/logo_dark.svg" ]; then
        pass "CE dark logo exists"
    else
        fail "CE dark logo missing"
    fi

    if [ -f "$logo_dir_ce/logo_light.svg" ]; then
        pass "CE light logo exists"
    else
        fail "CE light logo missing"
    fi

    if [ -f "$logo_dir_ce/favicon.ico" ]; then
        pass "CE favicon exists"
    else
        fail "CE favicon missing"
    fi

    # Check EE logos
    if [ -f "$logo_dir_ee/logo_dark.svg" ]; then
        pass "EE dark logo exists"
    else
        fail "EE dark logo missing"
    fi

    if [ -f "$logo_dir_ee/logo_light.svg" ]; then
        pass "EE light logo exists"
    else
        fail "EE light logo missing"
    fi

    # Check for "Plausible" in logo alt text
    local plausible_logo_refs=$(git grep -n "Plausible logo" -- '*.heex' '*.eex' 2>/dev/null | wc -l | tr -d ' ')

    if [ "$plausible_logo_refs" -eq 0 ]; then
        pass "No 'Plausible logo' alt text found"
    else
        fail "Found $plausible_logo_refs references to 'Plausible logo' (should be 'Qusto logo')"
    fi

    echo ""
}

################################################################################
# Checkpoint 4: Text Replacement
################################################################################

validate_text() {
    echo -e "${BLUE}=== Checkpoint 4: Text Replacement ===${NC}"
    echo ""

    # Check for remaining "Plausible" text (excluding AGPL attribution)
    info "Scanning for remaining 'Plausible' text references..."

    local plausible_refs=$(git grep -n "Plausible" -- '*.heex' '*.eex' '*.ex' 2>/dev/null \
        | grep -v "github.com/plausible" \
        | grep -v "AGPL" \
        | grep -v "LICENSE" \
        | grep -v "based on Plausible" \
        | wc -l | tr -d ' ')

    if [ "$plausible_refs" -eq 0 ]; then
        pass "No inappropriate 'Plausible' references found"
    else
        warn "Found $plausible_refs 'Plausible' references (review if they're appropriate)"
        git grep -n "Plausible" -- '*.heex' '*.eex' '*.ex' 2>/dev/null \
            | grep -v "github.com/plausible" \
            | grep -v "AGPL" \
            | grep -v "LICENSE" \
            | head -5
    fi

    # Check for AGPL attribution
    if git grep -q "based on Plausible" 2>/dev/null; then
        pass "AGPL attribution present"
    else
        fail "AGPL attribution missing (required for compliance)"
    fi

    # Check email templates
    local plausible_emails=$(git grep -n "The Plausible Team" -- 'lib/plausible_web/templates/email' 2>/dev/null | wc -l | tr -d ' ')

    if [ "$plausible_emails" -eq 0 ]; then
        pass "Email templates updated to 'The Qusto Team'"
    else
        fail "Found $plausible_emails email templates still using 'The Plausible Team'"
    fi

    echo ""
}

################################################################################
# Checkpoint 5: Production Ready
################################################################################

validate_production_ready() {
    echo -e "${BLUE}=== Checkpoint 5: Production Readiness ===${NC}"
    echo ""

    # Run Elixir tests
    info "Running Elixir tests..."
    cd "$PROJECT_ROOT"
    if mix test > /dev/null 2>&1; then
        pass "Elixir tests passing"
    else
        fail "Elixir tests failing"
    fi

    # Run JavaScript tests (if configured)
    if [ -f "$PROJECT_ROOT/assets/package.json" ] && grep -q '"test"' "$PROJECT_ROOT/assets/package.json"; then
        info "Running JavaScript tests..."
        cd "$PROJECT_ROOT/assets"
        if npm test > /dev/null 2>&1; then
            pass "JavaScript tests passing"
        else
            warn "JavaScript tests failing or not configured"
        fi
    else
        info "JavaScript tests not configured"
    fi

    # Check for compilation errors
    info "Checking production build..."
    cd "$PROJECT_ROOT"
    if MIX_ENV=prod mix compile > /dev/null 2>&1; then
        pass "Production compilation successful"
    else
        fail "Production compilation failed"
    fi

    # Check asset build
    cd "$PROJECT_ROOT/assets"
    if npm run build > /dev/null 2>&1; then
        pass "Asset build successful"
    else
        fail "Asset build failed"
    fi

    # Check for TODO/FIXME comments added during rebrand
    local todos=$(git grep -n "TODO\|FIXME" -- '*.ex' '*.tsx' '*.ts' '*.css' 2>/dev/null | wc -l | tr -d ' ')
    info "Found $todos TODO/FIXME comments"

    # Performance check (if Lighthouse is available)
    if command -v lighthouse &> /dev/null; then
        info "Lighthouse is available for performance testing"
    else
        info "Lighthouse not available (install for performance validation)"
    fi

    echo ""
}

################################################################################
# Main Execution
################################################################################

CHECKPOINT=""
RUN_ALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --checkpoint)
            CHECKPOINT="$2"
            shift 2
            ;;
        --all)
            RUN_ALL=true
            shift
            ;;
        --help)
            echo "Week 5 Validation Framework"
            echo ""
            echo "Usage:"
            echo "  ./validate.sh --checkpoint css-variables    # Validate CSS variables"
            echo "  ./validate.sh --checkpoint color-migration  # Validate color migration"
            echo "  ./validate.sh --checkpoint logos            # Validate logo assets"
            echo "  ./validate.sh --checkpoint text             # Validate text replacement"
            echo "  ./validate.sh --checkpoint production-ready # Full production validation"
            echo "  ./validate.sh --all                         # Run all checkpoints"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Week 5 Validation Framework v1.0     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

if [ "$RUN_ALL" = true ]; then
    validate_css_variables
    validate_color_migration
    validate_logos
    validate_text
    validate_production_ready
elif [ -n "$CHECKPOINT" ]; then
    case "$CHECKPOINT" in
        css-variables)
            validate_css_variables
            ;;
        color-migration)
            validate_color_migration
            ;;
        logos)
            validate_logos
            ;;
        text)
            validate_text
            ;;
        production-ready)
            validate_production_ready
            ;;
        *)
            echo "Unknown checkpoint: $CHECKPOINT"
            exit 1
            ;;
    esac
else
    echo "Please specify --checkpoint or --all"
    echo "Use --help for usage information"
    exit 1
fi

################################################################################
# Summary
################################################################################

echo -e "${BLUE}=== Validation Summary ===${NC}"
echo ""
echo -e "${GREEN}Passed:${NC}   $PASSED"
echo -e "${YELLOW}Warnings:${NC} $WARNINGS"
echo -e "${RED}Failed:${NC}   $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All critical checks passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some checks failed. Please review and fix.${NC}"
    exit 1
fi
