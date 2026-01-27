#!/bin/bash
#
# Worktree session manager for GTM collaboration
# Creates isolated git worktrees for each Claude Code session
#
# Usage:
#   ./scripts/worktree-session.sh create [USER]        # Create new session
#   ./scripts/worktree-session.sh list                 # List active sessions
#   ./scripts/worktree-session.sh remove SESSION_NAME  # Remove a session
#   ./scripts/worktree-session.sh cleanup              # Remove old sessions (7+ days)
#   ./scripts/worktree-session.sh end SESSION_NAME     # End session gracefully

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKTREES_DIR="$REPO_DIR/worktrees"

cd "$REPO_DIR" || exit 1

# Generate session name with random ID
generate_session_name() {
    local user="${1:-$(git config user.name | tr ' ' '-' | tr '[:upper:]' '[:lower:]')}"
    local date=$(date +%Y%m%d)
    local time=$(date +%H%M)
    # Generate 6 random hex characters
    local random=$(openssl rand -hex 3 2>/dev/null || printf "%06x" $RANDOM$RANDOM)
    echo "session-${user}-${date}-${time}-${random}"
}

create_session() {
    local user="${1:-}"
    local session_name=$(generate_session_name "$user")
    local worktree_path="$WORKTREES_DIR/$session_name"

    echo "Creating new session: $session_name"
    echo ""

    # Create worktree
    if git worktree add "$worktree_path" -b "$session_name" 2>&1; then
        echo "✓ Worktree created: $worktree_path"
    else
        echo "✗ Failed to create worktree"
        exit 1
    fi

    # Start auto-commit in the worktree
    cd "$worktree_path" || exit 1
    if ../../scripts/auto-commit.sh start; then
        echo "✓ Auto-commit started"
    else
        echo "✗ Failed to start auto-commit"
    fi

    # Start auto-merge for this session
    cd "$REPO_DIR" || exit 1
    if ./scripts/auto-merge.sh start "$session_name"; then
        echo "✓ Auto-merge started"
    else
        echo "✗ Failed to start auto-merge"
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Session ready!"
    echo ""
    echo "Work in: $worktree_path"
    echo "Branch: $session_name"
    echo ""
    echo "Auto-commit: Every 5 minutes"
    echo "Auto-merge: Every 15 minutes"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "To work in this session:"
    echo "  cd $worktree_path"
    echo ""
    echo "To end this session:"
    echo "  ./scripts/worktree-session.sh end $session_name"
    echo ""

    # Return the session name for Claude to use
    echo "$session_name" > /tmp/last-session-name.txt
}

list_sessions() {
    echo "Active worktree sessions:"
    echo ""

    if [[ ! -d "$WORKTREES_DIR" ]] || [[ -z "$(ls -A "$WORKTREES_DIR" 2>/dev/null | grep -v README.md | grep -v .gitkeep)" ]]; then
        echo "  (no active sessions)"
        return 0
    fi

    for worktree in "$WORKTREES_DIR"/session-*; do
        if [[ -d "$worktree" ]]; then
            local session_name=$(basename "$worktree")
            local auto_commit_status="✗"
            local auto_merge_status="✗"

            # Check auto-commit
            if [[ -f "$worktree/.auto-commit.pid" ]] && kill -0 "$(cat "$worktree/.auto-commit.pid")" 2>/dev/null; then
                auto_commit_status="✓"
            fi

            # Check auto-merge
            if [[ -f "$worktree/.auto-merge.pid" ]] && kill -0 "$(cat "$worktree/.auto-merge.pid")" 2>/dev/null; then
                auto_merge_status="✓"
            fi

            # Check for conflicts
            local conflict_marker=""
            if [[ -f "$worktree/.merge-conflict" ]]; then
                conflict_marker=" ⚠️  CONFLICT"
            fi

            # Get last activity
            local last_commit=$(git log -1 --format="%cr" "$session_name" 2>/dev/null || echo "no commits")

            echo "├─ $session_name"
            echo "│  ├─ Auto-commit: $auto_commit_status"
            echo "│  ├─ Auto-merge: $auto_merge_status"
            echo "│  ├─ Last activity: $last_commit"
            if [[ -n "$conflict_marker" ]]; then
                echo "│  └─ Status:$conflict_marker"
            fi
            echo "│"
        fi
    done
}

