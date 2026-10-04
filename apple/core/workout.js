// The workout screen's exercise blocks (views/Workout.jsx ExerciseBlock), headless: what each
// block shows, already worded through openGym's own i18n, and the set-level edits its controls
// make. SwiftUI draws `entryView` and calls the rest; the decisions stay openGym's.
import { need } from './actions.js'
import { t } from './i18n-native.js'
import { exOr, betterWeight } from '../../frontend/src/lib/exercises.js'
import {
  lastEntryFor, bestWeightFor, setLabel, modeOf, isBw, isPerSide, repStep, EFFORT, effortOf,
  stepEffort, cascadeWeight, setsRepsOf, pinnedNoteFor, exNoteFor,
} from '../../frontend/src/lib/history.js'
import { sessionHistory } from '../../frontend/src/lib/backfill.js'
import { bestSetFor } from '../../frontend/src/lib/exercise-history.js'
import { fmtNum, fmtPlate, fmtDate } from '../../frontend/src/lib/format.js'
import { speedUnitOf, toSpeed, fromSpeed } from '../../frontend/src/lib/speed.js'
import { weightIncrement, stepWeight } from '../../frontend/src/lib/progression.js'
import { progressionGuidance } from '../../frontend/src/lib/progression-copy.js'
import { buildPlannedEntry, plannedConfigOf, builtOutOfProgression } from '../../frontend/src/lib/session-start.js'
import { usesBar } from '../../frontend/src/lib/bar.js'
import { loadKindFor, baseWeightFor, inventoryFor, rowLoad, sameLoad, plateDelta, dropGrid } from '../../frontend/src/lib/plates.js'
import {
  isWarmupRow, isDropSet, isRestPauseSet, dropsOf, clustersOf, addDrop as withDrop, addCluster,
  removeDropAt, removeClusterAt, setDropAt, setClusterAt, nextDropWeight, nextBurstReps, isSideSet,
  setSideField as withSideField, addSideDrop, removeSideDropAt, setSideDropAt, addSideCluster,
  removeSideClusterAt, setSideClusterAt, WEIGHT_ORIGIN_MANUAL,
} from '../../frontend/src/lib/workout-model.js'
import { effortColor } from '../../frontend/src/lib/effort.js'
import { nextOpenSet } from '../../frontend/src/lib/workout-keys.js'
import { supersetUnits, unitOf } from '../../frontend/src/lib/history.js'
import { restSecFor } from '../../frontend/src/lib/supersetFlow.js'

const entryAt = idx => {
  const A = need().active
  if (!A) throw new Error('no session in progress')
  const e = A.entries[idx]
  if (!e) throw new Error(`no exercise at ${idx}`)
  return e
}

/** The columns a block's set rows have (Workout.jsx col1/col2/col3). */
function columnsOf(S, entry) {
  const cfg = { ...(entry.target || {}), id: entry.id }
  const mode = modeOf(cfg)
  const cardio = mode === 'cardio'
  const timed = mode === 'time'
  const bw = !cardio && isBw(cfg)
  const added = bw && entry.sets.some(s => s.w > 0)
  const loadStep = mode === 'reps' ? weightIncrement(cfg, S.unit) : 2.5
  const speedUnit = speedUnitOf(S)
  const load = { f: 'w', step: loadStep, dec: true, hd: bw ? t('Added ({0})', S.unit) : t('Weight ({0})', S.unit) }
  const reps = { f: 'r', step: repStep(cfg), dec: false, hd: t('Reps') }
  const col1 = cardio ? { f: 'min', step: 1, dec: false, hd: t('Duration (min)') }
    : timed ? { f: 'sec', step: 5, dec: false, hd: t('Seconds') }
      : (bw && !added) ? reps : load
  const col2 = cardio ? { f: 'speed', step: 0.5, dec: true, hd: speedUnit === 'mph' ? t('Speed (mph)') : t('Speed (km/h)'), speed: true }
    : timed ? ((bw && !added) ? null : load)
      : (bw && !added) ? null : reps
  const kind = effortOf(S)
  const eff = EFFORT[kind]
  const col3 = mode === 'reps' && eff ? { f: eff.f, eff: kind, hd: t(eff.hd) } : null
  return { cfg, mode, cardio, timed, bw, added, perSide: mode === 'reps' && isPerSide(cfg), loadStep, speedUnit, cols: [col1, col2, col3] }
}

