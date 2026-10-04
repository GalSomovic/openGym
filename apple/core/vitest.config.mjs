import { nativeI18nPlugin } from './aliases.mjs'

// The tests run the same modules the engine bundles, with the same substitution.
export default { plugins: [{ ...nativeI18nPlugin, enforce: 'pre' }], test: { include: ['*.test.js'] } }
