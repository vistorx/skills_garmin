---
name: garmin-health-check
description: Auto health and training status check before any planning.
version: 1.2.0
author: hermes-garmin-skills contributors
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

**D'abord : lire `device.capabilities` dans le profil.** Les métriques de récupération ne
sont pas universelles — readiness, statut d'entraînement, HRV nocturne et body battery
n'existent pas sur tous les appareils. Si une capacité est `unsupported`, ne pas interroger
le tool correspondant et **ne pas présenter l'absence comme une anomalie** : c'est une
limite matérielle normale. Construire le bilan sur ce que l'appareil fournit réellement,
et le dire une fois.

```
get_training_readiness(date)                      → readiness score + facteurs
get_training_status(date)                         → statut d'entraînement, charge, VO2max
get_sleep_summary(date)                           → sommeil, version compacte (~350 o)
get_hrv_trend(start_date, end_date)               → HRV quotidienne + moyenne glissante 7j
get_body_battery(start_date, end_date)            → body battery sur la période
get_vo2max_trend(start_date, end_date)            → tendance aérobie (4 à 12 semaines)
get_training_load_trend(start_date, end_date)     → CTL / ATL / TSB / ACWR
get_activities_by_date(start_date, end_date)      → charge récente : volume, intensité, sports, repos
```

**Toutes les plages prennent des dates explicites `YYYY-MM-DD`** — calculer les bornes en
Python (`date.today()`, `timedelta`), ne jamais écrire « 4 dernières semaines » comme
argument. Fenêtres : 14 jours pour les activités et le body battery, 7 à 21 jours pour la
HRV, 4 à 8 semaines pour la charge, 4 à 12 semaines pour le VO2max.

**Prendre les variantes légères.** `get_sleep_summary` renvoie ~350 octets là où
`get_sleep_data` en renvoie ~50 Ko de série temporelle ; même rapport entre
`get_heart_rates_summary` (~500 o) et `get_heart_rates` (~25 Ko). Un bilan quotidien n'a
jamais besoin de la série brute, et la charger sature le contexte pour rien.

**HRV : jamais un seul jour.** `get_hrv_data` ne donne qu'une date isolée, trop bruitée pour
décider quoi que ce soit. `get_hrv_trend` renvoie les valeurs quotidiennes **et** la moyenne
glissante sur 7 jours — c'est l'écart à cette base qui est exploitable.

Socle disponible sur tout appareil enregistrant des activités : `get_activities_by_date`
(volume, intensité, régularité, écarts de repos). Un bilan utile reste possible sans aucune
métrique physiologique — plus prudent, mais valable.

## Garmin Training Status — Interpretation

Surface this label explicitly every time. It's the central signal for planning.

| Status | Meaning | Planning implication |
|---|---|---|
| **Productive** | Load generating adaptation | Maintain or slightly increase |
| **Maintaining** | Holding fitness, not growing | Add one quality session if slot available |
| **Recovery** | Body adapting post-load | Light sessions only, prioritize rest |
| **Unproductive** | Training not generating benefit | Check sleep, stress, nutrition first |
| **Overreaching** | Accumulated too much load | Mandatory recovery week, no exceptions |
| **Strained** | Charge élevée sur un corps peu préparé | Traiter comme Overreaching : récupération, pas de progression |
| **Detraining** | Activity level too low | Gradually increase volume |
| **No status** | Not enough data | Use readiness + activity history as proxy |

**Le label arrive suffixé** (`MAINTAINING_2`, `PRODUCTIVE_8`, `STRAINED_4`, `RECOVERY_1`…) :
le suffixe est un code de message Garmin, pas un niveau de gravité. Découper sur le `_` pour
obtenir le statut, et utiliser `training_status_code` quand on a besoin d'une comparaison
stable.

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

À chaque health check, vérifier ces signaux. Lever un flag si ≥2 sont présents simultanément :

| Signal | Source | Seuil d'alerte |
|---|---|---|
| Charge aiguë/chronique déséquilibrée | `get_training_load_trend` → `acwr_status` | `HIGH` (surcharge) ou `LOW` prolongé (décharge) |
| CTL hors de la fenêtre optimale | `get_training_load_trend` | `ctl` sous `optimal_chronic_load_min` ou au-dessus de `optimal_chronic_load_max` |
| TSB très positif avec CTL en chute | `get_training_load_trend` | Fraîcheur artificielle : l'athlète ne s'entraîne plus, ce n'est pas de la forme |
| HRV déséquilibrée | `get_hrv_trend` → `status` | `UNBALANCED` ou `LOW` sur plusieurs nuits, ou `last_night_avg_hrv_ms` nettement sous `weekly_avg_hrv_ms` |
| Sommeil dégradé | `get_sleep_summary` → `sleep_score` | < 70 sur 5+ nuits |
| Body battery qui ne remonte pas | `get_body_battery` | Max quotidien < 60 sur 5+ jours |
| Statut Garmin dégradé | `get_training_status` | `UNPRODUCTIVE`, `STRAINED`, `OVERREACHING` |
| Volume en marche d'escalier | `get_activities_by_date` | Augmentation > 20 % en une semaine |

**Utiliser les classifications de Garmin plutôt que des seuils maison.** `acwr_status`
(`OPTIMAL` / `HIGH` / `LOW`) et le `status` HRV (`BALANCED` / `UNBALANCED` / `LOW`) sont
déjà calibrés sur l'athlète. Et surtout : **l'échelle de `tsb` et `ctl` dépend du compte** —
des valeurs de ±250 sont normales sur certains profils. Ne jamais appliquer un seuil absolu
de TSB ; lire la position relative via `optimal_chronic_load_min` / `max`, et la direction
du `ctl` sur la période.

**CTL / ATL / TSB / ACWR est le signal le plus solide de la table** : objectif, calculé sur
la charge réelle, là où sommeil et body battery sont des proxys sensibles au stress non
sportif. Le lire en premier ; si l'ACWR est `OPTIMAL` et le CTL dans sa fenêtre, un mauvais
score de sommeil isolé ne justifie pas de casser la semaine.

**Piège d'interprétation : un TSB très positif n'est pas une bonne nouvelle en soi.** Quand
le CTL s'effondre en parallèle, la « fraîcheur » ne traduit pas une forme mais un arrêt
d'entraînement — Garmin bascule alors en `DETRAINING`. Lire TSB et tendance du CTL ensemble,
jamais TSB seul.

Pour un athlète coureur, `get_running_tolerance_trend` complète utilement : il expose la
capacité de charge en kilomètres et le `load_ratio` (combien l'intensité renchérit chaque
kilomètre) — précieux quand la blessure est liée au volume d'impacts.

Si flag levé : le signaler clairement, nommer les signaux concernés, recommander Repos actif
indépendamment de la demande, et expliquer pourquoi.

## Conditions Météo — Ajustement pour activités extérieures

Pour toute séance de running, cyclisme ou sport extérieur planifiée :
- Si température prévue >25°C : noter dans le workout ("Par forte chaleur, réduire l'allure de 5-10% à effort égal")
- Si température <0°C : échauffement plus long recommandé (+3-5 min)
- Si vent fort ou pluie : ajuster les objectifs de pace (ne pas se fixer sur les allures Garmin habituelles)
- Source météo : demander à l'athlète ou utiliser `maps` skill si disponible. Ne pas inventer les conditions.
