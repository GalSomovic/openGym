// Plan intelligence (GymFree addition, not in openGym): how long a routine takes, how hard it
// is, what would improve it or the week, and a cool-down to finish it. Deterministic and
// on-device, like planner.js. Every rule cites apple/research/TRAINING.md (§ numbers); numbers
// the research does not give are marked **engineering default** (§0, §14.2: e.g. the
// minutes-per-set constants are engineering defaults, to be tuned).
//
// Everything here only reads the profile, except `applySuggestion` and `dismissInsight`.
// Suggestions are plain JSON describing one change; the screen shows them and, on a tap, hands
// the same object back to `applySuggestion`.
import { need } from './actions.js'
import { EXIDX } from '../../frontend/src/lib/exercises.js'
import { loadOfRoutine, levelsOf, rankOf, musclesOf } from '../../frontend/src/lib/muscles.js'
import { modeOf, supersetUnits, defaultConfig, cleanupSg } from '../../frontend/src/lib/history.js'
import { activeProfile, exAvailable } from '../../frontend/src/lib/equipment.js'
import { uid } from '../../frontend/src/lib/format.js'
import { pickExercise } from './planner.js'
import { isStretch, pickStretches, stretchConfig } from './stretches.js'

const routineOf = (s, id) => {
  const r = s.routines.find(x => x.id === id)
  if (!r) throw new Error(`no routine ${id}`)
  return r
}
const round1 = v => Math.round(v * 10) / 10
const setsOf = e => Math.max(1, Math.round(e.sets) || 1)
/** Training, as opposed to cardio or a stretch: what set counts and muscle loads are about. */
const isTraining = e => !isStretch(e.id) && modeOf(e) !== 'cardio'
/** Fractional sets per muscle (§2.1), training only. openGym's musclesOf counts a supporting
 *  muscle at 0.4 of a set, a little under §2.1's 0.5, so these counts lean conservative. */
const trainingLoad = r => loadOfRoutine({ ex: (r.ex || []).filter(isTraining) })

/* ------------------------------ how long a routine takes ------------------------------ */

// Engineering defaults (§14.2). Checked against §13.2 step 6: a 10-rep set with the 90 s rest
// of §2.6 comes to 15 + 30 + 90 s ≈ 2.25 min, close to its 2.5 min per set.
const SEC_PER_REP = 3        // one controlled rep
const SET_SETUP = 15         // getting into position, unracking
const HOLD_SETUP = 5         // getting into a timed hold
const SWITCH = 30            // moving on to the next exercise
const SUPERSET_SWITCH = 10   // between the exercises of a superset
const WARMUP_SET_REPS = 6    // a ramp-up set (§10: about 8, 5, then 2–3 reps)
const GENERAL_WARMUP = 5 * 60  // §10: 3–5 min of easy general movement first
const DEFAULT_REST = 90      // §2.6, and openGym's own default (defaults.gen.js restSec)

const defaultRest = s => (Number.isFinite(s.restSec) ? Math.max(0, s.restSec) : DEFAULT_REST)
const restOf = (e, s) => (e.restSec > 0 ? e.restSec : defaultRest(s))

/** Seconds one work set takes, rest not included. */
function workSec(e) {
  const mode = modeOf(e)
  if (mode === 'cardio') return (e.min || 20) * 60
  if (mode === 'time') return (e.sec || 45) + HOLD_SETUP
  const reps = e.reps || 10
  let sec = reps * SEC_PER_REP + SET_SETUP
  const x = e.intensifier
  if (x?.type === 'dropset') sec += (x.count || 1) * (Math.ceil(reps * 0.6) * SEC_PER_REP + 10)
  if (x?.type === 'restpause') sec += 2 * (x.restSec || 15) + Math.max(0, (x.totalReps || reps) - reps) * SEC_PER_REP
  return sec
}

/**
 * How long a routine takes, in seconds and whole minutes: every set's work (reps × 3 s, the
 * hold, or the cardio minutes), the rest after it (the exercise's own or the profile's), the
 * planned warm-up sets, and 5 minutes of general warm-up. A superset rests once per round, for
 * as long as its longest rest (openGym's supersetFlow restSecFor).
 */
