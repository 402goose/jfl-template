#!/usr/bin/env bash
#
# sync-template.sh - Sync product/template to jfl-template repo
#
# Usage:
#   ./scripts/sync-template.sh "commit message"
#
# This pushes template changes to 402goose/jfl-template so all
# jfl init/update users get the changes.
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE_SOURCE="$REPO_DIR/product/template"
TEMPLATE_REPO="git@github.com:402goose/jfl-template.git"
TEMP_DIR="/tmp/jfl-template-sync-$$"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Get commit message
COMMIT_MSG="${1:-sync: update template from product/template}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Syncing template to jfl-template repo"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Verify source exists
if [[ ! -d "$TEMPLATE_SOURCE" ]]; then
    echo -e "${RED}Error:${NC} product/template not found at $TEMPLATE_SOURCE"
    exit 1
fi

# Clone template repo
echo -e "${CYAN}→${NC} Cloning jfl-template..."
rm -rf "$TEMP_DIR"
git clone --depth 1 "$TEMPLATE_REPO" "$TEMP_DIR" 2>/dev/null

# Clear existing files (except .git)
echo -e "${CYAN}→${NC} Clearing old files..."
find "$TEMP_DIR" -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} +

# Copy new files
echo -e "${CYAN}→${NC} Copying from product/template..."
cp -r "$TEMPLATE_SOURCE"/* "$TEMP_DIR"/
cp -r "$TEMPLATE_SOURCE"/.[!.]* "$TEMP_DIR"/ 2>/dev/null || true

# Show what changed
cd "$TEMP_DIR"
echo ""
echo "Changes:"
git status --short

# Check if there are changes
if git diff --quiet && git diff --cached --quiet && [[ -z "$(git status --porcelain)" ]]; then
    echo -e "${YELLOW}No changes to sync.${NC}"
    rm -rf "$TEMP_DIR"
    exit 0
fi

# Commit and push
echo ""
echo -e "${CYAN}→${NC} Committing: $COMMIT_MSG"
git add -A
git commit -m "$COMMIT_MSG

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"

echo -e "${CYAN}→${NC} Pushing to origin..."
git push origin main

# Cleanup
rm -rf "$TEMP_DIR"

echo ""
echo -e "${GREEN}✓${NC} Template synced to jfl-template repo"
echo ""
echo "Users will get these changes on:"
echo "  - jfl init (new projects)"
echo "  - jfl update (existing projects)"
echo ""
