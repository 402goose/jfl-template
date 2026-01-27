#!/usr/bin/env bash
# Smart submodule setup - detects local repos or falls back to GitHub
# Zero-duplication setup using git alternates for local repos

set -e

PARENT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
GTM_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "🔍 Detecting local reference repositories..."
echo ""

# Parse .gitmodules to get all submodules (bash 3.2 compatible)
SUBMODULES=""
current_path=""
while IFS= read -r line; do
    if [[ "$line" =~ path\ *=\ *(.+) ]]; then
        current_path=$(echo "${BASH_REMATCH[1]}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        SUBMODULES="$SUBMODULES $current_path"
    fi
done < "$GTM_DIR/.gitmodules"

total_saved=0

for ref_path in $SUBMODULES; do
    repo_name="$(basename "$ref_path")"
    local_path="$PARENT_DIR/$repo_name"

    echo "📦 Configuring: $ref_path"

    # Check if local repo exists
    if [ -d "$local_path/.git" ]; then
        echo "   ✅ Found local repo at $local_path"
        echo "   🔗 Configuring zero-duplication setup..."

        # Configure local file:// URL (machine-specific, not committed)
        git config "submodule.$ref_path.url" "file://$local_path"

        # Initialize submodule from local
        if [ ! -d "$GTM_DIR/$ref_path/.git" ]; then
            cd "$GTM_DIR"
            git submodule update --init "$ref_path"
        fi

        # Set up git alternates to share objects (zero duplication!)
        # Find the actual git directory (could be a gitdir reference for submodules)
        if [ -f "$GTM_DIR/$ref_path/.git" ]; then
            # It's a gitdir reference, parse it
            gitdir=$(grep "^gitdir:" "$GTM_DIR/$ref_path/.git" | cut -d' ' -f2)
            actual_git_dir="$GTM_DIR/$ref_path/$gitdir"
        else
            actual_git_dir="$GTM_DIR/$ref_path/.git"
        fi

        mkdir -p "$actual_git_dir/objects/info"
        echo "$local_path/.git/objects" > "$actual_git_dir/objects/info/alternates"

        # Calculate savings
        if [ -d "$local_path/.git/objects" ]; then
            local_size=$(du -sk "$local_path/.git/objects" | cut -f1)
            ref_size=$(du -sk "$actual_git_dir/objects" 2>/dev/null | cut -f1 || echo "0")
            saved=$((local_size - ref_size))
            total_saved=$((total_saved + saved))

            # Convert to human readable
            if [ $saved -gt 1048576 ]; then
                saved_human="$(echo "scale=1; $saved/1048576" | bc)G"
            elif [ $saved -gt 1024 ]; then
                saved_human="$(echo "scale=1; $saved/1024" | bc)M"
            else
                saved_human="${saved}K"
            fi

            echo "   💾 Saved: $saved_human (objects shared with parent)"
        fi

    else
        # Local repo doesn't exist - use GitHub
        echo "   ⚠️  Local repo not found at $local_path"

        # Get GitHub URL from .gitmodules
        github_url=$(git config -f "$GTM_DIR/.gitmodules" "submodule.$ref_path.url")

        # Skip file:// URLs that don't exist locally (remote-only references)
        if [[ "$github_url" == file://* ]]; then
            echo "   ⏭️  Skipping: remote file path not accessible"
            echo ""
            continue
        fi

        echo "   🌐 Using GitHub: $github_url"

        # Use GitHub URL (don't override if already set to something else)
        current_url=$(git config "submodule.$ref_path.url" 2>/dev/null || echo "")
        if [ -z "$current_url" ] || [ "$current_url" == "$github_url" ]; then
            git config "submodule.$ref_path.url" "$github_url"
        fi

        # Initialize from GitHub
        if [ ! -d "$GTM_DIR/$ref_path/.git" ] && [ ! -f "$GTM_DIR/$ref_path/.git" ]; then
            cd "$GTM_DIR"
            git submodule update --init "$ref_path"
        fi

        ref_size=$(du -sh "$GTM_DIR/$ref_path" 2>/dev/null | cut -f1 || echo "0")
        echo "   💾 Disk usage: $ref_size (full clone)"
    fi

    echo ""
done

echo "✨ Reference setup complete!"
echo ""

# Show savings summary
if [ $total_saved -gt 0 ]; then
    if [ $total_saved -gt 1048576 ]; then
        total_saved_human="$(echo "scale=1; $total_saved/1048576" | bc)GB"
    elif [ $total_saved -gt 1024 ]; then
        total_saved_human="$(echo "scale=1; $total_saved/1024" | bc)MB"
    else
        total_saved_human="${total_saved}KB"
    fi
    echo "💰 Total space saved: $total_saved_human"
    echo ""
fi

echo "📊 Summary:"
cd "$GTM_DIR"
git submodule foreach --quiet 'url=$(git config remote.origin.url 2>/dev/null || git config submodule.$(git rev-parse --show-prefix | sed "s/\/$//").url); echo "  - $(basename $PWD): $url"'