export function durationOf(r, s = need()) {
  const ex = (r && r.ex) || []
  const out = { min: 0, sec: 0, work: 0, rest: 0, warmup: 0 }
  if (!ex.length) return out
  const units = supersetUnits(ex)
  units.forEach((unit, u) => {
    const members = unit.map(i => ex[i])
    const rounds = Math.max(...members.map(setsOf))
    const unitRest = Math.max(...members.map(e => restOf(e, s)))
    for (const e of members) {
      const n = Math.max(0, Math.min(5, Math.round(e.warmupSets) || 0))
      out.warmup += n * (WARMUP_SET_REPS * SEC_PER_REP + SET_SETUP + (e.warmupRestSec > 0 ? e.warmupRestSec : restOf(e, s)))
    }
    for (let k = 0; k < rounds; k++) {
      members.filter(e => setsOf(e) > k).forEach((e, j) => { out.work += workSec(e) + (j ? SUPERSET_SWITCH : 0) })
      const lastOfRoutine = u === units.length - 1 && k === rounds - 1
      if (!lastOfRoutine) out.rest += unitRest + (k === rounds - 1 ? SWITCH : 0)
    }
  })
  // The general warm-up is skipped when the session opens with cardio (that is the warm-up) or
  // is nothing but stretches.
  if (ex.some(isTraining) && modeOf(ex[0]) !== 'cardio') out.warmup += GENERAL_WARMUP
  out.sec = out.work + out.rest + out.warmup
  out.min = Math.round(out.sec / 60)
  return out
}

/** The planned week: routines on each weekday added up (date changes are not counted). */
export function weekSummary() {
  const s = need()
  let sec = 0, sessions = 0
  const days = []
  for (const [day, ids] of Object.entries(s.week || {})) {
    const rs = [].concat(ids || []).map(id => s.routines.find(r => r.id === id)).filter(Boolean)
    if (!rs.length) continue
    days.push(Number(day))
    sessions += rs.length
    for (const r of rs) sec += durationOf(r, s).sec
  }
  return { min: Math.round(sec / 60), sessions, days: days.sort((a, b) => a - b) }
}

/* ------------------------------ how hard a routine is ------------------------------ */

export const LEVELS = ['light', 'moderate', 'hard', 'veryHard']
const SESSION_CAP = 10    // §2.2: ≤10 fractional sets per muscle per session
const MAX_EXERCISES = 8   // §13.2 step 6: max ~8 exercises a session (complexity, §9)
const MIN_SETS = 6        // engineering default: under the smallest preset session (P01/P12, 8 sets, §14)

/**
 * A routine's difficulty from its hard sets, its length and its busiest muscle:
 *   minutes: <30 light, <60 moderate, ≤75 hard, >75 very hard (§14's sessions run 25–75 min;
 *            §9: longer sessions predict dropout)
 *   sets:    <10 light, ≤18 moderate, ≤25 hard, >25 very hard (≈ §13.2's sets that fit 25,
 *            45, 60 and 75 minutes at 2.5 min a set: an engineering default)
 * whichever is higher. A muscle over §2.2's per-session cap, or more than 8 exercises, makes it
 * at least hard and "too much"; fewer than 6 hard sets is "too little". Cardio and stretches
 * are not hard sets. `level` is null for a routine with nothing to judge.
 */
export function difficultyOf(r, s = need()) {
  const training = (r.ex || []).filter(isTraining)
  const minutes = durationOf(r, s).min
  const sets = training.reduce((n, e) => n + setsOf(e), 0)
  const base = { level: null, score: -1, sets, exercises: training.length, minutes, over: [], top: null, tooMuch: false, tooLittle: false }
  if (!training.length) return base
  const load = trainingLoad(r)
  const ranked = rankOf(load).worked
  const over = ranked.filter(m => load[m] > SESSION_CAP).map(m => ({ muscle: m, sets: round1(load[m]) }))
  const byTime = minutes < 30 ? 0 : minutes < 60 ? 1 : minutes <= 75 ? 2 : 3
  const bySets = sets < 10 ? 0 : sets <= 18 ? 1 : sets <= 25 ? 2 : 3
  let score = Math.max(byTime, bySets)
  const crowded = training.length > MAX_EXERCISES
  if (over.length || crowded) score = Math.max(score, 2)
  const tooMuch = score === 3 || over.length > 0 || crowded
  return {
    ...base, level: LEVELS[score], score, over,
    top: ranked.length ? { muscle: ranked[0], sets: round1(load[ranked[0]]) } : null,
    tooMuch, tooLittle: !tooMuch && sets < MIN_SETS,
  }
}

