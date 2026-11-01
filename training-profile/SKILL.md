---
name: training-profile
description: Read/maintain the athlete profile that feeds every skill.
version: 1.1.0
author: hermes-garmin-skills contributors
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [garmin, training, fitness, profile, planning]
    related_skills: [garmin-onboarding, garmin-plan, garmin-workouts]
---

# Training Profile

Source de vérité unique du pack. Ce skill définit **comment le profil de l'athlète est lu,
maintenu et mis à jour** entre les sessions. Il s'applique à n'importe quel sport,
n'importe quelle routine, n'importe quel athlète : le profil appartient à la personne,
il décrit son monde et non un modèle.

Aucun autre skill ne contient de donnée personnelle. Tous lisent ici.

## Quand charger ce skill

- Avant toute planification, tout ajustement, toute discussion de séance.
- Avant de répondre sur le niveau, le matériel, l'état d'une blessure, l'historique.
- Dès qu'une information nouvelle apparaît en conversation (matériel, préférence,
  douleur, retour de séance) → **l'enregistrer tout de suite**, sans attendre une
  mise à jour dédiée.

Ne pas utiliser pour : construire des fichiers de workout → `garmin-workouts`.
Planifier → `garmin-plan`. Premier contact / profil vide → `garmin-onboarding`.

---

## Le schéma du profil

Le contrat de données complet — champs, valeurs admises, fenêtres de validité,
frontière mémoire/skills — est dans **`references/profile-schema.md`**.
Le lire avant d'écrire quoi que ce soit dans le profil.

Vue d'ensemble des blocs :

```
identity          — qui il est, mesures, ID Garmin, unités, langue
device            — montre et capacités : ce que l'appareil sait afficher, pas ce que l'API accepte
sports            — sports pratiqués, niveau, fixe/flexible, dépendance, saisonnalité
locations         — lieux d'entraînement : matériel, sol praticable, appuis, espace
availability      — créneaux par jour + durée plafond (échauffement et cooldown inclus)
objectives        — course visée / performance / général / maintien / rééducation
injuries          — blessures actives : restrictions, seuil de douleur, variable à borner
injury_history    — antécédents, zones fragiles, déclencheurs
job_lifestyle     — métier, posture, stress, horaires, trajet
session_preferences — échauffement, cooldown, repos, nommage, style de réponse
planning_mode     — complet | ponctuel | null
```

## Où vivent les données

Dans la mémoire persistante Hermes : `context_notes(target='user')`.

- **Lire** : ce qui est en mémoire au démarrage de session.
- **Écrire** : `context_notes(target='user')` — toujours relire les entrées existantes
  pour **remplacer** plutôt que dupliquer. Entrées courtes et factuelles.

Ne jamais coder une donnée personnelle en dur dans un fichier de skill : elle ne
restera pas synchronisée, et elle casse le partage du pack avec d'autres athlètes.

---

## Deux modes d'usage

Les détecter dès la première demande et adapter le flow. Le routage est fait par
`garmin-plan`, ce skill ne fait que définir la distinction.

**Planification complète** — structurer une semaine ou un cycle.
> *« Planifie ma semaine »*, *« qu'est-ce que je fais cette semaine ? »*, *« on prépare le mois »*

**Ponctuel** — une séance, maintenant, sans contexte hebdomadaire.
> *« Je veux faire un run »*, *« j'ai 45 minutes ce soir »*, *« une séance de muscu ? »*

Règle de détection : un sport ou une durée sans mention de la semaine → ponctuel.
En cas de doute → ponctuel, plus léger et moins intrusif ; proposer le mode complet à la fin.

Champ `planning_mode` : optionnel. Beaucoup d'athlètes alternent selon le jour — ne pas figer.

---

## Combler les trous : récupérer d'abord, demander ensuite

1. **Toujours interroger Garmin avant de poser une question** : `get_user_profile`,
   `get_activities`, `get_personal_record`, `get_race_predictions`,
   `get_training_readiness`. Ne jamais demander une donnée que le compte contient déjà.
2. Ne demander que ce que Garmin ne peut pas révéler : préférence subjective, douleur
   actuelle, matériel précis, lieu, motivation, cotations des sports techniques.
3. Une ou deux questions précises à la fois — jamais un questionnaire.

## Disponibilité : la cadrer correctement

La disponibilité est du **temps mobilisable**, pas un planning à remplir. Le dire
explicitement à l'athlète.

- La durée plafond annoncée inclut déjà échauffement et retour au calme —
  ne jamais rajouter de temps par-dessus.
- Reconfirmer au début de chaque cycle de planification : les emplois du temps bougent.
- Un créneau laissé vide est un résultat valide.

## Lieu de séance : question bloquante

Pour toute séance non-running, le lieu détermine le matériel disponible **et** la posture
possible. Deux séances du même objectif à deux endroits différents sont deux séances
différentes. Une séance planifiée sans savoir où elle se déroule est une séance
potentiellement infaisable.

