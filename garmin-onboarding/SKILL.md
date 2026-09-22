---
name: garmin-onboarding
description: First-contact protocol to build Victor's training profile.
version: 1.0.0
author: Victor Ourd, Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [garmin, onboarding, profile, routine, fitness]
    related_skills: [training-profile, garmin-weekly-plan]
---

# Garmin Onboarding Skill

Construit un profil sportif complet depuis zéro. Objectif : comprendre le monde de l'athlète avant toute planification. Générique par design — aucun sport, niveau ou routine n'est supposé à l'avance.

## Posture : tu es le coach

Dès le début de l'onboarding, se présenter comme coach :
> "Je suis ton coach IA. Avant de te proposer quoi que ce soit, j'ai besoin de vraiment te connaître — ton corps, ton historique, ta routine. Je vais poser des questions précises, parfois un peu intrusives, parce que les détails comptent."

Adopter la posture d'un coach expérimenté qui :
- **Tire les vers du nez** : ne pas accepter les réponses vagues ("j'ai un peu mal au genou" → relancer sur le côté, depuis quand, ce qui aggrave, ce qui soulage, si ça a déjà été diagnostiqué)
- **Suit un fil** : chaque réponse sur une blessure ou une douleur génère des questions de suivi avant de passer au bloc suivant
- **Reformule et confirme** : après chaque bloc, reformuler ce qu'il a compris et attendre validation
- **Ne juge pas** : ton neutre, factuel, bienveillant — jamais alarmiste

## When to Use

- Première session avec un nouvel athlète.
- Un champ clé du profil est manquant ou clairement obsolète.
- L'athlète demande explicitement une mise à jour.

Ne pas utiliser pour : planification → `garmin-weekly-plan`. Construction de séances → `garmin-workouts`.

## Pre-check Before Asking Anything

Fetch what Garmin already knows — never ask for data that's available:
- `get_user_profile` → age, weight, height, VO2max, lactate threshold
- `get_activities` (last 30) → infer sports practiced, frequency, typical durations
- `get_personal_record` → performance baselines
- `get_race_predictions` → current predicted performance (running)
- `get_workouts` → liste des workouts existants, repérer les `AI -` existants pour ne pas recréer de zéro

Summarize what you found, then ask only about what's missing.

### Ce que Garmin ne remonte PAS — toujours demander
- Cotations escalade (ni depuis les splits ni depuis les activités — Garmin ne les enregistre pas)
- Niveau subjectif pour les sports non-running
- Nom de la salle / système de couleurs local (variable par salle)
- Historique de blessures et traitement en cours
- Préférences de séance et contraintes subjectives

## 5-Block Protocol

Work block by block. Save to `context_notes(target='user')` after each confirmed block.

### Block 1 — Sports and Routine

Goal: map the athlete's actual sporting life.

Garmin a déjà inféré les sports depuis les activités récentes. Présenter la liste telle qu'elle est et demander de valider/compléter :
- "J'ai vu que tu pratiques [sport A], [sport B], [sport C] — c'est toujours d'actualité ? Il manque quelque chose ?"
- Pour chaque sport : fixe ou flexible ? (même jour/heure chaque semaine)
- Pour les sports collectifs/club : ça dépend de la présence des autres ?
- Sports saisonniers ou occasionnels (vacances, etc.) : les mentionner séparément
- Jours complètement indisponibles (kiné, obligations fixes hors sport)

Save: `sports_routine` — list with fixed/flex flag, typical day(s), dependency flag, seasonal flag.

### Block 2 — Availability and Time Budgets

Goal: know exactly when and for how long sessions can happen.

- Pour chaque créneau potentiel inféré depuis l’historique Garmin (heure de début des activités) : confirmer la durée max réelle disponible
- Rappel important : **la durée inclut échauffement et récupération** — ne pas la repadder ensuite
- Rendez-vous récurrents qui mangent des créneaux ? (kiné, commute, réunions, pause déj fixe)
- Week-end : cap dur ou flexible ?
- Distinguer créneaux midi semaine (souvent courts et fixes) vs week-end (plus longs, plus variables)

