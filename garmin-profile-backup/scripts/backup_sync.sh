#!/bin/bash
# Backup profil garmin-coach vers GitHub (repo privé)
# Usage: backup_sync.sh "commit message"

SRC="/opt/data/profiles/garmin-coach"
DEST="/opt/data/profiles/garmin-coach/backup_repo"
MSG="${1:-chore: backup profile}"

# --- Copie des fichiers ---

# Fichiers racine
cp "$SRC/config.yaml"   "$DEST/config.yaml"
cp "$SRC/profile.yaml"  "$DEST/profile.yaml"
cp "$SRC/SOUL.md"       "$DEST/SOUL.md"

# Mémoire (sans .lock)
mkdir -p "$DEST/memories"
cp "$SRC/memories/MEMORY.md" "$DEST/memories/" 2>/dev/null || true
cp "$SRC/memories/USER.md"   "$DEST/memories/" 2>/dev/null || true

# Skills (entier, le .git interne est exclu par .gitignore)
mkdir -p "$DEST/skills"
cp -r "$SRC/skills/." "$DEST/skills/"
# Supprimer les .git internes
find "$DEST/skills" -name ".git" -type d -exec rm -rf {} + 2>/dev/null || true
find "$DEST/skills" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

# Agent hooks
mkdir -p "$DEST/agent-hooks"
cp -r "$SRC/agent-hooks/." "$DEST/agent-hooks/"

# Scripts (sans node_modules)
mkdir -p "$DEST/scripts"
cp -r "$SRC/scripts/." "$DEST/scripts/"
find "$DEST/scripts" -name "node_modules" -type d -exec rm -rf {} + 2>/dev/null || true
find "$DEST/scripts" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

# Cron (définitions seulement, pas executions.db ni output/)
mkdir -p "$DEST/cron"
find "$SRC/cron" -maxdepth 1 \( -name "*.json" -o -name "*.yaml" -o -name "*.yml" \) 2>/dev/null \
  | xargs -I{} cp {} "$DEST/cron/" 2>/dev/null || true

# Hooks
mkdir -p "$DEST/hooks"
cp -r "$SRC/hooks/." "$DEST/hooks/" 2>/dev/null || true

# .env (avec les vraies clés — repo privé)
cp "$SRC/.env" "$DEST/.env" 2>/dev/null || true

# --- Git ---
cd "$DEST" || exit 1

if git diff --quiet && git diff --staged --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
  echo "Nothing to commit."
  exit 0
fi

git add .
git commit -m "$MSG"
git push --force origin main 2>&1

echo "Backup pushed to GitHub."
