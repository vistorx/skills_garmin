# Adapter le brief à la spécialité

Chaque praticien ne peut agir que sur son périmètre. Un brief générique lui fait perdre du temps ; le bon brief lui donne ce que lui seul peut exploiter.

Ces briefs valent pour **n'importe quelle blessure** : les éléments à transmettre se lisent dans `injuries` du profil athlète (`area`, `side`, `diagnosis`, `aggravating`, `relieving`, `restrictions`, `volume_limiter`) — aucune pathologie n'est supposée ici. Si `diagnosis` est `null`, le dire explicitement plutôt que de nommer un syndrome.

## Tronc commun (toutes spécialités)

1. **Diagnostic retenu + qui l'a posé + date exacte** (vérifier la date avec `date`)
2. **Ce que l'examen a éliminé** — évite au praticien de refaire le travail
3. **Déclencheurs concrets** (positions, gestes, durées)
4. **Le différentiel de charge** : ce qui déclenche vs ce qui ne déclenche pas, chiffré
5. **Une question**, celle que ce praticien peut trancher

## Kinésithérapeute

Il agit sur la force, le contrôle moteur et la progression des exercices.

- Volumes et charges réellement tolérés sur les exercices qu'il a prescrits
- Dissociations entre groupes musculaires (un exercice indolore sous charge lourde, un autre douloureux d'emblée)
- Contrainte matérielle et de lieu : ce qui est faisable avec `locations[].equipment` / `supports`, et ce qui est impossible si `floor_ok` est faux (debout uniquement)
- Les conclusions des autres praticiens dans leur vocabulaire — elles réorientent son travail
- Apporter les paires de chaussures si un podologue l'a demandé

## Médecin du sport / généraliste

Il pose le diagnostic, prescrit les examens et fixe les critères de reprise.

- Chronologie des symptômes : apparition, progression, bilatéralisation
- **Symptômes qui progressent sans charge** — l'argument qui justifie un examen complémentaire
- Douleur per-effort vs différée
- Sensations mécaniques décrites précisément et séparément : un ressaut global n'est pas un frottement latéral, et confondre les deux fait passer le symptôme pour déjà connu
- Charge objective sur la période (ACWR, charge aiguë) pour étayer « avec ou sans surcharge »

## Podologue

Il agit sur l'appui, la chaîne ascendante et le chaussage.

- Demander d'abord **première visite ou contrôle**, et ce qui existe déjà (semelles, orthèses) : avec des semelles en place la question est « faut-il les revoir depuis le nouveau diagnostic »
- Apporter les chaussures de chaque sport pratiqué — l'usure des semelles est un diagnostic en soi
- Questions utiles : pronation ou affaissement de voûte, inégalité de longueur des membres, analyse **dynamique** et pas seulement statique au podoscope, semelles à porter dans tous les sports ou seulement en course
- Un problème bilatéral oriente vers une cause en amont (bassin, hanches) plutôt que locale — le dire

## Ostéopathe

Il agit sur la mobilité articulaire et les restrictions en amont.

- La zone suspectée et par qui elle l'a été
- **Le planifier après tout examen de mesure** : une manipulation la veille fausse un bilan de force
- Les positions qui aggravent (station assise prolongée, flexion maintenue) pointent vers des restrictions de hanche/bassin

## Chaussage et reprise minimaliste

Quand un praticien recommande de réduire l'amorti :

- Appliquer **dans le protocole de reprise**, jamais immédiatement
- Prévenir du transfert de charge : moins d'amorti déplace la contrainte vers mollets, tendon d'Achille et pieds — une transition trop rapide échange une douleur de genou contre une tendinopathie d'Achille
- La transition se compte en semaines, en gardant les deux paires en alternance
