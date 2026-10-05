// History, the Home screen's week and body weight, headless: the steps openGym's History view
// (views/History.jsx), Home (views/Home.jsx) and their sheets (sheets.jsx: WorkoutDetail,
// WorkoutDateEdit, WorkoutDurationEdit, Calendar, DayOverride, LogPastWorkout, BwSheet,
// WeighIns, GoalSheet) take. Same rules as actions.js: plain JSON in and out, worded through
// openGym's own i18n, and the profile is only changed here.
import { need } from './actions.js'
import { t } from './i18n-native.js'
import { EXIDX } from '../../frontend/src/lib/exercises.js'
import {
  effectiveRoutineIds, effectiveRoutines, nextTrainingDay, streakWeeks, lastBW, setsDone, setLabel,
  sessionSections, workoutVolume, workoutDay, NOTE_MAX,
} from '../../frontend/src/lib/history.js'
import {
  fmtDate, fmtNum, fmtVol, fmtDur, durPart, todayISO, isoOf, weekKey, weekStartOf, weekDayOffset,
  weekOrder, exerciseNameText, DAYS, DAYN, MONTHS_LONG,
} from '../../frontend/src/lib/format.js'
import { dateLocale } from './i18n-native.js'
import { speedUnitOf } from '../../frontend/src/lib/speed.js'
import { hasCompletedWork, isWarmupRow } from '../../frontend/src/lib/workout-model.js'
import { stampWorkout } from '../../frontend/src/lib/sync-merge.js'
import { workoutsOn } from '../../frontend/src/lib/backfill.js'
import { deriveSessionName } from '../../frontend/src/lib/session-merge.js'
import {
  legacySyncKey, sameWorkout, moveWorkout as moved, setWorkoutDuration, durationMinOf, startTimeOf,
} from '../../frontend/src/lib/workout-date.js'
import {
  editCompletedSession, saveWorkoutEdit, editChangesNothing, editLeftEmpty, deleteEditedWorkout,
} from '../../frontend/src/lib/session-edit.js'
import { workoutText } from '../../frontend/src/lib/workout-text.js'
import { saveSessionAsRoutine } from '../../frontend/src/lib/session-routines.js'
import { weeklyWeights } from '../../frontend/src/lib/bodyweight.js'

/* ------------------------------ workouts ------------------------------ */

// A workout is named by its id, or (from before ids) by the key the sync gives it.
const keyOf = w => (w?.id != null ? w.id : legacySyncKey(w))
const ref = key => ({ id: key })
const workoutAt = key => need().workouts.find(w => sameWorkout(w, ref(key))) || null
const nameOf = e => (EXIDX[e.id] ? exerciseNameText(EXIDX[e.id]) : (e.n || e.id))
const routineIdOf = w => w.routineId || [].concat(w.routineIds || [])[0] || null

/** sheets.jsx WorkoutRow: one line per workout, newest first. */
export function historyRows() {
  const S = need()
  return [...S.workouts].reverse().map(w => ({
    key: keyOf(w),
    d: w.d,
    name: w.name || '',
    emoji: (S.routines.find(r => r.id === routineIdOf(w)) || {}).emoji || null,
    line: [fmtDate(w.d, true), ...durPart(w.end - w.start), t('{0} sets', setsDone(w)), fmtVol(w.vol || 0, S.unit)].join(' · '),
    prs: (w.prs || []).length,
  }))
}

/** History's subtitle. */
export const historyCount = () => t('{0} workouts', need().workouts.length)

/**
 * sheets.jsx WorkoutDetail: the header line, then the exercises in the sections the sheet shows
 * (one per routine of a combined session, supersets kept together), with their PR badges.
 */
