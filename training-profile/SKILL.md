---
name: training-profile
description: Track user's training context and profile across sessions.
version: 1.0.0
author: Victor Ourd, Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [garmin, training, fitness, profile, planning]
    related_skills: [garmin-workouts]
---

# Training Profile Skill

This skill governs how an athlete's training context is read, maintained, and updated across sessions. It applies to **any sport, any routine, any athlete**. The profile belongs to the person — it reflects their world, not a template.

## When to Use

- Before planning, adjusting, or discussing any training session.
- Before answering questions about level, equipment, injury status, or history.
- Whenever new information surfaces mid-conversation: equipment, preference, injury, session feedback → **record immediately**, don't wait for a dedicated update.

Don't use for: building workout files → `garmin-workouts`. Planning the week → `garmin-weekly-plan`.

## Where the Data Lives

The athlete's context lives in **user profile memory** (`context_notes` target='user'). Never hardcode personal data in this skill file — it won't stay in sync.

- **To read**: use what's in memory at session start.
- **To write**: call `context_notes(action='add'/'replace', target='user')` — always read existing entries first to replace rather than duplicate. Keep entries concise and factual.

## Memory Structure

Maintain these fields (update incrementally as data arrives):

```
sports_routine       — which sports, fixed vs flexible, typical days
availability         — per-day slots + max durations (warm-up/cool-down included)
level_and_equipment  — per sport: self-assessed level + available gear
job_lifestyle        — type de métier (physique/sédentaire), posture, stress, horaires, trajet
objectives           — race target / general goal / "maintien" / rehab
injury_status        — current injuries: location, severity /10, treatment, date last confirmed
session_preferences  — warmup style, recovery type, set timing, feedback preference
```

## Filling Gaps: Fetch First, Then Ask

1. **Always check Garmin data first**: `get_activities`, `get_personal_record`, `get_race_predictions`, `get_training_readiness` — infer what you can before asking.
2. Ask only about what Garmin can't reveal: subjective preference, current pain, equipment specifics, motivation.
3. One or two specific questions at a time — never a form dump.

## Availability: Frame Correctly

Availability is **time that could be used for training**, not a schedule to fill. Always communicate it that way. Key rules:
- Max duration given by the athlete already includes warm-up and cool-down — never add time on top.
- Re-confirm at the start of each new planning cycle — schedules change.
- Empty slots are always valid — say so explicitly.

## Pre-Planning Safety Checks

Before any session is finalized:

1. **Bad session flag**: if the last session in that sport had a negative signal (pain, abandoned, very high RPE, HR anomaly) and the athlete hasn't explained it this session → ask before proposing anything new.
2. **Injury flag**: if an injury is active and relevant to the planned session → confirm current status. Don't assume last known state still holds after any gap.
3. **Never plan a progression right after a flagged bad session** without addressing it first.

### Toujours compléter le profil à la planéifícation — règle absolue

Au début de chaque session de planification, même si le profil est complet, vérifier activement :
- Les disponibilités réelles de la semaine (pas juste le pattern habituel)
- L'état physique du jour (ressenti, douleurs, courbatures)
- Le statut des blessures actives (ne jamais supposer que c'est mieux)
- La dernière séance (comment ça s'est passé si <48h)
- Les événements de vie (stress, sommeil dégradé, voyage, bo ulot chargé)

Un profil en mémoire = une base. La conversation du jour = la réalité. Toujours privilégier ce que l'athlète dit maintenant sur ce qui est enregistré.

## GitHub Sync

Après toute modification de skill (création, patch, mise à jour d'une référence), toujours committer et pusher :

```bash
bash /opt/data/profiles/garmin-coach/skills/fitness/garmin-workouts/scripts/sync_to_github.sh "feat/fix/chore: description"
```

- Skills dir (repo racine) : `/opt/data/profiles/garmin-coach/skills/fitness`
- Clé SSH : `/opt/data/profiles/garmin-coach/home/.ssh/id_ed25519`
- Repo : https://github.com/vistorx/skills_garmin

## Equipment Library

L'équipement est stocké dans `level_and_equipment` en mémoire. Ce qui importe :
- **Quoi** : ce dont l'athlète dispose (tapis, haltères, élastiques, banc, corde, box…)
- **Pour quoi** : utile à la construction des séances (un tapis = exos au sol possibles)
- **Pas besoin de tracker l'usage** : on ne note pas qu'il a utilisé son tapis mardi — on sait juste qu'il en a un

Questions à poser en onboarding (block 3) :
- Pour le renfo/muscu : poids de corps seul / élastiques / haltères (kg ?) / barre / kettlebell / accès salle ?
- Tapis de sol ?
- Accessoires cardio : corde à sauter, vélo, rameur ?
- Pour les sports techniques : matériel spécifique au sport ?

Mise à jour : si l'athlète mentionne un nouvel équipement → mettre à jour `level_and_equipment` immédiatement.

## Retours de séance → Garmin

À chaque fois que Victor donne un retour sur une séance terminée, l'écrire immédiatement dans la description de l'activité Garmin correspondante via `set_activity_description`.

**Quoi noter** :
- Ressenti général (feeling, fatigue, motivation)
- Douleurs ou gênes : localisation, intensité, durée, évolution pendant/après
- Équipement utilisé (genouillère, chaussures, etc.) et effet observé
- Conditions particulières (chaleur, terrain, stress)
- Toute info utile pour comprendre la séance rétrospectivement

**Pourquoi** : ça historise les sensations directement dans Garmin Connect, là où les données objectives sont déjà stockées. Pratique pour le kiné, pour suivre l'évolution des blessures, pour voir les patterns sur la durée.

**Workflow** :
1. Identifier l'activité via `get_activities` (sport + date + heure)
2. Écrire la description avec `set_activity_description`
3. Faire les deux en une fois si plusieurs séances à noter

## Edge Cases

- Garmin status unavailable → use readiness + acute load trend, state the limitation explicitly.
- Readiness data stale (>24h) → flag it, use last available + recent activities.
- New athlete / no history → skip trend sections, use VO2max + profile level as baseline, note it.
