// Stats, headless: what openGym's Stats view (views/Stats.jsx), its activity heatmap
// (components/Heatmap.jsx), the exercise history sheet and the 1RM calculator (sheets.jsx
// ExerciseHistory, OneRM) and the structural balance screen (views/StructuralBalance.jsx) show,
// computed on the same lib helpers and worded through openGym's i18n. Same rules as actions.js:
// plain JSON in and out, and the profile is only changed here.
import { need } from './actions.js'
import { t } from './i18n-native.js'
import { EXIDX, exOr, matchExercise, betterWeight, isAssisted, isCardio } from '../../frontend/src/lib/exercises.js'
import {
  lastBW, streakWeeks, setLabel, modeOf, effortOf, entriesForExercise, metricEntriesForExercise,
  metricModeForEntry, bestWeightForEntry, completedRepsOf, workoutDay, workoutDuration, workoutVolume,
} from '../../frontend/src/lib/history.js'
import {
  fmtNum, fmtDate, fmtVol, todayISO, isoOf, weekStartOf, weekDayOffset, exerciseNameText, MONTHS,
} from '../../frontend/src/lib/format.js'
import { speedUnitOf, speedLabel, toSpeed } from '../../frontend/src/lib/speed.js'
import { e1rmSeries, best1RM, estimate1RM, REP_CAP } from '../../frontend/src/lib/onerm.js'
import {
  hasEffort, displayScale, scaleName, toScale, avgRir, effortSummary, effortWeeks, effortHistogram, HARD_RIR,
} from '../../frontend/src/lib/effort.js'
import { exerciseHistory, bestSetFor } from '../../frontend/src/lib/exercise-history.js'
import { computeBalance, overrideKey, withOverride, loadForReps } from '../../frontend/src/lib/structuralBalance.js'
import { balanceStatusView } from '../../frontend/src/lib/structuralBalance-view.js'
import { TEMPLATES, TEMPLATE_LIST, DEFAULT_TEMPLATE_ID, EVALUATION_MODES } from '../../frontend/src/lib/structuralBalanceTemplates.js'
import { historyRows } from './history-actions.js'
import {
  MUSCLES, INERT, MUSCLE_NAME, levelsOf, rankOf, loadOfWorkouts, muscleBalanceWindow, musclesOf,
} from '../../frontend/src/lib/muscles.js'
import { isWarmupRow } from '../../frontend/src/lib/workout-model.js'
import { fatigueOf, strengthOf, STRENGTH_FLOOR, LB_TO_KG } from '../../frontend/src/lib/recovery.js'
import { fatigueStateOf } from '../../frontend/src/lib/recovery-view.js'
import { strengthExerciseRowsForMuscle } from '../../frontend/src/lib/strength-exercises.js'
import { isHardSet } from '../../frontend/src/lib/effort.js'

const DAY_MS = 86400000

/* ------------------------------ the overview ------------------------------ */

/**
 * Stats.jsx's tiles and recent workouts. `tone` is bwDeltaColor's reading of the 30-day weight
 * change: 'neutral' (no change), 'plain' (no goal), 'good' (toward the goal) or 'bad'.
 */
export function overview(now = Date.now(), today = todayISO()) {
  const S = need()
  const workouts = S.workouts
  // Stats.jsx reads a weigh-in's time as `b.t`, or its day at UTC midnight (new Date(iso)).
  const bw30 = S.bodyweight.filter(b => (b.t || new Date(b.d).getTime()) > now - 30 * DAY_MS)
  const delta = bw30.length > 1 ? bw30[bw30.length - 1].w - bw30[0].w : null
  const current = (lastBW(S) || {}).w || 0
  const tone = !delta ? 'neutral' : !S.targetW ? 'plain' : (delta > 0) === (S.targetW > current) ? 'good' : 'bad'
  return {
    workouts: workouts.length,
    month: workouts.filter(w => workoutDay(w)?.slice(0, 7) === today.slice(0, 7)).length,
    streak: streakWeeks(S),
    weight: delta === null ? '—' : (delta > 0 ? '+' : '') + fmtNum(delta) + ' ' + S.unit,
    tone,
    recent: historyRows().slice(0, 6),
    all: `${t('All')} ${workouts.length}`,
    hasEffort: hasEffort(S),
    heatmapMetric: S.heatmapMetric === 'vol' ? 'vol' : 'time',
    empty: t('Finish your first workout to see progress curves here.'),
  }
}