/** Time and difficulty of every routine, for the Plan list: `{ [id]: { min, level } }`. */
export function routineSummaries() {
  const s = need()
  return Object.fromEntries(s.routines.map(r => [r.id, { min: durationOf(r, s).min, level: difficultyOf(r, s).level }]))
}

/* ------------------------------ equipment and level ------------------------------ */

/**
 * Settings' equipment in the planner's terms (planner.js pickExercise): no filter is a full
 * gym; otherwise a barbell plus cables or machines counts as a gym (same rule as the Swift
 * PlanAnswers that fills "Make me a plan").
 */
export function plannerEquipment(s = need()) {
  const p = activeProfile(s)
  if (!p) return ['gym', 'db', 'bench', 'band', 'bar', 'table']
  const has = new Set(p.equipment || [])
  const gym = has.has('barbell') && (has.has('cable') || has.has('leverage machine'))
  return [gym && 'gym', has.has('dumbbell') && 'db', gym && 'bench',
    (has.has('band') || has.has('resistance band')) && 'band', gym && 'bar'].filter(Boolean)
}

/**
 * The lifter's level for picking exercise variations (§5.4): what "Make me a plan" was told,
 * or else the training history (§13.1's bands: under 6 months novice, 6 months–2 years
 * intermediate). Fewer than 40 logged workouts is novice whatever the span (engineering default).
 */
export function userLevel(s = need()) {
  if (s.gfPlan?.level) return s.gfPlan.level
  const dates = (s.workouts || []).map(w => w.d).filter(Boolean).sort()
  if (dates.length < 40) return 'novice'
  const months = (Date.parse(dates[dates.length - 1]) - Date.parse(dates[0])) / (30.44 * 864e5)
  return months >= 24 ? 'advanced' : months >= 6 ? 'intermediate' : 'novice'
}

// Muscle → planner slots that train it directly (§13.3's substitution table, read backwards).
const MUSCLE_SLOTS = {
  chest: ['hPush'], 'upper-back': ['hPull', 'vPull'], deltoids: ['vPush', 'latDelt'],
  biceps: ['biceps'], triceps: ['triceps'], abs: ['core'],
  quadriceps: ['knee', 'singleLeg'], hamstring: ['legCurl', 'hinge'], gluteal: ['hinge', 'singleLeg'],
  calves: ['calves'],
}
const ACCESSORY_SLOTS = new Set(['latDelt', 'biceps', 'triceps', 'calves', 'core', 'legCurl'])
const UPPER = new Set(['trapezius', 'deltoids', 'chest', 'upper-back', 'serratus', 'biceps', 'triceps', 'forearm'])
const LOWER = new Set(['gluteal', 'quadriceps', 'hamstring', 'adductors', 'hip-flexors', 'calves', 'tibialis'])
const regionOf = m => (UPPER.has(m) ? 'upper' : LOWER.has(m) ? 'lower' : 'core')

/** The best exercise for a slot that the equipment allows, skipping `exclude`. */
function pickFor(slot, s, eq, level, exclude) {
  const accept = id => !exclude.has(id) && exAvailable(s, EXIDX[id])
  return pickExercise(slot, eq, level, accept) || pickExercise(slot, [], level, accept)
}

/**
 * A routine slot for a picked exercise. §2.4: 8–12 reps for compounds (novices' ACSM range,
 * inside the 6–12 for everyone) and 10–15 for isolation; §2.6: 90 s rest, 60 s for isolation
 * and bodyweight holds; §3.1 double progression works off the range.
 */
