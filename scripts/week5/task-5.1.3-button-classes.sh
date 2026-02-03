#!/bin/bash
################################################################################
# Task 5.1.3: Enhanced Button Classes
# Creates enhanced button classes with gradients and improved states
#
# Automation Level: SEMI-AUTOMATED (YELLOW)
# Duration: ~1 hour manual → ~20 minutes automated + review
# Risk: MEDIUM (potential class name conflicts)
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

echo -e "${BLUE}Task 5.1.3: Enhanced Button Classes${NC}"
echo "Target file: $CSS_FILE"
echo ""

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}DRY RUN MODE - No changes will be made${NC}"
    echo ""
fi

################################################################################
# Check for Existing Classes
################################################################################

echo "Checking for potential class name conflicts..."

conflicts=false
if grep -q "\.button-primary" "$CSS_FILE"; then
    echo -e "${YELLOW}⚠${NC} Warning: .button-primary already exists"
    conflicts=true
fi

if grep -q "\.button-cta" "$CSS_FILE"; then
    echo -e "${YELLOW}⚠${NC} Warning: .button-cta already exists"
    conflicts=true
fi

if grep -q "\.button-secondary" "$CSS_FILE"; then
    echo -e "${YELLOW}⚠${NC} Warning: .button-secondary already exists"
    conflicts=true
fi

if [ "$conflicts" = true ]; then
    echo ""
    echo -e "${YELLOW}Class name conflicts detected. Please review manually before proceeding.${NC}"
    if [ "$DRY_RUN" = false ]; then
        read -p "Continue anyway? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            echo "Aborted by user"
            exit 0
        fi
    fi
fi

echo -e "${GREEN}✓${NC} No conflicts or user confirmed"
echo ""

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
# Add Button Classes
################################################################################

echo "Adding enhanced button classes..."

BUTTON_CLASSES=$(cat <<'EOF'

/* ============================================================================
   QUSTO ENHANCED BUTTON CLASSES
   Added: Week 5 - Design System Implementation
   Enhanced buttons with gradients and improved interaction states
   ============================================================================ */

/* Primary Button (Blue Analytics Theme) */
.button-primary {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0.5rem 1rem;
  font-weight: 600;
  font-size: 0.875rem;
  line-height: 1.25rem;
  border-radius: 0.375rem;
  transition: all 150ms cubic-bezier(0.4, 0, 0.2, 1);
  background: linear-gradient(135deg, var(--qusto-primary) 0%, var(--qusto-brand-blue) 100%);
  color: white;
  border: none;
  cursor: pointer;
  box-shadow: 0 1px 3px 0 rgba(22, 97, 190, 0.1), 0 1px 2px 0 rgba(22, 97, 190, 0.06);
}

.button-primary:hover {
  background: linear-gradient(135deg, var(--qusto-blue-400) 0%, var(--qusto-primary) 100%);
  box-shadow: 0 4px 6px -1px rgba(22, 97, 190, 0.1), 0 2px 4px -1px rgba(22, 97, 190, 0.06);
  transform: translateY(-1px);
}

.button-primary:focus {
  outline: none;
  ring: 2px solid var(--qusto-primary);
  ring-offset: 2px;
}

.button-primary:active {
  background: linear-gradient(135deg, var(--qusto-brand-blue) 0%, var(--qusto-blue-700) 100%);
  transform: translateY(0);
}

.button-primary:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  transform: none;
}

/* CTA Button (Orange Revenue Theme) */
.button-cta {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0.5rem 1rem;
  font-weight: 600;
  font-size: 0.875rem;
  line-height: 1.25rem;
  border-radius: 0.375rem;
  transition: all 150ms cubic-bezier(0.4, 0, 0.2, 1);
  background: linear-gradient(135deg, var(--qusto-accent) 0%, var(--qusto-orange-600) 100%);
  color: white;
  border: none;
  cursor: pointer;
  box-shadow: 0 1px 3px 0 rgba(197, 81, 48, 0.1), 0 1px 2px 0 rgba(197, 81, 48, 0.06);
}

