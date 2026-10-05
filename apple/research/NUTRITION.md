# GymFree — Nutrition Evidence Base (calorie targets, macros, weight-change goals, food logging)

Status: source of truth for the optional nutrition feature. It covers the calorie target, the protein/fat/carb split, realistic weight-change goals, the adaptive correction from weight trend, and logging food by weight. GymFree does **not** give meal plans or recipes.
Compiled: 2026-10-05. Every citation was checked against PubMed / Europe PMC / the publisher or official page at compile time. Companion to [TRAINING.md](TRAINING.md).

---

## 0. How to read this document

**Evidence standard (same bar as the ADHD and training research).** In order of preference: systematic reviews and meta-analyses; large or preregistered RCTs and metabolic-ward studies (DIETFITS, CALERIE, NIH ward studies); guidelines from public-health or independent bodies (WHO, NICE, National Academies DRIs, EFSA, AHA/ACC/TOS, KDIGO, AAP, IOC). Narrative reviews and single small trials are weaker. Brand sites, diet businesses, influencers and app-company blogs are **not** cited.

**Tiers**
- **Tier 1**: strong and consistent (meta-analysis, ward studies, or guideline level). The core algorithm is built on these.
- **Tier 2**: moderate (a few RCTs or meta-analyses with heterogeneity or COI caveats). Fine as defaults; keep them easy to change.
- **Tier 3**: weak, contested or expert practice only. Not used for core logic. Where the app still has to choose a number (for example a smoothing constant), the choice is labelled **engineering default**.

**Population tags**: [men], [women], [older adults] (≥65), [obesity], [overweight], [lean], [athletes/trained], [untrained], [adolescents].

**COI handling.** Funding and COI statements were read for every load-bearing paper. The protein literature has heavy food-industry involvement, so §5 and §11 flag it paper by paper. A flagged paper never decides a Tier 1 call on its own.

**Units.** Energy in kcal (1 kcal = 4.184 kJ). Mass in kg, height in cm. "%BW/week" means percent of current body weight per week.

---

## 1. Summary table: key numbers and formulas

