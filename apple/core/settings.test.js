import { describe, it, expect, beforeEach } from 'vitest'
import * as A from './actions.js'
import * as Set from './settings.js'
import * as L from './library.js'
import * as P from './plan.js'

beforeEach(() => A.load(null))

describe('equipment', () => {
  it('starts with everything and no filter', () => {
    const e = Set.equipment()
    expect(e.filterOn).toBe(false)
    expect(e.selected).toEqual(e.all)
    expect(e.all).not.toContain('body weight')
  })
  it('bodyweight only hides every loaded exercise', () => {
    Set.setEquipment([])
    expect(Set.equipment()).toMatchObject({ filterOn: true, selected: [] })
    const ids = L.browse({}).ids
    const cat = Object.fromEntries(L.catalogue().map(e => [e.id, e]))
    expect(ids.length).toBeGreaterThan(100)
    expect(ids.every(id => cat[id].eq === 'body weight')).toBe(true)
    expect(L.browse({ showAll: true }).ids.length).toBeGreaterThan(ids.length)
  })
  it('selecting everything again turns the filter off', () => {
    Set.setEquipment(['barbell'])
    expect(Set.equipment().selected).toEqual(['barbell'])
    Set.setEquipment(Set.equipment().all)
    expect(Set.equipment().filterOn).toBe(false)
  })
  it('flags routine exercises that need missing equipment', () => {
    const r = P.addRoutine('Mixed')
    P.addRoutineExercise(r, '0025')   // barbell
    P.addRoutineExercise(r, '0001')   // body weight
    Set.setEquipment([])
    expect(Set.missingEquipment(r)).toEqual([0])
  })
})
