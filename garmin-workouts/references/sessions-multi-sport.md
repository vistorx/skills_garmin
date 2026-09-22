# Multi-Sport Session Library

## Principe : Garmin définit les zones, on structure l'entraînement

Pour chaque sport, récupérer depuis Garmin avant de planifier :
- `get_activity_types` → liste des sports Garmin disponibles
- `get_activities` (filtré par sport) → historique, durées, intensités réelles
- `get_heart_rates_summary` → zones FC de l'athlète (valables tous sports cardio)
- `get_training_status` → état global (cross-sport)

Si le sport n'est pas dans cette lib : appliquer le cadre générique en bas de fichier.

---

## Cyclisme

**Référence zones** : FTP depuis `get_cycling_ftp`. Zones puissance (Coggan) :

| Zone | %FTP | Usage |
|---|---|---|
| Z1 Récupération | <55% | Récup active |
| Z2 Endurance | 56-75% | Base aérobie, sortie longue |
| Z3 Tempo | 76-90% | Endurance musculaire |
| Z4 Seuil | 91-105% | FTP, amélioration seuil |
| Z5 VO2max | 106-120% | Puissance aérobie max |
| Z6 Anaérobie | 121-150% | Efforts courts explosifs |

**Types de séances** :
- *Sortie endurance* : Z2, 1h-3h, base aérobie
- *Sweet spot* : 88-94% FTP, 2-3 blocs de 15-30 min, workhorse du cycliste time-crunché
- *Seuil (FTP intervals)* : 2 × 20 min @ Z4, récup 5 min
- *VO2max* : 5 × 3-4 min @ Z5, récup égale
- *Sprint / neuromusculaire* : 5-8 × 10-15s max, récup complète (4-5 min)

**Garmin** : `sportTypeKey: "cycling"` ou `"indoor_cycling"`. Cibler zones puissance si capteur disponible, sinon zones FC.

---

## Natation

**Référence** : pas de zones Garmin standard en natation par allure. Utiliser FC ou temps au 100m.
Lire depuis `get_activities` les temps/distances des sessions passées pour calibrer.

**Types de séances** :
- *Technique* : série courte (50-100m), récup longue, focus amplitude. 30% du volume hebdo pour nageurs en développement
- *Endurance* : 1000-3000m continu ou grands intervalles (200-400m), faible intensité
- *Intervalles courts* : 10 × 50m ou 8 × 100m, récup 15-30s, intensité élevée
- *Intervalles longs* : 4 × 200m ou 3 × 400m, récup 60s
- *Récupération* : nage lente style libre, 400-800m

**Distribution optimale** (source : nataswim 2024) : 65-70% en zones aérobies basses, 15-20% haute intensité, 15% technique.

**Garmin** : `sportTypeKey: "lap_swimming"` ou `"open_water_swimming"`. Pas de steps structurés en natation dans les workouts Garmin — créer comme cardio avec durée ou distance cible.

---

## Sports collectifs (basket, foot, rugby, handball…)

**Nature** : sports d'effort intermittent, impossible à structurer finement dans Garmin. Traiter comme activité fixe à caler dans le planning.

**Ce qu'on suit depuis Garmin** :
- Durée + FC moyenne/max depuis `get_activities` → estimer la charge
- Comparer les sessions semaine à semaine

**Session backup (si match/entraîne annulé)** : proposer session de remplacement de même durée, calibrée selon niveau. Types utiles :
- Cardio-training : fractionné court ou run-and-gun (course + changements direction)
- Circuit conditioning : enchainnement exercices explosifs (squats saut, shuttle run, gainage)
- Running aérobie si l'athlète court aussi

**Garmin** : `sportTypeKey: "basketball"`, `"soccer"`, etc. selon sport.

---

## Escalade

**Nature** : sport technique, charge difficile à quantifier. La FC monte très fort sur passages intenses, reste basse en réflexion.

**Ce qu'on suit** : durée totale, FC moyenne, calories depuis `get_activities`.

**Renfo complémentaire recommandé** : voir `sessions-strength.md` section Escalade.

**Garmin** : `sportTypeKey: "bouldering"` ou `"rock_climbing"`.

---

## Sports d'hiver (ski, snowboard)

**Nature** : saisonnier, intermittent, charges variables selon terrain.
**Suivi** : durée, dénivelé, FC depuis `get_activities`.
**Préparation physique** : renfo jambes (squat, fente), gainage, propriéception (planche unijambiste).
**Garmin** : `sportTypeKey: "skiing"` ou `"snowboarding"`.

---

## Cadre générique — Sport non listé

Si l'athlète pratique un sport absent de cette lib :

1. Demander : "Comment se déroule une session typique de [sport] pour toi ? (durée, intensité, format)"
2. Identifier si le sport est : continu (endurance), intermittent (cardio-training), technique, ou explosif
3. Appliquer la logique de distribution correspondante :
   - Continu : 80% faible intensité, 20% haute intensité
   - Intermittent : planifier charge globale, prévoir récup adéquate
   - Technique : volume modéré, pas de charge avant maîtrise
   - Explosif : récup complète entre efforts, fréquence basse
4. Sauvegarder la description du sport dans `training-profile` memory pour les prochaines sessions
5. Trouver le `sportTypeKey` Garmin correspondant via `get_activity_types`
