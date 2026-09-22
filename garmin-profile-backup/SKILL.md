---
name: garmin-profile-backup
description: Use when backing up garmin-coach profile to GitHub.
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux]
metadata:
  hermes:
    tags: [git, github, ssh, backup, profile, garmin-coach]
---

# Garmin Coach — Backup Profil Complet

Synchronise le profil complet `garmin-coach` vers le repo privé GitHub.

## Repo

- **URL** : https://github.com/vistorx/hermes_garmin_profile
- **Racine locale** : `/opt/data/profiles/garmin-coach/` (git direct, plus de backup_repo/)
- **Script** : `bash .../skills/fitness/garmin-profile-backup/scripts/backup_sync.sh "msg"`
- **Hook** : `agent-hooks/auto-backup-profile.sh`

## SSH

- **Clé** : `/opt/data/profiles/garmin-coach/home/.ssh/id_ed25519`
- `core.sshCommand` configuré dans le repo — pas besoin de `GIT_SSH_COMMAND` manuel.

## Contenu backupé

`config.yaml`, `profile.yaml`, `SOUL.md`, `.env`, `memories/`, `skills/`, `agent-hooks/`, `hooks/`, `scripts/`, `cron/`, `plans/`.

**Exclus via `.gitignore`** : `lazy-packages/`, `lsp/`, `bin/`, `sessions/`, `logs/`, `cache/`, `*.db`, `*.lock`, `auth.json`, `home/`, `workspace/`, `.npm/`, `.local/`, `.hermes_history`, `scripts/whatsapp-bridge/node_modules/`, `cron/ticker_*`, `cron/.hb_*`.

## Pitfalls

- **Git direct dans `/garmin-coach/`** — plus de `backup_repo/`, le `.git` est à la racine du profil.
- **`git add` sélectif** — ne pas faire `git add -A` (trop de bruit), ajouter explicitement les dossiers voulus.
- **`skills/fitness/` a son propre `.git`** — exclu par `.gitignore` (ne pas faire de submodule).
- **Toujours `--force` push** si conflit — le local fait référence.
