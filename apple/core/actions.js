// The native app's state and actions: openGym's profile, held here, changed by the same
// steps openGym's screens take. The web app writes its state from closures inside its React
// views and sheets (views/Workout.jsx, sheets.jsx); those closures are reproduced here,
// headless, line for line where possible, on top of the same lib helpers. SwiftUI calls these
// functions and draws what they return; it never edits the profile itself.
//
// Everything a function takes and returns is plain JSON, so the Swift bridge can pass it
// across JavaScriptCore. Side effects that belong to the device (sounds, the rest timer, a
// sheet) are returned as a description of what to do, never performed here.
import { DEF } from './defaults.gen.js'
import { registerCustom, EXIDX, betterWeight, beatsWeight } from '../../frontend/src/lib/exercises.js'
import { todayISO, uid, setWeightDecimals } from '../../frontend/src/lib/format.js'
import {
  bestWeightFor, bestWeightForEntry, buildSets, freestyleConfig, defaultConfig, setsDoneActive,
  setUnitsTotal, supersetUnits, unitOf, modeOf, isPerSide, cascadeWeight, insertWarmupRow,
  removeRowAt, pairAdjacent, unpairSuperset, cleanupSg, applyIntensifierPlan, workoutVolume,
  effectiveRoutineIds,
} from '../../frontend/src/lib/history.js'
import { is1RMRecord } from '../../frontend/src/lib/onerm.js'
import { exerciseMuscleSnapshot } from '../../frontend/src/lib/muscles.js'
import { buildCompletedWorkout } from '../../frontend/src/lib/finish-workout.js'
import { buildCombinedEntries, deriveSessionName } from '../../frontend/src/lib/session-merge.js'
import { buildSessionEntries, buildPlannedEntry, builtOutOfProgression } from '../../frontend/src/lib/session-start.js'
import { joinSessionNoProg, setEntryNoProg, setSessionNoProg, sessionNoProg } from '../../frontend/src/lib/session-noprog.js'
import { sessionHistory, markAllSetsDone, backfillStart, backfillEnd, completeBackfill, historyAsOf, workoutsOn } from '../../frontend/src/lib/backfill.js'
import { rebuildPrHistory } from '../../frontend/src/lib/workout-date.js'
import { stampWorkout } from '../../frontend/src/lib/sync-merge.js'
import { defaultIncrement, weightIncrement } from '../../frontend/src/lib/progression.js'
import { dropGrid } from '../../frontend/src/lib/plates.js'
import {
  isWarmupRow, isSideSet, makeSideSet, toggleSide, WEIGHT_ORIGIN_MANUAL,
} from '../../frontend/src/lib/workout-model.js'
import {
  insertionIndexAfterCurrentUnit, nextUnfinishedUnit, setProgressHighWater, supersetFlowStep,
  restAfterSet, restOnRecheck, restSecFor, warmupRestSecFor,
} from '../../frontend/src/lib/supersetFlow.js'
import { canMoveActiveWorkoutUnit, moveActiveWorkoutUnit } from '../../frontend/src/lib/active-workout-order.js'
import { swapActiveExercise } from '../../frontend/src/lib/active-exercise-swap.js'

const clone = o => JSON.parse(JSON.stringify(o))

let S = null
// How many sets of each exercise have ever been ticked in the running session (the web view
// keeps this in a ref): only progress past it may move on or start a rest, so unticking and
// reticking a finished set does not replay the flow. Index-keyed, like the web's.
let highWater = []

export function need() {
  if (!S) throw new Error('state not loaded')
  return S
}
function rebaseline() {
  highWater = (S?.active?.entries || []).map(e => e.sets.filter(s => s.done).length)
}

/* ------------------------------ the profile ------------------------------ */