function slotConfig(slot, c, sets, level) {
  if (c.mode === 'time') return { id: c.id, ...defaultConfig(c.id, 'time'), sets, sec: level === 'novice' ? 20 : 30, restSec: 60 }
  const acc = ACCESSORY_SLOTS.has(slot)
  return { id: c.id, ...defaultConfig(c.id, 'reps'), sets, reps: acc ? 15 : 12, repsMin: acc ? 10 : 8, restSec: acc ? 60 : 90 }
}

/* ------------------------------ the week: free days ------------------------------ */

const plannedDays = s => Object.entries(s.week || {})
  .filter(([, ids]) => [].concat(ids || []).some(id => s.routines.some(r => r.id === id))).map(([d]) => Number(d))
const freeDays = s => { const used = new Set(plannedDays(s)); return [0, 1, 2, 3, 4, 5, 6].filter(d => !used.has(d)) }
const gap = (a, b) => { const d = Math.abs(a - b) % 7; return Math.min(d, 7 - d) }
const daysOf = (s, rid) => Object.entries(s.week || {}).filter(([, ids]) => [].concat(ids || []).includes(rid)).map(([d]) => Number(d))
// Monday first, as a tie-break (1 … 6, then Sunday).
const mondayFirst = d => (d + 6) % 7

/** The free weekday furthest from `near` (a day of rest in between where possible). */
function freeDayAwayFrom(s, near) {
  const free = freeDays(s)
  if (!free.length || !near.length) return null
  return free.slice().sort((a, b) =>
    Math.min(...near.map(n => gap(b, n))) - Math.min(...near.map(n => gap(a, n))) || mondayFirst(a) - mondayFirst(b))[0]
}

/** `n` free weekdays spread as far apart as possible (§2.3: twice a week beats once). */
function spreadFreeDays(s, n) {
  const free = freeDays(s).sort((a, b) => mondayFirst(a) - mondayFirst(b))
  if (free.length <= 1 || n <= 1) return free.slice(0, Math.min(n, free.length))
  let best = null
  for (let i = 0; i < free.length; i++) {
    for (let j = i + 1; j < free.length; j++) {
      const g = gap(free[i], free[j])
      if (!best || g > best.g) best = { g, days: [free[i], free[j]] }
    }
  }
  return best.days
}

/* ------------------------------ one routine: fixes and a cool-down ------------------------------ */

/**
 * How to split a long routine in two (§2.2: spread volume over more sessions; §13.2 step 6): by
 * upper and lower body when each has at least two exercises, else into halves by sets. Supersets
 * stay whole; core work goes with the smaller half, stretches with the body part they stretch.
 * `keep` and `move` are indexes into the routine; together they are every exercise.
 */
export function splitPlan(r) {
  const ex = r.ex || []
  if (ex.filter(isTraining).length < 4) return null
  const units = supersetUnits(ex).map(idx => {
    const load = loadOfRoutine({ ex: idx.map(i => ex[i]) })
    const by = { upper: 0, lower: 0, core: 0 }
    for (const [m, v] of Object.entries(load)) by[regionOf(m)] += v
    const region = by.upper >= by.lower && by.upper >= by.core ? 'upper' : by.lower >= by.core ? 'lower' : 'core'
    return { idx, region, training: idx.some(i => isTraining(ex[i])), sets: idx.reduce((n, i) => n + (isTraining(ex[i]) ? setsOf(ex[i]) : 0), 0) }
  })
  const trainingUnits = units.filter(u => u.training)
  const upper = trainingUnits.filter(u => u.region === 'upper')
  const lower = trainingUnits.filter(u => u.region === 'lower')
  const keep = [], move = []
  let by
  if (upper.length >= 2 && lower.length >= 2) {
    by = 'upperLower'
    const stays = trainingUnits[0].region === 'core' ? (upper.length >= lower.length ? 'upper' : 'lower')
      : trainingUnits[0].region
    const goes = stays === 'upper' ? 'lower' : 'upper'
    const setsIn = region => units.filter(u => u.training && u.region === region).reduce((n, u) => n + u.sets, 0)
    const coreTo = setsIn(stays) <= setsIn(goes) ? keep : move
    for (const u of units) {
      const to = u.region === 'core' ? coreTo : u.region === stays ? keep : move
      to.push(...u.idx)
    }
    return { by, moveRegion: goes, keep, move }
  }
  by = 'halves'
  const total = trainingUnits.reduce((n, u) => n + u.sets, 0)
  let acc = 0
  for (const u of units) {
    // Stretches (no training sets) follow whatever came just before them.
    const second = u.training ? acc >= total / 2 : move.length > 0
    ;(second ? move : keep).push(...u.idx)
    acc += u.sets
  }
  if (!keep.some(i => isTraining(ex[i])) || !move.some(i => isTraining(ex[i]))) return null
  return { by, moveRegion: null, keep, move }
}

