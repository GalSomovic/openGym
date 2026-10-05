// Plan builder (GymFree addition, not in openGym): turns a short questionnaire into a weekly
// plan of ordinary routines. Deterministic and on-device; every rule comes from
// apple/research/TRAINING.md (section numbers in comments), where each one is tiered by
// evidence. Presets P01–P12 are its §14 matrix, filled with exercises the user can do with the
// equipment they have.
import { need } from './actions.js'
import { EXIDX } from '../../frontend/src/lib/exercises.js'
import { uid } from '../../frontend/src/lib/format.js'

/* ------------------------------ slots → exercises (§13.3) ------------------------------ */

// What each candidate needs: gym (barbell, cables, machines), db (dumbbells), bench, band,
// bar (pull-up bar), table (sturdy table or low bar to row under). Nothing = bodyweight.
// Bodyweight candidates (no `needs`) are a ladder, easiest first, picked by level (§5.4).
const SLOTS = {
  knee: [
    { id: '0043', needs: ['gym'] }, { id: '0739', needs: ['gym'] },
    { id: '1760', needs: ['db'] },
    { id: '1004', needs: ['band'] },
    { id: 'gf-squat' }, { id: 'gf-bulgarian-split-squat' }, { id: 'gf-bulgarian-split-squat' },
  ],
  hinge: [
    { id: '0085', needs: ['gym'] }, { id: '0811', needs: ['gym'] },
    { id: '1459', needs: ['db'] },
    { id: 'gf-band-romanian-deadlift', needs: ['band'] },
    { id: '3013' },
  ],
  singleLeg: [
    { id: '0410', needs: ['db'] }, { id: '0431', needs: ['db'] },
    { id: 'gf-reverse-lunge' }, { id: 'gf-step-up' }, { id: '2368' },
  ],
  legCurl: [
    { id: '0586', needs: ['gym'] },
    { id: 'gf-band-lying-leg-curl', needs: ['band'] },
    { id: '0696' },
  ],
  hPush: [
    { id: '0025', needs: ['gym'] },
    { id: '0289', needs: ['db', 'bench'] },
    { id: 'gf-band-standing-chest-press', needs: ['band'] },
    { id: '0493' }, { id: '0662' }, { id: '0279' },
  ],
  vPush: [
    { id: '1457', needs: ['gym'] },
    { id: '0426', needs: ['db'] },
    { id: '0997', needs: ['band'] },
    { id: 'gf-pike-push-up' },
  ],
  hPull: [
    { id: '0861', needs: ['gym'] },
    { id: '0292', needs: ['db'] },
    { id: 'gf-band-bent-over-row', needs: ['band'] },
    { id: '0499', needs: ['table'] },
    { id: '3161' },
  ],
  vPull: [
    { id: '2330', needs: ['gym'] },
    { id: 'gf-band-lat-pulldown', needs: ['band'] },
    { id: 'gf-negative-pull-up', needs: ['bar'], max: 'novice' }, { id: '0652', needs: ['bar'] },
    { id: '3162' },
  ],
  latDelt: [
    { id: '0178', needs: ['gym'] },
    { id: '0334', needs: ['db'] },
    { id: 'gf-band-lateral-raise', needs: ['band'] },
  ],
  biceps: [
    { id: '0868', needs: ['gym'] },
    { id: '0294', needs: ['db'] },
    { id: 'gf-band-biceps-curl', needs: ['band'] },
    { id: '1326', needs: ['bar'] },
  ],
  triceps: [
    { id: '1723', needs: ['gym'] },
    { id: '0430', needs: ['db'] },
    { id: 'gf-band-triceps-pushdown', needs: ['band'] },
    { id: '0283' },
  ],
  calves: [
    { id: '1372', needs: ['gym'] },
    { id: '0409', needs: ['db'] },
    { id: '1373' },
  ],
  core: [
    { id: 'gf-band-standing-twist', needs: ['band'], max: 'none' },
    { id: '0276' }, { id: 'gf-plank', mode: 'time' }, { id: 'gf-hollow-hold', mode: 'time' },
  ],
  // Strong & Steady (§8.3)
  sitStand: [{ id: '0739', needs: ['gym'] }, { id: 'gf-sit-to-stand' }],
  supportedRow: [{ id: '0861', needs: ['gym'] }, { id: 'gf-band-bent-over-row', needs: ['band'] }, { id: '0292', needs: ['db'] }, { id: '0499', needs: ['table'] }],
  inclinePush: [{ id: '0493' }],
  stepUp: [{ id: 'gf-step-up' }],
  bridge: [{ id: '3013' }],
  balance1: [{ id: 'gf-tandem-stance', mode: 'time' }],
  balance2: [{ id: 'gf-single-leg-stance', mode: 'time' }],
  balance3: [{ id: 'gf-heel-to-toe-walk', mode: 'time' }],
}

