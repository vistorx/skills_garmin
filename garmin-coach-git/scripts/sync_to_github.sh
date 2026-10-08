#!/bin/bash
# Auto-sync garmin skills to GitHub
# Usage: sync_to_github.sh "commit message"

SKILLS_DIR="/opt/data/profiles/garmin-coach/skills/fitness"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MSG="${1:-chore: update skills}"
# SSH key configured via git core.sshCommand — no extra env vars needed.

cd "$SKILLS_DIR" || exit 1

# Check if anything changed
if git diff --quiet && git diff --staged --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
  echo "Nothing to commit."
  exit 0
fi

git add .
git commit -m "$MSG"
git push origin main 2>&1

echo "Synced to GitHub."
