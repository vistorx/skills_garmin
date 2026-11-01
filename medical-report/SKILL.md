---
name: medical-report
description: Use when Victor needs a kine/doctor report.
version: 1.0.0
author: Victor Ourd, Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [kine, medecin, blessure, rapport, compte-rendu]
    related_skills: [training-profile, garmin-health-check]
---
# Medical Report Skill

Génère un compte-rendu synthétique pour un rendez-vous kiné ou médecin, basé sur les données Garmin et les retours de séance enregistrés.

## Quand utiliser

- "Je vais chez le kiné, fais-moi un CR"
- "J'ai un rendez-vous médecin, topo rapide"
- "Qu'est-ce que je dis au kiné ?"

## Données à récupérer

Tout en parallèle :

```
get_activities(last 7 days)           → séances récentes + descriptions (retours Victor) — défaut 7j, ajustable à la demande
get_training_readiness(today)         → état du jour
get_sleep_summary_range(last 7 days)  → qualité du sommeil
get_hrv_trend(last 14 days)           → tendance récupération
get_rhr_day(today)                    → FC repos
```

Lire aussi le profil mémoire (`training-profile`) pour :
- Blessures actives (localisation, contexte, date)
- Historique des sensations notées

## Choisir le format AVANT de rédiger

Trois livrables différents. Demander/déduire lequel, ne pas produire le CR long par défaut.

| Situation | Livrable |
|---|---|
| RDV à préparer à l'avance | **CR écrit** (structure ci-dessous) |
| Victor arrive au RDV / est devant la porte | **Pitch oral 20 s** |
| Il demande "qu'est-ce que je lui dis ?" | **Pitch oral 20 s** |

### Pitch oral — règles

- **20 secondes max, 4 phrases.** Diagnostic + symptômes + le chiffre qui frappe + LA question à poser.
- Rédigé **à la première personne, prêt à être lu à voix haute** (« J'ai un syndrome… ma question c'est… »).
- Pas de tableau, pas de puces imbriquées, pas de section « contexte ».
- Finir par **une seule question** — celle que ce praticien-là peut trancher.
- Si Victor demande plus court, couper le contexte, garder diagnostic + chiffre + question. Ne pas réécrire tout l'enrobage.

Demander le **type de RDV** avant de rédiger : première consultation ou **visite de contrôle**, et ce qu'il a déjà (semelles, orthèses, examens faits). La question à poser change du tout au tout — avec des semelles déjà en place on ne demande pas « faut-il des semelles » mais « faut-il revoir celles-là depuis le nouveau diagnostic ».

Adapter le brief à la **spécialité** du praticien : voir `references/practitioner-briefs.md`.

## Format du CR

Court, factuel, structuré. Le kiné veut des faits, pas du remplissage.

---

**CR Kiné / Dr [Nom] — [Date]**

**Blessure(s) suivie(s)**
- [Localisation] : contexte, symptômes, depuis quand

**Séances des 7 derniers jours** (ou N jours si demandé)
- [Date] [Sport] [durée/distance] — [retour Victor si disponible]
- ...

**Signaux objectifs (Garmin)**
- Readiness : [score] / [niveau]
- FC repos : [valeur]
- Sommeil : [score moyen 7j]
- HRV : [tendance : stable / en hausse / en baisse]

**Points à aborder avec le praticien**
- [Issu des retours de séance et des signaux]

---

## Règles

- Jamais inventer ou interpréter médicalement — rapporter les faits et sensations notées
- Si une séance n'a pas de description/retour → noter juste le type + durée, sans commentaire
- La section "Points à aborder" = ce que les données suggèrent de mentionner, pas un diagnostic
- Toujours demander à Victor s'il veut ajouter quelque chose avant de finaliser
- Format lisible à voix haute (Victor peut le lire directement en séance)

## Pitfalls

