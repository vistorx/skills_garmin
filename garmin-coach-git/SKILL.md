---
name: garmin-coach-git
description: Maintainer-only. Publish and version this skills pack.
version: 1.2.0
author: hermes-garmin-skills contributors
license: MIT
platforms: [linux]
metadata:
  hermes:
    tags: [git, github, ssh, release, versioning, maintainer]
    related_skills: []
---

# Pack de skills — publication et versionnage

**Skill de mainteneur.** Il ne sert pas au coaching : il sert à publier et versionner ce
pack. Un athlète qui utilise le pack n'en a jamais besoin.

## Repo

- **URL** : https://github.com/vistorx/skills_garmin
- **Racine locale** : le dossier qui contient `README.md` et les dossiers de skills.
  Le `.git` est **à cette racine**, pas au niveau parent `skills/` — les autres catégories
  de skills du profil ne doivent pas être trackées par ce repo.
  Sur l'installation de référence : `/opt/data/profiles/garmin-coach/skills/fitness/`.
- **Script** : `bash <racine>/garmin-coach-git/scripts/sync_to_github.sh "msg"`

## SSH

Le `$HOME` système d'un profil Hermes n'est pas le home de l'utilisateur de la machine,
donc SSH ne trouve pas les clés tout seul. On court-circuite avec `core.sshCommand`
configuré dans le repo — pas besoin de `GIT_SSH_COMMAND` à chaque appel.

- Clé sur l'installation de référence : `/opt/data/profiles/garmin-coach/home/.ssh/id_ed25519`

```bash
git config core.sshCommand "ssh -i <chemin>/.ssh/id_ed25519 -o StrictHostKeyChecking=no -o IdentitiesOnly=yes"
ssh -i <chemin>/.ssh/id_ed25519 -o StrictHostKeyChecking=no -T git@github.com
```

---

## Versionnage

Le pack est versionné par **tags git annotés** à la racine du repo, en SemVer.

| Incrément | Quand |
|---|---|
| **majeur** | Rupture du contrat de profil (`training-profile/references/profile-schema.md`) : champ renommé ou supprimé, sémantique changée. Les profils existants doivent être migrés. |
| **mineur** | Nouveau skill, nouveau champ de profil optionnel, nouvelle référence, nouvelle capacité. Rétrocompatible. |
| **correctif** | Correction de règle, de pitfall, de formulation. Aucun impact sur le profil. |

Procédure de release :

1. **Gate de dépersonnalisation — vérifier par grep, pas à l'œil.** Un pack partagé ne
   doit contenir aucune donnée personnelle : prénom, pathologie supposée, matériel
   supposé, créneau horaire en dur, dosage individuel, adresse d'infrastructure privée.
   Relire le diff ne suffit pas : ces fuites sont diffuses et une seule relecture en rate.

   ```bash
   grep -rin "<prenom>\|<pathologies>\|<marqueurs perso>\|192\.168\|10\." --include="*.md" .
   ```

   Les dates ne partent pas toutes : une date qui atteste une vérification technique de
   l'API se garde (elle date la validité du constat), une date d'anecdote personnelle part.
2. **Gate de cohérence du contrat.** Tout champ de profil cité dans un skill doit exister
   dans `training-profile/references/profile-schema.md`. Un skill qui lit un champ fantôme
   échoue silencieusement : l'agent ne trouve rien et improvise au lieu de signaler un trou.

   ```bash
   grep -rhoE "\b(identity|device|sports|locations|availability|objectives|injuries|injury_history|job_lifestyle|session_preferences|planning_mode)\b(\[\])?\.[a-z_]+" --include="*.md" . | sort -u
   ```

   Comparer la sortie au schéma. C'est ce contrôle qui rattrape les renommages de champs
   oubliés dans les `references/`, là où personne ne relit.
3. **Mettre à jour `CHANGELOG.md`** — voir la discipline de changelog ci-dessous. C'est
   l'étape qui détermine aussi l'incrément de version.
4. Aligner le champ `version:` du frontmatter des skills touchés — tous les skills du pack
   portent la même version, le pack se publie en bloc.
5. Commit, puis tag annoté :

   ```bash
   git tag -a vX.Y.Z -m "Résumé de la version"
   git push origin main --tags
   ```

6. Vérifier que le tag est arrivé : `git ls-remote --tags origin`.

Un commit sans tag est une itération de travail ; seul un tag constitue une version
publiée. Un tag sans section de changelog correspondante est une erreur à corriger
immédiatement : c'est la seule trace que lira quelqu'un qui récupère le pack.

---

## Discipline de changelog

`CHANGELOG.md` vit à la racine du repo et se tient **en continu**, pas au moment de taguer.
Un `git log` n'est pas un changelog : il raconte des commits, alors que le changelog répond
à la seule question qui intéresse quelqu'un qui met à jour — *qu'est-ce qui change pour
moi, et qu'est-ce que j'ai à faire ?*

