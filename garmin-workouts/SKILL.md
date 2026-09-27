---
name: garmin-workouts
description: Create and schedule Garmin workouts via MCP for Victor.
version: 1.0.0
author: Victor Ourd, Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [garmin, workout, running, strength, planning, mcp]
    related_skills: [training-profile]
---

# Garmin Workout Creation Skill

Builds and schedules running and strength workouts via the Garmin Connect MCP. Always check `training-profile` first for Victor's current context (injuries, level, availability).

## When to Use

- Creating, updating, or scheduling any running or strength workout in Garmin Connect.
- Reviewing the AI-managed workout library (prefix `"AI - "`).
- Building a weekly training plan to push to Garmin calendar.

Don't use for: session evaluation, injury tracking, availability — that's `training-profile`.

## Session Libraries

Voir les références pour le détail des types de séances et exercices :
- `references/sessions-running.md` — EF, fractionné court/long, seuil, côtes
- `references/sessions-strength.md` — exercices Garmin par groupe musculaire + templates
- `references/sessions-multi-sport.md` — cyclisme, natation, sports collectifs, escalade, générique
- `references/warmup-protocols.md` — protocoles échauffement par type de séance
- `references/json-examples.md` — structures JSON Garmin annotées

## Vocabulary

- **Workout/entraînement** = template in Garmin library (`get_workouts`, `upload_workout`, `schedule_workout`).
- **Activity/séance** = completed recorded activity (`get_activities`, `get_activity`). This skill does NOT manage past activities.
- Ambiguous "séance": planning context → workout template; "what I did/felt" → completed activity.

Tout ce que Garmin sait déjà — on le lit, on ne le recalcule pas :
- **Zones FC** : lire depuis `get_heart_rates_summary` ou cibler par numéro (`zoneNumber: 2`) dans les steps — Garmin les traduit en FC réelle selon le profil
- **Seuil lactique** : `get_user_profile` → `lactateThresholdSpeed` (m/s) + `lactateThresholdHeartRate`
- **Allures cibles** : `get_race_predictions` → pace 5K, 10K, semi, marathon réelles de l'athlète
- **FTP cyclisme** : `get_cycling_ftp`
- **Statut d'entraînement** : `get_training_status`
- **Disponibilité du jour** : `get_training_readiness`

Jamais estimer ou inventer une zone. Si la donnée n'est pas disponible dans Garmin → demander à l'athlète.

## Exercices : utiliser le catalogue Garmin

Pour chaque exercice de renfo/cardio structuré :
1. Utiliser `list_supported_strength_exercises(query="...")` pour trouver le bon `category` + `exerciseName`
2. Ne jamais inventer un nom. Si non trouvé : prendre la catégorie la plus proche + noter dans `description`
3. 49 catégories disponibles (SQUAT, LUNGE, PLANK, HIP_RAISE, DEADLIFT, CORE…) — voir `references/sessions-strength.md`

## Séance à partir d'une vidéo (Instagram reel…)