/** Plate loading lines (Workout.jsx loadLine), keyed by set ('3') or drop ('3:d0'). */
function loadLinesOf(S, entry, mode, perSide, cfg) {
  const kind = mode === 'reps' && !S.active.editingWorkoutId ? loadKindFor(S, cfg) : 'none'
  const base = baseWeightFor(S, entry.id)
  const ex = exOr(entry.id)
  const summary = kind === 'none' ? t('Off') : kind === 'single' ? t('Single stack')
    : !usesBar(ex) ? t('Per side') : base > 0 ? t('Bar {0}', fmtNum(base) + ' ' + S.unit) : t('No bar')
  if (kind === 'none') return { summary, lines: {} }
  const inv = inventoryFor(S)
  const seq = []
  entry.sets.forEach((s, i) => {
    let w = s.w
    if (perSide && isSideSet(s)) {
      const L = s.sides.L?.w || 0, R = s.sides.R?.w || 0
      if (L && R && L !== R) return
      w = L || R
    }
    seq.push({ key: String(i), load: rowLoad(kind, w, base, inv) })
    dropsOf(s).forEach((d, di) => seq.push({ key: i + ':d' + di, load: rowLoad(kind, d.w, base, inv) }))
  })
  const lines = {}
  seq.forEach(({ key, load }, at) => {
    if (!load) return
    let p = at - 1
    while (p >= 0 && !seq[p].load) p--
    const prev = p >= 0 ? seq[p].load : null
    if (prev && sameLoad(prev, load)) return
    const stack = load.plates.map(w => fmtPlate(w)).join(' + ')
    const text = load.barOnly ? t('Bar only') : load.kind === 'pairs' ? t('{0} per side', stack || '—') : t('Load {0}', stack || '—')
    const d = prev ? plateDelta(prev.plates, load.plates) : null
    lines[key] = {
      text,
      short: load.missing > 0 ? t('{0} short', fmtPlate(load.missing) + ' ' + S.unit) : null,
      moves: d ? [...d.strip.map(w => '−' + fmtPlate(w)), ...d.add.map(w => '+' + fmtPlate(w))].join(' ') : '',
    }
  })
  return { summary, lines }
}

/**
 * Everything one exercise block shows. Strings are worded by openGym's catalogue in the
 * current language.
 */
export function entryView(idx) {
  const S = need()
  const entry = entryAt(idx)
  const { cfg, mode, cardio, timed, bw, perSide, loadStep, speedUnit, cols } = columnsOf(S, entry)
  const H = sessionHistory(S)
  const last = lastEntryFor(H, entry.id, entry.rid)
  const bestHist = bestWeightFor(H, entry.id)
  const bestKept = (H.exWeights[entry.id] || {}).w || 0
  const best = cardio ? 0 : bestHist > 0 && bestKept > 0 ? betterWeight(entry.id, bestHist, bestKept) : Math.max(bestHist, bestKept)
  const guidance = progressionGuidance(entry.plan)

  const planned = entry.planned && mode !== 'cardio' ? entry.planned : null
  let planLine = null
  if (planned) {
    const today = entry.target || {}
    const todaySets = today.sets || planned.sets || 1
    const inPlan = timed
      ? today.sec == null || today.sec === planned.sec
      : today.reps == null || (planned.repsMin > 0 ? today.reps >= planned.repsMin && today.reps <= planned.reps : today.reps === planned.reps)
    const note = todaySets !== (planned.sets || 1) || !inPlan
      ? t('today {0}', setsRepsOf({ mode, sets: todaySets, reps: today.reps, sec: today.sec }))
      : entry.carried ? t('reps from your last session') : null
    planLine = t('Plan: {0}', setsRepsOf({ ...planned, mode })) + (note ? ' · ' + note : '')
  }

  const refBest = S.logRef === 'best'
  const ref = refBest ? bestSetFor(H, entry.id, mode) : last
  const refText = ref
    ? `${refBest ? t('Best set') : t('Last time')} (${fmtDate(ref.d)}): ` +
      (refBest ? [ref.set] : ref.sets).map(s => setLabel(entry.id, s, ref.target, speedUnit)).join(', ')
    : refBest && last ? t('Best set: nothing logged this way yet') : null

  const pinned = entry.sets.some(s => !s.done) ? pinnedNoteFor(S, entry.id) : null
  const plates = loadLinesOf(S, entry, mode, perSide, cfg)
  const routine = entry.rid ? S.routines.find(r => r.id === entry.rid) : null

  const rows = entry.sets.map((s, i) => {
    const warm = isWarmupRow(s)
    const warmBefore = i > 0 && isWarmupRow(entry.sets[i - 1])
    return {
      warm, firstWarmup: warm && !warmBefore, sepBefore: !warm && warmBefore,
      num: entry.sets.slice(0, i + 1).filter(x => isWarmupRow(x) === warm).length,
      label: setLabel(entry.id, s, entry.target, speedUnit),
      side: perSide && !warm && isSideSet(s),
      canDrop: !warm && mode === 'reps' && !isRestPauseSet(s),
      canBurst: !warm && mode === 'reps' && !isDropSet(s),
      effortColor: cols[2] ? effortColor(cols[2].eff === 'rpe' ? (s.rpe == null ? null : 10 - s.rpe) : s.rir) : null,
      speedShown: cardio && s.speed != null ? toSpeed(s.speed, speedUnit) : null,
    }
  })

  return {
    mode, cardio, timed, bw, perSide, loadStep, unit: S.unit, speedUnit,
    cols: cols.map(c => c && { ...c }),
    best, bestText: best > 0 ? t('Best:') + ' ' + fmtNum(best) + ' ' + S.unit : null,
    routineNote: cfg.note || null,
    standingNote: exNoteFor(S, entry.id),
    pinnedNote: pinned ? t('From {0}:', fmtDate(pinned.d, true)) + ' ' + pinned.note : null,
    note: entry.note || null,
    planLine, refText, refBest,
    refAction: refBest ? t('Show last time instead') : t('Show your best set instead'),
    lastDate: last ? fmtDate(last.d) : null,
    guidance: guidance ? { label: t(guidance.policyLabel), why: t(...guidance.why), kind: entry.plan.kind } : null,
    noProg: entry.noProg === true,
    routineKeepsOut: !!routine && routine.excludeFromProgression === true,
    plateSummary: plates.summary, plateLines: plates.lines,
    rows,
  }
}

