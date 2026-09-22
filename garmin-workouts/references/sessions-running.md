# Running Session Library

## Règle fondamentale : Garmin est la référence des zones

Ne jamais calculer ou inventer des zones. Tout est dans Garmin :
- `get_user_profile` → `lactateThresholdSpeed` (m/s) + `lactateThresholdHeartRate` = seuil réel
- `get_race_predictions` → allures cibles par distance (5K, 10K, semi, marathon)
- `get_heart_rates_summary` → zones FC de l'athlète
- `get_cycling_ftp` → si cycliste, FTP réelle
- `get_training_status` → statut actuel (Productive, Recovery, etc.)

Dans les workouts Garmin, cibler les zones par leur numéro (`zoneNumber: 2`, `zoneNumber: 3`…) — Garmin les traduit en FC/allure réelles selon le profil de l'athlète.

**Règle 80/20** : ~80% du volume en zones faciles (Z1-Z2), ~20% en zones intenses. C'est la distribution validée scientifiquement pour les coureurs de tous niveaux.

**Règle progression** : ne jamais augmenter le volume total de plus de 10% par semaine.

---

## Règle de variation inter-séances

**Pourquoi** : travailler toujours au même tempo use les mêmes structures (muscles, ligaments, articulations) au même point — c’est une source d’usure et de blessures de surcharge. Varier couvre une plage complète d’adaptations et réduit ce risque. C’est vrai pour les séances intenses comme pour les sorties EF : le bas d’une zone et le haut de cette zone ne sont pas la même foulée, pas les mêmes structures sollicitées.

**Charge totale = durée × intensité.** D’une séance à l’autre du même type, varier au moins un des deux. Jamais les deux en même temps sauf récup.

**Patterns** :
- Même durée + intensité légèrement plus haute
- Même intensité + durée plus longue
- Durée plus courte + intensité plus haute (charge équivalente, stimulus différent)
- Durée plus longue + intensité plus basse (focus volume)
- EF : alterner bas de Z2 et haut de Z2 — même zone, foulée et vitesse différentes
- Récup : -20% charge

Calibrer toujours depuis Garmin (`get_race_predictions`, zones FC profil). La variation est un delta par rapport à la séance précédente.

---

### 1. Endurance Fondamentale (EF)
**Objectif** : Base aérobie, récupération, volume sans fatigue  
**Garmin** : HR zone 2 pour le bloc principal  
**Durée** : 30 min → 1h30+ (bloc principal hors échauffement/retour)  
**Fréquence** : constitue la majorité du volume hebdomadaire  
**Signe de bonne intensité** : conversation complète possible  

**Structure obligatoire** (les 3 zones doivent être différentes — c'est la règle) :
1. **Échauffement** → Z1, 5 min, footing très léger — montée progressive
2. **Bloc principal** → Z2, durée cible de la séance
3. **Retour au calme** → Z1, 5 min, footing très léger — redescente

⚠️ Ne jamais mettre échauffement et récupération en Z2 si le bloc principal est déjà Z2 — les changements d'effort doivent être cohérents (Z1 → Z2 → Z1).

**Thème / conseil de tempo dans la description du step** :
Uniquement pour les séances à cible **zone FC** (EF, sortie longue) — la zone est large, le thème aide à se positionner dedans. Pour les séances à cible **allure (m/s)** (fractionné, tempo), la valeur de vitesse est déjà l'instruction — pas de commentaire redondant.

Exemples de thèmes :
- "Bas de Z2 — allure confort, conversation fluide, ~6:30-7:00/km"
- "Milieu de Z2 — effort régulier, quelques mots possibles, ~6:00-6:30/km"
- "Haut de Z2 — juste sous le seuil de confort, ~5:30-6:00/km"
- "Z2 progressif — commence bas, monte doucement vers le milieu de zone"
- "Z2 décroissant — commence milieu, relâche sur les 10 dernières minutes"

Les allures sont indicatives — toujours les calibrer depuis `get_race_predictions`. La zone FC fait foi, l'allure est un guide.

**Feedback post-séance** : quand Victor donne un retour, comparer le thème suggéré avec l'allure/FC moyenne réelle (depuis `get_activity`). Signaler positivement si le conseil a été suivi — pas un reproche si non, juste une observation utile.

**Variantes** :
- *Sortie longue* : 60-120 min, même structure, bloc Z2 allongé
- *Récupération active* : 20-30 min Z2 léger, lendemain d'une séance intense — échauffement/retour en Z1 identiques

---

### 2. Fractionné Court (≤1 min d'effort)
**Objectif** : Développement VMA, puissance aérobie  
**Garmin** : **pace zone uniquement** — la FC ne se stabilise pas sur <1 min, une cible HR est inutile  
**Calibration pace** : depuis `get_race_predictions` — effort légèrement plus rapide que pace 5K actuelle  
**Formats** :
- 30s effort / 30s récup × 10-15 (défaut, accessible)
- 20s effort / 40s récup × 12-18 (débutant)
- 45s effort / 45s récup × 8-12 (confirmé)

**Volume effort total** : 3-6 km  
**Warm-up requis** : 10-12 min (voir `warmup-protocols.md`)  
**Si douleur articulaire** : préférer fractionné en côtes (même format, terrain montant)

---

### 3. Fractionné Long (≥2 min d'effort)
**Objectif** : VO2max, puissance aérobie soutenue  
**Garmin** : HR zone 4-5 (durée suffisante pour stabilisation FC)  
**Formats** :
- 5 × 3 min Z5 / 3 min Z2
- 6 × 2 min Z5, récup 2 min
- 8-10 × 400m @ allure 5K (`get_race_predictions`), récup 200m trot

**Volume effort total** : 4-8 km  
**Fréquence** : max 1x/semaine, 48h de récup minimum après

---

### 4. Séance au Seuil (Tempo)
**Objectif** : Relever le seuil lactique  
**Garmin** : HR zone 4, ou pace = `lactateThresholdSpeed` depuis `get_user_profile`  
**Formats** :
- Tempo continu : 20-40 min zone 4
- Intervals seuil : 3-4 × 8-12 min zone 4, récup 2-3 min trot

**Signe de bonne intensité** : phrases difficiles mais pas haletant

---

### 5. Fractionné en Côtes
**Objectif** : Force spécifique, VMA, faible impact articulaire  
**Garmin** : HR zone cible (pas pace — terrain variable)  
**Formats** :
- 8-12 × 30-45s montée puissante, descente en récup
- 6-8 × 1 min montée Z4-Z5, récup descente

**Privilégier si** : douleur articulaire, reprise après blessure, surface dure

---

### 6. Récupération Active
**Objectif** : Faciliter la récupération sans stress supplémentaire  
**Garmin** : HR zone 2, 20-30 min max  
**Règle** : si impossible de tenir une conversation → trop vite

---

## Sélection du type de séance selon statut Garmin

| Statut Garmin | Sessions running semaine | Types autorisés |
|---|---|---|
| Productive | 3-4 | 1 qualité (seuil/VMA) + EF + sortie longue |
| Maintaining | 2-3 | 1 qualité + 1-2 EF |
| Recovery | 1-2 | EF courte + récup active |
| Overreaching | 1 max | Récupération active uniquement |
| Detraining | 2-3 | EF + 1 légère VMA pour stimulus |

## Règles d'enchaînement

- Jamais 2 séances Z5+ consécutives sans 48h entre elles
- Sortie longue : pas le lendemain d'une séance seuil ou VMA
- Progresser en volume OU en intensité, jamais les deux la même semaine