/* ------------------------------ exercise progress ------------------------------ */

// Stats.jsx's per-workout reading of one exercise: the mode its latest occurrence was logged
// in, the rows of that mode and, for reps, the best weight under the exercise's own "better".
function metricDataOf(workout, id) {
  const entries = metricEntriesForExercise(workout, id)
  const mode = entries.at(-1)?.mode || null
  const sameMode = entries.filter(item => item.mode === mode)
  const best = mode === 'reps' ? sameMode.reduce((value, item) => {
    const candidate = bestWeightForEntry(item.entry)
    if (!(candidate > 0)) return value
    return value > 0 ? betterWeight(id, value, candidate) : candidate
  }, 0) : 0
  return { mode, entries: sameMode, rows: sameMode.flatMap(item => item.rows), best }
}

const listOf = value => Array.isArray(value) ? value : value == null || value === '' ? [] : [value]
const firstAvailable = (...values) => {
  for (const value of values) {
    const list = listOf(value)
    if (list.length) return list
  }
  return []
}
const entryOf = (S, id) => S.workouts.flatMap(w => w.entries || []).find(e => e.id === id)
const nameOf = (S, id) => {
  if (EXIDX[id]) return exerciseNameText(EXIDX[id])
  const entry = entryOf(S, id)
  return entry?.muscleSnapshot?.n || entry?.n || id
}
// What the picker's search matches a logged exercise against, custom ones from their snapshot.
function matcherOf(S, id) {
  if (EXIDX[id]) return EXIDX[id]
  const entry = entryOf(S, id)
  const snapshot = entry?.muscleSnapshot || {}
  const primaries = firstAvailable(snapshot.primaries, entry?.primaries)
  const secondaries = firstAvailable(
    snapshot.sm, snapshot.secondaries, snapshot.muscleGroups,
    entry?.sm, entry?.secondaries, entry?.muscleGroups,
  )
  return {
    n: snapshot.n || entry?.n || id,
    bp: snapshot.bp || entry?.bp || '',
    tg: primaries[0] || snapshot.tg || entry?.tg || '',
    sm: secondaries,
    eq: snapshot.eq || entry?.eq || '',
    desc: snapshot.desc || entry?.desc || '',
  }
}

// The latest figure for an exercise, shown beside it in the picker and used to order it.
function currentOf(S, id) {
  const workouts = S.workouts
  const speedUnit = speedUnitOf(S)
  for (let i = workouts.length - 1; i >= 0; i--) {
    const data = metricDataOf(workouts[i], id)
    if (!data.mode) continue
    const mode = data.mode
    const rows = data.rows
    const mx = mode === 'reps'
      ? data.best
      : Math.max(0, ...rows.map(s => mode === 'cardio' ? toSpeed(s.speed || 0, speedUnit) : mode === 'time' ? (s.sec || 0) : (s.w || 0)))
    if (mx > 0) return { mx, unit: mode === 'cardio' ? speedLabel(speedUnit) : mode === 'time' ? 's' : S.unit }
    if (mode === 'reps') {
      const reps = Math.max(0, ...rows.map(completedRepsOf))
      if (reps > 0) return { mx: reps, unit: t('reps') }
    }
  }
  return { mx: 0, unit: S.unit }
}

/**
 * The exercise progress picker (Stats.jsx SelectRow): every exercise logged, strongest first,
 * each with its latest figure; `q` searches them the way openGym's picker does.
 */
export function progressExercises(q = '') {
  const S = need()
  const ids = [...new Set(S.workouts.flatMap(w => (w.entries || []).map(e => e.id)))]
    .filter(id => EXIDX[id] || nameOf(S, id) !== id)
  const cur = Object.fromEntries(ids.map(id => [id, currentOf(S, id)]))
  ids.sort((a, b) => cur[b].mx - cur[a].mx || nameOf(S, a).localeCompare(nameOf(S, b)))
  return ids
    .filter(id => matchExercise(matcherOf(S, id), q))
    .map(id => ({ id, name: nameOf(S, id), value: cur[id].mx ? fmtNum(cur[id].mx) + ' ' + cur[id].unit : null }))
}

/** The exercise the progress card opens on: the first in the picker's order, or null. */
export const firstProgressExercise = () => progressExercises()[0]?.id || null