/** Loads a saved profile (openGym's state JSON, or null for a new one) over the defaults. */
export function load(json) {
  const saved = json ? (typeof json === 'string' ? JSON.parse(json) : json) : null
  S = Object.assign(clone(DEF), saved || {})
  if (!saved) S.langAuto = true
  registerCustom(S.customEx)
  setWeightDecimals(S.wdec)
  rebaseline()
  return true
}

/** The whole profile, as openGym stores it: what the app saves and what a backup holds. */
export function exportState() {
  return JSON.stringify(need())
}

/** Top-level fields of the profile, for the screens that read them. */
export function pick(keys) {
  const st = need()
  return Object.fromEntries([].concat(keys).map(k => [k, st[k] ?? null]))
}

/**
 * Settings and other top-level values written as a whole (`{ restSec: 120 }`). The workout,
 * history and custom exercises have their own actions and cannot be replaced from here.
 */
const GUARDED = new Set(['active', 'workouts'])
export function patch(values) {
  const st = need()
  for (const [k, v] of Object.entries(values || {})) {
    if (GUARDED.has(k)) throw new Error(`${k} is changed through its own actions`)
    st[k] = v
  }
  if ('customEx' in (values || {})) registerCustom(st.customEx)
  if ('wdec' in (values || {})) setWeightDecimals(st.wdec)
  return true
}

/** Today's planned routines (week plan plus any one-day change), for the Start screen. */
export function todayRoutineIds(iso) {
  return effectiveRoutineIds(need(), iso || todayISO())
}

/* ------------------------------ the session ------------------------------ */

/** Snapshot of the running session with the counts the header shows, or null. */
export function active() {
  const A = need().active
  if (!A) return null
  return { ...A, setsDone: setsDoneActive(A), setsTotal: setUnitsTotal(A.entries), units: supersetUnits(A.entries) }
}

/** sheets.jsx beginWorkout: `freestyleName` is the localised "Freestyle". */
export function beginWorkout(routineIds, bw, freestyleName = 'Freestyle', now = Date.now()) {
  const st = need()
  const { entries, routineIds: rids, routines } = buildCombinedEntries(st, routineIds)
  st.active = {
    id: uid(), d: todayISO(), start: now,
    routineIds: rids,
    name: routines.length ? deriveSessionName(routines.map(r => r.name)) : freestyleName,
    bw: bw || null, cur: 0, entries,
    workoutView: st.workoutView || 'cards',
  }
  rebaseline()
  return active()
}

/** Workouts already on a day, for "Log a past workout" to offer replace or add. */
export function workoutsOnDay(iso) {
  return workoutsOn(need(), iso)
}

/** sheets.jsx beginBackfill: the workout screen pointed at a past day, without timers. */
export function beginBackfill({ iso, time, durationMin, routineIds, replaceId = null }, freestyleName = 'Freestyle') {
  const st = need()
  const start = backfillStart(iso, time)
  const past = historyAsOf(st, { d: iso, start, replaceId })
  const { entries, routineIds: rids, routines } = buildCombinedEntries(past, routineIds || [])
  st.active = {
    id: uid(), d: iso, start,
    routineIds: rids,
    name: routines.length ? deriveSessionName(routines.map(r => r.name)) : freestyleName,
    bw: null, cur: 0, entries,
    backfill: { durationMin, replaceId: replaceId || null },
    workoutView: st.workoutView || 'cards',
  }
  rebaseline()
  return active()
}

export function discardWorkout() {
  need().active = null
  highWater = []
  return true
}

const entryAt = idx => {
  if (!need().active) throw new Error('no session in progress')
  const e = S.active.entries[idx]
  if (!e) throw new Error(`no exercise at ${idx}`)
  return e
}
const modeAt = idx => {
  const e = entryAt(idx)
  return modeOf({ ...(e.target || {}), id: e.id })
}

