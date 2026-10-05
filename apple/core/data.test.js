import { describe, it, expect, beforeEach } from 'vitest'
import * as A from './actions.js'
import * as D from './data.js'
import * as Set from './settings.js'
import { EXIDX } from '../../frontend/src/lib/exercises.js'
import { fmtNum } from '../../frontend/src/lib/format.js'

// FitNotes (Android): kg in its own column, a category per row.
const FITNOTES = [
  'Date,Exercise,Category,Weight (kg),Reps,Distance,Distance Unit,Time',
  '2026-03-02,Flat Barbell Bench Press,Chest,60.0,5,,,',
  '2026-03-02,Flat Barbell Bench Press,Chest,60.0,5,,,',
  '2026-03-02,Zorb Roller,Abs,10.0,12,,,',
  '2026-03-05,Barbell Squat,Legs,80.0,5,,,',
].join('\n')

// Strong: pounds (its imperial export), an RPE column, the workout's duration on every row.
const STRONG = [
  'Date,Workout Name,Duration,Exercise Name,Set Order,Weight (lbs),Reps,Distance,Seconds,Notes,Workout Notes,RPE',
  '2026-04-01 18:00:00,Push,45m,Bench Press (Barbell),1,135,8,0,0,,,8',
  '2026-04-01 18:00:00,Push,45m,Bench Press (Barbell),2,135,8,0,0,,,9',
].join('\n')

const HEALTH = `<?xml version="1.0"?><HealthData>
<Record type="HKQuantityTypeIdentifierBodyMass" unit="kg" value="80.4" startDate="2026-01-02 07:00:00 +0100"/>
<Record type="HKQuantityTypeIdentifierBodyMass" unit="kg" value="80.1" startDate="2026-01-09 07:00:00 +0100"/>
</HealthData>`

const bench = { id: '0025', sets: 3, reps: 5, weight: 60, inc: 2.5 }

beforeEach(() => A.load(null))

describe('backups', () => {
  it('export, reset and import come back to the same profile', () => {
    A.load(JSON.stringify({ restSec: 120, routines: [{ id: 'r1', name: 'Push', emoji: 'dumbbell', ex: [bench] }] }))
    const backup = A.exportState()
    expect(D.backupInfo(backup)).toMatchObject({ ok: true, workouts: 0, routines: 1, unit: 'kg' })
    D.resetEverything(1000)
    const wiped = JSON.parse(A.exportState())
    expect(wiped.routines).toEqual([])
    expect(wiped.restSec).toBe(90)
    expect(wiped.resetAt).toBe(1000)
    expect(wiped.resetIds.routines).toContain('r1')
    D.importBackup(backup)
    const back = JSON.parse(A.exportState())
    expect(back.routines[0].name).toBe('Push')
    expect(back.restSec).toBe(120)
    expect(back.resetAt).toBe(1000)          // the reset is never taken back (keepReset)
  })
  it('refuses a file that is not an openGym backup', () => {
    expect(D.backupInfo('not json')).toEqual({ ok: false })
    expect(D.backupInfo('[1,2]')).toEqual({ ok: false })
    expect(D.backupInfo('{"workouts":[]}')).toEqual({ ok: false })
    expect(() => D.importBackup('{}')).toThrow()
  })
  it('a second reset is stamped after the first', () => {
    D.resetEverything(5000)
    D.resetEverything(10)
    expect(JSON.parse(A.exportState()).resetAt).toBe(5001)
  })
})

