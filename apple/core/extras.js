// Exercises GymFree adds to openGym's catalogue: popular calisthenics movements the catalogue
// lacks. Same shape as frontend/src/lib/exercises-data.js; ids start with `gf-` so they never
// collide. They have GymFree's own animation and no ExerciseDB media.
export const EXTRAS = [
  {
    id: 'gf-squat', n: 'bodyweight squat', bp: 'upper legs', eq: 'body weight', tg: 'quads', mg: 'glutes',
    sm: ['glutes', 'hamstrings', 'calves', 'core'],
    st: [
      'Stand with your feet about shoulder-width apart, toes turned out slightly.',
      'Push your hips back and bend your knees, keeping your chest up and your heels on the floor; reach your arms forward for balance.',
      'Lower until your thighs are at least parallel to the floor, knees tracking over your toes.',
      'Drive through your whole foot to stand back up, squeezing your glutes at the top.',
    ],
  },
  {
    id: 'gf-plank', n: 'plank', bp: 'waist', eq: 'body weight', tg: 'abs', mg: 'core',
    sm: ['obliques', 'lower back', 'shoulders', 'glutes'],
    st: [
      'Rest on your forearms with your elbows directly under your shoulders.',
      'Step your feet back so your body forms a straight line from head to heels.',
      'Brace your abs and squeeze your glutes; do not let your hips sag or pike up.',
      'Breathe steadily and hold for the set time.',
    ],
  },
]
