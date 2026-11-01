# Strength Session Library

> **Filtre obligatoire avant toute sélection d'exercice.** Les templates de ce fichier sont des *candidats*, pas des séances prêtes à publier. La sélection finale est filtrée par :
> - `locations[].equipment` / `supports` — seul ce qui est listé pour le lieu de la séance est disponible ; rien n'est supposé présent par défaut,
> - `locations[].floor_ok` — si faux, aucun exercice au sol (planche, pont fessier, dead bug),
> - `locations[].space` — contraintes d'espace, de bruit, de surface,
> - `injuries[].restrictions` — mouvements interdits, retirés sans négociation,
> - `injuries[].pain_threshold` — à reporter dans la description du workout tant qu'une blessure est active.
>
> Aucune pathologie n'est supposée : en l'absence de blessure déclarée dans `injuries`, aucun exercice n'est écarté pour raison clinique.

## Règle : utiliser les exercices natifs Garmin

Avant de construire une séance, utiliser `list_supported_strength_exercises` du MCP pour :
- Vérifier qu'un exercice est disponible dans Garmin
- Obtenir la `category` et `exerciseName` exacts à utiliser dans le JSON
- Chercher par mot-clé : `list_supported_strength_exercises(query="glute")`

Ne jamais inventer un nom d'exercice. Si un exercice n'est pas dans le catalogue Garmin, utiliser la catégorie la plus proche et noter la différence dans la description du step.

## Équipement : lire depuis le profil

L'équipement disponible se lit dans `locations[].equipment` du profil athlète, **lieu par lieu** : une même séance à deux endroits différents n'a pas le même matériel, donc n'est pas la même séance. Ne proposer que des exercices réalisables avec ce qui est listé pour le lieu retenu. Si `locations` n'est pas connu, ou si le lieu de la séance n'est pas tranché → demander avant de construire, ne jamais supposer d'haltères, de barre, d'élastique, de banc ou de barre fixe.

Les templates « avec charge » ci-dessous ne sont éligibles que si `equipment` contient effectivement une charge ; sinon, basculer sur la version poids de corps.

---

## Groupes musculaires prioritaires par sport

### Running
Chaîne postérieure + stabilité hanche + core. Améliore l'économie de course de 2-8%.

| Priorité | Groupe | Pourquoi |
|---|---|---|
| 🔴 P1 | Fessiers / ischio | Propulsion, protection genou |
| 🔴 P1 | Stabilité hanche (abducteurs) | IT band, genou valgus |
| 🟡 P2 | Core | Maintien posture en fatigue |
| 🟡 P2 | Mollets / Achille | Prévention tendinite |
| 🟢 P3 | Quadriceps (unilatéral) | Équilibre chaine ant/post |
| 🟢 P3 | Plyométrie | Puissance stride |

### Cyclisme
Puissance jambes, core anti-rotation, stabilité genou.

| Priorité | Groupe | Pourquoi |
|---|---|---|
| 🔴 P1 | Quadriceps / fessiers | Production de puissance |
| 🔴 P1 | Core | Transfert puissance bras/jambes |
| 🟡 P2 | Ischio | Équilibre, protection genou |
| 🟢 P3 | Haut du corps | Position aérodynamique, endurance |

### Sports collectifs (basket, foot, rugby…)
Explosivité, changements de direction, endurance musculaire.

| Priorité | Groupe | Pourquoi |
|---|---|---|
| 🔴 P1 | Fessiers + quadriceps | Sauts, accélérations |
| 🔴 P1 | Plyométrie | Explosivité, changements direction |
| 🟡 P2 | Core | Stabilité duels, réception |
| 🟡 P2 | Cheville / mollets | Réception de saut, entorse prévention |

### Escalade
Traction, gainage, doigts, épaules, opposition jambes.

| Priorité | Groupe | Pourquoi |
|---|---|---|
| 🔴 P1 | Dorsaux / trapèzes | Traction |
| 🔴 P1 | Core + lombaires | Gainage paroi |
| 🟡 P2 | Épaules / coiffe | Stabilité, prévention |
| 🟢 P3 | Antagonistes (pectoraux) | Équilibre musculaire |

---

## Templates de séances types

### Renfo Running — Poids de corps (20-25 min)

| Exercice | Séries × Rép | Chercher dans MCP |
|---|---|---|
| Pont fessier unijambiste | 3 × 12/jambe | "single leg hip raise" |
| Fente arrière | 3 × 10/jambe | "reverse lunge" |
| Clam Shell | 3 × 15/côté | "clam" |
| Planche latérale | 3 × 30-40s | "side plank" |
| Dead Bug | 3 × 8/côté | "dead bug" |
| Mollet unijambiste | 3 × 12/jambe | "single leg calf raise" |

### Renfo Running — Avec charge (40-50 min)

| Exercice | Séries × Rép | Chercher dans MCP |
|---|---|---|
| Bulgarian Split Squat | 3 × 8/jambe | "split squat" |
| RDL unijambiste | 3 × 8/jambe | "single leg deadlift" |
| Hip Thrust | 4 × 8-10 | "hip thrust" |
| Nordic Hamstring Curl | 3 × 5 | "nordic" |
| Mollet excentrique | 3 × 10/jambe | "calf raise" |
| Planche | 3 × 45s | "plank" |

### Renfo Corrective (selon blessure active)

Exercices à choisir selon la zone blessée, telle que déclarée dans `injuries` (`area`, `side`, `restrictions`) — demander/reconfirmer le statut avant de construire, le champ `injuries` se revalide à chaque session de planification.
Toujours partir de l'exercice le moins contraignant et valider avec l'athlète. Reporter `pain_threshold` dans la description du workout comme règle d'arrêt.

---

## Règles de programmation

- **Placement** : renfo après la course (même jour), pas la veille d'une sortie longue ou VMA
- **Fréquence** : 1-2x/semaine suffit pour les sportifs dont ce n'est pas le sport principal
- **Progression** : débuter poids de corps → ajouter charge après 4-6 semaines de maîtrise
- **Plyométrie** : uniquement si aucune douleur articulaire active et si les impacts ne sont pas dans `injuries[].restrictions`
- **Ordre des séances** : respecter `session_preferences.order_constraints` s'il est posé — il prime sur la règle de placement ci-dessus
- **Séance renfo seul vs greffée** : si temps limité (<20 min), greffer en fin de course ; si créneau dédié, séance complète