/** Switches the reference line between last time and the best set (S.logRef). */
export function toggleLogRef() {
  const S = need()
  S.logRef = S.logRef === 'best' ? 'last' : 'best'
  return S.logRef
}

/**
 * One tap of a stepper (Workout.jsx bump / sideBump): weights walk the exercise's load grid,
 * speed steps in the unit on screen, effort walks its own scale. `side` for a per-side row.
 */
export function bump(idx, i, field, dir, side = null) {
  const S = need()
  const entry = entryAt(idx)
  const { mode, loadStep, speedUnit, cols } = columnsOf(S, entry)
  const row = entry.sets[i]
  if (field === 'rir' || field === 'rpe') {
    const kind = cols[2]?.eff || field
    const cur = side ? row.sides?.[side]?.[field] : row[field]
    return side ? setSideValue(idx, i, side, field, stepEffort(kind, cur ?? null, dir)) : setValue(idx, i, field, stepEffort(kind, cur ?? null, dir))
  }
  if (side) {
    const cur = row.sides?.[side]?.[field] || 0
    if (field === 'w') return setSideValue(idx, i, side, field, stepWeight(cur, loadStep, dir))
    const step = field === 'r' ? 1 : (cols.find(c => c && c.f === field)?.step || 1)
    return setSideValue(idx, i, side, field, Math.max(0, Math.round((cur + dir * step) * 100) / 100))
  }
  const col = cols.find(c => c && c.f === field) || { step: 1 }
  const cur = row[field]
  if (mode === 'reps' && field === 'w') return setValue(idx, i, field, stepWeight(cur, col.step, dir))
  if (field === 'speed') {
    const shown = Math.max(0, Math.round(((toSpeed(cur, speedUnit) || 0) + dir * col.step) * 100) / 100)
    return setValue(idx, i, field, fromSpeed(shown, speedUnit))
  }
  return setValue(idx, i, field, Math.max(0, Math.round(((cur || 0) + dir * col.step) * 100) / 100))
}

/** A typed value (actions.js setField); a cardio speed is typed in the unit on screen. */
export function setTyped(idx, i, field, v) {
  const S = need()
  if (field === 'speed' && v != null) v = fromSpeed(v, speedUnitOf(S))
  return setValue(idx, i, field, v)
}

