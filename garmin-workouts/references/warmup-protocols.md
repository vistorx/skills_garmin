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
- **Phase 3 (Victor — genou G fémoro-patellaire) : plyométrie d'activation genou, ~10 min max** :
  - Série 1 : sauts depuis un banc/step, contrôle de la réception avec rebond immédiat — activer le contact au sol et le gainage du genou
  - Série 2 : rebond arrière + rebond avant enchaîné (saut en avant)
  - Objectif : activer la proprioception, le gainage articulaire, la réponse neuromusculaire du genou avant l'effort de fractionné
  - Prescrit par le kiné (sept. 2026) — à intégrer dans l'échauffement fractionné, pas en séance séparée
- Phase 3 standard (si pas de plyométrie) : 3–5 strides at target effort pace, full recovery between
- Total avec plyométrie : ~20 min — adapter la durée du footing en conséquence
- Garmin steps: warmup step (10 min, no target) + transition Zone 2 (5 min)

### Race day
- 15–20 min progressive jog + full drill sequence + 3–5 strides

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
