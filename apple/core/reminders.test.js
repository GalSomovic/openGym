import { describe, it, expect, beforeEach } from 'vitest'
import * as A from './actions.js'
import * as R from './reminders.js'
import * as P from './plan.js'

beforeEach(() => A.load(null))

describe('reminders', () => {
  it('are off by default and list nothing', () => {
    expect(R.reminder().on).toBe(false)
    expect(R.upcoming()).toEqual([])
  })
  it('list planned days in the window, at the chosen time, skipping days already trained', () => {
    P.loadStarterPlan('full-body')            // Monday, Wednesday, Friday
    R.setReminder({ on: true, time: '07:30' })
    const monday = new Date(2026, 9, 5, 6, 0).getTime()   // Mon 5 Oct 2026, 06:00
    const list = R.upcoming(monday)
    expect(list.length).toBe(6)
    expect(list[0].iso).toBe('2026-10-05')
    expect(new Date(list[0].at).getHours()).toBe(7)
    expect(list[0].routines).toEqual(['Full Body A'])
    const after = new Date(2026, 9, 5, 8, 0).getTime()    // past today's time
    expect(R.upcoming(after)[0].iso).toBe('2026-10-07')
  })
})
