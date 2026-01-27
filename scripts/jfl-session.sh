#!/bin/bash
# jfl-session.sh - Launch Claude in an isolated worktree session
#
# This fixes the worktree bug where Claude runs in main repo instead of worktree.
# The fix: create worktree FIRST, then launch Claude INSIDE it.
#
# Usage:
#   ./scripts/jfl-session.sh              # Start new session
#   ./scripts/jfl-session.sh resume       # Resume existing session
#   ./scripts/jfl-session.sh end          # End current session

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKTREES_DIR="$PROJECT_ROOT/worktrees"
SESSION_FILE="$PROJECT_ROOT/.jfl/current-session.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Get username for session naming
get_username() {
    if command -v whoami &> /dev/null; then
        whoami
    else
        echo "user"
    fi
}

# Generate session name
generate_session_name() {
    local user=$(get_username)
    local timestamp=$(date +%Y%m%d-%H%M)
    local hash=$(openssl rand -hex 3)
    echo "session-${user}-${timestamp}-${hash}"
}

# Find existing sessions
find_existing_sessions() {
    if [ -d "$WORKTREES_DIR" ]; then
        find "$WORKTREES_DIR" -maxdepth 1 -type d -name "session-*" 2>/dev/null | while read dir; do
            if [ -f "$dir/.git" ]; then
                basename "$dir"
            fi
        done
    fi
}

# Check if session is active (has auto-commit running)
is_session_active() {
    local session_name="$1"
    local pid_file="$WORKTREES_DIR/$session_name/.jfl/auto-commit.pid"
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if ps -p "$pid" > /dev/null 2>&1; then
            echo "active"
            return
        fi
    fi
    echo "stopped"
}