export function workoutDetail(key) {
  const S = need()
  const w = workoutAt(key)
  if (!w) return null
  const speedUnit = speedUnitOf(S)
  const entry = i => {
    const e = w.entries[i]
    return {
      idx: i, id: e.id, name: nameOf(e),
      pr: !!(w.prs && w.prs.includes(e.id)),
      sets: e.sets.filter(hasCompletedWork).map(s => setLabel(e.id, s, e.target, speedUnit)).join('  ·  ') || t('no sets'),
      note: e.note || null, notePin: !!e.notePin,
    }
  }
  const groups = sessionSections(w.entries)
  const grouped = groups.length > 1 || !!(groups[0] && groups[0].rid && (w.routineIds || []).length > 1)
  const sections = (grouped ? groups : groups.slice(0, 1)).map(g => {
    const r = g.rid ? S.routines.find(x => x.id === g.rid) : null
    const items = g.items.map(i => w.entries[i])
    const setN = items.reduce((n, e) => n + e.sets.filter(s => s.done && !isWarmupRow(s)).length, 0)
    return {
      title: grouped ? (r ? r.name : t('Freestyle')) : null,
      emoji: r ? r.emoji || null : null,
      summary: grouped ? `${t('{0} sets', setN)} · ${fmtVol(workoutVolume({ entries: items }), S.unit)}` : null,
      units: g.units.map(unit => unit.map(entry)),
    }
  })
  return {
    key: keyOf(w), d: w.d, name: w.name || '',
    line: [fmtDate(w.d, true), ...durPart(w.end - w.start), fmtVol(w.vol || 0, S.unit), ...(w.bw ? [fmtNum(w.bw) + ' ' + S.unit] : [])].join(' · '),
    note: w.note || '',
    durationMin: durationMinOf(w),
    startTime: startTimeOf(w),
    prs: (w.prs || []).length,
    sections,
    // The editor and a date move need no session running (WorkoutDetail disables Edit).
    busy: !!S.active,
  }
}

/** WorkoutDetail's note box: an edit of the saved workout, stamped only when it changed. */
export function setWorkoutNote(key, text, now = Date.now()) {
  const rec = workoutAt(key)
  if (!rec) return false
  const note = String(text || '').trim().slice(0, NOTE_MAX)
  if (note === (rec.note || '')) return false
  if (note) rec.note = note; else delete rec.note
  stampWorkout(rec, now)
  return true
}

/** WorkoutDateEdit: refuses a day after today; a no-op or a deleted workout changes nothing. */
export function moveWorkout(key, iso, time, today = todayISO(), now = Date.now()) {
  const S = need()
  if (!iso || iso > today) throw new Error('Pick a day up to today')
  const w = workoutAt(key)
  if (!w || (iso === w.d && time === startTimeOf(w))) return false
  const next = moved(S.workouts, w, iso, time, now)
  if (!next) return false
  S.workouts = next
  return true
}

/** WorkoutDurationEdit: at least a minute; false when nothing changed. */
export function setDuration(key, minutes, now = Date.now()) {
  if (!(minutes >= 1)) throw new Error('Enter how long it took — at least 1 minute.')
  const S = need()
  const next = setWorkoutDuration(S.workouts, ref(key), minutes, now)
  if (!next) return false
  S.workouts = next
  return true
}

/** WorkoutDetail's Delete, matched the way the edits are (a legacy record has no id). */
export function deleteWorkout(key) {
  const S = need()
  const before = S.workouts.length
  S.workouts = S.workouts.filter(x => !sameWorkout(x, ref(key)))
  return S.workouts.length < before
}

/** "Copy as text", with the note as it stands in the box (which may not be saved yet). */
export function copyText(key, note = null) {
  const S = need()
  const w = workoutAt(key)
  if (!w) return null
  const rec = note == null ? w : { ...w, note: String(note).trim() }
  return workoutText(rec, { unit: S.unit, nameOf, speedUnit: speedUnitOf(S) })
}

/** "Save as routine": an independent routine from the session's targets. Returns its id. */
export function saveAsRoutine(key) {
  const S = need()
  const w = workoutAt(key)
  if (!w) throw new Error('Workout deleted')
  return saveSessionAsRoutine(S, w, w.name)
}

