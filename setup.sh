#!/bin/bash
# ============================================================
# AI Mirror — Setup Script
# Automated daily activity tracking + AI-native work analysis
#
# Built with Claude
#
# Prerequisites:
#   - macOS
#   - Homebrew (brew.sh)
#   - GitHub CLI (gh) — logged in
#   - Claude Code CLI (claude) — logged in
#   - Claude account with Slack + Granola + Google Calendar MCP connectors
#
# Usage: bash setup.sh
# ============================================================

set -e

echo "================================================"
echo "  AI Mirror — Setup"
echo "  Automated AI-native work analysis"
echo "================================================"
echo ""

# ---- Collect user info ----
read -p "Your full name: " USER_NAME
read -p "Your email (for git): " USER_EMAIL
read -p "Your Slack user ID (find it in Slack profile > three dots > Copy member ID): " SLACK_USER_ID
read -p "GitHub username: " GH_USERNAME
echo ""

# ---- Check prerequisites ----
echo "Checking prerequisites..."

if ! command -v brew &>/dev/null; then
    echo "ERROR: Homebrew not found. Install from https://brew.sh"
    exit 1
fi

if ! command -v gh &>/dev/null; then
    echo "ERROR: GitHub CLI not found. Run: brew install gh"
    exit 1
fi

if ! gh auth status &>/dev/null 2>&1; then
    echo "ERROR: GitHub CLI not authenticated. Run: gh auth login"
    exit 1
fi

if ! command -v claude &>/dev/null; then
    echo "ERROR: Claude Code CLI not found. Install from https://claude.ai/code"
    exit 1
fi

echo "All prerequisites met."
echo ""

# ---- Create directories ----
echo "Creating directories..."
mkdir -p ~/ai-mirror/screenshots ~/ai-mirror/daily-summaries ~/ai-mirror/weekly-summaries

# ---- Create capture script ----
echo "Creating capture script..."
cat > ~/ai-mirror/capture.sh << 'CAPTURE_EOF'
#!/bin/bash
SCREENSHOT_DIR="$HOME/ai-mirror/screenshots/$(date +%Y-%m-%d)"
mkdir -p "$SCREENSHOT_DIR"

TIMESTAMP=$(date +%H%M%S)
FILEPATH="$SCREENSHOT_DIR/$TIMESTAMP.jpg"

screencapture -x -t png "/tmp/ai-mirror-temp.png" 2>/dev/null
sips -s format jpeg -s formatOptions 40 "/tmp/ai-mirror-temp.png" --out "$FILEPATH" >/dev/null 2>&1
rm -f "/tmp/ai-mirror-temp.png"