/** Workout.jsx setField: a cleared optional field is dropped; a weight carries forward. */
export function setField(idx, i, field, v) {
  const e = entryAt(idx)
  if (v == null) delete e.sets[i][field]; else e.sets[i][field] = v
  if (field === 'sec') delete e.sets[i].planSec
  if (field === 'w') {
    e.sets[i].weightOrigin = WEIGHT_ORIGIN_MANUAL
    e.sets = cascadeWeight(e.sets, i, v)
  }
  return e
}

export function addSet(idx) {
  const e = entryAt(idx)
  const l = e.sets[e.sets.length - 1]
  const m = modeOf({ ...(e.target || {}), id: e.id })
  if (m === 'cardio') e.sets.push({ min: l ? l.min : (e.target.min || 20), speed: l ? l.speed : (e.target.speed || 8), done: false })
  else if (m === 'time') e.sets.push({ sec: l ? l.sec : (e.target.sec || 45), w: l ? (l.w || 0) : (e.target.weight || 0), done: false })
  else {
    const row = { w: l ? l.w : 0, r: l ? l.r : e.target.reps, done: false }
    e.sets.push(isPerSide({ ...(e.target || {}), id: e.id })
      ? (l && isSideSet(l) ? makeSideSet({ w: l.sides.L.w, r: (l.sides.L.r || 0) * 2 }) : makeSideSet(row))
      : row)
  }
  return e
}

export function removeSet(idx) {
  const e = entryAt(idx)
  if (e.sets.length > 1) e.sets.pop()
  return e
}

export function addWarmup(idx) {
  const e = entryAt(idx)
  const m = modeOf({ ...(e.target || {}), id: e.id })
  e.sets = insertWarmupRow(e.sets, m, e.target || {}, defaultIncrement(e.id, S.unit))
  return e
}

export function removeSetAt(idx, i) {
  const e = entryAt(idx)
  if (S.active.editingWorkoutId) e.sets.splice(i, 1)
  else e.sets = removeRowAt(e.sets, i)
  return e
}

/**
 * A timed hold has ended (Workout.jsx startTimed). `abandoned`: a rest displaced it, so it
 * keeps its seconds and nothing else. Otherwise the hold is logged and the set ticked.
 */
export function recordHold(idx, i, elapsed, { abandoned = false, plan = null, timerRunning = false, quiet = false } = {}) {
  const e = entryAt(idx)
  if (abandoned) {
    if (e.sets[i].planSec == null && !e.sets[i].done && plan != null) e.sets[i].planSec = plan
    e.sets[i].sec = elapsed
    return { entry: e }
  }
  e.sets[i].sec = elapsed
  delete e.sets[i].planSec
  if (!e.sets[i].done) return toggleSet(idx, i, null, { timerRunning, quiet })
  return { entry: e }
}

/**
 * Workout.jsx toggle: ticks or unticks a set (one side of a per-side set when `side` is 'L'
 * or 'R') and works out what follows. `timerRunning`: a rest is counting down right now.
 *
 * Returns `{ checked, beep, toast, complete, stopRest, rest: { sec, forIdx } | null, cur }`:
 * `complete` opens the "workout complete" sheet; `toast` is 'cardio' or 'hold'.
 */