- `web_extract` échoue (403) sur Instagram. Utiliser `browser_exec` : la page publique donne la légende via `meta[property=og:description]` (souvent la liste d'exos), et la `<video>` est lisible : seek `currentTime` + `canvas.drawImage` pour faire une planche de ~12-24 frames, puis l'inspecter visuellement.
- Catalogue exact des exercices : `https://connect.garmin.com/web-data/exercises/Exercises.json` (curl) → `categories[CAT].exercises`.
- Exos au temps (plyo 30s) : `conditionTypeId: 2` time au lieu de reps. Adapter volume/amplitude aux blessures du profil et le noter en description.
- **Toujours mettre l'URL de la/des vidéo(s) source en début de `description`** ("Vidéo : <url>") — Victor s'en sert pour retrouver les mouvements. URL sans le paramètre `?stkn=`.
- **Reproduire la vidéo à l'identique** : mêmes exos, même ordre (vidéo 1 puis vidéo 2 si plusieurs), pas d'échauffement ni d'exo ajouté. Victor l'exige. Adaptations blessure = conseils dans le message, pas dans la séance.
- Frames : ~0.35s d'écart (30+ frames), crop sur la zone du corps, horodatées — 12 frames ratent des exos. Les reels commencent souvent par un intro (~3s) à ignorer.
- La lecture de frames reste peu fiable (positions pieds/talons, intro prise pour un exo). **Avant d'uploader, lister les exos identifiés à Victor et lui demander de valider** — il connaît la vidéo. Ses corrections priment.
- Descriptions de step : "EXO n/N (vidéo X) — reps PAR JAMBE/CÔTÉ. Position de départ → mouvement → retour" pour que ce soit lisible sur la montre.

## Types de sports Garmin

Toujours vérifier le `sportTypeKey` exact via `get_activity_types` avant de créer un workout. Exemples connus : `running`, `strength_training`, `cycling`, `indoor_cycling`, `lap_swimming`, `basketball`, `bouldering`, `yoga`, `hiking`.

## Naming Convention

Always prefix `workoutName` with `"AI - "` (e.g. `"AI - Renfo course"`, `"AI - Fractionné court"`). Applies to every sport and test workouts. When the athlete refers to "my sessions" or "the sessions you manage" without detail → workouts starting with `"AI - "`.

## Pre-Planning Checks

Before building/scheduling, fetch live signals:
- `get_training_readiness` + recent sleep for the target day.
- `get_training_status` — aim to keep Victor in **"Productive"** status.
- `get_vo2max_trend` + `get_activities` (last 2–4 weeks) — flat/declining = more stimulus; high load/no rest = back off.
- A rest day beats an overreaching session. A lighter week is a valid outcome.

## Nettoyage de la bibliothèque AI

### Règle de gestion

La bibliothèque `AI -` doit rester propre à tout moment. Avant chaque planification :
1. Lister toutes les séances `AI -` via `get_workouts`
2. Identifier les obsolètes : séances remplacées par une version améliorée, placeholders vides (sport "other"), séances dont le niveau ou le profil ne correspondent plus
3. Lister à Victor ce qui sera supprimé et pourquoi, puis supprimer après confirmation

### Crédit obsolète = ce qui déclenche une suppression
- Une nouvelle version de la séance a été uploadée (l'ancienne est remplacée)
- La séance est un placeholder vide (sport "other", pas de steps)
- Le niveau ou le profil ne correspond plus (ex. "niveau débutant" si l'athlète est confirmé)
- La séance n'a pas été utilisée depuis >8 semaines ET n'est pas dans un cycle en cours

### Ne jamais supprimer sans lister
Toujours afficher la liste de ce qui sera supprimé avec la raison avant d'agir. Jamais de suppression silencieuse.

### Séances non-AI
Les workouts sans préfixe `AI -` ne sont pas gérés par l'agent. Ne pas les supprimer sans demande explicite de l'athlète.
Ceux générés par un plan Garmin Coach (noms "Course tranquille", "Répétitions vitesse"…) ne sont pas supprimables via l'API (400 "workout with ATP plan id") : ne pas réessayer, renvoyer Victor vers Garmin Connect (supprimer le plan Coach).

### Vérifier avant de scheduler

Toujours appeler `get_scheduled_workouts` sur la semaine cible avant d'ajouter des séances. Détecter et supprimer les doublons issus de tentatives précédentes avec `unschedule_workouts`.

## Editing vs Delete-and-Recreate

Prefer editing over recreating. Known MCP limitation: re-uploading with `workoutId` in payload creates a NEW workout (no in-place update).

Workflow:
1. Reuse/schedule an existing workout if it matches.
2. If change needed: upload corrected version → verify with `get_workout_by_id` → only then delete the old one. Never delete first.
3. Check scheduling before replacing: `get_scheduled_workouts` → reschedule on same date(s) after swap. Verify it landed.
4. Never bulk-delete without listing what will be removed and getting confirmation.

## Build on History

Before creating a new session, check the `"AI - "` library and recent activity history for a similar existing session — evolve/progress it rather than starting blank. If no reference exists, discuss structure with Victor before uploading.

## Reinforcement: Always Propose

Every weekly plan must include renfo — not optional. Evolve existing renfo sessions. See `training-profile` for injury/corrective context.

## Running Workouts — Core Rules

1. **Warm-up**: always 12 min — Victor's standard = the fractionné warm-up (footing progressif 7min + plyo genou kiné) on EVERY run type, EF and sortie longue included. See `references/warmup-protocols.md`.
2. Never use Zone 1 for running efforts — Zone 2 minimum.
3. Use `RepeatGroupDTO` for any repeated pattern — never manually duplicate steps.
4. Short intervals (≤1 min effort): **pace targets only** (m/s) — HR has 20–40s lag, zone unreachable. See `references/json-examples.md`.
5. Long blocks (≥2–3 min effort): HR zone targets are fine.
6. Calibrate pace from `get_race_predictions` / personal records — never invent a pace. See `references/sessions-running.md` for %VMA calibration.
7. **Cooldown**: always propose a cooldown step (5 min easy jog/walk) — include in workout if user confirmed it in preferences.

### Fractionné formats (from Decathlon reference method)

| Format | Description | Default use |
|--------|-------------|-------------|
| 30/30 | 30s hard / 30s recovery, 10–15 reps | Best default, most accessible |
| Fractionné long | 400m–3km sustained effort | VO2max development |
| Fartlek | Free-form speed play, min-scale blocks | Variety, HR-zone fine |
| Seuil | Near-threshold sustained | Lactate threshold |
| Pyramidal | Increasing then decreasing duration | Variety |
| Côtes | Hill repeats | Joint-friendly speed work |

**Mandatory adaptation**: given ongoing knee issue, default to submaximal effort and prefer shorter bouts or hill repeats over long sustained hard efforts. Always state explicitly when and why a deviation is made.

## Strength Workouts — Core Rules

1. `RepeatGroupDTO` for every exercise: one iteration = one working set + one rest step, N times.
2. Working set end condition: reps-based (`conditionTypeId: 10, conditionTypeKey: "reps"`) — no timer.
3. Rest steps: lap-button by default (`conditionTypeId: 1, conditionTypeKey: "lap.button"`).
4. Step comment format: `"<reps> fois <exercise short name>"` — e.g. `"12 fois Pont fessier"`.
5. `skipLastRestStep`: always set explicitly (true/false), never silent.
6. Exercise categorization: best-effort Garmin enum match for `category` + `exerciseName` — flag to Victor for visual check.

## Equipment

Victor's actual equipment is in `training-profile` memory — check before proposing exercises. Everyday objects (chair, backpack, wall…) must be explicitly proposed and validated before finalizing any step using them.

## RepeatGroupDTO — Mandatory Structure

See `references/json-examples.md` for full annotated JSON examples (strength, 30/30 pace, fartlek HR).

Key rules:
- `"type": "RepeatGroupDTO"`, `stepTypeId: 6`
- `endCondition`: always `conditionTypeId: 7` (iterations) — omitting it silently corrupts repeat count
- `endConditionValue` = repeat count
- `workoutSteps`: child steps for ONE pass only
- `skipLastRestStep`: always explicit

## Recovery Step End Conditions

- **Timed**: `conditionTypeId: 2, conditionTypeKey: "time"`, value in seconds.
- **Manual/lap-button**: `conditionTypeId: 1, conditionTypeKey: "lap.button"`, no value needed.

Defaults: strength → lap-button. Running → timed (unless user asks otherwise).
