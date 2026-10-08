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

### Exercices valides pour genou douloureux (ITB / fémoro-patellaire)

Principe : la rotule souffre de la **flexion sous charge**, l'ITB de l'**instabilité frontale**. Classer tout exercice sur ces deux axes avant de le proposer.

| Sûr (à privilégier) | Pourquoi |
|---|---|
| `HIP_RAISE`/`SINGLE_LEG_HIP_RAISE` | Fessier, genou non chargé |
| `HIP_STABILITY`/`SIDE_LYING_LEG_RAISE`, `LATERAL_WALKS_WITH_BAND_AT_ANKLES` | Moyen fessier = anti-valgus, anti-ITB |
| `DEADLIFT`/`SINGLE_LEG_RDL_CIRCUIT` | Chaîne postérieure, genou quasi tendu |
| `SQUAT`/`BODY_WEIGHT_WALL_SQUAT` (Spanish squat / wall sit) | Isométrique, tibia vertical = cisaillement minimal |
| `CALF_RAISE`/`SINGLE_LEG_STANDING_CALF_RAISE`, `SINGLE_LEG_BENT_KNEE_CALF_RAISE` | Absorption d'impact en amont du genou |
| `PLANK`/`SIDE_PLANK`, `SINGLE_LEG_SIDE_PLANK` (Copenhagen) | Gainage latéral, zéro charge articulaire |
| `PLYO`/`SIDE_TO_SIDE_SHUFFLE_JUMP` | Plan frontal, flexion minimale |
| `CARDIO`/`JUMP_ROPE` en pogo jumps | Tout passe par la cheville |

| À retirer en phase douleur | Pourquoi |
|---|---|
| `PLYO`/`ALTERNATING_JUMP_LUNGE` (fentes sautées) | Charge rotulienne maximale — le premier exo à couper |
| `PLYO`/`BODY_WEIGHT_JUMP_SQUAT`, `BOX_JUMP` | Flexion profonde + impact |
| Step-up classique en montée | Préférer le **step-down** (excentrique, 3s) : même muscle, contrôle au lieu de poussée |

**Exos plyo prescrits kiné (Victor, sept. 2026)** : sauts depuis banc avec rebond immédiat = `PLYO`/`DEPTH_JUMP`. Dose G1.5 / D0.5 → noter dans la description de privilégier la jambe gauche.

**Ordre dans une séance plyo adaptée** : cheville (pogo) → plan frontal (sauts latéraux) → bipodal avec impact (depth jump) → unipodal (patineur). Contrainte croissante, et on s'arrête où ça coince.

## Exercices : catalogue Garmin

Pour chaque exercice de renfo/cardio structuré :
1. Utiliser le catalogue officiel : `curl https://connect.garmin.com/web-data/exercises/Exercises.json` → `categories[CAT].exercises`. **Le tool `list_supported_strength_exercises` n'existe PAS sur ce serveur MCP** (vérifié le 2026-10-01, absent du `tools/list`) — ne pas le chercher. Filtrer le JSON par mot-clé sur le nom d'exercice normalisé (`SIDE_PLANK`, `SPLIT_SQUAT`, `CALF_RAISE`…).
2. Ne jamais inventer un nom. Si non trouvé : prendre la catégorie la plus proche + noter dans `description`
3. 47 catégories / ~1531 exercices disponibles (SQUAT, LUNGE, PLANK, HIP_RAISE, HIP_STABILITY, DEADLIFT, CALF_RAISE, CORE, PLYO…) — voir `references/sessions-strength.md`

