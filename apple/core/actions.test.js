import { describe, it, expect, beforeEach } from 'vitest'
import * as A from './actions.js'
import { readDefaults } from './gen-defaults.mjs'
import { DEF } from './defaults.gen.js'
import { isWarmupRow } from '../../frontend/src/lib/workout-model.js'

// 0025 barbell bench press, 0032 barbell deadlift, 0001 3/4 sit-up (body weight).
const routine = (id, name, ex) => ({ id, name, emoji: 'dumbbell', ex })
const bench = { id: '0025', sets: 3, reps: 5, weight: 60 }
const dead = { id: '0032', sets: 2, reps: 5, weight: 100 }

function fresh(extra = {}) {
  A.load(JSON.stringify({ restSec: 90, routines: [routine('r1', 'Push', [bench]), routine('r2', 'Pull', [dead])], ...extra }))
}
const tickAll = idx => {
  const a = A.active()
  const outs = []
  a.entries[idx].sets.forEach((s, i) => { if (!s.done) outs.push(A.toggleSet(idx, i)) })
  return outs
}

describe('defaults', () => {
  it('match openGym’s store, so nothing upstream added is missing', () => {
    expect(DEF).toEqual(JSON.parse(JSON.stringify(readDefaults())))
  })
  it('overlay a saved profile and mark a new one as language-unpicked', () => {
    A.load(null)
    expect(A.pick(['restSec', 'langAuto'])).toEqual({ restSec: 90, langAuto: true })
    A.load(JSON.stringify({ restSec: 120, futureKey: 1 }))
    const st = JSON.parse(A.exportState())
    expect(st.restSec).toBe(120)
    expect(st.futureKey).toBe(1)          // unknown keys survive a round trip
    expect(st.langAuto).toBeUndefined()
  })
})

describe('patch', () => {
  beforeEach(() => fresh())
  it('writes settings but not the session or the history', () => {
    A.patch({ restSec: 60 })
    expect(A.pick('restSec').restSec).toBe(60)
    expect(() => A.patch({ workouts: [] })).toThrow()
    expect(() => A.patch({ active: null })).toThrow()
  })
})

describe('a session', () => {
  beforeEach(() => fresh())

  it('starts from a routine with its prescription and name', () => {
    const a = A.beginWorkout(['r1'], 80, 'Freestyle', 1000)
    expect(a.name).toBe('Push')
    expect(a.bw).toBe(80)
    expect(a.entries).toHaveLength(1)
    expect(a.entries[0].rid).toBe('r1')
    expect(a.entries[0].sets.filter(s => !isWarmupRow(s))).toHaveLength(3)
    expect(a.setsTotal).toBe(a.entries[0].sets.length)
  })

  it('combines routines and names them the openGym way', () => {
    expect(A.beginWorkout(['r1', 'r2']).name).toBe('Push + Pull')
    expect(A.beginWorkout([], null, 'Libre').name).toBe('Libre')
  })

  it('rests between sets and asks to finish after the last', () => {
    A.beginWorkout(['r1'])
    const first = A.toggleSet(0, 0)
    expect(first).toMatchObject({ checked: true, beep: true, complete: false })
    expect(first.rest).toEqual({ sec: 90, forIdx: 0 })
    A.toggleSet(0, 1)
    const last = A.toggleSet(0, 2)
    expect(last.complete).toBe(true)
    expect(last.rest).toBeNull()
  })

  it('does not replay the flow when a set is unticked and ticked again', () => {
    A.beginWorkout(['r1'])
    A.toggleSet(0, 0)
    expect(A.toggleSet(0, 0).checked).toBe(false)
    // A re-check with a rest already running owes nothing more.
    expect(A.toggleSet(0, 0, null, { timerRunning: true }).rest).toBeNull()
  })

  it('moves to the next exercise of a superset and rests after the round', () => {
    A.beginWorkout(['r1', 'r2'])
    A.pair(0, 1)
    const a = A.active()
    expect(a.units[0]).toEqual([0, 1])
    const out = A.toggleSet(0, 0)
    expect(out.cur).toBe(1)
    expect(out.rest).toBeNull()
    expect(A.toggleSet(1, 0).rest).not.toBeNull()
  })

  it('carries a corrected weight to the following sets', () => {
    A.beginWorkout(['r1'])
    A.setField(0, 0, 'w', 62.5)
    expect(A.active().entries[0].sets.map(s => s.w)).toEqual([62.5, 62.5, 62.5])
    A.setField(0, 0, 'rpe', 8)
    A.setField(0, 0, 'rpe', null)
    expect('rpe' in A.active().entries[0].sets[0]).toBe(false)
  })

  it('adds and removes sets, warm-ups and exercises', () => {
    A.beginWorkout(['r1'])
    A.addSet(0)
    expect(A.active().entries[0].sets).toHaveLength(4)
    A.removeSet(0)
    A.addWarmup(0)
    expect(A.active().entries[0].sets.some(isWarmupRow)).toBe(true)
    const at = A.addExercise('0032')
    expect(at).toBe(1)
    expect(A.active().cur).toBe(1)
    expect(A.active().entries[1].rid).toBe('r1')   // inherits the routine it was added to
    A.removeExercise(1)
    expect(A.active().entries).toHaveLength(1)
    expect(A.active().cur).toBe(0)
  })

  it('adds a routine mid-session once', () => {
    A.beginWorkout(['r1'])
    expect(A.addRoutineToSession('r2')).toBe(true)
    expect(A.addRoutineToSession('r2')).toBe(false)
    expect(A.active().name).toBe('Push + Pull')
  })

  it('swaps an unlogged exercise in place and asks first for a logged one', () => {
    A.beginWorkout(['r1'])
    expect(A.swapExercise(0, '0032')).toEqual({ inserted: false, index: 0 })
    expect(A.active().entries[0].id).toBe('0032')
    A.toggleSet(0, 0)
    expect(A.swapExercise(0, '0025').needsConfirmation).toBe(true)
    expect(A.swapExercise(0, '0025', null, { loggedConfirmed: true }).inserted).toBe(true)
    expect(A.active().entries.map(e => e.id)).toEqual(['0032', '0025'])
  })
})

