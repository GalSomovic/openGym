// Plan, routines and the exercise settings sheet: the steps openGym's Plan screen, routine
// editor (views/Plan.jsx, views/RoutineEdit.jsx) and their sheets (sheets.jsx) take, headless.
// Same rules as actions.js: plain JSON in and out, and the profile is only changed here.
import { need } from './actions.js'
import { uid } from '../../frontend/src/lib/format.js'
import { isCardio, isBodyweightEq } from '../../frontend/src/lib/exercises.js'
import {
  supersetUnits, moveSupersetUnit, cleanupSg, defaultConfig, modeOf, isBw, isPerSide, exLine,
  MAX_PLANNED_WARMUPS,
} from '../../frontend/src/lib/history.js'
import { copyRoutine as copyOf, deleteRoutine as deleteFrom, replaceSlotExercise } from '../../frontend/src/lib/routines.js'
import { starterPlanOptions, starterPlanDays, buildStarterPlan } from '../../frontend/src/lib/starter.js'
import { policyFor, POLICIES_FOR, POLICY_NAME, POLICY_DESC, MAX_BW_SETS, defaultIncrement } from '../../frontend/src/lib/progression.js'
import { normalizeRepRange } from '../../frontend/src/lib/rep-range.js'
import { speedUnitOf } from '../../frontend/src/lib/speed.js'
import { loadOfRoutine, rankOf } from '../../frontend/src/lib/muscles.js'

const routineOf = id => {
  const r = need().routines.find(x => x.id === id)
  if (!r) throw new Error(`no routine ${id}`)
  return r
}

/* ------------------------------ routines ------------------------------ */

/** Plan.jsx addRoutine. Returns the new routine's id. */
export function addRoutine(name, emoji = 'dumbbell') {
  const r = { id: uid(), name, emoji, ex: [] }
  need().routines.push(r)
  return r.id
}

/** Plan.jsx moveRoutine: S.routines is the one order every screen reads (#142). */
export function moveRoutine(i, delta) {
  const s = need()
  const to = i + delta
  if (to < 0 || to >= s.routines.length) return false
  const [moved] = s.routines.splice(i, 1)
  s.routines.splice(to, 0, moved)
  return true
}

/** Removes a routine and every pointer to it from the week and the day changes. */
export function deleteRoutine(id) {
  deleteFrom(need(), id)
  return true
}

/** RoutineEdit "Copy routine": `suffix` is the localised "Copy". Returns the copy's id. */
export function copyRoutine(id, suffix = 'Copy') {
  const copy = copyOf(routineOf(id), suffix)
  need().routines.push(copy)
  return copy.id
}

/** An empty name falls back to `fallback` (the localised "Routine"), as the web field does. */
export function renameRoutine(id, name, fallback = 'Routine') {
  routineOf(id).name = (name || '').trim() || fallback
  return true
}

export function setRoutineEmoji(id, emoji) {
  routineOf(id).emoji = emoji
  return true
}

export function setRoutineProgression(id, policy) {
  routineOf(id).prog = policy
  return true
}

/** A deload routine's workouts never count toward progression (#294). */
export function setRoutineDeload(id, on) {
  const r = routineOf(id)
  if (on) r.excludeFromProgression = true
  else delete r.excludeFromProgression
  return true
}

/** Each routine exercise with its one-line summary ("3 × 8 · 60 kg"), for the editor. */
export function routineLines(id) {
  const s = need()
  return routineOf(id).ex.map(e => exLine(e, s.unit, speedUnitOf(s)))
}

/** The muscles a routine works, most first: the editor's "What this session hits". */
export function routineMuscles(id) {
  const load = loadOfRoutine(routineOf(id))
  return { load, worked: rankOf(load).worked }
}

/* ------------------------------ routine exercises ------------------------------ */

/** RoutineEdit "Add exercise": `cfg` null is the quick "+" default. */
export function addRoutineExercise(rid, exId, cfg = null) {
  routineOf(rid).ex.push({ id: exId, ...(cfg || defaultConfig(exId)) })
  return true
}

/**
 * Library "Plan": adds to a routine, or to a new one when `rid` is null (named `newName`).
 * Returns the routine's id.
 */