Correspondances notables (aucun nom français exact n'existe dans le catalogue) :
- « Spanish squat » / wall sit → `SQUAT` / `BODY_WEIGHT_WALL_SQUAT` (ou `WEIGHTED_WALL_SQUAT`)
- « step-down » → aucun exercice stepwise : `SQUAT` / `STEP_UP` avec la consigne step-down dans la `description`
- « Pallof press » → aucun Pallof : `CORE` / `CABLE_CORE_PRESS` avec la consigne dans la `description`
- « Copenhagen plank » → `PLANK` / `SINGLE_LEG_SIDE_PLANK`
- « hops unipodaux » → aucun :-description libre en `PLYO`, la catégorie PLYO n'a que 40 exos (sauts, box, depth)

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

### ⚠️ Les workouts ont leur PROPRE table de sportTypeId — pas celle des activités

Ne jamais prendre les IDs de `get_activity_types` pour un `upload_workout` : ce sont deux référentiels différents. La bonne table vient de `read_resource(uri="workout://reference/structure")` → `sportType_values` :

| sportTypeId | sportTypeKey |
|---|---|
| 1 | running |
| 2 | cycling |
| 3 | other |
| 4 | lap_swimming |
| **5** | **strength_training** |
| 6 | cardio_training |
| 7 | yoga |
| 8 | pilates |
| **9** | **hiit** |
| 11 | mobility |
| 12 | walking |
| 13 | rucking |

Pièges vérifiés par upload réel (2026-10-06) : `25` donne **indoor_cycling** (type générique côté app), `13` donne **rucking**. L'API accepte n'importe quel ID sans erreur — elle ignore le `sportTypeKey` et ne garde que l'entier. **Toujours relire avec `get_workout_by_id` et vérifier le champ `sport` avant de scheduler.**

Conventions Victor : renfo/muscu → `strength_training` (5), pliométrie → `hiit` (9).

### Activités (pas workouts)

Pour un `create_manual_activity` ou un `set_activity_type`, là oui : vérifier via `get_activity_types`.

## Ne jamais appeler le serveur MCP à la main

Tous les outils Garmin passent par `tool_call` / `tool_describe`. **Interdit** de rejouer du JSON-RPC en Python `urllib` vers `http://192.168.1.11:9711/mcp` pour « aller plus vite » ou « voir la payload brute ».

Pourquoi : ça déclenche une demande de confirmation Hermes qui fait perdre plusieurs minutes à Victor, et ça sort du chemin tested (validation des enums, garde-fous du skill). Le catalogue d'exercices se récupère par `curl` sur `connect.garmin.com` (lecture seule, publique) — ça c'est correct.

## Naming Convention

Always prefix `workoutName` with `"AI - "` (e.g. `"AI - Renfo course"`, `"AI - Fractionné court"`). Applies to every sport and test workouts. When the athlete refers to "my sessions" or "the sessions you manage" without detail → workouts starting with `"AI - "`.

## Pre-Planning Checks

Before building/scheduling, fetch live signals:
- `get_training_readiness` + recent sleep for the target day.
- `get_training_status` — aim to keep Victor in **"Productive"** status.
- `get_vo2max_trend` + `get_activities` (last 2–4 weeks) — flat/declining = more stimulus; high load/no rest = back off.
- A rest day beats an overreaching session. A lighter week is a valid outcome.

## Nettoyage de la bibliothèque AI

### ⚠️ `get_workouts` est plafonné à 100, sans pagination

Le tool n'accepte **aucun paramètre** (ni `start`, ni `limit`, ni `page`) et renvoie les 100 workouts les plus récents, triés par date de création décroissante. Vérifié en comparant deux appels autour de 4 uploads : 4 anciens workouts avaient disparu de la liste.

Conséquence sur ce compte : le plan Garmin Coach occupe ~91 slots ("Course tranquille" ×55, "Répétitions course très rapide" ×20…), donc toute séance créée avant mars 2025 est invisible. **Ne jamais affirmer qu'une séance n'existe pas à partir de `get_workouts` seul** — dire que la fenêtre est saturée, et demander l'ID (`get_workout_by_id` n'a aucune limite) ou l'URL Garmin (`connect.garmin.com/app/workout/<ID>`).

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

**Mythe corrigé (2026-10-06)** : on a cru un temps que `get_scheduled_workouts` ne listait que le `running`. Faux — c'était le symptôme d'un mauvais `sportTypeId` à l'upload (25 → indoor_cycling). Avec le bon ID (5 = strength_training, 9 = hiit), le listing remonte bien toutes les séances, tous sports confondus. Si une séance schedulée n'apparaît pas : vérifier son `sport` via `get_workout_by_id` avant de soupçonner le tool.

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

## Structure des séances non-running (muscu, HIIT) — OBLIGATOIRE

S'applique à tout ce qui n'est pas de la course : `strength_training`, `hiit`, mobilité, pilates.

### 1. Un repos après CHAQUE série, y compris la dernière

`skipLastRestStep: false` sur **tous** les `RepeatGroupDTO`. Victor veut que le dernier repos de la boucle se joue : c'est le temps de transition vers l'exo suivant, et la montre l'affiche proprement.

Ne jamais mettre `skipLastRestStep: true` sur une séance de renfo ou de HIIT.

### 2. Un step de repos à la fin de l'échauffement

Après le dernier step `warmup` et avant le premier bloc de travail, insérer :

```json
{
  "type": "ExecutableStepDTO",
  "stepOrder": N,
  "stepType": {"stepTypeId": 5, "stepTypeKey": "rest"},
  "endCondition": {"conditionTypeId": 1, "conditionTypeKey": "lap.button"},
  "description": "Fin de l echauffement - repos, se mettre en place pour le premier exo"
}
```

Raison : meilleure UX sur la montre — ça marque la fin de l'échauffement et laisse le temps de se mettre en place sans qu'un chrono tourne.

### 3. Un exercice = un RepeatGroupDTO

Un bloc par exercice, contenant l'exo + son repos. Jamais plusieurs exercices différents dans le même `RepeatGroupDTO` (ça produit un circuit, pas des séries).

Seule exception : un exo unipodal découpé en deux steps gauche/droite — les deux côtés forment une série, suivie d'un repos.

### 4. Repos : TOUJOURS `lap.button`, sans exception

Tous les steps `rest` des séances non-running utilisent `lap.button` — renfo, HIIT, pliométrie, mobilité, tous les exos, toutes les séries.