- Lire `locations` et le `location_id` par défaut du créneau dans `availability`.
- **Confirmer, jamais déduire** : un jour de télétravail, un déplacement ou une salle
  fermée change tout ce qui est possible.
- Si `floor_ok` est faux pour ce lieu, aucun exercice au sol n'est programmable.
- Si `equipment` ne contient aucune charge, aucun exercice qui n'a de sens que chargé.

---

## Contrôles de sécurité avant planification

Avant de finaliser une séance :

1. **Drapeau mauvaise séance** : si la dernière séance de ce sport portait un signal
   négatif (douleur, abandon, RPE très élevé, anomalie de FC) et que l'athlète ne l'a pas
   expliqué dans cette session → demander avant de proposer quoi que ce soit.
2. **Drapeau blessure** : si une blessure est active et concerne la séance prévue →
   confirmer l'état du jour. Ne jamais supposer que le dernier état connu tient encore.
3. **Jamais de progression juste après une séance signalée mauvaise** sans l'avoir traitée.

### Compléter le profil à chaque planification — règle absolue

Au début de chaque session de planification, même profil complet, vérifier activement :

- les disponibilités réelles de la semaine (pas le pattern habituel) ;
- le lieu de chaque créneau non-running ;
- l'état physique du jour (ressenti, courbatures, gêne) ;
- le statut des blessures actives — ne jamais supposer que ça va mieux ;
- la dernière séance si elle a moins de 48 h ;
- les événements de vie : stress, sommeil dégradé, voyage, charge de travail.

Un profil en mémoire est une base. La conversation du jour est la réalité.
Ce que l'athlète dit maintenant prime toujours sur ce qui est enregistré.

---

## Équipement

Stocké par lieu dans `locations[].equipment`. Ce qui compte :

- **Quoi** : ce dont l'athlète dispose à cet endroit (tapis, haltères et leur charge,
  élastiques, banc, corde, barre fixe, accès salle…).
- **Pour quoi faire** : l'information sert la construction des séances — un tapis rend
  les exercices au sol possibles, une absence de charge disqualifie les mouvements
  qui n'ont de sens que chargés.
- **Pas besoin de tracer l'usage** : on ne note pas qu'il a utilisé son tapis mardi,
  seulement qu'il en a un.

Mise à jour : tout nouvel équipement mentionné en conversation va immédiatement dans
`locations[].equipment`.

---

## Retours de séance → vers Garmin

Chaque fois que l'athlète donne un retour sur une séance terminée, l'écrire tout de suite
dans la description de l'activité Garmin correspondante via `set_activity_description`.

**Workflow**

1. Identifier l'activité avec `get_activities` (sport + date + heure).
2. **Si aucune activité ne correspond → le dire immédiatement** : l'enregistrement a
   peut-être été oublié sur la montre. Ne pas deviner, ne pas rattacher le retour à une
   activité approximative.
3. Écrire la description avec `set_activity_description`.
4. Grouper les appels si plusieurs séances sont à annoter.

**Quoi noter**

- Ressenti général : feeling, fatigue, motivation.
- Douleurs ou gênes : localisation, intensité, durée, évolution pendant et après.
- Équipement utilisé (orthèse, chaussures…) et effet observé.
- Conditions particulières : chaleur, terrain, stress.
- **Séance infaisable ou adaptée sur le moment** : noter pourquoi — matériel manquant,
  lieu inadapté, douleur. C'est le signal le plus utile pour corriger la planification
  suivante.

**Pourquoi** : ça historise les sensations là où les données objectives sont déjà
stockées. Exploitable par un praticien, utile pour suivre l'évolution d'une blessure
et repérer les patterns dans la durée. C'est aussi la seule source des retours que
`medical-report` relit ensuite.

---

## Planning temporel : calculer, ne pas demander

L'emploi du temps est dans le profil (`availability`, `sports`). **Ne jamais demander**
ce qui est prévu — le calculer.

Avant toute mention d'une prochaine séance :

1. `date.today()` et `today.weekday()` en Python.
2. Croiser avec `availability` pour identifier le prochain créneau utilisable.
3. Énoncer le jour calculé directement — jamais d'approximation ni d'hypothèse.

Un événement ponctuel qui modifie la semaine sera signalé par l'athlète. Sans
information contraire, le profil fait foi.

---

## Cas limites

- Statut d'entraînement Garmin indisponible → utiliser readiness + tendance de charge
  aiguë, et énoncer explicitement la limite.
- Données de readiness périmées (>24 h) → le signaler, utiliser la dernière valeur
  disponible plus les activités récentes.
- Athlète nouveau, sans historique → sauter les sections de tendance, prendre VO2max et
  niveau déclaré comme référence, et le dire.
- Profil vide ou largement obsolète → passer la main à `garmin-onboarding`.