function setValue(idx, i, field, v) {
  const e = entryAt(idx)
  if (v == null) delete e.sets[i][field]; else e.sets[i][field] = v
  if (field === 'sec') delete e.sets[i].planSec
  if (field === 'w') {
    e.sets[i].weightOrigin = WEIGHT_ORIGIN_MANUAL
    e.sets = cascadeWeight(e.sets, i, v)
  }
  return true
}

/** One side of a per-side row (Workout.jsx setSide); a weight carries forward on that side. */
export function setSideValue(idx, i, side, field, v) {
  const e = entryAt(idx)
  const row = withSideField(e.sets[i], side, field, v)
  if (field === 'w') {
    row.sides[side].weightOrigin = WEIGHT_ORIGIN_MANUAL
    e.sets[i] = row
    e.sets = cascadeWeight(e.sets, i, v, side)
  } else e.sets[i] = row
  return true
}

/* ------------------------------ drop sets and rest-pause bursts ------------------------------ */

export function addDrop(idx, i) {
  const S = need()
  const entry = entryAt(idx)
  const row = entry.sets[i]
  const pct = entry.target?.intensifier?.type === 'dropset' ? entry.target.intensifier.pct : undefined
  const grid = dropGrid(S, { ...entry.target, id: entry.id })
  if (isSideSet(row)) entry.sets[i] = addSideDrop(row, pct, grid)
  else {
    const drops = dropsOf(row)
    const base = drops.length ? drops[drops.length - 1].w : (row.w || 0)
    entry.sets[i] = withDrop(row, { w: nextDropWeight(base, pct, grid), r: row.r })
  }
  return true
}

/** A rest-pause row's own reps are the total across its bursts, so `r` moves with them. */
export function addBurst(idx, i) {
  const S = need()
  const entry = entryAt(idx)
  const row = entry.sets[i]
  const restSec = entry.target?.intensifier?.type === 'restpause' ? entry.target.intensifier.restSec : (S.restPauseSec || 15)
  if (isSideSet(row)) entry.sets[i] = addSideCluster(row, restSec)
  else {
    const clusters = clustersOf(row)
    const base = clusters.length ? clusters[clusters.length - 1].r : (row.r || 0)
    const added = nextBurstReps(base)
    entry.sets[i] = { ...addCluster(row, { r: added, restSec }), r: (row.r || 0) + added }
  }
  return true
}

export function removeDrop(idx, i, di) {
  const e = entryAt(idx)
  e.sets[i] = isSideSet(e.sets[i]) ? removeSideDropAt(e.sets[i], di) : removeDropAt(e.sets[i], di)
  return true
}

export function removeBurst(idx, i, ci) {
  const e = entryAt(idx)
  const row = e.sets[i]
  if (isSideSet(row)) e.sets[i] = removeSideClusterAt(row, ci)
  else {
    const removed = clustersOf(row)[ci]?.r || 0
    e.sets[i] = { ...removeClusterAt(row, ci), r: Math.max(0, (row.r || 0) - removed) }
  }
  return true
}

export function setDrop(idx, i, di, field, v, side = null) {
  const e = entryAt(idx)
  const row = e.sets[i]
  e.sets[i] = isSideSet(row) ? setSideDropAt(row, side, di, { [field]: v }) : setDropAt(row, di, { [field]: v })
  return true
}

/** A drop's weight steps on the load grid, its reps by one. */
export function bumpDrop(idx, i, di, field, dir, side = null) {
  const S = need()
  const e = entryAt(idx)
  const { loadStep } = columnsOf(S, e)
  const row = e.sets[i]
  const d = (side ? dropsOf(row.sides?.[side] || {}) : dropsOf(row))[di] || {}
  const v = field === 'w' ? stepWeight(d.w, loadStep, dir) : Math.max(0, (d.r || 0) + dir)
  return setDrop(idx, i, di, field, v, side)
}

export function setBurst(idx, i, ci, v, side = null) {
  const e = entryAt(idx)
  const row = e.sets[i]
  if (isSideSet(row)) e.sets[i] = setSideClusterAt(row, side, ci, v)
  else {
    const delta = (Number(v) || 0) - (clustersOf(row)[ci]?.r || 0)
    e.sets[i] = { ...setClusterAt(row, ci, { r: v }), r: Math.max(0, (row.r || 0) + delta) }
  }
  return true
}

/* ------------------------------ progression settings mid-session ------------------------------ */

/** Where the exercise's settings open mid-session: the plan's numbers, not today's. */
export function progressionStart(idx) {
  const entry = entryAt(idx)
  return { config: plannedConfigOf(entry), routineId: entry.rid || null }
}

