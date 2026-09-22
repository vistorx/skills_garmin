---
name: garmin-weekly-plan
description: Plan any training week for any sport mix via Garmin MCP.
version: 1.0.0
author: Victor Ourd, Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [garmin, planning, weekly, training, multi-sport]
    related_skills: [garmin-health-check, garmin-workouts, training-profile]
---

# Garmin Weekly Plan Skill

Plans a complete training week for **any athlete, any sport mix**. Adapts entirely to the individual's routine, Garmin signals, and available time. No sport, level, or schedule is assumed.

## When to Use

- Athlete asks to plan the week, next week, or a batch of sessions.
- Start of a new training cycle.
- After a significant event: race, illness, travel, injury update.

Don't use for: health check only → `garmin-health-check`.

**Détection du mode** : lire `training-profile` — Typologies d'utilisateur.
- Demande ponctuelle (*"je veux faire un run"*, *"j'ai 45min"*) → **Mode Ponctuel** (Step 0 ci-dessous) — ne pas lancer le flow complet.
- Demande semaine/cycle → **Mode Complet** (Step 1+).

---

---

## Step 0 — Mode Ponctuel (demande isolée)

**Trigger** : l'utilisateur veut une séance maintenant sans contexte hebdomadaire.

### Flow

1. **Readiness rapide** : `get_training_readiness` + `get_training_status` — juste le score et le statut, pas le rapport complet.
2. **Dernière séance du sport demandé** : `get_activities_by_date` (7 derniers jours) — type, intensité, date.
3. **1-2 questions max** :
   - Si blessure active en mémoire : état du jour ?
   - Si pas de préférence connue : durée disponible ?
   - Ne pas poser les deux si le contexte donne déjà la réponse.
4. **Proposition immédiate** : 1 séance, structure détaillée, calibrée depuis Garmin (zones, allures).
   - Appliquer la **règle de variation** : différente de la dernière séance du même sport.
   - Adapter l'intensité au readiness : si score < 50 → proposer Z2 même si l'utilisateur demande du fractionné, expliquer pourquoi.
5. **Upload optionnel** : proposer d'uploader sur Garmin. Ne pas le faire sans accord.
6. **Transition douce** : à la fin, proposer en une ligne de planifier la semaine si pertinent — ne pas insister.

### Ce qu'on ne fait PAS en mode ponctuel
- Pas de squelette semaine.
- Pas de questions sur les disponibilités globales.
- Pas de health check complet (rapport 3 sections).
- Pas d'onboarding si le profil est incomplet — travailler avec ce qu'on a, noter les lacunes.

---

## Step 1 — Run Health Check (mandatory, automatic)

Load and run `garmin-health-check` first. Extract:
- Week recommendation: 🟢 Progresser / 🟡 Maintenir / 🟠 Récupérer / 🔴 Repos actif
- Garmin training status label
- Active injury flags
- Recovery time remaining

If any injury is flagged: ask current status before proceeding.

---

## Step 2 — Load User Context

From `training-profile` memory, retrieve:
- Sports routine (which sports, fixed vs flexible days)
- Availability + max durations per slot
- Level and equipment per sport
- Objectives and injury status
- Session preferences (warmup style, recovery type)

If any critical field is missing → run `garmin-onboarding` for that block only.

### Compléter le profil avant de planifier — jamais à l'aveugle

Avant de proposer quoi que ce soit, poser systématiquement ces questions si la réponse n'est pas en mémoire ou n'a pas été confirmée ce jour :

1. **Disponibilités de la semaine** : "Cette semaine, tes créneaux habituels sont ok ? Un rendez-vous, un déplacement, une fatigue particulière ?"
2. **État physique du jour** : "Tu te sens comment là ? Des courbatures, une gêne, quelque chose qui a changé depuis la dernière séance ?"
3. **Blessures** : si une blessure est active en mémoire → toujours demander l'état actuel. Ne jamais supposer que c'est réglé.
4. **Dernière séance** : si la dernière activité Garmin était il y a moins de 48h → demander comment ça s'est passé (douleur, effort ressenti, genou ok ?)
5. **Événements inhabituels** : "Semaine chargée au boulot ? Mauvaises nuits ? Quelque chose qui pourrait influencer la charge ?"

Règle : si l'athlète a déjà répondu à ces questions en début de conversation, ne pas les reposer. Sinon, toujours demander avant de proposer le plan.

---

## Step 3 — Define Week Objective (confirm with user)

Propose based on health-check recommendation. Don't impose — confirm:

| Objective | What it means in practice |
|---|---|
| **Progression** | Add stimulus: volume ↑ or intensity ↑ (not both) |
| **Maintien** | Same load as last week, keep quality |
| **Récupération** | Volume ↓ 30-40%, intensity capped at Zone 2 |
| **Repos actif** | Max 2 light sessions, no structured load |

Rule: if Garmin status = Overreaching → always propose Récupération, never override toward progression even if user asks. Explain why.

---

## Step 4 — Build the Skeleton

