#!/bin/bash
# Dynamic status line for JFL projects
# Shows: Project | Days to launch | Phase | Active team

set -e

# Get project name
PROJECT_NAME="JFL"
if [ -f ".jfl/config.json" ]; then
  PROJECT_NAME=$(jq -r '.name // "JFL"' .jfl/config.json 2>/dev/null || echo "JFL")
elif [ -f "knowledge/VISION.md" ]; then
  PROJECT_NAME=$(head -20 knowledge/VISION.md | grep '^# ' | head -1 | sed 's/^# //' || echo "JFL")
fi

# Get days to launch and phase from ROADMAP
DAYS=""
PHASE=""
if [ -f "knowledge/ROADMAP.md" ]; then
  # Extract launch date
  LAUNCH_DATE=$(grep -i "launch.*date\|ship.*date" knowledge/ROADMAP.md | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}|Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec' | head -1 || echo "")

  if [ -n "$LAUNCH_DATE" ]; then
    # Calculate days (rough estimate)
    if command -v date >/dev/null 2>&1; then
      if [[ "$LAUNCH_DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        LAUNCH_EPOCH=$(date -j -f "%Y-%m-%d" "$LAUNCH_DATE" "+%s" 2>/dev/null || echo "")
        if [ -n "$LAUNCH_EPOCH" ]; then
          NOW_EPOCH=$(date "+%s")
          DAYS_DIFF=$(( (LAUNCH_EPOCH - NOW_EPOCH) / 86400 ))
          DAYS="${DAYS_DIFF}d"
        fi
      fi
    fi
  fi

  # Extract current phase
  PHASE=$(grep -i "current.*phase\|phase.*:" knowledge/ROADMAP.md | head -1 | sed 's/.*://' | xargs | cut -c1-15 || echo "")
fi

# Get active team count
ACTIVE_TEAM=""
if command -v jfl >/dev/null 2>&1; then
  TEAM_COUNT=$(jfl context-hub sessions 2>/dev/null | grep -c "🟢\|🟡" || echo "0" | head -1 | tr -d '\n')
  TEAM_COUNT=${TEAM_COUNT:-0}
  if [ "$TEAM_COUNT" -gt 1 ] 2>/dev/null; then
    ACTIVE_TEAM="👥 $TEAM_COUNT"
  fi
fi

# Build status line
STATUS="$PROJECT_NAME"

if [ -n "$DAYS" ]; then
  STATUS="$STATUS | $DAYS"
fi

if [ -n "$PHASE" ]; then
  STATUS="$STATUS | $PHASE"
fi

if [ -n "$ACTIVE_TEAM" ]; then
  STATUS="$STATUS | $ACTIVE_TEAM"
fi

echo "$STATUS"
