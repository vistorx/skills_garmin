# Changelog

Toutes les versions notables de ce pack. Format inspiré de
[Keep a Changelog](https://keepachangelog.com/fr/1.1.0/), versionnage
[SemVer](https://semver.org/lang/fr/) par tags git annotés.

Une version **majeure** signale une rupture du contrat de profil
(`training-profile/references/profile-schema.md`) : les profils existants doivent être
migrés. Mineure et correctif sont rétrocompatibles.

---

## [1.0.0] — 2026-11-01

Première version publiable. Le pack passait d'un usage mono-athlète à un pack partageable :
toutes les données personnelles de son auteur ont été extraites des skills et remplacées
par des lectures du profil athlète.

### Ajouté

- **Contrat de profil canonique** — `training-profile/references/profile-schema.md` :
  schéma complet (champs, valeurs admises, fenêtres de validité), source de vérité unique
  lue par tous les skills.
- **Champ `locations`** — les lieux d'entraînement deviennent une entité de premier plan,
  avec `equipment`, `floor_ok`, `supports` et `space` par lieu. Le lieu détermine le
  matériel *et* la posture possible ; une séance construite pour le mauvais lieu est une
  séance jetée.
- **Champ `injuries` structuré** — dont `restrictions` (filtre les exercices),
  `pain_threshold` (obligatoire dans la description de tout workout tant qu'une blessure
  est active) et `volume_limiter` (la variable clinique à borner, pas une approximation).
- **`garmin-onboarding` — Step 0 : lecture des données existantes.** L'onboarding ne
  démarre plus sur une page blanche : il balaye la mémoire de l'agent, les conversations
  passées (`chat_history_lookup`), le compte Garmin et les fichiers du profil, restitue ce
  qu'il a reconstitué champ par champ, puis ne questionne que les trous. Un agent qui
  tourne déjà depuis des semaines ne fait pas répéter l'athlète.
- **Bloc « Lieux et matériel »** dans l'onboarding (nouveau bloc 2), et bloc « Niveau »
  séparé de l'équipement.
- **Procédure de release et convention de versionnage** dans `garmin-coach-git`.
- **Bloc d'échauffement optionnel « activation neuromusculaire sur blessure articulaire
  déclarée »** dans `warmup-protocols.md`, conditionné à `injuries`, dosage non figé
  (il vient du praticien de l'athlète).
- Ce `CHANGELOG.md`.

### Modifié

- **Dépersonnalisation complète** — plus aucune donnée personnelle dans le pack : pas de
  prénom, pas de pathologie supposée, pas de matériel supposé, pas de créneau horaire en
  dur, pas de dosage individuel, pas d'adresse d'infrastructure privée.
- **Préférences de séance pilotées par le profil** — ordre des blocs, cooldown intégré ou
  non, mode de repos entre séries, préfixe de nommage, politique de séance de remplacement
  et style de réponse se lisent dans `session_preferences`. Les règles qui étaient absolues
  parce qu'elles venaient d'un seul athlète deviennent des défauts conditionnels, en
  conservant le raisonnement physiologique qui les justifiait.
- **Échauffement** — les protocoles scientifiques (sources citées) redeviennent le défaut ;
  `session_preferences.warmup_standard` les surcharge quand le profil en définit un.
- **Sélection des exercices** — l'ancienne liste « exercices valides pour genou douloureux »
  devient une *méthode* : classer tout exercice sur les axes de contrainte de la blessure
  déclarée, puis filtrer. Les tables d'origine restent comme exemple d'application.
- **Multisport** — reste un défaut fort (un sport = un workout, certaines montres ne lisent
  pas les workouts multisport), mais n'est plus un interdit absolu : autorisé si le profil
  déclare un appareil vérifié *sur l'appareil*, jamais sur la base d'un upload accepté.
- **`training-profile`** devient explicitement le hub du contrat de profil ; `garmin-coach-git`
  devient un skill de mainteneur, hors flux de coaching.
- README réécrit : principes, démarrage, carte des skills, versionnage.
- Allures en dur des exemples de séances remplacées par des placeholders calculés depuis
  `get_race_predictions` et les zones Garmin.

### Corrigé

- `sessions-strength.md` et `sessions-multi-sport.md` lisaient un champ de profil
  inexistant (`level_and_equipment`) — corrigé vers `locations[].equipment`,
  `sports[].level` et `sports[].notes`.
- Bloc « Retours de séance → Garmin » dupliqué mot pour mot dans `training-profile` —
  dédupliqué.
- Numérotation des blocs d'onboarding incohérente (annoncés 5, présents 6, avec une note
  de renumérotation périmée) — 7 blocs, numérotation alignée.
- Fautes d'orthographe dans plusieurs références (`bléssée`, `propriéception`,
  `enchainnement`, `planéifícation`, `bo ulot`).

### Rompu

- Les champs de profil `sports_routine`, `level_and_equipment` et `injury_status` sont
  remplacés par `sports`, `locations` + `sports[].level` et `injuries`. Un profil écrit
  avant cette version doit être relu et réécrit au nouveau schéma — `garmin-onboarding`
  le fait automatiquement via son Step 0.
- Le skill `garmin-profile-backup` et la sauvegarde du profil Hermes complet sont
  supprimés. Ce pack est le seul repo ; les skills sont ce qui a de la valeur, le reste
  est reconstructible.
- Le skill `weekly-review-planning` est retiré du pack : doublon d'un skill de
  productivité tiers, hors périmètre du coaching sportif.