const LEVELS = ['novice', 'intermediate', 'advanced']
const rank = l => Math.max(0, LEVELS.indexOf(l))

/** Picks the best exercise for a slot: gym first, then dumbbells, bands, bodyweight. */
export function pickExercise(slot, equipment, level = 'novice') {
  const have = new Set(equipment || [])
  if (have.has('gym')) ['db', 'bench', 'band', 'bar', 'table'].forEach(k => have.add(k))
  const ok = c =>
    (c.needs || []).every(n => have.has(n)) &&
    (!c.min || rank(level) >= rank(c.min)) &&
    (!c.max || c.max === 'none' || rank(level) <= rank(c.max)) &&
    !!EXIDX[c.id]
  const list = SLOTS[slot] || []
  // Prefer equipment in order; among bodyweight rungs, the last one the level allows.
  const equipped = list.filter(c => (c.needs || []).length && ok(c))
  if (equipped.length) return equipped[0]
  // Bodyweight candidates are a ladder, easiest first: novices take the first rung,
  // intermediates the second, advanced the third (or the last there is).
  const bw = list.filter(c => !(c.needs || []).length && ok(c))
  if (bw.length) return bw[Math.min(rank(level), bw.length - 1)]
  return null
}

/* ------------------------------ presets (§14) ------------------------------ */

// A session is [slot, sets] pairs in order. Reps are [low, high] (double progression, §3.1).
const FB_A = [['knee', 3], ['hPush', 3], ['hPull', 3], ['hinge', 2], ['latDelt', 2], ['core', 2]]
const FB_B = [['hinge', 3], ['vPush', 3], ['vPull', 3], ['singleLeg', 2], ['biceps', 2], ['calves', 2]]
const UPPER = [['hPush', 3], ['hPull', 3], ['vPush', 2], ['vPull', 3], ['latDelt', 2], ['biceps', 2], ['triceps', 2]]
const LOWER = [['knee', 3], ['hinge', 3], ['singleLeg', 2], ['legCurl', 2], ['calves', 3], ['core', 2]]
const PUSH = [['hPush', 4], ['vPush', 3], ['latDelt', 3], ['triceps', 3]]
const PULL = [['vPull', 4], ['hPull', 4], ['biceps', 3], ['core', 2]]
const LEGS = [['knee', 4], ['hinge', 3], ['legCurl', 3], ['calves', 3]]
const STEADY = [['sitStand', 2], ['supportedRow', 2], ['inclinePush', 2], ['stepUp', 2], ['bridge', 2],
  ['balance1', 2], ['balance2', 2], ['balance3', 1]]
const halve = s => s.map(([slot, n]) => [slot, Math.max(1, Math.round(n * 2 / 3))])

