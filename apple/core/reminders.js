// Workout-day reminders: openGym's buildReminderNotifications (frontend/src/lib/mobile.js),
// which imports Capacitor, restated on the same helpers so it runs in JavaScriptCore. Swift
// schedules what this returns with UNUserNotificationCenter.
import { need } from './actions.js'
import { effectiveRoutineIds } from '../../frontend/src/lib/history.js'
import { isoOf } from '../../frontend/src/lib/format.js'

export const WINDOW_DAYS = 14

/** The reminder setting ({ on, time: 'HH:MM' }). */
export function reminder() {
  const r = need().reminder || {}
  return { on: !!r.on, time: r.time || '08:00' }
}

export function setReminder(patch) {
  const S = need()
  S.reminder = { ...(S.reminder || {}), ...patch, tz: Intl.DateTimeFormat().resolvedOptions().timeZone }
  return reminder()
}

/**
 * One notification per upcoming day in the window that has a routine planned and no workout
 * logged yet: [{ iso, at (ms), routines: [names], count }]. Empty when reminders are off.
 */
export function upcoming(nowMs = Date.now()) {
  const S = need()
  const r = S.reminder
  if (!r?.on) return []
  const routines = Array.isArray(S.routines) ? S.routines : []
  const done = new Set((S.workouts || []).map(w => w.d))
  const state = { ...S, routines, week: S.week || {}, dayPlan: S.dayPlan || {} }
  const [hour, minute] = (r.time || '08:00').split(':').map(Number)
  if (!Number.isInteger(hour) || !Number.isInteger(minute)) return []
  const now = new Date(nowMs)
  const base = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 12)
  const out = []
  for (let i = 0; i < WINDOW_DAYS; i++) {
    const day = new Date(base)
    day.setDate(base.getDate() + i)
    const iso = isoOf(day)
    if (done.has(iso)) continue
    const list = effectiveRoutineIds(state, iso).map(id => routines.find(x => x.id === id)).filter(Boolean)
    if (!list.length) continue
    const at = new Date(day)
    at.setHours(hour, minute, 0, 0)
    if (at <= now) continue
    out.push({ iso, at: at.getTime(), routines: list.map(x => x.name), count: list.length })
  }
  return out
}
