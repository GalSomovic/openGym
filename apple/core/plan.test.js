import { describe, it, expect, beforeEach } from 'vitest'
import * as A from './actions.js'
import * as P from './plan.js'
import * as L from './library.js'

const st = () => JSON.parse(A.exportState())
beforeEach(() => A.load(null))

describe('routines', () => {
  it('are added, renamed, copied, ordered and deleted with their schedule', () => {
    const a = P.addRoutine('Push')
    const b = P.addRoutine('Pull')
    P.renameRoutine(a, '  ', 'Routine')
    expect(st().routines[0].name).toBe('Routine')
    P.assignDay(1, a)
    P.addRoutineToDay(1, b)
    expect(P.addRoutineToDay(1, b)).toBe(false)
    P.setDayOverride('2026-10-05', a)
    const c = P.copyRoutine(a, 'Copy')
    expect(st().routines.find(r => r.id === c).name).toBe('Routine (Copy)')
    P.moveRoutine(2, -2)
    expect(st().routines.map(r => r.id)).toEqual([c, a, b])
    P.deleteRoutine(a)
    expect(st().week[1]).toEqual([b])
    expect(st().dayPlan).toEqual({})
    P.removeFromDay(1, b)
    expect(st().week[1]).toBeUndefined()   // never stored as []
  })

  it('edit exercises, supersets and order', () => {
    const r = P.addRoutine('Full')
    P.addRoutineExercise(r, '0025')
    P.addRoutineExercise(r, '0032', { sets: 5, reps: 5, weight: 100, mode: 'reps' })
    P.addRoutineExercise(r, '0001')
    P.toggleSupersetLink(r, 1)
    const ex = st().routines[0].ex
    expect(ex[0].sg).toBeTruthy()
    expect(ex[0].sg).toBe(ex[1].sg)
    // The superset moves as one.
    P.moveRoutineExercise(r, 2, -1)
    expect(st().routines[0].ex.map(e => e.id)).toEqual(['0001', '0025', '0032'])
    P.updateRoutineExercise(r, 1, { sets: 4, reps: 6, weight: 70 })
    expect(st().routines[0].ex[1]).toMatchObject({ id: '0025', sets: 4, sg: ex[0].sg })
    P.removeRoutineExercise(r, 2)
    expect(st().routines[0].ex.some(e => e.sg)).toBe(false)   // a superset of one is cleared
    expect(P.routineLines(r)).toHaveLength(2)
  })

  it('replace a slot keeping its prescription', () => {
    const r = P.addRoutine('Push')
    P.addRoutineExercise(r, '0025', { sets: 4, reps: 6, weight: 80, mode: 'reps', note: 'pause' })
    P.replaceRoutineExercise(r, 0, '0047')
    expect(st().routines[0].ex[0]).toMatchObject({ id: '0047', sets: 4, reps: 6, note: 'pause' })
  })
})

describe('the exercise settings sheet', () => {
  it('saves what openGym saves', () => {
    const c = P.configStart('0025')
    const out = P.configToSave('0025', { ...c, sets: 4, reps: 7, weight: 62.5, note: '  cue  ', restSec: 120, warmupSets: 9 })
    expect(out).toEqual({ sets: 4, mode: 'reps', reps: 7, weight: 62.5, note: 'cue', restSec: 120, warmupSets: 5 })
  })
  it('keeps per-side reps even and holds a timed set to its own fields', () => {
    const c = P.configWithPerSide('0025', { ...P.configStart('0025'), reps: 7 }, true)
    expect(c.reps).toBe(8)
    expect(P.configToSave('0025', c).side).toBe(true)
    const timed = P.configWithMode('0001', P.configStart('0001'), 'time')
    const saved = P.configToSave('0001', { ...timed, sec: 30 })
    expect(saved).toMatchObject({ mode: 'time', sec: 30 })
    expect(saved.reps).toBeUndefined()
  })
  it('refuses an invalid progression step, as the web sheet disables Save', () => {
    const c = { ...P.configStart('0025'), prog: 'linear', inc: 0 }
    expect(P.configInfo('0025', c).stepValid).toBe(false)
    expect(P.configToSave('0025', c)).toBeNull()
  })
  it('reports the rule in force and the fields that apply', () => {
    const info = P.configInfo('0025', P.configStart('0025'))
    expect(info.mode).toBe('reps')
    expect(info.policies.length).toBeGreaterThan(1)
    expect(P.configInfo('0001', P.configStart('0001')).bw).toBe(true)
  })
  it('seeds intensifiers like the web sheet', () => {
    expect(P.configWithIntensifier({ reps: 10 }, 'restpause').intensifier).toMatchObject({ type: 'restpause', totalReps: 10, restSec: 15 })
    expect(P.configWithIntensifier({ intensifier: { type: 'dropset' } }, '').intensifier).toBeUndefined()
  })
})

