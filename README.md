# Garmin Coach — pack de skills

Skills [Hermes Agent](https://hermes-agent.nousresearch.com/docs) pour du coaching sportif
piloté par les données [Garmin Connect](https://github.com/cyberjunky/python-garminconnect)
(via MCP).

Un coach qui lit ton compte Garmin, construit ton profil, planifie tes séances et les
pousse sur ta montre. Multi-sport, pas seulement la course.

---

## Principes

- **Garmin est la source de vérité physiologique.** Zones FC, seuil lactique, VO2max,
  allures prédites : lus depuis l'API, jamais recalculés ni estimés.
- **Le profil athlète est la source de vérité personnelle.** Blessures, matériel, lieux,
  disponibilités, préférences vivent dans la mémoire persistante Hermes, pas dans les
  fichiers de skills. Un seul contrat de données, lu par tous les skills :
  [`training-profile/references/profile-schema.md`](training-profile/references/profile-schema.md).
- **Aucune donnée personnelle dans le pack.** Pas de pathologie supposée, pas de matériel
  supposé, pas de créneau en dur. Le pack s'adapte à l'athlète, pas l'inverse.
- **Rien ne s'invente.** Une donnée absente se récupère, se demande, ou se signale comme
  manquante — jamais elle ne se devine.
- **Le profil est une base, la conversation du jour est la réalité.** Ce que l'athlète dit
  maintenant prime toujours sur ce qui est enregistré.

---

## Démarrage

Pré-requis : [Hermes Agent](https://hermes-agent.nousresearch.com/docs) et un serveur MCP
Garmin Connect configuré sur le compte de l'athlète.

Première session :

> *« Crée mon profil de sportif »*

L'onboarding commence par **lire ce qui existe déjà** — mémoire de l'agent, conversations
passées, compte Garmin — restitue ce qu'il a reconstitué, puis ne questionne que les trous.
Un agent qui tourne déjà depuis des semaines ne repart pas de zéro.

Ensuite, au choix :

> *« Planifie ma semaine »* — plan complet, uploadé et schedulé sur le calendrier Garmin
> *« J'ai 45 minutes ce soir »* — une séance, maintenant

---

## Skills

| Skill | Rôle |
|---|---|
| **`garmin-plan`** | Point d'entrée de toute demande d'entraînement. Détecte le mode et route. |
| **`training-profile`** | Source de vérité du profil athlète : schéma, lecture, mise à jour, frontière mémoire/skills. |
| **`garmin-onboarding`** | Construction du profil en 7 blocs, après lecture des données déjà disponibles. |
| **`garmin-health-check`** | Bilan de l'état du jour : readiness, statut d'entraînement, HRV, sommeil, VO2max, détection de surmenage. Lecture seule. |
| **`garmin-weekly-plan`** | Semaine complète : objectif → squelette → séances → upload et schedule. |
| **`garmin-session-plan`** | Séance unique, flow court, sans contexte hebdomadaire. |
| **`garmin-workouts`** | Règles de construction des workouts Garmin et bibliothèques de séances. |
| **`garmin-mcp-upload`** | Mécanique d'upload MCP : forme des appels, pièges de payload, gate de validation. |
| **`medical-report`** | Compte-rendu structuré pour un kiné ou un médecin, à partir des données Garmin et des retours de séance. |
| **`garmin-coach-git`** | Mainteneur uniquement : publication et versionnage du pack. |

### Bibliothèques de séances (`garmin-workouts/references/`)

| Fichier | Contenu |
|---|---|
| `sessions-running.md` | EF, fractionné court et long, seuil, côtes — calibrés depuis Garmin |
| `sessions-strength.md` | Exercices mappés aux enums Garmin natifs, par groupe musculaire |
| `sessions-multi-sport.md` | Cyclisme, natation, sports collectifs, escalade |
| `warmup-protocols.md` | Protocoles d'échauffement par type de séance, sources citées |
| `json-examples.md` | Structures JSON Garmin annotées : RepeatGroupDTO, cibles d'allure, zones FC |

---

## Versions

Versionné en SemVer par tags git annotés. Voir [`CHANGELOG.md`](CHANGELOG.md).

Une version **majeure** signale une rupture du contrat de profil : les profils existants
doivent être migrés. Mineure et correctif sont rétrocompatibles. La procédure de release
est dans `garmin-coach-git`.

## Licence

MIT.
