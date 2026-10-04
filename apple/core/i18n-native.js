// Stands in for frontend/src/lib/i18n.js inside the engine. The web module lazy-loads its
// language packs with Vite's import.meta.glob and subscribes React to changes; neither exists
// in JavaScriptCore. Here the app hands the packs over itself (setLangPacks), read from files
// it ships, and everything else is openGym's own i18n-core.
import {
  LANGS, INSTR_LANGS, EXERCISE_NAME_LANGS, DATE_LOCALES, DERIVED_LOCALES, RTL_LANGS,
  getLang, dateLocale, t, instrFor, exerciseNameFor, exerciseNameSearchText, getVersion,
  baseLang, derivePack, _setLangState, exerciseNameClass,
} from '../../frontend/src/lib/i18n-core.js'

export {
  LANGS, INSTR_LANGS, EXERCISE_NAME_LANGS, DATE_LOCALES, DERIVED_LOCALES, RTL_LANGS,
  getLang, dateLocale, t, instrFor, exerciseNameFor, exerciseNameSearchText, exerciseNameClass, baseLang, getVersion,
}

/** Switches language with packs the app loaded (null for English or a pack it lacks). */
export function setLangPacks(l, dict, instr, names, showEn = true, enOnly = false) {
  if (!LANGS[l]) l = 'en'
  _setLangState(l, derivePack(l, dict || {}), derivePack(l, instr || null), derivePack(l, names || null), showEn !== false, enOnly === true)
  return getLang()
}

// The web signature, for any lib module that calls it: without packs it can only go English.
export async function setLang(l) { return setLangPacks(l, null, null, null) }
export const useLang = () => getVersion()
