---
name: garmin-health-check
description: Auto health and training status check before any planning.
version: 1.0.0
author: Victor Ourd, Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [garmin, health, readiness, training-status, recovery]
    related_skills: [garmin-weekly-plan, training-profile]
---

# Garmin Health Check Skill

Fetches and interprets all available Garmin signals to produce a clear picture of an athlete's current state. Works for **any sport, any routine**. Always run automatically at the start of any planning session.

## When to Use

- **Automatically**: at the start of every `garmin-weekly-plan` session.
- **On demand**: "comment je vais ?", "quel est mon état de forme ?", "bilan de la semaine".

Don't use for: planning or building sessions — this is read-only analysis.

## Data to Fetch (all in parallel)

```
get_training_readiness(date=today)     → readiness score, sleep, HRV, recovery time
get_training_status(date=today)        → Garmin training status label
get_hrv_data(date=today)               → HRV trend vs weekly average
get_sleep_data(date=today)             → sleep quality details
get_vo2max_trend(last 4 weeks)         → aerobic fitness trend
get_activities(last 14 days)           → recent load: volume, intensity, sport mix, rest gaps
get_body_battery(date=today)           → energy level if available
```

## Garmin Training Status — Interpretation

Surface this label explicitly every time. It's the central signal for planning.

| Status | Meaning | Planning implication |
|---|---|---|
| **Productive** | Load generating adaptation | Maintain or slightly increase |
| **Maintaining** | Holding fitness, not growing | Add one quality session if slot available |
| **Recovery** | Body adapting post-load | Light sessions only, prioritize rest |
| **Unproductive** | Training not generating benefit | Check sleep, stress, nutrition first |
| **Overreaching** | Accumulated too much load | Mandatory recovery week, no exceptions |
| **Detraining** | Activity level too low | Gradually increase volume |
| **No status** | Not enough data | Use readiness + activity history as proxy |

## Output Format

Always three sections, always in this order:

### 1. État du jour
- Readiness score + level (Low / Moderate / High)
- Sleep score
- Body battery (if available)
- HRV vs weekly average (above / at / below baseline)
- Recovery time remaining

### 2. Tendance de la semaine
- Garmin training status — label + plain-language interpretation
- VO2max trend over 4 weeks (stable / +X / -X)
- Load over last 14 days: session count, dominant sport(s), notable rest gaps
- Any signal worth flagging: missed sessions, unusual HR, very short/long sessions

### 3. Recommandation pour la planification

One verdict, one reason:

- 🟢 **Progresser** — all signals green, room to add stimulus
- 🟡 **Maintenir** — reasonable state, hold current load
- 🟠 **Récupérer** — reduce volume/intensity this week
- 🔴 **Repos actif** — one or two very light sessions max

Always 1–2 sentences: which signal is driving the recommendation and why.

## Injury Status Bridge

After the 3 sections:
- Check `training-profile` memory for active injury flags.
- If flagged: surface it explicitly, ask current status if not already confirmed this session.
- Never move to planning without resolving this.

## Burnout / Surmenage — Détection de patterns

À chaque health check, vérifier ces signaux sur les 14 derniers jours. Lever un flag si ≥2 sont présents simultanément :

| Signal | Source | Seuil d'alerte |
|---|---|---|
| HRV en baisse persistante | `get_hrv_data` | Baisse >10% sur 7j consécutifs |
| Sommeil dégradé | `get_sleep_data` | Score <70 sur 5+ nuits |
| Body battery qui ne remonte pas | `get_body_battery` | Max quotidien <60 sur 5+ jours |
| Statut Garmin Unproductive/Overreaching | `get_training_status` | Présent |
| Volume brutal | `get_activities` | Augmentation >20% en 1 semaine |

Si flag levé : signaler clairement, recommander Repos actif indépendamment de ce que l'athlète demande, expliquer pourquoi.

## Conditions Météo — Ajustement pour activités extérieures

Pour toute séance de running, cyclisme ou sport extérieur planifiée :
- Si température prévue >25°C : noter dans le workout ("Par forte chaleur, réduire l'allure de 5-10% à effort égal")
- Si température <0°C : échauffement plus long recommandé (+3-5 min)
- Si vent fort ou pluie : ajuster les objectifs de pace (ne pas se fixer sur les allures Garmin habituelles)
- Source météo : demander à l'athlète ou utiliser `maps` skill si disponible. Ne pas inventer les conditions.
