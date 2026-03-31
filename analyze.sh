#!/bin/bash
# End-of-day screenshot analysis
# Sends screenshots to Claude for deep activity analysis
# Correlates with calendar and meeting data via timestamps

DATE=${1:-$(date +%Y-%m-%d)}
SCREENSHOT_DIR="$HOME/ai-mirror/screenshots/$DATE"
SUMMARY_DIR="$HOME/ai-mirror/daily-summaries"
SUMMARY_FILE="$SUMMARY_DIR/$DATE.md"

if [ ! -d "$SCREENSHOT_DIR" ]; then
    echo "No screenshots found for $DATE"
    exit 1
fi

# Count available screenshots
TOTAL=$(ls "$SCREENSHOT_DIR"/*.jpg 2>/dev/null | wc -l | tr -d ' ')
echo "Found $TOTAL screenshots for $DATE"

if [ "$TOTAL" -eq 0 ]; then
    echo "No screenshots to analyze"
    exit 1
fi

# Sample evenly across the day if more than 300 screenshots
# This preserves temporal coverage while keeping analysis deep
if [ "$TOTAL" -gt 300 ]; then
    STEP=$((TOTAL / 300))
    SELECTED=$(ls "$SCREENSHOT_DIR"/*.jpg | awk "NR % $STEP == 1")
    SAMPLE_COUNT=$(echo "$SELECTED" | wc -l | tr -d ' ')
    echo "Sampled $SAMPLE_COUNT screenshots (every ${STEP}th) for analysis"
else
    SELECTED=$(ls "$SCREENSHOT_DIR"/*.jpg)
    SAMPLE_COUNT=$TOTAL
    echo "Analyzing all $SAMPLE_COUNT screenshots"
fi

# Build the file list for Claude
FILE_ARGS=""
for f in $SELECTED; do
    FILE_ARGS="$FILE_ARGS $f"
done

# Run Claude Code in non-interactive mode for analysis
claude --print -m opus "You are analyzing a day's worth of screenshots from Dhruv Saharya's laptop to understand how he spends his working time.

## Context
Dhruv is Director of Customer Success at Atlan. He leads 3 pods (EMEA, Growth, EST) with 15 direct reports. His day involves a mix of: customer calls, 1:1s with team, internal strategy meetings, and work between meetings.

## Your Task
Analyze all the screenshots provided. Each filename is a timestamp (HHMMSS.jpg) from $DATE.

For EVERY screenshot:
1. Note the timestamp
2. Identify what app/tool is visible (Zoom, Chrome, Slack, terminal, etc.)
3. If Chrome: what site/tool (Vitally, Confluence, Google Sheets, Claude, Glean, Linear, etc.)
4. What specific activity is happening (reading, writing, building, browsing, on a call, etc.)
5. Is this AI-assisted work or manual/traditional work? Be nuanced — using Slack isn't automatically manual, and being on Zoom doesn't mean no AI work is happening in other windows.

Then produce a daily summary in this format:

# Daily Activity Report — $DATE

## Time Map
(Chronological breakdown of the day in blocks, with what was happening in each block)

## Activity Breakdown
(Categories discovered from the data — do NOT use a preset list. Let the screenshots tell you what the categories are.)

## AI-Native vs Manual Work
- Total active time: Xh Ym
- AI-assisted time: Xh Ym (X%) — explain what qualifies
- Manual/traditional time: Xh Ym (X%) — explain what qualifies
- Ambiguous: Xh Ym (X%) — calls, reading, etc. where you can't determine

## Patterns Noticed
(What stood out? Long stretches of repetitive work? Context switching? Deep focus blocks?)

## Biggest Opportunity
(ONE specific workflow from today that would benefit most from AI assistance. Be specific about what was being done and how AI could help.)

Read each screenshot carefully. Go deep, not wide." $FILE_ARGS > "$SUMMARY_FILE" 2>/dev/null

if [ -f "$SUMMARY_FILE" ] && [ -s "$SUMMARY_FILE" ]; then
    echo "Analysis complete: $SUMMARY_FILE"
else
    echo "Analysis failed or produced empty output"
    exit 1
fi
