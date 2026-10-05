// GPS walks, runs and rides (GymFree addition). A tracked activity is filed as an ordinary
// openGym workout: one cardio entry logged as minutes at the average speed (history.js: cardio
// sets look like { min, speed }, speed always in km/h), so History, the calendar, the week strip,
// the streak, backups and openGym itself read it like any other session. GymFree's own summary
// rides along on the record as `gfActivity` (openGym keeps fields it does not know). The route
// itself is not in the profile: the app keeps it in a file on the device (RouteStore.swift).
import { need } from './actions.js'
import { t, dateLocale } from './i18n-native.js'
import { uid, isoOf, fmtDate, durPart } from '../../frontend/src/lib/format.js'
import { stampWorkout } from '../../frontend/src/lib/sync-merge.js'
import { insertChronological } from '../../frontend/src/lib/backfill.js'
import { speedUnitOf, fmtSpeed } from '../../frontend/src/lib/speed.js'

/** What can be tracked, and the catalogue exercise each is logged as. */
export const KINDS = {
  walk: { ex: 'gf-walk', name: 'Walk' },
  run: { ex: '0685', name: 'Run' },
  cycle: { ex: 'gf-cycling', name: 'Ride' },
}

const M_PER_MI = 1609.344
const round = (n, p) => Math.round(n * p) / p

/** "2.34 km" or "1.45 mi": distances follow the profile's speed unit. */
export function distanceText(meters, speedUnit) {
  const v = speedUnit === 'mph' ? meters / M_PER_MI : meters / 1000
  const n = v.toLocaleString(dateLocale(), { minimumFractionDigits: 2, maximumFractionDigits: 2 })
  return `${n} ${speedUnit === 'mph' ? 'mi' : 'km'}`
}

/** "5:41 /km": time per kilometre (or mile); null without a distance worth dividing by. */
export function paceText(seconds, meters, speedUnit) {
  if (!(meters >= 10) || !(seconds > 0)) return null
  const per = seconds / (speedUnit === 'mph' ? meters / M_PER_MI : meters / 1000)
  if (!Number.isFinite(per) || per >= 100 * 60) return null
  let m = Math.floor(per / 60)
  let s = Math.round(per - m * 60)
  if (s === 60) { m += 1; s = 0 }
  return `${m}:${String(s).padStart(2, '0')} /${speedUnit === 'mph' ? 'mi' : 'km'}`
}

/**
 * Files a finished activity and returns its key (the workout id).
 * spec: { kind, start, end (ms), movingSec, meters, ascent?, route?, name? }
 */
export function logActivity(spec, now = Date.now()) {
  const kind = KINDS[spec?.kind] ? spec.kind : null
  if (!kind) throw new Error('Unknown activity')
  const start = Number(spec.start), end = Number(spec.end)
  if (!(start > 0) || !(end > start)) throw new Error('An activity needs a start and an end')
  const meters = Math.max(0, Number(spec.meters) || 0)
  const movingSec = Math.min((end - start) / 1000, Math.max(0, Number(spec.movingSec) || (end - start) / 1000))
  const min = Math.max(1, Math.round(movingSec / 60))
  // km/h over the moving time, to a tenth: what openGym shows next to the minutes.
  const speed = movingSec > 0 ? round((meters / 1000) / (movingSec / 3600), 10) : 0
  const S = need()
  const w = {
    id: uid(),
    d: isoOf(new Date(start)),
    start, end,
    routineIds: [], routineId: null,
    name: String(spec.name || t(KINDS[kind].name)),
    bw: null,
    entries: [{ id: KINDS[kind].ex, sets: [{ min, speed, done: true }], topW: null, target: { sets: 1, min, speed } }],
    prs: [],
    vol: 0,
    gfActivity: {
      kind,
      m: Math.round(meters),
      movingSec: Math.round(movingSec),
      ...(Number(spec.ascent) > 0 ? { ascent: Math.round(Number(spec.ascent)) } : {}),
      route: !!spec.route,
    },
  }
  stampWorkout(w, now)
  S.workouts = insertChronological(S.workouts, w)
  return w.id
}

/** Remembers the Apple Health workout an activity was saved as. */
export function setActivityHealthId(key, uuid, now = Date.now()) {
  const w = need().workouts.find(x => x.id === key)
  if (!w?.gfActivity) return false
  w.gfActivity.hk = String(uuid)
  stampWorkout(w, now)
  return true
}

/** The activity part of a saved workout, worded for the screens; null for a strength session. */
export function activitySummary(S, w) {
  const a = w?.gfActivity
  if (!a || !KINDS[a.kind]) return null
  const unit = speedUnitOf(S)
  const moving = Number(a.movingSec) || Math.max(0, ((w.end || 0) - (w.start || 0)) / 1000)
  const kmh = moving > 0 ? (a.m / 1000) / (moving / 3600) : 0
  return {
    kind: a.kind,
    meters: a.m,
    movingSec: moving,
    ascent: a.ascent || null,
    route: !!a.route,
    hk: a.hk || null,
    distance: distanceText(a.m, unit),
    pace: paceText(moving, a.m, unit),
    speed: fmtSpeed(round(kmh, 10), unit),
    moving: durPart(moving * 1000)[0] || t('{0} min', 0),
    imperial: unit === 'mph',
  }
}

/** History's line for an activity: date · time · distance · pace (or speed on a ride). */
export function activityLine(S, w) {
  const a = activitySummary(S, w)
  if (!a) return null
  return [fmtDate(w.d, true), ...durPart(a.movingSec * 1000), a.distance, ...(a.kind === 'cycle' ? [a.speed] : a.pace ? [a.pace] : [])].join(' · ')
}

/** Every activity, newest first, with a route file to look for (for clean-up and tests). */
export const activityKeys = () => need().workouts.filter(w => w.gfActivity).map(w => w.id).reverse()

