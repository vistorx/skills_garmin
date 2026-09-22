# Garmin Fitness Skills

Skills [Hermes Agent](https://hermes-agent.nousresearch.com/docs) pour le coaching sportif via [Garmin Connect MCP](https://github.com/cyberjunky/python-garminconnect).

---

## Skills

### `training-profile`
Lit et maintient le contexte de l'athlète entre les sessions : sports pratiqués, disponibilités, niveau, équipement, blessures actives, préférences de séance. À charger avant tout planning.

### `garmin-onboarding`
Protocole de premier contact en 5 blocs. Récupère ce que Garmin sait déjà, ne demande que ce qui manque. À lancer une seule fois pour construire le profil complet.

### `garmin-health-check`
Bilan automatique au démarrage de chaque session de planning : readiness, statut d'entraînement, HRV, body battery, VO2max, détection de surmenage. Lecture seule — ne planifie pas.

### `garmin-weekly-plan`
Planification complète d'une semaine : health check → objectif semaine → squelette des jours → choix des séances depuis la librairie → upload + schedule sur calendrier Garmin. Couvre tous les sports.

### `garmin-workouts`
Construit et uploade des workouts Garmin (JSON). Librairie de séances running, renfo, multi-sport. Règles de calibrage depuis les données Garmin réelles (zones FC, allures, seuil lactique).

### `medical-report`
Génère un compte-rendu structuré pour kiné ou médecin à partir des données Garmin et du contexte de blessure.

---

## Librairies de séances (`garmin-workouts/references/`)

| Fichier | Contenu |
|---|---|
| `sessions-running.md` | EF, fractionné court/long, seuil, côtes — zones depuis Garmin |
| `sessions-strength.md` | Exercices mappés aux enums Garmin natifs, par groupe musculaire |
| `sessions-multi-sport.md` | Cyclisme, natation, sports collectifs, escalade |
| `warmup-protocols.md` | Protocoles d'échauffement par type de séance (science-based, pas d'étirements statiques avant effort) |
| `json-examples.md` | Structures JSON Garmin annotées : RepeatGroupDTO, zones allure, zones FC |

---

## Principes

- **Garmin est la source de vérité** — zones FC, seuil, VO2max, allures lus directement depuis l'API, jamais recalculés
- **Le profil vit en mémoire** — données athlète (blessures, équipement, objectifs) stockées en mémoire persistante Hermes, pas dans les skills
- **Tous les workouts créés sont préfixés `AI -`** — identification facile sur la montre et dans l'app
- **Règle 80/20** — ~80% du volume en zones faciles (Z1-Z2), ~20% en intensité

---

## Setup

Pré-requis : [Hermes Agent](https://hermes-agent.nousresearch.com/docs) + plugin Garmin MCP configuré.

Au premier démarrage :
> *"Crée mon profil de sportif"*

Puis :
> *"Planifie ma semaine"*

---

## Auto-sync

Toute modification de skill est automatiquement committée et poussée via hook Hermes (`agent-hooks/auto-sync-skills.sh`).

```bash
# Sync manuel
bash scripts/sync_to_github.sh "chore: description"
```
