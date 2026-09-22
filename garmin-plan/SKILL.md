---
name: garmin-plan
description: Use for any training request. Routes to weekly or session.
version: 1.0.0
author: Victor Ourd, Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [garmin, planning, routing, training]
    related_skills: [garmin-weekly-plan, garmin-session-plan, garmin-health-check, training-profile]
---

# Garmin Plan — Master Router

Point d'entrée unique pour toute demande de planification. Détecte le mode et délègue au bon skill. Ne contient pas de logique de séance — il route.

## Quand charger ce skill

Toute demande liée à l'entraînement : planification, recommandation de séance, "qu'est-ce que je fais", "planifie ma semaine", "j'ai 45 minutes".

---

## Détection du mode

### 🗓️ Mode Complet → `garmin-weekly-plan`

Triggers :
- *"Planifie ma semaine"* / *"la semaine prochaine"*
- *"Qu'est-ce que je fais cette semaine ?"*
- *"On prépare le mois"* / *"nouveau cycle"*
- Mention explicite de plusieurs jours ou d'une structure hebdomadaire

### ⚡ Mode Ponctuel → `garmin-session-plan`

Triggers :
- *"Je veux faire un run"* / *"une séance de muscu"*
- *"Qu'est-ce que tu me recommandes ?"* sans contexte semaine
- *"J'ai 45 minutes ce soir"* / *"j'ai le temps là"*
- Mention d'un sport ou d'une durée sans évoquer la semaine

**Règle par défaut** : en cas de doute → **Mode Ponctuel**. Plus léger, moins intrusif. Proposer le mode complet à la fin si pertinent.

---

## Routing

```
Demande reçue
    ├── semaine / cycle / plusieurs jours  →  garmin-weekly-plan
    └── séance / sport / durée / maintenant  →  garmin-session-plan
```

Charger le skill cible immédiatement — ne pas reproduire sa logique ici.
