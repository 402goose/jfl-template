#!/bin/bash
# time-audit.sh - Analyze where time is going based on git commits
#
# Usage:
#   ./scripts/time-audit.sh              # Today
#   ./scripts/time-audit.sh --week       # This week
#   ./scripts/time-audit.sh --since "2026-01-15"

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Default to today
SINCE="$(date +%Y-%m-%d) 00:00"

case "${1:-}" in
    --week)
        SINCE="$(date -v-7d +%Y-%m-%d) 00:00"
        ;;
    --since)
        SINCE="$2"
        ;;
esac

cd "$PROJECT_ROOT"

echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  TIME AUDIT - Since $SINCE${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Count total commits (excluding auto-noise)
TOTAL=$(git log --since="$SINCE" --oneline | grep -v "session: end" | grep -v "auto:" | grep -v "auto-save" | wc -l | tr -d ' ')
TOTAL_WITH_NOISE=$(git log --since="$SINCE" --oneline | wc -l | tr -d ' ')
NOISE=$((TOTAL_WITH_NOISE - TOTAL))

# Categories
INFRA=$(git log --since="$SINCE" --oneline | grep -v "session: end" | grep -v "auto:" | grep -iE "fix:|session|worktree|submodule|daemon|debug:" | wc -l | tr -d ' ')
FEATURES=$(git log --since="$SINCE" --oneline | grep -iE "feat:|US-[0-9]+" | wc -l | tr -d ' ')
PRODUCT_FEATURES=$(git -C product log --since="$SINCE" --oneline 2>/dev/null | grep -iE "feat:|US-[0-9]+" | wc -l | tr -d ' ')
FEATURES=$((FEATURES + PRODUCT_FEATURES))
DOCS=$(git log --since="$SINCE" --oneline | grep -iE "docs:|spec|prd" | wc -l | tr -d ' ')
PRODUCT_DOCS=$(git -C product log --since="$SINCE" --oneline 2>/dev/null | grep -iE "docs:|spec|prd" | wc -l | tr -d ' ')
DOCS=$((DOCS + PRODUCT_DOCS))
CONTENT=$(git log --since="$SINCE" --oneline | grep -iE "transcript|call|content|skill|thread|article" | wc -l | tr -d ' ')

# Calculate percentages
if [ "$TOTAL" -gt 0 ]; then
    INFRA_PCT=$((INFRA * 100 / TOTAL))
    FEATURES_PCT=$((FEATURES * 100 / TOTAL))
    DOCS_PCT=$((DOCS * 100 / TOTAL))
    CONTENT_PCT=$((CONTENT * 100 / TOTAL))
else
    INFRA_PCT=0
    FEATURES_PCT=0
    DOCS_PCT=0
    CONTENT_PCT=0
fi

echo -e "${BOLD}COMMIT BREAKDOWN${NC}"
echo ""
printf "  %-25s %5d  (%3d%%)\n" "Infrastructure/Bugs" "$INFRA" "$INFRA_PCT"
printf "  %-25s %5d  (%3d%%)\n" "Features (US-xxx)" "$FEATURES" "$FEATURES_PCT"
printf "  %-25s %5d  (%3d%%)\n" "Docs/Specs/PRDs" "$DOCS" "$DOCS_PCT"
printf "  %-25s %5d  (%3d%%)\n" "Content/Outreach" "$CONTENT" "$CONTENT_PCT"
echo "  ─────────────────────────────────"
printf "  %-25s %5d\n" "Total (real work)" "$TOTAL"
printf "  %-25s %5d  ${YELLOW}(noise)${NC}\n" "Auto-commits filtered" "$NOISE"
echo ""

# Warnings
echo -e "${BOLD}HEALTH CHECK${NC}"
echo ""

if [ "$INFRA_PCT" -gt 50 ]; then
    echo -e "  ${RED}⚠ $INFRA_PCT% on infrastructure - too high!${NC}"
    echo "    You should be building product, not fighting tools."
elif [ "$INFRA_PCT" -gt 25 ]; then
    echo -e "  ${YELLOW}⚠ $INFRA_PCT% on infrastructure - watch this${NC}"
else
    echo -e "  ${GREEN}✓ $INFRA_PCT% on infrastructure - healthy${NC}"
fi

if [ "$CONTENT_PCT" -lt 10 ]; then
    echo -e "  ${RED}⚠ Only $CONTENT_PCT% on content/outreach${NC}"
    echo "    Are you talking to customers? Creating content?"
elif [ "$CONTENT_PCT" -lt 25 ]; then
    echo -e "  ${YELLOW}⚠ $CONTENT_PCT% on content - could be higher${NC}"
else
    echo -e "  ${GREEN}✓ $CONTENT_PCT% on content/outreach - good${NC}"
fi

echo ""

# Recent high-value work
echo -e "${BOLD}RECENT HIGH-VALUE WORK${NC}"
echo ""
echo "  Features:"
git log --since="$SINCE" --pretty=format:"    %s" | grep -iE "feat:|US-[0-9]+" | head -5 || echo "    (none)"
echo ""
echo "  Content/Outreach:"
git log --since="$SINCE" --pretty=format:"    %s" | grep -iE "transcript|call|content|skill" | head -5 || echo "    (none)"
echo ""

# What ate your time
echo -e "${BOLD}WHAT ATE YOUR TIME${NC}"
echo ""
echo "  Bug fixes:"
git log --since="$SINCE" --pretty=format:"    %s" | grep -iE "fix:|resolve:|debug:" | head -5 || echo "    (none)"
echo ""

echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  Multiplier math:"
echo "    Infrastructure: ${INFRA} commits × 0x = 0 units"
echo "    Features:       ${FEATURES} commits × 2x = $((FEATURES * 2)) units"
echo "    Docs/Specs:     ${DOCS} commits × 5x = $((DOCS * 5)) units"
echo "    Content:        ${CONTENT} commits × 10x = $((CONTENT * 10)) units"
echo "    ─────────────────────────────────"
TOTAL_UNITS=$((FEATURES * 2 + DOCS * 5 + CONTENT * 10))
echo -e "    ${BOLD}Total output: $TOTAL_UNITS units${NC}"
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
