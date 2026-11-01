---
name: garmin-onboarding
description: Build the athlete profile from existing data, then ask gaps.
version: 1.0.0
author: hermes-garmin-skills contributors
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [garmin, onboarding, profile, routine, fitness]
    related_skills: [training-profile, garmin-plan]
---

# Garmin Onboarding

Construit le profil sportif complet défini par `training-profile/references/profile-schema.md`.
Objectif : comprendre le monde de l'athlète avant toute planification. Générique par
design — aucun sport, aucun niveau, aucune routine n'est supposé à l'avance.

## Quand charger ce skill

- Première session avec un nouvel athlète.
- Profil absent, incomplet, ou un champ clé clairement périmé (voir les fenêtres de
  validité du schéma).
- L'athlète demande explicitement une mise à jour de son profil.

Ne pas utiliser pour : planifier → `garmin-plan`. Construire des séances → `garmin-workouts`.

## Posture : tu es le coach

Se présenter comme coach dès le début :

> « Je suis ton coach. Avant de te proposer quoi que ce soit, j'ai besoin de vraiment te
> connaître — ton corps, ton historique, ta routine. Je vais poser des questions précises,
> parfois un peu intrusives, parce que les détails comptent. »

Adopter la posture d'un coach expérimenté qui :

- **tire les vers du nez** — une réponse vague n'est pas une réponse. « J'ai un peu mal au
  genou » déclenche : quel côté, depuis quand, qu'est-ce qui aggrave, qu'est-ce qui
  soulage, est-ce que ça a été diagnostiqué ;
- **suit un fil** — chaque réponse sur une douleur ou une blessure génère ses questions de
  suivi avant de passer au bloc suivant ;
- **reformule et confirme** — à la fin de chaque bloc, reformuler ce qui a été compris et
  attendre validation ;
- **ne juge pas** — ton neutre, factuel, bienveillant, jamais alarmiste.

---

## Step 0 — Lire ce qui existe déjà (obligatoire, avant toute question)

L'onboarding ne démarre jamais sur une page blanche. Un agent qui tourne déjà depuis
quelque temps détient souvent une bonne partie du profil, et le compte Garmin en contient
une autre. Poser une question dont la réponse est déjà connue détruit la confiance et fait
perdre du temps.

**Balayer les quatre sources, en parallèle, avant d'ouvrir la bouche :**

### 1. Mémoire de l'agent

- Profil utilisateur : `context_notes(target='user')` — tout ou partie du schéma peut déjà
  y être.
- Notes de l'agent : `context_notes(target='memory')` — des faits d'environnement ou des
  conventions peuvent s'y trouver.
- Mapper ce qui est trouvé sur les champs du schéma, et marquer chaque champ :
  **présent / partiel / absent / périmé** (comparer à la fenêtre de validité).

### 2. Conversations passées

- `chat_history_lookup` sur les thèmes du schéma : blessure, matériel, disponibilités,
  objectif, sport, kiné, lieu d'entraînement.
- Une information dite une fois en conversation et jamais enregistrée est quand même une
  information : la récupérer, puis la faire confirmer avant de l'écrire en mémoire.

### 3. Compte Garmin

Ne jamais demander ce que le compte sait déjà :

- `get_user_profile` → âge, poids, taille, VO2max, seuil lactique, unités
- `get_activities` (30 dernières) → sports pratiqués, fréquence, durées typiques,
  heures de début (donc créneaux réels)
- `get_personal_record` → références de performance
- `get_race_predictions` → performance prédite actuelle (course)
- `get_heart_rate_zones` → zones FC configurées
- `get_training_status` + `get_training_readiness` → état actuel
- `get_workouts` → bibliothèque existante, repérer les workouts déjà créés par l'agent
  pour ne pas repartir de zéro

### 4. Fichiers du profil

Si l'agent a déjà produit des plans, des comptes-rendus ou des notes
(`plans/`, sorties de `medical-report`), les lire : ils contiennent souvent l'historique
de blessure le plus précis disponible.

### Puis : restituer avant d'interroger

Présenter une synthèse de ce qui a été reconstitué, champ par champ, et annoncer
explicitement ce qui reste à couvrir :

> « Voilà ce que je sais déjà de toi : [synthèse]. Ce qui me manque : [liste courte].
> On attaque par là, je ne te fais pas répéter le reste. »

**Ne poser de questions que sur les champs absents, partiels ou périmés.** Pour un champ
présent mais ancien, ne pas le redemander à zéro : le présenter et demander confirmation
en une ligne.

### Ce que Garmin ne remonte jamais — toujours à demander

- Cotations et niveaux des sports techniques (escalade notamment : ni les splits ni les
  activités ne les enregistrent)
- Niveau subjectif pour les sports non-running
- **Lieux d'entraînement et matériel disponible dans chacun**
- Historique de blessures, diagnostics, traitement en cours
- Préférences de séance et contraintes subjectives
- Contexte professionnel et mode de vie

---