export function addToRoutine(exId, rid, cfg, newName = 'New routine') {
  const s = need()
  let r = rid ? s.routines.find(x => x.id === rid) : null
  if (!r) { r = { id: uid(), name: newName, emoji: 'dumbbell', ex: [] }; s.routines.push(r) }
  r.ex.push({ id: exId, ...(cfg || defaultConfig(exId)) })
  return r.id
}

/** The settings sheet saved: the slot keeps its exercise and its superset. */
export function updateRoutineExercise(rid, i, cfg) {
  const x = routineOf(rid).ex
  if (!x[i]) return false
  x[i] = { id: x[i].id, sg: x[i].sg, ...cfg }
  if (x[i].sg == null) delete x[i].sg
  return true
}

export function removeRoutineExercise(rid, i) {
  const x = routineOf(rid).ex
  x.splice(i, 1)
  cleanupSg(x)
  return true
}

/** Up or down one place; a superset moves as one. */
export function moveRoutineExercise(rid, i, dir) {
  const x = routineOf(rid).ex
  const reordered = moveSupersetUnit(x, i, dir)
  if (!reordered) return false
  x.splice(0, x.length, ...reordered)
  cleanupSg(x)
  return true
}

/**
 * RoutineEdit reorderRoutineUnit (drag and drop): slots are counted after the source unit is
 * taken out, so a superset is never split.
 */
export function reorderRoutineExercise(rid, sourceIndex, targetSlot) {
  const exercises = routineOf(rid).ex
  if (!exercises.length) return false
  const units = supersetUnits(exercises)
  const sourcePosition = units.findIndex(unit => unit.includes(sourceIndex))
  if (sourcePosition < 0) return false
  const remaining = units.filter((_, position) => position !== sourcePosition)
  const slot = Math.max(0, Math.min(remaining.length, Number.isFinite(targetSlot) ? Math.trunc(targetSlot) : sourcePosition))
  if (slot === sourcePosition) return false
  const source = units[sourcePosition]
  const moved = exercises.splice(source[0], source.length)
  const insertAt = remaining.slice(0, slot).reduce((count, unit) => count + unit.length, 0)
  exercises.splice(insertAt, 0, ...moved)
  cleanupSg(exercises)
  return true
}

/** The link button: supersets an exercise with the one above, or splits them. */
export function toggleSupersetLink(rid, i) {
  const ex = routineOf(rid).ex
  if (i < 1) return false
  const cur = ex[i], prev = ex[i - 1]
  if (cur.sg && prev.sg && cur.sg === prev.sg) delete cur.sg
  else { const gid = prev.sg || ('sg' + uid()); prev.sg = gid; cur.sg = gid }
  cleanupSg(ex)
  return true
}

/** What the slot would become with another exercise in it (#110), for the settings sheet. */
export function replacementFor(rid, i, exId) {
  const slot = routineOf(rid).ex[i]
  return slot ? replaceSlotExercise(slot, exId, need(), rid) : null
}

/** Puts another exercise in a slot, keeping what was set up for it; `cfg` from the sheet wins. */
export function replaceRoutineExercise(rid, i, exId, cfg = null) {
  const x = routineOf(rid).ex
  if (!x[i]) return false
  x[i] = cfg ? { id: exId, sg: x[i].sg, ...cfg } : replaceSlotExercise(x[i], exId, need(), rid)
  if (x[i].sg == null) delete x[i].sg
  return true
}

/* ------------------------------ the exercise settings sheet ------------------------------ */

/** sheets.jsx ExConfig: where the sheet opens (a slot, a seed, or the exercise's defaults). */
export function configStart(exId, existing = null, rid = null, initial = null) {
  const routine = rid ? need().routines.find(r => r.id === rid) : null
  const cfg = { ...(existing || initial || defaultConfig(exId)) }
  return policyFor({ ...cfg, id: exId }, routine, modeOf({ ...cfg, id: exId })) === 'double'
    ? { ...cfg, ...normalizeRepRange(cfg.reps, cfg.repsMin, isPerSide(cfg) ? 2 : 1) }
    : cfg
}

/**
 * What the sheet shows for a draft: which fields apply and which rule is in force. The screen
 * draws exactly what this says, so it follows openGym's sheet without re-deciding anything.
 */