/**
 * Workout.jsx openProgressionSettings save: the rows are rebuilt from the new settings the way
 * the session start builds them, keeping what was already logged.
 */
export function applyProgressionSettings(idx, cfg) {
  const s = need()
  const activeEntry = entryAt(idx)
  const opened = plannedConfigOf(activeEntry)
  const full = { ...cfg, id: activeEntry.id }
  if ((cfg.weight || 0) === (opened.weight || 0) && activeEntry.planned?.weight != null) full.weight = activeEntry.planned.weight
  const activeRoutine = s.routines.find(r => r.id === activeEntry.rid)
  if (!(full.sets > 0)) full.sets = activeEntry.sets.filter(x => !isWarmupRow(x)).length || 1
  const built = buildPlannedEntry(sessionHistory(s), full, activeRoutine, { noProg: builtOutOfProgression(activeEntry, activeRoutine) })
  const fresh = built.sets
  const doneWarm = activeEntry.sets.filter(x => x.done && isWarmupRow(x))
  const doneWork = activeEntry.sets.filter(x => x.done && !isWarmupRow(x))
  const freshWarm = fresh.filter(isWarmupRow)
  const freshWork = fresh.filter(x => !isWarmupRow(x))
  activeEntry.target = built.target
  activeEntry.plan = built.plan
  activeEntry.planned = built.planned
  if (built.carried) activeEntry.carried = true
  else delete activeEntry.carried
  activeEntry.sets = [...doneWarm, ...freshWarm.slice(doneWarm.length), ...doneWork, ...freshWork.slice(doneWork.length)]
  return true
}


/* ------------------------------ guided mode ------------------------------ */

function describeStep(S, entries, at) {
  if (!at) return null
  const entry = entries[at.idx]
  const row = entry.sets[at.i]
  const warm = isWarmupRow(row)
  const cfg = { ...(entry.target || {}), id: entry.id }
  const mode = modeOf(cfg)
  const phase = entry.sets.filter(x => isWarmupRow(x) === warm)
  const src = at.side ? (row.sides?.[at.side] || {}) : row
  return {
    idx: at.idx, set: at.i, side: at.side || null, current: !!at.current,
    exerciseId: entry.id, mode, warm, timed: mode === 'time', cardio: mode === 'cardio', bw: isBw(cfg),
    num: entry.sets.slice(0, at.i + 1).filter(x => isWarmupRow(x) === warm).length,
    count: phase.length,
    label: setLabel(entry.id, row, entry.target, speedUnitOf(S)),
    w: src.w ?? null, r: src.r ?? null, sec: row.sec ?? null, min: row.min ?? null,
    speed: row.speed != null ? toSpeed(row.speed, speedUnitOf(S)) : null,
  }
}

/**
 * Guided mode's step: the next set to do, by openGym's own rule (workout-keys.js nextOpenSet:
 * the current exercise, the member of a superset whose turn it is, then the next exercise with
 * work left; per-side sets left first), and a preview of the one after it.
 */
export function guide() {
  const S = need()
  const A = S.active
  if (!A || !A.entries.length) return { done: true, step: null, next: null, unit: S.unit, speedUnit: speedUnitOf(S) }
  const at = nextOpenSet(A.entries, A.cur)
  if (!at) return { done: true, step: null, next: null, unit: S.unit, speedUnit: speedUnitOf(S) }
  const step = describeStep(S, A.entries, at)
  const units = supersetUnits(A.entries)
  const unit = unitOf(units, at.idx)
  step.unitNum = units.findIndex(u => u === unit) + 1
  step.unitCount = units.length
  step.superset = unit.length > 1
  step.restSec = restSecFor(A.entries, unit, S.restSec)
  // The step after: this one ticked on a copy, then the same rule from where a superset would
  // move next (its partner).
  const copy = JSON.parse(JSON.stringify(A.entries))
  const row = copy[at.idx].sets[at.i]
  if (at.side) { row.sides[at.side].done = true; row.done = row.sides.L.done && row.sides.R.done } else row.done = true
  const pos = unit.indexOf(at.idx)
  const from = unit.length > 1 && !at.side ? unit[(pos + 1) % unit.length] : at.idx
  const next = describeStep(S, copy, nextOpenSet(copy, from))
  return { done: false, step, next, unit: S.unit, speedUnit: speedUnitOf(S) }
}
