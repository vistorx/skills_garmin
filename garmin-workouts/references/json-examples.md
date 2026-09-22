# Garmin Workout JSON Examples

Annotated reference for `upload_workout` payloads. These are the exact structures expected by the Garmin Connect MCP.

---

## 1. Strength Session — RepeatGroupDTO with reps + lap-button rest

**Use case**: any strength exercise, N sets × M reps, manual recovery.

```json
{
  "type": "RepeatGroupDTO",
  "stepOrder": 1,
  "stepType": {"stepTypeId": 6, "stepTypeKey": "repeat"},
  "numberOfIterations": 3,
  "skipLastRestStep": true,
  "endCondition": {"conditionTypeId": 7, "conditionTypeKey": "iterations"},
  "endConditionValue": 3.0,
  "workoutSteps": [
    {
      "type": "ExecutableStepDTO",
      "stepOrder": 1,
      "stepType": {"stepTypeId": 3, "stepTypeKey": "interval"},
      "endCondition": {"conditionTypeId": 10, "conditionTypeKey": "reps"},
      "endConditionValue": 12.0,
      "targetType": {"workoutTargetTypeId": 1, "workoutTargetTypeKey": "no.target"},
      "category": "HIP_RAISE",
      "exerciseName": "SINGLE_LEG_HIP_RAISE",
      "description": "12 fois Pont fessier"
    },
    {
      "type": "ExecutableStepDTO",
      "stepOrder": 2,
      "stepType": {"stepTypeId": 5, "stepTypeKey": "rest"},
      "endCondition": {"conditionTypeId": 1, "conditionTypeKey": "lap.button"}
    }
  ]
}
```

**Notes**:
- `conditionTypeId: 7` on the RepeatGroupDTO is mandatory — omitting it silently corrupts the repeat count.
- `skipLastRestStep: true` skips recovery after the final set.
- `endConditionValue: 12.0` = rep target (goal, not obligation — Garmin logs actual reps done).

---

## 2. Short Interval Run — 30/30 pace-based

**Use case**: fractionné court ≤1 min effort. Always use pace (m/s), never HR zone — HR lag makes zone targets meaningless at this duration.

```json
{
  "type": "RepeatGroupDTO",
  "stepOrder": 3,
  "stepType": {"stepTypeId": 6, "stepTypeKey": "repeat"},
  "numberOfIterations": 15,
  "skipLastRestStep": false,
  "endCondition": {"conditionTypeId": 7, "conditionTypeKey": "iterations"},
  "endConditionValue": 15,
  "workoutSteps": [
    {
      "type": "ExecutableStepDTO",
      "stepOrder": 1,
      "stepType": {"stepTypeId": 3, "stepTypeKey": "interval"},
      "endCondition": {"conditionTypeId": 2, "conditionTypeKey": "time"},
      "endConditionValue": 30,
      "targetType": {"workoutTargetTypeId": 6, "workoutTargetTypeKey": "pace.zone"},
      "targetValueOne": 3.6364,
      "targetValueTwo": 3.9216,
      "description": "Effort ~4:15-4:35/km"
    },
    {
      "type": "ExecutableStepDTO",
      "stepOrder": 2,
      "stepType": {"stepTypeId": 5, "stepTypeKey": "rest"},
      "endCondition": {"conditionTypeId": 2, "conditionTypeKey": "time"},
      "endConditionValue": 30,
      "targetType": {"workoutTargetTypeId": 6, "workoutTargetTypeKey": "pace.zone"},
      "targetValueOne": 2.5641,
      "targetValueTwo": 2.7778,
      "description": "Recup ~6:00-6:30/km"
    }
  ]
}
```

**Notes**:
- `targetValueOne`/`targetValueTwo` are in **meters per second**. Conversion: pace (min/km) → m/s = 1000 / (pace_seconds).
  - 4:15/km = 255s → 1000/255 = 3.9216 m/s
  - 4:35/km = 275s → 1000/275 = 3.6364 m/s