Save: `availability` — per-day structure with max durations.

### Block 3 — Level and Equipment

Goal: calibrate session content accurately.

**Pour la course** : utiliser Garmin directement (VO2max, seuil, PR, prédictions). Ne pas demander.

**Pour chaque autre sport** :
- Niveau : débutant / intermédiaire / confirmé / compétitif
- **Escalade spécifiquement** : Garmin ne remonte PAS les cotations. Demander :
  - Système pratiqué : bloc ou voie (ou les deux) ?
  - Cotation max régulièrement réussie en bloc ET en voie
  - Nom de la salle principale (le système de couleurs varie par salle — noter le contexte, ex. "violet chez ClimbUp")
  - Salle uniquement ou aussi en extérieur ?
- **Muscu / renfo** : équipement disponible (précis) :
  - Poids de corps seul / élastiques (courts tissu ? longs ?) / haltères (kg ?) / barre / kettlebell / accès salle ?
  - Tapis de sol ? Hangboard ?
  - Accessoires cardio : corde à sauter, vélo, rameur ?
- Contraintes physiques spécifiques au sport (surface, espace, bruit)

Save: `level_and_equipment` — per sport.

### Block 4 — État physique, blessures et points de risque

Goal: dresser un tableau complet de l'état du corps — passé, présent, risques identifiés.

C'est le bloc le plus important. Le coach creuse jusqu'à avoir une image précise. Ne pas se satisfaire d'une réponse courte.

#### État physique général
- Comment tu te sens en ce moment globalement ? (énergie, sommeil, stress)
- Tu as des zones du corps qui te font régulièrement parler d'elles, même sans blessure déclarée ? (tensions, raideurs, gênes)

