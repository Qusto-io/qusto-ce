#!/usr/bin/env bash

# Qusto Branding Asset Replacement Script
# This script replaces Plausible branding assets with Qusto branding

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ASSETS_SOURCE="/Users/ac/Documents/Bizz/Ventures/qusto-project/10-design-ux/brand-guidelines/Visual Assets"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Qusto Branding Asset Replacement${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if source assets directory exists
if [ ! -d "$ASSETS_SOURCE" ]; then
    echo -e "${RED}Error: Source assets directory not found at:${NC}"
    echo -e "${RED}  $ASSETS_SOURCE${NC}"
    exit 1
fi

echo -e "${BLUE}Source assets:${NC} $ASSETS_SOURCE"
echo -e "${BLUE}Project root:${NC} $PROJECT_ROOT"
echo ""

# Function to safely copy file
copy_asset() {
    local src="$1"
    local dst="$2"
    local desc="$3"

    if [ ! -f "$src" ]; then
        echo -e "${YELLOW}  ⚠ Skipped:${NC} $desc (source not found: $(basename "$src"))"
        return 1
    fi

    # Create destination directory if it doesn't exist
    mkdir -p "$(dirname "$dst")"

    # Backup original if it exists
    if [ -f "$dst" ]; then
        local backup_dir="$PROJECT_ROOT/backups/original-branding-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$backup_dir/$(dirname "${dst#$PROJECT_ROOT/}")"
        cp "$dst" "$backup_dir/$(dirname "${dst#$PROJECT_ROOT/}")/"
    fi

    # Copy the new asset
    cp "$src" "$dst"
    echo -e "${GREEN}  ✓ Replaced:${NC} $desc"
    return 0
}

# Function to convert SVG logos to PNGs for favicons if needed
convert_svg_to_png() {
    local src_svg="$1"
    local dst_png="$2"
    local size="$3"

    # Check if ImageMagick or inkscape is available
    if command -v convert &> /dev/null; then
        convert -background none -resize "${size}x${size}" "$src_svg" "$dst_png"
        return 0
    elif command -v inkscape &> /dev/null; then
        inkscape -w "$size" -h "$size" "$src_svg" -o "$dst_png" 2>/dev/null
        return 0
    else
        echo -e "${YELLOW}  ⚠ Warning: ImageMagick or Inkscape not found. Cannot convert SVG to PNG.${NC}"
        echo -e "${YELLOW}    Please install ImageMagick (brew install imagemagick) or Inkscape.${NC}"
        return 1
    fi
}

echo -e "${BLUE}Step 1: Replacing Logo Files${NC}"
echo -e "${BLUE}=============================${NC}"

# Community Edition (CE) Logos
copy_asset \
    "$ASSETS_SOURCE/qusto_logo_full_v3.svg" \
    "$PROJECT_ROOT/priv/static/images/ce/logo_dark.svg" \
    "CE Dark Mode Logo"

copy_asset \
    "$ASSETS_SOURCE/qusto_logo_full_v3.svg" \
    "$PROJECT_ROOT/priv/static/images/ce/logo_light.svg" \
    "CE Light Mode Logo"

# Enterprise Edition (EE) Logos
copy_asset \
    "$ASSETS_SOURCE/qusto_logo_full_v3.svg" \
    "$PROJECT_ROOT/priv/static/images/ee/logo_dark.svg" \
    "EE Dark Mode Logo"

copy_asset \
    "$ASSETS_SOURCE/qusto_logo_full_v3.svg" \
    "$PROJECT_ROOT/priv/static/images/ee/logo_light.svg" \
    "EE Light Mode Logo"

echo ""
echo -e "${BLUE}Step 2: Replacing Favicon Files${NC}"
echo -e "${BLUE}================================${NC}"

# Root favicon
if [ -f "$ASSETS_SOURCE/favicon-16x16.png" ]; then
    # If we have a 16x16 favicon, create .ico from it
    if command -v convert &> /dev/null; then
        convert "$ASSETS_SOURCE/favicon-16x16.png" "$ASSETS_SOURCE/favicon-32x32.png" \
                "$PROJECT_ROOT/priv/static/favicon.ico" 2>/dev/null || \
        copy_asset "$ASSETS_SOURCE/favicon-32x32.png" "$PROJECT_ROOT/priv/static/favicon.ico" "Root Favicon"
    else
        copy_asset "$ASSETS_SOURCE/favicon-32x32.png" "$PROJECT_ROOT/priv/static/favicon.ico" "Root Favicon"
    fi
fi

# Community Edition (CE) Favicons
copy_asset \
    "$ASSETS_SOURCE/favicon-16x16.png" \
    "$PROJECT_ROOT/priv/static/images/ce/favicon-16x16.png" \
    "CE Favicon 16x16"

copy_asset \
    "$ASSETS_SOURCE/favicon-32x32.png" \
    "$PROJECT_ROOT/priv/static/images/ce/favicon-32x32.png" \
    "CE Favicon 32x32"

# Create multi-resolution .ico for CE
if command -v convert &> /dev/null && [ -f "$ASSETS_SOURCE/favicon-16x16.png" ] && [ -f "$ASSETS_SOURCE/favicon-32x32.png" ]; then
    convert "$ASSETS_SOURCE/favicon-16x16.png" "$ASSETS_SOURCE/favicon-32x32.png" \
            "$PROJECT_ROOT/priv/static/images/ce/favicon.ico" 2>/dev/null && \
    echo -e "${GREEN}  ✓ Created:${NC} CE Multi-resolution Favicon (.ico)"
fi

# Enterprise Edition (EE) Favicons
copy_asset \
    "$ASSETS_SOURCE/favicon-16x16.png" \
    "$PROJECT_ROOT/priv/static/images/ee/favicon-16x16.png" \
    "EE Favicon 16x16"

copy_asset \
    "$ASSETS_SOURCE/favicon-32x32.png" \
    "$PROJECT_ROOT/priv/static/images/ee/favicon-32x32.png" \
    "EE Favicon 32x32"

# Create multi-resolution .ico for EE
if command -v convert &> /dev/null && [ -f "$ASSETS_SOURCE/favicon-16x16.png" ] && [ -f "$ASSETS_SOURCE/favicon-32x32.png" ]; then
    convert "$ASSETS_SOURCE/favicon-16x16.png" "$ASSETS_SOURCE/favicon-32x32.png" \
            "$PROJECT_ROOT/priv/static/images/ee/favicon.ico" 2>/dev/null && \
    echo -e "${GREEN}  ✓ Created:${NC} EE Multi-resolution Favicon (.ico)"
fi

echo ""
echo -e "${BLUE}Step 3: Replacing Apple Touch Icons${NC}"
echo -e "${BLUE}====================================${NC}"

# Apple Touch Icons (180x180 standard)
copy_asset \
    "$ASSETS_SOURCE/apple-touch-icon.png" \
    "$PROJECT_ROOT/priv/static/images/ce/apple-touch-icon.png" \
    "CE Apple Touch Icon"

copy_asset \
    "$ASSETS_SOURCE/apple-touch-icon.png" \
    "$PROJECT_ROOT/priv/static/images/ee/apple-touch-icon.png" \
    "EE Apple Touch Icon"

echo ""
echo -e "${BLUE}Step 4: Additional Assets (Optional)${NC}"
echo -e "${BLUE}=====================================${NC}"

# Android Chrome Icons (if available)
copy_asset \
    "$ASSETS_SOURCE/android-chrome-192x192.png" \
    "$PROJECT_ROOT/priv/static/images/ce/android-chrome-192x192.png" \
    "CE Android Chrome 192x192" || true

copy_asset \
    "$ASSETS_SOURCE/android-chrome-512x512.png" \
    "$PROJECT_ROOT/priv/static/images/ce/android-chrome-512x512.png" \
    "CE Android Chrome 512x512" || true

copy_asset \
    "$ASSETS_SOURCE/android-chrome-192x192.png" \
    "$PROJECT_ROOT/priv/static/images/ee/android-chrome-192x192.png" \
    "EE Android Chrome 192x192" || true

copy_asset \
    "$ASSETS_SOURCE/android-chrome-512x512.png" \
    "$PROJECT_ROOT/priv/static/images/ee/android-chrome-512x512.png" \
    "EE Android Chrome 512x512" || true

# Email header image (if available)
copy_asset \
    "$ASSETS_SOURCE/email-header.png" \
    "$PROJECT_ROOT/priv/static/images/email-header.png" \
    "Email Header Image" || true

# OG Image (Open Graph for social media)
copy_asset \
    "$ASSETS_SOURCE/og-image.png" \
    "$PROJECT_ROOT/priv/static/images/og-image.png" \
    "Open Graph Image" || true

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Asset Replacement Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "1. Review the replaced assets in your browser"
echo "2. Clear browser cache for accurate testing"
echo "3. Test both CE and EE builds if applicable"
echo "4. Commit the changes when satisfied"
echo ""

# Check if backups were created
if [ -d "$PROJECT_ROOT/backups/original-branding-"* 2>/dev/null ]; then
    echo -e "${BLUE}Backup:${NC} Original branding assets backed up to:"
    ls -dt "$PROJECT_ROOT/backups/original-branding-"* 2>/dev/null | head -1
    echo ""
fi

echo -e "${YELLOW}Note:${NC} If any assets were skipped, you may need to:"
echo "  - Create missing asset sizes from the source SVG/PNG"
echo "  - Install ImageMagick for automatic conversion: brew install imagemagick"
echo ""
