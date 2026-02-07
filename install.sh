#!/bin/bash
# ===========================================================================
# disk2iso-metadata Module Installation Script
# ===========================================================================
# Installation script for Metadata Framework Module
# ===========================================================================

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Installation directory
INSTALL_DIR="${DISK2ISO_DIR:-/opt/disk2iso}"
MODULE_NAME="disk2iso-metadata"

echo -e "${GREEN}=== Installing $MODULE_NAME ===${NC}"

# Check if disk2iso is installed
if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "${RED}Error: disk2iso not found at $INSTALL_DIR${NC}"
    echo "Please install disk2iso first."
    exit 1
fi

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root${NC}"
    echo "Please use: sudo ./install.sh"
    exit 1
fi

echo -e "${YELLOW}Checking dependencies...${NC}"
# Check for required tools
MISSING_DEPS=""
for cmd in curl jq; do
    if ! command -v $cmd &> /dev/null; then
        MISSING_DEPS="$MISSING_DEPS $cmd"
    fi
done

if [ -n "$MISSING_DEPS" ]; then
    echo -e "${YELLOW}Missing dependencies:$MISSING_DEPS${NC}"
    echo "Installing dependencies..."
    apt-get update
    apt-get install -y curl jq
fi

echo -e "${YELLOW}Installing module files...${NC}"

# Copy library
cp -v lib/libmetadata.sh "$INSTALL_DIR/lib/"
chmod 755 "$INSTALL_DIR/lib/libmetadata.sh"

# Copy configuration
cp -v conf/libmetadata.ini "$INSTALL_DIR/conf/"
chmod 644 "$INSTALL_DIR/conf/libmetadata.ini"

# Copy language files
cp -v lang/libmetadata.* "$INSTALL_DIR/lang/"
chmod 644 "$INSTALL_DIR/lang/libmetadata".*

# Copy documentation
echo -e "${YELLOW}Installing documentation...${NC}"
cp -rv doc/04_Module "$INSTALL_DIR/doc/"
chmod 644 "$INSTALL_DIR/doc/04_Module/04-4_Metadaten.md"
if [ -d "doc/04_Module/04-4_Metadaten" ]; then
    chmod -R 644 "$INSTALL_DIR/doc/04_Module/04-4_Metadaten"/*.md
fi

# Copy web interface components (if exist)
if [ -d "www" ]; then
    echo -e "${YELLOW}Installing web interface components...${NC}"
    cp -rv www/* "$INSTALL_DIR/services/disk2iso-web/"
fi

echo -e "${GREEN}✓ $MODULE_NAME installed successfully${NC}"
echo ""
echo "This is the metadata framework module."
echo "To use metadata features, also install provider modules:"
echo "  - disk2iso-tmdb (for movie/TV show metadata)"
echo "  - disk2iso-musicbrainz (for audio CD metadata)"
echo ""
echo "Next steps:"
echo "1. Restart disk2iso service: systemctl restart disk2iso"
echo "2. Check module status: systemctl status disk2iso"
echo "3. View documentation: cat $INSTALL_DIR/doc/04_Module/04-4_Metadaten.md"
echo ""
echo "The module is now ready to use!"
