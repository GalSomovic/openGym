import { describe, it, expect, beforeEach } from 'vitest'
import * as A from './actions.js'
import * as Pl from './plates-actions.js'

beforeEach(() => A.load(null))

describe('plates', () => {
  it('starts on the standard set and becomes your own after a change', () => {
    const inv = Pl.inventory()
    expect(inv.own).toBe(false)
    expect(inv.plates.find(p => p.w === 20).n).toBeGreaterThan(0)
    const mine = Pl.setPairs(20, 1)
    expect(mine.own).toBe(true)
    expect(mine.plates.find(p => p.w === 20).n).toBe(1)
    expect(Pl.resetPlates().own).toBe(false)
  })
  it('bar exercises load per side from a 20 kg bar; no bar and custom bar weights stick', () => {
    const bench = Pl.loading('0025')
    expect(bench).toMatchObject({ kind: 'pairs', bar: true, base: 20, noBar: false })
    expect(Pl.setBase('0025', 15).base).toBe(15)
    expect(Pl.setNoBar('0025', true).noBar).toBe(true)
    expect(Pl.setNoBar('0025', false).base).toBe(20)
    expect(Pl.setKind('0025', 'single').kind).toBe('single')
    expect(Pl.setKind('0025', 'pairs').kind).toBe('pairs')
  })
})