- **Calculer la date réelle avec `date` avant toute référence temporelle.** Ne jamais écrire « hier », « la semaine dernière » ou « fin octobre » de mémoire dans un CR ou un pitch : la date d'un diagnostic est l'information que le praticien vérifie en premier, et se tromper coûte la crédibilité du brief entier.
- **Le différentiel de charge est l'apport unique des données Garmin — le mettre en avant.** Un praticien a l'examen clinique ; il n'a pas « 3 km continu = douleur, 7×400 m / 100 m marche = rien ». Formuler ce qui déclenche ET ce qui ne déclenche pas, avec les chiffres : c'est ça qui réoriente une prise en charge, pas la liste des séances.
- **Distinguer douleur pendant l'effort et douleur différée.** Noter systématiquement « pendant la séance » vs « le soir / le lendemain » : une douleur différée oriente vers une réaction post-charge, une douleur per-effort vers un conflit mécanique. C'est une info que seul le journal d'activités conserve.
- **Des symptômes qui progressent pendant une semaine de décharge invalident l'explication par la charge d'entraînement.** Arrêter d'ajuster le volume et orienter vers un avis médical avec imagerie. Continuer à planifier des séances dans ce cas revient à traiter un problème qu'on a déjà démontré ne pas être le bon.
- **Retirer explicitement une hypothèse rassurante quand les données la contredisent.** Écrire « je retire ce que j'ai dit » plutôt que de laisser une interprétation optimiste périmée dans l'historique — Victor s'appuie dessus pour décider de s'entraîner ou pas.
- **Signaler quand un symptôme rapporté n'apparaît pas dans le compte-rendu du praticien.** Un symptôme omis n'est pas un symptôme écarté ; le rappeler au praticien suivant.

## Journaliser les retours dans Garmin (source du CR)

Le CR ne vaut que si les données existent. Après chaque séance et chaque RDV :

```
set_activity_name(activity_id, nom explicite)
set_activity_description(activity_id, contenu + retour verbatim de Victor + état articulaire)
```

- Écrire le retour **le jour même**, pendant que Victor le raconte — c'est la seule source des « retours Victor » que le CR relit ensuite.
- Inclure dans la description : contenu réel de la séance (exos, charges, séries), ressenti, douleur (pendant / après / absente), et le contexte de charge des jours précédents.
- Une séance kiné en machine : noter les **charges et le nombre de séries par exercice**. La dissociation entre deux exercices (l'un indolore sous charge lourde, l'autre douloureux d'emblée) est un signe clinique exploitable.

## Lire un courrier médical

Les courriers d'adressage et comptes-rendus arrivent en PDF → `read_file(path)` en extrait le texte directement, pas besoin d'OCR.

En extraire et consigner en mémoire : le **diagnostic retenu**, ce que l'examen **élimine** (laxité, épanchement, imagerie), les **consignes d'activité** (mouvements interdits, sports autorisés), l'**examen prescrit** et le praticien adressé, puis la **condition de réévaluation**.

Restituer à Victor en séparant ce qui est **éliminé** de ce qui est **retenu** : savoir ce qu'il n'a pas est aussi utile que le diagnostic.

## Parcours multi-praticiens

Quand plusieurs RDV s'enchaînent, l'ordre compte :

- **Un examen de mesure (isocinétique, bilan de force) passe AVANT toute manipulation** (ostéo, mobilisation) — une manipulation la veille fausse la mesure.
- Identifier le **goulot d'étranglement** (l'examen qui débloque tous les autres) et le dire en une ligne : c'est la seule action urgente.
- Transmettre à chaque praticien ce que le précédent a conclu, avec son vocabulaire (« verrouillage de bassin », « syndrome fémoro-patellaire ») — c'est ce qui réoriente sa prise en charge.

## Variante médecin généraliste

Même structure, mais ajouter si dispo :
- VO2max tendance (4 semaines)
- Poids / composition corporelle récente
- Tout signal inhabituel (FC anormalement élevée, sommeil dégradé persistant, etc.)