// The mode an exercise was last charted in (Stats.jsx curMode).
function modeFor(S, id) {
  const workouts = S.workouts
  for (let i = workouts.length - 1; i >= 0; i--) {
    const data = metricDataOf(workouts[i], id)
    if (data.mode) return data.mode
    const entries = entriesForExercise(workouts[i], id)
    for (let j = entries.length - 1; j >= 0; j--) {
      const mode = metricModeForEntry(entries[j])
      if (mode) return mode
    }
  }
  return modeOf({ id })
}

/**
 * Stats.jsx's Exercise progress card for one exercise: the top-set curve (with each session's
 * effort as the dot's fill), the estimated-1RM curve, the effort curve, the last five sessions,
 * the best, and — from exercise-history.js — the best set ever logged.
 */
export function exerciseProgress(id) {
  const S = need()
  const workouts = S.workouts
  const speedUnit = speedUnitOf(S)
  const kind = displayScale(S)
  const hd = scaleName(kind)
  const mode = modeFor(S, id)
  const cardio = mode === 'cardio'
  const timed = mode === 'time'
  const repsOnly = mode === 'reps' && !workouts.some(w => entriesForExercise(w, id).some(en => bestWeightForEntry(en) > 0))
  const metric = s => cardio ? toSpeed(s.speed || 0, speedUnit) : timed ? (s.sec || 0) : (s.w || 0)
  const unit = cardio ? speedLabel(speedUnit) : timed ? 's' : repsOnly ? t('reps') : S.unit

  const pts = []
  let best = 0
  workouts.forEach(w => {
    const data = metricDataOf(w, id)
    if (data.mode !== mode) return
    const rows = data.rows
    const representative = data.entries.at(-1)?.entry
    const mx = mode === 'reps' ? (repsOnly ? Math.max(0, ...rows.map(completedRepsOf)) : data.best) : Math.max(0, ...rows.map(metric))
    if (!(mx > 0)) return
    pts.push({ t: w.start, y: mx, d: w.d, sets: rows, target: representative?.target })
    const better = mode === 'reps' && !repsOnly ? betterWeight(id, best || mx, mx) : Math.max(best, mx)
    best = best > 0 ? better : mx
  })

  const e1 = mode === 'reps' ? e1rmSeries(S, id) : []
  const e1Best = mode === 'reps' ? best1RM(S, id) : null
  const rir = pts.map(p => avgRir(p.sets))
  const showEff = rir.filter(v => v != null).length >= 3
  const metrics = [{ value: 'top', label: t('Top set') }]
  if (e1.length) metrics.push({ value: 'e1rm', label: t('Est. 1RM') })
  if (showEff) metrics.push({ value: 'effort', label: t('Effort') })
  const bestSet = bestSetFor(S, id, mode)

  return {
    id, name: nameOf(S, id), mode, unit, scale: hd,
    // RIR runs the other way up: less left in the tank is the harder set, drawn higher.
    invertEffort: kind === 'rir',
    metrics,
    top: pts.map((p, i) => ({
      t: p.t, d: p.d, y: p.y,
      // 0 RIR (nothing left) is a full dot, 4+ a faint one; unrated sessions keep the plain line.
      m: rir[i] == null ? null : 1 - Math.min(4, Math.max(0, rir[i])) / 4,
      note: rir[i] == null ? null : hd + ' ' + fmtNum(toScale(kind, rir[i])),
    })),
    e1rm: e1.map(p => ({ t: p.t, d: p.d, y: p.y })),
    effort: showEff ? pts.map((p, i) => (rir[i] == null ? null : { t: p.t, d: p.d, y: toScale(kind, rir[i]) })).filter(Boolean) : [],
    captions: {
      top: cardio ? t('Top speed per workout') : timed ? t('Longest hold per workout') : repsOnly ? t('Most reps in a set per workout') : t('Best set weight per workout'),
      e1rm: t('Estimated 1RM per workout'),
      effort: t('Average effort per workout'),
    },
    best: { top: fmtNum(best) + ' ' + unit, e1rm: e1Best ? fmtNum(e1Best.est) + ' ' + S.unit : null },
    bestLabel: t('Best:'),
    e1rmNote: e1Best ? t('Best estimate from {0} on {1} — an estimate, not a tested max.', fmtNum(e1Best.w) + ' ' + S.unit + ' × ' + e1Best.r, fmtDate(e1Best.d, true)) : null,
    effortNote: showEff ? t('A fuller dot means less left in the tank — the same weight at a lower {0} is progress the line alone does not show.', hd) : null,
    recent: pts.slice(-5).reverse().map(p => ({
      d: p.d, date: fmtDate(p.d, true), sets: p.sets.map(s => setLabel(id, s, p.target, speedUnit)).join('  '),
    })),
    bestSet: bestSet ? { d: bestSet.d, date: fmtDate(bestSet.d, true), text: setLabel(id, bestSet.set, bestSet.target, speedUnit) } : null,
    sessions: pts.length,
  }
}

