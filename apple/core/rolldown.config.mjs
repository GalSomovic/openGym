import { nativeI18nPlugin } from './aliases.mjs'

export default {
  input: 'entry.js',
  platform: 'browser',
  plugins: [nativeI18nPlugin],
  transform: { define: { 'import.meta.env': '{}' } },
  output: {
    format: 'iife',
    name: 'OG',
    file: '../OpenGymCore/Sources/OpenGymCore/Resources/engine.js',
    minify: true,
  },
}
