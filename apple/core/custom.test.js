import { describe, it, expect, beforeEach } from 'vitest'
import * as A from './actions.js'
import * as C from './custom.js'
import * as L from './library.js'
import * as P from './plan.js'

beforeEach(() => A.load(null))

describe('custom exercises', () => {
  it('needs a name, body part and equipment, and a unique name', () => {
    expect(C.save({ n: '' }).error).toBe('name')
    expect(C.save({ n: 'Thing' }).error).toBe('bodyPart')
    expect(C.save({ n: 'Thing', bp: 'chest' }).error).toBe('equipment')
    expect(C.save({ n: 'push-up', bp: 'chest', eq: 'body weight' }).error).toBe('duplicate')
  })
  it('creates one that behaves like any other exercise', () => {
    const { id } = C.save({ n: 'Ring dip', bp: 'chest', eq: 'body weight', primaries: ['triceps', 'chest'], secondaries: ['deltoids'] })
    const ex = L.catalogue().find(e => e.id === id)
    expect(ex.n).toBe('Ring dip')
    expect(C.get(id)).toMatchObject({ tg: 'triceps', primaries: ['chest', 'triceps'], secondaries: ['deltoids'], custom: true })
    A.load(A.exportState())
    expect(L.catalogue().some(e => e.id === id)).toBe(true)
  })
  it('edits keep the id; deleting removes it from routines but keeps history names', () => {
    const { id } = C.save({ n: 'Ring dip', bp: 'chest', eq: 'body weight', primaries: ['chest'] })
    expect(C.save({ id, n: 'Gal ring dip', bp: 'chest', eq: 'body weight', primaries: ['chest'] })).toEqual({ id })
    expect(C.get(id).n).toBe('Gal ring dip')
    const rid = P.addRoutine('Dips', 'arm')
    P.addRoutineExercise(rid, id)
    expect(A.pick('routines').routines.find(r => r.id === rid).ex.map(e => e.id)).toEqual([id])
    expect(C.remove(id)).toBe(true)
    expect(A.pick('routines').routines.find(r => r.id === rid).ex).toEqual([])
    expect(C.get(id)).toBeNull()
    expect(L.catalogue().some(e => e.id === id)).toBe(false)
  })
})
