#!/bin/bash
# Screenshot capture script — runs every 30 seconds
# Captures silently, stores with timestamp, lightweight dedup (identical frames only)

SCREENSHOT_DIR="$HOME/ai-mirror/screenshots/$(date +%Y-%m-%d)"
mkdir -p "$SCREENSHOT_DIR"

TIMESTAMP=$(date +%H%M%S)
FILEPATH="$SCREENSHOT_DIR/$TIMESTAMP.jpg"

# Capture silently (-x) as PNG first, then compress to JPEG at 40% quality
# 40% JPEG is still readable for analysis but ~200-300KB vs 5MB
screencapture -x -t png "/tmp/ai-mirror-temp.png" 2>/dev/null
sips -s format jpeg -s formatOptions 40 "/tmp/ai-mirror-temp.png" --out "$FILEPATH" >/dev/null 2>&1
rm -f "/tmp/ai-mirror-temp.png"

# Light dedup: only remove if IDENTICAL to previous screenshot (byte-level match)
# This preserves near-similar screenshots (same app, different content)
PREV=$(ls -t "$SCREENSHOT_DIR"/*.jpg 2>/dev/null | head -2 | tail -1)
if [ -n "$PREV" ] && [ "$PREV" != "$FILEPATH" ]; then
    CURR_HASH=$(md5 -q "$FILEPATH" 2>/dev/null)
    PREV_HASH=$(md5 -q "$PREV" 2>/dev/null)
    if [ "$CURR_HASH" = "$PREV_HASH" ]; then
        rm "$FILEPATH"
    fi
fi
