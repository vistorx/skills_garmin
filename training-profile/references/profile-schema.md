# Athlete Profile — Schéma canonique

Contrat de données unique du pack. **Tous** les skills lisent ici et nulle part ailleurs ;
aucun skill ne contient de donnée personnelle en dur.

Stockage : mémoire persistante Hermes, `context_notes(target='user')`.
Une entrée mémoire par bloc de premier niveau, préfixée par le nom du champ.

---

## Règle de lecture

1. Le profil en mémoire est une **base**, pas une vérité du jour.
2. Ce que l'athlète dit maintenant prime toujours sur ce qui est enregistré.
3. Un champ absent se demande ou se déduit de Garmin — jamais il ne s'invente.
4. Un champ marqué `last_confirmed` plus vieux que sa fenêtre de validité
   (voir table ci-dessous) doit être reconfirmé avant usage.

| Champ | Fenêtre de validité |
|---|---|
| `injuries` | chaque session de planification |
| `availability` | chaque cycle de planification |
| `objectives` | 4 semaines |
| `sports`, `locations`, `equipment` | 3 mois |
| `identity`, `job_lifestyle` | 6 mois |
| `session_preferences` | stable, sur demande |

---

## Champs

### `identity`
Qui est l'athlète. Les mesures corporelles viennent de Garmin (`get_user_profile`) —
ne les redemander que si Garmin est vide.

```
name, age, sex, height_cm, weight_kg, garmin_user_id, units (metric|imperial), language
```

### `sports`
Liste. Un sport pratiqué = une entrée.

```
sport            — nom libre (running, escalade, basket…)
level            — debutant | intermediaire | confirme | competitif
schedule         — fixed | flexible
typical_days     — jours habituels si fixed
dependency       — true si la séance dépend d'autres personnes (club, équipe, partenaire)
seasonal         — true si saisonnier/occasionnel
notes            — cotations, catégorie, spécificités non remontées par Garmin
```

Pour la course, `level` se déduit de Garmin (VO2max, seuil, PR, prédictions) — ne pas demander.
Pour tout le reste, c'est déclaratif.

### `locations`
**Bloquant pour toute séance non-running.** Le lieu détermine le matériel ET la posture
possible. Deux séances du même objectif à deux endroits différents sont deux séances
différentes.

```
id            — identifiant court (maison, travail, salle, exterieur…)
label         — libellé lisible
equipment     — liste explicite de ce qui est disponible ICI
floor_ok      — true si on peut s'allonger/s'asseoir au sol
space         — contraintes d'espace, de bruit, de surface
supports      — appuis utilisables (mur, poteau, banc, marche, barre fixe…)
```

Règle : si `floor_ok` est faux, aucun exercice au sol (planche, pont fessier, dead bug)
ne peut être programmé pour ce lieu. Si `equipment` ne contient pas de charge, aucun
exercice qui n'a de sens que chargé.

### `availability`
Par jour de semaine. La durée annoncée **inclut échauffement et retour au calme** —
ne jamais rajouter de temps par-dessus.

```
weekday          — lundi…dimanche
slot             — matin | midi | soir | libre
max_duration_min — plafond réel, échauffement et cooldown compris
location_id      — lieu par défaut pour ce créneau (à confirmer, jamais déduit)
hard_block       — true si le créneau est indisponible (obligation fixe, soin, repos imposé)
```

Un créneau vide est un résultat valide. La disponibilité est du temps *mobilisable*,
pas un planning à remplir.

### `objectives`
```
type        — race | performance | general | maintien | rehab
target      — objectif chiffré ou description libre
date        — échéance si applicable
priority    — primary | secondary
```

### `injuries`
Liste des blessures **actives**. Le champ le plus consulté du profil.

```
area              — localisation précise (pas « la jambe »)
side              — gauche | droite | bilateral
diagnosis         — diagnostic posé, ou null si non vu par un praticien
severity_10       — à l'effort / au repos
since             — date ou ancienneté
treatment         — suivi en cours + fréquence
aggravating       — ce qui déclenche (impact, flexion, charge, descente…)
relieving         — ce qui soulage
restrictions      — mouvements interdits, formulés comme des interdits exploitables
pain_threshold    — règle d'arrêt à porter dans la description des séances
volume_limiter    — variable clinique à borner (ex. distance, nb d'impacts, charge)
last_confirmed    — date de dernière confirmation
```

Deux champs pilotent la construction des séances :
- `restrictions` filtre le choix des exercices,
- `pain_threshold` **doit** apparaître dans la description de tout workout publié
  tant qu'une blessure est active.

### `injury_history`
Antécédents. Ne jamais supposer l'absence d'historique parce qu'il n'en a pas parlé.

```
area, side, year, healed (true|fragile), trigger
```

### `job_lifestyle`
Charge de fond non sportive qui pèse sur la récupération.

```
job_type   — physique | sedentaire | mixte
posture    — assis | debout | mixte
stress     — faible | moyen | eleve
hours      — fixes | variables | decales
commute    — mode + durée
```

Implications de planification : métier physique → charge de fond haute, volume à modérer.
Sédentaire → raideurs posturales, mobilité et activation à l'échauffement.
Stress élevé → HRV déprimée sans charge physique, lire les signaux Garmin en conséquence.

### `session_preferences`
Défauts de construction. Chaque valeur est un défaut proposé à l'onboarding, pas une
obligation — mais une fois posée, elle s'applique sans redemander.

```
warmup_standard      — protocole d'échauffement par défaut (durée + contenu)
warmup_per_type      — surcharges par type de séance si l'athlète en veut
cooldown_in_workout  — true si le cooldown est intégré au workout Garmin
rest_mode            — lap_button | timer  (repos entre séries en renfo)
feedback_prompt      — true si on demande un retour après chaque séance
backup_session       — politique de séance de remplacement pour les sports dépendants
naming_prefix        — préfixe des workouts créés par l'agent (défaut "AI - ")
response_style       — concis | detaille
order_constraints    — contraintes d'ordre imposées (ex. course avant renfo)
```

### `planning_mode`
`complet` | `ponctuel` | `null`. Optionnel — beaucoup d'athlètes alternent selon le jour,
ne pas figer.

---

## Frontière mémoire / skills

| Mémoire (profil athlète) | Skills |
|---|---|
| Qui il est, ses mesures, son ID Garmin | Comment planifier |
| Matériel possédé, lieux d'entraînement | Règles de sélection d'exercices |
| Disponibilités, sports fixes | Ordre des séances, protocoles, gates de validation |
| Niveaux, PR, zones | Quoi faire face à une blessure |
| Blessures actives et leur état | Conventions de nommage, mécanique MCP |
| Objectif du cycle | Logique de variation de charge |

La mémoire décrit **l'athlète**. Les skills décrivent **le travail du coach**.
Une règle de comportement qui atterrit en mémoire doit migrer vers le skill concerné :
la mémoire est injectée à chaque tour et son budget est serré.