/* ------------------------------ editing a saved workout ------------------------------ */

/** "Edit workout": a copy becomes the running session, on the ordinary workout screen. */
export function editWorkout(key) {
  editCompletedSession(need(), key)
  return true
}

/**
 * sheets.jsx saveWorkoutEdits: `{ empty: true }` when no set is left (the screen offers to delete
 * the workout instead), otherwise saves and returns `{ saved: true }`.
 */
export function saveEdit(now = Date.now()) {
  const S = need()
  if (!S.active?.editingWorkoutId) return { saved: false }
  if (editLeftEmpty(S.active)) return { empty: true }
  saveWorkoutEdit(S, now)
  return { saved: true }
}

/** Whether closing the editor loses nothing (it then just closes). */
export const editUnchanged = () => editChangesNothing(need())

/** "Don't save": the record stays exactly as it was. */
export function discardEdit() {
  const S = need()
  if (S.active?.editingWorkoutId) S.active = null
  return true
}

/** An edit that took out every set deletes the workout instead of saving it empty. */
export const deleteEdit = () => deleteEditedWorkout(need())

/* ------------------------------ the week and the calendar ------------------------------ */

const dotOf = (S, iso, done) => {
  const eff = effectiveRoutineIds(S, iso).length > 0
  const ovr = S.dayPlan[iso] !== undefined
  return done ? 'done' : ovr && eff ? 'ovr' : eff ? 'plan' : ''
}
const at = (iso, days) => { const d = new Date(iso + 'T12:00:00'); d.setDate(d.getDate() + days); return d }

/** Home's week strip: `offset` weeks from this one, each day with its dot. */
export function weekStrip(offset = 0, today = todayISO()) {
  const S = need()
  const ws = weekStartOf(S)
  const now = new Date(today + 'T12:00:00')
  const start = at(today, -weekDayOffset(now.getDay(), ws) + offset * 7)
  const done = new Set(S.workouts.map(w => w.d))
  const days = []
  for (let i = 0; i < 7; i++) {
    const d = new Date(start); d.setDate(start.getDate() + i)
    const iso = isoOf(d)
    days.push({ iso, label: t(DAYS[d.getDay()]), num: d.getDate(), dot: dotOf(S, iso, done.has(iso)), today: iso === today })
  }
  const end = new Date(start); end.setDate(start.getDate() + 6)
  const month = d => d.toLocaleDateString(dateLocale(), { month: 'short' })
  const label = offset === 0 ? t('This week') : `${start.getDate()} ${month(start)} – ${end.getDate()} ${month(end)}`
  return { label, days }
}

/**
 * Home's today row: what is planned, whether it is already done (the last session logged today),
 * and on a rest day when you train next.
 */
export function todayInfo(today = todayISO()) {
  const S = need()
  const routines = effectiveRoutines(S, today)
  const done = S.workouts.filter(w => w.d === today).at(-1) || null
  const next = !S.active && !routines.length ? nextTrainingDay(S, today) : null
  return {
    routineIds: routines.map(r => r.id),
    rescheduled: S.dayPlan[today] !== undefined && routines.length > 0 && !done,
    done: done ? { key: keyOf(done), name: done.name ? t('{0} — done', done.name) : t('Workout done') } : null,
    next: next && !done ? t('Next session: {0}, {1}', t(DAYN[next.weekday]), next.routine.name) : null,
  }
}

/** Home's streak card: weeks in a row, this week against the plan, the total. */
export function streak(today = todayISO()) {
  const S = need()
  const ws = weekStartOf(S)
  const thisWeek = S.workouts.filter(w => weekKey(w.d, ws) === weekKey(today, ws)).length
  const planned = Object.values(S.week).filter(ids => [].concat(ids || []).length).length
  return {
    title: t('{0} week streak', streakWeeks(S)),
    line: `${thisWeek}${planned ? ' / ' + planned : ''} ${t('this week')} · ${t(S.workouts.length === 1 ? '{0} workout total' : '{0} workouts total', S.workouts.length)}`,
  }
}