/**
 * sheets.jsx ExerciseHistory, the sheet opened from an exercise in a workout: the curve (top set,
 * or the estimated 1RM), the best, and the last sessions set by set.
 */
export function historySheet(id) {
  const S = need()
  const h = exerciseHistory(S, id)
  const unit = h.metric === 'weight' ? S.unit : h.metric === 'reps' ? t('reps') : h.metric === 'sec' ? 's' : t('min')
  const e1Best = Math.max(0, ...h.e1rmPoints.map(p => p.y))
  const speedUnit = speedUnitOf(S)
  return {
    name: exerciseNameText(exOr(id)),
    total: h.total,
    subtitle: `${t('Exercise history')} · ${t(h.total === 1 ? '{0} session' : '{0} sessions', h.total)}`,
    empty: t('No sessions logged yet'),
    unit, e1rmUnit: S.unit,
    points: h.points.map(p => ({ t: p.t, d: p.d, y: p.y })),
    // Only reps work with a load produces an estimate, so the toggle is absent for the rest.
    e1rm: h.metric === 'weight' ? h.e1rmPoints : [],
    bestLabel: t('Best:'),
    best: fmtNum(h.best) + ' ' + unit,
    e1rmBest: e1Best > 0 ? fmtNum(e1Best) + ' ' + S.unit : null,
    sessionsTitle: h.sessions.length < h.total ? t('Last {0} sessions', h.sessions.length) : t('Sessions'),
    sessions: h.sessions.map((s, i) => ({
      key: String(s.id ?? s.t ?? i),
      date: fmtDate(s.d, true),
      pr: !!s.pr,
      sets: s.sets.map(x => setLabel(id, x, s.target, speedUnit)).join('  ·  '),
      tail: [
        s.volume > 0 && t('Volume') + ' ' + fmtVol(s.volume, S.unit),
        s.e1rm != null && t('Est. 1RM') + ' ' + fmtNum(s.e1rm) + ' ' + S.unit,
      ].filter(Boolean).join(' · ') || null,
      value: s.value != null && s.value > 0 ? fmtNum(s.value) + ' ' + unit : null,
    })),
  }
}

/* ------------------------------ the 1RM calculator ------------------------------ */

/**
 * sheets.jsx OneRM: the estimate the log already implies, and a calculator for a set not done
 * yet, opening on the best set (or the exercise's working weight × 5). The table reads the
 * estimate back as the load for 1–12 reps, by Epley the other way round (structuralBalance.js
 * loadForReps), so a 1RM turns into something to put on the bar.
 * `available` is false for cardio and assistance machines, which openGym gives no 1RM.
 */
export function oneRM(id, w = null, r = null) {
  const S = need()
  const best = best1RM(S, id)
  const weight = w ?? (best ? best.w : (S.exWeights?.[id] || {}).w || 20)
  const reps = r ?? (best ? best.r : 5)
  const est = estimate1RM(weight, reps)
  return {
    available: !isCardio(id) && !isAssisted(id),
    unit: S.unit, w: weight, r: reps, step: 2.5,
    title: t('Estimated 1RM'),
    fromLog: best ? {
      label: t('From your log:'),
      value: fmtNum(best.est) + ' ' + S.unit,
      line: t('{0} × {1} on {2}', fmtNum(best.w) + ' ' + S.unit, best.r, fmtDate(best.d, true)),
    } : null,
    weightLabel: t('Weight ({0})', S.unit),
    repsLabel: t('Reps'),
    estimateLabel: t('Estimate'),
    estimate: est,
    estimateText: est === null ? '—' : fmtNum(est) + ' ' + S.unit,
    note: est === null
      ? t('Enter a weight and 1–{0} reps — beyond that an estimate is guesswork.', REP_CAP)
      : t('Epley formula — a calculation from one set, not a tested max.'),
    table: est === null ? [] : Array.from({ length: REP_CAP }, (_, i) => {
      const n = i + 1
      const load = Math.round(loadForReps(est, n) * 10) / 10
      return { reps: n, w: load, text: fmtNum(load) + ' ' + S.unit, pct: Math.round(100 / (n > 1 ? 1 + n / 30 : 1)) }
    }),
  }
}