Format : [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/). Une section par version,
la plus récente en haut, titrée `## [X.Y.Z] — AAAA-MM-JJ`.

### Les quatre rubriques

Dans cet ordre, et seulement celles qui ont du contenu :

| Rubrique | Contenu |
|---|---|
| **Ajouté** | Nouveau skill, nouveau champ de profil, nouvelle règle, nouvelle référence |
| **Modifié** | Comportement changé à périmètre constant |
| **Corrigé** | Bug de contenu : règle fausse, renvoi mort, champ de profil fantôme, faute |
| **Rompu** | Ce qui casse un profil ou un usage existant, **avec la marche à suivre** |

### Règles d'écriture

- **Écrire pour l'athlète qui met à jour**, pas pour soi : « le pack s'adapte au modèle de
  montre », pas « ajout du champ device ».
- **Une entrée = un changement**, compréhensible sans lire le diff. Nommer le fichier ou le
  champ concerné entre backticks pour qu'on puisse le retrouver.
- **Dire pourquoi** quand la raison n'est pas évidente. C'est ce qui évite qu'une règle soit
  détricotée six mois plus tard par quelqu'un qui n'en voit plus le motif.
- **Toute entrée de « Rompu » porte sa procédure de migration.** Une rupture sans marche à
  suivre est un bug, pas une note de version.
- Pas de détail d'implémentation sans effet observable, pas de ménage cosmétique. Si
  personne ne peut le constater à l'usage, ça n'y va pas.

### Travail en cours et choix de l'incrément

Entre deux versions, les entrées s'accumulent sous une section `## [Non publié]` en haut du
fichier. Au moment du tag, elle est renommée `## [X.Y.Z] — <date du jour>` et une nouvelle
`[Non publié]` vide est recréée.

C'est le contenu de `[Non publié]` qui **détermine** l'incrément :

- une entrée dans **Rompu** → majeur ;
- sinon une entrée dans **Ajouté** → au moins mineur ;
- sinon → correctif.

L'incrément se lit dans le changelog, il ne se décide pas à l'intuition.

Avant de renommer la section, contrôler qu'aucun changement observable n'a été oublié :

```bash
git log <dernier-tag>..HEAD --stat
```

---

## Reconstruire le repo si le `.git` a disparu

```bash
cd $TMPDIR && git clone --depth 1 https://github.com/vistorx/skills_garmin.git sg
cd <racine-du-pack> && cp -r $TMPDIR/sg/.git ./.git
git remote set-url origin git@github.com:vistorx/skills_garmin.git
git config core.sshCommand "ssh -i <chemin>/.ssh/id_ed25519 -o StrictHostKeyChecking=no -o IdentitiesOnly=yes"
git config user.email "<email>"; git config user.name "<nom>"
```

Si la clé SSH manque aussi : `ssh-keygen -t ed25519 -N "" -f <chemin>/.ssh/id_ed25519`,
**puis `chmod 600`**, puis faire ajouter la clé publique sur
https://github.com/settings/keys par le propriétaire du compte.

## Réécrire plusieurs skills en parallèle

Une refonte qui touche beaucoup de fichiers se délègue par lots, mais la cohérence ne
survit que si chaque exécutant partage la même référence :

- **Figer le contrat AVANT de déléguer.** Écrire ou mettre à jour
  `training-profile/references/profile-schema.md` d'abord, puis passer son chemin dans le contexte de chaque lot.
  Des exécutants parallèles sans source commune inventent des noms de champs divergents.
- **Un lot = des fichiers disjoints.** Deux exécutants sur le même fichier se écrasent
  mutuellement sans erreur visible.
- **Énoncer ce qui doit SURVIVRE, pas seulement ce qui doit partir.** Sans consigne de
  conservation explicite, une passe de nettoyage ampute les vérités d'API chèrement
  acquises et les justifications physiologiques — c'est ce qui fait la valeur du pack.
  La généricité est l'objectif, la brièveté n'en est pas un.
- Relire le résultat soi-même : un exécutant qui rapporte « 0 occurrence restante » a
  vérifié son périmètre, pas le pack.

## Pitfalls

- **`chmod 600` sur la clé privée est obligatoire.** Sans ça SSH la refuse
  (`UNPROTECTED PRIVATE KEY FILE`) et le push échoue sur un trompeur
  `Permission denied (publickey)` — qui ressemble à une clé non autorisée alors que ce ne
  sont que les droits du fichier.
- **Ne jamais remonter le `.git` au dossier parent** `skills/`.
- Un `Repository not found` alors que `ssh -T git@github.com` répond correctement signifie
  que le repo distant n'existe plus (supprimé ou renommé), pas que l'authentification
  échoue. Vérifier avec `git ls-remote` avant de conclure.
- Ce pack est le seul repo du profil, et c'est volontaire : il n'y a pas de sauvegarde du
  profil Hermes complet. Les skills sont ce qui a de la valeur, le reste est
  reconstructible. Ne pas proposer de remettre en place un backup de profil.
