#!/bin/bash
# Cleanup screenshots older than 2 days
# Daily summaries are kept permanently

find "$HOME/ai-mirror/screenshots" -type d -mtime +2 -exec rm -rf {} + 2>/dev/null
find "$HOME/ai-mirror/screenshots" -type f -mtime +2 -delete 2>/dev/null

# Log cleanup
echo "$(date): Cleaned up screenshots older than 2 days" >> "$HOME/ai-mirror/cleanup.log"
