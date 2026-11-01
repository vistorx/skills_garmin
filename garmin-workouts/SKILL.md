---
name: garmin-workouts
description: Create and schedule Garmin running/strength workouts via MCP.
version: 1.1.1
author: hermes-garmin-skills contributors
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [garmin, workout, running, strength, planning, mcp]
    related_skills: [training-profile]
---

# Garmin Workout Creation Skill

Construit et planifie des séances de course et de renforcement via le MCP Garmin Connect.
Toujours lire le profil athlète (`training-profile`) **avant** de construire : `injuries`,
`locations`, `availability`, `sports`, `session_preferences`. Aucune donnée personnelle
n'est codée en dur dans ce skill — tout vient du profil.

## Quand l'utiliser

- Créer, modifier ou planifier une séance de course ou de renfo dans Garmin Connect.
- Passer en revue la bibliothèque de séances gérées par l'agent (préfixe `session_preferences.naming_prefix`, défaut `"AI - "`).
- Construire une semaine d'entraînement à pousser sur le calendrier Garmin.

Ne pas utiliser pour : évaluation de séance, suivi de blessure, disponibilité — c'est `training-profile`.

## Bibliothèques de séances

Voir les références pour le détail des types de séances et exercices :
- `references/sessions-running.md` — EF, fractionné court/long, seuil, côtes
- `references/sessions-strength.md` — exercices Garmin par groupe musculaire + templates
- `references/sessions-multi-sport.md` — cyclisme, natation, sports collectifs, escalade, générique
- `references/warmup-protocols.md` — protocoles échauffement par type de séance
- `references/json-examples.md` — structures JSON Garmin annotées

## Vocabulaire

- **Workout/entraînement** = template dans la bibliothèque Garmin (`get_workouts`, `upload_workout`, `schedule_workout`).
- **Activity/séance** = activité enregistrée et terminée (`get_activities`, `get_activity`). Ce skill ne gère PAS les activités passées.
- « Séance » ambigu : contexte de planification → template de workout ; « ce que j'ai fait / ressenti » → activité terminée.

Tout ce que Garmin sait déjà — on le lit, on ne le recalcule pas :
- **Zones FC** : lire depuis `get_heart_rates_summary` ou cibler par numéro (`zoneNumber: 2`) dans les steps — Garmin les traduit en FC réelle selon le profil
- **Seuil lactique** : `get_user_profile` → `lactateThresholdSpeed` (m/s) + `lactateThresholdHeartRate`
- **Allures cibles** : `get_race_predictions` → pace 5K, 10K, semi, marathon réelles de l'athlète
- **FTP cyclisme** : `get_cycling_ftp`
- **Statut d'entraînement** : `get_training_status`
- **Disponibilité du jour** : `get_training_readiness`

Jamais estimer ou inventer une zone. Si la donnée n'est pas disponible dans Garmin → demander à l'athlète.

## Filtrer les exercices selon la blessure déclarée

Méthode générique, applicable à n'importe quelle blessure listée dans `injuries` :

1. Lire `injuries[].aggravating` et `injuries[].restrictions` → en déduire les **axes de
   contrainte** que la structure anatomique concernée ne tolère pas.
2. Classer chaque exercice candidat sur ces axes.
3. Écarter ceux qui chargent un axe interdit ; privilégier ceux qui travaillent le même
   muscle sans solliciter l'axe.
4. Reporter `injuries[].pain_threshold` dans la `description` de tout workout publié tant
   que la blessure est active.

### Exemple de méthode : genou douloureux (ITB / fémoro-patellaire)

À lire comme une démonstration du classement par axes, pas comme une liste à appliquer
telle quelle. Ici deux axes : la rotule souffre de la **flexion sous charge**, l'ITB de
l'**instabilité frontale**.

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

Si un praticien a prescrit un exercice précis, il est consigné dans le profil
(`injuries[].treatment` / `restrictions`) : le traduire en nom de catalogue Garmin et
reporter la dose exacte du profil dans la `description` du step. Exemple de traduction :
sauts depuis banc avec rebond immédiat = `PLYO`/`DEPTH_JUMP`.