/* ------------------------------ the activity heatmap ------------------------------ */

const normalizeMetric = value => (value === 'vol' ? 'vol' : 'time')
// Heatmap.jsx: a record with entries is recomputed from its sets; a legacy one has only `vol`.
const volumeOf = w => {
  if (Array.isArray(w?.entries)) return Math.max(0, Number(workoutVolume(w)) || 0)
  const volume = Number(w?.vol)
  return Number.isFinite(volume) ? Math.max(0, volume) : 0
}

/**
 * Heatmap.jsx: the last 12 months as 53 week columns from the profile's first weekday, each day
 * shaded 0–4 by quartile of the chosen metric ('time' minutes or 'vol' volume) across the days
 * trained. Level 1 is a workout with nothing measured.
 */
export function heatmap(metric = null, now = Date.now()) {
  const S = need()
  const m = normalizeMetric(metric ?? S.heatmapMetric)
  const key = m === 'vol' ? 'vol' : 'min'
  const agg = {}
  ;(S.workouts || []).forEach(w => {
    const day = workoutDay(w)
    if (!day) return
    const a = agg[day] = agg[day] || { n: 0, vol: 0, min: 0 }
    a.n++
    a.vol += volumeOf(w)
    a.min += Math.max(0, Math.round(workoutDuration(w) / 60000))
  })
  const values = Object.values(agg).map(a => a[key]).filter(v => v > 0).sort((a, b) => a - b)
  const q = p => (values.length ? values[Math.min(values.length - 1, Math.floor(p * values.length))] : 0)
  const t1 = q(0.25), t2 = q(0.5), t3 = q(0.75)
  const level = a => !a ? 0 : !a[key] ? 1 : a[key] >= t3 ? 4 : a[key] >= t2 ? 3 : a[key] >= t1 ? 2 : 1

  const today = new Date(now); today.setHours(12, 0, 0, 0)
  const todayIso = isoOf(today)
  const ws = weekStartOf(S)
  const end = new Date(today); end.setDate(today.getDate() - weekDayOffset(today.getDay(), ws))
  const start = new Date(end); start.setDate(end.getDate() - 52 * 7)

  const dayLabels = Array(7).fill('')
  dayLabels[weekDayOffset(1, ws)] = t('Mon')
  dayLabels[weekDayOffset(3, ws)] = t('Wed')
  dayLabels[weekDayOffset(5, ws)] = t('Fri')

  const weeks = []
  let lastMonth = -1
  for (let wk = 0; wk <= 52; wk++) {
    const colStart = new Date(start); colStart.setDate(start.getDate() + wk * 7)
    const mo = colStart.getMonth()
    const month = mo !== lastMonth && colStart.getDate() <= 7 && wk < 51 ? t(MONTHS[mo]) : ''
    if (colStart.getDate() <= 7) lastMonth = mo
    const days = []
    for (let d = 0; d < 7; d++) {
      const day = new Date(colStart); day.setDate(colStart.getDate() + d)
      const iso = isoOf(day)
      const a = agg[iso]
      days.push({
        iso, level: level(a), n: a ? a.n : 0, today: iso === todayIso, future: day > today,
        tip: a ? `${fmtDate(iso, true)} · ${t(a.n === 1 ? '{0} workout' : '{0} workouts', a.n)} · ${t('{0} min', a.min)} · ${fmtVol(a.vol, S.unit)}` : null,
      })
    }
    weeks.push({ month, days })
  }
  return {
    metric: m,
    title: t('Activity — last 12 months'),
    options: [{ value: 'time', label: t('Time') }, { value: 'vol', label: t('Volume') }],
    dayLabels, weeks,
    less: t(m === 'vol' ? 'Less volume' : 'Less time'),
    more: t(m === 'vol' ? 'More volume' : 'More time'),
  }
}

/** The heatmap's Time / Volume choice, kept in the profile as openGym does (S.heatmapMetric). */
export function setHeatmapMetric(metric) {
  need().heatmapMetric = normalizeMetric(metric)
  return true
}

/* ------------------------------ effort ------------------------------ */

/**
 * Stats.jsx EffortCard for a window of `days` (0 = everything): the average, the share of hard
 * sets, how much of the training was rated, week by week, and where the sets land on the scale.
 */
