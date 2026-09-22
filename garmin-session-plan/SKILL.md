---
name: garmin-session-plan
description: Use when athlete wants one session now. No weekly plan.
version: 1.0.0
author: Victor Ourd, Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [garmin, planning, session, ponctuel, training]
    related_skills: [garmin-plan, garmin-workouts, garmin-health-check, training-profile]
---

# Garmin Session Plan — Séance Ponctuelle

Recommande et construit une séance unique, calibrée depuis les données Garmin réelles. Flow court — pas de squelette semaine, pas d'onboarding, pas de health check complet.

## Quand utiliser

- *"Je veux faire un run"*, *"une séance de muscu ?"*, *"qu'est-ce que tu me recommandes ?"*
- Demande d'un sport ou d'une durée sans contexte hebdomadaire.
- Routé depuis `garmin-plan`.

---

## Flow

### 1. Readiness rapide

`get_training_readiness` + `get_training_status` — score + statut uniquement.

| Score | Implication |
|---|---|
| ≥ 70 | Séance normale, respecter la demande |
| 50–69 | Modérer l'intensité si la demande est haute, expliquer |
| < 50 | Proposer Z2 ou récup active même si intensité demandée — expliquer pourquoi |

Si statut = Overreaching → récupération active uniquement, ne pas céder si l'athlète insiste.

### 2. Dernière séance du sport demandé

`get_activities_by_date` (7 derniers jours), filtrer sur le sport.
- Type, intensité, durée, date → récup restante estimée

### 3. Questions — 1-2 max

Poser seulement ce qu'on ne peut pas inférer :
- **Durée disponible** — si pas mentionnée et pas en mémoire
- **État du jour** — si blessure active en mémoire

Ne pas poser les deux si le contexte répond déjà à l'une.

### 4. Proposition

1 séance, structure complète :
- Type choisi + justification 1 ligne (variation vs dernière séance + readiness)
- Durée totale
- Étapes détaillées (échauffement, bloc principal, retour calme)
- Cibles calibrées depuis Garmin : zones FC (`zoneNumber`), allures (`get_race_predictions`)
- Adaptation blessure si active

**Règle de variation obligatoire** : différente de la dernière séance du même sport sur au moins un levier (durée ou intensité).

### 5. Upload optionnel

Proposer d'uploader sur Garmin après validation. Jamais sans accord.

### 6. Transition douce

Une seule ligne à la fin :
> *"Je peux aussi planifier ta semaine complète si tu veux."*

---

## Ce qu'on ne fait PAS

- ❌ Squelette semaine
- ❌ Questions sur les disponibilités globales
- ❌ Health check complet (rapport 3 sections)
- ❌ Onboarding si profil incomplet — travailler avec ce qu'on a
- ❌ Upload sans accord

---

## Références sessions

- Running : `garmin-workouts/references/sessions-running.md`
- Renfo : `garmin-workouts/references/sessions-strength.md`
- Autres sports : `garmin-workouts/references/sessions-multi-sport.md`
- Échauffements : `garmin-workouts/references/warmup-protocols.md`
