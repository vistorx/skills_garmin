---
name: garmin-mcp-upload
description: Upload Garmin workouts via MCP. Tool shape and batch recipe.
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [garmin, mcp, workout, upload, strength, plyo]
    related_skills: [garmin-workouts, garmin-plan, training-profile]
---

# Garmin MCP Upload — mécanique d'upload

Companion de `garmin-workouts` (user-owned, non modifiable en curation) : couvre la mécanique pure d'appel MCP et de construction de payload. Pour la *programmation* des séances (phase, volume, ordre des exos, consignes blessure), suivre `garmin-workouts` — ce skill ne dit rien du contenu.

## Quand charger ce skill

- Upload d'une séance force ou pliométrie construite à la main (échauffement + groupes + cooldown).
- Lot de séances, ou reprise d'une séance existante.
- Échec `is not a known tool name`, `calls is not valid JSON`, ou `400 must not be null` sur un upload.

---

## 1. Forme exacte de l'appel

`tool_call` prend `calls` = liste d'objets `{"name": <chaîne nue>, "arguments": <objet>}`.

```
tool_call(calls=[{"name": "mcp__garmn__upload_workout",
                  "arguments": {"workout_data": {<DTO complet>}}}])
```

**Ne jamais** passer `name` en tableau ni `arguments` en positionnel : l'appel n'atteint pas le serveur et échoue en `'...' is not a known tool name` ou `calls is not valid JSON`.

**Après 2 tentatives mal formées : arrêter, relire cette section, ne pas muter les arguments à l'aveugle.** Itérer sur un appel qui ne parse pas ne converge jamais et épuise le tour — c'est ce qui a fait échouer la construction d'un lot de 5 séances.

### Quel outil pour quoi

| Outil | Usage | Piège connu |
|---|---|---|
| `upload_workout` | Cas contrôle. `workout_data` = DTO complet. | Aucun si le DTO est complet |
| `upload_workouts` | Batch prévu | Atteint Garmin mais lui transmet un DTO **vide** (`workoutName=null, sportType=null, workoutSegments=[]`) : `400 ... must not be null`. Pour un lot, **appeler le singulier en boucle** |
| `create_strength_workout` | `name` + `exercises[{name, sets, reps, rest_seconds, category}]` | Suffit seulement sans échauffement/cooldown distincts |

## 2. Construire un lot — les deux pièges coûteux

**Objet dict partagé entre séances.** `stepOrder` est muté après assemblage ; un cooldown construit une seule fois et réutilisé corrompt le `stepOrder` de toutes les autres séances *sans erreur*. Toujours `copy.deepcopy` ou construction fraîche par séance.

**Renumérotation en deux temps.** `steps.pop()` puis append laisse un `stepOrder` trou. Renuméroter une seule fois, après assemblage :

```python
for i, s in enumerate(steps, 1):
    s["stepOrder"] = i
```

## 3. Gate de validation — obligatoire avant tout upload

