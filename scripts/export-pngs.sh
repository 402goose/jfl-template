#!/bin/bash
# Export all SVGs to PNGs
# Requires: brew install librsvg

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
SVG_DIR="$ROOT_DIR/outputs/svg"
PNG_DIR="$ROOT_DIR/outputs/png"

echo "Exporting SVGs to PNGs..."

# Create PNG directories
mkdir -p "$PNG_DIR/mark" "$PNG_DIR/social" "$PNG_DIR/favicon"

# Export marks
echo "Exporting marks..."
for svg in "$SVG_DIR/mark"/*.svg; do
  [ -f "$svg" ] || continue
  filename=$(basename "$svg" .svg)

  # Extract size from filename if present (e.g., mark-v1-80-dark.svg → 80)
  size=$(echo "$filename" | grep -oE '[0-9]+' | head -1)

  if [ -n "$size" ]; then
    rsvg-convert -w "$size" -h "$size" "$svg" -o "$PNG_DIR/mark/${filename}.png"
  else
    # Default size for marks without size in name
    rsvg-convert -w 400 -h 400 "$svg" -o "$PNG_DIR/mark/${filename}.png"
  fi
  echo "  ✓ $filename.png"
done

# Export social assets
echo "Exporting social assets..."
for svg in "$SVG_DIR/social"/*.svg; do
  [ -f "$svg" ] || continue
  filename=$(basename "$svg" .svg)

  # Parse dimensions from filename
  if [[ "$filename" == *"1500x500"* ]]; then
    rsvg-convert -w 1500 -h 500 "$svg" -o "$PNG_DIR/social/${filename}.png"
  elif [[ "$filename" == *"1200x630"* ]]; then
    rsvg-convert -w 1200 -h 630 "$svg" -o "$PNG_DIR/social/${filename}.png"
  elif [[ "$filename" == *"400"* ]]; then
    rsvg-convert -w 400 -h 400 "$svg" -o "$PNG_DIR/social/${filename}.png"
  else
    # Default
    rsvg-convert -w 800 "$svg" -o "$PNG_DIR/social/${filename}.png"
  fi
  echo "  ✓ $filename.png"
done

# Export favicons at all required sizes
echo "Exporting favicons..."
for svg in "$SVG_DIR/favicon"/*.svg; do
  [ -f "$svg" ] || continue
  filename=$(basename "$svg" .svg)

  # Export at standard favicon sizes
  for size in 16 32 48 96 180 192 512; do
    rsvg-convert -w "$size" -h "$size" "$svg" -o "$PNG_DIR/favicon/${filename}-${size}.png"
  done
  echo "  ✓ $filename (all sizes)"
done

echo ""
echo "Export complete!"
echo "PNGs saved to: $PNG_DIR"