export function toggleSet(idx, i, side = null, { timerRunning = false, quiet = false } = {}) {
  const st = need()
  const m = modeAt(idx)
  const A = st.active
  const editing = !!A.editingWorkoutId
  const units = supersetUnits(A.entries)
  const e = A.entries[idx]
  let exJustDone = false, workoutDone = false
  if (side) e.sets[i] = toggleSide(e.sets[i], side)
  else e.sets[i].done = !e.sets[i].done
  const checked = !!e.sets[i].done
  if (checked && e.sets[i].planSec != null) delete e.sets[i].planSec
  const out = { checked, beep: false, toast: null, complete: false, stopRest: false, rest: null, cur: A.cur }
  if (checked && !editing) {
    out.beep = !quiet
    const ownUnit = unitOf(units, idx)
    const unitDone = ownUnit.every(ui => A.entries[ui].sets.every(x => x.done))
    if (unitDone) workoutDone = !nextUnfinishedUnit(A.entries, supersetUnits(A.entries), idx)
    if (e.sets.every(x => x.done)) {
      exJustDone = true
      e.topW = bestWeightForEntry(e) || null
    }
  }
  if (editing) return out
  if (workoutDone) out.complete = true
  else if (exJustDone && m === 'cardio') out.toast = 'cardio'
  else if (exJustDone && m === 'time') out.toast = 'hold'

  // A past workout has no rest to time.
  const rests = !A.backfill
  if (checked) {
    if (highWater.length !== A.entries.length) rebaseline()
    const progress = setProgressHighWater(e, highWater[idx] || 0)
    highWater[idx] = progress.highWater

    const freshUnits = supersetUnits(A.entries)
    const freshUnit = freshUnits.find(u => u.includes(idx))
    const freshUnitDone = freshUnit?.every(ui => A.entries[ui].sets.every(x => x.done))
    const nextUnit = freshUnitDone ? nextUnfinishedUnit(A.entries, freshUnits, idx) : null
    const freshWorkoutDone = freshUnitDone && !nextUnit
    const restBeforeWarmup = nextUnit?.some(ui => A.entries[ui].sets.some(set => isWarmupRow(set) && !set.done))
    const restSec = restSecFor(A.entries, freshUnit || [idx], st.restSec)
    const restAfter = warmupRestSecFor(e, i, restSec)
    const startRest = () => { if (rests) out.rest = { sec: restAfter, forIdx: idx } }

    if (!progress.isNew) {
      if (!restBeforeWarmup && restOnRecheck({ timerRunning, unitDone: freshUnitDone, lastUnit: freshWorkoutDone })) startRest()
      return out
    }
    if (freshUnitDone) out.stopRest = true
    if (!freshUnit || freshUnit.length <= 1) {
      if (!restBeforeWarmup && restAfterSet({ unitDone: freshUnitDone, lastUnit: freshWorkoutDone })) startRest()
      return out
    }
    const step = supersetFlowStep(A.entries, freshUnit, idx)
    if (!step) return out
    if (step.unitDone) {
      if (nextUnit?.length && !restBeforeWarmup) startRest()
    } else {
      if (step.nextIdx != null) { A.cur = step.nextIdx; out.cur = A.cur }
      if (step.roundDone) startRest()
    }
  }
  return out
}

/** Prev/Next between exercises (supersets move as one). */
export function navigateUnit(direction) {
  const A = need().active
  if (!A || !Number.isInteger(A.cur) || A.cur < 0 || A.cur >= A.entries.length) return A?.cur ?? 0
  const units = supersetUnits(A.entries)
  const at = units.findIndex(u => u.includes(A.cur))
  const target = at < 0 ? null : units[at + direction]?.[0] ?? null
  if (target != null) A.cur = target
  return A.cur
}

export function setCurrent(idx) {
  const A = need().active
  if (A && idx >= 0 && idx < A.entries.length) A.cur = idx
  return A?.cur ?? 0
}

export function setWorkoutView(view) {
  const A = need().active
  if (A) A.workoutView = view
  return true
}

export function renameWorkout(name) {
  const A = need().active
  if (!A) return false
  const n = (name || '').trim()
  if (n) { A.name = n; A.customName = true }
  return true
}

export function setSessionNote(note) {
  const A = need().active
  if (A) A.note = note || ''
  return true
}

export function setExerciseNote(idx, note, pin = false) {
  const e = entryAt(idx)
  e.note = note || ''
  if (pin) e.notePin = true; else delete e.notePin
  return e
}

/** Workout.jsx removeActiveExercise. Returns where the rest timer's owner moved, if anywhere. */
export function removeExercise(idx) {
  const A = need().active
  if (!A || idx < 0 || idx >= A.entries.length) return false
  A.entries.splice(idx, 1)
  cleanupSg(A.entries)
  if (idx < A.cur) A.cur--
  if (A.cur >= A.entries.length) A.cur = Math.max(0, A.entries.length - 1)
  highWater.splice(idx, 1)
  return true
}