/** sheets.jsx DayOverride: what the day plans and whether it was missed. */
export function dayInfo(iso, today = todayISO()) {
  const S = need()
  const wd = new Date(iso + 'T12:00:00').getDay()
  const weekly = [].concat(S.week[wd] || []).map(id => S.routines.find(r => r.id === id)?.name).filter(Boolean)
  const planned = effectiveRoutineIds(S, iso)
  return {
    title: fmtDate(iso, true),
    weekly: weekly.length ? deriveSessionName(weekly) : t('Rest'),
    changed: S.dayPlan[iso] !== undefined,
    planned,
    // Planned, in the past, nothing logged: trained and never logged, or missed (#284).
    missed: iso < today && planned.length > 0 && !workoutsOn(S, iso).length,
    workouts: workoutsOn(S, iso).map(keyOf),
  }
}

/** The toast a day change shows. */
export function dayChangeText(iso, value) {
  const S = need()
  return value === '' ? t('Back to weekly plan') : value === 'rest' ? t('{0} set to rest', fmtDate(iso))
    : t('{0} planned for {1}', (S.routines.find(r => r.id === value) || {}).name, fmtDate(iso))
}

/** sheets.jsx Calendar: one month (`month` 0–11), each day with its dot and workouts. */
export function calendarMonth(year, month, today = todayISO()) {
  const S = need()
  const byDay = {}
  S.workouts.forEach(w => {
    const day = workoutDay(w)
    if (day) (byDay[day] = byDay[day] || []).push(w)
  })
  const ws = weekStartOf(S)
  const pad = n => String(n).padStart(2, '0')
  const prefix = year + '-' + pad(month + 1)
  const daysIn = new Date(year, month + 1, 0).getDate()
  const monthWs = S.workouts.filter(w => workoutDay(w)?.startsWith(prefix))
  const vol = monthWs.reduce((a, w) => a + (w.vol || 0), 0)
  const ms = monthWs.reduce((a, w) => a + Math.max(0, (w.end || w.start) - w.start), 0)
  const days = []
  for (let d = 1; d <= daysIn; d++) {
    const iso = prefix + '-' + pad(d)
    const list = byDay[iso] || []
    days.push({ iso, day: d, dot: dotOf(S, iso, list.length > 0), today: iso === today, workouts: list.map(keyOf) })
  }
  return {
    title: `${t(MONTHS_LONG[month])} ${year}`,
    summary: monthWs.length ? `${t(monthWs.length === 1 ? '{0} workout' : '{0} workouts', monthWs.length)} · ${fmtDur(ms)} · ${fmtVol(vol, S.unit)}` : t('No workouts this month'),
    headers: weekOrder(ws).map(d => t(DAYS[d])),
    blanks: weekDayOffset(new Date(year, month, 1).getDay(), ws),
    days,
  }
}

/** A combined day's session name ("Push + Pull"), for Log a past workout's routine picker. */
export const sessionName = ids => deriveSessionName([].concat(ids || []).map(id => need().routines.find(r => r.id === id)?.name).filter(Boolean)) || t('Freestyle')

/* ------------------------------ body weight ------------------------------ */

// The weight picker's range follows the unit: 300 kg, or 660 lb (sheets.jsx wHi).
const wHi = unit => (unit === 'lb' ? 660 : 300)
// Whether a change moves toward the goal (sheets.jsx bwDeltaColor): 'good', 'bad' or 'neutral'.
function toneOf(S, delta, current) {
  if (!delta || !S.targetW) return 'neutral'
  return (delta > 0) === (S.targetW > current) ? 'good' : 'bad'
}