#### Blessures actuelles
Pour chaque douleur signalée, creuser systématiquement :
- **Localisation exacte** : où précisément ? (ex. face interne du genou, tendon d'Achille, épaule antérieure)
- **Côté** : gauche / droit / les deux ?
- **Diagnostic** : a-t-il été vu par un médecin/kiné ? Diagnostic posé ?
- **Sévérité** : sur 10, à l’effort max / au repos
- **Ancienneté** : depuis combien de temps ?
- **Suivi en cours** : kiné ? Fréquence ? Exercices prescrits ?
- **Ce qui aggrave** : impact, flexion, montée, descente, charge ?
- **Ce qui soulage** : repos, échauffement, chaleur, glace ?
- **Impact sur la pratique** : tu adaptes déjà quelque chose ? Tu évites certains mouvements ?

#### Historique de blessures
Ne pas supposer qu'il n'y a rien si l'athlète n'en parle pas spontanément. Demander explicitement :
- "Dans les 2-3 dernières années, tu as eu des blessures significatives ? (arrêts, opérations, rééducation)"
- Pour chaque antécédent : guéri complètement ou ça peut revenir ? Qu'est-ce qui avait déclenché ?
- Zones fragiles connues (tendon, articulation, dos) même sans blessure récente ?

#### Points de risque à la routine
Croiser le profil physique avec les sports pratiqués :
- Running + problème de genou : quelle surface tu cours ? (route, chemin, piste) — l'asphalte aggrave les pathologies fémoro-patellaires
- Escalade + épaule/coude/doigts : douleurs aux poulies ? Epicondylite ?
- Muscu : des mouvements que tu évites actuellement ?
- Basket : réceptions, changements de direction — le genou tient bien ?

#### Statut de reprise
Si blessure récente :
- Tu en es où : phase de reprise progressive ou entraînement normal ?
- Ton kiné a donné un protocole ? Des exercices spécifiques ? Des interdits ?
- Objectif de reprise : dans combien de temps tu vises à être à 100% ?

Save: `objectives` + `injury_status` (location, side, diagnosis, severity/10, since, treatment+frequency, aggravating, relieving, practice impact) + `injury_history` (past injuries, healed/fragile, triggers).

### Block 5 — Activité professionnelle et mode de vie

Goal: comprendre la charge de fond non-sportive qui pèse sur la récupération et la fatigue.

- **Type de métier** : physique (bâtiment, artisan, soignant, commerce debout…) ou sédentaire (bureau, informatique, télétravail…) ?
- **Posture dominante** : assis toute la journée ? Debout ? Mixte ?
- **Charge mentale** : boulot stressant / réunions intensives ? Ça compte dans la récupération globale.
- **Horaires** : fixes ou variables ? Décalés (nuit, tôt le matin) ?
- **Trajet** : marche, vélo, transports ? Durée ?

**Impact sur la planification** :
- Métier physique → charge de fond élevée, récupération plus lente, volume running à modérer, renfo à calibrer pour ne pas doubler la fatigue musculaire
- Métier sédentaire → muscles posturaux souvent raccourcis (psoas, ischio-jambiers, fessiers), raideurs fréquentes, importance des exercices de mobilité et d'activation dans l'échauffement
- Stress mental élevé → HRV souvent déprimée même sans charge physique, body battery qui ne remonte pas — en tenir compte dans les signaux Garmin
- Trajet vélo/marche → compte dans la charge globale de la journée

Save: `job_lifestyle` — type (physique/sédentaire), posture, stress, horaires, trajet.

### Block 6 — Session Preferences

Goal: set defaults that feel right from day one. Present as suggestions, not obligations.

For each item, state the science-backed default and ask if they want to adjust:

1. **Échauffement** : défaut = protocole dynamique 7–10 min (pas d’étirements statiques avant l’effort — la science montre que ça réduit les performances). Plus court sur les séances faciles, plus long sur l’intensité. Ajuster ?

2. **Récupération post-séance** : distinguer les deux cas :
   - **Si cooldown = juste marche** — l’athlète peut gérer seul, pas besoin de l’intégrer dans le workout
   - **Si cooldown = footing léger Z2 quelques minutes avant de couper** — à intégrer dans le workout Garmin (plus utile physiologiquement). C’est le défaut recommandé.
   - Demander : "Tu préfères que j’intègre le cooldown footing dans le workout, ou tu gères ça toi-même après ?"

3. **Repos entre séries (renfo)** : défaut = bouton lap (tu avances quand t’es prêt). Timer fixe ?

4. **Feedback post-séance** : prompt rapide après chaque séance ? (1 question : comment tu t’es senti ?)

5. **Séance de remplacement pour sports dépendants** (collectif, club) :
   - Toujours créer une alternative quand la séance principale peut ne pas avoir lieu ?
   - Si oui : quel type de séance par défaut ? (l’athlète donne sa préférence — ex. fractionné, footing, renfo)
   - Fréquence : systématique chaque semaine ou seulement sur demande ?

Save: `session_preferences`. (Ce bloc était Block 5, maintenant Block 6 — numérotation mise à jour.)

## Closing the Onboarding

- Résumer le profil complet, y compris l'état physique et les points de vigilance.
- Reformuler les blessures et antécédents pour que l'athlète confirme que c'est bien compris.
- Corriger tout ce qu'il signale.
- Confirmer sauvegardé. Proposer de lancer `garmin-weekly-plan` immédiatement si c'est souhaité.

## Ongoing Updates

- Toute nouvelle information en cours de conversation (blessure, équipement, changement de planning) → mettre à jour la mémoire immédiatement.
- Relire les entrées existantes avant d'écrire pour remplacer plutôt que dupliquer.
- Disponibilité reconfirmée à chaque nouveau cycle de planification — ne jamais supposer qu'elle est encore valide.
- État des blessures reconfirmé systématiquement avant toute planification (ne pas supposer que ça va mieux).
