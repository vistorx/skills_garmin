# Strength Session Library

## Règle : utiliser les exercices natifs Garmin

Avant de construire une séance, utiliser `list_supported_strength_exercises` du MCP pour :
- Vérifier qu'un exercice est disponible dans Garmin
- Obtenir la `category` et `exerciseName` exacts à utiliser dans le JSON
- Chercher par mot-clé : `list_supported_strength_exercises(query="glute")`

Ne jamais inventer un nom d'exercice. Si un exercice n'est pas dans le catalogue Garmin, utiliser la catégorie la plus proche et noter la différence dans la description du step.

## Équipement : lire depuis le profil

L'équipement disponible est dans `training-profile` memory (`level_and_equipment`). Ne proposer que des exercices réalisables avec ce qui est disponible. Si l'équipement n'est pas connu → demander avant de construire.

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

Exercices à choisir selon la zone bléssée — demander le statut avant de construire.
Toujours partir de l'exercice le moins contraignant et valider avec l'athlète.

---

## Règles de programmation

- **Placement** : renfo après la course (même jour), pas la veille d'une sortie longue ou VMA
- **Fréquence** : 1-2x/semaine suffit pour les sportifs dont ce n'est pas le sport principal
- **Progression** : débuter poids de corps → ajouter charge après 4-6 semaines de maîtrise
- **Plyométrie** : uniquement si aucune douleur articulaire active
- **Séance renfo seul vs greffée** : si temps limité (<20 min), greffer en fin de course ; si créneau dédié, séance complète
