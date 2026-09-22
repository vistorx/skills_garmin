---
name: medical-report
description: Use when Victor needs a kine/doctor report.
version: 1.0.0
author: Victor Ourd, Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [kine, medecin, blessure, rapport, compte-rendu]
    related_skills: [training-profile, garmin-health-check]
---

# Medical Report Skill

Génère un compte-rendu synthétique pour un rendez-vous kiné ou médecin, basé sur les données Garmin et les retours de séance enregistrés.

## Quand utiliser

- "Je vais chez le kiné, fais-moi un CR"
- "J'ai un rendez-vous médecin, topo rapide"
- "Qu'est-ce que je dis au kiné ?"

## Données à récupérer

Tout en parallèle :

```
get_activities(last 7 days)           → séances récentes + descriptions (retours Victor) — défaut 7j, ajustable à la demande
get_training_readiness(today)         → état du jour
get_sleep_summary_range(last 7 days)  → qualité du sommeil
get_hrv_trend(last 14 days)           → tendance récupération
get_rhr_day(today)                    → FC repos
```

Lire aussi le profil mémoire (`training-profile`) pour :
- Blessures actives (localisation, contexte, date)
- Historique des sensations notées

## Format du CR

Court, factuel, structuré. Le kiné veut des faits, pas du remplissage.

---

**CR Kiné / Dr [Nom] — [Date]**

**Blessure(s) suivie(s)**
- [Localisation] : contexte, symptômes, depuis quand

**Séances des 7 derniers jours** (ou N jours si demandé)
- [Date] [Sport] [durée/distance] — [retour Victor si disponible]
- ...

**Signaux objectifs (Garmin)**
- Readiness : [score] / [niveau]
- FC repos : [valeur]
- Sommeil : [score moyen 7j]
- HRV : [tendance : stable / en hausse / en baisse]

**Points à aborder avec le praticien**
- [Issu des retours de séance et des signaux]

---

## Règles

- Jamais inventer ou interpréter médicalement — rapporter les faits et sensations notées
- Si une séance n'a pas de description/retour → noter juste le type + durée, sans commentaire
- La section "Points à aborder" = ce que les données suggèrent de mentionner, pas un diagnostic
- Toujours demander à Victor s'il veut ajouter quelque chose avant de finaliser
- Format lisible à voix haute (Victor peut le lire directement en séance)

## Variante médecin généraliste

Même structure, mais ajouter si dispo :
- VO2max tendance (4 semaines)
- Poids / composition corporelle récente
- Tout signal inhabituel (FC anormalement élevée, sommeil dégradé persistant, etc.)