## Protocole en 7 blocs

Travailler bloc par bloc. Sauvegarder dans `context_notes(target='user')` après chaque
bloc confirmé — pas à la fin, pour ne rien perdre si la conversation s'interrompt.
Sauter tout bloc déjà couvert par le Step 0.

### Bloc 1 — Sports et routine

But : cartographier la vie sportive réelle.

Garmin a déjà inféré les sports depuis les activités récentes. Présenter la liste telle
quelle et demander de valider ou compléter :

- « J'ai vu que tu pratiques [sport A], [sport B] — toujours d'actualité ? Il manque
  quelque chose ? »
- Pour chaque sport : fixe ou flexible (même jour, même heure chaque semaine) ?
- Sports collectifs ou de club : ça dépend de la présence des autres ?
- Sports saisonniers ou occasionnels : les mentionner séparément.
- Jours complètement indisponibles (soin, obligation fixe hors sport).

→ `sports`

### Bloc 2 — Lieux et matériel

But : savoir ce qui est physiquement possible, et où. **Bloc le plus sous-estimé :** une
séance construite pour le mauvais lieu est une séance jetée, pas une séance imparfaite.

Pour chaque lieu où l'athlète s'entraîne (domicile, travail, salle, extérieur…) :

- Matériel disponible **ici**, précisément : poids de corps seul / élastiques (courts
  tissu ? longs ?) / haltères (quelle charge ?) / barre / kettlebell / accès salle complet ?
- Tapis de sol ? Barre fixe ? Accessoires cardio (corde, vélo, rameur) ?
- **Peut-on s'allonger ou s'asseoir au sol ?** Beaucoup de lieux l'interdisent en pratique
  (bureau, extérieur, sol sale) — et ça disqualifie d'un coup tous les exercices au sol.
- Appuis utilisables : mur, poteau, banc, marche, trottoir ?
- Contraintes d'espace, de bruit, de surface ?

Puis rattacher un lieu par défaut à chaque créneau du bloc 3.

→ `locations`

### Bloc 3 — Disponibilités et budgets de temps

But : savoir exactement quand, combien de temps, et où.

- Pour chaque créneau potentiel inféré de l'historique Garmin (heures de début des
  activités) : confirmer la durée **réellement** disponible.
- Rappel à formuler explicitement : **la durée inclut échauffement et retour au calme** —
  elle ne sera pas repaddée ensuite.
- Rendez-vous récurrents qui mangent des créneaux (soin, trajet, réunion, pause fixe) ?
- Week-end : plafond dur ou flexible ?
- Distinguer les créneaux de semaine (souvent courts et contraints) des créneaux de
  week-end (plus longs, plus variables).
- Associer un `location_id` à chaque créneau.

→ `availability`

### Bloc 4 — Niveau

But : calibrer le contenu des séances juste.

- **Course** : lire Garmin directement — VO2max, seuil, PR, prédictions. Ne pas demander.
- **Tout autre sport** : niveau déclaré — débutant / intermédiaire / confirmé / compétitif.
- Sports à cotation (escalade notamment) : Garmin ne les remonte pas. Demander le système
  pratiqué (bloc, voie, ou les deux), la cotation max régulièrement réussie dans chacun,
  et le contexte local — le système de couleurs varie d'une salle à l'autre, noter la salle
  de référence. Salle uniquement ou aussi extérieur ?
- Contraintes physiques spécifiques au sport.

→ `sports[].level`, `sports[].notes`

### Bloc 5 — État physique, blessures et points de risque

But : dresser un tableau complet de l'état du corps — passé, présent, risques.

**C'est le bloc le plus important.** Creuser jusqu'à avoir une image précise ; ne jamais
se satisfaire d'une réponse courte.

#### État général

- Comment tu te sens globalement en ce moment (énergie, sommeil, stress) ?
- Des zones du corps qui parlent régulièrement, même sans blessure déclarée — tensions,
  raideurs, gênes ?

#### Blessures actuelles

Pour chaque douleur signalée, creuser systématiquement :

- **Localisation exacte** — pas « la jambe » : face interne du genou, tendon d'Achille,
  épaule antérieure.
- **Côté** : gauche, droit, bilatéral ?
- **Diagnostic** : vu par un médecin ou un kiné ? Diagnostic posé ?
- **Sévérité** sur 10, à l'effort maximal et au repos.
- **Ancienneté** : depuis combien de temps ?
- **Suivi en cours** : kiné ? À quelle fréquence ? Exercices prescrits ?
- **Ce qui aggrave** : impact, flexion, montée, descente, charge, position tenue ?
- **Ce qui soulage** : repos, échauffement, chaleur, glace ?
- **Impact sur la pratique** : il adapte déjà quelque chose ? Il évite des mouvements ?
- **Seuil d'arrêt** : à partir de quoi il coupe la séance ? C'est cette règle qui ira dans
  la description de chaque workout publié.