export const PRESETS = {
  P01: { name: 'First Steps', days: [2], sessions: { A: halve(FB_A).slice(0, 5), B: halve(FB_B).slice(0, 5) },
    reps: [10, 15], rir: '3–4 reps in reserve for two weeks, then 2–3', rest: 75, minutes: 30, cardio: 'walk' },
  P02: { name: 'Full Body 3×', days: [3], sessions: { A: FB_A, B: FB_B }, reps: [6, 10], accReps: [10, 15],
    rir: '2–3 reps in reserve, then 1–2 after week 4', rest: 105, minutes: 50, cardio: 'moderate' },
  P04: { name: 'Full Body 3× · Bodyweight', days: [3], sessions: { A: FB_A, B: FB_B }, reps: [8, 20],
    rir: '0–2 reps in reserve', rest: 75, minutes: 40, cardio: 'moderate' },
  P05: { name: 'Full Body 3× · Bands', days: [3], sessions: { A: FB_A, B: FB_B }, reps: [10, 20],
    rir: '0–2 reps in reserve', rest: 75, minutes: 40, cardio: 'moderate' },
  P06: { name: 'Upper / Lower 4×', days: [4], sessions: { Upper: UPPER, Lower: LOWER }, reps: [6, 10], accReps: [10, 20],
    rir: '1–2 reps in reserve; last isolation set 0–1', rest: 120, minutes: 65, cardio: 'separate' },
  P08: { name: 'Strength Base 3×', days: [3], sessions: {
      Heavy: [['knee', 3], ['hPush', 3], ['hPull', 3], ['core', 2]],
      Medium: [['hinge', 3], ['vPush', 3], ['vPull', 3], ['knee', 2]],
      Light: [['knee', 2], ['hPush', 3], ['hPull', 3], ['hinge', 2]] },
    reps: [3, 6], accReps: [6, 12], rir: '1–3 reps in reserve, never to failure', rest: 180, minutes: 65, cardio: 'separate', load: true },
  P09: { name: 'Push / Pull / Legs', days: [5, 6], sessions: { Push: PUSH, Pull: PULL, Legs: LEGS }, reps: [6, 12], accReps: [10, 20],
    rir: '0–2 reps in reserve', rest: 120, minutes: 65, cardio: 'easy' },
  P10: { name: 'Fat Loss & Fitness', days: [3], sessions: { A: FB_A, B: FB_B }, reps: [8, 15],
    rir: '1–3 reps in reserve', rest: 60, minutes: 40, cardio: 'fatloss', supersets: true },
  P11: { name: 'Strong & Steady', days: [2, 3], sessions: { A: STEADY }, reps: [8, 15],
    rir: '3–4 reps in reserve, then 2–3', rest: 90, minutes: 40, cardio: 'walk' },
  P12: { name: 'Minimal Dose 2×30', days: [2], sessions: {
      A: [['knee', 2], ['hPush', 2], ['hPull', 2], ['hinge', 2]], B: [['singleLeg', 2], ['vPush', 2], ['vPull', 2], ['core', 2]] },
    reps: [6, 15], rir: '1–3 reps in reserve', rest: 60, minutes: 30, cardio: 'walk', supersets: true },
}
// P03 (dumbbells) and P07 (home upper/lower) are P02/P06 with other equipment: the slot picker
// fills them, so they are the same templates (§14 lists them separately for the evidence).

/* ------------------------------ the questionnaire (§13) ------------------------------ */

const DEFAULT_DAYS = { 2: [1, 4], 3: [1, 3, 5], 4: [1, 2, 4, 5], 5: [1, 2, 3, 5, 6], 6: [1, 2, 3, 4, 5, 6] }
const ACCESSORY = new Set(['latDelt', 'biceps', 'triceps', 'calves', 'core', 'legCurl'])

/**
 * The plan for a set of answers (all optional; sensible defaults):
 *   goal: 'health' | 'muscle' | 'strength' | 'fatloss' | 'balance'
 *   experience: 'none' | 'novice' | 'intermediate' | 'advanced'
 *   timeOff: 'none' | 'short' | 'long'   (long = 3 months or more)
 *   days: 2–6, weekdays: [0–6] (1 = Monday), minutes: 20–90
 *   equipment: ['gym', 'db', 'bench', 'band', 'bar', 'table']
 *   ageBand: '<40' | '40-59' | '60-74' | '75+', unsteady: bool, lowImpact: bool
 *   symptoms: bool (chest pain, faintness, breathlessness when active), condition: bool,
 *   pregnant: bool, steps: number
 * Returns { preset, name, why[], safety, routines, schedule, cardio, notes[] }; nothing is saved.
 */
