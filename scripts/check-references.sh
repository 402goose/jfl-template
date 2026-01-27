#!/usr/bin/env bash
# Natural language reference checker
# Runs after session-sync to proactively detect and fix reference issues

set -e

GTM_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_FILE="$GTM_DIR/.jfl/references.json"
PREFS_FILE="$GTM_DIR/.jfl/references-preferences.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "⚠️  jq not installed - skipping reference check"
    echo "Install with: brew install jq"
    exit 0
fi

# Initialize preferences file if it doesn't exist
if [ ! -f "$PREFS_FILE" ]; then
    echo "{}" > "$PREFS_FILE"
fi

echo ""
echo "🔍 Checking references..."
echo ""

# Track if we need user input
NEEDS_INPUT=false
ISSUES_FOUND=0
ISSUES_FIXED=0

# Get all references from config
REFS=$(jq -r 'keys[]' "$CONFIG_FILE" 2>/dev/null || echo "")

if [ -z "$REFS" ]; then
    echo "ℹ️  No references configured"
    exit 0
fi

# Check each reference
for ref_name in $REFS; do
    ref_path=$(jq -r ".[\"$ref_name\"].path" "$CONFIG_FILE")
    ref_local=$(jq -r ".[\"$ref_name\"].localPath // \"\"" "$CONFIG_FILE")
    ref_desc=$(jq -r ".[\"$ref_name\"].description" "$CONFIG_FILE")

    # Check preferences for this reference
    pref_action=$(jq -r ".[\"$ref_name\"].action // \"\"" "$PREFS_FILE")
    pref_reason=$(jq -r ".[\"$ref_name\"].reason // \"\"" "$PREFS_FILE")
    pref_local_path=$(jq -r ".[\"$ref_name\"].localPath // \"\"" "$PREFS_FILE")

    # Status: configured, linked, missing, or skipped
    status="unknown"

    # Check if reference exists
    if [ -d "$GTM_DIR/$ref_path/.git" ] || [ -f "$GTM_DIR/$ref_path/.git" ]; then
        # Reference is initialized

        # Check if using git alternates (zero duplication)
        if [ -f "$GTM_DIR/$ref_path/.git" ]; then
            # Submodule - find actual git dir
            gitdir=$(grep "^gitdir:" "$GTM_DIR/$ref_path/.git" | cut -d' ' -f2)
            actual_git_dir="$GTM_DIR/$ref_path/$gitdir"
        else
            actual_git_dir="$GTM_DIR/$ref_path/.git"
        fi

        if [ -f "$actual_git_dir/objects/info/alternates" ]; then
            alternate_path=$(cat "$actual_git_dir/objects/info/alternates")
            status="linked"

            # Check if the alternate path still exists
            if [ ! -d "$alternate_path" ]; then
                echo -e "📦 ${YELLOW}$ref_name${NC}"
                echo "   ⚠️  Linked to missing location: $alternate_path"
                echo "   The local repo may have moved"
                echo ""
                ISSUES_FOUND=$((ISSUES_FOUND + 1))
                NEEDS_INPUT=true

                # Ask if they want to search for it or unlink
                read -p "   Search for new location? (y/n): " -n 1 -r
                echo

                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    # Try common locations
                    local_name=$(basename "$ref_path")
                    parent_dir="$(cd "$GTM_DIR/.." && pwd)"

                    found_path=""
                    for search_path in "$parent_dir/$local_name" "$HOME/code/$local_name" "$HOME/code/*/$local_name"; do
                        if [ -d "$search_path/.git" ]; then
                            found_path="$search_path"
                            break
                        fi
                    done

                    if [ -n "$found_path" ]; then
                        echo "   ✅ Found at: $found_path"
                        echo "   Updating link..."

                        # Update alternate path
                        echo "$found_path/.git/objects" > "$actual_git_dir/objects/info/alternates"

                        # Update config
                        git config "submodule.$ref_path.url" "file://$found_path"

                        # Update preferences
                        jq ".[\"$ref_name\"] = {action: \"link\", localPath: \"$found_path\", updated: \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" "$PREFS_FILE" > "$PREFS_FILE.tmp" && mv "$PREFS_FILE.tmp" "$PREFS_FILE"

                        ISSUES_FIXED=$((ISSUES_FIXED + 1))
                        echo "   ✅ Re-linked successfully"
                    else
                        echo "   ❌ Not found in common locations"
                        read -p "   Enter path to repo (or leave empty to skip): " user_path

                        if [ -n "$user_path" ] && [ -d "$user_path/.git" ]; then
                            echo "$user_path/.git/objects" > "$actual_git_dir/objects/info/alternates"
                            git config "submodule.$ref_path.url" "file://$user_path"
                            jq ".[\"$ref_name\"] = {action: \"link\", localPath: \"$user_path\", updated: \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" "$PREFS_FILE" > "$PREFS_FILE.tmp" && mv "$PREFS_FILE.tmp" "$PREFS_FILE"
                            ISSUES_FIXED=$((ISSUES_FIXED + 1))
                            echo "   ✅ Re-linked successfully"
                        fi
                    fi
                fi
                echo ""
                continue
            fi

            # Check if local path has changed
            if [ -n "$ref_local" ] && [ -n "$pref_local_path" ] && [ "$ref_local" != "$pref_local_path" ]; then
                # Local repo might have moved
                if [ -d "$ref_local/.git" ] && [ ! -d "$pref_local_path/.git" ]; then
                    echo -e "📦 ${BLUE}$ref_name${NC}"
                    echo "   ℹ️  Local repo moved"
                    echo "   Old: $pref_local_path"
                    echo "   New: $ref_local"
                    echo ""

                    # Update automatically since we detected it
                    echo "$ref_local/.git/objects" > "$actual_git_dir/objects/info/alternates"
                    git config "submodule.$ref_path.url" "file://$ref_local"
                    jq ".[\"$ref_name\"].localPath = \"$ref_local\" | .[\"$ref_name\"].updated = \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"" "$PREFS_FILE" > "$PREFS_FILE.tmp" && mv "$PREFS_FILE.tmp" "$PREFS_FILE"

                    echo "   ✅ Updated link automatically"
                    echo ""
                    ISSUES_FIXED=$((ISSUES_FIXED + 1))
                    continue
                fi
            fi

            echo -e "📦 ${GREEN}$ref_name${NC}"
            echo "   ✅ Linked to $alternate_path"
            echo "   ✅ Zero duplication"
            echo ""

        else
            # Using GitHub clone (duplicated)
            status="configured"

            # Check if local repo exists that we could link to
            if [ -n "$ref_local" ] && [ -d "$ref_local/.git" ]; then
                # Check if we've already decided to skip this
                if [ "$pref_action" == "skip" ]; then
                    echo -e "📦 ${BLUE}$ref_name${NC}"
                    echo "   ℹ️  Using GitHub clone (you chose this)"
                    echo "   Reason: $pref_reason"
                    echo ""
                    continue
                fi

                echo -e "📦 ${YELLOW}$ref_name${NC}"
                echo "   ⚠️  Found at $ref_local"
                echo "   Currently pulling from GitHub (objects duplicated)"
                echo ""

                # Calculate duplication size
                local_size=$(du -sh "$ref_local/.git/objects" 2>/dev/null | cut -f1 || echo "unknown")
                echo "   💡 Linking would save ~$local_size"
                echo ""

                ISSUES_FOUND=$((ISSUES_FOUND + 1))
                NEEDS_INPUT=true

                read -p "   Link to local copy? (y/n): " -n 1 -r
                echo

                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    echo "   Configuring..."

                    # Set up git alternates
                    mkdir -p "$actual_git_dir/objects/info"
                    echo "$ref_local/.git/objects" > "$actual_git_dir/objects/info/alternates"

                    # Update submodule URL
                    git config "submodule.$ref_path.url" "file://$ref_local"

                    # Save preference
                    jq ".[\"$ref_name\"] = {action: \"link\", localPath: \"$ref_local\", updated: \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" "$PREFS_FILE" > "$PREFS_FILE.tmp" && mv "$PREFS_FILE.tmp" "$PREFS_FILE"

                    echo "   ✅ Linked successfully"
                    ISSUES_FIXED=$((ISSUES_FIXED + 1))
                else
                    # Save skip preference
                    jq ".[\"$ref_name\"] = {action: \"skip\", reason: \"User prefers GitHub clone\", updated: \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" "$PREFS_FILE" > "$PREFS_FILE.tmp" && mv "$PREFS_FILE.tmp" "$PREFS_FILE"
                    echo "   ✅ Saved preference (won't ask again)"
                fi
                echo ""
            else
                echo -e "📦 ${BLUE}$ref_name${NC}"
                echo "   ✅ Using GitHub clone"
                echo ""
            fi
        fi
    else
        # Reference not initialized
        status="missing"

        # Check if we've already decided to skip
        if [ "$pref_action" == "skip" ]; then
            echo -e "📦 ${BLUE}$ref_name${NC}"
            echo "   ℹ️  Skipping (you chose this)"
            echo "   Reason: $pref_reason"
            echo ""
            continue
        fi

        # Check if local repo appeared since last time
        if [ -n "$ref_local" ] && [ -d "$ref_local/.git" ]; then
            echo -e "📦 ${GREEN}$ref_name${NC}"
            echo "   🆕 Found new local repo at $ref_local!"
            echo ""

            ISSUES_FOUND=$((ISSUES_FOUND + 1))
            NEEDS_INPUT=true

            read -p "   Link to this repo? (y/n): " -n 1 -r
            echo

            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo "   Initializing..."

                # Configure local URL
                git config "submodule.$ref_path.url" "file://$ref_local"

                # Initialize submodule
                cd "$GTM_DIR"
                git submodule update --init "$ref_path"

                # Set up git alternates
                if [ -f "$GTM_DIR/$ref_path/.git" ]; then
                    gitdir=$(grep "^gitdir:" "$GTM_DIR/$ref_path/.git" | cut -d' ' -f2)
                    actual_git_dir="$GTM_DIR/$ref_path/$gitdir"
                else
                    actual_git_dir="$GTM_DIR/$ref_path/.git"
                fi

                mkdir -p "$actual_git_dir/objects/info"
                echo "$ref_local/.git/objects" > "$actual_git_dir/objects/info/alternates"

                # Save preference
                jq ".[\"$ref_name\"] = {action: \"link\", localPath: \"$ref_local\", updated: \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" "$PREFS_FILE" > "$PREFS_FILE.tmp" && mv "$PREFS_FILE.tmp" "$PREFS_FILE"

                echo "   ✅ Linked successfully"
                ISSUES_FIXED=$((ISSUES_FIXED + 1))
            else
                jq ".[\"$ref_name\"] = {action: \"skip\", reason: \"User chose not to link\", updated: \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" "$PREFS_FILE" > "$PREFS_FILE.tmp" && mv "$PREFS_FILE.tmp" "$PREFS_FILE"
                echo "   ✅ Saved preference"
            fi
            echo ""
            continue
        fi

        echo -e "📦 ${YELLOW}$ref_name${NC}"
        echo "   ❌ Not found locally"
        echo "   $ref_desc"
        echo ""

        ISSUES_FOUND=$((ISSUES_FOUND + 1))
        NEEDS_INPUT=true

        read -p "   Do you have this repo somewhere? (y/n): " -n 1 -r
        echo

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            read -p "   Enter path to repo: " user_path

            if [ -n "$user_path" ] && [ -d "$user_path/.git" ]; then
                echo "   Initializing..."

                git config "submodule.$ref_path.url" "file://$user_path"
                cd "$GTM_DIR"
                git submodule update --init "$ref_path"

                # Set up alternates
                if [ -f "$GTM_DIR/$ref_path/.git" ]; then
                    gitdir=$(grep "^gitdir:" "$GTM_DIR/$ref_path/.git" | cut -d' ' -f2)
                    actual_git_dir="$GTM_DIR/$ref_path/$gitdir"
                else
                    actual_git_dir="$GTM_DIR/$ref_path/.git"
                fi

                mkdir -p "$actual_git_dir/objects/info"
                echo "$user_path/.git/objects" > "$actual_git_dir/objects/info/alternates"

                jq ".[\"$ref_name\"] = {action: \"link\", localPath: \"$user_path\", updated: \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" "$PREFS_FILE" > "$PREFS_FILE.tmp" && mv "$PREFS_FILE.tmp" "$PREFS_FILE"

                echo "   ✅ Linked successfully"
                ISSUES_FIXED=$((ISSUES_FIXED + 1))
            else
                echo "   ⚠️  Invalid path"
            fi
        else
            read -p "   Clone from GitHub? (y/n): " -n 1 -r
            echo

            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo "   Cloning..."
                cd "$GTM_DIR"
                git submodule update --init "$ref_path"

                jq ".[\"$ref_name\"] = {action: \"clone\", reason: \"Cloned from GitHub\", updated: \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" "$PREFS_FILE" > "$PREFS_FILE.tmp" && mv "$PREFS_FILE.tmp" "$PREFS_FILE"

                echo "   ✅ Cloned successfully"
                ISSUES_FIXED=$((ISSUES_FIXED + 1))
            else
                jq ".[\"$ref_name\"] = {action: \"skip\", reason: \"User doesn't have it locally\", updated: \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" "$PREFS_FILE" > "$PREFS_FILE.tmp" && mv "$PREFS_FILE.tmp" "$PREFS_FILE"

                echo "   ✅ Saved preference (won't ask again)"
            fi
        fi
        echo ""
    fi
done

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${GREEN}✅ All references configured correctly${NC}"
elif [ $ISSUES_FIXED -gt 0 ]; then
    echo -e "${GREEN}✅ Fixed $ISSUES_FIXED issue(s)${NC}"
    if [ $((ISSUES_FOUND - ISSUES_FIXED)) -gt 0 ]; then
        echo -e "${YELLOW}⚠️  $((ISSUES_FOUND - ISSUES_FIXED)) issue(s) remaining${NC}"
    fi
else
    echo -e "${YELLOW}ℹ️  Found $ISSUES_FOUND issue(s), none fixed${NC}"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