describe('import from another app', () => {
  it('previews a FitNotes file without writing, then merges it', () => {
    const p = D.previewImport(FITNOTES)
    expect(p).toMatchObject({ kind: 'workouts', source: 'FitNotes', count: 2, fresh: 2, have: 0, sets: 4,
      from: '2026-03-02', to: '2026-03-05', fileUnit: 'kg', converted: false })
    expect(p.matched).toBe(2)
    expect(p.unmatchedNames).toEqual(['Zorb Roller'])
    expect(A.pick('workouts').workouts).toEqual([])
    expect(D.applyImport()).toEqual({ kind: 'workouts', added: 2, skipped: 0 })
    const S = JSON.parse(A.exportState())
    expect(S.workouts.map(w => w.d)).toEqual(['2026-03-02', '2026-03-05'])
    expect(S.customEx.map(c => c.n.toLowerCase())).toEqual(['zorb roller'])
    expect(EXIDX[S.customEx[0].id]).toBeTruthy()   // registered, so the library knows it
    expect(Object.values(S.exWeights).map(v => v.w).sort()).toEqual([10, 60, 80])
  })
  it('importing the same file twice adds nothing and keeps one custom exercise', () => {
    D.previewImport(FITNOTES); D.applyImport()
    const p = D.previewImport(FITNOTES)
    expect(p).toMatchObject({ have: 2, fresh: 0 })
    expect(D.applyImport()).toMatchObject({ added: 0, skipped: 2 })
    expect(JSON.parse(A.exportState()).customEx).toHaveLength(1)
  })
  it('converts a Strong file in pounds and counts its RPE', () => {
    const p = D.previewImport(STRONG)
    expect(p).toMatchObject({ source: 'Strong', fileUnit: 'lb', converted: true, unit: 'kg', effortSets: 2,
      effortKind: 'RPE', effortOn: false })
    D.applyImport()
    const w = JSON.parse(A.exportState()).workouts[0]
    expect(w.entries[0].sets[0].w).toBeCloseTo(61.2, 0)
  })
  it('reads Apple Health weigh-ins', () => {
    expect(D.previewImport(HEALTH)).toMatchObject({ kind: 'bodyweight', source: 'Apple Health', count: 2, fresh: 2 })
    expect(D.applyImport()).toEqual({ kind: 'bodyweight', added: 2, skipped: 0 })
    expect(A.pick('bodyweight').bodyweight.map(b => b.w)).toEqual([80.4, 80.1])
  })
  it('says why a file cannot be imported', () => {
    expect(D.previewImport('')).toEqual({ error: 'empty' })
    expect(D.previewImport('foo,bar\n1,2')).toEqual({ error: 'unrecognised' })
    expect(() => D.applyImport()).toThrow()
  })
  it('a cancelled preview cannot be applied', () => {
    D.previewImport(FITNOTES)
    D.cancelImport()
    expect(() => D.applyImport()).toThrow()
  })
})

describe('weight unit', () => {
  beforeEach(() => A.load(JSON.stringify({
    routines: [{ id: 'r1', name: 'Push', emoji: 'dumbbell', ex: [bench] }],
    exWeights: { '0025': { w: 60, d: '2026-01-01' } }, bodyweight: [{ d: '2026-01-01', w: 80 }],
  })))
  it('converts every stored weight', () => {
    expect(D.setUnit('lb', true, 7)).toBe(true)
    const S = JSON.parse(A.exportState())
    expect(S.unit).toBe('lb')
    expect(S.routines[0].ex[0].weight).toBe(132.5)
    expect(S.routines[0].ex[0].inc).toBe(5.5)
    expect(S.exWeights['0025'].w).toBe(132.5)
    expect(S.bodyweight[0].w).toBe(176.4)
    expect(S.unitSet).toEqual({ at: 7, convert: true })
  })
  it('or only changes the label', () => {
    D.setUnit('lb', false)
    const S = JSON.parse(A.exportState())
    expect(S.unit).toBe('lb')
    expect(S.routines[0].ex[0].weight).toBe(60)
    expect(S.unitSet.convert).toBe(false)
  })
  it('does nothing when the unit is already set', () => {
    expect(D.setUnit('kg')).toBe(false)
    expect(A.pick('unitSet').unitSet).toBeNull()
  })
  it('converts the running workout too', () => {
    A.beginWorkout(['r1'], null)
    D.setUnit('lb')
    expect(A.active().entries[0].sets[0].w).toBe(132.5)
  })
})

describe('preferences', () => {
  it('read absent values the way openGym shows them', () => {
    expect(Set.prefs()).toMatchObject({ unit: 'kg', speedUnit: 'kmh', wdec: 1, weekStart: 1, effort: 'none',
      startFrom: 'plan', restSec: 90, restPauseSec: 15, keepAwake: true, weighIn: true, vibrate: true })
    A.patch({ unit: 'lb' })
    expect(Set.prefs().speedUnit).toBe('mph')
    A.patch({ showRir: true })
    expect(Set.prefs().effort).toBe('rir')
  })
  it('effort replaces the legacy showRir switch', () => {
    A.patch({ showRir: true })
    expect(Set.setEffort('rpe').effort).toBe('rpe')
    expect(A.pick('showRir').showRir).toBeNull()
    expect(Set.setEffort('none').effort).toBe('none')
  })
  it('weight decimals reach the engine’s number format', () => {
    A.patch({ wdec: 2 })
    expect(fmtNum(61.25)).toBe('61.25')
    A.patch({ wdec: 1 })
    expect(fmtNum(61.25)).toBe('61.3')
    A.load(JSON.stringify({ wdec: 2 }))
    expect(fmtNum(61.25)).toBe('61.25')
  })
})