/** The exercise to take one set from: on the over-worked muscle if there is one, else the
 *  exercise with the most sets (ties: the later one, usually an accessory). */
function dropSetFix(r, diff) {
  const muscle = diff.over[0]?.muscle || null
  const candidates = (r.ex || []).map((e, index) => ({ e, index }))
    .filter(({ e }) => isTraining(e) && setsOf(e) >= 3)
    .filter(({ e }) => !muscle || (musclesOf(EXIDX[e.id]) || {})[muscle] >= 1)
  if (!candidates.length) return null
  const pick = candidates.reduce((a, b) => (setsOf(b.e) >= setsOf(a.e) ? b : a))
  return { id: 'dropSet', group: 'tooMuch', type: 'dropSet', rid: r.id, index: pick.index, exId: pick.e.id,
    from: setsOf(pick.e), to: setsOf(pick.e) - 1, muscle }
}

function tooMuchFixes(r, diff, s) {
  const out = []
  // Splitting is for a session too long or too busy; one muscle over the cap only needs a set
  // less (§2.2).
  const split = diff.score === 3 || diff.exercises > MAX_EXERCISES ? splitPlan(r) : null
  if (split) {
    const a = durationOf({ ex: split.keep.map(i => r.ex[i]) }, s).min
    const b = durationOf({ ex: split.move.map(i => r.ex[i]) }, s).min
    out.push({ id: 'split', group: 'tooMuch', type: 'split', rid: r.id, by: split.by, moveRegion: split.moveRegion,
      keep: split.keep, move: split.move, minutes: [a, b], day: freeDayAwayFrom(s, daysOf(s, r.id)) })
  }
  const drop = dropSetFix(r, diff)
  if (drop) out.push(drop)
  return out
}

function tooLittleFixes(r, diff, s) {
  const out = []
  const ex = r.ex || []
  const more = ex.map((e, i) => (isTraining(e) && setsOf(e) < 4 ? i : -1)).filter(i => i >= 0)
  if (more.length) out.push({ id: 'addSets', group: 'tooLittle', type: 'addSets', rid: r.id, indexes: more })
  // An exercise for the biggest muscle this routine leaves out, in its own part of the body.
  const load = trainingLoad(r)
  const by = { upper: 0, lower: 0 }
  for (const [m, v] of Object.entries(load)) if (regionOf(m) !== 'core') by[regionOf(m)] += v
  const order = by.lower > 2 * by.upper ? ['quadriceps', 'hamstring', 'gluteal', 'calves']
    : by.upper > 2 * by.lower ? ['chest', 'upper-back', 'deltoids', 'biceps', 'triceps']
      : ['quadriceps', 'chest', 'upper-back', 'hamstring', 'deltoids', 'gluteal']
  const eq = plannerEquipment(s), level = userLevel(s)
  const have = new Set(ex.map(e => e.id))
  for (const muscle of order) {
    if ((load[muscle] || 0) >= 1) continue
    for (const slot of MUSCLE_SLOTS[muscle]) {
      const c = pickFor(slot, s, eq, level, have)
      if (c) {
        out.push({ id: 'addExercise', group: 'tooLittle', type: 'addExercise', rid: r.id, muscle, ex: [slotConfig(slot, c, 3, level)] })
        return out
      }
    }
  }
  return out
}