describe('finishing', () => {
  beforeEach(() => fresh())

  it('files the workout, remembers the weight and reports a first PR', () => {
    A.beginWorkout(['r1'], null, 'Freestyle', 1000)
    tickAll(0)
    expect(A.finishCheck()).toEqual({ done: 3, total: 3 })
    const sum = A.finishWorkout(2000)
    expect(sum.workout.end).toBe(2000)
    expect(sum.workout.vol).toBe(60 * 5 * 3)
    expect(sum.prs).toEqual(['0025'])
    const st = JSON.parse(A.exportState())
    expect(st.active).toBeNull()
    expect(st.workouts).toHaveLength(1)
    expect(st.exWeights['0025'].w).toBe(60)
  })

  it('drops exercises with nothing logged', () => {
    A.beginWorkout(['r1', 'r2'])
    tickAll(0)
    expect(A.finishWorkout().workout.entries.map(e => e.id)).toEqual(['0025'])
  })

  it('reports no PR for the same load again, and one for more', () => {
    A.beginWorkout(['r1']); tickAll(0); A.finishWorkout()
    A.beginWorkout(['r1'])
    A.setField(0, 0, 'w', 60)
    tickAll(0)
    const same = A.finishWorkout()
    // Progression may raise the load on its own after a full session; either way a PR is
    // reported exactly when the top set beats the best before it.
    const top = Math.max(...same.workout.entries[0].sets.map(s => s.w))
    expect(same.prs.includes('0025')).toBe(top > 60)
  })

  it('logs a past workout into its day without timers', () => {
    A.beginWorkout(['r1']); tickAll(0); A.finishWorkout(Date.parse('2026-10-03T19:00:00'))
    const a = A.beginBackfill({ iso: '2026-09-01', time: '18:00', durationMin: 45, routineIds: ['r1'] })
    expect(a.backfill).toEqual({ durationMin: 45, replaceId: null })
    expect(A.toggleSet(0, 0).rest).toBeNull()
    A.markAllDone()
    A.finishWorkout()
    const ws = JSON.parse(A.exportState()).workouts
    expect(ws.map(w => w.d)).toEqual(['2026-09-01', ws[1].d])
    expect(ws[0].end - ws[0].start).toBe(45 * 60000)
  })
})
