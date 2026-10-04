// The engine's one substitution: openGym's browser i18n shell becomes the native one.
import { fileURLToPath } from 'node:url'
import path from 'node:path'

const here = path.dirname(fileURLToPath(import.meta.url))
const webI18n = path.resolve(here, '../../frontend/src/lib/i18n.js')
const nativeI18n = path.resolve(here, 'i18n-native.js')

export const nativeI18nPlugin = {
  name: 'native-i18n',
  async resolveId(source, importer, opts) {
    if (!importer || !source.endsWith('i18n.js')) return null
    const resolved = path.resolve(path.dirname(importer), source)
    return resolved === webI18n ? nativeI18n : null
  },
}