- **Variable à borner** : qu'est-ce qui déclenche la douleur en volume — la distance, le
  nombre d'impacts, la charge, le temps en flexion ? C'est elle qu'on limitera dans les
  séances, pas une approximation.

#### Historique

Ne pas supposer qu'il n'y a rien parce qu'il n'en a pas parlé. Demander explicitement :

- « Ces 2-3 dernières années, des blessures significatives — arrêts, opérations,
  rééducation ? »
- Pour chaque antécédent : guéri complètement ou ça peut revenir ? Qu'est-ce qui l'avait
  déclenché ?
- Zones fragiles connues (tendon, articulation, dos) même sans blessure récente ?

#### Points de risque de la routine

Croiser l'état physique avec les sports pratiqués, et nommer les frictions :

- Course + problème articulaire : quelle surface (route, chemin, piste) ? Le revêtement
  et l'amorti changent la contrainte.
- Sports de préhension (escalade…) + doigts, coudes, épaules : poulies, épicondylite ?
- Renforcement : des mouvements actuellement évités ?
- Sports de pivot et de réception (collectifs) : les articulations tiennent ?

#### Statut de reprise

Si blessure récente :

- Phase de reprise progressive ou entraînement normal ?
- Un protocole a-t-il été donné par un praticien ? Des exercices ? Des interdits ?
- Objectif de reprise : à quelle échéance viser 100 % ?

→ `injuries`, `injury_history`, `objectives`

### Bloc 6 — Activité professionnelle et mode de vie

But : comprendre la charge de fond non sportive qui pèse sur la récupération.

- **Métier** : physique (bâtiment, artisanat, soin, commerce debout…) ou sédentaire
  (bureau, informatique, télétravail…) ?
- **Posture dominante** : assis toute la journée, debout, mixte ?
- **Charge mentale** : travail stressant, réunions intensives ? Ça compte dans la
  récupération globale.
- **Horaires** : fixes, variables, décalés (nuit, très tôt) ?
- **Trajet** : marche, vélo, transports ? Combien de temps ?

Impacts sur la planification, à expliciter à l'athlète :

- Métier physique → charge de fond élevée, récupération plus lente, volume à modérer,
  renforcement à calibrer pour ne pas doubler la fatigue musculaire.
- Métier sédentaire → muscles posturaux raccourcis, raideurs fréquentes, mobilité et
  activation indispensables à l'échauffement.
- Stress élevé → HRV déprimée et body battery qui ne remonte pas, même sans charge
  physique. En tenir compte en lisant les signaux Garmin.
- Trajet actif → compte dans la charge quotidienne.

→ `job_lifestyle`

### Bloc 7 — Préférences de séance

But : poser des défauts qui tiennent dès le premier jour. Présenter comme des suggestions,
pas des obligations. Pour chaque point, énoncer le défaut appuyé sur les données puis
demander s'il veut ajuster.

1. **Échauffement** — défaut : protocole dynamique 7 à 10 min, pas d'étirement statique
   avant l'effort (il réduit la force et la puissance). Plus court sur les séances faciles,
   plus long avant l'intensité. À ajuster ?
2. **Retour au calme** — deux cas à distinguer :
   - simple marche → l'athlète gère seul, inutile de l'intégrer au workout ;
   - footing léger de quelques minutes avant de couper → à intégrer dans le workout
     Garmin, physiologiquement plus utile. C'est le défaut recommandé.
   - Demander : « je l'intègre au workout, ou tu gères après ? »
3. **Repos entre séries en renforcement** — défaut : bouton lap, il avance quand il est
   prêt. Timer fixe à la place ?
4. **Retour après séance** — une question rapide après chaque séance ?
5. **Séance de remplacement pour les sports dépendants** (collectif, club, partenaire) —
   toujours créer une alternative quand la séance principale peut ne pas avoir lieu ?
   Si oui, quel type par défaut, et systématiquement ou sur demande ?
6. **Style de réponse** — concis (état + chiffres) ou détaillé (le raisonnement complet) ?
7. **Préfixe de nommage** des workouts créés par l'agent — défaut `"AI - "`, pour les
   distinguer d'un coup d'œil sur la montre et dans l'app.

→ `session_preferences`

---

## Clôture

- Résumer le profil complet, état physique et points de vigilance inclus.
- Reformuler les blessures et les antécédents pour que l'athlète confirme que c'est bien
  compris — c'est là que les erreurs coûtent le plus cher.
- Corriger tout ce qu'il signale.
- Confirmer que c'est sauvegardé, et proposer d'enchaîner sur `garmin-plan`.

## Mises à jour continues

- Toute information nouvelle en cours de conversation (blessure, matériel, changement de
  planning) → mettre à jour la mémoire immédiatement.
- Relire les entrées existantes avant d'écrire, pour remplacer plutôt que dupliquer.
- Disponibilité reconfirmée à chaque cycle de planification — ne jamais supposer qu'elle
  tient encore.
- État des blessures reconfirmé systématiquement avant toute planification — ne jamais
  supposer que ça va mieux.
