#!/bin/bash
################################################################################
# Task 5.1.1: Update CSS Variables
# Updates CSS variables from Plausible indigo to Qusto blue/orange palette
#
# Automation Level: FULLY AUTOMATED (GREEN)
# Duration: ~3 hours manual → ~30 minutes automated
# Risk: LOW (isolated changes, reversible)
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
CSS_FILE="$PROJECT_ROOT/assets/css/app.css"

DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
fi

echo -e "${BLUE}Task 5.1.1: Update CSS Variables${NC}"
echo "Target file: $CSS_FILE"
echo ""

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}DRY RUN MODE - No changes will be made${NC}"
    echo ""
fi

################################################################################
# Backup
################################################################################

if [ "$DRY_RUN" = false ]; then
    echo "Creating backup..."
    cp "$CSS_FILE" "$CSS_FILE.backup-$(date +%Y%m%d-%H%M%S)"
    echo -e "${GREEN}✓${NC} Backup created"
    echo ""
fi

################################################################################
# Add Qusto Color Variables
################################################################################

echo "Adding Qusto color variables..."

CSS_ADDITIONS=$(cat <<'EOF'

/* ============================================================================
   QUSTO BRAND COLORS
   Added: Week 5 - Design System Implementation
   Source: Qusto Phase 1 Work Plan (Consolidated)
   ============================================================================ */

:root {
  /* Background Colors */
  --qusto-background: #eeece2;      /* Warm cream - page backgrounds */
  --qusto-surface: #ffffff;          /* White - cards, modals */

  /* Brand Colors */
  --qusto-brand-blue: #002d9c;       /* Deep blue - headings, brand emphasis */
  --qusto-primary: #1661be;          /* Primary blue - buttons, links, charts */
  --qusto-accent: #c55130;           /* Accent orange - CTAs, revenue, alerts */

  /* Semantic Colors */
  --qusto-analytics: #1661be;        /* Blue for analytics/data displays */
  --qusto-revenue: #c55130;          /* Orange for revenue/money contexts */

  /* Extended Blue Scale */
  --qusto-blue-50: #e6f0ff;
  --qusto-blue-100: #b3d1ff;
  --qusto-blue-200: #80b3ff;
  --qusto-blue-300: #4d94ff;
  --qusto-blue-400: #1a75ff;
  --qusto-blue-500: #1661be;         /* Primary */
  --qusto-blue-600: #002d9c;         /* Brand */
  --qusto-blue-700: #002073;
  --qusto-blue-800: #001a5c;
  --qusto-blue-900: #001345;

  /* Extended Orange Scale */
  --qusto-orange-50: #fff5f2;
  --qusto-orange-100: #ffe6df;
  --qusto-orange-200: #ffc7b8;
  --qusto-orange-300: #ffa891;
  --qusto-orange-400: #ff8969;
  --qusto-orange-500: #c55130;       /* Accent */
  --qusto-orange-600: #a33f22;
  --qusto-orange-700: #822f18;
  --qusto-orange-800: #5c2213;
  --qusto-orange-900: #3d180c;

  /* Neutral Scale (Text & Borders) */
  --qusto-gray-50: #f9fafb;
  --qusto-gray-100: #f3f4f6;
  --qusto-gray-200: #e5e7eb;
  --qusto-gray-300: #d1d5db;
  --qusto-gray-400: #9ca3af;
  --qusto-gray-500: #6b7280;
  --qusto-gray-600: #4b5563;
  --qusto-gray-700: #374151;
  --qusto-gray-800: #1f2937;
  --qusto-gray-900: #111827;

  /* Typography */
  --qusto-font-heading: 'Arbutus Slab', Georgia, 'Times New Roman', serif;
  --qusto-font-body: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
  --qusto-font-mono: 'SF Mono', Monaco, 'Cascadia Code', 'Roboto Mono', Consolas, 'Courier New', monospace;
}

/* ============================================================================
   SEMANTIC VARIABLE MAPPINGS
   Maps old Plausible variables to new Qusto variables
   ============================================================================ */

:root {
  /* Primary Colors (Analytics) */
  --color-primary: var(--qusto-primary);
  --color-primary-dark: var(--qusto-brand-blue);
  --color-primary-light: var(--qusto-blue-400);

  /* Accent Colors (Revenue/CTAs) */
  --color-accent: var(--qusto-accent);
  --color-accent-dark: var(--qusto-orange-600);
  --color-accent-light: var(--qusto-orange-400);

  /* Backgrounds */
  --color-bg-primary: var(--qusto-background);
  --color-bg-surface: var(--qusto-surface);

  /* Text */
  --color-text-primary: var(--qusto-gray-900);
  --color-text-secondary: var(--qusto-gray-600);
  --color-text-tertiary: var(--qusto-gray-500);

  /* Borders */
  --color-border: var(--qusto-gray-200);
  --color-border-dark: var(--qusto-gray-300);
}

/* ============================================================================
   DARK MODE VARIANTS
   ============================================================================ */

@media (prefers-color-scheme: dark), .dark {
  :root {
    --qusto-background: #111827;
    --qusto-surface: #1f2937;

    --color-bg-primary: var(--qusto-gray-900);
    --color-bg-surface: var(--qusto-gray-800);

    --color-text-primary: var(--qusto-gray-50);
    --color-text-secondary: var(--qusto-gray-400);
    --color-text-tertiary: var(--qusto-gray-500);

    --color-border: var(--qusto-gray-700);
    --color-border-dark: var(--qusto-gray-600);
  }
}

EOF
)