export function canMoveUnit(at, direction) {
  return canMoveActiveWorkoutUnit(need().active, at, direction)
}

/** Moves an exercise (or its superset) up or down. Returns the new index order, or null. */
export function moveUnit(at, direction) {
  const A = need().active
  if (!canMoveActiveWorkoutUnit(A, at, direction)) return null
  const moved = moveActiveWorkoutUnit(A, at, direction)
  if (!moved) return null
  highWater = moved.indices.map(index => highWater[index])
  return moved.indices
}

export function pair(first, second) {
  const A = need().active
  A.entries = pairAdjacent(A.entries, first, second)
  return true
}

export function unpair(idx) {
  const A = need().active
  A.entries = unpairSuperset(A.entries, idx)
  return true
}

export function setExerciseNoProg(idx, on) {
  setEntryNoProg(need().active, idx, on)
  return true
}

const routineKeepsOut = e => !!e?.rid && S.routines.some(r => r.id === e.rid && r.excludeFromProgression === true)
export function toggleSessionNoProg() {
  const A = need().active
  setSessionNoProg(A, !sessionNoProg(A), routineKeepsOut)
  return sessionNoProg(A)
}

/** How an exercise added to this session would open: the config sheet's starting point. */
export function addExerciseSeed(exId) {
  const st = need()
  const A = st.active
  const curRid = A?.entries?.[A.cur]?.rid
  const routine = curRid ? st.routines.find(r => r.id === curRid) : null
  return routine ? defaultConfig(exId) : freestyleConfig(sessionHistory(st), { id: exId, ...defaultConfig(exId) })
}

function builtFor(st, exId, cfg, routine, noProg) {
  const full = { ...cfg, id: exId }
  const past = sessionHistory(st)
  return routine
    ? buildPlannedEntry(past, full, routine, { noProg })
    : { target: { ...cfg }, plan: null, sets: applyIntensifierPlan(buildSets(past, full, {
      step: modeOf(full) === 'reps' ? weightIncrement(full, st.unit) : defaultIncrement(exId, st.unit), preferLast: true,
    }), full, dropGrid(st, full)) }
}

/**
 * Workout.jsx "Add exercise": inserted after the current exercise, inheriting its routine.
 * `cfg` null uses the same default the quick "+" does. Returns the new index.
 */
export function addExercise(exId, cfg = null) {
  const st = need()
  const A = st.active
  const curEntry = A.entries[A.cur]
  const curRid = curEntry?.rid
  const routine = curRid ? st.routines.find(r => r.id === curRid) : null
  const noProg = !!routine && builtOutOfProgression(curEntry, routine)
  const built = builtFor(st, exId, cfg || addExerciseSeed(exId), routine, noProg)
  const insertAt = insertionIndexAfterCurrentUnit(supersetUnits(A.entries), A.cur, A.entries.length)
  A.entries.splice(insertAt, 0, joinSessionNoProg(A, { id: exId, ...built, ...(curRid ? { rid: curRid } : {}), ...(noProg ? { noProg: true } : {}) }))
  A.cur = insertAt
  highWater.splice(insertAt, 0, 0)
  return insertAt
}

/**
 * sheets.jsx swapActiveWorkoutExercise. A logged exercise is never relabelled: the result asks
 * for confirmation (and, in a superset, `groupDisposition` 'keep' or 'detach') first.
 */
export function swapExercise(index, exId, cfg = null, opts = {}) {
  const st = need()
  const current = st.active?.entries?.[index]
  if (!current) return null
  const slotRoutine = current.rid ? st.routines.find(r => r.id === current.rid) : null
  const built = builtFor(st, exId, cfg || defaultConfig(exId), slotRoutine, builtOutOfProgression(current, slotRoutine))
  const replacement = { id: exId, ...built, ...(current.rid ? { rid: current.rid } : {}), ...(current.noProg === true ? { noProg: true } : {}) }
  const res = swapActiveExercise(st.active, index, replacement, opts)
  if (res?.inserted) highWater.splice(res.index, 0, 0)
  return res
}

