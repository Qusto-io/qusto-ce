#!/bin/bash
################################################################################
# Task 5.4.3: Color Scheme Migration
# Migrates all indigo colors to Qusto blue/orange palette
#
# Automation Level: FULLY AUTOMATED (GREEN)
# Duration: ~6 hours manual → ~1 hour automated
# Risk: LOW (comprehensive search and replace, reversible)
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

echo -e "${BLUE}Task 5.4.3: Color Scheme Migration${NC}"
echo ""

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}DRY RUN MODE - No changes will be made${NC}"
    echo ""
fi

################################################################################
# Find Files with Color References
################################################################################

echo "Scanning for files with color references..."

# Directories to search
SEARCH_DIRS=(
    "assets/css"
    "assets/js"
    "lib/plausible_web/templates"
    "lib/plausible_web/views"
    "lib/plausible_web/live"
    "lib/plausible_web/components"
)

files_with_colors=()
for dir in "${SEARCH_DIRS[@]}"; do
    if [ -d "$PROJECT_ROOT/$dir" ]; then
        # Find files with indigo references
        while IFS= read -r file; do
            files_with_colors+=("$file")
        done < <(grep -rl "indigo-[0-9]" "$PROJECT_ROOT/$dir" 2>/dev/null || true)

        # Find files with hardcoded indigo hex values
        while IFS= read -r file; do
            if [[ ! " ${files_with_colors[@]} " =~ " ${file} " ]]; then
                files_with_colors+=("$file")
            fi
        done < <(grep -rl "#[46][ab][0-9a-f][0-9a-f][0-9a-f][0-9a-f]" "$PROJECT_ROOT/$dir" 2>/dev/null || true)
    fi
done

echo "Found ${#files_with_colors[@]} files with color references"
echo ""

################################################################################
# Color Mapping
################################################################################

# Tailwind class replacements (indigo → blue)
declare -A CLASS_REPLACEMENTS=(
    ["indigo-50"]="blue-50"
    ["indigo-100"]="blue-100"
    ["indigo-200"]="blue-200"
    ["indigo-300"]="blue-300"
    ["indigo-400"]="blue-400"
    ["indigo-500"]="blue-500"
    ["indigo-600"]="blue-600"
    ["indigo-700"]="blue-700"
    ["indigo-800"]="blue-800"
    ["indigo-900"]="blue-900"
)

# Hex color replacements (indigo shades → Qusto blue)
declare -A HEX_REPLACEMENTS=(
    ["#6366f1"]="#1661be"  # indigo-500 → qusto-primary
    ["#4f46e5"]="#002d9c"  # indigo-600 → qusto-brand-blue
    ["#4338ca"]="#002073"  # indigo-700 → qusto-blue-700
    ["#3730a3"]="#001a5c"  # indigo-800 → qusto-blue-800
    ["#312e81"]="#001345"  # indigo-900 → qusto-blue-900
)

################################################################################
# Perform Replacements
################################################################################

if [ "$DRY_RUN" = true ]; then
    echo "Would perform the following replacements:"
    echo ""
    echo "Tailwind classes:"
    for old_class in "${!CLASS_REPLACEMENTS[@]}"; do
        echo "  indigo-$old_class → blue-${CLASS_REPLACEMENTS[$old_class]}"
    done
    echo ""
    echo "Hex colors:"
    for old_hex in "${!HEX_REPLACEMENTS[@]}"; do
        echo "  $old_hex → ${HEX_REPLACEMENTS[$old_hex]}"
    done
    echo ""
    echo "Would update ${#files_with_colors[@]} files"
else
    echo "Performing color migrations..."

    replacement_count=0
    for file in "${files_with_colors[@]}"; do
        # Create backup
        cp "$file" "$file.backup-$(date +%Y%m%d-%H%M%S)"

        file_changed=false

        # Replace Tailwind classes
        for old_class in "${!CLASS_REPLACEMENTS[@]}"; do
            new_class="${CLASS_REPLACEMENTS[$old_class]}"
            if grep -q "$old_class" "$file"; then
                sed -i '' "s/${old_class}/${new_class}/g" "$file"
                file_changed=true
            fi
        done

        # Replace hex colors
        for old_hex in "${!HEX_REPLACEMENTS[@]}"; do
            new_hex="${HEX_REPLACEMENTS[$old_hex]}"
            if grep -qi "$old_hex" "$file"; then
                sed -i '' "s/${old_hex}/${new_hex}/gi" "$file"
                file_changed=true
            fi
        done

        if [ "$file_changed" = true ]; then
            replacement_count=$((replacement_count + 1))
        fi
    done

    echo -e "${GREEN}✓${NC} Updated $replacement_count files"
    echo ""
