import { describe, it, expect, beforeEach } from 'vitest'
import * as A from './actions.js'
import * as H from './history-actions.js'
import * as P from './plan.js'

// 0025 barbell bench press, 0032 barbell deadlift.
const routine = (id, name, ex) => ({ id, name, emoji: 'dumbbell', ex })
const bench = { id: '0025', sets: 2, reps: 5, weight: 60 }
const dead = { id: '0032', sets: 1, reps: 5, weight: 100 }
const st = () => JSON.parse(A.exportState())

function fresh(extra = {}) {
  // Monday (1) is Push, Wednesday (3) Pull.
  A.load(JSON.stringify({ routines: [routine('r1', 'Push', [bench]), routine('r2', 'Pull', [dead])], week: { 1: ['r1'], 3: ['r2'] }, ...extra }))
}
/** Logs a past workout of `rid` on `iso`, every set done. */
function logPast(iso, rid, time = '18:00', replaceId = null) {
  A.beginBackfill({ iso, time, durationMin: 45, routineIds: [rid], replaceId })
  A.markAllDone()
  return A.finishWorkout().workout
}

describe('history', () => {
  beforeEach(() => fresh())

  it('lists workouts newest first with their line and badges', () => {
    logPast('2026-09-28', 'r1')
    logPast('2026-09-30', 'r2')
    const rows = H.historyRows()
    expect(rows.map(r => r.name)).toEqual(['Pull', 'Push'])
    expect(rows[0].line).toContain('45 min')
    expect(rows[0].line).toContain('1 sets')
    expect(rows[0].emoji).toBe('dumbbell')
    expect(H.historyCount()).toBe('2 workouts')
  })

  it('shows a workout’s exercises, sets and note, and edits the note', () => {
    const w = logPast('2026-09-28', 'r1')
    const d = H.workoutDetail(w.id)
    expect(d.name).toBe('Push')
    expect(d.durationMin).toBe(45)
    expect(d.startTime).toBe('18:00')
    expect(d.sections).toHaveLength(1)
    expect(d.sections[0].units[0][0].name).toBe('Barbell Bench Press')
    expect(d.sections[0].units[0][0].sets).toBe('60×5  ·  60×5')
    expect(H.setWorkoutNote(w.id, '  felt strong ', 5)).toBe(true)
    expect(st().workouts[0].note).toBe('felt strong')
    expect(st().workouts[0]._ts).toBe(5)
    expect(H.setWorkoutNote(w.id, 'felt strong')).toBe(false)   // unchanged: no new stamp
  })

  it('moves a workout to another day, refiling it, and refuses the future', () => {
    const a = logPast('2026-09-28', 'r1')
    logPast('2026-09-30', 'r2')
    expect(H.moveWorkout(a.id, '2026-10-01', '07:30', '2026-10-05')).toBe(true)
    expect(st().workouts.map(w => w.d)).toEqual(['2026-09-30', '2026-10-01'])
    expect(H.workoutDetail(a.id).startTime).toBe('07:30')
    expect(H.workoutDetail(a.id).durationMin).toBe(45)          // keeps its length
    expect(() => H.moveWorkout(a.id, '2026-10-09', '07:30', '2026-10-05')).toThrow('Pick a day')
    expect(H.moveWorkout(a.id, '2026-10-01', '07:30', '2026-10-05')).toBe(false)
  })

  it('changes the duration, deletes, copies as text and saves as a routine', () => {
    const w = logPast('2026-09-28', 'r1')
    expect(H.setDuration(w.id, 90)).toBe(true)
    expect(H.workoutDetail(w.id).durationMin).toBe(90)
    expect(() => H.setDuration(w.id, 0)).toThrow()
    const text = H.copyText(w.id, 'good day')
    expect(text).toContain('Push')
    expect(text).toContain('Barbell Bench Press')
    expect(text).toContain('60×5, 60×5')
    expect(text.endsWith('good day')).toBe(true)
    const rid = H.saveAsRoutine(w.id)
    const copy = st().routines.find(r => r.id === rid)
    expect(copy.name).toBe('Push')
    expect(copy.ex.map(e => e.id)).toEqual(['0025'])
    expect(H.deleteWorkout(w.id)).toBe(true)
    expect(st().workouts).toEqual([])
    expect(H.workoutDetail(w.id)).toBeNull()
  })

  it('finds a workout from before ids by its sync key', () => {
    A.load(JSON.stringify({ workouts: [{ d: '2026-09-01', start: 1000, end: 61000, name: 'Old', entries: [] }] }))
    const [row] = H.historyRows()
    expect(row.key).toBe('2026-09-01|1000')
    expect(H.workoutDetail(row.key).name).toBe('Old')
    expect(H.deleteWorkout(row.key)).toBe(true)
  })
})

