// The exercise library: openGym's Library screen (views/Library.jsx) and the exercise detail,
// headless. The catalogue crosses to Swift once; searches return ids into it.
import { need } from './actions.js'
import { BODYPARTS, EXIDX, allExercises, equipmentOf, searchExercises, isCardio } from '../../frontend/src/lib/exercises.js'
import { activeProfile, exAvailable } from '../../frontend/src/lib/equipment.js'
import { bestWeightFor, exNoteFor } from '../../frontend/src/lib/history.js'
import { isFav, toggleFav, sortFavouritesFirst } from '../../frontend/src/lib/favourites.js'
import { smOf } from '../../frontend/src/lib/exercises.js'
import { exerciseHistory } from '../../frontend/src/lib/exercise-history.js'

const brief = e => ({
  id: e.id, n: e.n, bp: e.bp, eq: e.eq, tg: e.tg || null, sm: smOf(e),
  custom: !!e.custom, cardio: isCardio(e.id),
})

/** Every exercise, custom ones first, in the catalogue's order. */
export function catalogue() {
  return allExercises(need()).map(brief)
}

export function bodyParts() {
  return BODYPARTS
}

/**
 * Library.jsx filtering: search, body part, then the equipment profile (unless `showAll`), then
 * the equipment chip, favourites first. An equipment choice the search narrowed away is dropped
 * for this view only, so the list never dead-ends.
 */
export function browse({ q = '', bp = '', eq = '', showAll = false } = {}) {
  const S = need()
  const profile = activeProfile(S)
  const base = searchExercises(allExercises(S).filter(e => !bp || e.bp === bp), q)
  const eqFiltered = (profile && !showAll) ? base.filter(e => exAvailable(S, e)) : base
  const equipment = equipmentOf(eqFiltered)
  const eqOn = equipment.includes(eq) ? eq : ''
  const list = sortFavouritesFirst(eqOn ? eqFiltered.filter(e => e.eq === eqOn) : eqFiltered, S)
  return { ids: list.map(e => e.id), equipment, eq: eqOn, profile: profile ? profile.name : null }
}

/** One exercise in full: instructions, muscles, best weight, favourite. */
export function detail(id) {
  const S = need()
  const e = EXIDX[id]
  if (!e) return null
  return {
    ...brief(e), st: e.st || [], desc: e.desc || null, secondaries: e.secondaries || null,
    best: bestWeightFor(S, id), fav: isFav(S, id), note: exNoteFor(S, id),
  }
}

/** Best weights for the rows on screen (Library shows them as a tag). */
export function bests(ids) {
  const S = need()
  return Object.fromEntries([].concat(ids).map(id => [id, bestWeightFor(S, id)]).filter(([, w]) => w > 0))
}

/** The standing note for an exercise ("seat 4, pin 7"); empty clears it. */
export function setExerciseNote(id, text) {
  const S = need()
  const v = (text || '').trim()
  S.exNotes = { ...(S.exNotes || {}) }
  if (v) S.exNotes[id] = v; else delete S.exNotes[id]
  return true
}

export function toggleFavourite(id) {
  return toggleFav(need(), id)
}

/** The exercise's past sessions, newest first, for the detail screen. */
export function history(id) {
  return exerciseHistory(need(), id)
}