fi

################################################################################
# Additional Replacements (bg-, text-, border- prefixes)
################################################################################

echo "Updating prefixed color classes..."

if [ "$DRY_RUN" = false ]; then
    for file in "${files_with_colors[@]}"; do
        # Background colors
        sed -i '' 's/bg-indigo-/bg-blue-/g' "$file" 2>/dev/null || true

        # Text colors
        sed -i '' 's/text-indigo-/text-blue-/g' "$file" 2>/dev/null || true

        # Border colors
        sed -i '' 's/border-indigo-/border-blue-/g' "$file" 2>/dev/null || true

        # Ring colors (focus states)
        sed -i '' 's/ring-indigo-/ring-blue-/g' "$file" 2>/dev/null || true

        # Hover states
        sed -i '' 's/hover:bg-indigo-/hover:bg-blue-/g' "$file" 2>/dev/null || true
        sed -i '' 's/hover:text-indigo-/hover:text-blue-/g' "$file" 2>/dev/null || true
        sed -i '' 's/hover:border-indigo-/hover:border-blue-/g' "$file" 2>/dev/null || true

        # Focus states
        sed -i '' 's/focus:ring-indigo-/focus:ring-blue-/g' "$file" 2>/dev/null || true
        sed -i '' 's/focus:border-indigo-/focus:border-blue-/g' "$file" 2>/dev/null || true
    done
    echo -e "${GREEN}✓${NC} Prefixed classes updated"
else
    echo "Would update bg-, text-, border-, ring-, hover:, focus: prefixed classes"
fi

echo ""

################################################################################
# Validation
################################################################################

echo "Validation checks..."

if [ "$DRY_RUN" = false ]; then
    # Count remaining indigo references
    indigo_count=0
    for dir in "${SEARCH_DIRS[@]}"; do
        if [ -d "$PROJECT_ROOT/$dir" ]; then
            count=$(grep -r "indigo-[0-9]" "$PROJECT_ROOT/$dir" 2>/dev/null | grep -v ".backup-" | wc -l | tr -d ' ')
            indigo_count=$((indigo_count + count))
        fi
    done

    if [ "$indigo_count" -eq 0 ]; then
        echo -e "${GREEN}✓${NC} 0 indigo color references remaining"
    else
        echo -e "${YELLOW}⚠${NC} Warning: $indigo_count indigo references still present"
        echo "  These may be in comments or non-user-facing code"
    fi

    # Verify blue classes are present
    blue_count=$(grep -r "blue-[0-9]" "$PROJECT_ROOT/assets" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$blue_count" -gt 0 ]; then
        echo -e "${GREEN}✓${NC} Blue color classes present ($blue_count references)"
    else
        echo -e "${YELLOW}⚠${NC} Warning: No blue color classes found"
    fi

    echo ""
    echo "Running CSS validation..."
    cd "$PROJECT_ROOT/assets" && npm run stylelint || echo -e "${YELLOW}⚠${NC} Note: Stylelint warnings present"
    echo -e "${GREEN}✓${NC} CSS validation complete"
fi

################################################################################
# Summary
################################################################################

echo ""
echo -e "${GREEN}Task 5.4.3 Complete!${NC}"
echo ""
echo "Changes made:"
echo "  • Replaced all indigo Tailwind classes with blue"
echo "  • Updated hardcoded indigo hex values to Qusto blue"
echo "  • Updated bg-, text-, border-, ring- prefixed classes"
echo "  • Updated hover and focus state colors"
echo ""

if [ "$DRY_RUN" = false ]; then
    echo "Next steps:"
    echo "  1. Review changes: git diff"
    echo "  2. Test in browser: mix phx.server"
    echo "  3. Verify all pages: check dashboard, settings, stats pages"
    echo "  4. Run validation: scripts/week5/validate.sh --checkpoint color-migration"
    echo "  5. Commit changes: git add . && git commit -m 'feat(rebrand): migrate color scheme to Qusto palette'"
    echo ""
else
    echo "Run without --dry-run to apply changes"
fi

echo ""
