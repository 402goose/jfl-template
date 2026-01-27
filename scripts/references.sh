#!/usr/bin/env bash
# Reference lifecycle management CLI

set -e

GTM_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_FILE="$GTM_DIR/.jfl/references.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

error() {
    echo -e "${RED}❌ $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

if [ ! -f "$CONFIG_FILE" ]; then
    error "No references configured"
    echo "Config file not found: $CONFIG_FILE"
    echo "Run: ./scripts/setup-references.sh first"
    exit 1
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
    error "jq is required but not installed"
    echo "Install with: brew install jq"
    exit 1
fi

ACTION=${1:-help}
NAME=$2

case "$ACTION" in
    list)
        echo "📦 Configured References:"
        echo ""
        jq -r 'to_entries[] | "  \(.key):\n    Description: \(.value.description)\n    Path: \(.value.path)\n    URL: \(.value.url)\n    Ports: \(.value.ports // [] | if length > 0 then join(", ") else "none" end)\n"' "$CONFIG_FILE"
        ;;

    info)
        if [ -z "$NAME" ]; then
            error "Usage: $0 info <name>"
            exit 1
        fi

        if ! jq -e ".[\"$NAME\"]" "$CONFIG_FILE" > /dev/null 2>&1; then
            error "Reference '$NAME' not found"
            exit 1
        fi

        echo "📦 $NAME"
        echo ""
        jq -r ".[\"$NAME\"] | \"Description: \(.description)\nPath: \(.path)\nURL: \(.url)\nLocal: \(.localPath // \"none\")\n\nCommands:\n\" + (.commands | to_entries | map(\"  \(.key): \(.value)\") | join(\"\n\")) + \"\n\nEnvironment (development):\n  Required: \(.env.development.required | join(\", \"))\n  Optional: \(.env.development.optional // [] | join(\", \"))\"" "$CONFIG_FILE"
        ;;

    env)
        if [ -z "$NAME" ]; then
            error "Usage: $0 env <name> [check]"
            exit 1
        fi

        if ! jq -e ".[\"$NAME\"]" "$CONFIG_FILE" > /dev/null 2>&1; then
            error "Reference '$NAME' not found"
            exit 1
        fi

        SUBCOMMAND=$3
        REF_PATH=$(jq -r ".[\"$NAME\"].path" "$CONFIG_FILE")

        # Find env file (check multiple patterns)
        ENV_FILE=""
        for pattern in ".env" ".env.local" ".env.development"; do
            if [ -f "$GTM_DIR/$REF_PATH/$pattern" ]; then
                ENV_FILE="$GTM_DIR/$REF_PATH/$pattern"
                break
            fi
        done

        if [ "$SUBCOMMAND" == "check" ]; then
            echo "🔑 Environment Check: $NAME"
            echo ""

            REQUIRED=$(jq -r ".[\"$NAME\"].env.development.required[]" "$CONFIG_FILE" 2>/dev/null)

            if [ -z "$REQUIRED" ]; then
                success "No required environment variables"
                exit 0
            fi

            all_set=true
            for VAR in $REQUIRED; do
                if [ -n "$ENV_FILE" ] && grep -q "^${VAR}=" "$ENV_FILE"; then
                    success "$VAR (set in $(basename "$ENV_FILE"))"
                else
                    error "$VAR (missing)"
                    all_set=false
                fi
            done

            if [ "$all_set" = true ]; then
                echo ""
                success "All required environment variables are set"
            else
                echo ""
                error "Some required environment variables are missing"
                echo "Create/edit: $ENV_FILE"
                exit 1
            fi
        else
            echo "🔑 Environment Variables: $NAME"
            echo ""
            jq -r ".[\"$NAME\"].env.development | \"Required:\n\" + (.required | map(\"  - \(.)\" ) | join(\"\n\")) + (if .optional then \"\n\nOptional:\n\" + (.optional | map(\"  - \(.)\") | join(\"\n\")) else \"\" end) + (if .notes then \"\n\nNotes: \(.notes)\" else \"\" end)" "$CONFIG_FILE"

            if [ -f "$ENV_FILE" ]; then
                echo ""
                info "Config file exists: $ENV_FILE"
            else
                echo ""
                warn "Config file not found: $ENV_FILE"
                TEMPLATE=$(jq -r ".[\"$NAME\"].env.development.template // empty" "$CONFIG_FILE")
                if [ -n "$TEMPLATE" ]; then
                    echo "Copy from: $GTM_DIR/$REF_PATH/$TEMPLATE"
                fi
            fi
        fi
        ;;

    start)
        if [ -z "$NAME" ]; then
            error "Usage: $0 start <name>"
            exit 1
        fi

        if ! jq -e ".[\"$NAME\"]" "$CONFIG_FILE" > /dev/null 2>&1; then
            error "Reference '$NAME' not found"
            exit 1
        fi

        START_CMD=$(jq -r ".[\"$NAME\"].commands.start // .[\"$NAME\"].commands.dev // empty" "$CONFIG_FILE")
        REF_PATH=$(jq -r ".[\"$NAME\"].path" "$CONFIG_FILE")

        if [ -z "$START_CMD" ]; then
            error "No start command configured for $NAME"
            exit 1
        fi

        echo "🚀 Starting $NAME..."
        cd "$GTM_DIR/$REF_PATH"

        # Check if already running
        PORTS=$(jq -r ".[\"$NAME\"].ports[]" "$CONFIG_FILE" 2>/dev/null)
        for PORT in $PORTS; do
            if lsof -i :"$PORT" > /dev/null 2>&1; then
                warn "$NAME may already be running on port $PORT"
            fi
        done

        eval "$START_CMD" &
        PID=$!
        success "Started (PID: $PID)"

        if [ -n "$PORTS" ]; then
            echo "Ports: $PORTS"
        fi
        ;;

    stop)
        if [ -z "$NAME" ]; then
            error "Usage: $0 stop <name>"
            exit 1
        fi

        if ! jq -e ".[\"$NAME\"]" "$CONFIG_FILE" > /dev/null 2>&1; then
            error "Reference '$NAME' not found"
            exit 1
        fi

        STOP_CMD=$(jq -r ".[\"$NAME\"].commands.stop // empty" "$CONFIG_FILE")

        if [ -n "$STOP_CMD" ]; then
            echo "🛑 Stopping $NAME..."
            eval "$STOP_CMD"
            success "Stopped"
        else
            # Auto-detect by port or start command
            PORTS=$(jq -r ".[\"$NAME\"].ports[]" "$CONFIG_FILE" 2>/dev/null)

            if [ -n "$PORTS" ]; then
                for PORT in $PORTS; do
                    PID=$(lsof -ti :"$PORT" 2>/dev/null || echo "")
                    if [ -n "$PID" ]; then
                        echo "🛑 Stopping $NAME (port $PORT, PID: $PID)..."
                        kill "$PID"
                        success "Stopped"
                    else
                        warn "No process found on port $PORT"
                    fi
                done
            else
                START_CMD=$(jq -r ".[\"$NAME\"].commands.start // .[\"$NAME\"].commands.dev" "$CONFIG_FILE")
                echo "🛑 Stopping $NAME (searching for: $START_CMD)..."
                pkill -f "$START_CMD" || warn "No matching process found"
            fi
        fi
        ;;

    health)
        echo "🏥 Health Check:"
        echo ""

        jq -r 'to_entries[] | "\(.key)|\(.value.healthcheck // "none")|\(.value.ports // [] | join(","))"' "$CONFIG_FILE" | while IFS='|' read -r name check ports; do
            if [ "$check" != "none" ] && [ -n "$check" ]; then
                if eval "$check" > /dev/null 2>&1; then
                    success "$name"
                else
                    error "$name (healthcheck failed)"
                fi
            elif [ -n "$ports" ]; then
                # Check by port
                all_up=true
                for port in ${ports//,/ }; do
                    if ! lsof -i :"$port" > /dev/null 2>&1; then
                        all_up=false
                        break
                    fi
                done

                if [ "$all_up" = true ]; then
                    success "$name (port: $ports)"
                else
                    warn "$name (not running on port: $ports)"
                fi
            else
                warn "$name (no healthcheck configured)"
            fi
        done
        ;;

    status)
        echo "📊 Reference Status:"
        echo ""

        jq -r 'to_entries[] | "\(.key)|\(.value.path)|\(.value.ports // [] | join(","))"' "$CONFIG_FILE" | while IFS='|' read -r name path ports; do
            if [ -d "$GTM_DIR/$path/.git" ] || [ -f "$GTM_DIR/$path/.git" ]; then
                # Check if running
                if [ -n "$ports" ]; then
                    running=false
                    for port in ${ports//,/ }; do
                        if lsof -i :"$port" > /dev/null 2>&1; then
                            running=true
                            break
                        fi
                    done

                    if [ "$running" = true ]; then
                        echo -e "  ${GREEN}●${NC} $name (running)"
                    else
                        echo -e "  ${YELLOW}○${NC} $name (stopped)"
                    fi
                else
                    echo -e "  ${BLUE}●${NC} $name (configured)"
                fi
            else
                echo -e "  ${RED}○${NC} $name (not initialized)"
            fi
        done
        ;;

    setup)
        "$GTM_DIR/scripts/setup-references.sh"
        ;;

    help|--help|-h|*)
        echo "JFL Reference Management"
        echo ""
        echo "Usage: $0 <command> [arguments]"
        echo ""
        echo "Commands:"
        echo "  list              List all configured references"
        echo "  info <name>       Show detailed info about a reference"
        echo "  status            Show status of all references"
        echo "  env <name>        Show environment variables for a reference"
        echo "  env <name> check  Check if all required env vars are set"
        echo "  start <name>      Start a reference"
        echo "  stop <name>       Stop a reference"
        echo "  health            Health check all references"
        echo "  setup             Run smart reference setup"
        echo ""
        echo "Examples:"
        echo "  $0 list"
        echo "  $0 info product"
        echo "  $0 env product check"
        echo "  $0 start product"
        echo "  $0 health"
        ;;
esac