**Ordre dans une séance plyo adaptée** : cheville (pogo) → plan frontal (sauts latéraux) →
bipodal avec impact (depth jump) → unipodal (patineur). Contrainte croissante, et on
s'arrête où ça coince.

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
- « hops unipodaux » → aucun : description libre en `PLYO`, la catégorie PLYO n'a que 40 exos (sauts, box, depth)

## Séance à partir d'une vidéo (Instagram reel…)

- `web_extract` échoue (403) sur Instagram. Utiliser `browser_exec` : la page publique donne la légende via `meta[property=og:description]` (souvent la liste d'exos), et la `<video>` est lisible : seek `currentTime` + `canvas.drawImage` pour faire une planche de ~12-24 frames, puis l'inspecter visuellement.
- Catalogue exact des exercices : `https://connect.garmin.com/web-data/exercises/Exercises.json` (curl) → `categories[CAT].exercises`.
- Exos au temps (plyo 30s) : `conditionTypeId: 2` time au lieu de reps. Adapter volume/amplitude aux blessures du profil et le noter en description.
- **Toujours mettre l'URL de la/des vidéo(s) source en début de `description`** (« Vidéo : <url> ») — l'athlète s'en sert pour retrouver les mouvements sur la montre. URL sans le paramètre `?stkn=`.
- **Reproduire la vidéo à l'identique** : mêmes exos, même ordre (vidéo 1 puis vidéo 2 si plusieurs), pas d'échauffement ni d'exo ajouté. La séance doit correspondre à ce que l'athlète a vu, sinon il ne la reconnaît pas. Adaptations blessure = conseils dans le message, pas dans la séance.
- Frames : ~0.35s d'écart (30+ frames), crop sur la zone du corps, horodatées — 12 frames ratent des exos. Les reels commencent souvent par un intro (~3s) à ignorer.
- La lecture de frames reste peu fiable (positions pieds/talons, intro prise pour un exo). **Avant d'uploader, lister les exos identifiés à l'athlète et lui demander de valider** — il connaît la vidéo. Ses corrections priment.
- Descriptions de step : « EXO n/N (vidéo X) — reps PAR JAMBE/CÔTÉ. Position de départ → mouvement → retour » pour que ce soit lisible sur la montre.

## Types de sports Garmin

### ⚠️ RÈGLE BLOQUANTE — vérifier les capacités de l'appareil AVANT de construire

Lire `device.capabilities` dans le profil. L'API Garmin accepte des structures que la
montre ne sait pas lire, **sans lever d'erreur** : un upload réussi ne prouve rien, seul
l'appareil tranche. Une séance illisible sur le poignet n'est pas une séance imparfaite,
c'est une séance perdue — et l'athlète ne le découvre qu'au moment de s'entraîner.

| Capacité | Statut `unsupported` → chemin de repli |
|---|---|
| `structured_workouts` | Ne rien publier. Livrer la séance en texte dans la conversation, et le dire clairement. |
| `strength_display` | Pas de workout renfo détaillé : séance texte, ou workout minimal sans exercices nommés (durée + description). |
| `hiit_display` | Typer la séance en `strength_training` (5) plutôt qu'en `hiit` (9). |
| `multisport_workouts` | Deux workouts séparés schedulés le même jour (voir ci-dessous). |
| `pace_targets` | Cibles en zone FC uniquement, et consigne d'allure portée dans la `description`. |
| `hr_zone_targets` | Cibles d'allure uniquement, zone FC en consigne texte. |

Statut `unknown` sur une capacité dont dépend la séance : ne pas parier. Le signaler et
proposer le test — un workout jetable préfixé `ZZTEST - `, l'athlète vérifie sur la montre,
le statut est figé dans le profil (voir « Tester plutôt que supposer »).

### ⚠️ Le type de sport doit correspondre au CONTENU réel de la séance

Ne jamais empaqueter des blocs de renfo dans un workout typé `running` (ni l'inverse). Une séance typée course qui contient des `RepeatGroupDTO` d'exercices de musculation n'a aucun sens : mauvais écran sur la montre, mauvaises métriques, mauvais historique.

### ⚠️ Beaucoup de montres ne lisent pas le multisport — par défaut, des workouts séparés

Vérifié par upload réel puis contrôle sur l'appareil : un workout `multi_sport` s'uploade et se schedule sans erreur côté API, mais **la montre peut ne pas l'afficher / ne pas le charger**. L'upload réussi ne prouve rien — seul l'appareil tranche.

**Règle par défaut :** un sport = un workout. Pour un enchaînement course + renfo, publier **deux workouts du bon type**, schedulés sur la même date ; l'athlète lance deux enregistrements. Ne revenir au multisport que si `device.capabilities.multisport_workouts` vaut `verified` — jamais sur `assumed`, jamais sur la base d'un upload accepté.

### Convention de nommage pour un enchaînement

- Partie course : `<prefix><nom> (1-2 avant renfo)` — sportTypeId 1
- Partie renfo : `<prefix>Renfo <objectif> (<lieu>)` — sportTypeId 5
- La `description` de chaque partie **nomme explicitement l'autre** (« PARTIE 1 SUR 2 - enchaîner avec : ... ») pour que l'ordre soit lisible sur la montre
- **L'ordre vient de `session_preferences.order_constraints`**. S'il impose course avant renfo, le respecter ; la justification physiologique est en section « Préférences de séance ».
- Le cooldown de la première partie dit d'arrêter l'enregistrement et de lancer la suivante — **pas d'étirements là** : ils vont en cooldown de la dernière partie, en fin d'enchaînement
- Le premier step de la partie suivante est un `rest` lap.button (« corps déjà chaud »)

### Remplacer une séance déjà schedulée — ordre des opérations

1. `upload_workout(s)` la nouvelle version, `get_workout_by_id` pour vérifier
2. `schedule_workout(s)` la nouvelle sur la date
3. `get_scheduled_workouts` sur la date → récupérer le `scheduled_workout_id` de l'ANCIENNE
4. `unschedule_workout` l'ancienne entrée de calendrier
5. `delete_workout(s)` l'ancien template
6. `get_scheduled_workouts` une dernière fois pour confirmer qu'il ne reste pas de doublon

Jamais supprimer avant d'avoir vérifié que la nouvelle est en place.

### Workout multisport — recette vérifiée (upload réel 2026-10-13)

Documenté pour le cas où l'appareil de l'athlète le supporte. `sportTypeId: 10`, `sportTypeKey: "multi_sport"` — **absent de `sportType_values`** de `read_resource("workout://reference/structure")`, mais accepté par l'API et relu correctement (`"sport": "multi_sport"`, `segment_count: 2`, chaque segment gardant son propre sport).

Deux contraintes, les deux donnent un 400 si violées :
1. **`stepOrder` doit être unique GLOBALEMENT**, à travers tous les segments — pas par segment. Segment 1 : steps 1–8 ; segment 2 : steps 9–20. Repartir à 1 dans le 2e segment → 400 « steps need to have unique step orders ».
2. **`sportTypeId` racine ≠ 3 (`other`)** : avec `other` + 2 segments, l'API renvoie 400 « only valid types of workouts have multiple segments ». Seul `multi_sport` autorise plusieurs segments de sports différents.

Chaque segment porte son `sportType` propre (`{1, running}` puis `{5, strength_training}`), avec ses règles habituelles : cibles FC/allure côté course, `category`/`exerciseName`/reps côté renfo.

### En cas de doute sur le typage : DEMANDER

Si le bon type n'est pas évident, poser la question à l'athlète avant d'uploader. Mieux vaut une question qu'une séance mal typée.

### Tester plutôt que supposer

L'API Garmin accepte des champs non documentés et en rejette d'autres sans logique apparente. Pour trancher une question de structure : créer un workout jetable préfixé **`ZZTEST - `**, l'uploader, le relire avec `get_workout_by_id`, puis le supprimer. Ne jamais livrer à l'athlète une structure non vérifiée.

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
| **10** | **multi_sport** (non documenté ; accepté par l'API mais **potentiellement illisible par la montre** — voir ci-dessus) |

Pièges vérifiés par upload réel (2026-10-06) : `25` donne **indoor_cycling** (type générique côté app), `13` donne **rucking**. L'API accepte n'importe quel ID sans erreur — elle ignore le `sportTypeKey` et ne garde que l'entier. **Toujours relire avec `get_workout_by_id` et vérifier le champ `sport` avant de scheduler.**

Conventions par défaut : renfo/muscu → `strength_training` (5), pliométrie → `hiit` (9).

### Activités (pas workouts)

Pour un `create_manual_activity` ou un `set_activity_type`, là oui : vérifier via `get_activity_types`.

## Ne jamais appeler le serveur MCP à la main

Tous les outils Garmin passent par `tool_call` / `tool_describe`. **Interdit** de rejouer du JSON-RPC en Python `urllib` vers l'endpoint `/mcp` pour « aller plus vite » ou « voir la payload brute ».

Pourquoi : ça déclenche une demande de confirmation Hermes qui fait perdre plusieurs minutes à l'athlète, et ça sort du chemin testé (validation des enums, garde-fous du skill). Le catalogue d'exercices se récupère par `curl` sur `connect.garmin.com` (lecture seule, publique) — ça c'est correct.

## Convention de nommage

Toujours préfixer `workoutName` avec `session_preferences.naming_prefix` (défaut `"AI - "`), p. ex. `"AI - Renfo course"`, `"AI - Fractionné court"`. S'applique à tous les sports et aux workouts de test. Quand l'athlète parle de « mes séances » ou « les séances que tu gères » sans plus de détail → les workouts portant ce préfixe.

Le nom doit aussi porter le **lieu** dès que la séance dépend du matériel (voir « Lieu et matériel »).

## Vérifications avant planification

Avant de construire/planifier, récupérer les signaux live :
- `get_training_readiness` + sommeil récent pour le jour visé.
- `get_training_status` — viser le maintien en statut **« Productive »**.
- `get_vo2max_trend` + `get_activities` (2–4 dernières semaines) — plat/en baisse = plus de stimulus ; charge haute sans repos = alléger.
- Un jour de repos vaut mieux qu'une séance en surcharge. Une semaine allégée est un résultat valide.

## Nettoyage de la bibliothèque gérée par l'agent

### ⚠️ `get_workouts` est plafonné à 100, sans pagination

Le tool n'accepte **aucun paramètre** (ni `start`, ni `limit`, ni `page`) et renvoie les 100 workouts les plus récents, triés par date de création décroissante. Vérifié en comparant deux appels autour de 4 uploads : 4 anciens workouts avaient disparu de la liste.

Conséquence : sur un compte où un plan Garmin Coach occupe des dizaines de slots (le même nom répété ×20 à ×55), les séances anciennes sont invisibles. **Ne jamais affirmer qu'une séance n'existe pas à partir de `get_workouts` seul** — dire que la fenêtre est saturée, et demander l'ID (`get_workout_by_id` n'a aucune limite) ou l'URL Garmin (`connect.garmin.com/app/workout/<ID>`).

### Règle de gestion

La bibliothèque préfixée doit rester propre à tout moment. Avant chaque planification :
1. Lister toutes les séances au préfixe via `get_workouts`
2. Identifier les obsolètes : séances remplacées par une version améliorée, placeholders vides (sport « other »), séances dont le niveau ou le profil ne correspondent plus
3. Lister à l'athlète ce qui sera supprimé et pourquoi, puis supprimer après confirmation

### Ce qui déclenche une suppression
- Une nouvelle version de la séance a été uploadée (l'ancienne est remplacée)
- La séance est un placeholder vide (sport « other », pas de steps)
- Le niveau ou le profil ne correspond plus (ex. « niveau débutant » si `sports[].level` est confirmé)
- La séance n'a pas été utilisée depuis >8 semaines ET n'est pas dans un cycle en cours

### Ne jamais supprimer sans lister
Toujours afficher la liste de ce qui sera supprimé avec la raison avant d'agir. Jamais de suppression silencieuse.

### Séances hors préfixe
Les workouts sans le préfixe de l'agent ne sont pas gérés par l'agent. Ne pas les supprimer sans demande explicite de l'athlète.
Ceux générés par un plan Garmin Coach (noms « Course tranquille », « Répétitions vitesse »…) ne sont pas supprimables via l'API (400 « workout with ATP plan id ») : ne pas réessayer, renvoyer l'athlète vers Garmin Connect (supprimer le plan Coach).

### Vérifier avant de scheduler

Toujours appeler `get_scheduled_workouts` sur la semaine cible avant d'ajouter des séances. Détecter et supprimer les doublons issus de tentatives précédentes avec `unschedule_workouts`.

**Mythe corrigé (2026-10-06)** : on a cru un temps que `get_scheduled_workouts` ne listait que le `running`. Faux — c'était le symptôme d'un mauvais `sportTypeId` à l'upload (25 → indoor_cycling). Avec le bon ID (5 = strength_training, 9 = hiit), le listing remonte bien toutes les séances, tous sports confondus. Si une séance schedulée n'apparaît pas : vérifier son `sport` via `get_workout_by_id` avant de soupçonner le tool.

## Modifier vs supprimer-et-recréer

Préférer la modification à la recréation. Limitation MCP connue : re-uploader avec `workoutId` dans la payload crée un NOUVEAU workout (pas de mise à jour en place).

Workflow :
1. Réutiliser/scheduler un workout existant s'il correspond.
2. Si un changement est nécessaire : uploader la version corrigée → vérifier avec `get_workout_by_id` → seulement ensuite supprimer l'ancienne. Jamais supprimer d'abord.
3. Vérifier la planification avant de remplacer : `get_scheduled_workouts` → re-scheduler sur les mêmes dates après l'échange. Vérifier que c'est bien arrivé.
4. Jamais de suppression en masse sans lister ce qui part et obtenir confirmation.

## S'appuyer sur l'historique

Avant de créer une nouvelle séance, chercher dans la bibliothèque préfixée et dans l'historique d'activités récent une séance similaire — la faire évoluer/progresser plutôt que repartir de zéro. Si aucune référence n'existe, discuter la structure avec l'athlète avant d'uploader.

## Renforcement : toujours en proposer

Toute semaine planifiée doit comporter du renfo — ce n'est pas optionnel. Faire évoluer les séances de renfo existantes. Voir `training-profile` pour le contexte blessure / travail correctif.

## Séances de course — règles de base

1. **Échauffement** : protocole par défaut = `session_preferences.warmup_standard` (durée + contenu), avec les surcharges de `warmup_per_type` si elles existent. À défaut de valeur dans le profil, utiliser les protocoles génériques de `references/warmup-protocols.md`. Si une blessure active impose un travail préparatoire (plyo, activation), il est listé dans `injuries[].treatment` et s'ajoute à l'échauffement.
2. Ne jamais utiliser la Zone 1 pour un effort de course — Zone 2 minimum.
3. Utiliser `RepeatGroupDTO` pour tout motif répété — jamais dupliquer les steps à la main.
4. Intervalles courts (effort ≤1 min) : **cibles d'allure uniquement** (m/s) — la FC a 20–40s de latence, la zone est inatteignable. Voir `references/json-examples.md`.
5. Blocs longs (effort ≥2–3 min) : les cibles de zone FC conviennent.
6. Calibrer l'allure depuis `get_race_predictions` / les records personnels — jamais inventer une allure. Voir `references/sessions-running.md` pour la calibration %VMA.
7. **Cooldown** : toujours proposer un retour au calme (5 min footing/marche facile) — l'intégrer au workout si `session_preferences.cooldown_in_workout` est vrai.

### Formats de fractionné (méthode de référence Decathlon)

| Format | Description | Usage par défaut |
|--------|-------------|------------------|
| 30/30 | 30s dur / 30s récup, 10–15 reps | Meilleur défaut, le plus accessible |
| Fractionné long | Effort soutenu 400m–3km | Développement VO2max |
| Fartlek | Jeu d'allure libre, blocs à la minute | Variété, zone FC adaptée |
| Seuil | Soutenu proche du seuil | Seuil lactique |
| Pyramidal | Durées croissantes puis décroissantes | Variété |
| Côtes | Répétitions en montée | Travail de vitesse peu traumatisant |

**Adaptation obligatoire** : si `injuries` contient une blessure sensible à l'impact ou à la charge, passer par défaut en effort sous-maximal et préférer des efforts plus courts ou des côtes aux longs efforts durs soutenus. Toujours expliciter quand et pourquoi une déviation est faite.

## Séances de renfo — règles de base

1. `RepeatGroupDTO` pour chaque exercice : une itération = une série de travail + un step de repos, N fois.
2. Condition de fin de la série de travail : en reps (`conditionTypeId: 10, conditionTypeKey: "reps"`) — pas de chrono.
3. Steps de repos : selon `session_preferences.rest_mode` (défaut `lap_button` → `conditionTypeId: 1, conditionTypeKey: "lap.button"`).
4. Format du commentaire de step : `"<reps> fois <nom court de l'exercice>"` — p. ex. `"12 fois Pont fessier"`.
5. `skipLastRestStep` : toujours renseigné explicitement (true/false), jamais implicite.
6. Catégorisation des exercices : meilleure correspondance possible dans les enums Garmin pour `category` + `exerciseName` — le signaler à l'athlète pour contrôle visuel.

## Structure des séances non-running (muscu, HIIT) — OBLIGATOIRE

S'applique à tout ce qui n'est pas de la course : `strength_training`, `hiit`, mobilité, pilates.

### 1. Un repos après CHAQUE série, y compris la dernière

`skipLastRestStep: false` sur **tous** les `RepeatGroupDTO`. Le dernier repos de la boucle doit se jouer : c'est le temps de transition vers l'exo suivant, et la montre l'affiche proprement.

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

### 4. Repos : cohérents dans toute la séance

Tous les steps `rest` d'une séance non-running utilisent le **même** mode, celui de `session_preferences.rest_mode` — renfo, HIIT, pliométrie, mobilité, tous les exos, toutes les séries.

Avec le défaut `lap_button` :

```json
{"endCondition": {"conditionTypeId": 1, "conditionTypeKey": "lap.button"}}
```

Les repos chronométrés (`conditionTypeKey: time`) ont du sens quand la densité est elle-même le stimulus (cardio pur, fractionné) ; ailleurs la récupération se pilote au ressenti, l'athlète appuie sur LAP quand il est prêt. Ne les utiliser que si `rest_mode` vaut `timer`.

Attention au mélange : utiliser `time` sur les premiers exos et `lap.button` sur les suivants dans la même séance est incohérent et illisible sur la montre.

Le temps de travail (`interval`) garde bien sûr sa durée ou ses reps — c'est le **repos** qui dépend du mode.

## Préférences de séance — défauts lus depuis le profil

Appliquer sans redemander à chaque planification. Source : `session_preferences`, complétée par `injuries.restrictions`.

- **Ordre dans une séance mixte** : suivre `session_preferences.order_constraints`. Cas fréquent, course avant renfo : un quadriceps préfatigué dégrade le contrôle rotulien et expose la rotule — donc jamais de footing après le renfo quand une blessure de genou est active. Si aucune blessure ne le justifie et que le profil ne contraint rien, l'ordre est libre : le choisir selon l'objectif prioritaire de la séance (ce qui compte le plus se fait frais).
- **Cooldown** : si `cooldown_in_workout` est vrai, l'intégrer au workout et le compter dans la durée annoncée (jamais en plus).
- **Étirements** : statiques en fin de séance uniquement, muscles chauds. Jamais à froid.
- **Sport dépendant annulé** (`sports[].dependency` true, séance club/équipe/partenaire qui tombe) : appliquer `session_preferences.backup_session`. Si la politique dit « remplacement automatique », proposer directement la séance de substitution sans demander.
- **Durée** : `availability[].max_duration_min` est un plafond échauffement et cooldown compris. Ne jamais ajouter de temps par-dessus.

## Lieu et matériel — RÈGLE BLOQUANTE

Le lieu détermine le matériel ET la posture possible. Lire `locations` dans le profil **AVANT** de construire, pas après. Un exercice qui exige du matériel ou une posture absents du lieu = séance jetée, pas séance imparfaite.

Pour chaque séance non-running, résoudre le lieu (via `availability[].location_id` du créneau visé, ou en demandant), puis filtrer :

- `equipment` ne contient pas de charge → aucun exercice qui n'a de sens que chargé (un RDL à vide ne sert à rien).
- `floor_ok` faux → aucun exercice au sol : pas de `PLANK`, `HIP_RAISE`, `DEAD_BUG`, `SIDE_LYING_LEG_RAISE`.
- `supports` liste les appuis réellement utilisables (mur, poteau, banc, marche, barre fixe) — ne construire sur un appui que s'il y figure.
- `space` borne l'amplitude, le bruit et les déplacements (sauts, courses navette).

### Une variante par lieu

Pour un même objectif (ex. stabilité de hanche), prévoir **une variante par lieu** quand l'athlète s'entraîne à plusieurs endroits : il choisit selon où il est. Deux séances du même objectif à deux endroits différents sont deux séances différentes.

### Nommage obligatoire

Le `workoutName` doit porter le lieu, pour que la planification soit lisible d'un coup d'œil :

- `<prefix>Renfo <objectif> (<lieu>, <contrainte matériel>)` — p. ex. `AI - Renfo hanche (extérieur, sans matériel)`, `AI - Renfo hanche (maison, élastiques)`

Et dans la `description` : lister explicitement le matériel requis en première ligne (`Materiel : aucun` / `Materiel : elastique + tapis`). L'athlète ne doit jamais découvrir à l'échauffement qu'il lui manque quelque chose.

### Objets du quotidien

Chaise, sac à dos, mur, banc : à proposer et faire valider explicitement avant de finaliser un step qui s'appuie dessus, sauf s'ils figurent déjà dans `equipment` ou `supports`.

### Exemple de filtrage : exos valides SANS matériel et DEBOUT

Cas d'un lieu avec `equipment: []`, `floor_ok: false`, `supports: [mur, poteau, banc, marche, trottoir]`. Testés contre le catalogue Garmin :

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

Même logique à refaire pour tout autre jeu de contraintes : partir des contraintes du lieu, pas d'une liste figée.

## RepeatGroupDTO — structure obligatoire

Voir `references/json-examples.md` pour les exemples JSON annotés complets (renfo, 30/30 à l'allure, fartlek FC).

Règles clés :
- `"type": "RepeatGroupDTO"`, `stepTypeId: 6`
- `endCondition` : toujours `conditionTypeId: 7` (iterations) — l'omettre corrompt silencieusement le nombre de répétitions
- `endConditionValue` = nombre de répétitions
- `workoutSteps` : les steps enfants pour UN seul passage
- `skipLastRestStep` : toujours explicite

## Conditions de fin des steps de récupération

- **Chronométré** : `conditionTypeId: 2, conditionTypeKey: "time"`, valeur en secondes.
- **Manuel / lap-button** : `conditionTypeId: 1, conditionTypeKey: "lap.button"`, pas de valeur.

Défauts : renfo → lap-button (ou `session_preferences.rest_mode`). Course → chronométré, sauf demande contraire de l'athlète.