describe('editing a saved workout', () => {
  beforeEach(() => fresh())

  it('opens it as the session, saves the edit and closes', () => {
    const w = logPast('2026-09-28', 'r1')
    H.editWorkout(w.id)
    expect(A.active().editingWorkoutId).toBe(w.id)
    expect(H.editUnchanged()).toBe(true)
    A.setField(0, 1, 'w', 70)
    expect(H.editUnchanged()).toBe(false)
    expect(H.saveEdit(9)).toEqual({ saved: true })
    expect(A.active()).toBeNull()
    expect(st().workouts[0].entries[0].sets.map(s => s.w)).toEqual([60, 70])
    expect(st().workouts[0]._ts).toBe(9)
  })

  it('offers to delete a workout left without sets, and discards an edit', () => {
    const w = logPast('2026-09-28', 'r1')
    H.editWorkout(w.id)
    A.toggleSet(0, 0); A.toggleSet(0, 1)
    expect(H.saveEdit()).toEqual({ empty: true })
    expect(A.active()).not.toBeNull()
    H.discardEdit()
    expect(A.active()).toBeNull()
    expect(st().workouts).toHaveLength(1)
    H.editWorkout(w.id)
    expect(H.deleteEdit()).toBe(true)
    expect(st().workouts).toEqual([])
  })

  it('is refused while a session runs', () => {
    const w = logPast('2026-09-28', 'r1')
    A.beginWorkout(['r2'], null)
    expect(() => H.editWorkout(w.id)).toThrow()
  })
})

describe('log a past workout', () => {
  beforeEach(() => fresh())

  it('replaces a day’s workout, keeping its note, or adds a second', () => {
    const first = logPast('2026-09-28', 'r1')
    H.setWorkoutNote(first.id, 'knee')
    expect(A.workoutsOnDay('2026-09-28')).toHaveLength(1)
    logPast('2026-09-28', 'r2', '19:00', first.id)
    expect(st().workouts.map(w => w.name)).toEqual(['Pull'])
    expect(st().workouts[0].note).toBe('knee')
    logPast('2026-09-28', 'r1', '07:00')
    expect(st().workouts.map(w => w.name)).toEqual(['Push', 'Pull'])   // in time order
  })

  it('carries the session note written during the workout into history', () => {
    A.beginWorkout(['r1'], null)
    A.setSessionNote('  heavy day  ')
    expect(A.active().note).toBe('heavy day')
    A.setSessionNote('   ')
    expect(A.active().note).toBeUndefined()
    A.setSessionNote('felt good')
    A.markAllDone()
    const w = A.finishWorkout().workout
    expect(H.workoutDetail(w.id).note).toBe('felt good')
  })

  it('names a combined day', () => {
    expect(H.sessionName(['r1', 'r2'])).toBe('Push + Pull')
    expect(H.sessionName([])).toBe('Freestyle')
  })
})