/**
 * A cool-down for a routine (§10: static stretching after lifting, never before): one stretch
 * for each of its most-worked muscles, 2–4 of them, as timed holds at the end. Null when the
 * routine has no lifting, already has two stretches, or nothing fits.
 */
export function cooldownFor(r, s = need()) {
  const ex = r.ex || []
  const training = ex.filter(isTraining)
  if (!training.length || ex.filter(e => isStretch(e.id)).length >= 2) return null
  const worked = rankOf(trainingLoad(r)).worked
  const count = training.length <= 2 ? 2 : worked.length >= 6 ? 4 : 3
  const ok = id => exAvailable(s, EXIDX[id])
  const have = ex.map(e => e.id)
  let ids = pickStretches(worked, count, have, ok)
  // Too few muscles with a stretch of their own (say, only forearms): child's pose suits most.
  if (ids.length < 2) ids = [...ids, ...pickStretches(['upper-back', 'hamstring'], 2 - ids.length, [...have, ...ids], ok)]
  if (ids.length < 2) return null
  const list = ids.map(id => ({ id, ...stretchConfig(id) }))
  return { id: 'cooldown', group: 'cooldown', type: 'cooldown', rid: r.id, ex: list, minutes: Math.max(1, durationOf({ ex: list }, s).min) }
}

/**
 * Everything the routine editor shows about a routine: its time, its difficulty, and the
 * optional fixes and cool-down not dismissed for it.
 */
export function routineInsights(rid) {
  const s = need()
  const r = routineOf(s, rid)
  const duration = durationOf(r, s)
  const difficulty = difficultyOf(r, s)
  const dismissed = new Set((s.gfDismissed || {})[rid] || [])
  const suggestions = [
    ...(difficulty.tooMuch && !dismissed.has('tooMuch') ? tooMuchFixes(r, difficulty, s) : []),
    ...(difficulty.tooLittle && !dismissed.has('tooLittle') ? tooLittleFixes(r, difficulty, s) : []),
  ]
  const cooldown = dismissed.has('cooldown') ? null : cooldownFor(r, s)
  return { minutes: duration.min, duration, difficulty, suggestions, cooldown }
}

/* ------------------------------ the whole plan ------------------------------ */

// The muscles the plan check looks at, in priority order: §14's major muscles (chest, back,
// quads, hamstrings/glutes, delts) and core, then arms and calves, which §14 says are mostly
// reached through indirect work.
const REVIEW = ['quadriceps', 'chest', 'upper-back', 'hamstring', 'gluteal', 'deltoids', 'abs', 'biceps', 'triceps', 'calves']
const MAJOR = new Set(['quadriceps', 'chest', 'upper-back', 'hamstring', 'gluteal', 'deltoids', 'abs'])
const MIN_WEEKLY = 4      // §2.7 / §1 row 4: about 4 sets per muscle a week is the minimum dose
const MIN_ACCESSORY = 2   // engineering default: arms and calves get indirect work too (§14)
const MAX_WEEKLY = 20     // §2.1: never prescribe more than 20 fractional sets a week
const FOCUS = { core: ['Core', 'abs'], lower: ['Legs', 'legs'], upper: ['Upper body', 'arm'], mixed: ['Extra work', 'figureStrength'] }

/**
 * A check of the planned week and a few optional fixes (§2.1–2.3):
 *   checks: muscles with under 4 fractional sets a week (2 for arms and calves), or shaded at
 *           most 1 of 4 on the week's map (`plan.weekMuscles`); over 20 a week; or a major
 *           muscle worked on only one day (§2.3: at least twice a week).
 *   suggestions: a short new routine for the weakest muscles on one or two free days, and
 *           exercises for a muscle added to the routine that already trains that part of the
 *           body. Exercises come from planner.js's slots, for the equipment in Settings and
 *           the lifter's level, so nothing needs equipment that isn't there.
 */
