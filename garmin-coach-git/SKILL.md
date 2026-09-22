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

# Garmin Coach — Skills Git (repo public)

Synchronise les skills fitness vers le repo public GitHub.

## Repo

- **URL** : https://github.com/vistorx/skills_garmin
- **Racine locale** : `/opt/data/profiles/garmin-coach/skills/fitness/`
- **Script** : `bash .../skills/fitness/garmin-coach-git/scripts/sync_to_github.sh "msg"`
- **Hook** : `agent-hooks/auto-sync-skills.sh`

## SSH

- **Clé** : `/opt/data/profiles/garmin-coach/home/.ssh/id_ed25519`
- `core.sshCommand` configuré dans le repo — pas besoin de `GIT_SSH_COMMAND` manuel.
- **Pitfall** : `$HOME` système est `/opt/data/profiles/garmin-coach/home/`, SSH cherche les clés dans `/opt/data/.ssh/`. `core.sshCommand` court-circuite ça.

Vérification :
```bash
ssh -i /opt/data/profiles/garmin-coach/home/.ssh/id_ed25519 -o StrictHostKeyChecking=no -T git@github.com
```

## Pitfalls

- Le `.git` est dans `skills/fitness/`, pas dans `skills/`. Ne jamais remonter le `.git` au parent — les autres catégories ne doivent pas être trackées par ce repo public.
- Pour le backup profil complet, voir le skill `garmin-profile-backup`.