describe('the week and the calendar', () => {
  beforeEach(() => fresh())

  it('marks done, planned and rescheduled days in the week strip', () => {
    logPast('2026-09-28', 'r1')
    P.setDayOverride('2026-10-02', 'r2')
    const { label, days } = H.weekStrip(-1, '2026-10-05')
    expect(label).not.toBe('This week')
    expect(days[0]).toMatchObject({ iso: '2026-09-28', dot: 'done', label: 'Mo', num: 28 })
    expect(days[2].dot).toBe('plan')
    const now = H.weekStrip(0, '2026-10-05')
    expect(now.label).toBe('This week')
    expect(now.days[0].today).toBe(true)
    expect(now.days[4]).toMatchObject({ iso: '2026-10-09', dot: '' })
    expect(H.weekStrip(-1, '2026-10-05').days[4]).toMatchObject({ iso: '2026-10-02', dot: 'ovr' })
  })

  it('starts the week on Sunday when the profile says so', () => {
    fresh({ weekStart: 0 })
    expect(H.weekStrip(0, '2026-10-05').days[0].iso).toBe('2026-10-04')
  })

  it('says what today is: planned, done, or when you train next', () => {
    expect(H.todayInfo('2026-10-05')).toMatchObject({ routineIds: ['r1'], done: null, next: null, rescheduled: false })
    expect(H.todayInfo('2026-10-06').next).toBe('Next session: Wednesday, Pull')
    P.setDayOverride('2026-10-05', 'r2')
    expect(H.todayInfo('2026-10-05')).toMatchObject({ routineIds: ['r2'], rescheduled: true })
    logPast('2026-10-05', 'r2')
    expect(H.todayInfo('2026-10-05').done.name).toBe('Pull — done')
    expect(H.todayInfo('2026-10-05').rescheduled).toBe(false)
  })

  it('knows a missed planned day, and words a day change', () => {
    const missed = H.dayInfo('2026-09-28', '2026-10-05')
    expect(missed).toMatchObject({ weekly: 'Push', planned: ['r1'], missed: true, changed: false })
    logPast('2026-09-28', 'r1')
    expect(H.dayInfo('2026-09-28', '2026-10-05').missed).toBe(false)
    expect(H.dayInfo('2026-09-29', '2026-10-05')).toMatchObject({ weekly: 'Rest', missed: false })
    expect(H.dayInfo('2026-10-12', '2026-10-05').missed).toBe(false)   // the future is not missed
    expect(H.dayChangeText('2026-09-29', '')).toBe('Back to weekly plan')
    expect(H.dayChangeText('2026-09-29', 'r2')).toContain('Pull planned for')
  })

  it('lays out a month with its workouts', () => {
    const w = logPast('2026-10-01', 'r2')
    const m = H.calendarMonth(2026, 9, '2026-10-05')
    expect(m.title).toBe('October 2026')
    expect(m.headers[0]).toBe('Mo')
    expect(m.blanks).toBe(3)                      // 1 October 2026 is a Thursday
    expect(m.days).toHaveLength(31)
    expect(m.days[0]).toMatchObject({ dot: 'done', workouts: [w.id] })
    expect(m.days[4]).toMatchObject({ dot: 'plan', today: true })
    expect(m.summary).toContain('1 workout')
    expect(H.calendarMonth(2026, 10).summary).toBe('No workouts this month')
  })

  it('counts the streak and this week', () => {
    logPast('2026-10-05', 'r1')
    expect(H.streak('2026-10-05').line).toContain('1 / 2 this week')
    expect(H.streak('2026-10-05').line).toContain('1 workout total')
  })
})

describe('body weight', () => {
  beforeEach(() => fresh())

  it('logs one weigh-in a day, in date order, and deletes one', () => {
    expect(H.logWeight(80.04, '2026-10-02', 1)).toBe(80)
    H.logWeight(81, '2026-09-30', 2)
    H.logWeight(79.5, '2026-10-02', 3)
    expect(st().bodyweight).toEqual([{ d: '2026-09-30', w: 81, t: 2 }, { d: '2026-10-02', w: 79.5, t: 3 }])
    expect(() => H.logWeight(0)).toThrow('Enter a valid weight')
    H.deleteWeighIn('2026-09-30')
    expect(st().bodyweight.map(b => b.d)).toEqual(['2026-10-02'])
  })

  it('shows the latest, the change and the goal on the card', () => {
    expect(H.weightCard().last).toBeNull()
    expect(H.weightCard().show).toBe(true)
    H.logWeight(82, '2026-09-30')
    H.logWeight(81, '2026-10-02')
    expect(H.weightCard()).toMatchObject({ last: { w: 81 }, delta: -1, deltaText: '1', tone: 'neutral', goal: null })
    expect(H.setGoal(78)).toContain('Goal set: 78 kg')
    expect(H.weightCard()).toMatchObject({ goal: 78, tone: 'good', goalText: 'Goal 78 kg · 3 kg to lose' })
    expect(H.setGoal(null)).toBe('Goal removed')
    expect(st().targetW).toBeNull()
  })

  it('follows the unit and the settings', () => {
    fresh({ unit: 'lb', showWeightCard: false, weighIn: false })
    expect(H.weightCard()).toMatchObject({ unit: 'lb', max: 660, show: false, weighIn: false })
  })

  it('groups weigh-ins by week with their averages', () => {
    H.logWeight(80, '2026-09-28')
    H.logWeight(82, '2026-09-30')
    H.logWeight(79, '2026-10-05')
    const w = H.weighIns()
    expect(w.count).toBe(3)
    expect(w.title).toBe('3 weigh-ins')
    expect(w.weeks.map(x => x.key)).toEqual(['2026-10-05', '2026-09-28'])
    expect(w.weeks[1].average).toBe('Average 81 kg')
    expect(w.weeks[0]).toMatchObject({ delta: -2, deltaText: '2' })
    expect(w.weeks[1].entries.map(e => e.d)).toEqual(['2026-09-30', '2026-09-28'])
    expect(H.weightSeries().map(b => b.w)).toEqual([80, 82, 79])
  })
})