Place activities in this order:
1. **Fixed activities** (same day every week — team sport, club session, physio)
2. **Hard recovery constraints** (mandatory rest days, travel days)
3. **Preferred long-day slots** (from profile)
4. **Flexible slots** — fill last

Rules:
- Never schedule two high-intensity sessions back to back (regardless of sport).
- Always leave at least one full rest day per week unless status is Productive + user explicitly agrees.
- Any slot gap < 12h between sessions: flag it, ask user.

---

## Step 5 — Fill Sessions from Library

For each available slot, select session type based on:
1. Week objective
2. Sport for that slot
3. Last session in that sport (don't repeat same type twice in a row — see Variation rule below)
4. Time budget available

### Règle de variation — obligatoire

Avant de créer une séance, consulter `get_activities` (7 derniers jours) pour identifier la dernière séance du même type.

**Pourquoi varier** : ce n’est pas seulement une question d’ennui. Travailler toujours au même tempo, à la même allure, dans la même zone use les mêmes muscles, les mêmes ligaments, les mêmes articulations au même point — c’est une source d’usure et de blessures de surcharge. Varier la charge (durée × intensité) couvre une plage plus large d’adaptations : musculaires, ligamentaires, articulaires. C’est vrai aussi pour les séances lentes — le bas d’une zone n’est pas le haut de cette même zone : foulée différente, structures sollicitées différentes.

**Charge totale = durée × intensité** (intensité = allure cible, zone FC, ou tempo selon le type).

**Règle absolue** : d’une séance à l’autre du même type, faire varier au moins un des deux leviers (durée ou intensité). Jamais les deux en même temps sauf pour réduire la charge (récup).

**Patterns de variation** (alterner librement selon l’objectif) :
- Même durée + intensité légèrement plus haute
- Même intensité + durée plus longue
- Durée plus courte + intensité plus haute (charge équivalente, stimulus différent)
- Durée plus longue + intensité plus basse (focus volume, charge stable)
- Pour l’EF : alterner bas de zone et haut de zone — c’est déjà une variation significative (foulée, vitesse, structures impliquées)
- Semaine récup : -20% charge (les deux à la baisse)

**Calibration** : toujours depuis les données Garmin réelles (`get_race_predictions`, zones FC profil). La variation est un delta par rapport à la séance précédente, pas une valeur absolue inventée.

### Sport-specific session libraries

See references:
- Running → `references/sessions-running.md`
- Strength / renfo → `references/sessions-strength.md`
- Other sports (basketball, climbing, cycling, swimming…) → apply generic principles below

### Generic session selection logic (any sport)

| Week objective | Session type to prioritize |
|---|---|
| Progression | 1 high-intensity + volume at low-moderate |
| Maintien | Mix of moderate + 1 low-intensity |
| Récupération | Low-intensity only, short duration |
| Repos actif | Active recovery (walk, easy swim, mobility) |

For any sport not in the library:
1. Ask user: "What does a typical [sport] session look like for you?"
2. Once described, save as a reference in `training-profile` memory.
3. Build and upload to Garmin using `garmin-workouts`.

---

## Step 6 — Contextual Add-ons

### Backup sessions (dependent activities)

For any fixed activity depending on others (team sport, club, partner):
- Ask: "Tu veux une séance de remplacement si [sport] ne se fait pas ?"
- If yes: propose a session of similar duration, same or adjacent sport, calibrated to current level.
- Upload backup to Garmin on same date as primary. User picks which to do.
- Don't assume yes every week — ask each time unless user set it as a standing preference.

### Renfo (strength / conditioning)

Propose renfo if at least ONE of these is true:
- Active injury flagged → propose corrective exercises targeting that area
- Week objective = Progression or Maintien + light load week
- Garmin status = Detraining (strength stimulus needed)
- User has explicit strength goal
- Slot available and would otherwise be empty

Do NOT propose renfo if: Récupération week, Repos actif, or schedule already dense.

Fit into available slot: standalone 20-30 min session or appended to end of a short session.

---

## Step 7 — Present Plan, Validate, Upload

### Present

Format per day:
```
Lundi — [Session name] ([sport], [duration], [intensity/type], [objective])
Mardi — Repos
Mercredi — [Session name] (fixe: basket) + [Backup: ...] (optionnel)
...
```

Include:
- Weekly load summary (estimated)
- Why each session was chosen (1 line)
- Any deviations from health-check recommendation (with reason)

### Validate

Wait for user confirmation before uploading anything. Address any changes.

### Upload

For each session to upload:
1. Check if an existing `"AI - "` workout already matches → reuse/schedule it.
2. Otherwise → build via `garmin-workouts` rules, upload, verify with `get_workout_by_id`.
3. Schedule on Garmin calendar via `schedule_workout`.
4. Verify scheduling landed for each session.

---

## Progress Report (on demand only)

When user asks for a CR on a sport or the week:
1. Fetch `get_activities` for the relevant period + sport.
2. Compare to previous equivalent period.
3. Surface: volume trend, pace/intensity trend, recovery patterns, notable sessions.
4. Flag: regression, plateau, overreach signals.
5. Conclude with 1-2 actionable observations for next planning cycle.

Never produce a CR unsolicited.