/** Home's body weight card. */
export function weightCard() {
  const S = need()
  const bw = lastBW(S)
  const prev = S.bodyweight.length > 1 ? S.bodyweight[S.bodyweight.length - 2] : null
  const delta = bw && prev ? bw.w - prev.w : null
  const goal = S.targetW || null
  return {
    unit: S.unit, max: wHi(S.unit),
    show: S.showWeightCard !== false,
    weighIn: S.weighIn !== false,
    last: bw ? { d: bw.d, w: bw.w, date: fmtDate(bw.d, true) } : null,
    // Only when it actually moved: an unchanged weight read as "− 0".
    delta: delta ? delta : null,
    deltaText: delta ? fmtNum(Math.abs(delta)) : null,
    tone: toneOf(S, delta, bw?.w),
    goal,
    goalText: goal && bw ? `${t('Goal')} ${fmtNum(goal)} ${S.unit} · ${Math.abs(goal - bw.w) < 0.05 ? t('reached!') : t(goal > bw.w ? '{0} to gain' : '{0} to lose', fmtNum(Math.abs(goal - bw.w)) + ' ' + S.unit)}` : null,
    empty: S.weighIn === false ? t('No entries yet — log your weight to start the curve.')
      : t("No entries yet — log your weight to start the curve. It's also asked before every workout."),
    today: t('Today') + ', ' + fmtDate(todayISO(), true),
  }
}

/** Every weigh-in, oldest first, for the chart. */
export const weightSeries = () => need().bodyweight.filter(b => b?.d && Number(b.w) > 0).map(b => ({ d: b.d, w: Number(b.w) }))
  .sort((a, b) => (a.d < b.d ? -1 : a.d > b.d ? 1 : 0))

/** sheets.jsx WeighIns: week by week, each under its mean and how far that moved. */
export function weighIns() {
  const S = need()
  const weeks = weeklyWeights(S.bodyweight, weekStartOf(S))
  const n = weeks.reduce((sum, w) => sum + w.n, 0)
  return {
    count: n,
    title: t(n === 1 ? '{0} weigh-in' : '{0} weigh-ins', n),
    weeks: weeks.map(w => {
      const moved = w.delta != null && fmtNum(Math.abs(w.delta)) !== fmtNum(0)
      return {
        key: w.key,
        title: t('Week of {0}', fmtDate(w.key)),
        avg: w.avg,
        average: t('Average {0}', fmtNum(w.avg) + ' ' + S.unit),
        delta: moved ? w.delta : null,
        deltaText: moved ? fmtNum(Math.abs(w.delta)) : null,
        tone: moved ? toneOf(S, w.delta, w.avg) : 'neutral',
        entries: w.entries.map(b => ({ d: b.d, w: Number(b.w), date: fmtDate(b.d, true), text: `${fmtNum(b.w)} ${S.unit}` })),
      }
    }),
  }
}

/** sheets.jsx BwSheet save: one weigh-in a day (today's is replaced), kept in date order. */
export function logWeight(value, iso = null, now = Date.now()) {
  iso = iso || todayISO()
  const n = Math.round((Number(value) || 0) * 10) / 10
  if (!n || n <= 0) throw new Error('Enter a valid weight')
  const S = need()
  const ex = S.bodyweight.find(b => b.d === iso)
  if (ex) { ex.w = n; ex.t = now } else S.bodyweight.push({ d: iso, w: n, t: now })
  S.bodyweight.sort((a, b) => (a.d < b.d ? -1 : 1))
  return n
}

export function deleteWeighIn(iso) {
  const S = need()
  S.bodyweight = S.bodyweight.filter(x => x.d !== iso)
  return true
}

/** GoalSheet: a target weight, or null to remove it. Returns the toast. */
export function setGoal(value) {
  const S = need()
  if (value == null) { S.targetW = null; return t('Goal removed') }
  const n = Math.round((Number(value) || 0) * 10) / 10
  if (!n || n <= 0) throw new Error('Enter a valid weight')
  S.targetW = n
  const b = lastBW(S)
  return t('Goal set: {0}', fmtNum(n) + ' ' + S.unit) + (b ? ' (' + t('{0} to go', fmtNum(Math.abs(n - b.w))) + ')' : '')
}