export function effortCard(days = 90) {
  const S = need()
  const kind = displayScale(S)
  const hd = scaleName(kind)
  const sum = effortSummary(S, days)
  const weeks = effortWeeks(S, days)
  const hist = effortHistogram(S, days)
  const maxBin = Math.max(1, ...hist.map(b => b.n))
  const binLabel = b => kind === 'rpe' ? (b.tail ? '≤ 6' : String(10 - b.rir)) : (b.tail ? b.rir + '+' : String(b.rir))
  return {
    title: t('Effort'),
    subtitle: t('how close to failure'),
    windows: [{ value: 30, label: '30d' }, { value: 90, label: '90d' }, { value: 365, label: '1Y' }, { value: 0, label: t('All') }],
    scale: hd,
    invert: kind === 'rir',
    rated: sum.rated,
    empty: t('No rated sets in this period.'),
    average: sum.avg == null ? '—' : fmtNum(toScale(kind, sum.avg)) + ' ' + hd,
    averageLabel: t('average effort'),
    hard: sum.hardPct == null ? '—' : Math.round(sum.hardPct * 100) + '%',
    hardLabel: t('at {0} {1} or harder', hd, fmtNum(toScale(kind, HARD_RIR))),
    coverage: t('{0} of {1} finished sets rated', sum.rated, sum.done),
    off: effortOf(S) === 'none' ? t('Effort per set is switched off — turn it on in Settings to keep rating.') : null,
    weeksTitle: t('Week by week'),
    weeks: weeks.map(w => ({ t: w.t, y: toScale(kind, w.rir), note: t('{0} sets', w.sets) })),
    binsTitle: t('Where the sets land'),
    bins: hist.map(b => ({
      label: hd + ' ' + binLabel(b), n: b.n, frac: b.n / maxBin, hard: b.rir <= HARD_RIR,
      value: b.n ? b.n + ' · ' + Math.round(b.pct * 100) + '%' : '—',
    })),
    footer: t('Most working sets belong close to failure without living there — half at the floor and half at the top average out to a healthy-looking middle.'),
  }
}

/* ------------------------------ structural balance ------------------------------ */

const templateOf = S => (Object.prototype.hasOwnProperty.call(TEMPLATES, S.balanceTemplate) ? TEMPLATES[S.balanceTemplate] : TEMPLATES[DEFAULT_TEMPLATE_ID])

/**
 * StructuralBalance.jsx: the chosen ratio table, each lift against its target. `status` is the
 * engine's ('balanced', 'borderline', 'weak', 'no-data'), worded by balanceStatusView.
 */
export function balance() {
  const S = need()
  const template = templateOf(S)
  const results = computeBalance(S, template)
  return {
    title: t('Structural balance'),
    subtitle: t('Compare your lifts against a published ratio table to find the weak link.'),
    template: template.id,
    templates: TEMPLATE_LIST.map(tpl => ({ id: tpl.id, label: t(tpl.label) })),
    rows: results.map(r => {
      const role = template.roles.find(x => x.id === r.roleId)
      const view = balanceStatusView(r.status, r.needsAnchor)
      const exId = r.mappedExerciseId || r.configuredExerciseId
      const reps = role.evaluationMode === EVALUATION_MODES.REP_COUNT
      const actual = r.status === 'no-data' ? '—' : reps ? r.current.r : `${Math.round(r.actualPct)}%`
      return {
        role: r.roleId,
        label: t(role.label),
        exercise: exId ? exerciseNameText(exOr(exId)) : null,
        exerciseId: exId || null,
        custom: r.isOverridden,
        status: r.status,
        statusLabel: t(view.label),
        value: `${actual} / ${r.targetPct}${reps ? '' : '%'}`,
        needsBodyweight: !!r.needsBodyweight,
        needsAnchor: !!r.needsAnchor,
      }
    }),
  }
}

export function setBalanceTemplate(id) {
  if (!Object.prototype.hasOwnProperty.call(TEMPLATES, id)) throw new Error('Unknown template')
  need().balanceTemplate = id
  return true
}

/** A role's exercise, or back to the table's own (null). */
export function setBalanceExercise(roleId, exId, now = Date.now()) {
  const S = need()
  const template = templateOf(S)
  const role = template.roles.find(x => x.id === roleId)
  if (!role) throw new Error('Unknown lift')
  S.balanceOverrides = withOverride(S.balanceOverrides, overrideKey(template, role), exId || null, now)
  return true
}

/* ------------------------------ muscle maps ------------------------------ */

const muscleName = slug => t(MUSCLE_NAME[slug] || slug)

