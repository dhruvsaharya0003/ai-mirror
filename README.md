# AI Mirror

Automated daily activity tracking that analyzes how you spend your working time — specifically measuring AI-native vs manual work patterns.

## What It Does

- **Captures** a screenshot every 30 seconds while your laptop is awake
- **Analyzes** the day's screenshots using Claude when you close your laptop after 9pm
- **Delivers** a tabular activity report to your Slack DM every morning
- **Trends** your AI-native work % week over week

## What You Get

**Daily (Slack DM every morning):**
- Time map of your day correlated with your calendar
- Activity breakdown by category (discovered from data, not preset)
- AI-native score (% of time using AI tools vs manual work)
- Context switching metrics
- Top 3 automation opportunities

**Weekly (Slack DM every Sunday):**
- This week vs last week comparison
- AI-native % trend
- Recurring manual workflows that could be automated

## Requirements

- macOS
- [Homebrew](https://brew.sh)
- [GitHub CLI](https://cli.github.com/) (`brew install gh`)
- [Claude Code CLI](https://claude.ai/code) with active subscription
- Claude account with MCP connectors: Slack, Granola, Google Calendar

## Setup

```bash
bash setup.sh
```

The script handles local setup (screenshot capture, analysis, cleanup). You'll then need to create two scheduled agents in Claude — the script prints instructions and `TRIGGERS.md` has the prompts.

## Architecture

```
Local (your Mac)                    Cloud (Claude)
├── Capture (every 30s)             ├── Daily delivery (Slack DM)
├── Analysis (on lid close >9pm)    │   + Calendar/Granola enrichment
├── Cleanup (3am, >2 days)          └── Weekly trend (Sunday Slack DM)
└── Push summary → GitHub ─────────────→ Read by cloud agents
```

Screenshots never leave your laptop. Only text summaries (~10KB) are pushed to your private GitHub repo.

## Storage

- ~500MB/day of screenshots, auto-deleted after 2 days (~1GB max)
- Daily summaries persist (~10KB each)

## Privacy

- Screenshots stay local — never pushed to any cloud
- GitHub repo is private — only you can see summaries
- Slack DMs go to your self-DM
- All data sources (Slack, Granola, Calendar) use your own account permissions

## Built By

An experiment in measuring and improving AI-native work habits — built with Claude.