# Create new session
create_session() {
    local session_name=$(generate_session_name)
    local worktree_path="$WORKTREES_DIR/$session_name"

    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  Creating JFL Session${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Sync first
    echo -e "${BLUE}→${NC} Syncing repositories..."
    if [ -f "$PROJECT_ROOT/product/scripts/session/session-sync.sh" ]; then
        "$PROJECT_ROOT/product/scripts/session/session-sync.sh" 2>/dev/null || true
    fi
    echo -e "${GREEN}✓${NC} Synced"

    # Create worktree
    echo -e "${BLUE}→${NC} Creating worktree: $session_name"
    mkdir -p "$WORKTREES_DIR"

    cd "$PROJECT_ROOT"
    if ! git worktree add "$worktree_path" -b "$session_name" 2>&1; then
        echo -e "${RED}✗${NC} Failed to create worktree"
        exit 1
    fi
    echo -e "${GREEN}✓${NC} Worktree created"

    # Initialize submodules in worktree
    echo -e "${BLUE}→${NC} Initializing submodules..."
    cd "$worktree_path"
    git submodule update --init --recursive 2>/dev/null || true
    echo -e "${GREEN}✓${NC} Submodules ready"

    # Create session tracking
    mkdir -p "$worktree_path/.jfl"
    cat > "$worktree_path/.jfl/session.json" << EOF
{
  "session_name": "$session_name",
  "worktree_path": "$worktree_path",
  "started_at": "$(date -Iseconds)",
  "base_commit": "$(git rev-parse HEAD)"
}
EOF

    # Start auto-commit in worktree
    echo -e "${BLUE}→${NC} Starting auto-commit..."
    if [ -f "$worktree_path/product/scripts/session/auto-commit.sh" ]; then
        cd "$worktree_path"
        "$worktree_path/product/scripts/session/auto-commit.sh" start 120 > /dev/null 2>&1 &
        echo -e "${GREEN}✓${NC} Auto-commit running (2 min interval)"
    fi

    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  Session ready!${NC}"
    echo ""
    echo -e "  ${BOLD}Launching Claude in:${NC}"
    echo -e "  $worktree_path"
    echo ""
    echo -e "  To end session later:"
    echo -e "  ${BLUE}./scripts/jfl-session.sh end${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Launch Claude in the worktree directory
    cd "$worktree_path"
    exec claude
}

# Resume existing session
resume_session() {
    local sessions=($(find_existing_sessions))

    if [ ${#sessions[@]} -eq 0 ]; then
        echo -e "${YELLOW}No existing sessions found.${NC}"
        echo ""
        read -p "Create new session? [Y/n] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            exit 0
        fi
        create_session
        return
    fi

    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  Existing Sessions${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    local i=1
    for session in "${sessions[@]}"; do
        local status=$(is_session_active "$session")
        local worktree_path="$WORKTREES_DIR/$session"
        local last_modified=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$worktree_path" 2>/dev/null || echo "unknown")

        if [ "$status" = "active" ]; then
            echo -e "  ${GREEN}[$i]${NC} $session"
            echo -e "      Status: ${GREEN}active${NC}"
        else
            echo -e "  ${YELLOW}[$i]${NC} $session"
            echo -e "      Status: ${YELLOW}stopped${NC}"
        fi
        echo -e "      Last activity: $last_modified"
        echo ""
        ((i++))
    done

    echo -e "  [n] Create new session"
    echo -e "  [q] Quit"
    echo ""

    read -p "Select session: " choice

    if [ "$choice" = "q" ]; then
        exit 0
    elif [ "$choice" = "n" ]; then
        create_session
        return
    fi

    # Validate choice
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#sessions[@]} ]; then
        echo -e "${RED}Invalid choice${NC}"
        exit 1
    fi

    local selected_session="${sessions[$((choice-1))]}"
    local worktree_path="$WORKTREES_DIR/$selected_session"

    echo ""
    echo -e "${BLUE}→${NC} Resuming session: $selected_session"

    # Restart auto-commit if not running
    if [ "$(is_session_active "$selected_session")" = "stopped" ]; then
        if [ -f "$worktree_path/product/scripts/session/auto-commit.sh" ]; then
            cd "$worktree_path"
            "$worktree_path/product/scripts/session/auto-commit.sh" start 120 > /dev/null 2>&1 &
            echo -e "${GREEN}✓${NC} Auto-commit restarted"
        fi
    fi

    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  Resuming session${NC}"
    echo ""
    echo -e "  ${BOLD}Launching Claude in:${NC}"
    echo -e "  $worktree_path"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    cd "$worktree_path"
    exec claude
}

# End session (merge and cleanup)
end_session() {
    local session_name="$1"

    # If no session specified, try to find current
    if [ -z "$session_name" ]; then
        # Check if we're in a worktree
        local current_dir="$(pwd)"
        if [[ "$current_dir" == *"/worktrees/session-"* ]]; then
            session_name=$(basename "$current_dir")
        else
            # List sessions and ask
            local sessions=($(find_existing_sessions))
            if [ ${#sessions[@]} -eq 0 ]; then
                echo -e "${YELLOW}No sessions to end.${NC}"
                exit 0
            fi

            echo "Active sessions:"
            local i=1
            for session in "${sessions[@]}"; do
                echo "  [$i] $session"
                ((i++))
            done
            read -p "End which session? " choice

            if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#sessions[@]} ]; then
                echo -e "${RED}Invalid choice${NC}"
                exit 1
            fi
            session_name="${sessions[$((choice-1))]}"
        fi
    fi

    local worktree_path="$WORKTREES_DIR/$session_name"

    if [ ! -d "$worktree_path" ]; then
        echo -e "${RED}Session not found: $session_name${NC}"
        exit 1
    fi

    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  Ending Session: $session_name${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    cd "$worktree_path"

    # Stop auto-commit
    echo -e "${BLUE}→${NC} Stopping auto-commit..."
    if [ -f "$worktree_path/product/scripts/session/auto-commit.sh" ]; then
        "$worktree_path/product/scripts/session/auto-commit.sh" stop 2>/dev/null || true
    fi
    echo -e "${GREEN}✓${NC} Stopped"

    # Commit any remaining changes
    echo -e "${BLUE}→${NC} Committing final changes..."
    git add -A
    if ! git diff --cached --quiet; then
        git commit -m "session: end $(date '+%Y-%m-%d %H:%M')" || true
        echo -e "${GREEN}✓${NC} Changes committed"
    else
        echo -e "${GREEN}✓${NC} No uncommitted changes"
    fi

    # Push session branch
    echo -e "${BLUE}→${NC} Pushing session branch..."
    git push -u origin "$session_name" 2>/dev/null || true
    echo -e "${GREEN}✓${NC} Branch pushed"

    # Merge to main
    echo -e "${BLUE}→${NC} Merging to main..."
    cd "$PROJECT_ROOT"
    git checkout main
    git pull origin main

    if git merge "$session_name" -m "Merge session: $session_name"; then
        echo -e "${GREEN}✓${NC} Merged to main"
        git push origin main
        echo -e "${GREEN}✓${NC} Pushed to main"
    else
        echo -e "${YELLOW}⚠${NC} Merge conflicts detected"
        echo "  Resolve conflicts, then run:"
        echo "  git add . && git commit && git push origin main"
        exit 1
    fi

    # Cleanup worktree
    echo -e "${BLUE}→${NC} Cleaning up worktree..."
    git worktree remove "$worktree_path" --force 2>/dev/null || true
    git branch -d "$session_name" 2>/dev/null || true
    echo -e "${GREEN}✓${NC} Worktree removed"

    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  Session ended and merged!${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Main
case "${1:-start}" in
    start|new)
        # Check for existing sessions first
        existing=($(find_existing_sessions))
        if [ ${#existing[@]} -gt 0 ]; then
            echo ""
            echo -e "${YELLOW}⚠ Existing sessions found:${NC}"
            for s in "${existing[@]}"; do
                echo "  - $s ($(is_session_active "$s"))"
            done
            echo ""
            read -p "Resume existing, create new, or quit? [r/n/q] " -n 1 -r
            echo
            case $REPLY in
                r|R) resume_session ;;
                n|N) create_session ;;
                *) exit 0 ;;
            esac
        else
            create_session
        fi
        ;;
    resume)
        resume_session
        ;;
    end)
        end_session "${2:-}"
        ;;
    *)
        echo "Usage: $0 {start|resume|end [session-name]}"
        exit 1
        ;;
esac
