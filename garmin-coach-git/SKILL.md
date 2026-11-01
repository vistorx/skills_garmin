---
name: garmin-coach-git
description: Maintainer-only. Publish and version this skills pack.
version: 1.0.0
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

1. Relire le diff en entier. Un pack partagé ne doit contenir **aucune donnée
   personnelle** : pas de prénom, pas de pathologie supposée, pas de matériel supposé,
   pas de créneau horaire en dur, pas de dosage individuel.
2. Mettre à jour `CHANGELOG.md` — section de la nouvelle version, entrées groupées en
   *Ajouté / Modifié / Corrigé / Rompu*.
3. Aligner le champ `version:` du frontmatter des skills touchés.
4. Commit, puis tag annoté :

```bash
git tag -a vX.Y.Z -m "Résumé de la version"
git push origin main --tags
```

5. Vérifier que le tag est arrivé : `git ls-remote --tags origin`.

Un commit sans tag est une itération de travail ; seul un tag constitue une version publiée.

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