remove_session() {
    local session_name="$1"
    local worktree_path="$WORKTREES_DIR/$session_name"

    if [[ -z "$session_name" ]]; then
        echo "Error: SESSION_NAME required"
        echo "Usage: $0 remove SESSION_NAME"
        exit 1
    fi

    if [[ ! -d "$worktree_path" ]]; then
        echo "Error: Session not found: $session_name"
        exit 1
    fi

    echo "Removing session: $session_name"

    # Stop auto-commit
    if [[ -f "$worktree_path/.auto-commit.pid" ]]; then
        cd "$worktree_path" && ../../scripts/auto-commit.sh stop
    fi

    # Stop auto-merge
    cd "$REPO_DIR"
    if [[ -f "$worktree_path/.auto-merge.pid" ]]; then
        ./scripts/auto-merge.sh stop "$session_name"
    fi

    # Remove worktree
    if git worktree remove "$worktree_path" --force 2>&1; then
        echo "✓ Worktree removed"
    else
        echo "✗ Failed to remove worktree (may have uncommitted changes)"
        return 1
    fi

    # Delete the branch
    if git branch -D "$session_name" 2>&1; then
        echo "✓ Branch deleted"
    else
        echo "✗ Failed to delete branch"
    fi

    echo ""
    echo "Session $session_name removed."
}

end_session() {
    local session_name="$1"
    local worktree_path="$WORKTREES_DIR/$session_name"

    if [[ -z "$session_name" ]]; then
        echo "Error: SESSION_NAME required"
        echo "Usage: $0 end SESSION_NAME"
        exit 1
    fi

    if [[ ! -d "$worktree_path" ]]; then
        echo "Error: Session not found: $session_name"
        exit 1
    fi

    echo "Ending session: $session_name"
    echo ""

    # Stop auto-commit (commits any pending changes)
    echo "→ Stopping auto-commit..."
    if [[ -f "$worktree_path/.auto-commit.pid" ]]; then
        cd "$worktree_path"
        ../../scripts/auto-commit.sh once  # One final commit
        ../../scripts/auto-commit.sh stop
    fi

    # Try final merge
    cd "$REPO_DIR"
    echo "→ Attempting final merge..."
    if ./scripts/auto-merge.sh once "$session_name"; then
        echo "✓ Final merge successful"

        # Stop auto-merge
        if [[ -f "$worktree_path/.auto-merge.pid" ]]; then
            ./scripts/auto-merge.sh stop "$session_name"
        fi

        # Remove the worktree
        echo "→ Removing worktree..."
        remove_session "$session_name"

        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Session ended successfully!"
        echo "All changes merged to main and pushed."
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    else
        echo "✗ Final merge failed (conflicts exist)"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Session paused - conflicts need resolution"
        echo ""
        echo "Your work is safe in: $worktree_path"
        echo "Branch: $session_name"
        echo ""
        echo "To resolve conflicts:"
        echo "  1. cd $worktree_path"
        echo "  2. Edit conflicting files"
        echo "  3. git add <files> && git commit"
        echo "  4. rm .merge-conflict"
        echo "  5. Run: ./scripts/worktree-session.sh end $session_name"
        echo ""
        echo "Or ask Claude to help resolve the conflict."
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    fi
}

cleanup_old() {
    local days="${1:-7}"
    echo "Cleaning up sessions older than $days days..."
    echo ""

    local count=0
    for worktree in "$WORKTREES_DIR"/session-*; do
        if [[ -d "$worktree" ]]; then
            local session_name=$(basename "$worktree")
            local age_days=$(( ($(date +%s) - $(stat -f %m "$worktree" 2>/dev/null || stat -c %Y "$worktree")) / 86400 ))

            if [[ $age_days -gt $days ]]; then
                echo "Removing old session: $session_name ($age_days days old)"
                remove_session "$session_name"
                count=$((count + 1))
            fi
        fi
    done

    if [[ $count -eq 0 ]]; then
        echo "No old sessions to clean up."
    else
        echo ""
        echo "Cleaned up $count old session(s)."
    fi
}

case "${1:-}" in
    create)
        create_session "$2"
        ;;
    list)
        list_sessions
        ;;
    remove)
        remove_session "$2"
        ;;
    end)
        end_session "$2"
        ;;
    cleanup)
        cleanup_old "$2"
        ;;
    *)
        echo "Worktree Session Manager"
        echo ""
        echo "Usage:"
        echo "  $0 create [USER]        Create new session (generates random ID)"
        echo "  $0 list                 List active sessions"
        echo "  $0 remove SESSION_NAME  Remove a session"
        echo "  $0 end SESSION_NAME     End session gracefully (merge + cleanup)"
        echo "  $0 cleanup [DAYS]       Remove sessions older than DAYS (default: 7)"
        echo ""
        echo "Examples:"
        echo "  $0 create hathbanger"
        echo "  $0 list"
        echo "  $0 end session-hathbanger-20260118-1430-a3f9b2"
        echo "  $0 cleanup 14"
        exit 1
        ;;
esac