export function configInfo(exId, c, rid = null) {
  const s = need()
  const routine = rid ? s.routines.find(r => r.id === rid) : null
  const cardio = isCardio(exId)
  const mode = cardio ? 'cardio' : modeOf({ ...c, id: exId })
  const bw = !cardio && isBw({ ...c, id: exId })
  const perSide = isPerSide(c)
  const policy = policyFor({ ...c, id: exId }, routine, mode)
  const step = c.inc >= 0 ? c.inc : (mode === 'time' ? 5 : defaultIncrement(exId, s.unit))
  const stride = mode === 'reps' && perSide ? 2 : 1
  const policies = POLICIES_FOR[mode] || ['off']
  return {
    cardio, mode, bw, perSide, policy,
    inheritedPolicy: policyFor({ id: exId }, routine, mode),
    policies: policies.length < 2 ? [] : policies,
    policyNames: Object.fromEntries(policies.map(p => [p, POLICY_NAME[p]])),
    policyDesc: POLICY_DESC[policy] || null,
    step,
    stepValid: policy === 'off' || (Number.isFinite(step) && step > 0),
    double: mode === 'reps' && policy === 'double',
    range: policy === 'double' ? normalizeRepRange(c.reps, c.repsMin, stride) : null,
    epleyEligible: mode === 'reps' && !bw && (policy === 'linear' || policy === 'double'),
    maxWarmups: MAX_PLANNED_WARMUPS, maxBwSets: MAX_BW_SETS,
    unit: s.unit, speedUnit: speedUnitOf(s), restPauseSec: s.restPauseSec || 15,
  }
}

/** Switching between reps and a timed hold keeps what still applies. */
export function configWithMode(exId, c, m, rid = null) {
  const routine = rid ? need().routines.find(r => r.id === rid) : null
  const next = { ...defaultConfig(exId, m), ...c, mode: m }
  return m === 'reps' && policyFor({ ...next, id: exId }, routine, 'reps') === 'double'
    ? { ...next, ...normalizeRepRange(next.reps, next.repsMin, isPerSide(next) ? 2 : 1) }
    : next
}

/** Turning "Reps per side" on rounds the target up to an even number. */
export function configWithPerSide(exId, c, on, rid = null) {
  const routine = rid ? need().routines.find(r => r.id === rid) : null
  const next = { ...c, side: on || undefined, reps: on ? Math.ceil((c.reps || 0) / 2) * 2 : c.reps }
  if (!on) delete next.side
  return policyFor({ ...next, id: exId }, routine, 'reps') === 'double'
    ? { ...next, ...normalizeRepRange(next.reps, next.repsMin, on ? 2 : 1) }
    : next
}

/** Picking a progression rule ('' follows the routine). */
export function configWithRule(exId, c, rule, rid = null) {
  const s = need()
  const routine = rid ? s.routines.find(r => r.id === rid) : null
  const mode = isCardio(exId) ? 'cardio' : modeOf({ ...c, id: exId })
  const next = { ...c, prog: rule || undefined }
  if (!rule) delete next.prog
  return policyFor({ ...next, id: exId }, routine, mode) === 'double'
    ? { ...next, ...normalizeRepRange(next.reps, next.repsMin, mode === 'reps' && isPerSide(c) ? 2 : 1) }
    : next
}

/** Picking an intensifier: '' none, 'dropset' or 'restpause', seeded like the web sheet. */
export function configWithIntensifier(c, type) {
  const st = need()
  const intensifier = !type ? undefined : type === 'dropset'
    ? { type: 'dropset', count: c.intensifier?.count || 1, pct: c.intensifier?.pct || 20 }
    : { type: 'restpause', totalReps: c.intensifier?.totalReps || c.reps || 8, restSec: c.intensifier?.restSec || st.restPauseSec || 15 }
  const next = { ...c, intensifier }
  if (!intensifier) delete next.intensifier
  return next
}

const intensifierToSave = x => (x.type === 'dropset'
  ? { ...x, count: Math.max(1, Math.round(x.count) || 0), pct: Math.max(5, Number(x.pct) || 0) }
  : x.type === 'restpause'
    ? { ...x, totalReps: Math.max(1, Math.round(x.totalReps) || 0), restSec: Math.max(5, Number(x.restSec) || 0) }
    : x)

/**
 * sheets.jsx ExConfig save: the draft as openGym stores it, or null while the progression
 * step is invalid (the web sheet's Save is disabled then).
 */