/** sheets.jsx AddRoutineToSession: appends a routine's exercises to the running session. */
export function addRoutineToSession(routineId) {
  const st = need()
  const A = st.active
  const r = st.routines.find(x => x.id === routineId)
  if (!A || !r || [].concat(A.routineIds || []).includes(r.id) || !(r.ex || []).length) return false
  const entries = buildSessionEntries(sessionHistory(st), r).map(e => ({ ...e, rid: r.id }))
  A.entries.push(...entries.map(e => joinSessionNoProg(A, e)))
  A.routineIds = [...[].concat(A.routineIds || []), r.id]
  if (!A.customName) A.name = deriveSessionName(A.routineIds.map(id => st.routines.find(x => x.id === id)?.name).filter(Boolean))
  rebaseline()
  return true
}

/** A past workout's "Mark all sets done". */
export function markAllDone() {
  const A = need().active
  if (A) A.entries = markAllSetsDone(A.entries)
  rebaseline()
  return true
}

/* ------------------------------ finishing ------------------------------ */

/**
 * What finishing would mean (sheets.jsx finishWorkout): `{ done, total }`. Nothing logged asks
 * "Finish anyway?", fewer than all asks "Finish early?"; the screen decides, then calls finish.
 */
export function finishCheck() {
  const A = need().active
  if (!A) return null
  return { done: setsDoneActive(A), total: setUnitsTotal(A.entries) }
}

/**
 * sheets.jsx doFinishWorkout: files the session and returns the summary
 * `{ workout, prs, e1prs }`. Remembered weights move only for a live session; one logged into
 * the past is held against the history around it instead.
 */
export function finishWorkout(now = Date.now()) {
  const st = need()
  const A = st.active
  if (!A) return null
  const past = !!A.backfill
  const prs = []
  const e1prs = []
  if (!past) A.entries.forEach(e => {
    const loads = e.sets.filter(s => s.done && !isWarmupRow(s)).map(s => s.w).filter(w => w > 0)
    const mx = loads.length ? loads.reduce((a, b) => betterWeight(e.id, a, b)) : 0
    if (beatsWeight(e.id, mx, bestWeightFor(st, e.id))) prs.push(e.id)
    const rec = is1RMRecord(st, e.id, e)
    if (rec && !prs.includes(e.id)) e1prs.push({ id: e.id, ...rec })
  })
  const w = buildCompletedWorkout(A, {
    end: past ? backfillEnd(A) : now,
    prs,
    snapshotFor: e => EXIDX[e.id]?.custom ? exerciseMuscleSnapshot(EXIDX[e.id]) : null,
  })
  w.vol = workoutVolume(w)
  let shown = w
  if (past) {
    stampWorkout(w)
    const replaced = A.backfill.replaceId ? st.workouts.find(x => x.id === A.backfill.replaceId) : null
    const touched = [...new Set([...(replaced?.entries || []), ...w.entries].map(e => e?.id).filter(id => id != null))]
    st.workouts = rebuildPrHistory(completeBackfill(st.workouts, A, w), touched, w)
    shown = st.workouts.find(x => x === w || (w.id != null && x.id === w.id)) || w
    prs.push(...[...(shown.prs || [])])
  } else {
    w.entries.forEach(e => {
      const mx = bestWeightForEntry(e)
      if (mx > 0 && beatsWeight(e.id, mx, (st.exWeights[e.id] || {}).w || 0)) st.exWeights[e.id] = { w: mx, d: w.d }
    })
    st.workouts.push(w)
  }
  st.active = null
  highWater = []
  return { workout: clone(shown), prs, e1prs }
}