export function generatePlan(a = {}) {
  const why = [], notes = []
  const goal = a.goal || 'health'
  let level = a.experience === 'advanced' ? 'advanced' : a.experience === 'intermediate' ? 'intermediate' : 'novice'
  const older = a.ageBand === '60-74' || a.ageBand === '75+'
  let days = Math.max(2, Math.min(6, Math.round(a.days || 3)))
  const minutes = Math.max(20, Math.min(90, Math.round(a.minutes || 45)))
  const equipment = a.equipment && a.equipment.length ? a.equipment : []

  // 1. Safety (§8.1)
  const safety = { level: 'ok', message: null }
  if (a.symptoms) {
    safety.level = 'stop'
    safety.message = 'You mentioned chest pain, faintness or unusual breathlessness when active. Please see a doctor before starting; meanwhile this plan stays light.'
  } else if (a.condition || a.pregnant) {
    safety.level = 'check'
    safety.message = a.pregnant
      ? 'During pregnancy or after giving birth, check this plan with your doctor or midwife. It keeps the effort moderate and skips intervals.'
      : 'With a heart, metabolic or kidney condition, get your doctor\'s OK before starting. The plan starts gently.'
  }

  // 2. Level (§8.5): returning after 3+ months starts a level lower for two weeks
  if (a.timeOff === 'long' && level !== 'novice') {
    notes.push('You have had a long break: the first two weeks are lighter than usual.')
  }

  // 3. Template
  let id
  if (safety.level === 'stop') id = older || goal === 'balance' ? 'P11' : 'P01'
  else if (goal === 'balance' || (older && level === 'novice') || (a.ageBand === '75+')) id = 'P11'
  else if (minutes <= 30 && days <= 2) id = 'P12'
  else if (goal === 'fatloss') id = 'P10'
  else if (goal === 'health' && level === 'novice') id = days <= 2 ? 'P01' : bodyweightOnly(equipment) ? 'P04' : 'P02'
  else if (goal === 'strength' && equipment.includes('gym')) id = 'P08'
  else if (level === 'novice' || days <= 3) id = bodyweightOnly(equipment) ? (equipment.includes('band') ? 'P05' : 'P04') : 'P02'
  // Push/pull/legs needs a gym's range of exercises; at home the upper/lower split covers it (P07)
  else if (days === 4 || level === 'intermediate' || !equipment.includes('gym')) id = 'P06'
  else id = 'P09'
  if (level === 'novice' && days > 4) {
    why.push('New lifters progress best on up to 4 strength days; extra days are for walking or cardio.')
    days = 4
  }
  return buildPreset(id, { days, minutes, equipment, level, older, safety, why, notes, answers: a })
}

/**
 * One preset filled with exercises for this equipment and level, fitted to the session length
 * (§13.2 steps 4–7). `generatePlan` chooses the preset; the preset browser calls this directly.
 */
export function buildPreset(id, { days, minutes, equipment = [], level = 'novice', older = false,
  safety = { level: 'ok', message: null }, why = [], notes = [], answers = {} } = {}) {
  const p = PRESETS[id]
  days = days || p.days[0]
  minutes = minutes || p.minutes
  if (id === 'P01' || id === 'P12') days = 2
  else if (id === 'P11') days = Math.min(3, Math.max(2, days))
  else if (id === 'P06') days = 4
  else if (id === 'P09') days = days >= 6 ? 6 : 5
  else days = Math.min(days, 3)

  const perSet = p.load ? 3.5 : p.supersets ? 1.6 : 2.5
  const budget = Math.max(6, Math.floor((minutes - 6) / perSet))
  const keys = Object.keys(p.sessions)
  const order = id === 'P09' && days === 5 ? ['Push', 'Pull', 'Legs', 'Push', 'Pull'] : null
  const routines = keys.map(key => {
    const slots = []
    let total = 0
    for (const [slot, sets] of p.sessions[key]) {
      const n = safety.level === 'stop' ? Math.min(sets, 2) : sets
      if (total + n > budget && slots.length >= 3) continue
      const c = pickExercise(slot, equipment, level)
      if (!c || slots.some(s => s.id === c.id)) continue
      const [lo, hi] = ACCESSORY.has(slot) && p.accReps ? p.accReps : p.reps
      const ex = c.mode === 'time'
        ? { id: c.id, sets: n, mode: 'time', sec: older || level === 'novice' ? 20 : 30, weight: 0, restSec: 60 }
        : { id: c.id, sets: n, mode: 'reps', reps: hi, repsMin: lo, weight: 0, restSec: ACCESSORY.has(slot) ? Math.min(90, p.rest) : p.rest }
      slots.push(ex)
      total += n
    }
    if (p.supersets) pairAntagonists(slots)
    return { key, name: keys.length === 1 ? p.name : `${p.name.split(' · ')[0]} · ${key}`, emoji: emojiFor(id), ex: slots, prog: 'double' }
  })
  if (!equipment.some(e => e === 'gym' || e === 'bar' || e === 'band') && !notes.some(n => n.includes('vertical pull'))) {
    notes.push('Without a pull-up bar or bands there is no vertical pull; rows cover your back instead.')
  }

  const weekdays = (answers.weekdays && answers.weekdays.length >= days ? answers.weekdays.slice(0, days) : DEFAULT_DAYS[days]).slice().sort()
  const seq = order || weekdays.map((_, i) => keys[i % keys.length])
  const schedule = weekdays.map((day, i) => ({ day, key: seq[i % seq.length] }))

  why = [`${p.name}: ${days} days a week, about ${p.minutes} minutes, ${p.rir}.`, ...why]
  if (['P02', 'P04', 'P05', 'P10'].includes(id)) why.push('Full-body sessions train every muscle at least twice a week, which matters more than the split.')
  if (id === 'P11') why.push('Strength plus balance work at least three days a week lowers the risk of falls by about a third.')
  if (id === 'P08') why.push('Strength grows fastest with heavy sets (3–6 reps) on the main lifts, a few times a week.')
  why.push('Each exercise uses a rep range: when every set reaches the top, add a little weight (or a harder version) and start from the bottom again.')

  return { preset: id, name: p.name, level, days, minutes, why, safety, notes, routines, schedule, cardio: cardioFor(p.cardio, answers, safety) }
}

