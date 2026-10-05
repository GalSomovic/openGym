# GymFree — Training Evidence Base (routines, plans, plan-builder algorithm)

Status: source of truth for preset routines and the deterministic plan builder.
Compiled: 2026-10-05. Every citation was checked against PubMed / Europe PMC / the publisher at compile time.

---

## 0. How to read this document

**Evidence standard (same bar as the ADHD research).** In order of preference: systematic reviews and meta-analyses, large or preregistered RCTs, consensus guidelines from public-health or independent professional bodies. Narrative reviews and single small trials are weaker. Fitness blogs, brand sites, coaching businesses and influencers are **not** cited as evidence.

**Tiers**
- **Tier 1**: strong and consistent (meta-analytic or guideline level). Presets are built on these.
- **Tier 2**: moderate or emerging (a few meta-analyses with heterogeneity, preprints, small RCT sets). Fine as defaults, but keep them easy to change.
- **Tier 3**: weak, contested or expert practice only. Do not build the core logic on these. Where the app still has to make a choice (for example deload timing), the choice is labelled **engineering default**.

**Population tags**: [untrained], [trained], [men], [women], [young], [older adults], [overweight/obesity], [mostly young men]. Most resistance-training (RT) research uses men aged 18–35. For example, the largest volume/frequency meta-regression was 79% male, mean age 25 ([Pelland 2026](https://pubmed.ncbi.nlm.nih.gov/41343037/)). The big ACSM-linked network meta-analysis is the main exception at 45–47% women ([Currier 2023](https://pubmed.ncbi.nlm.nih.gov/37414459/)).

**Conflict-of-interest (COI) handling.** COI or funding was checked for each load-bearing paper. Section 12 lists flagged items. Some caveats apply across the whole field:
- Several prolific authors also sell coaching, books or education products: Krieger (Weightology), Nuckols (Stronger By Science), Helms (3DMJ), Israetel (Renaissance Periodization), Aragon, Henselmans, and Schoenfeld (trade books).
- Their systematic reviews are used only where independent groups agree with them. The main independent checks are the ACSM 2026 position stand, the McMaster network meta-analysis and Cochrane reviews.
- No Tier 1 call depends on them alone.
- Studies funded by a company selling a program, app or equipment are flagged and capped at Tier 3.

---

## 1. Summary table: key numbers

| # | Topic | Number / rule | Tier | Population | Key sources |
|---|---|---|---|---|---|
| 1 | Any RT vs none | The largest benefit comes from going from no RT to any RT. Train all major muscle groups **at least 2 days/week**. | 1 | adults, all ages | [ACSM 2026](https://pubmed.ncbi.nlm.nih.gov/41843416/), [WHO 2020](https://pubmed.ncbi.nlm.nih.gov/33239350/) |
| 2 | Health dose of RT | Lower all-cause mortality, CVD and cancer risk peak at about **30–60 min/week** of muscle-strengthening. | 1 (observational) | adults | [Momma 2022](https://pubmed.ncbi.nlm.nih.gov/35228201/) |
| 3 | Hypertrophy volume | **≥10 sets/muscle/week** beats fewer. More gives more, with diminishing returns. Practical range **10–20**. | 1 (≥10, dose–response); 2 (upper bound) | mostly young men | [ACSM 2026](https://pubmed.ncbi.nlm.nih.gov/41843416/), [Schoenfeld 2017](https://pubmed.ncbi.nlm.nih.gov/27433992/), [Pelland 2026](https://pubmed.ncbi.nlm.nih.gov/41343037/), [Baz-Valle 2022](https://pubmed.ncbi.nlm.nih.gov/35291645/) |
| 4 | Minimum effective dose | About **4 sets/muscle/week** at 6–15 RM. In trained men, **1 hard set, 2–3×/week** still raises 1RM. | 2 | untrained & trained men | [Iversen 2021](https://pubmed.ncbi.nlm.nih.gov/34125411/), [Androulakis-Korakakis 2020](https://pubmed.ncbi.nlm.nih.gov/31797219/) |
| 5 | Strength volume | **2–3 sets per exercise** at **≥80% 1RM**, ≥2×/week. | 1 | adults | [ACSM 2026](https://pubmed.ncbi.nlm.nih.gov/41843416/), [Currier 2023](https://pubmed.ncbi.nlm.nih.gov/37414459/) |
| 6 | Frequency (hypertrophy) | No meaningful effect when weekly volume is equated. | 1 | mostly young | [Schoenfeld 2019](https://pubmed.ncbi.nlm.nih.gov/30558493/), [Pelland 2026](https://pubmed.ncbi.nlm.nih.gov/41343037/) |
| 7 | Frequency (strength) | Higher frequency helps strength, with diminishing returns (1→2×/week matters most). | 1–2 | mostly young | [Pelland 2026](https://pubmed.ncbi.nlm.nih.gov/41343037/), [Grgic 2018](https://pubmed.ncbi.nlm.nih.gov/29470825/) |
| 8 | Per-session ceiling | Extra sets stop adding detectable benefit at about **11 "fractional" sets per muscle per session** (hypertrophy) and about **2 direct sets per session** (strength). | 2 (preprint) | mostly young men | [Remmert 2025 preprint](https://doi.org/10.51224/SRXIV.537) |
| 9 | Load / rep range | Hypertrophy is similar from about 6 to 30+ reps when sets end near failure. Strength is best with heavy loads (≤8 RM, ≥80% 1RM). | 1 | young adults | [Schoenfeld 2017b](https://pubmed.ncbi.nlm.nih.gov/28834797/), [Lopez 2021](https://pubmed.ncbi.nlm.nih.gov/33433148/), [Currier 2023](https://pubmed.ncbi.nlm.nih.gov/37414459/) |
| 10 | Proximity to failure | Training to failure is **not required**. Hypertrophy improves as sets end closer to failure; strength is insensitive to it. Default **1–3 RIR**. | 1 (not required); 2 (dose–response) | mostly young | [Grgic 2022](https://pubmed.ncbi.nlm.nih.gov/33497853/), [Refalo 2023](https://pubmed.ncbi.nlm.nih.gov/36334240/), [Robinson 2024](https://pubmed.ncbi.nlm.nih.gov/38970765/), [ACSM 2026](https://pubmed.ncbi.nlm.nih.gov/41843416/) |
| 11 | Rest intervals | Hypertrophy: rest **>60 s**, with no added benefit beyond about **90 s**. Strength in trained lifters: **≥2 min**. Untrained lifters: 60–120 s is enough. | 2 | mostly young men | [Singer 2024](https://pubmed.ncbi.nlm.nih.gov/39205815/), [Grgic 2018b](https://pubmed.ncbi.nlm.nih.gov/28933024/) |
| 12 | Split choice | Full-body ≈ split when volume is equated. Choose by schedule. | 1 | mostly young | [Ramos-Campo 2024](https://pubmed.ncbi.nlm.nih.gov/38595233/) |
| 13 | Equipment | Free weights ≈ machines; elastic bands ≈ weights for strength; push-ups ≈ bench press at matched effort. A gym is not required. | 1 (ACSM: effective); 2 (equivalence) | mixed | [Haugen 2023](https://pubmed.ncbi.nlm.nih.gov/37582807/), [Lopes 2019](https://pubmed.ncbi.nlm.nih.gov/30815258/), [Kikuchi 2017](https://pubmed.ncbi.nlm.nih.gov/29541130/), [ACSM 2026](https://pubmed.ncbi.nlm.nih.gov/41843416/) |
| 14 | Aerobic dose | **150–300 min/week moderate** or **75–150 min/week vigorous**, or a mix. | 1 | adults, older adults | [WHO 2020](https://pubmed.ncbi.nlm.nih.gov/33239350/), [US PAG 2018](https://pubmed.ncbi.nlm.nih.gov/30418471/) |
| 15 | HIIT vs steady state | Similar fat loss when energy expenditure is matched. HIIT gives slightly more VO2max (~1.2 mL/kg/min). | 1 (fat); 2 (VO2max) | young–middle-aged | [Bellicha 2021](https://pubmed.ncbi.nlm.nih.gov/33955140/), [Wewege 2017](https://pubmed.ncbi.nlm.nih.gov/28401638/), [Milanović 2015](https://pubmed.ncbi.nlm.nih.gov/26243014/) |
| 16 | Interference effect | Adding cardio does **not** blunt hypertrophy or maximal strength on average. It may blunt explosive strength (worse in the same session) and lower-body 1RM in trained lifters. | 1 (no effect on hypertrophy); 2 (trained/explosive) | adults | [Schumann 2022](https://pubmed.ncbi.nlm.nih.gov/34757594/), [Petré 2021](https://pubmed.ncbi.nlm.nih.gov/33751469/) |
| 17 | Exercise-only weight loss | About **1.5–3.5 kg**. Diet plus exercise beats exercise alone by about **6 kg at 12–18 months**. | 1 | overweight/obesity | [Bellicha 2021](https://pubmed.ncbi.nlm.nih.gov/33955140/), [Johns 2014](https://pubmed.ncbi.nlm.nih.gov/25257365/) |
| 18 | Lean mass in a deficit | RT spares about **0.8 kg** of lean mass during weight loss. Keep the deficit **≤500 kcal/day** to protect lean mass. | 1 (RT spares); 2 (≤500 kcal) | overweight/obesity; mixed | [Bellicha 2021](https://pubmed.ncbi.nlm.nih.gov/33955140/), [Lopez 2022](https://pubmed.ncbi.nlm.nih.gov/35191588/), [Murphy & Koehler 2022](https://pubmed.ncbi.nlm.nih.gov/34623696/) |
| 19 | Steps | Mortality risk keeps falling up to about **6,000–8,000 steps/day (age ≥60)** and **8,000–10,000 (age <60)**. "10,000" is not a threshold. | 1 (observational) | adults | [Paluch 2022](https://pubmed.ncbi.nlm.nih.gov/35247352/) |
| 20 | Falls (older adults) | Exercise cuts the fall rate by **23%**. Balance + functional exercise: **24%**. Multicomponent (balance + resistance): **34%**. RT alone: uncertain. WHO: multicomponent training **≥3 days/week**. | 1 | older adults (60+) | [Sherrington 2019 (Cochrane)](https://pubmed.ncbi.nlm.nih.gov/30703272/), [WHO 2020](https://pubmed.ncbi.nlm.nih.gov/33239350/) |
| 21 | Screening | Use the ACSM 2015 algorithm (current activity × disease/symptoms × intended intensity) and PAR-Q+ style questions. Most people need no medical clearance for light–moderate exercise. | 1 (guideline) | adults | [Riebe 2015](https://pubmed.ncbi.nlm.nih.gov/26473759/), [Bredin 2013](https://pubmed.ncbi.nlm.nih.gov/23486800/) |
| 22 | Adherence | Enjoyment, autonomy, low complexity, consistency, progress feedback and supervision help. A habit forms after about **≥4 sessions/week for 6 weeks**. Longer sessions increase dropout. | 2 | mixed | [Collado-Mateo 2021](https://pubmed.ncbi.nlm.nih.gov/33669679/), [Teixeira 2012](https://pubmed.ncbi.nlm.nih.gov/22726453/), [Kaushal 2015](https://pubmed.ncbi.nlm.nih.gov/25851609/), [Reljic 2019](https://pubmed.ncbi.nlm.nih.gov/31050061/) |
| 23 | Warm-up and stretching | A general plus exercise-specific warm-up improves performance. Static stretching **≥60 s per muscle** lowers performance by about 4.6% (less than 60 s: about 1%). Stretching does **not** prevent injury. RT itself improves ROM. | 1–2 | active adults | [Fradkin 2010](https://pubmed.ncbi.nlm.nih.gov/19996770/), [Behm 2016](https://pubmed.ncbi.nlm.nih.gov/26642915/), [Lauersen 2014](https://pubmed.ncbi.nlm.nih.gov/24100287/), [Alizadeh 2023](https://pubmed.ncbi.nlm.nih.gov/36622555/) |
| 24 | Progression | Adding load and adding reps both work. ACSM: raise load **2–10%** once the trainee can do 1–2 reps above target. | 2 | trained; guideline | [Plotkin 2022](https://pubmed.ncbi.nlm.nih.gov/36199287/), [ACSM 2009](https://pubmed.ncbi.nlm.nih.gov/19204579/) |
| 25 | Periodization | Small 1RM benefit (ES 0.31), none for hypertrophy. ACSM 2026: optional for the average adult. | 2 | mixed | [Moesgaard 2022](https://pubmed.ncbi.nlm.nih.gov/35044672/), [ACSM 2026](https://pubmed.ncbi.nlm.nih.gov/41843416/) |
| 26 | Deloads | No good evidence that scheduled deloads improve outcomes. One industry-funded RCT found a 1-week full break **reduced** strength and did not change hypertrophy. | 3 | trained | [Coleman 2024](https://pubmed.ncbi.nlm.nih.gov/38274324/) (flagged) |
| 27 | Sex differences | Similar **relative** hypertrophy. Women gain more relative upper-body strength. Use the same programming for both. | 2 | untrained men & women | [Roberts 2020](https://pubmed.ncbi.nlm.nih.gov/32218059/) (flagged), [Hubal 2005](https://pubmed.ncbi.nlm.nih.gov/15947721/) |
| 28 | Range of motion | Full ROM beats partial ROM for strength (ES 0.56) and lower-limb hypertrophy. | 2 | mixed | [Pallarés 2021](https://pubmed.ncbi.nlm.nih.gov/34170576/) |

---

## 2. Resistance-training dose (Q1)

### 2.1 Weekly sets per muscle (hypertrophy)
- **≥10 sets/muscle/week produces more hypertrophy than fewer — Tier 1.** [mostly young men]
  - Schoenfeld, Ogborn & Krieger: each extra weekly set adds about **0.37%** to muscle growth. Higher-volume arms beat lower-volume arms by about **3.9 percentage points**. 15 studies. ([PubMed 27433992](https://pubmed.ncbi.nlm.nih.gov/27433992/))
  - The 2026 ACSM position stand (an overview of 137 systematic reviews, >30,000 participants) independently concludes that hypertrophy benefits from "higher volumes (≥10 sets/wk)". ([PubMed 41843416](https://pubmed.ncbi.nlm.nih.gov/41843416/), [ACSM summary](https://acsm.org/resistance-training-guidelines/))
- **Dose–response with diminishing returns — Tier 1 for its shape, Tier 2 for exact numbers.** [79% male, mean age 25]
  - Pelland et al. 2026 ran meta-regressions over 67 studies (n = 2,058). Posterior probability that more volume increases hypertrophy and strength: **100%** for both. Both curves flatten, and strength flattens much sooner. ([PubMed 41343037](https://pubmed.ncbi.nlm.nih.gov/41343037/), [preprint with full text](https://doi.org/10.51224/SRXIV.460))
  - Their volume-counting method fit best and is adopted here: a **direct set counts 1** for the target muscle and an **indirect set counts 0.5**. Example: a bench-press set is 1 for chest and 0.5 for triceps.
  - A systematic review proposed **12–20 sets/muscle/week** as the productive range for trained lifters ([Baz-Valle 2022, PMID 35291645](https://pubmed.ncbi.nlm.nih.gov/35291645/)). Evidence above about 20 sets is sparse and mostly from trained young men — Tier 3.
- **Multiple sets beat a single set** per exercise: about **40% larger** hypertrophy effect sizes, in both trained and untrained people — Tier 1/2 ([Krieger 2010, PMID 20300012](https://pubmed.ncbi.nlm.nih.gov/20300012/); author COI flagged in §12). Currier 2023 agrees: multiset prescriptions ranked highest ([PMID 37414459](https://pubmed.ncbi.nlm.nih.gov/37414459/)).

**Product consequence:** The plan builder counts **fractional weekly sets per muscle** (direct = 1, indirect = 0.5). Default targets:
- 10 sets for muscle-building goals.
- 4–6 for health/minimum.
- 12–16 for intermediates.
- 14–20 for advanced users.

Never auto-prescribe more than 20 fractional sets/muscle/week.

### 2.2 Per-session volume ceiling
- **Benefit per session plateaus at about 11 fractional sets per muscle (hypertrophy) and about 2 direct sets per exercise (strength) — Tier 2 (preprint, not yet peer reviewed).** [mostly young men]
  - Remmert et al. 2025 call this the "point of undetectable outcome superiority". They report too little data at very high per-session volumes to say whether more helps or harms. ([SportRxiv 10.51224/SRXIV.537](https://doi.org/10.51224/SRXIV.537), [FAU summary](https://fau.edu/newsdesk/articles/build-muscle-gain-strength-study.php))
  - A separate whole-body meta-analysis of 111 studies found that more **sets per workout** was negatively associated with lean-mass gain ([Benito 2020, PMID 32079265](https://pubmed.ncbi.nlm.nih.gov/32079265/)) — Tier 2.

**Product consequence:** Cap a muscle at **≤10 fractional sets per session**. If the weekly target needs more, spread it over more sessions. This is why a "bro split" (each muscle once a week) is not a default: 16 sets for one muscle in a single session wastes about a third of them.

### 2.3 Frequency per muscle per week
- **Hypertrophy: frequency does not matter when weekly volume is equated — Tier 1.** [mostly young; trained and untrained]
  - Schoenfeld, Grgic & Krieger 2019 (25 studies) found no difference on a volume-equated basis. When volume was not equated, higher frequency helped only modestly. ([PMID 30558493](https://pubmed.ncbi.nlm.nih.gov/30558493/))
  - Pelland 2026: frequency's effect on hypertrophy is "compatible with negligible". ACSM 2026: frequency does not affect hypertrophy when volume is equated.
- **Strength: more frequency helps, with diminishing returns — Tier 1/2.**
  - Pelland 2026: posterior probability 100% that strength rises with frequency, with diminishing returns.
  - Grgic 2018 effect sizes by sessions/week: 1× = 0.74, 2× = 0.82, 3× = 0.93, 4+× = 1.08. The difference disappears when volume is equated, which suggests extra volume is doing the work. ([PMID 29470825](https://pubmed.ncbi.nlm.nih.gov/29470825/))
- ACSM 2026: RT at least 2×/week improves strength (QoE 69%).

**Product consequence:** Every preset trains each major muscle **≥2×/week**. Strength presets train each main lift **2–3×/week**. Days per week is a **scheduling** choice, not an "effectiveness" choice. The app should say so.

### 2.4 Load, rep ranges and goal
- **Hypertrophy is load-independent across a wide range when sets end near failure — Tier 1.** [young adults; most trials to failure]
  - Schoenfeld 2017b (21 studies): low-load (≤60% 1RM) and high-load training give similar hypertrophy; 1RM gains favour heavy loads. ([PMID 28834797](https://pubmed.ncbi.nlm.nih.gov/28834797/))
  - Lopez 2021 network meta-analysis (28 studies, n = 747) compared low load (>15 RM), moderate (9–15 RM) and high (≤8 RM). Hypertrophy did not differ. Strength was better with high or moderate loads than with low loads. ([PMID 33433148](https://pubmed.ncbi.nlm.nih.gov/33433148/))
  - Currier 2023 network meta-analysis (178 strength studies with 45% women; 119 hypertrophy studies with 47% women):
    - Higher-load (>80% 1RM) prescriptions maximised strength.
    - All prescriptions promoted similar hypertrophy.
    - 91% of head-to-head comparisons were not significant.
    - Top-ranked: high-load, multiset, 3×/week for strength; 2×/week for hypertrophy.
    - Conclusion: adults "can adopt a resistance training prescription of their choice". ([PMID 37414459](https://pubmed.ncbi.nlm.nih.gov/37414459/))
- **Strength: ≥80% 1RM, 2–3 sets — Tier 1** (ACSM 2026: load QoE 79%, volume QoE 71%).
- **Novices: 8–12 RM** is the classic ACSM 2009 recommendation. It is guideline level but older, and the newer evidence above shows a wider range works. ([PMID 19204579](https://pubmed.ncbi.nlm.nih.gov/19204579/))

**Product consequence:** Rep ranges by goal:
- Hypertrophy and general: **6–12** for compounds, **10–20** for isolation, bodyweight and bands. Up to **30** is allowed when the variation is easy.
- Strength: **3–6** for main lifts at RIR 1–3, which is about 80–88% 1RM. Accessories stay at 6–12.

No preset requires a 1RM test. Load is set by reps and RIR.

### 2.5 Proximity to failure (RIR)
- **Failure is not required — Tier 1.**
  - Grgic 2022 (15 studies, young adults): no difference between failure and non-failure for strength or hypertrophy. A small hypertrophy edge for failure appeared only in trained subgroups (ES 0.15). ([PMID 33497853](https://pubmed.ncbi.nlm.nih.gov/33497853/))
  - Refalo 2023: training to momentary failure was not better than non-failure ([PMID 36334240](https://pubmed.ncbi.nlm.nih.gov/36334240/)).
  - Refalo 2024 RCT in trained men and women: 0 RIR vs 1–2 RIR gave the same quadriceps growth, and the failure condition caused more fatigue ([PMID 38393985](https://pubmed.ncbi.nlm.nih.gov/38393985/)).
  - ACSM 2026: failure training "did not consistently impact" outcomes.
- **Hypertrophy improves as sets end closer to failure; strength does not depend on it — Tier 2.** Robinson 2024's exploratory meta-regressions: RIR had a negative slope for hypertrophy and a null slope for strength ([PMID 38970765](https://pubmed.ncbi.nlm.nih.gov/38970765/)).
- **People misjudge RIR by about 1 rep**, typically underpredicting how many reps they have left. They are more accurate close to failure and in sets of ≤12 reps — Tier 2 ([Halperin 2022, PMID 34542869](https://pubmed.ncbi.nlm.nih.gov/34542869/)).

**Product consequence:** Default RIR is **1–3**.
- New users: **RIR 3–4** in weeks 1–2 (technique, plus a pleasant first experience; see §9).
- Optional **0–1 RIR** on the last set of isolation, machine or bodyweight exercises.
- **Never 0 RIR** on heavy barbell compounds.
- RIR prompt wording: "stop when you could do about 2 more good reps".

### 2.6 Rest intervals
- **Hypertrophy: rest >60 s; no detectable benefit beyond about 90 s — Tier 2.** Singer 2024 Bayesian meta-analysis (9 studies) ([PMID 39205815](https://pubmed.ncbi.nlm.nih.gov/39205815/)).
- **Strength: short rests still produce strength. Trained lifters gain more with longer rests (>2 min); untrained lifters do fine with 60–120 s — Tier 2.** Grgic 2018b, 23 studies, 84% male ([PMID 28933024](https://pubmed.ncbi.nlm.nih.gov/28933024/)). ACSM 2026: rest interval did not affect strength outcomes.

**Product consequence:** Rest-timer defaults:
- **90 s** for hypertrophy and general sets.
- **2–3 min** for strength-preset main lifts.
- **60 s** for isolation, bodyweight and bands.

Antagonist supersets are allowed to save time (§2.7).

### 2.7 Session length and the busy beginner
- **Health dose: about 30–60 min/week** of muscle-strengthening is where all-cause mortality, CVD and cancer risk are lowest. Associations are J-shaped, so benefit above this is unclear. Tier 1 (cohort data) ([Momma 2022, PMID 35228201](https://pubmed.ncbi.nlm.nih.gov/35228201/)).
- **Time-efficient programming — Tier 2** (narrative review by academics, NTNU-funded) ([Iversen 2021, PMID 34125411](https://pubmed.ncbi.nlm.nih.gov/34125411/)):
  - Minimum of **4 weekly sets per muscle** at **6–15 RM** (15–40 reps if taken to failure).
  - Prioritise one leg press/squat, one upper-body pull and one upper-body push.
  - Supersets, drop sets and rest-pause roughly halve session time.
  - Keep warm-ups exercise-specific; stretch only if flexibility is the goal.
- **Trained men:** a single set of 6–12 reps at about 70–85% 1RM, 2–3×/week, near failure, for 8–12 weeks raised squat by about 17 kg and bench by about 8 kg. Gains were described as suboptimal but significant. Tier 2 (6 studies) ([Androulakis-Korakakis 2020, PMID 31797219](https://pubmed.ncbi.nlm.nih.gov/31797219/)).

**Product consequence:**
- The "Minimal Dose" and "First Steps" presets use **2 sessions × 25–35 min**, about 4–6 fractional sets/muscle/week, built mainly from compound lifts. Antagonist supersets are on by default.
- The plan builder must respect the user's minutes per session (formula in §13.4).

---

## 3. Progression, expectations, deloads (Q2)

### 3.1 How to progress
- **Load progression and rep progression both work — Tier 2.** Plotkin 2022 RCT (n = 43, trained men and women): adding load vs adding reps gave similar hypertrophy and strength over 8 weeks ([PMID 36199287](https://pubmed.ncbi.nlm.nih.gov/36199287/)). COI flag in §12.
- **ACSM rule:** raise load by **2–10%** once the trainee can do 1–2 reps above the target on the current load. Tier 2 (2009 guideline; still the only formal rule) ([PMID 19204579](https://pubmed.ncbi.nlm.nih.gov/19204579/)).
- **Linear progression vs double progression** has never been compared head to head. Choosing between them is Tier 3 practice. Double progression (work up through a rep range, then add load) is the more general choice because it:
  - handles large dumbbell jumps,
  - handles bodyweight and bands (rep → variation progression), and
  - is self-limiting when progress slows.
- **Periodization:** adds a modest 1RM benefit over non-periodized training (ES 0.31) and no hypertrophy benefit. Undulating beat linear periodization only in trained subjects. Tier 2 ([Moesgaard 2022, PMID 35044672](https://pubmed.ncbi.nlm.nih.gov/35044672/)). ACSM 2026: periodization "did not consistently impact" outcomes for the average adult.
- **Exercise variation:** systematic variation (for example 2–3 exercises per muscle that cover different joint angles) may help regional growth. Excessive random rotation may hurt. All 8 studies were in young men — Tier 2 ([Kassiano 2022, PMID 35438660](https://pubmed.ncbi.nlm.nih.gov/35438660/)).

**Product consequence:**
- **Default rule for all presets: double progression.**
  - Each exercise has a rep range [lo, hi] and a target RIR.
  - When **every** working set reaches `hi` at or above the target RIR, raise the load next session by the smallest available step. That is about 2–5% for barbell and machine (barbell: +2.5 kg upper, +5 kg lower). For dumbbells, use the next dumbbell.
  - Bodyweight and bands: move to the next variation or band (§5.4).
  - Reset reps to `lo`.
- **Strength preset:** fixed-rep load progression on main lifts (§13).
- **Stall rule (engineering default):** if the user misses `lo` on an exercise in **2 consecutive sessions**, reduce load by about 10% and climb again. If it stalls 3 times, offer an exercise swap.
- Keep the same exercises for at least a **6–8-week block**. No random daily rotation.
- Periodization stays optional: weekly heavy/moderate/light undulation is used only in the strength preset.

### 3.2 Realistic gain rates (for expectation-setting copy)
- **Large individual variation — Tier 1.** Hubal 2005 (n = 585; 342 women, 243 men; 12 weeks of elbow-flexor training): biceps size changes ranged from **−2% to +59%** and 1RM changes from **0 to +250%**. Women outpaced men in **relative** strength gain; men had only a slight edge in relative size gain. ([PMID 15947721](https://pubmed.ncbi.nlm.nih.gov/15947721/))
- **Average whole-body lean-mass gain in RT trials: about 1.5 kg** [healthy men, 111 studies] ([Benito 2020, PMID 32079265](https://pubmed.ncbi.nlm.nih.gov/32079265/)) — Tier 1 for the average, though trials are typically 8–12 weeks.
- **Untrained people grow more than trained people** ([Lopez 2021](https://pubmed.ncbi.nlm.nih.gov/33433148/)). Trained people sit further along the diminishing-returns curve ([Pelland 2026](https://pubmed.ncbi.nlm.nih.gov/41343037/)) — Tier 1/2.
- **Sex:** similar relative hypertrophy and lower-body strength; women gain more relative upper-body strength (ES −0.60) ([Roberts 2020, PMID 32218059](https://pubmed.ncbi.nlm.nih.gov/32218059/)) — Tier 2. Authors run commercial businesses (§12); Hubal's independent NIH-funded cohort agrees. [women: less data overall]
- ACSM 2026 rejects the idea that beginners need fundamentally different programs from trained lifters ([ACSM summary](https://acsm.org/resistance-training-guidelines/)).

**Product consequence:**
- Never promise numbers. Copy should say something like: "Most beginners get noticeably stronger within 4–8 weeks. Muscle growth is slower and varies a lot between people."
- **Do not branch programming on sex.** Sex is optional and is not used by the algorithm.
- Experience level changes volume and RIR only, not program structure.

### 3.3 Deloads
- **No meta-analytic evidence on deloads — Tier 3.** Coleman 2024 RCT (n = 39 trained; **funded by Renaissance Periodization LLC**, a commercial coaching and app company): a 1-week complete break mid-program did not change hypertrophy and produced **smaller strength gains** ([PMID 38274324](https://pubmed.ncbi.nlm.nih.gov/38274324/)).
- **Detraining:** older adults kept most of their muscle size after 12–24 weeks without training. Losses were significant after 31–52 weeks — Tier 2 ([Grgic 2022, PMID 36360927](https://pubmed.ncbi.nlm.nih.gov/36360927/)).

**Product consequence (engineering defaults, Tier 3):**
- **No scheduled deloads for novices or low-volume presets.**
- **Reactive deload** when any of these occur:
  - (a) performance drops on ≥2 exercises across 2 consecutive sessions,
  - (b) the user reports unusual fatigue, poor sleep or joint pain for a week, or
  - (c) more than 8 weeks of high-volume training (≥15 sets/muscle/week).
- Deload = **one week at about 50% of sets, same exercises, about 90% load, RIR ≥3**. Do not use a full week off.
- Missed weeks are not a crisis: short breaks do not erase progress.

---

## 4. Split choice (Q3)

- **Full-body vs split routines give the same strength and hypertrophy when volume is equated — Tier 1.** Ramos-Campo 2024 meta-analysis: 14 studies, 392 subjects, no difference in bench press, lower-limb strength, arm or thigh cross-sectional area, or lean mass. Authors conclude people can choose by preference. ([PMID 38595233](https://pubmed.ncbi.nlm.nih.gov/38595233/)) The frequency meta-analyses (§2.3) agree.
- Splits differ mainly in how they meet three constraints:
  - each muscle trained ≥2×/week (§2.3),
  - ≤~10 fractional sets per muscle per session (§2.2),
  - the user's minutes per session.

| Days/week | Default split | Each muscle per week | Notes |
|---|---|---|---|
| 2 | Full body A/B | 2× | Best for beginners, busy people and older adults. Meets the WHO/ACSM minimum. |
| 3 | Full body A/B alternating (ABA / BAB) | 3× (or 2–3×) | Strongest default for novices (ACSM 2009: novices 2–3 d/week). Top-ranked strength prescription is 3×/week ([Currier 2023](https://pubmed.ncbi.nlm.nih.gov/37414459/)). |
| 4 | Upper / Lower ×2 | 2× | Fits 12–16 sets/muscle in 60–75 min. |
| 5 | Upper / Lower / Push / Pull / Legs | ~2× | For intermediate+ users. Alternative: 3 full-body + 2 cardio days. |
| 6 | Push / Pull / Legs ×2 | 2× | For advanced users only. Novices get 3–4 RT days and walking/cardio on the others. |
| "Bro split" (1 muscle group per day) | Not a default | 1× | Same hypertrophy only if volume is equal, but it breaks the per-session ceiling and the strength-frequency benefit. Offer only if the user explicitly picks it. |

**Product consequence:** Choose the split **deterministically from days/week** using the table. Novices who ask for 5–6 days get **3–4 RT days**, with the remaining days as cardio, walking or optional mobility. Copy: "More gym days aren't required to make progress as a beginner."

---

## 5. Exercise selection and equipment (Q4)

### 5.1 Compound vs isolation
- Compound (multi-joint) exercises are the most time-efficient way to cover all muscles ([Iversen 2021](https://pubmed.ncbi.nlm.nih.gov/34125411/)) — Tier 2 (narrative). ACSM 2026: exercise order matters for strength. The exercise done **first** gains most (QoE 88%) — Tier 1/2.
- Isolation adds direct volume to muscles that compounds hit only partially: biceps, triceps, lateral/rear delts, calves, and hamstrings via knee flexion. Systematic variation may help regional growth ([Kassiano 2022](https://pubmed.ncbi.nlm.nih.gov/35438660/)) — Tier 2.
- **Full ROM** beats partial ROM for strength (ES 0.56) and lower-limb hypertrophy (ES 0.88) ([Pallarés 2021, PMID 34170576](https://pubmed.ncbi.nlm.nih.gov/34170576/)) — Tier 2. ACSM 2026 lists full ROM as positive for strength (QoE 50%).

**Product consequence:** Build each session from **movement-pattern slots**:
- knee-dominant
- hip hinge
- horizontal push
- vertical push
- horizontal pull
- vertical pull
- single-leg
- isolation: arms / delts / calves / hamstring curl
- core / carry

Order: compounds first, isolation last; the goal-priority lift goes first. Each slot keeps the same exercise for the whole block.

### 5.2 Free weights vs machines
- **No difference in hypertrophy or strength when tested on neutral equipment; strength gains are specific to the modality trained — Tier 1/2.** Haugen 2023 (13 studies, n = 1,016, 78% men) ([PMID 37582807](https://pubmed.ncbi.nlm.nih.gov/37582807/)). ACSM 2026: equipment type showed no consistent difference.

**Product consequence:** Machine, free-weight, cable, band and bodyweight versions of a slot are **interchangeable** for programming. Swap freely for equipment, comfort or joint issues.

### 5.3 Bodyweight and bands — can they build muscle and strength?
- **Yes — Tier 1 for "effective", Tier 2 for "as effective as weights".**
  - ACSM 2026: "elastic bands, bodyweight exercises, and home-based training" are effective, and a gym is not required ([ACSM infographic](https://acsm.org/wp-content/uploads/2026/03/Resistance-Training-Position-Stand-infographic.pdf)).
  - **Bands vs weights:** no difference in strength gains, upper limb (SMD 0.09) or lower limb (SMD −0.11). 8 RCTs, mixed populations. ([Lopes 2019, PMID 30815258](https://pubmed.ncbi.nlm.nih.gov/30815258/))
  - **Push-up vs bench press:** with load matched to about 40% 1RM bench, push-ups produced similar pectoral and triceps growth and 1RM gains over 8 weeks (n = 18 men) ([Kikuchi 2017, PMID 29541130](https://pubmed.ncbi.nlm.nih.gov/29541130/)). A related RCT found similar strength gains at matched muscle activity ([Calatayud 2015, PMID 24983847](https://pubmed.ncbi.nlm.nih.gov/24983847/)). Small trials [young men] — Tier 2.
  - **Progressive calisthenics:** push-up variations progressed over 4 weeks raised bench 1RM comparably to bench training (n = 23 moderately trained men) ([Kotarsky 2018, PMID 29466268](https://pubmed.ncbi.nlm.nih.gov/29466268/)) — Tier 2/3.
  - **Mechanism:** low-load training near failure grows muscle as well as heavy loads (§2.4). Bodyweight and band sets of 10–30 reps near failure are therefore a valid hypertrophy stimulus. **Max-strength transfer to a barbell 1RM will be smaller** because strength is specific to the modality.

**Product consequence:**
- Bodyweight-only and bands-only presets are first-class presets, not "lite" versions.
- They use wider rep ranges (8–20, up to 30) and lower RIR (0–2). That is safe on bodyweight, except for balance-demanding single-leg work, where RIR is 1–2.
- Progression is by variation ladder (§5.4).
- The app should not claim these presets maximise 1RM barbell strength.

### 5.4 Calisthenics progressions (structure Tier 3; principle Tier 2)
No RCT compares specific progression ladders. They follow biomechanics: increase the share of body weight lifted, the lever length, or move to one limb. The principle of progressing by variation is supported by Kotarsky 2018.

| Slot | Ladder (easier → harder) |
|---|---|
| Horizontal push | wall push-up → incline push-up (counter → table → chair) → knee push-up → full push-up → feet-elevated push-up → deficit / 3-s eccentric push-up → archer push-up → one-arm progressions |
| Vertical push | pike push-up (hands on floor) → feet-elevated pike → wall-supported handstand hold → partial wall handstand push-up → full wall handstand push-up |
| Horizontal pull | towel/door-frame row or backpack bent-over row → high table/bar inverted row (body more upright) → lower bar → feet-elevated inverted row → archer row |
| Vertical pull (needs bar) | dead hang / scapular pull → band-assisted or jump-assisted pull-up → slow negatives (3–5 s) → full pull-up / chin-up → weighted (backpack) → archer |
| Knee-dominant | sit-to-stand from chair → bodyweight squat → tempo/pause squat → split squat → rear-foot-elevated split squat → assisted pistol / shrimp squat → full pistol |
| Hinge / posterior chain | glute bridge → single-leg glute bridge → shoulder-elevated hip thrust → single-leg hip thrust; single-leg RDL (backpack); sliding leg curl → Nordic curl negatives |
| Calves | two-leg calf raise → single-leg → single-leg on step (full ROM) |
| Core | dead bug / plank → side plank → hollow hold → hanging knee raise (bar) |

**Progression rule (bodyweight/bands):**
- When all sets reach the **top of the range** (for example 3 × 15–20) at RIR ≤2, move to the next rung and drop to the bottom of the range.
- Within a rung: add reps first, then a 3-s eccentric or a pause.
- Bands: progress reps, then the next band tension, then use a shorter band or a double band.
- **No-bar caveat:** without a pull-up bar, sturdy table, door anchor or bands, vertical pulling is not possible. Pulling volume then comes from rows and backpack rows. The equipment screen must ask about these items (§13.1).

---

## 6. Cardio and conditioning (Q5)

- **Dose — Tier 1:** **150–300 min/week moderate** or **75–150 min/week vigorous**, or an equivalent mix. "Some activity is better than none; more is better." Adults should also do muscle-strengthening on **≥2 days/week**. **Older adults:** varied multicomponent activity emphasising balance and strength on **≥3 days/week**. ([WHO 2020, PMID 33239350](https://pubmed.ncbi.nlm.nih.gov/33239350/), [US PAG 2018, PMID 30418471](https://pubmed.ncbi.nlm.nih.gov/30418471/)) [adults; older adults; includes guidance for chronic conditions and pregnancy]
- **HIIT vs moderate continuous training (MICT):**
  - Fat loss is similar when energy expenditure is matched — **Tier 1**. Bellicha 2021 overview of 12 meta-analyses ([PMID 33955140](https://pubmed.ncbi.nlm.nih.gov/33955140/)); Wewege 2017 found no difference in any body-composition measure ([PMID 28401638](https://pubmed.ncbi.nlm.nih.gov/28401638/)).
  - Viana 2019 found both reduce body-fat %, with interval training giving a 28.5% larger reduction in absolute fat mass ([PMID 30765340](https://pubmed.ncbi.nlm.nih.gov/30765340/)). Treat this as Tier 2: heterogeneous protocols, many sprint-interval studies, and energy expenditure not matched.
  - VO2max: HIIT adds a small extra gain over endurance training, about **1.2 mL/kg/min** ([Milanović 2015, PMID 26243014](https://pubmed.ncbi.nlm.nih.gov/26243014/)) — Tier 2. [ages 18–45]
  - Enjoyment of HIIT is similar to or slightly higher than MICT ([Oliveira 2018, PMID 29874256](https://pubmed.ncbi.nlm.nih.gov/29874256/)) — Tier 2.
  - HIIT dropout in sedentary adults is **17.6%**. Dropout is lower for cycling than running/walking, and longer sessions or more weekly time predicted more dropout ([Reljic 2019, PMID 31050061](https://pubmed.ncbi.nlm.nih.gov/31050061/)) — Tier 2.
- **Interference with lifting:**
  - On average, concurrent training does **not** reduce hypertrophy (SMD −0.01) or maximal strength (SMD −0.06). It does reduce **explosive** strength (SMD −0.28), more so when both are done in the same session. 43 studies ([Schumann 2022, PMID 34757594](https://pubmed.ncbi.nlm.nih.gov/34757594/)) — **Tier 1**.
  - **Trained** individuals lose some lower-body 1RM gain (ES −0.35); untrained and moderately trained do not ([Petré 2021, PMID 33751469](https://pubmed.ncbi.nlm.nih.gov/33751469/)) — Tier 2.
  - An older meta-analysis found interference rises with running (vs cycling), frequency and duration ([Wilson 2012, PMID 22002517](https://pubmed.ncbi.nlm.nih.gov/22002517/)). COI flag §12; used only as supporting evidence.

**Product consequence:**
- Every preset includes an aerobic prescription that works toward **150 min/week moderate**. Fat-loss and health presets go up to 300.
- Walking counts.
- HIIT is **optional, at most 1–2 sessions/week**, and only offered after 4 weeks of consistent training to users who pass the screen with no flags. Default HIIT modality is cycling or another low-impact option.
- For muscle and strength goals:
  - Put cardio on separate days, or **after** lifting with **≥3 h between them where possible**.
  - Prefer cycling for leg-day conditioning.
  - Cap at about 3 cardio sessions/week for trained strength users.
- Do not tell anyone that cardio "kills gains".

---

## 7. Fat loss (Q6)

- **Exercise alone produces modest weight loss:** **−1.5 to −3.5 kg**, fat **−1.3 to −2.6 kg**, and less visceral fat (SMD −0.33 to −0.56). Exercise had no proven effect on weight maintenance ([Bellicha 2021](https://pubmed.ncbi.nlm.nih.gov/33955140/)) — Tier 1. [overweight/obesity]
- **Diet dominates; combining is best long term.** Combined programmes lost **6.3 kg more** than exercise-only at 12–18 months. Combined vs diet-only was similar at 3–6 months and **1.7 kg better** at 12 months. Independently funded (MRC/NIHR). ([Johns 2014, PMID 25257365](https://pubmed.ncbi.nlm.nih.gov/25257365/)) — Tier 1.
- **People lose less weight from exercise than predicted** from energy expended, partly through compensation ([Thomas 2012, PMID 22681398](https://pubmed.ncbi.nlm.nih.gov/22681398/)) — Tier 2.
- **RT during a deficit preserves lean mass:**
  - About **+0.8 kg** lean mass vs no RT ([Bellicha 2021](https://pubmed.ncbi.nlm.nih.gov/33955140/)).
  - RT + caloric restriction cut fat mass by **−5.3 kg** and body fat by **−3.8%**, with lean mass maintained ([Lopez 2022, PMID 35191588](https://pubmed.ncbi.nlm.nih.gov/35191588/); 114 trials, n = 4,184, all ages).
  - RT works regardless of dose ([Lopez 2022b MSSE, PMID 35977113](https://pubmed.ncbi.nlm.nih.gov/35977113/)).
  - All Tier 1.
- **Deficit size:** energy deficits impair lean-mass gain but not strength gain. About **500 kcal/day** prevented lean-mass gain, and the authors advise avoiding deficits **>500 kcal/day** when preserving lean mass ([Murphy & Koehler 2022, PMID 34623696](https://pubmed.ncbi.nlm.nih.gov/34623696/)) — Tier 2.
- **Protein** (context only; GymFree is not a nutrition app). Above about **1.6 g/kg/day** total intake, no further lean-mass gain with RT ([Morton 2018, PMID 28698222](https://pubmed.ncbi.nlm.nih.gov/28698222/)). Tier 2, **COI-flagged** (§12): it concerns protein supplementation, and authors have dairy/supplement and commercial ties.
- **Steps and NEAT:**
  - More daily steps track with lower mortality up to **6,000–8,000 steps/day (≥60 y)** and **8,000–10,000 (<60 y)**. 15 cohorts, n = 47,471, CDC-funded ([Paluch 2022, PMID 35247352](https://pubmed.ncbi.nlm.nih.gov/35247352/)).
  - Each **+1,000 steps/day** is associated with **15% lower** all-cause mortality ([Banach 2023, PMID 37555441](https://pubmed.ncbi.nlm.nih.gov/37555441/)).
  - Both Tier 1 for association; observational data. Direct evidence that step targets cause fat loss is weaker (Tier 2/3).
- **Spot reduction does not happen:** pooled ES −0.03 across 37 comparisons ([Ramírez-Campillo 2021, Human Movement, doi:10.5114/hm.2022.110373](https://doi.org/10.5114/hm.2022.110373); see also [Ramírez-Campillo 2013 RCT, PMID 23222084](https://pubmed.ncbi.nlm.nih.gov/23222084/)) — Tier 1/2.

**Product consequence:** The fat-loss preset is **RT 2–3×/week (to keep muscle) + cardio up to 150–300 min/week + a daily step goal**. Copy must state honestly that weight change depends mostly on diet. The app does not prescribe diets, but it may show the evidence-based guardrail: "aim for a moderate deficit; very aggressive deficits cost muscle". No ab or "toning" circuits marketed as targeted fat loss.

**Step goal (engineering default on Tier 1 data):**
- Baseline = the user's current average. If HealthKit is available, use it as an optional, local-only read.
- Target = baseline + 1,000/day, raised every 1–2 weeks.
- Cap at 8,000 (age ≥60) or 10,000 (age <60).

---

## 8. Special populations and screening (Q7)

### 8.1 Pre-participation screening
- **ACSM 2015 algorithm — Tier 1 guideline** ([Riebe 2015, PMID 26473759](https://pubmed.ncbi.nlm.nih.gov/26473759/)). It replaced risk-factor counting with three inputs: (1) current activity level, (2) signs/symptoms or known cardiovascular, metabolic or renal disease, (3) desired intensity. The aim is fewer unnecessary physician referrals. Outcomes:
  - **Inactive + no disease + no symptoms** → no clearance needed. Start at light–moderate intensity and progress gradually.
  - **Inactive + known CV/metabolic/renal disease, no symptoms** → medical clearance recommended before starting.
  - **Any signs or symptoms** (chest pain or pressure, unusual breathlessness, dizziness or fainting, palpitations, ankle swelling, calf pain on walking) → stop and get medical clearance, whatever the activity level.
  - **Already active + known disease, no symptoms** → may continue at moderate intensity; clearance is advised before progressing to vigorous.
- **PAR-Q+** is the widely used self-screen. Answering "yes" to any initial question leads to follow-up questions or referral to a qualified professional/physician ([Bredin 2013, PMID 23486800](https://pubmed.ncbi.nlm.nih.gov/23486800/)). The PAR-Q+ has its own copyright, so **paraphrase** its items; do not copy them verbatim. Items cover:
  - heart condition or high blood pressure diagnosis
  - chest pain at rest, during daily activity or during exercise
  - dizziness or loss of consciousness in the last 12 months
  - another diagnosed chronic condition
  - prescribed medication for a chronic condition
  - a bone, joint or soft-tissue problem that activity could worsen
  - having been told to exercise only under medical supervision

**Product consequence:** Onboarding includes a short screen: the PAR-Q+-style items above, plus pregnancy/postpartum and current activity level.
- **Any "yes" to symptom questions** → show "Talk to a clinician before starting." Only a **light plan** may be generated: P01 or P11, RIR ≥3, no HIIT, no maximal efforts.
- **Known disease, no symptoms, currently inactive** → recommend clearance; allow light plans.
- **Pregnant or postpartum** → recommend clinician input. Point to the WHO recommendation of ≥150 min/week moderate activity plus muscle-strengthening, and do not auto-progress intensity.

Everyone gets a persistent in-workout notice listing stop-and-seek-care symptoms. Screening answers are stored only on the device.

### 8.2 Complete beginners and sedentary users
- Starting from zero gives the largest benefit; a simple program works (ACSM 2026). Affect **during** moderate exercise predicts future activity ([Rhodes & Kates 2015, PMID 25921307](https://pubmed.ncbi.nlm.nih.gov/25921307/)) — Tier 2.

**Product consequence:** Start with P01: 2 days/week, 1–2 sets, RIR 3–4, about 30 minutes, walking toward 150 min/week. Offer an upgrade after 4–6 weeks of ≥80% attendance.

### 8.3 Older adults (≥65, or anyone worried about balance/falls)
- **Falls — Tier 1, high certainty** ([Sherrington 2019, PMID 30703272](https://pubmed.ncbi.nlm.nih.gov/30703272/); 108 RCTs, n = 23,407, mean age 76, 77% women):
  - Exercise reduces the fall rate by **23%**.
  - Balance and functional exercise: **−24%**.
  - Multicomponent (balance + resistance): **−34%**, moderate certainty.
  - Tai Chi: **−19%**.
  - Programs that are mainly RT, dance or walking: uncertain effect on falls.
- **World Falls Guidelines 2022:** all older adults should get falls-prevention and physical-activity advice. High-risk people need a multifactorial assessment ([Montero-Odasso 2022, PMID 36178003](https://pubmed.ncbi.nlm.nih.gov/36178003/)). → Tell high-risk users to see a clinician.
- **Progressive RT in older adults:** large effect on strength (SMD 0.84; 73 trials), better physical function, serious adverse events rare. Typical dose was 2–3×/week at high intensity ([Liu & Latham 2009 Cochrane, PMID 19588334](https://pubmed.ncbi.nlm.nih.gov/19588334/)) — Tier 1.
- **Power training:** ACSM 2026 reports that RT improves gait speed, timed up-and-go and chair stands, and that **power RT** (moving fast against moderate loads) improves physical function. The NSCA older-adult position statement agrees ([Fragala 2019, PMID 31343601](https://pubmed.ncbi.nlm.nih.gov/31343601/)) — Tier 1/2.
- **Detraining** in older adults: little loss up to about 12–24 weeks off; clear loss by 31–52 weeks ([Grgic 2022](https://pubmed.ncbi.nlm.nih.gov/36360927/)).

**Product consequence:** P11 "Strong & Steady":
- 2–3 days/week of full-body strength, using machines, bands, bodyweight or chair support.
- **Balance and functional work on ≥3 days/week**: sit-to-stand, step-ups, tandem/single-leg stance with support, walking variations; Tai Chi-style option.
- After 8 weeks, add "lift fast, lower slow" intent on 1–2 exercises.
- Floor-based exercises have standing or chair alternatives.
- If the user reports a fall in the last 12 months, fear of falling, or unsteadiness → show "talk to a clinician about a falls assessment".

### 8.4 People with obesity / joint pain
- RT improves body composition at any dose ([Lopez 2022b](https://pubmed.ncbi.nlm.nih.gov/35977113/)).
- **Knee OA:** exercise reduces pain by about 12/100 points and improves function by about 10/100 points. Withdrawal rates (14%) were the same as control, and there were no serious adverse events ([Fransen 2015 Cochrane, PMID 25569281](https://pubmed.ncbi.nlm.nih.gov/25569281/)) — Tier 1.
- HIIT dropout is lower with cycling than running ([Reljic 2019](https://pubmed.ncbi.nlm.nih.gov/31050061/)).

**Product consequence:** A **"low-impact" modifier**, auto-on if the user selects joint pain or "prefer low impact" (do not infer it from BMI alone; just offer it):
- No jumping.
- No burpees or floor-to-stand transitions by default.
- Incline push-ups instead of floor push-ups.
- Box squat to a bench or chair.
- Supported or machine variants.
- Cardio: walking, cycling or water.

Joint pain that persists or gets worse leads to a clinician prompt.

### 8.5 Returning after a long break
- Evidence on retraining speed ("muscle memory") is not strong enough to set numbers — Tier 3. Detraining data are above.

**Product consequence (engineering default):**
- Off ≥3 months → start at **novice volume and RIR 3** for 2 weeks, at about 60–70% of the user's remembered working loads (or use rep-based self-selection), then progress by double progression. Prior training usually means faster progress.
- Off <3 months → resume the previous plan at about 80% of sets for 1 week.

---

## 9. Adherence (Q8)

- **What predicts sticking with exercise — Tier 2** (umbrella review of 55 reviews, chronic disease and older adults) ([Collado-Mateo 2021, PMID 33669679](https://pubmed.ncbi.nlm.nih.gov/33669679/)). Factors:
  - program characteristics
  - supervision
  - technology
  - initial assessment of barriers
  - education and realistic expectations
  - **enjoyment and absence of unpleasant experiences**
  - integration into daily life
  - social support
  - feedback
  - **progress monitoring**
  - self-efficacy
  - active participant role
  - goal setting
- **Autonomy:** more autonomous (self-chosen) motivation predicts exercise; intrinsic motivation predicts **long-term** adherence ([Teixeira 2012, PMID 22726453](https://pubmed.ncbi.nlm.nih.gov/22726453/)) — Tier 2.
- **Habit formation:** in new gym members, **≥4 sessions/week for 6 weeks** was the minimum to form a habit. Habit was predicted by consistency, **low complexity**, environment and enjoyment. Single cohort, n = 111 ([Kaushal & Rhodes 2015, PMID 25851609](https://pubmed.ncbi.nlm.nih.gov/25851609/)) — Tier 3 for the number, Tier 2 for the factors.
- **Affect:** feeling good **during** moderate exercise predicts future activity ([Rhodes & Kates 2015](https://pubmed.ncbi.nlm.nih.gov/25921307/)) — Tier 2.
- **Dropout and attendance:**
  - HIIT trials in sedentary people: 17.6% dropout. Longer sessions and more weekly time predicted dropout; intensity did not ([Reljic 2019](https://pubmed.ncbi.nlm.nih.gov/31050061/)).
  - Older adults: program completion 65–86%, session attendance 58–77%, higher when supervised ([Picorelli 2014, PMID 25092418](https://pubmed.ncbi.nlm.nih.gov/25092418/)).
  - Sustained vs intermittent aerobic programs: no consistent difference ([Linke 2011, PMID 21604068](https://pubmed.ncbi.nlm.nih.gov/21604068/)).
- **Lack of time** is among the most-reported barriers ([Iversen 2021](https://pubmed.ncbi.nlm.nih.gov/34125411/)).
- ACSM 2026: "The best program is the one you will actually do."

**Product consequence (defaults):**
- **2–3 RT days/week and 30–45 minutes** for anyone new.
- Gentle start: RIR 3–4 in weeks 1–2.
- **Exercise swaps always allowed** (autonomy).
- Few exercises per session (low complexity).
- The same days each week, for consistency.
- Visible progress logs.
- Plans can hit ≥4 weekly "sessions" by counting walks or cardio, without adding lifting days.
- Missed sessions should not trigger guilt messaging. Resume where the user left off.

---

## 10. Warm-ups and mobility (Q9)

- **Warming up helps:** performance improved in **79%** of criteria measured; there is little evidence of harm ([Fradkin 2010, PMID 19996770](https://pubmed.ncbi.nlm.nih.gov/19996770/)) — Tier 2.
- **Exercise-specific warm-ups are enough** for strength training ([Iversen 2021](https://pubmed.ncbi.nlm.nih.gov/34125411/)) — Tier 2.
- **Static stretching before lifting:**
  - **≥60 s per muscle** cuts performance by about **4.6%**; **<60 s** by about **1.1%**.
  - Dynamic stretching gives small improvements.
  - Static and PNF stretching have **no clear effect on injury**.
  - Source: [Behm 2016, PMID 26642915](https://pubmed.ncbi.nlm.nih.gov/26642915/); also [Kay & Blazevich 2012, PMID 21659901](https://pubmed.ncbi.nlm.nih.gov/21659901/). Tier 1/2.
- **Injury prevention:** stretching had no effect (RR 0.96). Strength training cut sports injuries to under a third (RR 0.32) ([Lauersen 2014, PMID 24100287](https://pubmed.ncbi.nlm.nih.gov/24100287/)) — Tier 1. [mostly athletes and military]
- **RT improves range of motion** (ES 0.73), similar to stretching. Separate stretching "may not be necessary" for flexibility ([Alizadeh 2023, PMID 36622555](https://pubmed.ncbi.nlm.nih.gov/36622555/)) — Tier 1.

**Product consequence:** Default warm-up, auto-inserted:
1. **3–5 min of easy general movement** (optional; brisk walk, bike, or the first exercise's movement unloaded).
2. **1–3 ramp-up sets** before the first compound of each movement pattern. Example ramp: about 50% × 8, 70% × 5, 85% × 2–3 of working load. Bodyweight users do an easier rung for 1 set.

No pre-lift static stretching by default. Short (<60 s/muscle) dynamic mobility is optional. Stretching appears only if the user picks a flexibility goal, and it is placed after lifting or on separate days.

---

## 11. Popular claims evaluated

| Claim | Verdict | Evidence |
|---|---|---|
| "Muscle confusion" — change exercises constantly | **Rejected.** Excessive random variation may hinder gains; systematic variation is fine | [Kassiano 2022](https://pubmed.ncbi.nlm.nih.gov/35438660/) |
| You must train to failure to grow | **Rejected** | [Grgic 2022](https://pubmed.ncbi.nlm.nih.gov/33497853/), [Refalo 2024](https://pubmed.ncbi.nlm.nih.gov/38393985/), [ACSM 2026](https://pubmed.ncbi.nlm.nih.gov/41843416/) |
| 8–12 reps is "the hypertrophy zone" | **Over-simplified.** About 6–30 reps work near failure | [Schoenfeld 2017b](https://pubmed.ncbi.nlm.nih.gov/28834797/), [Lopez 2021](https://pubmed.ncbi.nlm.nih.gov/33433148/) |
| Light weights / high reps "tone"; heavy weights "bulk" | **Rejected.** Hypertrophy is load-independent. "Definition" depends on body fat | as above, [Roberts 2020](https://pubmed.ncbi.nlm.nih.gov/32218059/) |
| Women need different programs / will get bulky | **Rejected.** Similar relative responses; ACSM recommends no sex-specific programming | [Roberts 2020](https://pubmed.ncbi.nlm.nih.gov/32218059/), [Hubal 2005](https://pubmed.ncbi.nlm.nih.gov/15947721/) |
| Spot reduction (crunches for belly fat) | **Rejected** (ES −0.03) | [Ramírez-Campillo 2021](https://doi.org/10.5114/hm.2022.110373) |
| "Fat-burning zone" / low-intensity cardio burns more fat | **Rejected for fat loss.** Total energy expenditure matters; HIIT ≈ MICT when energy-matched | [Bellicha 2021](https://pubmed.ncbi.nlm.nih.gov/33955140/), [Wewege 2017](https://pubmed.ncbi.nlm.nih.gov/28401638/) |
| HIIT "afterburn" (EPOC) burns lots of extra calories | **Rejected.** EPOC is only 6–15% of the exercise's net oxygen cost | [LaForgia 2006](https://pubmed.ncbi.nlm.nih.gov/17101527/) |
| Cardio "kills gains" | **Mostly rejected.** No effect on hypertrophy or max strength on average; minor effect on explosive strength and trained lower-body 1RM | [Schumann 2022](https://pubmed.ncbi.nlm.nih.gov/34757594/), [Petré 2021](https://pubmed.ncbi.nlm.nih.gov/33751469/) |
| Free weights are superior to machines | **Rejected** (gains are modality-specific; no difference overall) | [Haugen 2023](https://pubmed.ncbi.nlm.nih.gov/37582807/) |
| You need a gym to build muscle | **Rejected** | [ACSM 2026](https://pubmed.ncbi.nlm.nih.gov/41843416/), [Lopes 2019](https://pubmed.ncbi.nlm.nih.gov/30815258/) |
| Static stretching before lifting prevents injury | **Rejected** | [Lauersen 2014](https://pubmed.ncbi.nlm.nih.gov/24100287/), [Behm 2016](https://pubmed.ncbi.nlm.nih.gov/26642915/) |
| Exercise alone is an effective weight-loss strategy | **Rejected as a stand-alone.** About 1.5–3.5 kg; diet needed | [Bellicha 2021](https://pubmed.ncbi.nlm.nih.gov/33955140/), [Johns 2014](https://pubmed.ncbi.nlm.nih.gov/25257365/) |
| 10,000 steps is the magic number | **Not supported as a threshold.** Benefit plateaus at 6–8k (≥60 y) or 8–10k (<60 y) | [Paluch 2022](https://pubmed.ncbi.nlm.nih.gov/35247352/) |
| Deload every 4 weeks is required | **Unsupported (Tier 3).** One industry-funded RCT found a full week off slightly reduced strength | [Coleman 2024](https://pubmed.ncbi.nlm.nih.gov/38274324/) |
| More volume is always better (30–50+ sets/week) | **Unsupported.** Diminishing returns; little data above about 20 sets; per-session ceiling | [Pelland 2026](https://pubmed.ncbi.nlm.nih.gov/41343037/), [Remmert 2025](https://doi.org/10.51224/SRXIV.537) |
| You must periodize | **Optional** for general users; small 1RM edge only | [Moesgaard 2022](https://pubmed.ncbi.nlm.nih.gov/35044672/), [ACSM 2026](https://pubmed.ncbi.nlm.nih.gov/41843416/) |
| Beginners need a special "beginner program" | **Rejected by ACSM 2026.** Same principles, lower volume and effort | [ACSM summary](https://acsm.org/resistance-training-guidelines/) |
| Training each muscle once a week (bro split) is optimal | **Rejected as optimal.** Equivalent only at equal volume; conflicts with per-session ceiling and strength frequency | [Schoenfeld 2019](https://pubmed.ncbi.nlm.nih.gov/30558493/), [Pelland 2026](https://pubmed.ncbi.nlm.nih.gov/41343037/) |

---

## 12. Studies flagged or excluded for COI / quality

| Source | Issue | How it is used |
|---|---|---|
| [Coleman 2024](https://pubmed.ncbi.nlm.nih.gov/38274324/) (deload RCT) | **Funded by Renaissance Periodization LLC** (commercial coaching/app company); co-author Israetel is its co-founder | Tier 3 only; not used to build rules, only to argue against full-week-off deloads |
| [Plotkin 2022](https://pubmed.ncbi.nlm.nih.gov/36199287/) (load vs rep progression) | Co-author Israetel (RP). Funding was a university grant (PSC-CUNY) | Tier 2. The conclusion (both progression styles work) is low-stakes and consistent with load-independence meta-analyses |
| [Roberts, Nuckols, Krieger 2020](https://pubmed.ncbi.nlm.nih.gov/32218059/) | Nuckols (Stronger By Science) and Krieger (Weightology) run commercial fitness-education businesses | Tier 2; corroborated by the independent NIH-funded [Hubal 2005](https://pubmed.ncbi.nlm.nih.gov/15947721/) |
| [Krieger 2010](https://pubmed.ncbi.nlm.nih.gov/20300012/), [Schoenfeld 2017](https://pubmed.ncbi.nlm.nih.gov/27433992/), [Schoenfeld 2019](https://pubmed.ncbi.nlm.nih.gov/30558493/) | Krieger has a commercial business; Schoenfeld writes commercial trade books | Kept because conclusions are replicated by independent groups (ACSM 2026, Currier 2023 McMaster, Pelland 2026) |
| [Refalo 2023](https://pubmed.ncbi.nlm.nih.gov/36334240/), [Refalo 2024](https://pubmed.ncbi.nlm.nih.gov/38393985/) | Co-author Helms runs a coaching business (3DMJ) | Tier 1/2 only together with Grgic 2022 and ACSM 2026 |
| [Currier 2023](https://pubmed.ncbi.nlm.nih.gov/37414459/) and [ACSM 2026](https://pubmed.ncbi.nlm.nih.gov/41843416/) | Senior author Phillips reports research funding from dairy, food and supplement companies (US National Dairy Council, Nestlé Health Science, Roquette, Myos) and patents licensed to Exerkine (per Currier 2023 COI). ACSM 2026 COIs are in its Supplementary Appendix 8 (not retrieved) | Kept: RT-prescription conclusions involve no products, and the methods are a preregistered NMA / an overview of 137 reviews. Flagged for transparency |
| [Morton 2018](https://pubmed.ncbi.nlm.nih.gov/28698222/) (protein) | Topic is supplementation; authors include Phillips plus Aragon, Helms, Henselmans (commercial) | Context only (Tier 2, flagged); no app logic depends on it |
| [Wilson 2012](https://pubmed.ncbi.nlm.nih.gov/22002517/) (interference) | First author later founded a contract research institute running supplement-industry studies | Supporting only; core interference rules rest on [Schumann 2022](https://pubmed.ncbi.nlm.nih.gov/34757594/) (university-funded) |
| [Remmert 2025](https://doi.org/10.51224/SRXIV.537) | Preprint, not peer reviewed; no COI statement visible | Tier 2; used for the per-session cap only |
| [Iversen 2021](https://pubmed.ncbi.nlm.nih.gov/34125411/) | Narrative review (weaker design) | Tier 2; used for minimum-dose and time-saving tactics, consistent with Momma 2022 and Androulakis 2020 |
| Fitness-industry claims (influencer "programs", brand HIIT/fat-burning claims, coaching sites) | Not evidence | Not cited; addressed only in §11 |

---

## 13. Inputs the plan algorithm should ask for

### 13.1 Questions (onboarding, all stored on device)
1. **Safety screen** (§8.1): PAR-Q+-style items (paraphrased); pregnancy/postpartum; "Do you ever get chest pain, faintness or unusual breathlessness when active?"; known heart, metabolic or kidney disease.
2. **Main goal** (one): *Get healthier / start moving* · *Build muscle* · *Get stronger* · *Lose fat* · *Stay strong & steady (balance)*.
3. **Experience** (ACSM 2009 definitions):
   - *Never / not in years* → novice
   - *Up to ~6 months consistent* → novice
   - *6–24 months consistent* → intermediate
   - *2+ years consistent* → advanced
4. **Time off:** "Are you training now? If not, how long since you trained regularly?" (none / <3 months / ≥3 months).
5. **Days per week** for RT (2–6) and **which days**.
6. **Minutes per session** (20 / 30 / 45 / 60 / 75+).
7. **Equipment** (multi-select): full gym · adjustable dumbbells or a DB set (max weight) · bench · resistance bands (+ door anchor?) · pull-up bar · sturdy table/low bar for rows · none.
8. **Age band** (<40 / 40–59 / 60–74 / 75+) and "Have you fallen in the last year, or do you feel unsteady?"
9. **Joints:** pain or limitation in knee / hip / back / shoulder; "prefer low-impact"; "can you get down to and up from the floor comfortably?"
10. **Current activity:** typical daily steps (or HealthKit opt-in) and minutes of cardio per week.
11. **Cardio preference:** walk · cycle · run · swim/water · rower · none.
12. Optional: exercises to avoid or favourite exercises. Sex is **not** asked for programming.

### 13.2 Deterministic decision steps
```
1. SAFETY
   if symptomFlag            -> plan = P01-light or P11-light (RIR>=4, no HIIT); show "see a clinician before starting"
   elif knownDisease && inactive -> recommend clearance; allow P01/P11 only until user confirms clearance
   if pregnant/postpartum    -> recommend clinician; no auto-intensity progression; no HIIT
   if fallLastYear || unsteady -> add balance block; recommend falls assessment

2. LEVEL
   level = novice | intermediate | advanced  (from Q3)
   if timeOff >= 3 months -> level = max(novice, level-1) for weeks 1-2 ("return" mode, §8.5)

3. TEMPLATE (by goal override, then days)
   goal == balance OR age >= 65 && level == novice -> P11
   goal == health && level == novice               -> P01 (2d) / P02-P05 (3d)
   RT days for novices capped at 4 (extra days -> cardio/walk)
   split by days: 2=FB A/B, 3=FB A/B alt, 4=Upper/Lower, 5=U/L/Push/Pull/Legs, 6=PPLx2

4. EQUIPMENT VARIANT
   pick exercise per slot from substitution table (§5.4, §13.3) using the richest available equipment;
   no vertical-pull equipment -> replace vertical pull with a 2nd row variant
   lowImpact -> apply low-impact substitutions (§8.4)

5. WEEKLY VOLUME TARGET (fractional sets/muscle/week; direct=1, indirect=0.5)
   health/minimal: 4-6 | novice muscle/fat-loss: 8-10 | intermediate: 12-16 | advanced: 14-20
   strength goal: main lifts 2-3 sets x 2-3 exposures/wk (~6-10 sets/muscle) + accessories to reach >=8
   hard caps: <=20/wk, <=10 per muscle per session

6. FIT TO TIME
   setsPerSession ≈ floor((minutes - 6) / minutesPerSet)
       minutesPerSet = 2.5 (hypertrophy/general, 90 s rest) | 3.5 (strength main lifts) | 1.6 with antagonist supersets
   if weekly target doesn't fit: enable supersets -> drop isolation -> reduce target, floor = 4/muscle/wk
   max ~8 exercises/session (complexity)

7. REPS / RIR / REST per goal & level (table §14)
   weeks 1-2 for novices/returners: RIR +1 (i.e. 3-4)

8. PROGRESSION: double progression (§3.1); strength preset main lifts: load progression (§14 P08)
9. DELOAD: reactive rules (§3.3); scheduled every 8 wk only if weekly volume >= 15
10. CARDIO: §6/§7 prescription by goal; steps target = baseline +1000, step every 1-2 wk, cap 8k/10k
11. REVIEW at 6-8 weeks: if attendance >= 80% and progress, offer next preset (P01->P02-P05, P02->P06/P08)
```

### 13.3 Slot → exercise substitution (excerpt; engineers extend from the exercise library)

| Slot | Full gym | Dumbbells | Bands | Bodyweight |
|---|---|---|---|---|
| Knee-dominant | back squat / leg press / hack squat | goblet squat / DB split squat | band squat / band split squat | squat ladder (§5.4) |
| Hinge | RDL / trap-bar deadlift / hip thrust | DB RDL / DB hip thrust | band RDL / band pull-through | bridge → hip thrust → single-leg RDL |
| Hamstring (knee flexion) | leg curl | DB leg curl (advanced) / sliding curl | band leg curl | sliding leg curl → Nordic negatives |
| Horizontal push | bench / machine press | DB bench / floor press | band chest press | push-up ladder |
| Vertical push | OHP / machine press | DB shoulder press | band overhead press | pike ladder |
| Horizontal pull | cable / chest-supported row | one-arm DB row | band row | inverted-row ladder / backpack row |
| Vertical pull | pull-up / lat pulldown | (none → 2nd row) | band lat pulldown (high anchor) | pull-up ladder (bar) / else 2nd row |
| Arms | cable/DB curls, pushdowns | DB curl, overhead extension | band curl, band pushdown | chin-up (bar), close-grip/diamond push-up, bench dip |
| Lateral delt | cable/DB lateral raise | DB lateral raise | band lateral raise | (limited; covered indirectly by pike/push) |
| Calves | calf machine | DB single-leg calf raise | band calf raise | single-leg calf raise on step |
| Core | cable crunch, hanging raise | DB carry, dead bug | band Pallof press | plank ladder, dead bug |

Muscle mapping for the fractional-set counter (engineering convention):

| Exercise type | Direct (1) | Indirect (0.5) |
|---|---|---|
| Squat / leg press | quads | glutes |
| Hinge | hamstrings, glutes | lower back |
| Horizontal push | chest | triceps, front delts |
| Vertical push | front/side delts | triceps |
| Rows / pulls | lats/upper back | biceps, rear delts |
| Isolation | target muscle | — |

---

## 14. Recommended preset matrix

All presets share these defaults:
- Warm-up per §10.
- Double progression per §3.1.
- Reactive deload per §3.3.
- 1–3 RIR unless stated.
- Each muscle ≥2×/week.
- Exercises fixed for the block (6–8 weeks).
- Swaps always allowed.

Volumes are **fractional sets per major muscle per week** (chest, back, quads, hamstrings/glutes, delts). Arms and calves are reached through indirect work plus 0–2 isolation sets per session.

| ID | Name | Goal / level | Days & split | Equipment | Sets/muscle/wk | Reps | RIR | Rest | Session | Progression | Deload | Cardio | Evidence |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **P01** | First Steps | Health, sedentary, returners, cleared-but-cautious | 2 · Full body A/B | any (variant per equipment) | 4–6 (2 sets × 5–6 exercises) | 10–15 | 3–4 wk 1–2 → 2–3 | 60–90 s | 25–35 min | Double progression; offer upgrade after 4–6 wk ≥80% attendance | none scheduled | Walk: steps baseline +1000/d every 1–2 wk; build to 150 min/wk moderate | ACSM 2026; WHO 2020; Momma 2022; Iversen 2021; Rhodes 2015 |
| **P02** | Full Body 3× — Gym | Muscle + strength, novice | 3 · FB A/B alt | full gym | 9–12 | compounds 6–10; accessories 10–15 | 2–3 → 1–2 after wk 4; last isolation set 0–1 | 90–120 s / 60–90 s | 45–60 min | Double progression; barbell +2.5 kg upper / +5 kg lower | reactive | 150 min/wk moderate (walk/cycle), separate or after lifting | Schoenfeld 2017; ACSM 2026; Currier 2023 (3×/wk); Ramos-Campo 2024 |
| **P03** | Full Body 3× — Dumbbells | Muscle + strength, novice | 3 · FB A/B alt | dumbbells (+bench optional) | 9–12 | 8–15 (wider for big DB jumps) | as P02 | 60–90 s | 40–55 min | Reps first, then next DB | reactive | as P02 | Haugen 2023; Plotkin 2022; Lopez 2021 |
| **P04** | Full Body 3× — Bodyweight | Muscle/general, novice–intermediate, no equipment | 3 · FB A/B alt | none (+table/bar optional) | 9–12 | 8–20 (to 30 on easy rungs) | 0–2 (1–2 on single-leg balance work) | 60–90 s | 35–45 min | Variation ladder (§5.4) | reactive | as P02 | Kikuchi 2017; Kotarsky 2018; Schoenfeld 2017b; ACSM 2026 |
| **P05** | Full Body 3× — Bands | Muscle/general, novice–intermediate | 3 · FB A/B alt | bands (+door anchor) | 9–12 | 10–20 | 0–2 | 60–90 s | 35–45 min | Reps → band tension → doubled band | reactive | as P02 | Lopes 2019; ACSM 2026 |
| **P06** | Upper/Lower 4× — Gym | Muscle, intermediate | 4 · U/L ×2 | full gym | 12–16 (≤8 per session) | compounds 6–10 (one 4–6 slot optional); isolation 10–20 | 1–2; isolation last set 0–1 | 2 min compounds / 60–90 s | 60–75 min | Double progression | reactive; scheduled every 8 wk if ≥15 sets | 2–3 × 20–30 min moderate, cycling preferred; ≥3 h from lower sessions where possible | Pelland 2026; Baz-Valle 2022; Remmert 2025; Schumann 2022 |
| **P07** | Upper/Lower 4× — Home | Muscle, intermediate | 4 · U/L ×2 | DB + bands + bodyweight mix | 12–16 | 8–20 | 0–2 | 60–90 s | 45–60 min | Double progression / ladders | as P06 | as P06 | as P04–P06 |
| **P08** | Strength Base 3× | Strength, novice–intermediate | 3 · FB; weekly undulation H/M/L (Heavy 3–5, Medium 5–8, Light 8–10 reps) | full gym (barbell) | Main lifts: squat 3×/wk, bench 3×/wk, hinge 1–2×, press 1–2×, row/pull-up 2–3×; 2–4 sets each (~8–10/muscle incl. accessories) | main 3–6 (H day 3–5 ≈ 85% 1RM); accessories 6–12 | main 1–3; never 0 | 2–4 min main / 90 s | 60–75 min | Main lifts: if all sets hit target reps at RIR ≥1 → +2.5 kg upper / +5 kg lower (micro 1–2.5% when stalling); 2 missed sessions → −10% and rebuild | reactive | ≤3 sessions/wk low-impact, separated from lifting by ≥3 h or after lifting | ACSM 2026 (≥80% 1RM, 2–3 sets); Currier 2023; Pelland 2026 (frequency); Moesgaard 2022; Petré 2021 |
| **P09** | PPL 5–6× | Muscle, advanced (≥2 yr) | 6 · PPL ×2 (5-day: U/L/P/P/L) | full gym | 14–20 (≤10 per session) | 6–20 | 0–2 | ≥90 s / 2 min compounds | 60–75 min | Double progression | scheduled every 6–8 wk (Tier 3) + reactive | 2 × 20–30 min easy cycling/walking | Pelland 2026; Schoenfeld 2017; Remmert 2025 |
| **P10** | Fat Loss & Fitness | Fat loss / health, any level | 3 · FB A/B alt (equipment variant from P02–P05), antagonist supersets | any | 8–12 | 8–15 | 1–3 | 60 s within supersets | 35–45 min | Double progression | reactive | 150 → 300 min/wk moderate (walk/cycle/swim); optional 1 × HIIT/wk (cycling, e.g. 6–10 × 30–60 s hard / 60–90 s easy) from wk 5 if screen clean; steps +1000/d every 1–2 wk to 8–10k | Bellicha 2021; Johns 2014; Lopez 2022; Wewege 2017; Paluch 2022; Murphy & Koehler 2022 |
| **P11** | Strong & Steady | Older adults (≥65), balance/falls concern, very deconditioned | 2–3 strength (FB) + balance/functional ≥3 d/wk (10–15 min blocks; can be the same days plus 1 more) | machines / bands / bodyweight / chair | 4–8 | 8–15 | 3–4 → 2–3 | 60–120 s | 30–45 min | Double progression; from wk 8 add "lift fast, lower slow" on 1–2 exercises | none scheduled; reactive | Walk toward 150 min/wk; Tai Chi-style option | Sherrington 2019; WHO 2020; Montero-Odasso 2022; Liu & Latham 2009; Fragala 2019; ACSM 2026 |
| **P12** | Minimal Dose 2×30 | Busy people (any level), maintenance | 2 · FB, 4–5 exercises in antagonist supersets | any | 4–6 | 6–15 | trained 0–2 / untrained 1–3 | 60 s within supersets | 25–30 min | Double progression | none | Walk / steps goal; 150 min/wk if possible | Androulakis 2020; Iversen 2021; Momma 2022; Remmert 2025 |

### 14.1 Example session skeletons (slot order)
- **FB-A (P02–P05, P10):**
  1. knee-dominant
  2. horizontal push
  3. horizontal pull
  4. hinge (light)
  5. lateral delt or arms
  6. core
- **FB-B:**
  1. hinge
  2. vertical push
  3. vertical pull (or 2nd row)
  4. single-leg
  5. arms
  6. calves
- **Upper (P06/P07):**
  - horizontal push ×3 sets
  - horizontal pull ×3
  - vertical push ×2–3
  - vertical pull ×3
  - lateral delt ×2–3
  - biceps ×2
  - triceps ×2
- **Lower:**
  - knee-dominant ×3
  - hinge ×3
  - single-leg ×2–3
  - leg curl ×2–3
  - calves ×3
  - core ×2
- **P11 (strength + balance):**
  1. sit-to-stand / leg press
  2. supported row
  3. incline push-up / chest press
  4. step-up
  5. bridge
  6. balance block: tandem stance → single-leg stance with support → walking heel-to-toe → stepping drills, 10–15 min total

### 14.2 What is evidence vs engineering default in the matrix
- **Evidence-based (Tier 1/2):**
  - ≥2×/week per muscle
  - weekly set ranges
  - rep ranges by goal
  - RIR 1–3 / failure optional
  - rest ranges
  - split equivalence
  - equipment equivalence
  - aerobic minutes
  - cardio sequencing
  - balance ≥3 d/week for older adults
  - no pre-lift static stretching
- **Engineering defaults (Tier 3; tune with user data):**
  - exact load increments
  - stall and deload triggers
  - return-from-break percentages
  - minutes-per-set constants
  - HIIT session format
  - calisthenics ladder order
  - the 4–6 week upgrade prompt

---

## 15. Reference list (all links verified 2026-10-05)

Guidelines / position stands
- Currier BS, …, Phillips SM. ACSM Position Stand: Resistance training prescription for muscle function, hypertrophy, and physical performance in healthy adults: an overview of reviews. *Med Sci Sports Exerc* 2026. doi:10.1249/MSS.0000000000003897. [PubMed 41843416](https://pubmed.ncbi.nlm.nih.gov/41843416/) · [PMC12965823](https://pmc.ncbi.nlm.nih.gov/articles/PMC12965823/) · [ACSM summary](https://acsm.org/resistance-training-guidelines/)
- ACSM. Progression models in resistance training for healthy adults. *Med Sci Sports Exerc* 2009. [PubMed 19204579](https://pubmed.ncbi.nlm.nih.gov/19204579/)
- Bull FC et al. WHO 2020 guidelines on physical activity and sedentary behaviour. *Br J Sports Med* 2020. [PubMed 33239350](https://pubmed.ncbi.nlm.nih.gov/33239350/)
- Piercy KL et al. The Physical Activity Guidelines for Americans. *JAMA* 2018. [PubMed 30418471](https://pubmed.ncbi.nlm.nih.gov/30418471/)
- Riebe D et al. Updating ACSM's recommendations for exercise preparticipation health screening. *Med Sci Sports Exerc* 2015. [PubMed 26473759](https://pubmed.ncbi.nlm.nih.gov/26473759/)
- Bredin SS et al. PAR-Q+ and ePARmed-X+. *Can Fam Physician* 2013. [PubMed 23486800](https://pubmed.ncbi.nlm.nih.gov/23486800/)
- Montero-Odasso M et al. World guidelines for falls prevention and management for older adults. *Age Ageing* 2022. [PubMed 36178003](https://pubmed.ncbi.nlm.nih.gov/36178003/)
- Fragala MS et al. Resistance training for older adults: NSCA position statement. *J Strength Cond Res* 2019. [PubMed 31343601](https://pubmed.ncbi.nlm.nih.gov/31343601/)
- Donnelly JE et al. ACSM position stand: physical activity for weight loss and prevention of regain. *Med Sci Sports Exerc* 2009. [PubMed 19127177](https://pubmed.ncbi.nlm.nih.gov/19127177/) (background)

Dose, load, effort, rest
- Pelland JC et al. The resistance training dose response: meta-regressions … weekly volume and frequency. *Sports Med* 2026. doi:10.1007/s40279-025-02344-w. [PubMed 41343037](https://pubmed.ncbi.nlm.nih.gov/41343037/) · [preprint](https://doi.org/10.51224/SRXIV.460)
- Remmert JF et al. Is there too much of a good thing? Meta-regressions of per-session volume. *SportRxiv preprint* 2025. [doi:10.51224/SRXIV.537](https://doi.org/10.51224/SRXIV.537)
- Schoenfeld BJ, Ogborn D, Krieger JW. Dose-response … weekly RT volume and muscle mass. *J Sports Sci* 2017. [PubMed 27433992](https://pubmed.ncbi.nlm.nih.gov/27433992/)
- Baz-Valle E et al. Effects of different RT volumes on hypertrophy. *J Hum Kinet* 2022. [PubMed 35291645](https://pubmed.ncbi.nlm.nih.gov/35291645/)
- Krieger JW. Single vs multiple sets for hypertrophy. *J Strength Cond Res* 2010. [PubMed 20300012](https://pubmed.ncbi.nlm.nih.gov/20300012/)
- Currier BS et al. RT prescription for strength and hypertrophy: Bayesian network meta-analysis. *Br J Sports Med* 2023. [PubMed 37414459](https://pubmed.ncbi.nlm.nih.gov/37414459/) · [PMC10579494](https://pmc.ncbi.nlm.nih.gov/articles/PMC10579494/)
- Schoenfeld BJ, Grgic J, Krieger J. RT frequency and hypertrophy. *J Sports Sci* 2019. [PubMed 30558493](https://pubmed.ncbi.nlm.nih.gov/30558493/)
- Grgic J et al. RT frequency and strength. *Sports Med* 2018. [PubMed 29470825](https://pubmed.ncbi.nlm.nih.gov/29470825/)
- Schoenfeld BJ et al. Low- vs high-load RT. *J Strength Cond Res* 2017. [PubMed 28834797](https://pubmed.ncbi.nlm.nih.gov/28834797/)
- Lopez P et al. RT load effects: network meta-analysis. *Med Sci Sports Exerc* 2021. [PubMed 33433148](https://pubmed.ncbi.nlm.nih.gov/33433148/)
- Grgic J et al. Failure vs non-failure. *J Sport Health Sci* 2022. [PubMed 33497853](https://pubmed.ncbi.nlm.nih.gov/33497853/)
- Refalo MC et al. Proximity-to-failure and hypertrophy: meta-analysis. *Sports Med* 2023. [PubMed 36334240](https://pubmed.ncbi.nlm.nih.gov/36334240/)
- Refalo MC et al. Failure vs RIR RCT in trained individuals. *J Sports Sci* 2024. [PubMed 38393985](https://pubmed.ncbi.nlm.nih.gov/38393985/)
- Robinson ZP et al. Proximity to failure dose-response meta-regressions. *Sports Med* 2024. [PubMed 38970765](https://pubmed.ncbi.nlm.nih.gov/38970765/)
- Halperin I et al. Accuracy in predicting repetitions to failure. *Sports Med* 2022. [PubMed 34542869](https://pubmed.ncbi.nlm.nih.gov/34542869/)
- Singer A et al. Inter-set rest and hypertrophy: Bayesian meta-analysis. *Front Sports Act Living* 2024. [PubMed 39205815](https://pubmed.ncbi.nlm.nih.gov/39205815/)
- Grgic J et al. Rest interval and strength: systematic review. *Sports Med* 2018. [PubMed 28933024](https://pubmed.ncbi.nlm.nih.gov/28933024/)
- Schoenfeld BJ et al. Longer interset rest in trained men (RCT). *J Strength Cond Res* 2016. [PubMed 26605807](https://pubmed.ncbi.nlm.nih.gov/26605807/)
- Iversen VM et al. No time to lift? *Sports Med* 2021. [PubMed 34125411](https://pubmed.ncbi.nlm.nih.gov/34125411/)
- Androulakis-Korakakis P et al. Minimum effective dose for 1RM in trained men. *Sports Med* 2020. [PubMed 31797219](https://pubmed.ncbi.nlm.nih.gov/31797219/)
- Momma H et al. Muscle-strengthening activities and NCD/mortality. *Br J Sports Med* 2022. [PubMed 35228201](https://pubmed.ncbi.nlm.nih.gov/35228201/)
- Benito PJ et al. RT and whole-body muscle growth in men. *IJERPH* 2020. [PubMed 32079265](https://pubmed.ncbi.nlm.nih.gov/32079265/)

Progression, variation, periodization, deload, sex
- Plotkin D et al. Load vs repetition progression (RCT). *PeerJ* 2022. [PubMed 36199287](https://pubmed.ncbi.nlm.nih.gov/36199287/)
- Moesgaard L et al. Periodization, volume-equated: meta-analysis. *Sports Med* 2022. [PubMed 35044672](https://pubmed.ncbi.nlm.nih.gov/35044672/)
- Kassiano W et al. Exercise variation: systematic review. *J Strength Cond Res* 2022. [PubMed 35438660](https://pubmed.ncbi.nlm.nih.gov/35438660/)
- Coleman M et al. One-week deload (RCT; RP-funded). *PeerJ* 2024. [PubMed 38274324](https://pubmed.ncbi.nlm.nih.gov/38274324/)
- Grgic J. Detraining and muscle size in older adults. *IJERPH* 2022. [PubMed 36360927](https://pubmed.ncbi.nlm.nih.gov/36360927/)
- Roberts BM, Nuckols G, Krieger JW. Sex differences in RT. *J Strength Cond Res* 2020. [PubMed 32218059](https://pubmed.ncbi.nlm.nih.gov/32218059/)
- Hubal MJ et al. Variability in size and strength gain (n = 585). *Med Sci Sports Exerc* 2005. [PubMed 15947721](https://pubmed.ncbi.nlm.nih.gov/15947721/)
- Pallarés JG et al. Range of motion and RT adaptations. *Scand J Med Sci Sports* 2021. [PubMed 34170576](https://pubmed.ncbi.nlm.nih.gov/34170576/)

Splits and equipment
- Ramos-Campo DJ et al. Split vs full-body: meta-analysis. *J Strength Cond Res* 2024. [PubMed 38595233](https://pubmed.ncbi.nlm.nih.gov/38595233/)
- Haugen ME et al. Free-weight vs machine: meta-analysis. *BMC Sports Sci Med Rehabil* 2023. [PubMed 37582807](https://pubmed.ncbi.nlm.nih.gov/37582807/)
- Lopes JSS et al. Elastic vs conventional resistance: meta-analysis. *SAGE Open Med* 2019. [PubMed 30815258](https://pubmed.ncbi.nlm.nih.gov/30815258/)
- Kikuchi N, Nakazato K. Push-up vs bench press (RCT). *J Exerc Sci Fit* 2017. [PubMed 29541130](https://pubmed.ncbi.nlm.nih.gov/29541130/)
- Calatayud J et al. Bench press vs push-up at matched EMG (RCT). *J Strength Cond Res* 2015. [PubMed 24983847](https://pubmed.ncbi.nlm.nih.gov/24983847/)
- Kotarsky CJ et al. Progressive calisthenic push-up training (RCT). *J Strength Cond Res* 2018. [PubMed 29466268](https://pubmed.ncbi.nlm.nih.gov/29466268/)

Cardio, interference, fat loss
- Schumann M et al. Concurrent training compatibility: meta-analysis. *Sports Med* 2022. [PubMed 34757594](https://pubmed.ncbi.nlm.nih.gov/34757594/)
- Petré H et al. Concurrent training by training status: meta-analysis. *Sports Med* 2021. [PubMed 33751469](https://pubmed.ncbi.nlm.nih.gov/33751469/)
- Wilson JM et al. Concurrent training interference: meta-analysis. *J Strength Cond Res* 2012. [PubMed 22002517](https://pubmed.ncbi.nlm.nih.gov/22002517/)
- Wewege M et al. HIIT vs MICT body composition. *Obes Rev* 2017. [PubMed 28401638](https://pubmed.ncbi.nlm.nih.gov/28401638/)
- Viana RB et al. Interval training vs MICT for fat loss. *Br J Sports Med* 2019. [PubMed 30765340](https://pubmed.ncbi.nlm.nih.gov/30765340/)
- Milanović Z et al. HIT vs endurance training for VO2max. *Sports Med* 2015. [PubMed 26243014](https://pubmed.ncbi.nlm.nih.gov/26243014/)
- Oliveira BRR et al. Affect/enjoyment HIIT vs MICT. *PLoS One* 2018. [PubMed 29874256](https://pubmed.ncbi.nlm.nih.gov/29874256/)
- Reljic D et al. HIIT dropout in sedentary adults. *Scand J Med Sci Sports* 2019. [PubMed 31050061](https://pubmed.ncbi.nlm.nih.gov/31050061/)
- LaForgia J et al. EPOC review. *J Sports Sci* 2006. [PubMed 17101527](https://pubmed.ncbi.nlm.nih.gov/17101527/)
- Bellicha A et al. Exercise and weight loss: overview of 12 SR-MAs. *Obes Rev* 2021. [PubMed 33955140](https://pubmed.ncbi.nlm.nih.gov/33955140/)
- Johns DJ et al. Diet or exercise vs combined programs. *J Acad Nutr Diet* 2014. [PubMed 25257365](https://pubmed.ncbi.nlm.nih.gov/25257365/)
- Thomas DM et al. Why individuals don't lose more weight from exercise. *Obes Rev* 2012. [PubMed 22681398](https://pubmed.ncbi.nlm.nih.gov/22681398/)
- Lopez P et al. RT and body composition in overweight/obesity. *Obes Rev* 2022. [PubMed 35191588](https://pubmed.ncbi.nlm.nih.gov/35191588/)
- Lopez P et al. Moderators of RT effects in overweight/obese adults. *Med Sci Sports Exerc* 2022. [PubMed 35977113](https://pubmed.ncbi.nlm.nih.gov/35977113/)
- Murphy C, Koehler K. Energy deficiency and RT gains. *Scand J Med Sci Sports* 2022. [PubMed 34623696](https://pubmed.ncbi.nlm.nih.gov/34623696/)
- Cava E et al. Preserving healthy muscle during weight loss. *Adv Nutr* 2017. [PubMed 28507015](https://pubmed.ncbi.nlm.nih.gov/28507015/) (narrative background)
- Morton RW et al. Protein supplementation and RT (flagged). *Br J Sports Med* 2018. [PubMed 28698222](https://pubmed.ncbi.nlm.nih.gov/28698222/)
- Paluch AE et al. Daily steps and mortality. *Lancet Public Health* 2022. [PubMed 35247352](https://pubmed.ncbi.nlm.nih.gov/35247352/)
- Banach M et al. Step count and mortality. *Eur J Prev Cardiol* 2023. [PubMed 37555441](https://pubmed.ncbi.nlm.nih.gov/37555441/)
- Ramírez-Campillo R et al. Spot reduction model + meta-analysis. *Human Movement* 2021/22. [doi:10.5114/hm.2022.110373](https://doi.org/10.5114/hm.2022.110373)
- Ramírez-Campillo R et al. Regional fat changes after localized training (RCT). *J Strength Cond Res* 2013. [PubMed 23222084](https://pubmed.ncbi.nlm.nih.gov/23222084/)

Special populations
- Sherrington C et al. Exercise for preventing falls (Cochrane). 2019. [PubMed 30703272](https://pubmed.ncbi.nlm.nih.gov/30703272/)
- Liu CJ, Latham NK. Progressive RT in older adults (Cochrane). 2009. [PubMed 19588334](https://pubmed.ncbi.nlm.nih.gov/19588334/)
- Fransen M et al. Exercise for knee osteoarthritis (Cochrane). 2015. [PubMed 25569281](https://pubmed.ncbi.nlm.nih.gov/25569281/)

Adherence
- Collado-Mateo D et al. Key factors for exercise adherence: umbrella review. *IJERPH* 2021. [PubMed 33669679](https://pubmed.ncbi.nlm.nih.gov/33669679/)
- Teixeira PJ et al. Exercise and self-determination theory. *IJBNPA* 2012. [PubMed 22726453](https://pubmed.ncbi.nlm.nih.gov/22726453/)
- Kaushal N, Rhodes RE. Exercise habit formation in new gym members. *J Behav Med* 2015. [PubMed 25851609](https://pubmed.ncbi.nlm.nih.gov/25851609/)
- Rhodes RE, Kates A. Affective response and future activity. *Ann Behav Med* 2015. [PubMed 25921307](https://pubmed.ncbi.nlm.nih.gov/25921307/)
- Picorelli AM et al. Adherence in older adults' exercise programs. *J Physiother* 2014. [PubMed 25092418](https://pubmed.ncbi.nlm.nih.gov/25092418/)
- Linke SE et al. Attrition: sustained vs intermittent exercise. *Ann Behav Med* 2011. [PubMed 21604068](https://pubmed.ncbi.nlm.nih.gov/21604068/)

Warm-up, stretching, mobility
- Fradkin AJ et al. Warm-up and performance: meta-analysis. *J Strength Cond Res* 2010. [PubMed 19996770](https://pubmed.ncbi.nlm.nih.gov/19996770/)
- Behm DG et al. Acute effects of stretching. *Appl Physiol Nutr Metab* 2016. [PubMed 26642915](https://pubmed.ncbi.nlm.nih.gov/26642915/)
- Kay AD, Blazevich AJ. Acute static stretch and performance. *Med Sci Sports Exerc* 2012. [PubMed 21659901](https://pubmed.ncbi.nlm.nih.gov/21659901/)
- Lauersen JB et al. Exercise interventions to prevent sports injuries. *Br J Sports Med* 2014. [PubMed 24100287](https://pubmed.ncbi.nlm.nih.gov/24100287/)
- Alizadeh S et al. RT improves range of motion. *Sports Med* 2023. [PubMed 36622555](https://pubmed.ncbi.nlm.nih.gov/36622555/)
