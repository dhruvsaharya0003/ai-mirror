# Remote Agent Prompts

Copy these prompts when setting up scheduled agents at https://claude.ai/code/scheduled

Replace `YOUR_SLACK_USER_ID` with your Slack member ID (find it in your Slack profile > three dots > Copy member ID).

---

## 1. Daily Slack Delivery

**Schedule:** Every night (e.g., `30 20 * * *` for 2am IST)
**MCP Connectors:** Slack, Granola, Google Calendar

**Prompt:**

```
You are the delivery and enrichment agent for a daily AI Mirror activity report.

## Task

### Step 1: Find the report
1. Check daily-summaries/ for today's report (YYYY-MM-DD.md).
2. If not found, check yesterday's date.
3. If the file starts with 'FAILED', note this for the alert.

### Step 2: Enrich with Calendar + Granola
If a valid report is found:
1. Use Google Calendar to list meetings for that date.
2. Use Granola to list meetings for that date.
3. Cross-reference the Time Map table with actual calendar events. Add:

## Calendar Correlation

| Time Block (from screenshots) | Calendar Event | Match? | Notes |
|---|---|---|---|
| (fill from data) | | | |

### Step 3: Send via Slack DM
Send to channel_id 'YOUR_SLACK_USER_ID'. Do NOT search for the user.

Format for Slack:
- *bold* for headers
- Monospace blocks for tables
- Start with: *AI Mirror — Daily Report (DATE)*
- Prioritize: AI-Native Score, Top 3 Opportunities, Calendar Correlation
- Keep under 4000 chars

If FAILED: send '*AI Mirror — Alert* :warning: Analysis failed for DATE.'
If no report: send '*AI Mirror* — No report for today. Laptop may have been closed before 9pm.'

Do this now.
```

---

## 2. Weekly Trend Report

**Schedule:** Sunday evening (e.g., `0 13 * * 0` for 6:30pm IST)
**MCP Connectors:** Slack

**Prompt:**

```
You are a weekly trend analyzer for the AI Mirror system.

## Task

Read all daily summary files in daily-summaries/ from the past 7 days. Produce a weekly trend report.

*AI Mirror — Weekly Trend Report (week ending DATE)*

*Summary*
| Metric | This Week | Last Week | Trend |
|---|---|---|---|
| Avg daily active time | Xh Ym | Xh Ym | up/down/same |
| AI-native % | X% | X% | up/down/same |
| Manual % | X% | X% | up/down/same |
| Avg context switches/day | X | X | up/down/same |
| Longest focus block (avg) | Xm | Xm | up/down/same |

*Day-by-Day*
| Day | Active Time | AI-Native % | Manual % | Top Manual Activity |
|---|---|---|---|---|
| Mon-Sun | | | | |

*Top Recurring Manual Workflows*
| Workflow | Times seen | Total time | Automatable? |
|---|---|---|---|

*Key Insight*
ONE observation about work pattern shifts. Be specific and evidence-based.

Save to weekly-summaries/YYYY-WNN.md, commit, push.
Send via Slack DM to channel_id 'YOUR_SLACK_USER_ID'.

Do this now.
```