/**
 * What every body map needs besides its geometry (body-paths.json): which outline set to draw
 * (Settings → Appearance → Body diagram, S.body), the muscles that take a shade in head-to-toe
 * order with their names, and the parts drawn only as the silhouette.
 */
export function bodyInfo() {
  const S = need()
  return {
    body: S.body === 'female' ? 'female' : 'male',
    muscles: MUSCLES.map(slug => ({ slug, name: muscleName(slug) })),
    inert: INERT,
  }
}

// Stats.jsx's fixed shade bands for the recovery maps (FATIGUE_LEVELS, STRENGTH_LEVELS). They
// live in the React view, which the engine cannot import, so they are carried over verbatim.
const FATIGUE_LEVELS = [
  { at: 0, level: 0 },
  { at: 0.15, level: 1 },
  { at: 0.25, level: 2 },
  { at: 0.4, level: 3 },
  { at: 0.55, level: 4, exclusive: true },
]
const STRENGTH_LEVELS = [
  { at: STRENGTH_FLOOR, level: 0 },
  { at: 0.625, level: 1 },
  { at: 0.75, level: 2 },
  { at: 0.875, level: 3 },
  { at: 1, level: 4 },
]

// Stats.jsx latestMuscleTraining: when each muscle last had a completed work set.
function latestMuscleTraining(workouts) {
  const latest = {}
  for (const workout of workouts || []) {
    const timestamp = Number(workout?.start || new Date(workout?.d).getTime())
    if (!Number.isFinite(timestamp)) continue
    for (const entry of workout.entries || []) {
      if (!(entry.sets || []).some(set => set?.done === true && !isWarmupRow(set))) continue
      const exercise = EXIDX[entry.id] || entry.exercise || entry
      for (const slug of Object.keys(musclesOf(exercise))) {
        if (latest[slug] == null || timestamp > latest[slug]) latest[slug] = timestamp
      }
    }
  }
  return latest
}
// Stats.jsx weeksSinceTraining.
const weeksSinceTraining = (now, lastTrained) => Math.max(0, Math.floor((now - lastTrained) / DAY_MS / 7))

// Stats.jsx MuscleBalance: the user's own last weigh-in drives bodyweight-exercise tonnage.
function bodyweightKgOf(S) {
  const entries = S.bodyweight || []
  if (!entries.length) return null
  const last = entries.slice().sort((a, b) => String(a.d).localeCompare(String(b.d))).at(-1)
  if (!last || !(last.w > 0)) return null
  return S.unit === 'lb' ? last.w * LB_TO_KG : last.w
}

/**
 * Stats.jsx MuscleBalance, one of its three maps:
 *   'balance'  — sets per muscle in a window (`win` 7 = this week, 30, 90, 0 = all), or only the
 *                hard ones (`hard`, offered when the window holds rated sets)
 *   'fatigue'  — how recently each muscle was trained (lib/recovery.js), on fixed bands
 *   'strength' — retained strength since each muscle was last trained; a `selected` muscle
 *                lists its exercises with their estimated 1RM (lib/strength-exercises.js)
 * `levels` (0–4 per muscle) is what the map shades; `palette` says which colours.
 */