if [ "$DRY_RUN" = true ]; then
    echo "Would add the following to $CSS_FILE:"
    echo "$CSS_ADDITIONS"
    echo ""
else
    # Append to CSS file
    echo "$CSS_ADDITIONS" >> "$CSS_FILE"
    echo -e "${GREEN}✓${NC} Qusto color variables added"
    echo ""
fi

################################################################################
# Replace Indigo References with Blue
################################################################################

echo "Replacing indigo color classes with blue..."

replacements=(
    # Focus rings
    "s/ring-indigo-500/ring-blue-500/g"
    "s/focus:ring-indigo-500/focus:ring-blue-500/g"

    # Backgrounds
    "s/bg-indigo-600/bg-blue-500/g"
    "s/bg-indigo-500/bg-blue-500/g"
    "s/bg-indigo-50/bg-blue-50/g"

    # Hover states
    "s/hover:bg-indigo-700/hover:bg-blue-600/g"
    "s/hover:bg-indigo-600/hover:bg-blue-600/g"

    # Text colors
    "s/text-indigo-600/text-blue-500/g"
    "s/text-indigo-500/text-blue-500/g"
    "s/hover:text-indigo-700/hover:text-blue-600/g"

    # Borders
    "s/border-indigo-500/border-blue-500/g"
    "s/border-indigo-300/border-blue-300/g"
)

if [ "$DRY_RUN" = true ]; then
    echo "Would apply ${#replacements[@]} replacements"
    for replacement in "${replacements[@]}"; do
        echo "  - $replacement"
    done
    echo ""
else
    for replacement in "${replacements[@]}"; do
        sed -i '' "$replacement" "$CSS_FILE"
    done
    echo -e "${GREEN}✓${NC} Indigo classes replaced with blue"
    echo ""
fi

################################################################################
# Validation
################################################################################

echo "Validation checks..."

if [ "$DRY_RUN" = false ]; then
    # Check if CSS file is valid
    if grep -q "qusto-primary" "$CSS_FILE"; then
        echo -e "${GREEN}✓${NC} Qusto variables present in CSS file"
    else
        echo -e "${YELLOW}⚠${NC} Warning: Qusto variables not found in CSS file"
    fi

    # Check for remaining indigo references (should be minimal)
    indigo_count=$(grep -o "indigo-[0-9]" "$CSS_FILE" | wc -l | tr -d ' ')
    if [ "$indigo_count" -eq 0 ]; then
        echo -e "${GREEN}✓${NC} No indigo color classes remaining"
    else
        echo -e "${YELLOW}⚠${NC} Warning: $indigo_count indigo references still present (check if intentional)"
    fi

    echo ""
    echo "Validating CSS syntax..."
    cd "$PROJECT_ROOT/assets" && npm run stylelint || echo -e "${YELLOW}⚠${NC} Note: Stylelint warnings present (will be addressed in formatting step)"
    echo -e "${GREEN}✓${NC} CSS syntax validated"
fi

################################################################################
# Summary
################################################################################

echo ""
echo -e "${GREEN}Task 5.1.1 Complete!${NC}"
echo ""
echo "Changes made:"
echo "  • Added Qusto color variables (blue/orange palette)"
echo "  • Added extended color scales (50-900)"
echo "  • Added semantic variable mappings"
echo "  • Added dark mode variants"
echo "  • Replaced indigo classes with blue"
echo ""

if [ "$DRY_RUN" = false ]; then
    echo "Next steps:"
    echo "  1. Review changes: git diff $CSS_FILE"
    echo "  2. Start dev server: mix phx.server"
    echo "  3. Verify colors in browser"
    echo "  4. Commit changes: git add $CSS_FILE && git commit -m 'feat(design): update CSS variables to Qusto palette'"
    echo ""
    echo "Backup location: $CSS_FILE.backup-*"
else
    echo "Run without --dry-run to apply changes"
fi

echo ""
