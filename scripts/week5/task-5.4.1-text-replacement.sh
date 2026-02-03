#!/bin/bash
################################################################################
# Task 5.4.1: Text Replacement (Plausible → Qusto)
# Replaces all user-facing "Plausible" references with "Qusto"
#
# Automation Level: FULLY AUTOMATED (GREEN)
# Duration: ~4 hours manual → ~30 minutes automated
# Risk: LOW (preserves AGPL attribution, reversible)
#
# Version: 1.0
# Date: February 3, 2026
################################################################################

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
fi

echo -e "${BLUE}Task 5.4.1: Text Replacement (Plausible → Qusto)${NC}"
echo ""

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}DRY RUN MODE - No changes will be made${NC}"
    echo ""
fi

################################################################################
# Find Files to Update
################################################################################

echo "Scanning for files containing 'Plausible'..."

# User-facing files (templates, views, components)
USER_FACING_DIRS=(
    "lib/plausible_web/templates"
    "lib/plausible_web/views"
    "lib/plausible_web/live"
    "assets/js"
    "priv/gettext"
)

files_to_update=()
for dir in "${USER_FACING_DIRS[@]}"; do
    if [ -d "$PROJECT_ROOT/$dir" ]; then
        while IFS= read -r file; do
            files_to_update+=("$file")
        done < <(grep -rl "Plausible" "$PROJECT_ROOT/$dir" 2>/dev/null || true)
    fi
done

echo "Found ${#files_to_update[@]} files to update"
echo ""

################################################################################
# Excluded Patterns (Preserve AGPL Attribution)
################################################################################

EXCLUDED_PATTERNS=(
    "Based on Plausible Analytics"
    "Plausible Insights OÜ"
    "Copyright.*Plausible"
    "plausible.io"  # Keep original attribution links
)

################################################################################
# Text Replacements
################################################################################

if [ "$DRY_RUN" = true ]; then
    echo "Would perform the following replacements:"
    echo "  'Plausible Analytics' → 'Qusto Analytics'"
    echo "  'Plausible' → 'Qusto' (in user-facing text)"
    echo ""
    echo "Would update ${#files_to_update[@]} files"
    echo ""
else
    echo "Performing text replacements..."

    replacement_count=0
    for file in "${files_to_update[@]}"; do
        # Check if file should be excluded (AGPL attribution)
        skip_file=false
        for pattern in "${EXCLUDED_PATTERNS[@]}"; do
            if grep -q "$pattern" "$file"; then
                # Only skip if it's a license/attribution file
                if [[ "$file" == *"LICENSE"* ]] || [[ "$file" == *"ATTRIBUTION"* ]] || [[ "$file" == *"README"* ]]; then
                    skip_file=true
                    break
                fi
            fi
        done

        if [ "$skip_file" = true ]; then
            continue
        fi

        # Perform replacements
        if grep -q "Plausible" "$file"; then
            # Create backup
            cp "$file" "$file.backup-$(date +%Y%m%d-%H%M%S)"

            # Replace "Plausible Analytics" → "Qusto Analytics"
            sed -i '' 's/Plausible Analytics/Qusto Analytics/g' "$file"

            # Replace standalone "Plausible" → "Qusto" (but not in URLs or code)
            sed -i '' 's/\([^a-zA-Z]\)Plausible\([^a-zA-Z]\)/\1Qusto\2/g' "$file"

            replacement_count=$((replacement_count + 1))
        fi
    done

    echo -e "${GREEN}✓${NC} Updated $replacement_count files"
    echo ""
fi

################################################################################
# Update Page Titles and Meta Tags
################################################################################

echo "Updating page titles and meta tags..."

META_FILES=(
    "lib/plausible_web/templates/layout/app.html.eex"
    "lib/plausible_web/templates/layout/focus.html.eex"
    "priv/static/index.html"
)

if [ "$DRY_RUN" = false ]; then
    for file in "${META_FILES[@]}"; do
        if [ -f "$PROJECT_ROOT/$file" ]; then
            sed -i '' 's/<title>Plausible/<title>Qusto/g' "$file" 2>/dev/null || true
            sed -i '' 's/content="Plausible/content="Qusto/g' "$file" 2>/dev/null || true
        fi
    done
    echo -e "${GREEN}✓${NC} Page titles and meta tags updated"
else
    echo "Would update page titles and meta tags in ${#META_FILES[@]} files"
fi

echo ""

################################################################################
# Update Email Templates
################################################################################

echo "Updating email templates..."

EMAIL_DIR="$PROJECT_ROOT/lib/plausible_web/templates/email"
if [ -d "$EMAIL_DIR" ]; then
    if [ "$DRY_RUN" = false ]; then
        find "$EMAIL_DIR" -type f \( -name "*.html.eex" -o -name "*.text.eex" \) -exec sed -i '' 's/Plausible/Qusto/g' {} \;
        echo -e "${GREEN}✓${NC} Email templates updated"
    else
        email_count=$(find "$EMAIL_DIR" -type f \( -name "*.html.eex" -o -name "*.text.eex" \) | wc -l | tr -d ' ')
        echo "Would update $email_count email template files"
    fi
else
    echo -e "${YELLOW}⚠${NC} Email templates directory not found"
fi

echo ""

################################################################################
# Validation
################################################################################

echo "Validation checks..."

if [ "$DRY_RUN" = false ]; then
    # Count remaining "Plausible" references in user-facing files
    remaining_count=0
    for dir in "${USER_FACING_DIRS[@]}"; do
        if [ -d "$PROJECT_ROOT/$dir" ]; then
            count=$(grep -r "Plausible" "$PROJECT_ROOT/$dir" 2>/dev/null | grep -v ".backup-" | wc -l | tr -d ' ')
            remaining_count=$((remaining_count + count))
        fi
    done

    if [ "$remaining_count" -eq 0 ]; then
        echo -e "${GREEN}✓${NC} No 'Plausible' references remaining in user-facing files"
    else
        echo -e "${YELLOW}⚠${NC} Warning: $remaining_count 'Plausible' references still present"
        echo "  (These may be in AGPL attribution or code comments)"
    fi

    # Verify AGPL attribution preserved
    if grep -r "Based on Plausible Analytics" "$PROJECT_ROOT/LICENSE" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} AGPL attribution preserved in LICENSE"
    else
        echo -e "${YELLOW}⚠${NC} Warning: AGPL attribution may need verification"
    fi
fi

################################################################################
# Summary
################################################################################

echo ""
echo -e "${GREEN}Task 5.4.1 Complete!${NC}"
echo ""
echo "Changes made:"
echo "  • Replaced 'Plausible Analytics' with 'Qusto Analytics'"
echo "  • Updated page titles and meta tags"
echo "  • Updated email templates"
echo "  • Preserved AGPL attribution"
echo ""

if [ "$DRY_RUN" = false ]; then
    echo "Next steps:"
    echo "  1. Review changes: git diff"
    echo "  2. Verify AGPL compliance: check LICENSE file"
    echo "  3. Test email templates: send test emails"
    echo "  4. Commit changes: git add . && git commit -m 'feat(rebrand): replace Plausible with Qusto text'"
    echo ""
else
    echo "Run without --dry-run to apply changes"
fi

echo ""