| # | Topic | Number / rule | Tier | Population | Key sources |
|---|---|---|---|---|---|
| 1 | REE equation | **Mifflin–St Jeor** by default. Men: 10W + 6.25H − 5A + 5. Women: 10W + 6.25H − 5A − 161. It lands within ±10% of measured REE for more people than other equations (about 75% in obesity, so about 1 in 4 people are off by more than 10%). | 1 | adults, normal weight & obesity | [Frankenfield 2005](https://pubmed.ncbi.nlm.nih.gov/15883556/), [Madden 2016](https://pubmed.ncbi.nlm.nih.gov/26923904/), [Mifflin 1990](https://pubmed.ncbi.nlm.nih.gov/2305711/) |
| 2 | Harris–Benedict | Overestimates REE by about 5%. Do not use it as the default. | 1 | adults | [Mifflin 1990](https://pubmed.ncbi.nlm.nih.gov/2305711/) |
| 3 | Fat-free-mass equations | Cunningham (500 + 22 × FFM) is the most accurate in **athletes**, where Mifflin tends to underestimate. Use it only if a trustworthy FFM is known. | 2 | athletes | [O'Neill 2023](https://pubmed.ncbi.nlm.nih.gov/37632665/), [Cunningham 1980](https://pubmed.ncbi.nlm.nih.gov/7435418/) |
| 4 | TEE | Use the **National Academies 2023 DRI equations**, derived from doubly-labelled water (DLW). There are 4 activity categories per sex. Error: men RMSE 339 kcal (MAE 266); women RMSE 246 kcal (MAE 191). | 1 | adults 19+ | [NASEM 2023](https://nap.nationalacademies.org/catalog/26818) |
| 5 | PAL reality | DLW quartile cut points: inactive <1.53, low active 1.53–1.69, active 1.69–1.85, very active 1.85–2.5. The common "sedentary × 1.2" multiplier is below what DLW measures in real sedentary adults (PAL about 1.4). | 1 | adults | [NASEM 2023](https://www.nationalacademies.org/read/26818/chapter/9), [FAO/WHO/UNU 2004](https://www.fao.org/4/Y5686E/y5686e07.htm) |
| 6 | Self-report error | "Diet-resistant" people under-reported intake by **47%** and over-reported activity by **51%**. Most DLW studies find under-reporting. | 1 | obesity; adults | [Lichtman 1992](https://pubmed.ncbi.nlm.nih.gov/1454084/), [Burrows 2019](https://pubmed.ncbi.nlm.nih.gov/31920966/) |
| 7 | Wearable "calories burned" | No wrist device reached <20% error for energy expenditure. Never add watch calories to the target. | 2 | adults | [Shcherbina 2017](https://pubmed.ncbi.nlm.nih.gov/28538708/) |
| 8 | 3,500 kcal/lb rule | Roughly right for the **first weeks** in overweight adults, but grossly overestimates loss over months. Long-term planning number (Hall): each **24 kcal/day** (100 kJ) of sustained intake change → about **1 kg** eventual change. Half of it arrives in about 1 year, 95% in about 3 years. | 1 | overweight adults | [Hall 2011](https://pubmed.ncbi.nlm.nih.gov/21872751/), [Thomas 2013](https://pubmed.ncbi.nlm.nih.gov/23628852/), [Hall 2008](https://pubmed.ncbi.nlm.nih.gov/17848938/) |
| 9 | Planning factor | Deficit (kcal/day) ≈ **1,100 × target loss (kg/week)**, i.e. 7,700 kcal/kg. Use it only for short-horizon planning; the adaptive loop corrects it. | 2 | adults with ≥ ~30 kg fat; overestimates for lean | [Hall 2008](https://pubmed.ncbi.nlm.nih.gov/17848938/) |
| 10 | Weight-loss rate | Guidelines: **0.5–1 kg/week**, about a **500–750 kcal/day** deficit. Initial goal: **5–10% in 6 months**. | 1 | overweight/obesity | [AHA/ACC/TOS 2013](https://pubmed.ncbi.nlm.nih.gov/24222017/), [NHS](https://www.nhs.uk/conditions/obesity/treatment/) |
| 11 | Rate for lean/trained | At **~0.7%BW/week** lean mass rose; at 1.4%/week it stayed flat. Deficits **>500 kcal/day** blunt lean-mass gain during RT. | 2 | athletes/trained; mixed | [Garthe 2011](https://pubmed.ncbi.nlm.nih.gov/21558571/), [Murphy & Koehler 2022](https://pubmed.ncbi.nlm.nih.gov/34623696/) |
| 12 | Speed vs regain | In obesity, rapid and gradual loss led to the same regain (about 71–76% at 3 years). | 1 (one large RCT) | obesity | [Purcell 2014](https://pubmed.ncbi.nlm.nih.gov/25459211/) |
| 13 | Calorie floors | Typical prescriptions are **1,200–1,500 kcal (women)** and **1,500–1,800 (men)**. NICE: 800–1,200 kcal/day only inside specialist services; <800 only for clinical need. | 1 | adults | [AHA/ACC/TOS 2013](https://pubmed.ncbi.nlm.nih.gov/24222017/), [NICE NG246](https://www.nice.org.uk/guidance/ng246/chapter/Physical-activity-and-diet) |
| 14 | Metabolic adaptation | Real but small: about **−92 kcal/day** of RMR during active loss, **halving** once weight stabilises. It does not predict regain. Large and persistent only in extreme cases. | 2 | obesity | [Martins 2020](https://pubmed.ncbi.nlm.nih.gov/32844188/), [Fothergill 2016](https://pubmed.ncbi.nlm.nih.gov/27136388/) |
| 15 | Muscle-gain surplus | A larger surplus mostly adds **fat**, not more lean mass. Use a small surplus (about 5–10% of TEE). | 2 | athletes/trained | [Garthe 2013](https://pubmed.ncbi.nlm.nih.gov/23679146/), [Helms 2023](https://pubmed.ncbi.nlm.nih.gov/37914977/) (flagged), [Slater 2019](https://pubmed.ncbi.nlm.nih.gov/31482093/) |
| 16 | Lean-gain rate | RT adds about **1.5 kg** lean mass in typical trials (untrained men). Relative hypertrophy is similar in women. Target weight gain: novice about **0.25%BW/week**, slower when trained. | 2 (gain size); 3 (rates) | untrained men; women | [Benito 2020](https://pubmed.ncbi.nlm.nih.gov/32079265/), [Roberts 2020](https://pubmed.ncbi.nlm.nih.gov/32218059/) (flagged), [Iraki 2019](https://pubmed.ncbi.nlm.nih.gov/31247944/) |
| 17 | Protein, general RT | **1.6 g/kg/day** default. Benefit appears above the RDA (about 1.3 g/kg in an independent meta-analysis); the plateau is around 1.6 (95% CI up to 2.2). | 1 (above RDA helps in deficit/RT); 2 (1.6 plateau, COI) | adults | [Hudson 2020](https://pubmed.ncbi.nlm.nih.gov/31794597/), [Morton 2018](https://doi.org/10.1136/bjsports-2017-097608) (flagged), [Nunes 2022](https://pubmed.ncbi.nlm.nih.gov/35187864/) (flagged) |
| 18 | Protein in a deficit | 1.6 g/kg (2× RDA) protected FFM as well as 2.4 g/kg in a 40% deficit. Lean trained people may benefit from up to about 2.2 g/kg. | 2 | young adults; lean trained | [Pasiakos 2013](https://pubmed.ncbi.nlm.nih.gov/23739654/), [Helms 2014](https://pubmed.ncbi.nlm.nih.gov/24092765/), [Longland 2016](https://pubmed.ncbi.nlm.nih.gov/26817506/) (flagged) |
| 19 | Protein, older adults | At least **1.0–1.2 g/kg**, and ≥1.2 if active. | 2 (flagged consensus) | older adults | [PROT-AGE 2013](https://pubmed.ncbi.nlm.nih.gov/23867520/), [Nunes 2022](https://pubmed.ncbi.nlm.nih.gov/35187864/) |
| 20 | Protein & kidneys | No change in GFR in healthy adults on high-protein diets. In CKD G3–G5: about 0.8 g/kg and avoid >1.3 → no high-protein target. | 2 (healthy); 1 (CKD guideline) | healthy adults; CKD | [Devries 2018](https://pubmed.ncbi.nlm.nih.gov/30383278/) (flagged), [KDIGO 2024](https://kdigo.org/guidelines/ckd-evaluation-and-management/), [EFSA 2012](https://doi.org/10.2903/j.efsa.2012.2557) |
| 21 | Fat | AMDR / reference intake **20–35% of energy**. Floor 20%. Default 30%. | 1 | adults | [IOM DRI](https://nap.nationalacademies.org/catalog/10490), [EFSA 2010 fats](https://doi.org/10.2903/j.efsa.2010.1461) |
| 22 | Carbs | Carbs are the remainder. AMDR 45–65% (EFSA 45–60%). RDA 130 g/day is soft information, not a block. | 1 | adults | [IOM DRI](https://nap.nationalacademies.org/catalog/10490), [EFSA 2010 carbs](https://doi.org/10.2903/j.efsa.2010.1462) |
| 23 | Low-carb vs low-fat | No meaningful difference in weight at equal calories and protein: DIETFITS 12 months −6.0 vs −5.3 kg, NS. Ward studies: slightly **more** fat loss on low-fat. | 1 | adults, overweight/obesity | [Gardner 2018](https://pubmed.ncbi.nlm.nih.gov/29466592/), [Hall 2015](https://pubmed.ncbi.nlm.nih.gov/26278052/), [Hall & Guo 2017](https://pubmed.ncbi.nlm.nih.gov/28193517/), [Ge 2020](https://pubmed.ncbi.nlm.nih.gov/32238384/) |
| 24 | Fibre | **≥25 g/day** (WHO, EFSA). US: 14 g per 1,000 kcal. Biggest risk reduction at 25–29 g. | 1 | adults | [WHO 2023](https://www.who.int/publications/i/item/9789240073593), [Reynolds 2019](https://pubmed.ncbi.nlm.nih.gov/30638909/), [IOM DRI](https://nap.nationalacademies.org/catalog/10490) |
| 25 | Central adiposity | Waist-to-height ratio (BMI < 35): 0.4–0.49 healthy; **0.5–0.59 increased risk**; **≥0.6 high risk**. Lower BMI cut-offs (23 / 27.5) for South Asian, Chinese, other Asian, Middle Eastern, Black African and African-Caribbean backgrounds. | 1 | adults | [NICE NG246](https://www.nice.org.uk/guidance/ng246/chapter/Identifying-and-assessing-overweight-obesity-and-central-adiposity) |
| 26 | Consumer body-fat % | Smart scales misestimate fat mass by a median **2–4 kg** vs DXA. Do not ask for BIA body fat. | 2 | adults | [Frija-Masson 2021](https://pubmed.ncbi.nlm.nih.gov/33929337/) |
| 27 | Self-monitoring | Dietary self-monitoring and regular self-weighing go with more weight loss. Logging **frequency** matters more than time spent. | 1 (consistent association) | overweight/obesity | [Burke 2011](https://pubmed.ncbi.nlm.nih.gov/21185970/), [Zheng 2015](https://pubmed.ncbi.nlm.nih.gov/25521523/), [Patel 2021](https://pubmed.ncbi.nlm.nih.gov/33624440/), [Harvey 2019](https://pubmed.ncbi.nlm.nih.gov/30801989/) |
| 28 | Label error | EU tolerance: ±20% for 10–40 g/100 g. US: protein/carbs must be ≥80% of label; kcal/fat ≤120%. Measured snack kcal averaged +4.3%. | 1 (regulation) | — | [EC 2012](https://food.ec.europa.eu/system/files/2016-10/labelling_nutrition-vitamins_minerals-guidance_tolerances_1212_en.pdf), [21 CFR 101.9](https://www.ecfr.gov/current/title-21/chapter-I/subchapter-B/part-101/subpart-A/section-101.9), [Jumpertz 2013](https://pubmed.ncbi.nlm.nih.gov/23505182/) |
| 29 | Open food data | USDA FoodData Central = **CC0**. CoFID (UK) = **Open Government Licence**. Ciqual (FR) = **Licence Ouverte 2.0**. Canadian Nutrient File = **OGL–Canada**. Open Food Facts = **ODbL** (share-alike) + DbCL; images CC BY-SA. | 1 (licence text) | — | §8.5 |
| 30 | Who must not get deficit targets | Under 18, pregnant, current/past eating disorder, BMI < 18.5. Breastfeeding, insulin/sulfonylurea-treated diabetes and CKD → clinician first. | 1 (guidelines); 2 (app-specific gating) | — | [Golden 2016 (AAP)](https://pubmed.ncbi.nlm.nih.gov/27550979/), [NICE NG246](https://www.nice.org.uk/guidance/ng246), [Levinson 2017](https://pubmed.ncbi.nlm.nih.gov/28843591/) |

---

## 2. Resting energy expenditure (Q1)

**Finding 2.1. Mifflin–St Jeor is the best general-purpose equation. Tier 1. [adults, normal weight & obesity]**
- A systematic review of the four common equations (Harris–Benedict, Mifflin–St Jeor, Owen, WHO/FAO/UNU) found that Mifflin predicted RMR within 10% of measured in more non-obese **and** obese people than any other equation, with the narrowest error range. Older adults and US ethnic minorities were underrepresented ([Frankenfield 2005](https://pubmed.ncbi.nlm.nih.gov/15883556/)). The review ran no individual-level validation of WHO/FAO/UNU.
- In overweight/obesity, Mifflin was the most **precise** equation at BMI 30–39.9 and ≥40, with about **75% of predictions within ±10%**. "No single prediction equation provides accurate and precise REE estimates in all obese adults" ([Madden 2016](https://pubmed.ncbi.nlm.nih.gov/26923904/)). WHO (weight + height) was most accurate on average at BMI ≥25. Henry was most accurate at BMI ≥40.
- Equation, from 498 adults aged 19–78, about half with obesity ([Mifflin 1990](https://pubmed.ncbi.nlm.nih.gov/2305711/)):
  - Men: `REE = 10·W + 6.25·H − 5·A + 5`
  - Women: `REE = 10·W + 6.25·H − 5·A − 161`
  - (W kg, H cm, A years.) In the same data Harris–Benedict overestimated by about 5%.

**Finding 2.2. Fat-free-mass equations (Katch–McArdle / Cunningham) help only when FFM is measured well. Tier 2. [athletes]**
- In a meta-analysis of 29 athlete studies, Cunningham (1980), Harris–Benedict, Cunningham (1991), De Lorenzo and Ten Haaf did not differ from measured RMR. Most other equations, Mifflin included, significantly under- or overestimated ([O'Neill 2023](https://pubmed.ncbi.nlm.nih.gov/37632665/)).
- Cunningham 1980: `REE = 500 + 22·FFM` ([Cunningham 1980](https://pubmed.ncbi.nlm.nih.gov/7435418/)). Cunningham 1991: `REE = 370 + 21.6·FFM`, the same as the "Katch–McArdle" formula ([Cunningham 1991](https://pubmed.ncbi.nlm.nih.gov/1957828/)).
- These equations are only as good as the FFM input. Consumer BIA scales misestimate fat mass by kilograms (§7), and that error feeds straight into REE.

**Finding 2.3. WHO/Schofield works on weight alone and is fine for populations, but it is less precise for individuals.** Schofield adult equations, in MJ/day: men 18–30: 0.063W + 2.896; men 30–60: 0.048W + 3.653; women 18–30: 0.062W + 2.036; women 30–60: 0.034W + 3.538; and so on ([FAO/WHO/UNU 2004](https://www.fao.org/4/Y5686E/y5686e07.htm)). Tier 1 as a population tool; Tier 2 for individuals.

**Finding 2.4. Every equation leaves a large individual error.** Even the best one misses by more than 10% in about 1 in 4 people with obesity ([Madden 2016](https://pubmed.ncbi.nlm.nih.gov/26923904/)). Tier 1.

**Product consequence:** Compute REE with **Mifflin–St Jeor** for everyone. Use it for display ("your body uses about X kcal at rest") and as a soft calorie floor. Offer **Cunningham 1980** only when the user says they are resistance-trained **and** has a body-fat value from DXA or a similar lab method; never use a smart-scale value. Do not use Harris–Benedict. Treat every estimate as a starting guess that the adaptive loop (§3.4) corrects. For trans and non-binary users, let them choose which sex-specific equation to use, or average the two; there is no evidence base here (Tier 3).

---

## 3. Total energy expenditure, activity level and adaptive TDEE (Q2)

**Finding 3.1. The National Academies 2023 DRI equations predict TEE directly from DLW data. Tier 1. [adults 19+]**
The committee used a large DLW database and defined four physical-activity-level (PAL) categories by quartile ([NASEM 2023](https://nap.nationalacademies.org/catalog/26818), [equations](https://www.nationalacademies.org/read/26818/chapter/2), [categories](https://www.nationalacademies.org/read/26818/chapter/9)).

TEE (kcal/day). A = age (y), H = height (cm), W = weight (kg):

| Category (PAL range) | Men | Women |
|---|---|---|
| Inactive (1.0–<1.53) | 753.07 − 10.83A + 6.50H + 14.10W | 584.90 − 7.01A + 5.72H + 11.71W |
| Low active (1.53–<1.69) | 581.47 − 10.83A + 8.30H + 14.94W | 575.77 − 7.01A + 6.60H + 12.14W |
| Active (1.69–<1.85) | 1,004.82 − 10.83A + 6.52H + 15.91W | 710.25 − 7.01A + 6.54H + 12.34W |
| Very active (1.85–<2.5) | −517.88 − 10.83A + 15.61H + 19.11W | 511.83 − 7.01A + 9.07H + 12.56W |
| Error | RMSE 339, MAE 266 | RMSE 246, MAE 191 |

NASEM's illustrations of each category (Table 7-1):
- **Inactive** (PAL ~1.4): daily living only.
- **Low active** (~1.6): daily living plus about 60–80 min/day of walking at 3–4 mph.
- **Active** (~1.75): daily living plus roughly 30–50 min walking, 45 min moderate cycling and 40 min doubles tennis.
- **Very active** (~2.05): more than 2 h/day of vigorous activity.

About 68% of people fall within one standard error of the prediction.

**Finding 3.2. The classic multipliers are too coarse, and "sedentary × 1.2" is too low. Tier 1.**
- FAO/WHO/UNU lifestyle bands are: sedentary/light 1.40–1.69 (office workers); active/moderately active 1.70–1.99 (construction workers, people who exercise 1 h/day); vigorous 2.00–2.40. PAL > 2.40 is hard to sustain ([FAO/WHO/UNU 2004](https://www.fao.org/4/Y5686E/y5686e07.htm)).
- Both the FAO/WHO/UNU bands and the NASEM inactive category start at about PAL 1.4 for free-living adults. A multiplier of 1.2 is below every DLW-based category.

**Finding 3.3. Self-reports of intake and activity are biased, usually toward under-eating and over-moving. Tier 1.**
- People who said they were "diet-resistant" had normal TEE and RMR (within 5% of predicted). They under-reported intake by 47 ± 16% and over-reported activity by 51 ± 75% ([Lichtman 1992](https://pubmed.ncbi.nlm.nih.gov/1454084/)).
- A systematic review of 59 DLW studies (6,298 adults) found significant under-reporting in most studies, more often in women, and highly variable between people ([Burrows 2019](https://pubmed.ncbi.nlm.nih.gov/31920966/)).
- Wrist wearables: no device achieved <20% error for energy expenditure ([Shcherbina 2017](https://pubmed.ncbi.nlm.nih.gov/28538708/)). Tier 2.

**Finding 3.4. Weight trend plus logged intake can recalibrate TDEE, if you allow for water noise and the energy density of weight change.**
- Energy balance: `TEE ≈ mean intake − (Δ stored energy / days)`. The energy per kg lost depends on body fat. The 3,500 kcal/lb (≈7,700 kcal/kg) figure roughly fits obese people with >30 kg fat, but **overestimates** the deficit needed per kg for leaner people. Weight lost later in a diet is lower in energy per kg because more of it is lean tissue ([Hall 2008](https://pubmed.ncbi.nlm.nih.gov/17848938/)). Tier 1 (model, validated).
- Day-to-day weight is noisy. Weight swings about 0.35% within a week (weekend gain, weekday loss), and holidays add about 1.35% ([Turicchi 2020](https://pubmed.ncbi.nlm.nih.gov/32353079/)). Tier 2.
- A key property: if intake is under-logged by a stable fraction, the adaptive estimate becomes a **"logged-calories TDEE"**. The target stays self-consistent with how this user logs, which partly cancels the Lichtman/Burrows bias. This is reasoning from energy balance, not a trial result (Tier 3, engineering).

**Product consequence:**
1. Starting TEE = **NASEM 2023 equation** for the user's activity category. Mifflin REE is shown for context only.
2. Map the questionnaire to a category using **activity-minutes-equivalent per day (AME)**. **Engineering default, Tier 3**, anchored to NASEM Table 7-1:
   - **Job:** mostly sitting = 0; on your feet most of the day (retail, nursing, teaching) = 45; heavy manual work = 90.
   - **Workouts:** weekly minutes ÷ 7. Moderate (lifting, brisk walking, easy cycling) × 1; vigorous (running, HIIT, hard sports) × 2. The 2:1 equivalence comes from the WHO activity guidelines cited in TRAINING.md.
   - **Steps (optional, HealthKit):** add `max(0, steps − 5,000) / 100` minutes. Below 5,000 steps/day is the "sedentary" band ([Tudor-Locke 2004](https://pubmed.ncbi.nlm.nih.gov/14715035/)). About 100 steps/min is moderate walking. If steps are used, do not also count walking workouts.
   - **Category:** AME < 35 → inactive; 35–99 → low active; 100–184 → active; ≥185 → very active.
   - If unsure, pick the **lower** category. Overestimating TEE only slows weight loss, and the loop fixes it within weeks.
3. **Never** add wearable "active calories" to the target. Exercise is already in the PAL category.
4. Run the **adaptive correction** weekly (§12, step 9) once there are 14+ days of data. Show calories as ranges or rounded numbers so they don't look more precise than they are.

---

## 4. Deficits, rates, floors and realistic loss (Q3)

**Finding 4.1. Guideline rate: 0.5–1 kg/week, with a 500–750 kcal/day deficit and a first goal of 5–10% in 6 months. Tier 1. [overweight/obesity]**
- The AHA/ACC/TOS guideline offers three ways to set intake: 1,200–1,500 kcal/day for women and 1,500–1,800 for men; **or** a 500 or 750 kcal/day deficit; **or** an evidence-based diet that creates a deficit. The initial goal is 5–10% of baseline weight within 6 months ([Jensen 2014, AHA/ACC/TOS 2013](https://pubmed.ncbi.nlm.nih.gov/24222017/)).
- The NHS advises 0.5–1 kg/week via about −600 kcal/day ([NHS](https://www.nhs.uk/conditions/obesity/treatment/)). The CDC says 1–2 lb/week ([CDC](https://www.cdc.gov/healthy-weight-growth/losing-weight/index.html)).

**Finding 4.2. Rate barely affects long-term regain in obesity, but slower loss protects lean mass in lean, trained people. Tier 1 (obesity); Tier 2 (lean).**
- Obesity: a 12-week rapid programme and a 36-week gradual one (both aiming for 15%) ended with about 71% regain in each by 144 weeks. One rapid-loss participant needed a cholecystectomy ([Purcell 2014](https://pubmed.ncbi.nlm.nih.gov/25459211/)).
- Elite athletes: losing **0.7%BW/week** (a 19% energy cut) raised lean mass by 2.1%. Losing 1.4%/week (a 30% cut) did not ([Garthe 2011](https://pubmed.ncbi.nlm.nih.gov/21558571/)). Independent. [athletes]
- A meta-regression of RT in an energy deficit found that deficits around **>500 kcal/day prevented lean-mass gains**, while strength gains were unaffected ([Murphy & Koehler 2022](https://pubmed.ncbi.nlm.nih.gov/34623696/)). Tier 2. This matches TRAINING.md row 18.

**Finding 4.3. Weight loss slows over time; the 3,500 kcal rule overpredicts. Tier 1.**
- For an average overweight adult, "every change of energy intake of 100 kJ per day will lead to an eventual bodyweight change of about 1 kg, with half of the weight change being achieved in about one year and 95% … in about three years". Higher adiposity means a bigger and slower total change ([Hall 2011](https://pubmed.ncbi.nlm.nih.gov/21872751/)). The public NIDDK [Body Weight Planner](https://www.niddk.nih.gov/bwp) implements this model.
- Across seven supervised experiments, the 3,500 kcal rule "grossly overestimates" weight loss ([Thomas 2013](https://pubmed.ncbi.nlm.nih.gov/23628852/)).
- The typical plateau at about 6 months comes mainly from **intermittent lapses in adherence**, not metabolic adaptation ([Thomas 2014](https://pubmed.ncbi.nlm.nih.gov/25080458/)). Tier 2 (modelling).

**Finding 4.4. Metabolic adaptation is real but modest. Tier 2. [obesity]**
- After an 8-week 1,000 kcal/day diet (−14 kg), measured RMR was **92 ± 110 kcal/day** below predicted. The gap halved after 4 weeks of weight stability and did not predict regain at 1 year ([Martins 2020](https://pubmed.ncbi.nlm.nih.gov/32844188/)).
- Extreme loss can cause large adaptation that persists for years ("The Biggest Loser", n = 14, average loss 58 kg) ([Fothergill 2016](https://pubmed.ncbi.nlm.nih.gov/27136388/)).
- Adaptive thermogenesis and appetite changes help explain why weight is regained ([Rosenbaum & Leibel 2010](https://pubmed.ncbi.nlm.nih.gov/20935667/)).
- Also seen in non-obese adults on 25% calorie restriction in CALERIE 2 ([Falkenhain 2025](https://pubmed.ncbi.nlm.nih.gov/40830369/)).

**Finding 4.5. Floors and clinical limits. Tier 1.**
- NICE (2025): low-energy diets of **800–1,200 kcal/day** only as part of a multicomponent plan with long-term support in specialist services. Very-low-energy diets (<800) only for people with obesity and a clinically assessed need for rapid loss. These diets should not be used long-term, should last no more than 12 weeks, and need clinical supervision. Ask about eating disorders before any such diet ([NICE NG246 §1.16.8–1.16.11](https://www.nice.org.uk/guidance/ng246/chapter/Physical-activity-and-diet)).
- The AHA lower bounds are 1,200 kcal (women) and 1,500 kcal (men).

**Finding 4.6. Realistic expectations for a sedentary beginner. Tier 1.**
- A comprehensive lifestyle programme achieves about **5–10% in 6 months** ([AHA/ACC/TOS 2013](https://pubmed.ncbi.nlm.nih.gov/24222017/)).
- Named diets lose modest weight at 6 months, and **weight loss shrinks by 12 months** across all macronutrient patterns ([Ge 2020](https://pubmed.ncbi.nlm.nih.gov/32238384/), [Johnston 2014](https://pubmed.ncbi.nlm.nih.gov/25182101/)).
- NICE now treats obesity as a long-term condition in which regain is common ([NICE NG246](https://www.nice.org.uk/guidance/ng246)).

**Product consequence:**
- Default rate **0.5%BW/week** for everyone eligible.
- Cap the rate by BMI and leanness:
  - BMI ≥ 25: up to 1.0%/week (and never more than 1 kg/week).
  - BMI 18.5–24.9, or "lean" (body fat <20% men / <30% women when lab-measured), or a "keep muscle" priority: up to **0.7%/week**.
  - Age ≥ 65: up to 0.5%/week (Tier 3, conservative).
  - BMI < 18.5: no deficit at all.
- Cap the deficit at **min(25% of TEE, 1,000 kcal)**, and at **500 kcal** for the lean / keep-muscle group.
- Floors: **1,200 kcal (female equation) / 1,500 kcal (male equation)**, and not below Mifflin REE (Tier 3 soft floor). If a floor binds, lower the rate and say so.
- Goal weight may not be set below BMI 18.5. Show a gentle note below BMI 20.
- Projections: use "0.5%/week while recalibrating". Show a range, and say that loss slows and plateaus are normal.
- Never promise a date. Suggest the NIDDK Body Weight Planner for detailed modelling.

---

## 5. Surplus for muscle gain (Q4)

**Finding 5.1. A bigger surplus mainly adds fat. Tier 2. [athletes/trained]**
- Elite athletes doing 4 RT sessions/week ate about **3,585 vs 2,964 kcal** (planned surplus vs ad libitum) for 8–12 weeks. Weight rose 3.9% vs 1.5% and fat mass rose 15% vs 3%, but **lean-mass gain did not differ** ([Garthe 2013](https://pubmed.ncbi.nlm.nih.gov/23679146/)). Independent.
- Trained lifters (n = 17 completers) on maintenance, +5% or +15% energy: faster weight gain mainly raised skinfolds, not muscle thickness or 1RM. The biceps may be an exception ([Helms 2023](https://pubmed.ncbi.nlm.nih.gov/37914977/)). **COI flag:** funded by Legion Athletics (supplements) and Renaissance Periodization (diet app/coaching). Tier 3 on its own; it agrees with Garthe 2013.
- The surplus needed to maximise hypertrophy is unknown. Textbook "energy stored in tissue" calculations ignore the cost of synthesis and other adaptations ([Slater 2019](https://pubmed.ncbi.nlm.nih.gov/31482093/), narrative). Tier 3.

**Finding 5.2. Realistic lean-gain rates. Tier 2 (size); Tier 3 (weekly rates).**
- A meta-analysis of 111 RT studies in healthy men found an average **muscle-mass gain of about 1.5 kg** across typical programmes ([Benito 2020](https://pubmed.ncbi.nlm.nih.gov/32079265/)). [untrained/mixed men]
- Women and men show similar **relative** hypertrophy ([Roberts 2020](https://pubmed.ncbi.nlm.nih.gov/32218059/), preregistered; authors sell education products, see TRAINING.md §12). Absolute gains are smaller in women because they have less FFM to start with.
- One narrative review (no declared COI) suggests about 0.25–0.5%BW/week gain for novice/intermediate bodybuilders, with a 10–20% surplus, and less for advanced lifters ([Iraki 2019](https://pubmed.ncbi.nlm.nih.gov/31247944/)). Garthe 2013 and Helms 2023 point to the **lower** end.
- Beginners and people with more body fat can gain lean mass at maintenance or in a small deficit with adequate protein ([Longland 2016](https://pubmed.ncbi.nlm.nih.gov/26817506/), flagged). Tier 2–3.

**Product consequence:**
- Muscle-gain target rate: novice (<1 year of consistent RT) **0.25%BW/week**; intermediate 0.15%; advanced 0.1%.
- Surplus = `1,100 × rate (kg/week)`, clamped to **5–15% of TEE**. The 1,100 factor is Tier 3 here.
- If BMI ≥ 27 (or WHtR ≥ 0.5) and the goal is "build muscle", default to **recomposition**: maintenance or a 0.25%/week deficit, with high protein.
- Same % targets for women and men.
- Expectation copy: "most of your early gains come from training; eating a lot more mostly adds fat."

---

## 6. Protein (Q5)

**COI landscape:** Most protein-dose meta-analyses involve authors with dairy, beef or supplement funding (§11). The one fully independent anchor here is Hudson 2020 (no funding, no COI). Government-funded trials (Pasiakos, US Army/USDA) and EFSA/IOM give independent context.

**Finding 6.1. Above-RDA protein helps when there is a stressor (deficit or RT) and does nothing otherwise. Tier 1. [adults]**
- An independent meta-analysis of 18 RCTs (≥6 weeks) compared about **1.3 g/kg** with the RDA (0.8 g/kg). Lean mass was better by +0.36 kg during energy restriction and +0.77 kg with RT, with no difference without a stressor ([Hudson 2020](https://pubmed.ncbi.nlm.nih.gov/31794597/); the authors report no funding and no COI).

**Finding 6.2. The plateau is around 1.6 g/kg/day with wide uncertainty. Tier 2 (COI).**
- Gains in FFM with RT plateaued at **1.62 g/kg/day (95% CI 1.03–2.20)** ([Morton 2018](https://doi.org/10.1136/bjsports-2017-097608)). **COI:** Phillips has grants and honoraria from the US National Dairy Council, which funded trials in the analysis; co-authors have commercial ties (see TRAINING.md §12).
- In a 74-RCT meta-analysis, the effect on lean mass was significant at **≥1.6 g/kg** in people <65 doing RT, and at **1.2–1.59 g/kg** in people ≥65 ([Nunes 2022](https://pubmed.ncbi.nlm.nih.gov/35187864/)). **COI:** funded by ILSI Europe (industry-funded); co-authors are employees of Abbott Nutrition, IFF and Givaudan; Phillips has dairy and beef ties.
- In a 105-RCT spline model, each +0.1 g/kg/day added 0.39 kg lean mass below 1.3 g/kg and 0.12 kg above it ([Tagawa 2020](https://pubmed.ncbi.nlm.nih.gov/33300582/)). **COI:** 5 of 7 authors are employees of Meiji Co. (dairy/protein products).
- All three COI-flagged analyses point to the same picture as the independent Hudson 2020: real but **small** benefits that level off around 1.3–1.6 g/kg.

**Finding 6.3. In a deficit, 1.6 g/kg was enough in normal-weight adults; lean trained people may need more. Tier 2.**
- Over 21 days at a 40% deficit, 1.6 g/kg (2× RDA) and 2.4 g/kg protected FFM equally, and both did better than 0.8 g/kg ([Pasiakos 2013](https://pubmed.ncbi.nlm.nih.gov/23739654/); US Army/USDA funded).
- Young men in a 40% deficit with 6 days/week RT + HIIT gained more lean mass on 2.4 than on 1.2 g/kg ([Longland 2016](https://pubmed.ncbi.nlm.nih.gov/26817506/)). Flag: Phillips dairy ties.
- Systematic review in lean, trained, energy-restricted athletes (6 studies): **2.3–3.1 g/kg of FFM**, scaled up with leanness and deficit size ([Helms 2014](https://pubmed.ncbi.nlm.nih.gov/24092765/)). At 15% body fat that is about 2.0–2.6 g/kg of body weight. Tier 3 (small evidence base).
- The **ISSN** position stand (1.4–2.0 g/kg; 2.3–3.1 g/kg in hypocaloric trained) is **excluded**. Several authors are employed by or consult for protein/supplement companies (BioTRUST, Increnovo, and others) ([Jäger 2017](https://pubmed.ncbi.nlm.nih.gov/28642676/)).
- The ACSM/AND/DC joint position (about 1.2–2.0 g/kg for athletes) is an acceptable professional consensus ([Thomas 2016](https://pubmed.ncbi.nlm.nih.gov/26891166/)). Tier 2.

**Finding 6.4. Older adults. Tier 2 (flagged consensus).**
- PROT-AGE recommends **≥1.0–1.2 g/kg**, and ≥1.2 for active older adults. Exception: severe CKD (eGFR < 30) not on dialysis ([Bauer 2013](https://pubmed.ncbi.nlm.nih.gov/23867520/)). Flag: the study group was funded through a Nestlé Nutrition grant to the EUGMS.
- EFSA's PRI is 0.83 g/kg for all adults, older adults included ([EFSA 2012](https://doi.org/10.2903/j.efsa.2012.2557)).
- Nunes 2022's ≥65 subgroup agrees on 1.2–1.59.

**Finding 6.5. Which body weight to use in obesity. Tier 3.**
- No trial in healthy people. Clinical nutrition practice uses the weight at **BMI 25** (or an adjusted weight) for people with obesity, so that targets aren't inflated by fat mass ([Weijs 2012](https://pubmed.ncbi.nlm.nih.gov/22640477/), ICU context).

**Finding 6.6. Safety and upper limit.**
- EFSA: intakes of twice the PRI (about 1.7 g/kg) are regularly eaten by active Europeans and are considered safe. No UL was set ([EFSA 2012](https://doi.org/10.2903/j.efsa.2012.2557)). The IOM set no UL; the AMDR top is 35% of energy ([IOM DRI](https://nap.nationalacademies.org/catalog/10490)). Tier 1.
- Healthy kidneys: a meta-analysis of 28 RCTs (≥1.5 g/kg or ≥20% of energy) found no difference in the **change** in GFR ([Devries 2018](https://pubmed.ncbi.nlm.nih.gov/30383278/); flagged: Phillips dairy/beef ties; independent EFSA/IOM agree). Tier 2.
- CKD: KDIGO 2024 suggests 0.8 g/kg/day for CKD G3–G5 not on dialysis and **avoiding >1.3 g/kg/day** in people at risk of progression ([KDIGO 2024](https://kdigo.org/guidelines/ckd-evaluation-and-management/)). Tier 1 (guideline; weak 2C grade).

**Product consequence:**
- Protein target = `g/kg × basis weight`.
  - Basis weight = actual weight if BMI < 30 (BMI < 27.5 for the NICE lower-threshold ethnic groups). Otherwise use the weight at BMI 25: `25 × (H/100)²`.
- Defaults by goal:
  - **Maintain / gain muscle / general deficit: 1.6 g/kg.**
  - Lean (BMI < 25) and trained and in a deficit: offer up to **2.2**.
  - Age ≥ 65: minimum **1.2**.
  - User-adjustable between **1.2 and 2.2**. Hard UI max 2.2 g/kg basis weight; there is no evidence of extra benefit above it.
- **Kidney disease** (any CKD, eGFR < 60 or nephrologist advice): no high-protein target. Show 0.8 g/kg as information and "follow your kidney team's advice".
- Do not cap protein at 35% of kcal. In a deficit, protein's share naturally exceeds the AMDR, and the trials ran at those levels.
- Meal timing and distribution: not part of the app (§11).

---

## 7. Fat, carbohydrate, fibre, and does the split matter? (Q6)

**Finding 7.1. Fat: 20–35% of energy. Tier 1.**
- IOM AMDR (adults): fat **20–35%**, carbohydrate **45–65%**, protein **10–35%** ([IOM DRI 2005](https://nap.nationalacademies.org/catalog/10490)).
- EFSA reference intakes: fat **20–35%**, carbohydrate **45–60%** ([EFSA 2010 fats](https://doi.org/10.2903/j.efsa.2010.1461), [EFSA 2010 carbs/fibre](https://doi.org/10.2903/j.efsa.2010.1462)).
- Below about 20% fat it gets hard to meet essential fatty acid and fat-soluble vitamin needs (EFSA rationale).
- In men, low-fat vs high-fat diets lowered total and free testosterone modestly (SMD about −0.38; 6 small studies) ([Whittaker 2021](https://pubmed.ncbi.nlm.nih.gov/33741447/); a corrigendum was published in 2026). Tier 3. It supports keeping the 20% floor, nothing more.
- A floor of 0.5 g/kg comes from a bodybuilding narrative review ([Iraki 2019](https://pubmed.ncbi.nlm.nih.gov/31247944/)). Tier 3; used only as a secondary guard.

**Finding 7.2. Carbohydrate is the remainder. The RDA of 130 g/day (brain glucose) is information only.** ([IOM DRI](https://nap.nationalacademies.org/catalog/10490)). Tier 1 for the RDA; the "remainder" approach is the logical consequence of fixing protein and fat.

**Finding 7.3. At equal calories and protein, the low-carb vs low-fat split does not matter for weight. Tier 1.**
- **DIETFITS** (n = 609, 12 months, BMI 28–40): healthy low-fat −5.3 kg vs healthy low-carb −6.0 kg (difference 0.7 kg, 95% CI −0.2 to 1.6). Neither genotype nor insulin secretion predicted who did better ([Gardner 2018](https://pubmed.ncbi.nlm.nih.gov/29466592/); NIH-funded).
- Metabolic ward, isocaloric: cutting fat produced **more** body-fat loss (89 vs 53 g/day) than cutting carbs ([Hall 2015](https://pubmed.ncbi.nlm.nih.gov/26278052/)).
- A meta-analysis of 32 controlled feeding studies found slightly **greater** energy expenditure (+26 kcal/day) and fat loss (+16 g/day) on **lower-fat** diets ([Hall & Guo 2017](https://pubmed.ncbi.nlm.nih.gov/28193517/)). These differences are physiologically trivial.
- Network meta-analyses: low-carb and low-fat diets give similar weight loss. Differences between named diets are small and shrink by 12 months ([Johnston 2014](https://pubmed.ncbi.nlm.nih.gov/25182101/), [Ge 2020](https://pubmed.ncbi.nlm.nih.gov/32238384/)).

**Finding 7.4. Fibre: at least 25 g/day. Tier 1.**
- WHO 2023: at least 25 g/day of naturally occurring fibre for adults ([WHO 2023](https://www.who.int/publications/i/item/9789240073593)).
- EFSA: 25 g/day is adequate ([EFSA 2010](https://doi.org/10.2903/j.efsa.2010.1462)). IOM AI: 14 g per 1,000 kcal.
- Largest risk reductions at 25–29 g/day, with possible further benefit above that ([Reynolds 2019](https://pubmed.ncbi.nlm.nih.gov/30638909/)).

**Product consequence:**
- Fat default **30%** of target kcal, with **floor max(20% of kcal, 0.5 g/kg basis weight)**.
- Let the user pick a split style; adherence is what matters and weight outcomes are equal:
  - *Balanced* (fat 30%)
  - *Lower-fat* (fat 20–25%)
  - *Lower-carb* (fat 40%)
- Carbs = remainder: `(kcal − 4·P − 9·F) / 4`. If carbs fall below 130 g, show an information line, not a warning.
- Fibre goal = `max(25 g, 14 g × kcal/1000)`. Show it as a soft goal, not a tracked "limit".
- No "metabolic advantage" copy for any split.

---

## 8. Body composition inputs (Q7)

**Finding 8.1. BMI is the practical screen. Add waist-to-height ratio when BMI is under 35. Tier 1.**
- NICE recommends BMI with caution: it is not a direct measure of central fat, is less accurate in very muscular people, and needs care at age ≥65. For BMI < 35, also use **waist-to-height ratio (WHtR)**: 0.4–0.49 healthy; 0.5–0.59 increased risk; ≥0.6 high risk. These cut-offs apply to all sexes and ethnicities and to muscular adults.
- Lower BMI thresholds (overweight 23–27.4, obesity ≥27.5) apply for South Asian, Chinese, other Asian, Middle Eastern, Black African and African-Caribbean backgrounds ([NICE NG246 §1.9](https://www.nice.org.uk/guidance/ng246/chapter/Identifying-and-assessing-overweight-obesity-and-central-adiposity)).
- WHtR discriminates cardiometabolic risk better than waist alone or BMI ([Ashwell 2012](https://pubmed.ncbi.nlm.nih.gov/22106927/)). Tier 2: minor COI, since the first author devised the Ashwell Shape Chart (distributed on a non-profit basis) and the work was self-funded. NICE independently adopted WHtR.
- How to measure: midway between the bottom of the ribs and the top of the hips, breathing out normally (NICE Box 1).

**Finding 8.2. Consumer body-fat % is too inaccurate to drive calculations. Tier 2.**
- Three smart scales vs DXA: weight was fine (median error 0–0.3 kg), but **fat mass** was off by a median −2.2 to −4.4 kg, with wide IQRs ([Frija-Masson 2021](https://pubmed.ncbi.nlm.nih.gov/33929337/)).

**Finding 8.3. Lean mass can be estimated without a body-fat measurement. Tier 2.**
- **Relative Fat Mass**: `RFM = 64 − 20 × (height / waist) + 12 × sex` (sex = 0 men, 1 women; same units). It estimated DXA body-fat % better than BMI in NHANES ([Woolcott 2018](https://pubmed.ncbi.nlm.nih.gov/30030479/)). Lean mass ≈ `W × (1 − RFM/100)`.

**Product consequence:**
- Ask height, weight, age and sex. Ask **waist** optionally, with NICE's how-to.
- Show BMI with the right ethnicity-adjusted thresholds, plus WHtR, in neutral language.
- **Do not ask for smart-scale body fat.** Accept body fat only if the user marks it as DXA, BodPod or a clinic measurement. Use it only for the Cunningham REE option and the "lean" rate cap.
- If no lab value is available but waist is known, RFM can classify "lean" (<20% men / <30% women) for the rate cap.
- BMI is never used to judge a person. It only drives safety gates (BMI < 18.5) and the protein basis weight.

---

## 9. Food logging by weight (Q8)

**Finding 9.1. Self-monitoring is consistently associated with weight loss. Tier 1 (association; causal evidence weaker).**
- Systematic review of 22 studies: dietary self-monitoring, exercise logging and self-weighing are consistently associated with weight loss, though methods were weak ([Burke 2011](https://pubmed.ncbi.nlm.nih.gov/21185970/)).
- Regular self-weighing (17 prospective studies) was associated with more weight loss and **not** with depression or anxiety ([Zheng 2015](https://pubmed.ncbi.nlm.nih.gov/25521523/)).
- In 39 digital-intervention RCTs, more digital self-monitoring was linked to weight loss in 74% of cases ([Patel 2021](https://pubmed.ncbi.nlm.nih.gov/33624440/)).
- **Frequency** of logging, not minutes spent, separated people who lost ≥5%. Time needed fell from about 23 to 15 min/day by month 6 ([Harvey 2019](https://pubmed.ncbi.nlm.nih.gov/30801989/)).

**Finding 9.2. Logging error is large and unavoidable. Tier 1.**
- **EU tolerances** for carbs, sugars, protein, fibre and fat: <10 g/100 g ±2 g (fat ±1.5 g); 10–40 g/100 g **±20%**; >40 g/100 g ±8 g ([European Commission 2012](https://food.ec.europa.eu/system/files/2016-10/labelling_nutrition-vitamins_minerals-guidance_tolerances_1212_en.pdf)).
- **US:** naturally occurring protein and carbohydrate must be ≥80% of the declared value; calories, sugars and fat may not exceed it by more than 20% ([21 CFR 101.9(g)](https://www.ecfr.gov/current/title-21/chapter-I/subchapter-B/part-101/subpart-A/section-101.9)).
- Measured energy of snack foods averaged **+4.3%** over the label ([Jumpertz 2013](https://pubmed.ncbi.nlm.nih.gov/23505182/)).
- Restaurant foods: 19% of items were ≥100 kcal over their stated value ([Urban 2011](https://pubmed.ncbi.nlm.nih.gov/21771989/)).
- On top of this sits self-report under-reporting (§3.3).

**Finding 9.3. Is simple tracking enough? Tier 3.** A pilot comparing "simplified" with detailed tracking tested feasibility only ([Patel 2022](https://pubmed.ncbi.nlm.nih.gov/36512404/)). There is no good outcome evidence that full macro tracking beats calories + protein. Since frequency matters most (Harvey 2019), a low-friction logger is the evidence-aligned choice.

**Finding 9.4. Computing nutrients from per-100 g data. Tier 1 (regulation definitions).**
- Portion nutrients: `n_portion = n_per100 × grams / 100`.
- Energy conversion factors (EU [Reg. 1169/2011 Annex XIV](https://www.legislation.gov.uk/eur/2011/1169/annex/XIV)), kcal/g: carbohydrate 4, protein 4, fat 9, alcohol 7, **fibre 2**, polyols 2.4, organic acid 3, erythritol 0.
- **Pitfall 1, carbohydrate definitions:**
  - EU/UK "carbohydrate" = **available** carbohydrate, which **excludes fibre** ([Annex I](https://www.legislation.gov.uk/eur/2011/1169/annex/I)).
  - US/Canada "Total carbohydrate" **includes** fibre.
  - Store fibre separately. For US-style labels, available carbs = total − fibre. Prefer the label's own kcal value when present.
- **Pitfall 2, cooked vs raw:**
  - Meat and poultry lose moisture and fat when cooked, so cooked weight is lower and per-100 g values are higher. USDA publishes cut-specific yields ([USDA Cooking Yields, Release 2](https://ars.usda.gov/ARSUserFiles/80400535/Data/retn/USDA_CookingYields_MeatPoultry02.pdf)).
  - Rice, pasta and grains absorb water, so cooked weight is several times the dry weight.
  - Logging the cooked weight against a raw (or dry) entry is the most common large error. Force a state choice ("raw/dry" vs "cooked") whenever the database has both.
- **Pitfall 3, home recipes:** per-gram values of a cooked dish = **sum of the raw ingredients' nutrients ÷ total cooked weight of the dish**. The app should support "weigh the pot" without becoming a recipe feature.

**Finding 9.5. Open food-composition databases (licence terms verified at the source).**

| Database | Content | Licence | Obligations / notes |
|---|---|---|---|
| [USDA FoodData Central](https://fdc.nal.usda.gov/) | Foundation Foods, SR Legacy (generic foods, raw and cooked), FNDDS, Branded | **CC0 1.0** (public domain) ([API guide](https://fdc.nal.usda.gov/api-guide)) | None. USDA asks for "FoodData Central" to be credited. **Best candidate to bundle offline.** |
| [CoFID — McCance & Widdowson (UK)](https://www.gov.uk/government/publications/composition-of-foods-integrated-dataset-cofid) | About 3,000 UK foods | **Open Government Licence** | Attribution statement required. |
| [ANSES Ciqual (France)](https://www.data.gouv.fr/datasets/table-de-composition-nutritionnelle-des-aliments-ciqual/) | About 3,500 foods | **Licence Ouverte / Open Licence 2.0 (Etalab)** | Attribution. The latest version now lives on recherche.data.gouv. |
| [Canadian Nutrient File](https://open.canada.ca/data/en/dataset/90a31d6a-9131-4f31-a156-cd1f3b2717fe) | Canadian foods | **Open Government Licence – Canada** | Attribution. The [archived CNF guidelines](https://www.canada.ca/en/health-canada/services/food-nutrition/healthy-eating/nutrient-data/copyright-guidelines-canadian-nutrient-file.html) asked users not to modify nutrient values. |
| [Open Food Facts](https://world.openfoodfacts.org/data) | Crowd-sourced barcoded products | Database **ODbL**; contents **DbCL**; images **CC BY-SA** | Attribute: "Contains data from Open Food Facts, available under the ODbL." **Share-alike**: a derived database that is shared must stay ODbL. Data quality varies (user-entered). |

**Product consequence:**
- The logger is grams × per-100 g, with protein / fat / carbs (+ optional fibre, alcohol) and kcal.
- If the user types macros without kcal, compute kcal with Atwater/EU factors. Ask once per entry whether the label is **EU-style or US-style** carbohydrate.
- Bundle **USDA SR Legacy + Foundation Foods** offline (CC0, no strings attached).
- Optional online barcode lookup via Open Food Facts. Show a "community data — check the label" badge and let the user correct values. Put OFF and OGL attributions on a Credits screen.
- If OFF data is cached or bundled, keep it as a separate ODbL-licensed file so the share-alike scope is clear.
- Always ask raw/dry vs cooked. Offer "weigh the whole pot" for home dishes.
- Display kcal rounded to 10 and macros to 1 g.
- Offer a **"calories + protein only"** logging mode with quick-add, because logging frequency matters more than detail.
- Let the user mark a day as **complete**. The adaptive loop only uses complete days.

---

## 10. Safety and ethics (Q9)

**Finding 10.1. Calorie tracking can harm people with, or at risk of, eating disorders. Tier 2 (cross-sectional, but consistent and plausible).**
- College students who used calorie trackers had higher eating concern and dietary restraint ([Simpson & Mazzeo 2017](https://pubmed.ncbi.nlm.nih.gov/28214452/)).
- Among 105 people with a diagnosed ED, about 75% used MyFitnessPal and **73% of them felt it contributed** to their ED ([Levinson 2017](https://pubmed.ncbi.nlm.nih.gov/28843591/)).
- In adults with obesity in **structured** programmes, ED psychopathology and binge eating usually **improve** ([Peckmezian & Hay 2017](https://pubmed.ncbi.nlm.nih.gov/28469914/)), and self-weighing showed no psychological harm ([Zheng 2015](https://pubmed.ncbi.nlm.nih.gov/25521523/)). Risk sits with specific groups and with unsupervised dieting.

**Finding 10.2. Adolescents: no weight-loss dieting without clinical care. Tier 1.**
- The AAP advises focusing on healthy behaviours, not weight. Dieting is a risk factor for both obesity and EDs. Obesity treatment done properly does not cause EDs ([Golden 2016](https://pubmed.ncbi.nlm.nih.gov/27550979/)).
- Paediatric obesity treatment is clinician-led, intensive behaviour treatment ([Hampl 2023](https://pubmed.ncbi.nlm.nih.gov/36622115/)).
- Unsupervised dieting may raise ED risk in adolescents with obesity, whereas supervised care likely lowers it ([Jebeile 2021](https://pubmed.ncbi.nlm.nih.gov/33410207/)).
- EFSA protein PRIs for under-18s differ by age (0.83–1.31 g/kg), so adult formulas do not apply ([EFSA 2012](https://doi.org/10.2903/j.efsa.2012.2557)).

**Finding 10.3. Pregnancy and breastfeeding. Tier 1 (pregnancy), Tier 2 (lactation).**
- Pregnancy has specific weight-*gain* targets by pre-pregnancy BMI ([IOM 2009](https://pubmed.ncbi.nlm.nih.gov/20669500/)). A deficit calculator is inappropriate.
- Lactation: from 4 weeks postpartum, overweight breastfeeding women losing about 0.5 kg/week (−500 kcal + exercise) did not affect infant growth (n = 40) ([Lovelady 2000](https://pubmed.ncbi.nlm.nih.gov/10675424/)). The evidence is small, and energy needs during lactation are individual.

**Finding 10.4. Other groups who need a clinician first. Tier 1 (guidelines).**
- **CKD:** protein limits ([KDIGO 2024](https://kdigo.org/guidelines/ckd-evaluation-and-management/)).
- **Diabetes on insulin or sulfonylureas:** an energy deficit changes glucose control, and NICE lists type 1 diabetes among comorbidities to account for ([NICE NG246 §1.16.1](https://www.nice.org.uk/guidance/ng246/chapter/Physical-activity-and-diet)).
- **Very low-energy diets:** specialist services only (NICE).
- **Athletes with low energy availability:** REDs harms health and performance in both sexes ([IOC 2023](https://pubmed.ncbi.nlm.nih.gov/37752011/)).
- **Unintentional weight loss** (commonly defined as >5% over 6–12 months): it can signal disease and needs medical evaluation ([Gaddey 2021](https://pubmed.ncbi.nlm.nih.gov/34264616/)).
- **Eating-disorder screening:** the SCOFF questionnaire is a validated 5-question screen ([Morgan 1999](https://pubmed.ncbi.nlm.nih.gov/10582927/)). NICE covers ED recognition and treatment ([NICE NG69](https://www.nice.org.uk/guidance/ng69)).

**Product consequence: gating, wording and design rules**
1. **The nutrition feature is opt-in and off by default.** Onboarding opens with: "Tracking food and calories helps some people and isn't right for everyone. You can use GymFree's training features without it."
2. **Eligibility gate (hard).** No calorie targets and no deficit or surplus if the user:
   - is under 18 (also hide the feature entirely, per AAP);
   - is pregnant;
   - reports a current or past eating disorder;
   - has BMI < 18.5 and wants to lose weight.
   Copy for these users: "This feature isn't designed for you right now. A doctor or dietitian can give advice that fits you."
3. **SCOFF-style check (optional, 5 yes/no questions).** If 2 or more answers are "yes", don't show numeric targets. Instead show: "Some of your answers suggest food and weight may be causing you stress. Counting calories can make that worse. Talking to your doctor could help." Add a link to localised ED support. **Verify helpline numbers per country before shipping.** Say clearly that it is not a diagnosis.
4. **Clinician-first (soft gate: acknowledge to continue, maintenance-only until confirmed):** breastfeeding; diabetes treated with insulin or sulfonylureas; CKD; heart, liver or other chronic disease; taking weight-loss medicines; age ≥65 with frailty or recent unintended weight loss; BMI ≥ 40, or BMI ≥ 35 with a health condition ("specialist support and treatments may help").
5. **Language:**
   - No "good/bad/clean/cheat" foods, no "earn/burn off" food, no red "over budget" alarms (use neutral colours).
   - No streaks that punish missed days, no before/after imagery, no praise for fast drops.
   - Use "target range", not "limit".
   - Weekly-average framing beats daily pass/fail.
6. **Controls:**
   - "Hide numbers" mode (protein-only or habits-only).
   - Weighing reminders off by default; the user chooses the frequency.
   - Easy "pause nutrition" and "delete my nutrition data".
7. **Disclaimer (settings + first run):** "GymFree estimates are approximate. For most people the starting estimate is within about 10–15%, and it improves as you log. GymFree is not medical advice and is not for diagnosing or treating any condition. If you have a health condition, are pregnant or breastfeeding, or have had an eating disorder, talk to a health professional first." Avoid any claim to treat obesity or diabetes.

---

## 11. Rejected or downgraded claims

| Claim | Verdict | Evidence |
|---|---|---|
| "3,500 kcal = 1 lb, so a 500 kcal/day deficit = 1 lb/week forever" | **Rejected** for anything beyond the first weeks. Loss slows; about half the 3,500-rule prediction arrives in year 1. | [Hall 2011](https://pubmed.ncbi.nlm.nih.gov/21872751/), [Thomas 2013](https://pubmed.ncbi.nlm.nih.gov/23628852/) |
| "Starvation mode": eating too little stops weight loss | **Rejected.** Adaptation is about 50–100 kcal/day in typical diets and halves at stable weight. "Diet resistance" was under-reporting (47%). | [Martins 2020](https://pubmed.ncbi.nlm.nih.gov/32844188/), [Lichtman 1992](https://pubmed.ncbi.nlm.nih.gov/1454084/) |
| "Dieting permanently damages metabolism" | **Rejected** for normal dieting; only extreme cases show large persistent adaptation. | [Martins 2020](https://pubmed.ncbi.nlm.nih.gov/32844188/), [Fothergill 2016](https://pubmed.ncbi.nlm.nih.gov/27136388/) |
| Low-carb has a metabolic advantage / the insulin model | **Rejected** at equal calories and protein. | [Hall 2015](https://pubmed.ncbi.nlm.nih.gov/26278052/), [Hall & Guo 2017](https://pubmed.ncbi.nlm.nih.gov/28193517/), [Gardner 2018](https://pubmed.ncbi.nlm.nih.gov/29466592/), [Ge 2020](https://pubmed.ncbi.nlm.nih.gov/32238384/) |
| Eating small frequent meals "stokes metabolism" | **Rejected.** The meta-analysis's positive finding came from one study (authors with commercial ties; Tier 3, but no counter-evidence). | [Schoenfeld 2015](https://pubmed.ncbi.nlm.nih.gov/26024494/) |
| Breakfast is essential for weight control | **Rejected.** RCTs: breakfast eaters weighed 0.44 kg more and ate +260 kcal/day. | [Sievert 2019](https://pubmed.ncbi.nlm.nih.gov/30700403/) |
| Time-restricted eating / alternate-day fasting beat ordinary calorie restriction | **Rejected** at equal calories: TRE −8.0 vs −6.3 kg (NS) at 12 months; ADF ≈ daily restriction, with more dropout. Fine as a personal preference. | [Liu 2022](https://pubmed.ncbi.nlm.nih.gov/35443107/), [Trepanowski 2017](https://pubmed.ncbi.nlm.nih.gov/28459931/) |
| Rapid weight loss is always regained faster | **Rejected** for long-term regain in obesity (but watch gallstones). Slower loss is still better for lean mass in lean/trained people. | [Purcell 2014](https://pubmed.ncbi.nlm.nih.gov/25459211/), [Garthe 2011](https://pubmed.ncbi.nlm.nih.gov/21558571/) |
| "The body can only use 20–30 g protein per meal" | **Downgraded.** 100 g produced a larger and longer anabolic response than 25 g. Distribution still debated. Not app logic. | [Trommelen 2023](https://pubmed.ncbi.nlm.nih.gov/38118410/), [Witard & Mettler 2024](https://pubmed.ncbi.nlm.nih.gov/38991545/) |
| High protein damages healthy kidneys | **Rejected** for healthy adults; **valid caution in CKD**. | [Devries 2018](https://pubmed.ncbi.nlm.nih.gov/30383278/) (flagged), [EFSA 2012](https://doi.org/10.2903/j.efsa.2012.2557), [KDIGO 2024](https://kdigo.org/guidelines/ckd-evaluation-and-management/) |
| Protein needs of 2.3–3.1 g/kg for everyone; supplements needed | **Rejected** (ISSN stand excluded for COI). Whole food is enough; 1.6 g/kg covers most people. | [Jäger 2017](https://pubmed.ncbi.nlm.nih.gov/28642676/) (excluded), [Hudson 2020](https://pubmed.ncbi.nlm.nih.gov/31794597/) |
| "Eat back your exercise calories" from a watch | **Rejected.** Device EE error is ≥20%, and exercise is already in PAL. | [Shcherbina 2017](https://pubmed.ncbi.nlm.nih.gov/28538708/) |
| "Sedentary = BMR × 1.2" | **Rejected.** DLW sedentary PAL is about 1.4–1.5. | [NASEM 2023](https://www.nationalacademies.org/read/26818/chapter/9) |
| Smart-scale body-fat % is good enough for formulas | **Rejected** (kg-level fat-mass errors). | [Frija-Masson 2021](https://pubmed.ncbi.nlm.nih.gov/33929337/) |
| "Dirty bulk": big surplus = more muscle | **Rejected.** Extra energy mostly becomes fat. | [Garthe 2013](https://pubmed.ncbi.nlm.nih.gov/23679146/), [Helms 2023](https://pubmed.ncbi.nlm.nih.gov/37914977/) (flagged) |
| Planned diet breaks are required | **Not built** (Tier 3). One RCT in 51 men with obesity found 2-week breaks improved efficiency; there is no replication. Could become an optional feature. | [Byrne 2018 (MATADOR)](https://pubmed.ncbi.nlm.nih.gov/28925405/) |
| Genotype / insulin-type diets | **Rejected.** No diet × genotype or insulin interaction. | [Gardner 2018](https://pubmed.ncbi.nlm.nih.gov/29466592/) |

**COI register (load-bearing papers).**
- **Excluded:** ISSN 2017 protein stand (supplement-industry employees/consultants).
- **Flagged, kept only where independent evidence agrees:**
  - Morton 2018, Longland 2016, Devries 2018 (Phillips: dairy/beef funding).
  - Nunes 2022 (ILSI Europe funding; Abbott/IFF/Givaudan employees).
  - Tagawa 2020 (Meiji employees).
  - PROT-AGE 2013 (Nestlé Nutrition grant).
  - Helms 2023 (Legion Athletics and Renaissance Periodization funding).
  - Schoenfeld 2015 and Roberts 2020 (authors sell education products).
  - Ashwell 2012 (minor: author's own non-profit Shape Chart).
- **Note:** Orsama 2014 on weekly weight rhythms was not used; co-author Wansink has multiple retractions. Turicchi 2020 is used instead.
- **Independent anchors:** Hudson 2020, Pasiakos 2013, Garthe 2011/2013, Murphy & Koehler 2022, Hall/NIH ward studies, DIETFITS, NASEM, EFSA, WHO, NICE, KDIGO, AHA/ACC/TOS.

---

## 12. Algorithm spec (evidence-based defaults)

Everything is computed in kg, cm and kcal. Round displayed kcal to the nearest 10. The tier of each step is in brackets.

### Step 0. Inputs and eligibility gate [Tier 1 guidelines; gating rules are engineering]
- **Inputs:** age (y), sex for equations (male / female / "choose equation" for trans and non-binary users), height H (cm), weight W (kg), job activity, workouts/week (minutes, intensity), optional steps (HealthKit), goal (lose / maintain / build muscle), training experience (novice <1 y, intermediate 1–3 y, advanced >3 y), optional waist (cm), optional lab body fat %, ethnicity group (optional, for BMI thresholds), safety answers.
- `BMI = W / (H/100)²`. `WHtR = waist / H`.
- **Hard stop (no targets):** age < 18; pregnant; current or past ED (or SCOFF ≥ 2); goal = lose and BMI < 18.5.
- **Clinician-first (maintenance only until acknowledged):** breastfeeding; insulin or sulfonylurea; CKD / eGFR < 60; other chronic disease or a diet prescribed by a clinician; weight-loss medicine; age ≥ 65 with frailty; BMI ≥ 40, or ≥ 35 with a comorbidity.

### Step 1. REE [Tier 1]
`REE = 10W + 6.25H − 5A + 5` (male) or `− 161` (female).
Option (trained + lab FFM): `REE = 500 + 22·FFM` [Tier 2].

### Step 2. TEE [Tier 1 equations; Tier 3 category mapping]
- `AME = job (0 / 45 / 90) + (moderate min/week + 2 × vigorous min/week) / 7 + max(0, steps − 5000) / 100`
- Category: AME < 35 inactive; 35–99 low active; 100–184 active; ≥185 very active.
- `TEE₀` = NASEM 2023 equation for sex and category (table in §3.1).

### Step 3. Goal adjustment with caps
- **Maintain:** `target = TEE`.
- **Lose** [Tier 1–2]:
  - `rate%` default 0.5%/week. User can choose 0.25 / 0.5 / 0.75 / 1.0, subject to the caps:
    - `maxRate = 1.0` if BMI ≥ 25 (≥ 23 for the NICE lower-threshold groups) and not "lean".
    - `maxRate = 0.7` if BMI below that, or lean (lab BF < 20% male / < 30% female, or RFM below the same), or "keep muscle" priority.
    - `maxRate = 0.5` if age ≥ 65.
  - `deficit = 1100 × (rate% / 100) × W_trend`, capped at `min(0.25 × TEE, 1000)`, and at 500 for the lean / keep-muscle group.
  - `target = TEE − deficit`.
- **Build muscle** [Tier 2–3]:
  - If BMI ≥ 27 or WHtR ≥ 0.5 → suggest recomposition (maintenance or 0.25%/week loss). The user may override.
  - Otherwise `rate%` = 0.25 (novice) / 0.15 (intermediate) / 0.10 (advanced) per week.
  - `surplus = clamp(1100 × (rate%/100) × W_trend, 0.05 × TEE, 0.15 × TEE)`.
  - `target = TEE + surplus`.

### Step 4. Calorie floor rules [Tier 1 floors; Tier 3 REE floor]
- `floor = max(1200 if female equation else 1500, REE)`.
- If `target < floor`: set `target = floor`, recompute the implied rate, and tell the user: "A slower pace is the safe option here."
- The app never sets a target below 1,200 kcal. Below that is specialist territory (NICE).

### Step 5. Protein [Tier 1–2]
- `basisW = W` if BMI < 30 (< 27.5 for the NICE lower-threshold groups); otherwise `25 × (H/100)²`.
- `g/kg` = 1.6 by default; up to 2.2 if lean + trained + losing; minimum 1.2 if age ≥ 65; user range 1.2–2.2.
- CKD → no target; show 0.8 g/kg as information.
- `P = g/kg × basisW` (g). `kcal_P = 4P`.

### Step 6. Fat floor [Tier 1 floor; Tier 3 g/kg guard]
- `F = fatShare × target / 9`, with fatShare = 0.30 (balanced), 0.225 (lower-fat) or 0.40 (lower-carb).
- `F = max(F, 0.20 × target / 9, 0.5 × basisW)`.

### Step 7. Carbs = remainder [Tier 1]
- `C = (target − 4P − 9F) / 4`.
- If C < 130 g → information line only.
- If C < 50 g because of floors and high protein → lower protein toward 1.6 (or 1.2) first, then fat toward its floor.
- **Fibre goal** = `max(25, 14 × target / 1000)` g.

### Step 8. Logging math [Tier 1]
- Portion values = per-100 g × grams / 100.
- kcal: use the label value if present. Otherwise `4·P + 4·C_available + 9·F + 2·fibre + 7·alcohol`.
- US-style labels: `C_available = C_total − fibre`.

### Step 9. Weekly adaptive correction from weight trend [Tier 2 principle (energy balance, Hall 2008); constants are engineering defaults (Tier 3)]
Run once a week (Monday).
1. **Data rules:**
   - Use the last 21 days, ending yesterday.
   - Skip if fewer than 14 days have passed since start or since any target change > 200 kcal (glycogen and water transients).
   - Require ≥ 10 weigh-ins and ≥ 75% of days marked "complete" in the log.
   - Drop weigh-ins more than 2.5 kg from the 7-day median.
   - Women with cycles may choose a 28-day window.
2. `slope` = least-squares slope of weight vs day (kg/day). `W_trend` = the regression value for yesterday.
3. `TEE_obs = mean(logged kcal on complete days) − slope × 7700`.
4. **Sanity check:**
   - If `TEE_obs` is outside `[0.65, 1.35] × TEE_equation`, don't update. Ask the user to check logging and weighing consistency, without blame.
   - Otherwise `TEE_new = TEE_old + 0.5 × (TEE_obs − TEE_old)`, with the weekly change clamped to ±200 kcal.
5. Recompute Steps 3–7 using `TEE_new` and `W_trend`. Floors still apply. If a floor binds, say: "progress may be slower; that's OK."
6. **Muscle-gain mode:**
   - If the trend rate is above 2 × target for 3 weeks → −100 kcal.
   - If it is below 0 for 3 weeks → +100 kcal.
   - (These are simple nudges inside the 5–15% surplus band.)
7. Messaging: plateaus at around 6 months are normal and are usually about consistency ([Thomas 2014](https://pubmed.ncbi.nlm.nih.gov/25080458/)). Use weekly averages, never daily pass/fail.

### Step 10. "Talk to a clinician" triggers [Tier 1–2]
Show a non-alarming card with a "why am I seeing this?" explanation when:
- the trend loss is > 1.5%BW/week for 3 consecutive weeks (excluding the first 2 weeks), or > 1 kg/week sustained for 4 weeks;
- the trend weight crosses BMI 18.5, or the user tries to set a goal below it;
- the 7-day average of **logged** intake is below 1,200 kcal (female eq.) / 1,500 (male eq.) for 2+ weeks. Also show ED resources gently;
- weight falls > 5% within 6 months while the goal is maintain or gain (unintentional loss);
- the user later reports pregnancy, ED symptoms, a new diagnosis or new medicines (re-run Step 0);
- BMI ≥ 40, or ≥ 35 with a comorbidity, at onboarding: specialist services and treatments exist (NICE).

### Worked example A: 95 kg sedentary 35-year-old man, 180 cm, wants to lose weight
- Inputs: desk job (0); lifts 3 × 60 min/week → AME = 180/7 = 26 → **inactive**. BMI = 95 / 1.8² = **29.3**.
- REE (Mifflin) = 950 + 1,125 − 175 + 5 = **1,905 kcal**.
- TEE₀ (NASEM, inactive man) = 753.07 − 379.05 + 1,170 + 1,339.5 = **2,884 kcal** (PAL vs Mifflin ≈ 1.51).
  - For comparison, Mifflin × 1.2 = 2,286, about 600 kcal too low by DLW standards.
- Rate: default 0.5%/week → 0.475 kg/week → deficit = 1,100 × 0.475 = **523 kcal**.
  - Caps: BMI ≥ 25 → maxRate 1.0%. Deficit cap = min(0.25 × 2,884 = 721, 1,000) = 721.
  - The most aggressive allowed is **−720 kcal** (≈0.65 kg/week).
- **Target = 2,884 − 523 ≈ 2,360 kcal/day.** Floor = max(1,500, 1,905) = 1,905 → OK.
- Protein: BMI < 30 → basisW 95 kg × 1.6 = **152 g** (608 kcal).
- Fat: 30% × 2,360 / 9 = **79 g** (711 kcal). Floors 52 g / 47.5 g → OK.
- Carbs: (2,360 − 608 − 711) / 4 = **260 g**. Fibre goal: max(25, 33) = **33 g**.
- **Realistic expectation:**
  - At about 0.5%/week while recalibrating: ≈ −5.5 kg in 12 weeks (95 → 89.5 kg). Show a 3–6 kg band.
  - The 6-month goal is 5–10% (≈ 4.75–9.5 kg).
  - If he kept eating 2,360 forever with no recalibration, Hall's rule gives about −22 kg eventually (523 / 24), roughly half of it in the first year.
- **Adaptive example (week 5):**
  - Days 15–35: logged mean 2,300 kcal; slope −0.05 kg/day (−0.35 kg/week).
  - TEE_obs = 2,300 + 0.05 × 7,700 = **2,685**. That is within [0.65, 1.35] × 2,884, so the update is accepted.
  - TEE_new = 2,884 + 0.5 × (2,685 − 2,884) = **2,784**.
  - W_trend 93.6 kg → deficit = 1,100 × 0.468 = 515 → **new target ≈ 2,270 kcal**.
  - Protein, fat and carbs are recomputed from the new target.

### Worked example B: 60 kg active 28-year-old woman, 165 cm, wants muscle
- Inputs: desk job (0); classes 5 × 60 min/week vigorous → 600/7 = 86; 9,000 steps → +40. AME = 126 → **active**. BMI = 60 / 1.65² = **22.0**. Novice lifter.
- REE (Mifflin) = 600 + 1,031 − 140 − 161 = **1,330 kcal**.
- TEE₀ (NASEM, active woman) = 710.25 − 196.28 + 1,079.1 + 740.4 = **2,333 kcal**. For comparison, Mifflin × 1.75 = 2,328.
- Goal: BMI < 27 → muscle gain. Novice rate 0.25%/week → 0.15 kg/week → surplus = 1,100 × 0.15 = **165 kcal**. Clamp [117, 350] → 165.
- **Target ≈ 2,500 kcal/day.**
- Protein: 1.6 × 60 = **96 g** (384 kcal). Fat: 30% → **83 g** (747 kcal). Carbs: (2,500 − 384 − 747) / 4 = **342 g**. Fibre goal: **35 g**.
- **Realistic expectation:**
  - About +1.8 kg body weight over 12 weeks. Perhaps half to two-thirds of it is lean tissue (Tier 3).
  - Strength rises faster than size.
  - Relative muscle gain is similar to men's, but absolute kg are smaller.
- Adaptive: if the trend gain is > 0.5%/week for 3 weeks → −100 kcal; if ≤ 0 for 3 weeks → +100 kcal.

### Worked example C (gate behaviour): 17-year-old, any goal
Nutrition targets are hidden. Copy: "Calorie targets aren't designed for under-18s. Training, sleep and regular meals matter most at your age. A doctor can help if you're worried about your weight." Training features stay fully available.

---

## 13. Open questions / not decided here
- Whether to implement Hall's full dynamic model (as in the NIDDK Body Weight Planner) for projections, instead of the simple %/week view. The full model would be more accurate for long horizons but more complex. Current recommendation: link to the NIDDK planner and keep in-app projections conservative.
- Whether the activity questionnaire should use HealthKit "active energy" at all. Current recommendation: no (error ≥ 20%); use steps only.
- Energy density of gained tissue in muscle-gain mode (1,100 kcal/day per kg/week is a placeholder; Tier 3). The adaptive nudges make the exact value unimportant.

---

## 14. Reference list (all links verified 2026-10-05)

**Energy expenditure**
- Mifflin MD et al. *Am J Clin Nutr* 1990. [PubMed 2305711](https://pubmed.ncbi.nlm.nih.gov/2305711/)
- Frankenfield D et al. Systematic review of RMR equations. *J Am Diet Assoc* 2005. [PubMed 15883556](https://pubmed.ncbi.nlm.nih.gov/15883556/)
- Madden AM et al. Prediction equations in obesity, systematic review. *J Hum Nutr Diet* 2016. [PubMed 26923904](https://pubmed.ncbi.nlm.nih.gov/26923904/)
- O'Neill JER et al. RMR equations in athletes, meta-analysis. *Sports Med* 2023. [PubMed 37632665](https://pubmed.ncbi.nlm.nih.gov/37632665/)
- Cunningham JJ. *Am J Clin Nutr* 1980 [PubMed 7435418](https://pubmed.ncbi.nlm.nih.gov/7435418/); 1991 [PubMed 1957828](https://pubmed.ncbi.nlm.nih.gov/1957828/)
- FAO/WHO/UNU. Human energy requirements, 2004. [FAO](https://www.fao.org/4/Y5686E/y5686e07.htm)
- National Academies. Dietary Reference Intakes for Energy, 2023. [NAP 26818](https://nap.nationalacademies.org/catalog/26818); [PubMed 36693139](https://pubmed.ncbi.nlm.nih.gov/36693139/)
- Lichtman SW et al. *N Engl J Med* 1992. [PubMed 1454084](https://pubmed.ncbi.nlm.nih.gov/1454084/)
- Burrows TL et al. DLW validation, systematic review. *Front Endocrinol* 2019. [PubMed 31920966](https://pubmed.ncbi.nlm.nih.gov/31920966/)
- Shcherbina A et al. Wrist-worn EE accuracy. *J Pers Med* 2017. [PubMed 28538708](https://pubmed.ncbi.nlm.nih.gov/28538708/)
- Tudor-Locke C, Bassett DR. Steps/day indices. *Sports Med* 2004. [PubMed 14715035](https://pubmed.ncbi.nlm.nih.gov/14715035/)
- Turicchi J et al. Weight fluctuation patterns. *PLoS One* 2020. [PubMed 32353079](https://pubmed.ncbi.nlm.nih.gov/32353079/)

**Weight change dynamics, rates, adaptation**
- Hall KD et al. *Lancet* 2011. [PubMed 21872751](https://pubmed.ncbi.nlm.nih.gov/21872751/); NIDDK [Body Weight Planner](https://www.niddk.nih.gov/bwp)
- Hall KD. Energy deficit per unit weight loss. *Int J Obes* 2008. [PubMed 17848938](https://pubmed.ncbi.nlm.nih.gov/17848938/)
- Thomas DM et al. 3,500-kcal rule. *Int J Obes* 2013. [PubMed 23628852](https://pubmed.ncbi.nlm.nih.gov/23628852/)
- Thomas DM et al. Adherence and plateau. *Am J Clin Nutr* 2014. [PubMed 25080458](https://pubmed.ncbi.nlm.nih.gov/25080458/)
- Jensen MD et al. 2013 AHA/ACC/TOS guideline. *Circulation* 2014. [PubMed 24222017](https://pubmed.ncbi.nlm.nih.gov/24222017/)
- NICE NG246 Overweight and obesity management (2025, updated 2026). [NICE](https://www.nice.org.uk/guidance/ng246)
- NHS obesity treatment. [NHS](https://www.nhs.uk/conditions/obesity/treatment/); CDC Losing weight. [CDC](https://www.cdc.gov/healthy-weight-growth/losing-weight/index.html)
- Purcell K et al. *Lancet Diabetes Endocrinol* 2014. [PubMed 25459211](https://pubmed.ncbi.nlm.nih.gov/25459211/)
- Garthe I et al. Weight-loss rates in athletes. *IJSNEM* 2011. [PubMed 21558571](https://pubmed.ncbi.nlm.nih.gov/21558571/)
- Murphy C, Koehler K. Energy deficiency and RT. *Scand J Med Sci Sports* 2022. [PubMed 34623696](https://pubmed.ncbi.nlm.nih.gov/34623696/)
- Martins C et al. *Am J Clin Nutr* 2020. [PubMed 32844188](https://pubmed.ncbi.nlm.nih.gov/32844188/)
- Fothergill E et al. *Obesity* 2016. [PubMed 27136388](https://pubmed.ncbi.nlm.nih.gov/27136388/)
- Rosenbaum M, Leibel RL. *Int J Obes* 2010. [PubMed 20935667](https://pubmed.ncbi.nlm.nih.gov/20935667/)
- Falkenhain K et al. CALERIE 2 organ size. *Sci Rep* 2025. [PubMed 40830369](https://pubmed.ncbi.nlm.nih.gov/40830369/)
- Byrne NM et al. MATADOR. *Int J Obes* 2018. [PubMed 28925405](https://pubmed.ncbi.nlm.nih.gov/28925405/)

**Muscle gain**
- Garthe I et al. Nutritional intervention, weight gain in athletes. *Eur J Sport Sci* 2013. [PubMed 23679146](https://pubmed.ncbi.nlm.nih.gov/23679146/)
- Helms ER et al. Energy surpluses (flagged). *Sports Med Open* 2023. [PubMed 37914977](https://pubmed.ncbi.nlm.nih.gov/37914977/)
- Slater GJ et al. Energy surplus review. *Front Nutr* 2019. [PubMed 31482093](https://pubmed.ncbi.nlm.nih.gov/31482093/)
- Iraki J et al. Off-season bodybuilding nutrition. *Sports* 2019. [PubMed 31247944](https://pubmed.ncbi.nlm.nih.gov/31247944/)
- Benito PJ et al. RT and muscle growth, meta-analysis. *IJERPH* 2020. [PubMed 32079265](https://pubmed.ncbi.nlm.nih.gov/32079265/)
- Roberts BM et al. Sex differences in RT (flagged). *JSCR* 2020. [PubMed 32218059](https://pubmed.ncbi.nlm.nih.gov/32218059/)

**Protein**
- Hudson JL et al. Protein > RDA, meta-analysis. *Adv Nutr* 2020. [PubMed 31794597](https://pubmed.ncbi.nlm.nih.gov/31794597/)
- Morton RW et al. (flagged). *Br J Sports Med* 2018. [DOI 10.1136/bjsports-2017-097608](https://doi.org/10.1136/bjsports-2017-097608)
- Nunes EA et al. (flagged). *J Cachexia Sarcopenia Muscle* 2022. [PubMed 35187864](https://pubmed.ncbi.nlm.nih.gov/35187864/)
- Tagawa R et al. (flagged). *Nutr Rev* 2020. [PubMed 33300582](https://pubmed.ncbi.nlm.nih.gov/33300582/)
- Pasiakos SM et al. *FASEB J* 2013. [PubMed 23739654](https://pubmed.ncbi.nlm.nih.gov/23739654/)
- Longland TM et al. (flagged). *Am J Clin Nutr* 2016. [PubMed 26817506](https://pubmed.ncbi.nlm.nih.gov/26817506/)
- Helms ER et al. Protein in caloric restriction. *IJSNEM* 2014. [PubMed 24092765](https://pubmed.ncbi.nlm.nih.gov/24092765/)
- Jäger R et al. ISSN protein stand (excluded). *JISSN* 2017. [PubMed 28642676](https://pubmed.ncbi.nlm.nih.gov/28642676/)
- Thomas DT et al. ACSM/AND/DC. *Med Sci Sports Exerc* 2016. [PubMed 26891166](https://pubmed.ncbi.nlm.nih.gov/26891166/)
- Bauer J et al. PROT-AGE (flagged). *JAMDA* 2013. [PubMed 23867520](https://pubmed.ncbi.nlm.nih.gov/23867520/)
- Weijs PJ et al. Body weight for protein dosing. *Clin Nutr* 2012. [PubMed 22640477](https://pubmed.ncbi.nlm.nih.gov/22640477/)
- Devries MC et al. (flagged). *J Nutr* 2018. [PubMed 30383278](https://pubmed.ncbi.nlm.nih.gov/30383278/)
- EFSA NDA Panel. DRVs for protein. *EFSA J* 2012. [DOI 10.2903/j.efsa.2012.2557](https://doi.org/10.2903/j.efsa.2012.2557)
- KDIGO 2024 CKD guideline. [KDIGO](https://kdigo.org/guidelines/ckd-evaluation-and-management/)
- Trommelen J et al. *Cell Rep Med* 2023. [PubMed 38118410](https://pubmed.ncbi.nlm.nih.gov/38118410/); Witard & Mettler commentary 2024. [PubMed 38991545](https://pubmed.ncbi.nlm.nih.gov/38991545/)

**Fat, carbohydrate, fibre, diet composition**
- IOM. DRIs for energy, carbohydrate, fiber, fat, fatty acids, cholesterol, protein and amino acids, 2002/2005. [NAP 10490](https://nap.nationalacademies.org/catalog/10490)
- EFSA NDA Panel. DRVs for fats, 2010. [DOI 10.2903/j.efsa.2010.1461](https://doi.org/10.2903/j.efsa.2010.1461); carbohydrates and fibre, 2010. [DOI 10.2903/j.efsa.2010.1462](https://doi.org/10.2903/j.efsa.2010.1462)
- WHO. Carbohydrate intake for adults and children, 2023. [WHO](https://www.who.int/publications/i/item/9789240073593)
- Reynolds A et al. *Lancet* 2019. [PubMed 30638909](https://pubmed.ncbi.nlm.nih.gov/30638909/)
- Whittaker J, Wu K. Low-fat diets and testosterone. *J Steroid Biochem Mol Biol* 2021. [PubMed 33741447](https://pubmed.ncbi.nlm.nih.gov/33741447/)
- Gardner CD et al. DIETFITS. *JAMA* 2018. [PubMed 29466592](https://pubmed.ncbi.nlm.nih.gov/29466592/)
- Hall KD et al. *Cell Metab* 2015. [PubMed 26278052](https://pubmed.ncbi.nlm.nih.gov/26278052/)
- Hall KD, Guo J. *Gastroenterology* 2017. [PubMed 28193517](https://pubmed.ncbi.nlm.nih.gov/28193517/)
- Johnston BC et al. *JAMA* 2014. [PubMed 25182101](https://pubmed.ncbi.nlm.nih.gov/25182101/)
- Ge L et al. *BMJ* 2020. [PubMed 32238384](https://pubmed.ncbi.nlm.nih.gov/32238384/)
- Schoenfeld BJ et al. Meal frequency. *Nutr Rev* 2015. [PubMed 26024494](https://pubmed.ncbi.nlm.nih.gov/26024494/)
- Sievert K et al. Breakfast. *BMJ* 2019. [PubMed 30700403](https://pubmed.ncbi.nlm.nih.gov/30700403/)
- Liu D et al. TRE. *N Engl J Med* 2022. [PubMed 35443107](https://pubmed.ncbi.nlm.nih.gov/35443107/)
- Trepanowski JF et al. ADF. *JAMA Intern Med* 2017. [PubMed 28459931](https://pubmed.ncbi.nlm.nih.gov/28459931/)

**Body composition**
- NICE NG246 §1.9 (BMI, WHtR, ethnicity thresholds). [NICE](https://www.nice.org.uk/guidance/ng246/chapter/Identifying-and-assessing-overweight-obesity-and-central-adiposity)
- Ashwell M et al. WHtR meta-analysis (flagged). *Obes Rev* 2012. [PubMed 22106927](https://pubmed.ncbi.nlm.nih.gov/22106927/)
- Woolcott OO, Bergman RN. RFM. *Sci Rep* 2018. [PubMed 30030479](https://pubmed.ncbi.nlm.nih.gov/30030479/)
- Frija-Masson J et al. Smart scales vs DXA. *JMIR mHealth uHealth* 2021. [PubMed 33929337](https://pubmed.ncbi.nlm.nih.gov/33929337/)

**Logging, labels, databases**
- Burke LE et al. *J Am Diet Assoc* 2011. [PubMed 21185970](https://pubmed.ncbi.nlm.nih.gov/21185970/)
- Zheng Y et al. *Obesity* 2015. [PubMed 25521523](https://pubmed.ncbi.nlm.nih.gov/25521523/)
- Patel ML et al. *Obesity* 2021. [PubMed 33624440](https://pubmed.ncbi.nlm.nih.gov/33624440/); Patel ML et al. *JMIR Form Res* 2022. [PubMed 36512404](https://pubmed.ncbi.nlm.nih.gov/36512404/)
- Harvey J et al. *Obesity* 2019. [PubMed 30801989](https://pubmed.ncbi.nlm.nih.gov/30801989/)
- Jumpertz R et al. *Obesity* 2013. [PubMed 23505182](https://pubmed.ncbi.nlm.nih.gov/23505182/)
- Urban LE et al. *JAMA* 2011. [PubMed 21771989](https://pubmed.ncbi.nlm.nih.gov/21771989/)
- European Commission. Guidance on tolerances, 2012. [PDF](https://food.ec.europa.eu/system/files/2016-10/labelling_nutrition-vitamins_minerals-guidance_tolerances_1212_en.pdf)
- US 21 CFR 101.9. [eCFR](https://www.ecfr.gov/current/title-21/chapter-I/subchapter-B/part-101/subpart-A/section-101.9)
- Regulation (EU) 1169/2011 Annex XIV [legislation.gov.uk](https://www.legislation.gov.uk/eur/2011/1169/annex/XIV), Annex I [legislation.gov.uk](https://www.legislation.gov.uk/eur/2011/1169/annex/I)
- USDA Table of Cooking Yields for Meat and Poultry, Release 2 (2014). [PDF](https://ars.usda.gov/ARSUserFiles/80400535/Data/retn/USDA_CookingYields_MeatPoultry02.pdf)
- USDA FoodData Central [site](https://fdc.nal.usda.gov/), [API/licence](https://fdc.nal.usda.gov/api-guide); Open Food Facts [data & licence](https://world.openfoodfacts.org/data); CoFID [gov.uk](https://www.gov.uk/government/publications/composition-of-foods-integrated-dataset-cofid); Ciqual [data.gouv.fr](https://www.data.gouv.fr/datasets/table-de-composition-nutritionnelle-des-aliments-ciqual/); Canadian Nutrient File [open.canada.ca](https://open.canada.ca/data/en/dataset/90a31d6a-9131-4f31-a156-cd1f3b2717fe)

**Safety**
- Simpson CC, Mazzeo SE. *Eat Behav* 2017. [PubMed 28214452](https://pubmed.ncbi.nlm.nih.gov/28214452/)
- Levinson CA et al. *Eat Behav* 2017. [PubMed 28843591](https://pubmed.ncbi.nlm.nih.gov/28843591/)
- Peckmezian T, Hay P. *J Eat Disord* 2017. [PubMed 28469914](https://pubmed.ncbi.nlm.nih.gov/28469914/)
- Jebeile H et al. *Obes Rev* 2021. [PubMed 33410207](https://pubmed.ncbi.nlm.nih.gov/33410207/)
- Golden NH et al. (AAP). *Pediatrics* 2016. [PubMed 27550979](https://pubmed.ncbi.nlm.nih.gov/27550979/)
- Hampl SE et al. (AAP CPG). *Pediatrics* 2023. [PubMed 36622115](https://pubmed.ncbi.nlm.nih.gov/36622115/)
- IOM. Weight gain during pregnancy, 2009. [PubMed 20669500](https://pubmed.ncbi.nlm.nih.gov/20669500/)
- Lovelady CA et al. *N Engl J Med* 2000. [PubMed 10675424](https://pubmed.ncbi.nlm.nih.gov/10675424/)
- Mountjoy M et al. IOC REDs 2023. *Br J Sports Med* 2023. [PubMed 37752011](https://pubmed.ncbi.nlm.nih.gov/37752011/)
- Morgan JF et al. SCOFF. *BMJ* 1999. [PubMed 10582927](https://pubmed.ncbi.nlm.nih.gov/10582927/)
- NICE NG69 Eating disorders. [NICE](https://www.nice.org.uk/guidance/ng69)
- Gaddey HL, Holder KK. Unintentional weight loss. *Am Fam Physician* 2021. [PubMed 34264616](https://pubmed.ncbi.nlm.nih.gov/34264616/)
