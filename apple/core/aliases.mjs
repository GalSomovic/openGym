// The engine's substitutions: openGym's browser i18n shell becomes the native one, and the
// catalogue gains GymFree's extra exercises.
import { fileURLToPath } from 'node:url'
import path from 'node:path'

const here = path.dirname(fileURLToPath(import.meta.url))
const webI18n = path.resolve(here, '../../frontend/src/lib/i18n.js')
const nativeI18n = path.resolve(here, 'i18n-native.js')
const webData = path.resolve(here, '../../frontend/src/lib/exercises-data.js')
const nativeData = path.resolve(here, 'exercises-data-native.js')

export const nativeI18nPlugin = {
  name: 'native-i18n',
  async resolveId(source, importer, opts) {
    if (!importer || !source.startsWith('.')) return null
    const resolved = path.resolve(path.dirname(importer), source)
    if (resolved === webI18n) return nativeI18n
    // The catalogue with GymFree's extra exercises, except for the wrapper itself.
    if (resolved === webData && importer !== nativeData) return nativeData
    return null
  },
}
