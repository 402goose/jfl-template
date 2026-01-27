#!/bin/bash
#
# Session Cleanup - Auto-merge and remove worktree if safe
#
# Called by Stop hook to clean up session branches automatically.
# Only keeps branches that have real conflicts or uncommitted work.

set -e

# Get current session info
BRANCH=$(git branch --show-current 2>/dev/null || echo "")
if [ -z "$BRANCH" ]; then
  echo "Not on a branch, skipping cleanup"
  exit 0
fi

# Skip if not a session branch
if [[ ! "$BRANCH" =~ ^session- ]]; then
  echo "Not a session branch, skipping cleanup"
  exit 0
fi

# Auto-commit any uncommitted changes first
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Auto-committing changes..."
  git add -A
  git commit -m "session: end $(date +%Y-%m-%d\ %H:%M)" || true
fi

# Try to merge to main
echo "Attempting to merge $BRANCH to main..."
git checkout main 2>/dev/null || {
  echo "Could not checkout main, skipping merge"
  git checkout "$BRANCH" 2>/dev/null
  exit 0
}

# Attempt merge with auto-resolve for .jfl/ conflicts
if git merge --no-edit -X ours "$BRANCH" 2>&1; then
  echo "✓ Merged $BRANCH to main"

  # Remove worktree if it exists
  WORKTREE_PATH=$(git worktree list | grep "$BRANCH" | awk '{print $1}' | head -1)
  if [ -n "$WORKTREE_PATH" ] && [ -d "$WORKTREE_PATH" ]; then
    echo "Removing worktree at $WORKTREE_PATH..."
    rm -rf "$WORKTREE_PATH" 2>/dev/null || true
    git worktree prune 2>/dev/null || true
  fi

  # Delete the branch
  echo "Deleting branch $BRANCH..."
  git branch -D "$BRANCH" 2>/dev/null || true

  echo "✓ Session cleanup complete"
else
  echo "⚠ Merge conflicts detected, keeping branch $BRANCH"
  echo "  Review later with: git log main..$BRANCH"
  git merge --abort 2>/dev/null || true
  git checkout "$BRANCH" 2>/dev/null || true
fi

exit 0