export function improvePlan() {
  const s = need()
  const eq = plannerEquipment(s), level = userLevel(s)
  const loads = {}
  const loadFor = r => (loads[r.id] ||= trainingLoad(r))
  const weekly = {}, days = {}, hitOn = {}
  const scheduled = new Set()
  for (const [day, ids] of Object.entries(s.week || {})) {
    const dayLoad = {}
    for (const id of [].concat(ids || [])) {
      const r = s.routines.find(x => x.id === id)
      if (!r) continue
      scheduled.add(r.id)
      for (const [m, v] of Object.entries(loadFor(r))) dayLoad[m] = (dayLoad[m] || 0) + v
    }
    for (const [m, v] of Object.entries(dayLoad)) {
      weekly[m] = (weekly[m] || 0) + v
      // A day counts as training a muscle from about one direct set (§2.3 counts sessions).
      if (v >= 1) { days[m] = (days[m] || 0) + 1; (hitOn[m] ||= []).push(Number(day)) }
    }
  }
  if (!scheduled.size) return { checks: [], suggestions: [], level, equipment: eq, scheduled: 0 }
  const levels = levelsOf(weekly)
  const checks = REVIEW.map(muscle => {
    const sets = round1(weekly[muscle] || 0), d = days[muscle] || 0, major = MAJOR.has(muscle)
    const low = sets < (major ? MIN_WEEKLY : MIN_ACCESSORY) || (major && levels[muscle] <= 1)
    const issue = low ? 'low' : sets > MAX_WEEKLY ? 'high' : major && d < 2 ? 'once' : null
    return { muscle, sets, days: d, level: levels[muscle] || 0, issue }
  }).filter(c => c.issue)

  const suggestions = []
  const lows = checks.filter(c => c.issue === 'low').map(c => c.muscle)

  // 1. A short routine for the weakest muscles, twice a week on free days (§2.3), two sets an
  //    exercise: with two days that is §2.7's four sets a week.
  const free = spreadFreeDays(s, 2)
  if (lows.length && free.length) {
    const chosen = [], have = new Set()
    const take = (slot, muscle) => {
      const c = pickFor(slot, s, eq, level, have)
      if (!c) return
      have.add(c.id)
      chosen.push({ muscle, cfg: slotConfig(slot, c, 2, level) })
    }
    // One exercise for each of the three weakest muscles, then a second (another slot, or
    // another exercise for the same slot) until there are three: one gap, say core, gets a
    // whole short core routine.
    const queue = [
      ...lows.slice(0, 3).map(m => [MUSCLE_SLOTS[m][0], m]),
      ...lows.map(m => [MUSCLE_SLOTS[m][1] || MUSCLE_SLOTS[m][0], m]),
      ...lows.map(m => [MUSCLE_SLOTS[m][0], m]),
    ]
    for (const [slot, m] of queue) if (chosen.length < 3) take(slot, m)
    if (chosen.length >= 2) {
      const regions = new Set(chosen.map(c => regionOf(c.muscle)))
      const focus = regions.size > 1 ? 'mixed' : [...regions][0]
      const ex = chosen.map(c => c.cfg)
      suggestions.push({ id: 'newRoutine', type: 'addRoutine', focus, name: FOCUS[focus][0], emoji: FOCUS[focus][1],
        muscles: [...new Set(chosen.map(c => c.muscle))], ex, days: free, minutes: durationOf({ ex }, s).min })
    }
  }

  // 2. Exercises for one muscle, added to the planned routine that already works that part of
  //    the body most (for a muscle trained once a week, a routine on another day), keeping it
  //    under §2.2's per-session cap.
  const targets = [...lows, ...checks.filter(c => c.issue === 'once').map(c => c.muscle)]
  for (const muscle of targets) {
    if (suggestions.filter(x => x.type === 'appendExercises').length >= 2) break
    const once = !lows.includes(muscle)
    const region = regionOf(muscle)
    const options = s.routines.filter(r => scheduled.has(r.id))
      .filter(r => !once || !daysOf(s, r.id).some(d => (hitOn[muscle] || []).includes(d)))
      .map(r => {
        const load = loadFor(r)
        const score = Object.entries(load).reduce((n, [m, v]) => n + (regionOf(m) === region ? v : 0), 0)
        return { r, load, score }
      })
      .filter(o => o.score > 0 && (o.load[muscle] || 0) + 3 <= SESSION_CAP)
      .sort((a, b) => b.score - a.score)
    const target = options[0]
    if (!target) continue
    const have = new Set(target.r.ex.map(e => e.id))
    const sets = MAJOR.has(muscle) ? 3 : 2
    const ex = []
    for (const slot of MUSCLE_SLOTS[muscle].slice(0, once ? 1 : 2)) {
      const c = pickFor(slot, s, eq, level, have)
      if (c) { have.add(c.id); ex.push(slotConfig(slot, c, sets, level)) }
    }
    if (!ex.length) continue
    const before = durationOf(target.r, s).sec
    const after = durationOf({ ex: [...target.r.ex, ...ex] }, s).sec
    suggestions.push({ id: `append:${muscle}`, type: 'appendExercises', rid: target.r.id, routineName: target.r.name,
      muscle, issue: once ? 'once' : 'low', ex, minutes: Math.max(1, Math.round((after - before) / 60)) })
  }
  return { checks, suggestions, level, equipment: eq, scheduled: scheduled.size }
}

