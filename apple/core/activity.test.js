import { describe, it, expect, beforeEach } from 'vitest'
import * as A from './actions.js'
import * as H from './history-actions.js'
import * as G from './activity.js'
import { EXIDX } from '../../frontend/src/lib/exercises.js'

const st = () => JSON.parse(A.exportState())
// Monday 28 September 2026, 07:00 local.
const at = (h, m = 0) => new Date(2026, 8, 28, h, m).getTime()

describe('activities', () => {
  beforeEach(() => A.load(null))

  it('logs every kind as a catalogue cardio exercise', () => {
    for (const k of Object.values(G.KINDS)) expect(EXIDX[k.ex]?.bp).toBe('cardio')
  })

  it('files a walk as a cardio workout with its summary', () => {
    const key = G.logActivity({ kind: 'walk', start: at(7), end: at(7, 40), movingSec: 36 * 60, meters: 3240, ascent: 12.4, route: true })
    const w = st().workouts.find(x => x.id === key)
    expect(w.d).toBe('2026-09-28')
    expect(w.name).toBe('Walk')
    expect(w.vol).toBe(0)
    expect(w.entries).toHaveLength(1)
    expect(w.entries[0].id).toBe('gf-walk')
    // 3.24 km in 36 minutes is 5.4 km/h.
    expect(w.entries[0].sets).toEqual([{ min: 36, speed: 5.4, done: true }])
    expect(w.gfActivity).toEqual({ kind: 'walk', m: 3240, movingSec: 2160, ascent: 12, route: true })
    expect(w._ts).toBeGreaterThan(0)
  })

  it('keeps the history in date order', () => {
    G.logActivity({ kind: 'run', start: at(18), end: at(18, 30), meters: 5000 })
    G.logActivity({ kind: 'cycle', start: at(7), end: at(8), meters: 20000 })
    expect(st().workouts.map(w => w.name)).toEqual(['Ride', 'Run'])
  })

  it('refuses what is not an activity', () => {
    expect(() => G.logActivity({ kind: 'swim', start: at(7), end: at(8), meters: 1 })).toThrow()
    expect(() => G.logActivity({ kind: 'walk', start: at(8), end: at(7), meters: 1 })).toThrow()
    expect(st().workouts).toHaveLength(0)
  })

  it('shows distance and pace in History and the detail', () => {
    const key = G.logActivity({ kind: 'run', start: at(7), end: at(7, 31), movingSec: 30 * 60, meters: 5000, route: true })
    const row = H.historyRows()[0]
    expect(row.activity).toBe('run')
    expect(row.line).toContain('30 min')
    expect(row.line).toContain('5.00 km')
    expect(row.line).toContain('6:00 /km')
    const d = H.workoutDetail(key)
    expect(d.line).toBe(row.line)
    expect(d.activity).toMatchObject({ kind: 'run', meters: 5000, route: true, distance: '5.00 km', pace: '6:00 /km', speed: '10 km/h' })
    // The cardio entry still reads the openGym way.
    expect(d.sections[0].units[0][0].sets).toContain('30 min')
  })

  it('follows the speed unit: miles and minutes per mile', () => {
    A.patch({ speedUnit: 'mph' })
    const key = G.logActivity({ kind: 'walk', start: at(7), end: at(7, 20), movingSec: 20 * 60, meters: 1609.344 })
    const d = H.workoutDetail(key).activity
    expect(d.distance).toBe('1.00 mi')
    expect(d.pace).toBe('20:00 /mi')
    expect(d.imperial).toBe(true)
  })

  it('a strength workout has no activity', () => {
    A.beginWorkout([], null, 'Freestyle')
    A.addExercise('0025', null)
    A.toggleSet(0, 0, null, {})
    const w = A.finishWorkout().workout
    expect(H.workoutDetail(w.id).activity).toBeNull()
    expect(H.historyRows()[0].activity).toBeNull()
  })

  it('remembers its Apple Health workout', () => {
    const key = G.logActivity({ kind: 'cycle', start: at(7), end: at(8), meters: 20000 })
    expect(G.setActivityHealthId(key, 'ABC')).toBe(true)
    expect(H.workoutDetail(key).activity.hk).toBe('ABC')
    expect(G.setActivityHealthId('nope', 'ABC')).toBe(false)
  })

  it('formats pace and distance', () => {
    expect(G.paceText(359.6, 1000, 'kmh')).toBe('6:00 /km')
    expect(G.paceText(100, 5, 'kmh')).toBeNull()
    expect(G.paceText(0, 1000, 'kmh')).toBeNull()
    expect(G.paceText(7 * 3600, 1000, 'kmh')).toBeNull()
    expect(G.distanceText(12345, 'kmh')).toBe('12.35 km')
  })

  it('survives a date move and a delete like any workout', () => {
    const key = G.logActivity({ kind: 'walk', start: at(7), end: at(7, 30), meters: 2000 })
    expect(H.moveWorkout(key, '2026-09-27', '09:00', '2026-10-05')).toBe(true)
    const w = st().workouts[0]
    expect(w.d).toBe('2026-09-27')
    expect(w.gfActivity.m).toBe(2000)
    expect(H.deleteWorkout(key)).toBe(true)
    expect(G.activityKeys()).toEqual([])
  })
})