PREV=$(ls -t "$SCREENSHOT_DIR"/*.jpg 2>/dev/null | head -2 | tail -1)
if [ -n "$PREV" ] && [ "$PREV" != "$FILEPATH" ]; then
    CURR_HASH=$(md5 -q "$FILEPATH" 2>/dev/null)
    PREV_HASH=$(md5 -q "$PREV" 2>/dev/null)
    if [ "$CURR_HASH" = "$PREV_HASH" ]; then
        rm "$FILEPATH"
    fi
fi
CAPTURE_EOF

# ---- Create analysis script ----
echo "Creating analysis script..."
cat > ~/ai-mirror/analyze.sh << 'ANALYZE_EOF'
#!/bin/bash
DATE=${1:-$(date +%Y-%m-%d)}
SCREENSHOT_DIR="$HOME/ai-mirror/screenshots/$DATE"
SUMMARY_DIR="$HOME/ai-mirror/daily-summaries"
SUMMARY_FILE="$SUMMARY_DIR/$DATE.md"

if [ ! -d "$SCREENSHOT_DIR" ]; then
    echo "No screenshots found for $DATE"
    exit 1
fi

TOTAL=$(ls "$SCREENSHOT_DIR"/*.jpg 2>/dev/null | wc -l | tr -d ' ')
echo "Found $TOTAL screenshots for $DATE"

if [ "$TOTAL" -eq 0 ]; then
    echo "No screenshots to analyze"
    exit 1
fi

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

FILE_ARGS=""
for f in $SELECTED; do
    FILE_ARGS="$FILE_ARGS $f"
done

claude --print -m opus "You are analyzing a day's worth of screenshots from a user's laptop to understand how they spend their working time.

## Your Task
Analyze all the screenshots provided. Each filename is a timestamp (HHMMSS.jpg) from $DATE.

For EVERY screenshot:
1. Note the timestamp
2. Identify what app/tool is visible
3. If browser: what site/tool
4. What specific activity is happening
5. Is this AI-assisted work or manual/traditional work? Be nuanced.

Produce a daily summary using ONLY this format. Use tables everywhere.

# Daily Activity Report — $DATE

## Time Map

| Time Block | Duration | App/Tool | Activity | AI-Native? |
|---|---|---|---|---|
| (fill from screenshots) | | | | |

## Activity Breakdown

| Category | Time | % of Day | Details |
|---|---|---|---|
| (let the screenshots define categories) | | | |

## AI-Native Score

| Metric | Time | % |
|---|---|---|
| Total active time | Xh Ym | 100% |
| AI-assisted | Xh Ym | X% |
| Manual/traditional | Xh Ym | X% |
| Ambiguous | Xh Ym | X% |

## Context Switching

| Metric | Value |
|---|---|
| Number of app switches | X |
| Longest uninterrupted block | Xm (doing what) |
| Most fragmented hour | X:00-X:00 (Y switches) |

## Top 3 Automation Opportunities

| # | What you did manually | Time spent | How AI could do it |
|---|---|---|---|
| 1 | | | |
| 2 | | | |
| 3 | | | |

Go deep, not wide. Let the data tell the story." $FILE_ARGS > "$SUMMARY_FILE" 2>/dev/null

if [ -f "$SUMMARY_FILE" ] && [ -s "$SUMMARY_FILE" ]; then
    echo "Analysis complete: $SUMMARY_FILE"
    cd "$HOME/ai-mirror"
    git add "daily-summaries/$DATE.md"
    git commit -m "Daily activity report — $DATE"
    git push origin main 2>/dev/null
    echo "Summary pushed to GitHub"
else
    echo "Analysis failed or produced empty output"
    mkdir -p "$SUMMARY_DIR"
    echo "FAILED — Analysis produced no output. Screenshots: $TOTAL, Sampled: $SAMPLE_COUNT" > "$SUMMARY_DIR/$DATE.md"
    cd "$HOME/ai-mirror"
    git add "daily-summaries/$DATE.md"
    git commit -m "Analysis FAILED — $DATE"
    git push origin main 2>/dev/null
    exit 1
fi
ANALYZE_EOF

# ---- Create cleanup script ----
echo "Creating cleanup script..."
cat > ~/ai-mirror/cleanup.sh << 'CLEANUP_EOF'
#!/bin/bash
find "$HOME/ai-mirror/screenshots" -type d -mtime +2 -exec rm -rf {} + 2>/dev/null
find "$HOME/ai-mirror/screenshots" -type f -mtime +2 -delete 2>/dev/null
find "$HOME/ai-mirror" -name ".analyzed-*" -mtime +2 -delete 2>/dev/null
echo "$(date): Cleaned up screenshots older than 2 days" >> "$HOME/ai-mirror/cleanup.log"
CLEANUP_EOF

chmod +x ~/ai-mirror/capture.sh ~/ai-mirror/analyze.sh ~/ai-mirror/cleanup.sh

# ---- Create sleep hook ----
echo "Creating sleep hook..."
cat > ~/.sleep << 'SLEEP_EOF'
#!/bin/bash
DATE=$(date +%Y-%m-%d)
HOUR=$(date +%H)
LOCK_FILE="$HOME/ai-mirror/.analyzed-$DATE"

if [ "$HOUR" -lt 21 ]; then
    exit 0
fi

if [ -f "$LOCK_FILE" ]; then
    exit 0
fi

SCREENSHOT_DIR="$HOME/ai-mirror/screenshots/$DATE"
TOTAL=$(ls "$SCREENSHOT_DIR"/*.jpg 2>/dev/null | wc -l | tr -d ' ')

if [ "$TOTAL" -gt 20 ]; then
    touch "$LOCK_FILE"
    /bin/bash "$HOME/ai-mirror/analyze.sh" "$DATE" >> "$HOME/ai-mirror/analyze-output.log" 2>&1 &
fi
SLEEP_EOF
chmod +x ~/.sleep

# ---- Install sleepwatcher ----
echo "Installing sleepwatcher..."
brew install sleepwatcher 2>/dev/null || true
brew services start sleepwatcher 2>/dev/null || true

# ---- Create LaunchAgents ----
echo "Setting up LaunchAgents..."

cat > ~/Library/LaunchAgents/com.ai-mirror.capture.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.ai-mirror.capture</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$HOME/ai-mirror/capture.sh</string>
    </array>
    <key>StartInterval</key>
    <integer>30</integer>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>$HOME/ai-mirror/capture-error.log</string>
</dict>
</plist>
EOF

cat > ~/Library/LaunchAgents/com.ai-mirror.cleanup.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.ai-mirror.cleanup</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$HOME/ai-mirror/cleanup.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>3</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardErrorPath</key>
    <string>$HOME/ai-mirror/cleanup-error.log</string>
</dict>
</plist>
EOF

launchctl load ~/Library/LaunchAgents/com.ai-mirror.capture.plist 2>/dev/null
launchctl load ~/Library/LaunchAgents/com.ai-mirror.cleanup.plist 2>/dev/null

# ---- Initialize Git repo ----
echo "Setting up private GitHub repo..."
cd ~/ai-mirror
git init 2>/dev/null || true
git config user.name "$USER_NAME"
git config user.email "$USER_EMAIL"

cat > .gitignore << 'GI_EOF'
screenshots/
*.log
.analyzed-*
.DS_Store
GI_EOF

git add -A
git commit -m "AI Mirror — initial setup" 2>/dev/null || true
gh auth setup-git 2>/dev/null
gh repo create ai-mirror --private --source=. --push --description "AI Mirror — daily activity analysis" 2>/dev/null || git push origin main 2>/dev/null

# ---- Print next steps ----
echo ""
echo "================================================"
echo "  LOCAL SETUP COMPLETE"
echo "================================================"
echo ""
echo "Screenshots are now being captured every 30 seconds."
echo "Analysis runs automatically when you close your laptop after 9pm."
echo ""
echo "NEXT STEPS (manual — requires your Claude account):"
echo ""
echo "1. Go to https://claude.ai/settings/connectors"
echo "   Ensure these MCP connectors are connected:"
echo "   - Slack"
echo "   - Granola"
echo "   - Google Calendar"
echo ""
echo "2. Go to https://claude.ai/code/scheduled"
echo "   Create two scheduled agents:"
echo ""
echo "   a) DAILY SLACK DELIVERY (runs every night)"
echo "      - Cron: 30 20 * * *  (2am IST / adjust for your timezone)"
echo "      - Repo: https://github.com/$GH_USERNAME/ai-mirror"
echo "      - MCP: Slack, Granola, Google Calendar"
echo "      - Prompt: See TRIGGERS.md in your repo"
echo ""
echo "   b) WEEKLY TREND REPORT (runs Sunday evening)"
echo "      - Cron: 0 13 * * 0  (6:30pm IST / adjust for your timezone)"
echo "      - Repo: https://github.com/$GH_USERNAME/ai-mirror"
echo "      - MCP: Slack"
echo "      - Prompt: See TRIGGERS.md in your repo"
echo ""
echo "3. Grant screen recording permission if screenshots are blank:"
echo "   System Settings → Privacy & Security → Screen Recording → enable Terminal/iTerm"
echo ""
echo "4. Update SLACK_USER_ID in TRIGGERS.md with: $SLACK_USER_ID"
echo ""
echo "Your private repo: https://github.com/$GH_USERNAME/ai-mirror"
echo "================================================"
