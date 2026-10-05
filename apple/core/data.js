// Settings → Data (views/Settings.jsx, sheets.jsx ImportSummary), headless: a backup in and out,
// another app's history merged in, the weight unit switched, and the whole profile wiped. The
// parsing, merging and converting are openGym's own (lib/import-csv.js, lib/units.js,
// lib/sync-merge.js); this file only holds the steps its screens take around them.
import { need, load } from './actions.js'
import { DEF } from './defaults.gen.js'
import { parseImport, mergeImport } from '../../frontend/src/lib/import-csv.js'
import { convertStateUnit } from '../../frontend/src/lib/units.js'
import { keepReset, resetIdsOf, mergeResetIds } from '../../frontend/src/lib/sync-merge.js'
import { registerCustom } from '../../frontend/src/lib/exercises.js'
import { effortOf } from '../../frontend/src/lib/history.js'

const clone = o => JSON.parse(JSON.stringify(o))

/* ------------------------------ backups ------------------------------ */

// lib/backup-media.js isBackup (that module also stores media in IndexedDB, so it is not bundled).
const isBackup = d => !!d && typeof d === 'object' && !Array.isArray(d) && Array.isArray(d.workouts) && Array.isArray(d.routines)

function readBackup(json) {
  try {
    const d = typeof json === 'string' ? JSON.parse(json) : json
    return isBackup(d) ? d : null
  } catch { return null }
}

/**
 * What a picked backup holds, for the confirm before it replaces everything:
 * `{ ok, workouts, routines, bodyweight, unit, from, to }`, or `{ ok: false }` for a file that
 * is not an openGym backup.
 */
export function backupInfo(json) {
  const d = readBackup(json)
  if (!d) return { ok: false }
  const days = d.workouts.map(w => w && w.d).filter(Boolean).sort()
  return {
    ok: true, workouts: d.workouts.length, routines: d.routines.length,
    bodyweight: Array.isArray(d.bodyweight) ? d.bodyweight.length : 0,
    unit: d.unit === 'lb' ? 'lb' : 'kg', from: days[0] || null, to: days[days.length - 1] || null,
  }
}

/**
 * useStore importBackup with nobody signed in: the backup over the defaults, in place of this
 * copy. The reset stamp is never taken back (keepReset), so a later sync still honours it.
 */
export function importBackup(json) {
  const d = readBackup(json)
  if (!d) throw new Error('not an openGym backup')
  load(keepReset(need(), Object.assign(clone(DEF), d)))
  return true
}

/**
 * useStore resetEverything: the empty copy, stamped with when, and the names of every entry
 * the reset wiped, so a device that has not seen it yet cannot bring them back.
 */
export function resetEverything(now = Date.now()) {
  const cur = need()
  const S = clone(DEF)
  S.resetAt = Math.max(now, (Number(cur.resetAt) || 0) + 1)
  S.resetIds = mergeResetIds(cur.resetIds, resetIdsOf(cur))
  load(S)
  return true
}

/* ------------------------------ another app ------------------------------ */

// The parsed file between the preview and the confirm (sheets.jsx keeps it in the sheet).
let pending = null

/**
 * sheets.jsx importFromApp + ImportSummary: reads a FitNotes, Strong, Hevy or generic CSV, or
 * Apple Health's export.xml, in the profile's unit, and says what importing it would do. Nothing
 * is written until `applyImport`. `{ error }` is 'empty', 'unrecognised', 'unreadable' or
 * 'nothing'.
 */
export function previewImport(text) {
  const S = need()
  pending = null
  let parsed
  try { parsed = parseImport(String(text ?? ''), { unit: S.unit || 'kg' }) }
  catch { return { error: 'unreadable' } }
  if (parsed.error) return { error: parsed.error === 'empty' ? 'empty' : 'unrecognised' }
  const isBW = parsed.kind === 'bodyweight'
  const rows = isBW ? parsed.bodyweight : parsed.workouts
  if (!rows.length) return { error: 'nothing' }
  pending = parsed
  // Existing days win (mergeImport): those are counted so the summary can say so.
  const have = isBW
    ? rows.filter(b => (S.bodyweight || []).some(x => x.d === b.d)).length
    : rows.filter(w => (S.workouts || []).some(x => x.d === w.d)).length
  return {
    kind: parsed.kind, source: parsed.source || null, from: parsed.from || null, to: parsed.to || null,
    count: rows.length, have, fresh: rows.length - have,
    sets: parsed.sets || 0, matched: parsed.matched || 0, created: parsed.created || 0,
    unmatchedNames: parsed.unmatchedNames || [],
    fileUnit: parsed.fileUnit || null, converted: !!parsed.converted, mixedUnits: !!parsed.mixedUnits,
    unit: S.unit || 'kg',
    effortSets: (parsed.rirSets || 0) + (parsed.rpeSets || 0), effortKind: parsed.rirSets ? 'RIR' : 'RPE',
    effortOn: effortOf(S) !== 'none',
  }
}

/** ImportSummary doImport: merges the previewed file. `{ kind, added, skipped }`. */
export function applyImport() {
  const parsed = pending
  if (!parsed) throw new Error('nothing to import')
  pending = null
  const S = need()
  S.workouts = S.workouts || []
  S.bodyweight = S.bodyweight || []
  S.exWeights = S.exWeights || {}
  const res = mergeImport(S, parsed)
  registerCustom(S.customEx)
  return { kind: parsed.kind, ...res }
}

export function cancelImport() {
  pending = null
  return true
}

/* ------------------------------ the unit ------------------------------ */

/**
 * useStore setUnit: `convert` walks every stored weight into the new unit (lib/units.js); off,
 * only the label changes. The choice is stamped (`unitSet`) for sync, as openGym does.
 */
export function setUnit(to, convert = true, now = Date.now()) {
  const S0 = need()
  const unit = to === 'lb' ? 'lb' : 'kg'
  if ((S0.unit || 'kg') === unit) return false
  Object.assign(S0, convert ? convertStateUnit(S0, unit) : { unit })
  S0.unitSet = { at: now, convert: !!convert }
  return true
}
