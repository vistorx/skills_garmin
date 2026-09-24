#!/bin/bash
# Backup profil garmin-coach vers GitHub (repo privé)
# Le repo git est directement /opt/data/profiles/garmin-coach (plus de backup_repo/).
# Ce qui est versionné est piloté par .gitignore à la racine du profil.
# Usage: backup_sync.sh "commit message"
set -uo pipefail

REPO="/opt/data/profiles/garmin-coach"
MSG="${1:-chore: backup profile}"

cd "$REPO" || { echo "ERROR: $REPO introuvable"; exit 1; }
git rev-parse --git-dir >/dev/null 2>&1 || { echo "ERROR: $REPO n'est pas un repo git"; exit 1; }

git add -A
if git diff --staged --quiet; then
  echo "Nothing to commit."
else
  git commit -q -m "$MSG" || { echo "ERROR: commit échoué"; exit 1; }
  echo "Committed: $(git log -1 --format='%h %s')"
fi

# Push (aussi s'il reste des commits locaux non poussés)
if ! git push origin main 2>&1; then
  echo "ERROR: push échoué"
  exit 1
fi

echo "Backup OK — HEAD $(git rev-parse --short HEAD) = origin/$(git rev-parse --short origin/main)"
