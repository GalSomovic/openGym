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
  {
    id: 'gf-bulgarian-split-squat', n: 'bulgarian split squat', bp: 'upper legs', eq: 'body weight', tg: 'quads', mg: 'glutes',
    sm: ['glutes', 'hamstrings', 'adductors', 'core'],
    st: [
      'Stand a stride in front of a bench and rest the top of your back foot on it.',
      'Keep your chest up and lower straight down until your front thigh is about parallel to the floor.',
      'Keep your front knee over your foot and most of your weight on the front leg.',
      'Drive through the front heel to stand back up. Finish all reps, then switch legs.',
    ],
  },
  {
    id: 'gf-reverse-lunge', n: 'reverse lunge', bp: 'upper legs', eq: 'body weight', tg: 'quads', mg: 'glutes',
    sm: ['glutes', 'hamstrings', 'calves', 'core'],
    st: [
      'Stand tall with your feet hip-width apart.',
      'Step one foot back and lower until both knees bend to about 90 degrees, the back knee just above the floor.',
      'Keep your torso upright and your front knee over your ankle.',
      'Push through the front heel to bring the back foot forward and stand. Alternate legs.',
    ],
  },
  {
    id: 'gf-wall-sit', n: 'wall sit', bp: 'upper legs', eq: 'body weight', tg: 'quads', mg: 'glutes',
    sm: ['glutes', 'hamstrings', 'calves'],
    st: [
      'Stand with your back against a wall and your feet about two feet in front of you.',
      'Slide down the wall until your thighs are parallel to the floor and your knees are over your ankles.',
      'Keep your back flat against the wall and your weight in your heels.',
      'Hold for the set time, breathing steadily, then slide back up.',
    ],
  },
  {
    id: 'gf-step-up', n: 'step-up', bp: 'upper legs', eq: 'body weight', tg: 'quads', mg: 'glutes',
    sm: ['glutes', 'hamstrings', 'calves'],
    st: [
      'Stand facing a sturdy box or step about knee height.',
      'Place one whole foot on the box and drive through that heel to stand up on it.',
      'Bring the other foot up, standing tall at the top.',
      'Step back down with the trailing leg first, then the lead leg. Repeat, then switch the lead leg.',
    ],
  },
  {
    id: 'gf-dead-hang', n: 'dead hang', bp: 'back', eq: 'body weight', tg: 'forearms', mg: 'lats',
    sm: ['lats', 'shoulders', 'grip muscles'],
    st: [
      'Grip a pull-up bar overhand, hands about shoulder-width apart.',
      'Hang with your arms straight and your feet off the floor.',
      'Keep your shoulders active, not shrugged up to your ears, and your body still.',
      'Hold for the set time, then step down.',
    ],
  },
  {
    id: 'gf-negative-pull-up', n: 'negative pull-up', bp: 'back', eq: 'body weight', tg: 'lats', mg: 'biceps',
    sm: ['biceps', 'upper back', 'forearms'],
    st: [
      'Jump or step up so your chin is above the bar, holding it overhand.',
      'Hold the top for a moment, chest up.',
      'Lower yourself as slowly as you can, taking three to five seconds, until your arms are straight.',
      'Step down, reset and repeat.',
    ],
  },
  {
    id: 'gf-toes-to-bar', n: 'toes to bar', bp: 'waist', eq: 'body weight', tg: 'abs', mg: 'hip flexors',
    sm: ['hip flexors', 'lats', 'obliques', 'forearms'],
    st: [
      'Hang from a pull-up bar with straight arms.',
      'Brace your abs and lift your straight legs, pressing the bar down with straight arms.',
      'Bring your toes up to touch the bar between your hands.',
      'Lower your legs under control without swinging.',
    ],
  },
]
