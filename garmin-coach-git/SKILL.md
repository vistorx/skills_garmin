---
name: garmin-coach-git
description: Use when syncing skills or backup repos for garmin-coach.
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux]
metadata:
  hermes:
    tags: [git, github, ssh, backup, skills, garmin-coach]
---

# Garmin Coach — Git Repos

Gestion des deux repos GitHub du profil `garmin-coach`.

## SSH

- **Clé** : `/opt/data/profiles/garmin-coach/home/.ssh/id_ed25519`
- **Mécanisme** : `core.sshCommand` configuré dans chaque repo — push/pull sans `GIT_SSH_COMMAND` manuel
- **Pitfall** : `$HOME` système est `/opt/data/profiles/garmin-coach/home/`, SSH cherche les clés dans `/opt/data/.ssh/`. `core.sshCommand` pointe explicitement vers la clé du profil pour court-circuiter ça.

Vérification :
```bash
ssh -i /opt/data/profiles/garmin-coach/home/.ssh/id_ed25519 -o StrictHostKeyChecking=no -T git@github.com
```

## Repo public — Skills fitness

- **URL** : https://github.com/vistorx/skills_garmin
- **Racine locale** : `/opt/data/profiles/garmin-coach/skills/fitness/`
- **Script** : `bash .../skills/fitness/scripts/sync_to_github.sh "msg"`
- **Auto-sync** : hook `agent-hooks/auto-sync-skills.sh` déclenché après `skill_manage`/`write_file`/`patch` sur `skills/fitness/`

**Pitfall** : le `.git` est dans `skills/fitness/`, pas dans `skills/`. Ne jamais remonter le `.git` au dossier parent — les autres catégories de skills ne doivent pas être trackées par ce repo public.

## Repo privé — Backup profil complet

- **URL** : https://github.com/vistorx/hermes_garmin_profile
- **Racine locale** : `/opt/data/profiles/garmin-coach/backup_repo/`
- **Script** : `bash .../backup_repo/scripts/backup_sync.sh "msg"`
- **Push** : `--force` systématique — le local fait toujours référence

Contenu backupé : `config.yaml`, `profile.yaml`, `SOUL.md`, `.env`, `memories/`, `skills/`, `agent-hooks/`, `hooks/`, `scripts/`, `cron/`, `plans/`.

Exclus : `lazy-packages/`, `lsp/`, `bin/`, `sessions/`, `logs/`, `cache/`, `*.db`, `*.lock`, `auth.json`, `home/.cache/`, `workspace/`, `backup_repo/`.

**Auto-backup** : hook `agent-hooks/auto-backup-profile.sh` déclenché après `skill_manage`/`write_file`/`patch` sur tout fichier tracké.

**Pitfall** : `rsync` absent sur ce système — le script utilise `cp -r` + `find -exec rm -rf`. Ne pas remplacer par `rsync` sans vérifier `which rsync`.

**Pitfall** : ne pas merger le remote en cas de conflit — toujours `--force`. Un merge sur un backup croise les états et corrompt l'historique.

**Pitfall** : les dossiers vides ne sont pas trackés par git — ajouter un `.gitkeep` si le répertoire doit apparaître dans le repo.

**Pitfall** : vérifier le `.gitignore` avant tout push — un fichier silencieusement ignoré (ex : `.env`) n'apparaît pas dans `git status` et ne sera jamais commité. Retirer la ligne du `.gitignore` si le fichier doit être tracké (le repo privé peut tracker `.env`).