export function muscleBalance({ view = 'balance', win = 7, hard = false, selected = null } = {}, now = Date.now(), today = todayISO()) {
  const S = need()
  const mode = view === 'fatigue' || view === 'strength' ? view : 'balance'
  const sel = MUSCLES.includes(selected) ? selected : null
  const base = {
    view: mode,
    views: [
      { value: 'balance', label: t('Muscle balance') },
      { value: 'fatigue', label: t('Fatigue') },
      { value: 'strength', label: t('Strength') },
    ],
    body: S.body === 'female' ? 'female' : 'male',
    selected: sel,
    selectedName: sel ? muscleName(sel) : null,
  }
  const opts = { bodyweightKg: bodyweightKgOf(S), unit: S.unit }

  if (mode === 'fatigue') {
    const fatigue = fatigueOf(S.workouts, now, opts)
    const state = sel ? fatigueStateOf(fatigue[sel]) : null
    return {
      ...base, palette: 'fatigue', title: t('Fatigue'),
      levels: levelsOf(fatigue, FATIGUE_LEVELS),
      legend: [{ label: t('Fatigued'), level: 4 }, { label: t('Recovering'), level: 2 }, { label: t('Ready'), level: 0 }],
      note: t('Fatigue shows how recently each muscle was trained. High means rest.'),
      selectedValue: state ? t(state === 'ready' ? 'Ready' : state === 'recovering' ? 'Recovering' : 'Fatigued') : null,
    }
  }

  if (mode === 'strength') {
    const strength = strengthOf(S.workouts, now, opts)
    const lastTrained = latestMuscleTraining(S.workouts)
    const hint = slug => lastTrained[slug] == null ? t('not trained') : t('Weeks since training: {0}', weeksSinceTraining(now, lastTrained[slug]))
    const volWin = S.workouts.filter(w => (w.start || new Date(w.d).getTime()) > now - 90 * DAY_MS)
    const vol90 = loadOfWorkouts(volWin, null)
    const { worked: order } = rankOf(strength)
    return {
      ...base, palette: 'strength', title: t('Strength'),
      levels: levelsOf(strength, STRENGTH_LEVELS),
      legend: [{ label: '1 ' + t('full'), level: 4 }, { label: '', level: 3 }, { label: '', level: 2 }, { label: '', level: 1 }, { label: fmtNum(STRENGTH_FLOOR) + ' ' + t('floor'), level: 0 }],
      note: t('Strength shows retained muscle strength. Train again to reset it.'),
      exercisesTitle: sel ? `${t('Exercises')} · ${muscleName(sel)}` : null,
      exercises: sel ? strengthExerciseRowsForMuscle(S, now, sel).map(row => ({
        // The catalogue's display name (capitalised as the rest of the app shows it), else the logged one.
        id: row.id, name: EXIDX[row.id] ? exerciseNameText(EXIDX[row.id]) : row.name,
        role: row.primary === sel ? t('primary') : t('secondary'),
        estimate: `${t('Est. 1RM')}: ${fmtNum(row.est)} ${S.unit} · ${fmtDate(row.estDate, true)}`,
        frac: row.decay,
        value: `${fmtNum(row.current)} ${S.unit} · ${Math.round(row.decay * 100)}%`,
      })) : [],
      noExercises: t('No exercises with an estimated 1RM yet.'),
      hint: sel ? null : t('Tap a muscle to see its exercises.'),
      detrained: order.filter(slug => strength[slug] < 1).map(slug => {
        const sets90 = Math.round((vol90[slug] || 0) * 10) / 10
        return {
          slug, name: muscleName(slug), frac: strength[slug],
          value: sets90 ? t('{0} sets', fmtNum(sets90)) : hint(slug),
          detail: sets90 ? hint(slug) : null,
        }
      }),
    }
  }

  const inWin = muscleBalanceWindow(S.workouts, win, now, today, weekStartOf(S))
  // Only offered when the window holds ratings: with none, the hard map would read as nothing trained.
  const rated = inWin.some(w => w.entries.some(e => e.sets.some(s => s.done && isHardSet(s))))
  const on = !!hard && rated
  const load = loadOfWorkouts(inWin, on ? isHardSet : null)
  const { worked, missed } = rankOf(load)
  const max = worked.length ? load[worked[0]] : 0
  const sets = m => fmtNum(Math.round((load[m] || 0) * 10) / 10)
  return {
    ...base, palette: 'balance', title: t('Muscle balance'),
    subtitle: on ? t('by hard sets') : t('by sets worked'),
    windows: [{ value: 7, label: t('Week') }, { value: 30, label: '30d' }, { value: 90, label: '90d' }, { value: 0, label: t('All') }],
    win,
    hardShown: rated, hard: on, hardLabel: on ? t('Hard') : t('All'),
    levels: levelsOf(load),
    legend: [{ label: t('Less'), level: 0 }, { label: '', level: 1 }, { label: '', level: 2 }, { label: '', level: 3 }, { label: t('More'), level: 4 }],
    empty: inWin.length ? null : t('No workouts in this period yet.'),
    selectedValue: sel ? (load[sel] ? t('{0} sets', sets(sel)) : on ? t('no hard sets') : t('not trained')) : null,
    top: worked.slice(0, 4).map(m => ({ slug: m, name: muscleName(m), frac: max ? load[m] / max : 0, value: t('{0} sets', sets(m)) })),
    missedTitle: missed.length ? (on ? t('No hard sets in this period') : t('Not trained in this period')) : null,
    missed: missed.map(muscleName),
    allWorked: !missed.length && worked.length ? (on ? t('Every muscle group got at least one hard set in this period.') : t('Every muscle group got some work in this period.')) : null,
  }
}