```json
{"endCondition": {"conditionTypeId": 1, "conditionTypeKey": "lap.button"}}
```

Ne jamais utiliser de repos à durée fixe (`conditionTypeKey: time`) sur un step `rest`. Les repos chronométrés ont du sens en cardio pur (fractionné où la densité est le stimulus) — Victor n'en fait pas. Partout ailleurs la récupération se pilote au ressenti : il appuie sur LAP quand il est prêt.

Attention au mélange : utiliser `time` sur les premiers exos et `lap.button` sur les suivants dans la même séance est incohérent et a été explicitement rejeté.

Le temps de travail (`interval`) garde bien sûr sa durée ou ses reps — c'est le **repos** qui est au lap button.

## Préférences de séance — Victor (règles fermes)

Acquises, à appliquer par défaut sans redemander à chaque planification.

- **Ordre dans une séance mixte** : échauffement → footing court → renfo. **Jamais footing après le renfo** : quadriceps préfatigué = contrôle rotulien dégradé = rotule exposée. C'est la situation où le genou lâche.
- **Cooldown** : footing 5 min Z1, inclus dans la durée annoncée (jamais en plus).
- **Étirements** : statiques en fin de séance uniquement quand les muscles sont chauds. Jamais à froid.
- **Basket annulé (mercredi midi)** : proposer automatiquement un fractionné de remplacement, sans demander.
- **Durée annoncée par Victor** = échauffement et cooldown compris. Ne jamais ajouter de temps par-dessus.

## Equipment — RÈGLE BLOQUANTE

L'équipement réel de Victor est dans `training-profile` memory. **Le lire AVANT de construire, pas après.** Un exercice qui exige du matériel absent = séance jetée, pas séance imparfaite.

### Ce que Victor a / n'a pas (confirmé 2026-10-06)

- **AUCUN poids libre**, nulle part : pas d'haltères, pas de barre, pas de kettlebell. Ni chez lui, ni au travail. Ne jamais proposer un exo qui n'a de sens qu'avec charge (un RDL à vide ne sert à rien — il le fait chez le kiné avec du poids).
- **Élastiques** : chez lui uniquement.
- **Hangboard, tapis** : chez lui uniquement.
- **Au travail (L/Ma/Je midi)** : RIEN. Pas de matériel, pas de sol où s'allonger, pas de vestiaire. Seuls appuis disponibles : murs, poteaux, bancs, marches, trottoirs.

### Deux contextes, deux bibliothèques

Toute séance de renfo doit exister dans la variante adaptée au lieu où elle sera faite :

| Contexte | Quand | Contraintes |
|---|---|---|
| **Extérieur / taf** | L, Ma, Je midi | Poids de corps seul. Debout, accroupi, appui mur/poteau/banc. **JAMAIS allongé, jamais assis au sol.** Zéro matériel. |
| **Maison** | Sa, Di, jours off | Poids de corps + élastiques + tapis (donc sol OK). Toujours pas de poids. |

Pour un même objectif (ex. stabilité hanche), prévoir **les deux variantes** quand c'est possible — Victor choisit selon où il est.

### Nommage obligatoire

Le `workoutName` doit porter le contexte, pour que la planification soit lisible d'un coup d'œil :

- `AI - Renfo <objectif> (extérieur, sans matériel)`
- `AI - Renfo <objectif> (maison, élastiques)`

Et dans la `description` : lister explicitement le matériel requis en première ligne (`Materiel : aucun` / `Materiel : elastique + tapis`). Ne jamais laisser Victor découvrir à l'échauffement qu'il lui manque quelque chose.

### Objets du quotidien

Chaise, sac à dos, mur, banc : à proposer et faire valider explicitement avant de finaliser un step qui s'appuie dessus.

### Exos renfo valides SANS matériel et DEBOUT (extérieur)

Testés contre le catalogue Garmin :

| Exo | Garmin | Cible |
|---|---|---|
| Wall sit / Spanish squat au mur | `SQUAT`/`BODY_WEIGHT_WALL_SQUAT` | Quadri isométrique |
| Squat poids de corps | `SQUAT`/`AIR_SQUAT` | Quadri/fessier |
| Step-down sur trottoir/marche | `SQUAT`/`STEP_UP` (consigne step-down en description) | Quadri excentrique |
| Fente arrière | `LUNGE`/`REVERSE_LUNGE` | Unilatéral |
| Mollet unipodal sur trottoir | `CALF_RAISE`/`SINGLE_LEG_STANDING_CALF_RAISE` | Mollet/Achille |
| Abduction hanche debout (appui mur) | `HIP_STABILITY`/`STANDING_HIP_ABDUCTION` | Moyen fessier, anti-ITB |
| Équilibre unipodal | `HIP_STABILITY` + description | Proprioception |
| Montantes de genou, talons-fesses | `WARM_UP`/`WALKING_HIGH_KNEES` | Activation |

À éviter en extérieur : tout `PLANK`, `HIP_RAISE` (pont fessier), `DEAD_BUG`, `SIDE_LYING_LEG_RAISE` — tous au sol.

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