/* ------------------------------ applying and dismissing ------------------------------ */

function addToDay(s, day, rid) {
  const ids = [].concat(s.week[day] || [])
  if (!ids.includes(rid)) s.week[day] = [...ids, rid]
}

/**
 * Applies one suggestion from `routineInsights` or `improvePlan`. `name` is the localised name
 * for a routine it creates. Returns the id of the routine it changed or created, or null when
 * the routine changed since the suggestion was made and it no longer fits.
 */
export function applySuggestion(sug, name = null) {
  const s = need()
  const copy = list => [].concat(list || []).map(e => ({ ...e }))
  switch (sug.type) {
    case 'addRoutine': {
      const id = uid()
      s.routines.push({ id, name: name || sug.name, emoji: sug.emoji || 'dumbbell', prog: 'double', ex: copy(sug.ex) })
      for (const d of sug.days || []) addToDay(s, d, id)
      return id
    }
    case 'appendExercises':
    case 'addExercise':
    case 'cooldown': {
      const r = routineOf(s, sug.rid)
      r.ex.push(...copy(sug.ex))
      return r.id
    }
    case 'addSets': {
      const r = routineOf(s, sug.rid)
      for (const i of sug.indexes || []) if (r.ex[i]) r.ex[i].sets = Math.min(10, setsOf(r.ex[i]) + 1)
      return r.id
    }
    case 'dropSet': {
      const r = routineOf(s, sug.rid)
      const e = r.ex[sug.index]
      if (!e || e.id !== sug.exId || setsOf(e) < 2) return null
      e.sets = setsOf(e) - 1
      return r.id
    }
    case 'split': {
      const r = routineOf(s, sug.rid)
      // Worked out again from the routine as it is now, so an edit since cannot lose an exercise.
      const plan = splitPlan(r)
      if (!plan) return null
      const moved = plan.move.map(i => r.ex[i])
      r.ex = plan.keep.map(i => r.ex[i])
      cleanupSg(r.ex)
      cleanupSg(moved)
      const fallback = plan.moveRegion ? `${r.name} · ${plan.moveRegion === 'lower' ? 'Lower' : 'Upper'}` : `${r.name} · 2`
      const twin = { id: uid(), name: name || fallback, emoji: r.emoji, ex: moved }
      if (r.prog) twin.prog = r.prog
      if (r.excludeFromProgression) twin.excludeFromProgression = true
      s.routines.splice(s.routines.indexOf(r) + 1, 0, twin)
      if (sug.day != null && freeDays(s).includes(sug.day)) addToDay(s, sug.day, twin.id)
      return twin.id
    }
    default:
      return null
  }
}

/**
 * Hides one kind of suggestion for a routine for good: 'tooMuch', 'tooLittle' or 'cooldown'.
 * Kept in the profile (`gfDismissed`), so a backup carries it; deleted routines are pruned.
 */
export function dismissInsight(rid, group) {
  const s = need()
  const next = {}
  for (const [id, list] of Object.entries(s.gfDismissed || {})) if (s.routines.some(r => r.id === id)) next[id] = list
  next[rid] = [...new Set([...(next[rid] || []), group])]
  s.gfDismissed = next
  return true
}