describe('starter plans', () => {
  it('load routines onto their weekdays and say when a day is taken', () => {
    const plans = P.starterPlans()
    expect(plans.map(p => p.id)).toContain('ppl')
    expect(P.starterPlanConflicts('full-body')).toBe(false)
    P.loadStarterPlan('full-body')
    expect(st().routines).toHaveLength(3)
    expect(Object.keys(st().week).sort()).toEqual(['1', '3', '5'])
    expect(P.starterPlanConflicts('5x5')).toBe(true)
    expect(P.loadStarterPlan('nope')).toBe(false)
  })
})

describe('library', () => {
  it('lists the catalogue and searches it', () => {
    expect(L.catalogue().length).toBeGreaterThan(1300)
    const res = L.browse({ q: 'bench press' })
    expect(res.ids).toContain('0025')
    const chest = L.browse({ bp: 'chest' })
    expect(chest.equipment.length).toBeGreaterThan(1)
    // An equipment chip the search narrowed away is dropped for this view only.
    expect(L.browse({ q: '3/4 sit-up', eq: 'barbell' }).eq).toBe('')
  })
  it('puts favourites first and keeps notes', () => {
    L.toggleFavourite('0032')
    expect(L.browse({ bp: L.detail('0032').bp }).ids[0]).toBe('0032')
    L.setExerciseNote('0032', ' seat 4 ')
    expect(L.detail('0032')).toMatchObject({ fav: true, note: 'seat 4' })
    expect(L.detail('0032').st.length).toBeGreaterThan(0)
  })
  it('browses by muscle, as the muscle explorer does', () => {
    const none = L.byMuscle()
    expect(none.selected).toBe(null)
    expect(none.exercises).toEqual([])
    expect(none.muscles.find(m => m.slug === 'chest').count).toBeGreaterThan(20)
    const chest = L.byMuscle({ selected: 'chest' })
    expect(chest.title).toBe('Exercises for Chest')
    expect(chest.exercises.map(e => e.id)).toContain('0025')
    expect(chest.exercises.find(e => e.id === '0025').line).toMatch(/^Primary target/)
    expect(L.byMuscle({ selected: 'chest', q: 'bench' }).exercises.length).toBeLessThan(chest.exercises.length)
    expect(L.byMuscle({ selected: 'nonsense' }).selected).toBe(null)
  })
})

describe('GymFree extras', () => {
  it('are in the catalogue and can be planned', () => {
    expect(L.detail('gf-squat')).toMatchObject({ n: 'bodyweight squat', eq: 'body weight' })
    expect(L.browse({ q: 'plank' }).ids).toContain('gf-plank')
    const r = P.addRoutine('Calisthenics')
    P.addRoutineExercise(r, 'gf-squat')
    expect(st().routines[0].ex[0].id).toBe('gf-squat')
  })
})

describe('week muscles', () => {
  it('adds up every planned day', () => {
    A.load(null)
    expect(P.weekMuscles().worked).toEqual([])
    P.loadStarterPlan('full-body')
    const w = P.weekMuscles()
    expect(w.worked.length).toBeGreaterThan(5)
    expect(Object.values(w.levels).some(l => l > 0)).toBe(true)
  })
})