function bodyweightOnly(eq) { return !eq.includes('gym') && !eq.includes('db') }

function emojiFor(id) {
  return { P01: 'figureRun', P11: 'heart', P08: 'barbell', P10: 'flame', P12: 'timer' }[id] || 'figureStrength'
}

// Push/pull pairs done back to back (supersets) to fit more into a short session (§13.2 step 6)
function pairAntagonists(slots) {
  let g = 0
  for (let i = 0; i + 1 < slots.length; i += 2) {
    const sg = 'p' + (++g)
    slots[i].sg = sg
    slots[i + 1].sg = sg
  }
}

/** Weekly cardio and steps advice (§6, §7, WHO 2020). Text only; nothing is scheduled. */
function cardioFor(kind, a, safety) {
  const steps = a.steps > 0 ? Math.min(a.ageBand === '60-74' || a.ageBand === '75+' ? 8000 : 10000, Math.round(a.steps / 500) * 500 + 1000) : null
  const base = {
    walk: 'Walk most days. Build up to 150 minutes a week of brisk walking.',
    moderate: 'Aim for 150 minutes a week of moderate cardio (brisk walking, cycling), on other days or after lifting.',
    separate: '2–3 sessions of 20–30 minutes of moderate cardio a week; cycling is easiest on the legs. Keep it a few hours away from leg days if you can.',
    easy: '2 easy sessions of 20–30 minutes a week (walking or cycling).',
    fatloss: 'Build from 150 to 300 minutes a week of moderate cardio (walking, cycling, swimming). From week 5, one short interval session a week is optional.',
  }[kind]
  const text = safety.level !== 'ok' ? base.replace(/ From week 5.*$/, '') : base
  return { text, steps, stepsNote: steps ? `Daily steps: aim for about ${steps.toLocaleString('en-US')}, adding 1,000 every week or two.` : null }
}

/* ------------------------------ applying ------------------------------ */

/** Weekdays the plan would take that already have a routine (to ask before replacing). */
export function planConflicts(plan) {
  const s = need()
  return plan.schedule.map(x => x.day).filter(day => [].concat(s.week[day] || []).some(rid => s.routines.some(r => r.id === rid)))
}

/** Adds the plan's routines and puts them on their weekdays; the routines are ordinary ones. */
export function applyPlan(plan) {
  const s = need()
  const ids = {}
  for (const r of plan.routines) {
    if (!r.ex.length) continue
    const id = uid()
    ids[r.key] = id
    s.routines.push({ id, name: r.name, emoji: r.emoji, prog: r.prog, ex: r.ex.map(e => ({ ...e })) })
  }
  for (const { day, key } of plan.schedule) if (ids[key]) s.week[day] = [ids[key]]
  s.gfPlan = { preset: plan.preset, at: Date.now(), cardio: plan.cardio }
  return Object.values(ids)
}

/** The presets for browsing (Plan → Starter plans), each filled for this equipment. */
export function presetList(equipment = ['gym'], level = 'novice') {
  const gym = equipment.includes('gym'), weights = gym || equipment.includes('db')
  // One full-body 3× entry, for the equipment there is (P02 gym/dumbbells, P05 bands, P04 none)
  const fb = weights ? 'P02' : equipment.includes('band') ? 'P05' : 'P04'
  const ids = ['P01', fb, 'P10', 'P12', 'P06', ...(gym ? ['P08', 'P09'] : []), 'P11']
  return ids.map(id => {
    const p = PRESETS[id]
    const lvl = id === 'P09' ? 'advanced' : id === 'P06' ? 'intermediate' : level
    const plan = buildPreset(id, { equipment, level: lvl, days: p.days[p.days.length - 1], older: id === 'P11' })
    return { id, name: p.name, days: plan.days, minutes: p.minutes, plan }
  }).filter(x => x.plan.routines.every(r => r.ex.length >= 3))
}
