#!/bin/bash
# End-of-day screenshot analysis
# Sends screenshots to Claude for deep activity analysis
# Correlates with calendar and meeting data via timestamps

DATE=${1:-$(date +%Y-%m-%d)}
SCREENSHOT_DIR="$HOME/ai-mirror/screenshots/$DATE"
SUMMARY_DIR="$HOME/ai-mirror-data/daily-summaries"
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
Analyze all the screenshots provided. Each filename is a timestamp (HHMMSS.jpg) from $DATE. The timestamp format is HHMMSS (e.g., 143025 = 2:30:25 PM IST).

For EVERY screenshot:
1. Note the timestamp
2. Identify what app/tool is visible (Zoom, Chrome, Slack, terminal, etc.)
3. If Chrome: what site/tool (Vitally, Confluence, Google Sheets, Claude, Glean, Linear, etc.)
4. What specific activity is happening (reading, writing, building, browsing, on a call, etc.)
5. Is this AI-assisted work or manual/traditional work? Be nuanced — using Slack isn't automatically manual, and being on Zoom doesn't mean no AI work is happening in other windows. Multiple windows may be visible.

Then produce a daily summary using ONLY this format. Use tables everywhere. No prose paragraphs.

# Daily Activity Report — $DATE

## Time Map

| Time Block | Duration | App/Tool | Activity | AI-Native? |
|---|---|---|---|---|
| 9:00-9:45am | 45m | Zoom + Chrome | 1:1 with Adriel, Slack open in background | Ambiguous |
| 9:45-10:15am | 30m | Chrome (Vitally) | Updating account health scores | Manual |
| ... | ... | ... | ... | ... |

## Activity Breakdown

| Category | Time | % of Day | Details |
|---|---|---|---|
| (let the screenshots define the categories — do NOT use a preset list) | | | |

## AI-Native Score

| Metric | Time | % |
|---|---|---|
| Total active time | Xh Ym | 100% |
| AI-assisted | Xh Ym | X% |
| Manual/traditional | Xh Ym | X% |
| Ambiguous (calls, reading) | Xh Ym | X% |

For each row, briefly note what qualified it.

## Context Switching

| Metric | Value |
|---|---|
| Number of app switches | X |
| Longest uninterrupted block | Xm (doing what) |
| Most fragmented hour | X:00-X:00 (Y switches) |

## Top 3 Automation Opportunities

| # | What you did manually | Time spent | How AI could do it |
|---|---|---|---|
| 1 | (specific activity from today) | Xm | (specific suggestion) |
| 2 | | | |
| 3 | | | |

Read each screenshot carefully. Go deep, not wide. Let the data tell the story — do not assume or generalize." $FILE_ARGS > "$SUMMARY_FILE" 2>/dev/null

if [ -f "$SUMMARY_FILE" ] && [ -s "$SUMMARY_FILE" ]; then
    echo "Analysis complete: $SUMMARY_FILE"

    # Push summary to GitHub so the remote Slack agent can pick it up
    cd "$HOME/ai-mirror-data"
    git add "daily-summaries/$DATE.md"
    git commit -m "Daily activity report — $DATE"
    git push origin main 2>/dev/null

    echo "Summary pushed to GitHub"
else
    echo "Analysis failed or produced empty output"
    # Push a failure marker so the remote agent can alert via Slack
    mkdir -p "$SUMMARY_DIR"
    echo "FAILED — Analysis produced no output. Screenshots: $TOTAL, Sampled: $SAMPLE_COUNT" > "$SUMMARY_DIR/$DATE.md"
    cd "$HOME/ai-mirror-data"
    git add "daily-summaries/$DATE.md"
    git commit -m "Analysis FAILED — $DATE"
    git push origin main 2>/dev/null
    exit 1
fi