export function configToSave(exId, c, rid = null) {
  const info = configInfo(exId, c, rid)
  if (!info.stepValid) return null
  const { cardio, mode, bw, perSide, policy, double } = info
  const sets = Math.max(1, Math.round(c.sets) || (cardio ? 1 : 3))
  const prog = {}
  if (c.prog) prog.prog = c.prog
  if (c.inc > 0) prog.inc = c.inc
  if (mode === 'reps' && !bw && (policy === 'linear' || policy === 'double')) {
    const deloadFactor = Math.max(0.5, Math.min(0.95, Number(c.deloadFactor) || 0.9))
    if (deloadFactor !== 0.9) prog.deloadFactor = deloadFactor
  }
  const flags = {}
  if (bw !== isBodyweightEq(exId)) flags.bodyweight = bw
  const note = (c.note || '').trim().slice(0, 500)
  const withNote = note ? { note } : {}
  const warmupSets = Math.max(0, Math.min(MAX_PLANNED_WARMUPS, Math.round(c.warmupSets) || 0))
  const withWarmups = warmupSets ? { warmupSets } : {}
  const restSec = Math.max(0, Math.round(c.restSec) || 0)
  const withRest = restSec ? { restSec } : {}
  if (cardio) return { sets, min: Math.max(1, Math.round(c.min) || 20), speed: Math.max(0, c.speed || 8), ...withNote, ...withRest }
  if (mode === 'time') return { sets, mode: 'time', sec: Math.max(1, Math.round(c.sec) || 45), weight: Math.max(0, c.weight || 0), ...flags, ...prog, ...withNote, ...withWarmups, ...withRest }
  const typed = Math.max(1, Math.round(c.reps) || 10)
  const stride = perSide ? 2 : 1
  let reps = perSide ? Math.ceil(typed / stride) * stride : typed
  let range = null
  if (double) {
    range = normalizeRepRange(reps, c.repsMin, stride)
    reps = range.reps
  }
  const out = { sets, mode: 'reps', reps, weight: Math.max(0, c.weight || 0), ...flags, ...(perSide ? { side: true } : {}), ...prog, ...withNote, ...withWarmups, ...withRest }
  if (double) out.repsMin = range.repsMin
  if (bw && !(out.weight > 0) && c.repsMax > 0) out.repsMax = Math.max(reps, Math.round(c.repsMax))
  if (c.intensifier && c.intensifier.type) out.intensifier = intensifierToSave(c.intensifier)
  return out
}

/* ------------------------------ the week ------------------------------ */

/** An empty weekday set to one routine, or to rest (null). */
export function assignDay(day, rid) {
  const s = need()
  if (rid) s.week[day] = [rid]; else delete s.week[day]
  return true
}

/** The ＋ on a planned weekday: another routine on the same day. */
export function addRoutineToDay(day, rid) {
  const s = need()
  const ids = [].concat(s.week[day] || [])
  if (ids.includes(rid)) return false
  s.week[day] = [...ids, rid]
  return true
}

/** Takes one routine off a weekday; an emptied day is dropped, never stored as []. */
export function removeFromDay(day, rid) {
  const s = need()
  const next = [].concat(s.week[day] || []).filter(id => id !== rid)
  if (next.length) s.week[day] = next; else delete s.week[day]
  return true
}

/** One date changed: a routine id, 'rest', or '' back to the weekly plan. */
export function setDayOverride(iso, value) {
  const s = need()
  if (!value) delete s.dayPlan[iso]; else s.dayPlan[iso] = value
  return true
}

/* ------------------------------ starter plans ------------------------------ */

/** `[{ id, days, weekdays }]`: the plans and the weekdays each would claim. */
export function starterPlans() {
  return starterPlanOptions().map(o => ({ ...o, weekdays: starterPlanDays(o.id) }))
}

/** Whether loading a plan would replace a routine on one of its days (asks first if so). */
export function starterPlanConflicts(id) {
  const s = need()
  const days = starterPlanDays(id) || []
  return days.some(day => [].concat(s.week[day] || []).some(rid => s.routines.some(r => r.id === rid)))
}

/** Adds the plan's routines and puts them on its weekdays; nothing else is touched. */
export function loadStarterPlan(id) {
  const plan = buildStarterPlan(id)
  if (!plan) return false
  const s = need()
  s.routines.push(...plan.routines)
  plan.schedule.forEach(({ day, routineId }) => { s.week[day] = [routineId] })
  return true
}