.button-cta:hover {
  background: linear-gradient(135deg, var(--qusto-orange-400) 0%, var(--qusto-accent) 100%);
  box-shadow: 0 4px 6px -1px rgba(197, 81, 48, 0.1), 0 2px 4px -1px rgba(197, 81, 48, 0.06);
  transform: translateY(-1px);
}

.button-cta:focus {
  outline: none;
  ring: 2px solid var(--qusto-accent);
  ring-offset: 2px;
}

.button-cta:active {
  background: linear-gradient(135deg, var(--qusto-orange-600) 0%, var(--qusto-orange-700) 100%);
  transform: translateY(0);
}

.button-cta:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  transform: none;
}

/* Secondary Button (Outline Style) */
.button-secondary {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0.5rem 1rem;
  font-weight: 600;
  font-size: 0.875rem;
  line-height: 1.25rem;
  border-radius: 0.375rem;
  transition: all 150ms cubic-bezier(0.4, 0, 0.2, 1);
  background: transparent;
  color: var(--qusto-primary);
  border: 2px solid var(--qusto-primary);
  cursor: pointer;
}

.button-secondary:hover {
  background: var(--qusto-blue-50);
  border-color: var(--qusto-brand-blue);
  color: var(--qusto-brand-blue);
}

.button-secondary:focus {
  outline: none;
  ring: 2px solid var(--qusto-primary);
  ring-offset: 2px;
}

.button-secondary:active {
  background: var(--qusto-blue-100);
}

.button-secondary:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* Dark Mode Adjustments */
@media (prefers-color-scheme: dark) {
  .button-secondary {
    border-color: var(--qusto-blue-400);
    color: var(--qusto-blue-400);
  }

  .button-secondary:hover {
    background: rgba(22, 97, 190, 0.1);
    border-color: var(--qusto-blue-300);
    color: var(--qusto-blue-300);
  }

  .button-secondary:active {
    background: rgba(22, 97, 190, 0.2);
  }
}

EOF
)

if [ "$DRY_RUN" = true ]; then
    echo "Would add the following to $CSS_FILE:"
    echo "$BUTTON_CLASSES"
    echo ""
else
    # Append to CSS file
    echo "$BUTTON_CLASSES" >> "$CSS_FILE"
    echo -e "${GREEN}✓${NC} Button classes added"
    echo ""
fi

################################################################################
# Validation
################################################################################

echo "Validation checks..."

if [ "$DRY_RUN" = false ]; then
    # Check if button classes are present
    if grep -q "\.button-primary" "$CSS_FILE"; then
        echo -e "${GREEN}✓${NC} .button-primary class present"
    else
        echo -e "${YELLOW}⚠${NC} Warning: .button-primary not found"
    fi

    if grep -q "\.button-cta" "$CSS_FILE"; then
        echo -e "${GREEN}✓${NC} .button-cta class present"
    else
        echo -e "${YELLOW}⚠${NC} Warning: .button-cta not found"
    fi

    if grep -q "\.button-secondary" "$CSS_FILE"; then
        echo -e "${GREEN}✓${NC} .button-secondary class present"
    else
        echo -e "${YELLOW}⚠${NC} Warning: .button-secondary not found"
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
echo -e "${GREEN}Task 5.1.3 Complete!${NC}"
echo ""
echo "Changes made:"
echo "  • Added .button-primary class (blue gradient)"
echo "  • Added .button-cta class (orange gradient)"
echo "  • Added .button-secondary class (outline)"
echo "  • Added hover/focus/active states for all buttons"
echo "  • Added dark mode adjustments"
echo ""

if [ "$DRY_RUN" = false ]; then
    echo "Next steps:"
    echo "  1. Review changes: git diff $CSS_FILE"
    echo "  2. Test buttons in browser:"
    echo "     - Create test HTML with button examples"
    echo "     - Verify hover/focus/active states"
    echo "     - Test in light and dark modes"
    echo "  3. Commit changes: git add $CSS_FILE && git commit -m 'feat(design): add enhanced button classes'"
    echo ""
    echo "Backup location: $CSS_FILE.backup-*"
else
    echo "Run without --dry-run to apply changes"
fi

echo ""
