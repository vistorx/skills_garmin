# Warm-up Protocols (Science-Based)

Source: Sople & Wilcox (2024), Konrad et al. (2021), Pacebrain (2024), doi:10.1016/j.asmr.2024.101023

**Key rule: NO static stretching before effort.** Static stretching before running reduces force/power by 3.7–8% (Behm et al., 2016). Dynamic warm-up improves running performance by +9.8% (Konrad 2021).

---

## Generic Warm-up Structure (any sport)

3 phases, total 7–15 min depending on session intensity:

### Phase 1 — Cardiovascular activation (2–5 min)
Goal: raise core temp, blood flow to muscles.
- Easy walk → light jog progression
- Low-intensity, conversational pace

### Phase 2 — Dynamic mobility (3–5 min)
Goal: joint mobility, muscle activation through movement.
- Leg swings front/back × 10/leg
- Leg swings side/side × 10/leg
- Hip circles × 10 each direction
- Walking lunges × 10/leg
- High knees × 30 sec
- Butt kicks × 30 sec
- Ankle circles + calf raises × 10

### Phase 3 — Sport-specific activation (2–5 min)
Goal: prime neuromuscular patterns for the session ahead.

---

## Running Warm-up Protocols by Session Type

> **Priorité du profil athlète.** Si `session_preferences.warmup_standard` est défini dans le profil, ce protocole **prime** sur tous les défauts ci-dessous, pour tous les types de séance de course — y compris quand il est plus long que le défaut. De même, `session_preferences.warmup_per_type` surcharge le défaut du type concerné. Les protocoles ci-dessous sont les défauts scientifiques à appliquer uniquement quand le profil ne pose rien.
>
> Conséquence pratique : un `warmup_standard` plus long que le défaut impose de réduire le bloc principal pour rester sous `availability.max_duration_min` (la durée annoncée inclut échauffement et retour au calme).

### Easy run / recovery run
- Phase 1: 2–3 min walk + easy jog — the first km IS the warm-up
- Phase 2: optional, minimal (2–3 drills)
- Total: 5–7 min

### Tempo / threshold / moderate session
- Phase 1: 5 min easy jog
- Phase 2: 4–6 dynamic drills (leg swings, lunges, high knees)
- Phase 3: 2–3 strides (10–15 sec accelerations at 5K effort, full recovery)
- Total: 10–12 min
- Garmin steps: warmup step (5 min, no target) + transition jog (5 min Zone 2) — drills happen off-watch or logged as pre-session

### Intervals / VO2max / short fractionné
- Phase 1: 7–10 min progressive jog (easy → moderate)
- Phase 2: full dynamic drill sequence (5–7 drills)
- Phase 3: 3–5 strides at target effort pace, full recovery between
- Total: 12–15 min
- Garmin steps: warmup step (10 min, no target) + transition Zone 2 (5 min)
- Si une blessure articulaire est déclarée dans `injuries`, voir le bloc optionnel d'activation neuromusculaire ci-dessous : il remplace ou complète la Phase 3 et allonge l'échauffement, donc raccourcit le bloc principal d'autant.

### Race day
- 15–20 min progressive jog + full drill sequence + 3–5 strides

---

## Bloc optionnel — activation neuromusculaire sur blessure articulaire déclarée

**Condition d'application.** Uniquement si `injuries` contient une blessure articulaire active **et** que les sauts/impacts ne figurent pas dans `injuries[].restrictions` **et** que la séance reste sous `injuries[].pain_threshold`. Si un protocole est posé dans `session_preferences.warmup_standard`, c'est lui qui fait foi : ce bloc ne s'y superpose pas.

**Pourquoi.** Une articulation douloureuse arrive à l'effort avec une proprioception et un gainage réflexe dégradés. Une courte séquence de contacts au sol contrôlés avant l'effort réactive la réponse neuromusculaire et le verrouillage articulaire, au lieu de demander à l'articulation de les produire à froid pendant la première répétition intense.

**Séquence** (à intégrer dans l'échauffement, jamais en séance séparée) :
1. Sauts depuis un banc/step, réception contrôlée avec rebond immédiat — travaille le contact au sol et le gainage de l'articulation concernée.
2. Rebond arrière puis rebond avant enchaîné (saut en avant) — enchaînement de contacts dans deux directions.

**Dosage.** Le volume (séries, répétitions, hauteur, durée totale) n'est pas fixé ici : il vient de la prescription du praticien de l'athlète, sinon du minimum viable validé avec lui. Le noter dans `session_preferences.warmup_standard` une fois stabilisé.

**Garde-fous.**
- Arrêt immédiat si la douleur dépasse `injuries[].pain_threshold`.
- Nécessite les appuis correspondants dans `locations[].supports` (banc, step, marche) — sinon, bloc non programmable à ce lieu.
- Ce bloc allonge l'échauffement : réduire le bloc principal pour rester dans `availability.max_duration_min`.
- Contre-indiqué si les impacts/la plyométrie sont interdits par les `restrictions`, ou en phase de douleur aiguë.

---

## Strength Warm-up Protocol

### Standard (any strength session)
- 5 min: joint mobility (hip circles, shoulder rolls, thoracic rotation, ankle mobilization)
- Light activation sets: 1 set × 50% weight / 15 reps of first exercise, advance at own pace
- Total: 5–8 min
- Garmin: warmup step (5 min, no target) or omitted if user manages warm-up independently (confirmed in preferences)

---

## Cooldown Protocols

**Rule: static stretching is IDEAL post-effort** — muscles warm, best time to improve flexibility.

### Running cooldown
- 3–5 min easy jog or walk (flush lactate)
- 5–10 min static stretching: calves, hamstrings, quads, hip flexors, glutes (30–45 sec/hold)
- Garmin cooldown step: 3–5 min, no target

### Strength cooldown
- 5 min light mobility or walk
- Static stretches targeting muscles worked
- Garmin cooldown step: optional (most users skip, advance on lap-button)

---

## Garmin Warmup Step Template

```json
{
  "type": "ExecutableStepDTO",
  "stepOrder": 1,
  "stepType": {"stepTypeId": 1, "stepTypeKey": "warmup"},
  "endCondition": {"conditionTypeId": 2, "conditionTypeKey": "time"},
  "endConditionValue": 420,
  "targetType": {"workoutTargetTypeId": 1, "workoutTargetTypeKey": "no.target"},
  "description": "Activation progressive (marche → footing léger)"
}
```

Adjust `endConditionValue` (seconds) per session type:
- Easy run: 300 (5 min)
- Tempo/threshold: 600 (10 min)
- Intervals/VO2max: 720 (12 min)

Si `session_preferences.warmup_standard` (ou `warmup_per_type`) fixe une durée, c'est elle qui est utilisée, et sa description est reprise telle quelle dans le step.
