#!/bin/bash
#
# Auto-pull script for GTM repo
# Keeps main branch synchronized with remote every 5 minutes
#
# Usage:
#   ./scripts/auto-pull.sh start   # Start background process
#   ./scripts/auto-pull.sh stop    # Stop background process
#   ./scripts/auto-pull.sh status  # Check if running
#   ./scripts/auto-pull.sh once    # Run once (for testing)

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PID_FILE="$REPO_DIR/.auto-pull.pid"
LOG_FILE="$REPO_DIR/.auto-pull.log"
INTERVAL=300  # 5 minutes

cd "$REPO_DIR" || exit 1

do_pull() {
    # Save current branch
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

    # Switch to main if not already there
    if [[ "$CURRENT_BRANCH" != "main" ]]; then
        git checkout main --quiet 2>> "$LOG_FILE"
    fi

    # Pull latest changes
    if git pull --rebase --quiet 2>> "$LOG_FILE"; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✓ Pulled main successfully" >> "$LOG_FILE"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✗ Pull failed (may have conflicts)" >> "$LOG_FILE"
        # Abort rebase if it failed
        git rebase --abort 2>/dev/null
    fi

    # Return to original branch if we switched
    if [[ "$CURRENT_BRANCH" != "main" && -n "$CURRENT_BRANCH" ]]; then
        git checkout "$CURRENT_BRANCH" --quiet 2>> "$LOG_FILE"
    fi
}

start_daemon() {
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "Auto-pull already running (PID: $(cat "$PID_FILE"))"
        return 1
    fi

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting auto-pull daemon..." >> "$LOG_FILE"

    # Run in background
    (
        while true; do
            do_pull
            sleep $INTERVAL
        done
    ) &

    echo $! > "$PID_FILE"
    echo "Auto-pull started (PID: $!)"
    echo "Interval: ${INTERVAL}s (5 minutes)"
    echo "Log: $LOG_FILE"
}

stop_daemon() {
    if [[ -f "$PID_FILE" ]]; then
        PID=$(cat "$PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            kill "$PID"
            rm "$PID_FILE"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Stopped auto-pull daemon" >> "$LOG_FILE"
            echo "Auto-pull stopped"
        else
            rm "$PID_FILE"
            echo "Process not running (cleaned up stale PID file)"
        fi
    else
        echo "Auto-pull not running"
    fi
}

status_daemon() {
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "Auto-pull running (PID: $(cat "$PID_FILE"))"
        echo "Last 5 log entries:"
        tail -5 "$LOG_FILE" 2>/dev/null || echo "  (no log entries)"
    else
        echo "Auto-pull not running"
    fi
}

case "${1:-}" in
    start)
        start_daemon
        ;;
    stop)
        stop_daemon
        ;;
    status)
        status_daemon
        ;;
    once)
        do_pull
        echo "Single pull check complete"
        ;;
    *)
        echo "Usage: $0 {start|stop|status|once}"
        exit 1
        ;;
esac
