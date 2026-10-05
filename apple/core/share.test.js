import { describe, it, expect, beforeEach } from 'vitest'
import * as A from './actions.js'
import * as Sh from './share.js'
import * as P from './plan.js'

beforeEach(() => A.load(null))

describe('share a plan', () => {
  it('exports routines only and imports them by merging', () => {
    expect(Sh.exportPlan()).toBeNull()
    P.loadStarterPlan('full-body')
    const file = Sh.exportPlan('My plan')
    expect(JSON.parse(file).routines.length).toBe(3)
    A.load(null)
    const p = Sh.previewPlan(file)
    expect(p).toMatchObject({ name: 'My plan', routineCount: 3, scheduledDays: 3 })
    expect(Sh.importPlan(true)).toBe(true)
    const s = A.pick(['routines', 'week'])
    expect(s.routines).toHaveLength(3)
    expect(s.week[1]).toHaveLength(1)
  })
  it('prints the week as HTML', () => {
    P.loadStarterPlan('full-body')
    expect(Sh.printHTML()).toContain('<html')
  })
})