- Always calibrate from `get_race_predictions` or personal records — never invent a pace.
- Recovery uses same pace target type for consistency.

---

## 3. Long-Block Interval — Fartlek HR-based

**Use case**: efforts ≥2–3 min (fartlek, tempo, threshold). HR has time to stabilize — zone targets are meaningful.

```json
{
  "type": "RepeatGroupDTO",
  "stepOrder": 2,
  "stepType": {"stepTypeId": 6, "stepTypeKey": "repeat"},
  "numberOfIterations": 5,
  "skipLastRestStep": false,
  "endCondition": {"conditionTypeId": 7, "conditionTypeKey": "iterations"},
  "endConditionValue": 5,
  "workoutSteps": [
    {
      "type": "ExecutableStepDTO",
      "stepOrder": 1,
      "stepType": {"stepTypeId": 3, "stepTypeKey": "interval"},
      "endCondition": {"conditionTypeId": 2, "conditionTypeKey": "time"},
      "endConditionValue": 180,
      "targetType": {"workoutTargetTypeId": 4, "workoutTargetTypeKey": "heart.rate.zone"},
      "zoneNumber": 3
    },
    {
      "type": "ExecutableStepDTO",
      "stepOrder": 2,
      "stepType": {"stepTypeId": 3, "stepTypeKey": "interval"},
      "endCondition": {"conditionTypeId": 2, "conditionTypeKey": "time"},
      "endConditionValue": 180,
      "targetType": {"workoutTargetTypeId": 4, "workoutTargetTypeKey": "heart.rate.zone"},
      "zoneNumber": 2
    }
  ]
}
```

**Notes**:
- `endConditionValue` for time steps is in **seconds** (180 = 3 min).
- Zone 1 is never used for running — Zone 2 minimum.
- Recovery block here uses `stepTypeKey: "interval"` not `"rest"` because it's an active recovery with HR target.

---

## 4. Full Running Workout Shell

```json
{
  "workoutName": "AI - [Name]",
  "sportType": {"sportTypeId": 1, "sportTypeKey": "running"},
  "workoutSegments": [
    {
      "segmentOrder": 1,
      "sportType": {"sportTypeId": 1, "sportTypeKey": "running"},
      "workoutSteps": [
        {
          "type": "ExecutableStepDTO",
          "stepOrder": 1,
          "stepType": {"stepTypeId": 1, "stepTypeKey": "warmup"},
          "endCondition": {"conditionTypeId": 2, "conditionTypeKey": "time"},
          "endConditionValue": 300,
          "targetType": {"workoutTargetTypeId": 1, "workoutTargetTypeKey": "no.target"},
          "description": "Marche"
        },
        {
          "type": "ExecutableStepDTO",
          "stepOrder": 2,
          "stepType": {"stepTypeId": 3, "stepTypeKey": "interval"},
          "endCondition": {"conditionTypeId": 2, "conditionTypeKey": "time"},
          "endConditionValue": 600,
          "targetType": {"workoutTargetTypeId": 4, "workoutTargetTypeKey": "heart.rate.zone"},
          "zoneNumber": 2,
          "description": "Zone 2 transition"
        }
      ]
    }
  ]
}
```

---

## Key IDs Quick Reference

| Concept | ID | Key |
|---|---|---|
| Step: warmup | stepTypeId: 1 | warmup |
| Step: cooldown | stepTypeId: 2 | cooldown |
| Step: interval/effort | stepTypeId: 3 | interval |
| Step: rest | stepTypeId: 5 | rest |
| Step: repeat group | stepTypeId: 6 | repeat |
| End: lap button | conditionTypeId: 1 | lap.button |
| End: time | conditionTypeId: 2 | time |
| End: iterations | conditionTypeId: 7 | iterations |
| End: reps | conditionTypeId: 10 | reps |
| Target: none | workoutTargetTypeId: 1 | no.target |
| Target: HR zone | workoutTargetTypeId: 4 | heart.rate.zone |
| Target: pace zone | workoutTargetTypeId: 6 | pace.zone |
