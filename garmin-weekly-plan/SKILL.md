---
name: garmin-weekly-plan
description: Plan a full training week. Routed from garmin-plan only.
version: 1.2.0
author: hermes-garmin-skills contributors
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [garmin, planning, weekly, training, multi-sport]
    related_skills: [garmin-plan, garmin-health-check, garmin-workouts, training-profile]
---

# Garmin Weekly Plan

Planifie une semaine complète d'entraînement. S'adapte à n'importe quel sport, n'importe quelle routine. Toujours routé depuis `garmin-plan` — ne pas charger si la demande est une séance isolée.

## When to Use

- Routé depuis `garmin-plan` : demande semaine / cycle / plusieurs jours.
- Début d'un nouveau cycle.
- Après un événement significatif : course, maladie, voyage, blessure.

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

Depuis le profil athlète (`training-profile`, schéma dans `training-profile/references/profile-schema.md`) :
- `sports` — quels sports, fixe vs flexible, jours habituels, dépendance à d'autres personnes
- `availability` — créneaux et durées plafond (échauffement et cooldown inclus)
- `locations` — lieu de chaque créneau, matériel disponible, sol praticable, appuis
- `sports[].level` — niveau par sport
- `objectives` et `injuries`
- `session_preferences` — échauffement, cooldown, repos, nommage
- `device.capabilities` — ce que la montre sait afficher ; conditionne ce qui est publiable (voir `garmin-workouts` → capacités de l'appareil)

Si un champ critique manque ou est périmé → lancer `garmin-onboarding` sur ce bloc uniquement.

### Compléter le profil avant de planifier — jamais à l'aveugle

Avant de proposer quoi que ce soit, poser systématiquement ces questions si la réponse n'est pas en mémoire ou n'a pas été confirmée ce jour :

1. **Disponibilités de la semaine** : "Cette semaine, tes créneaux habituels sont ok ? Un rendez-vous, un déplacement, une fatigue particulière ?"
2. **LIEU de chaque séance** (bloquant — voir ci-dessous)
3. **État physique du jour** : "Tu te sens comment là ? Des courbatures, une gêne, quelque chose qui a changé depuis la dernière séance ?"
4. **Blessures** : si une blessure est active en mémoire → toujours demander l'état actuel. Ne jamais supposer que c'est réglé.
5. **Dernière séance** : si la dernière activité Garmin était il y a moins de 48h → demander comment ça s'est passé (douleur, effort ressenti, zone sensible ok ?)
6. **Événements inhabituels** : "Semaine chargée au boulot ? Mauvaises nuits ? Quelque chose qui pourrait influencer la charge ?"

Règle : si l'athlète a déjà répondu à ces questions en début de conversation, ne pas les reposer. Sinon, toujours demander avant de proposer le plan.

### ⚠️ LIEU de la séance = question bloquante

Deux séances du même objectif à deux endroits différents sont deux séances différentes : matériel disponible, possibilité de s'allonger au sol, appuis, espace. Planifier sans savoir où = séance potentiellement infaisable.

Pour chaque créneau non-running :

1. Lire le `location_id` par défaut du créneau dans `availability`, et le détail du lieu dans `locations` (`equipment`, `floor_ok`, `supports`).
2. **Confirmer, jamais déduire.** Un jour de télétravail, un déplacement, une salle fermée change tout ce qui est possible : « tu es à [lieu habituel] ce jour-là ? »
3. Filtrer les exercices sur les contraintes du lieu retenu : pas d'exercice au sol si `floor_ok` est faux, pas d'exercice qui n'a de sens que chargé si `equipment` ne contient aucune charge.

Puis sélectionner la variante correspondant au lieu dans la bibliothèque (voir `garmin-workouts` → contraintes de lieu).

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
- Running → `garmin-workouts/references/sessions-running.md`
- Strength / renfo → `garmin-workouts/references/sessions-strength.md`
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
Mercredi — [Session name] (sport fixe) + [Backup: ...] (optionnel)
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