Un échec ici est **invisible sur la montre** (le workout s'affiche quand même, avec un contenu faux). À vérifier dans le script, pas à l'œil :

- `stepOrder` contigu de 1 à N, sans doublon ni trou
- tout `RepeatGroupDTO` porte `endCondition.conditionTypeId: 7` **et** `endConditionValue == numberOfIterations` (sinon Garmin corrompt silencieusement le nombre de répétitions)
- chaque `exerciseName` existe dans `categories[cat].exercises` du catalogue officiel
- **balayage des descriptions pour caractères hors alphabet cible** : un générateur peut laisser filer des mots d'une autre langue dans un texte censé être en français. Les descriptions sont du texte libre affiché sur le poignet — les relire avant d'envoyer.
- **`sport` attendu** : comparer le champ `sport` relu à l'intention (voir table sportTypeId §4). Un ID faux ne lève aucune erreur.
- **structure non-running** : sur une séance muscu/HIIT, vérifier dans le JSON relu qu'un step `rest` clôt l'échauffement, qu'un step `rest` termine **chaque** `repeat` (`skipLastRestStep: false` partout), et que **tous** les steps `rest` sont en `lap.button` — aucun repos à durée fixe. Voir `garmin-workouts` → Structure des séances non-running.
- **matériel requis vs matériel disponible** : chaque `exerciseName` doit être réalisable avec ce que l'athlète a sur place (voir `garmin-workouts` → Equipment). Un exo à charge pour quelqu'un sans poids = séance jetée. Vérifier aussi la posture : pas d'exo au sol si la séance se fait en extérieur.

Puis relire après envoi avec `get_workout_by_id`.

## 4. Catalogue d'exercices

Récupérer le catalogue public (lecture seule) et filtrer par mot-clé sur le nom normalisé :

```bash
curl -sS -o Exercises.json https://connect.garmin.com/web-data/exercises/Exercises.json
```

47 catégories, ~1531 exercices. Aucun nom d'exercice n'existe en français : passer par l'équivalent Garmin le plus proche et porter la consigne réelle dans `description`.

| Intention | `category` | `exerciseName` |
|---|---|---|
| Spanish squat / wall sit | SQUAT | `BODY_WEIGHT_WALL_SQUAT` |
| Step-down lent | SQUAT | `STEP_UP` + consigne step-down en description |
| Pallof press | CORE | `CABLE_CORE_PRESS` |
| Copenhagen plank | PLANK | `SINGLE_LEG_SIDE_PLANK` |
| Abduction hanche debout | HIP_STABILITY | `STANDING_HIP_ABDUCTION` |
| Marche latérale élastique | HIP_STABILITY | `LATERAL_WALKS_WITH_BAND_AT_ANKLES` |
| Pont fessier unipodal | HIP_RAISE | `SINGLE_LEG_HIP_RAISE` |
| Hip thrust | HIP_RAISE | `BARBELL_HIP_THRUST_WITH_BENCH` |
| Split squat bulgare | LUNGE | `DUMBBELL_BULGARIAN_SPLIT_SQUAT` |
| RDL unipodal | DEADLIFT | `SINGLE_LEG_ROMANIAN_DEADLIFT_WITH_DUMBBELL` |
| Mollets debout | CALF_RAISE | `WEIGHTED_STANDING_CALF_RAISE` (pas `..._DUMBBELL_`, ce nom n'existe pas) |
| Mollets assis (soleaire) | CALF_RAISE | `WEIGHTED_SEATED_CALF_RAISE` |
| Pogo bipodal | CARDIO | `JUMP_ROPE` (et non WARM_UP) |
| Skater / hop unipodal | PLYO | `LATERAL_LEAP_AND_HOP` |
| Saut de haie | PLYO | `BOX_JUMP_OVERS` |

### sportTypeId — table propre aux WORKOUTS

Ne jamais utiliser les IDs de `get_activity_types` : les workouts ont leur propre référentiel. Source de vérité : `read_resource(uri="workout://reference/structure")` → `sportType_values`.

| ID | Key |
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

L'API accepte **n'importe quel entier sans erreur** : elle ignore le `sportTypeKey` fourni à côté et ne garde que l'ID. Un ID faux produit un workout d'un autre sport, silencieusement (`25` → indoor_cycling, `13` → rucking — vérifié par upload réel 2026-10-06). **Ajouter le champ `sport` à la gate de validation** : relire avec `get_workout_by_id` et comparer à l'intention avant de scheduler.

## 5. Ne jamais appeler le serveur MCP a la main

Tous les outils passent par `tool_call`. **Interdit** de rejouer du JSON-RPC en Python `urllib` vers l'endpoint MCP pour « aller plus vite » ou « voir la payload brute » : ça declenche une demande de confirmation qui fait perdre plusieurs minutes a Victor, et ça sort du chemin teste.

Le catalogue d'exercices se recupere bien par `curl` sur `connect.garmin.com` (public, lecture seule) — ça c'est correct.

---

## Style de reponse attendu par Victor

Reponses **concises** — demande explicite de sa part. Une ligne d'etat, les chiffres qui comptent, pas le recit du cheminement ni des echecs intermediaires. Les rapports longs vont dans un fichier attache ou un bloc, pas dans le fil de conversation.

## Rappel du contexte blessure

Avant tout contenu de seance, relire le profil (genou G femoro-patellaire, genou D ITB, reprise progressive) et porter le seuil de douleur explicite dans la description du workout. Un template sans seuil de douleur n'est pas publiable pour ce profil.
