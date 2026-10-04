# Animated calisthenics demonstrations: licensed sources for GymFree

Research date: 2026-10-04/05. Scope: web research only. No accounts, no form submissions, nothing downloaded into the repo (preview GIF/WebP frames were inspected in a temporary scratch directory only).

Legend: **[V]** verified by reading the licence/page/API myself; **[S]** secondary source (primary page blocked: 403/Cloudflare); **[I]** inference/opinion. This is not legal advice.

GymFree constraints assumed: free iOS app, no ads/IAP, code AGPL-3.0, media bundled in the app and ideally committed to the public repo; Gym visual / ExerciseDB / AscendAPI media excluded beyond the 180px files already used, and AI-derived versions of their media forbidden.

---

## 1. Bottom line

1. **No existing open source gives a complete, consistent, animated set for the target list.** The hard ones are dips, muscle-ups, L-sits, inverted/Australian rows, hollow holds, glute bridges, pistol squats, handstand push-ups and mountain climbers. No CC/CMU-grade source covers any of them as smooth animation.
2. **The only fully clean route to the whole list is to generate our own animations.** That is the procedural 2D rig already in `apple/anim/` (`rig.py` / `exercises.py` / `lottie_export.py`). Optionally inform it with open motion capture: CMU (free for all uses) for timing and joint-angle reference, HDM05 (CC BY-SA 3.0), Mesh2Motion (CC0), Cologne MoCap (CC BY 4.0). We would own the output outright and can license it however we like (e.g. CC0 or CC BY-SA 4.0) next to the AGPL code.
3. **Ready-made animated media that is genuinely licensed for both app and repo is limited to two sets.**
   - Wikimedia Commons' **Wensceslao** set: CC BY-SA 4.0, 6 relevant moves, consistent style, rotoscoped from real motion so form is accurate.
   - **Feeel**'s low-poly WebPs: CC BY-SA 4.0, about 10 relevant moves, but only 1–4 frames each.
4. **Mixamo works if we only ship renders.** It is free with no attribution and covers about 9 of our moves. Rendered output is fine; raw FBX must never enter the public repo.
5. **LottieFiles free animations are permissive on paper but weak in practice.**
   - The Lottie Simple License allows apps, modification and commercial use, with no attribution.
   - LottieFiles' own help page says you "cannot redistribute as standalone animation files", which is exactly what a public repo does.
   - The relevant content is mixed-style and covers only about 50% of the list.
   - Provenance is bad: one prolific uploader's files carry a **"Runna App"** watermark (a commercial running app), and several files are re-uploads by other accounts.
   - Use at most as bundled-only, hand-picked fillers. Don't commit them.

### Top 5 options

| # | Option | (a) bundle in free iOS app | (b) commit to public AGPL repo | (c) modify/recolour | Attribution | Coverage of target list | Rating |
|---|---|---|---|---|---|---|---|
| 1 | **Own animations from the procedural rig, informed by open mocap** (CMU, HDM05, Mesh2Motion CC0, Cologne CC BY; MakeHuman/MPFB CC0 body if going 3D) | Yes | Yes (our own work). CMU raw data also committable; HDM05 raw data committable under BY-SA | Yes | CMU courtesy credit; HDM05 BY-SA credit if its data is used | 100% (by construction) | **5** |
| 2 | **Adobe Mixamo, render-only** (MP4 / sprite / flattened Lottie) | Yes | Renders: yes [I]. Raw FBX / retargeted actions: **no** | Yes | None required | ~9 moves: push-up, burpee, jumping jacks, air squat, sit-up, bicycle/circle crunch, plank, box jump | **4** |
| 3 | **Wikimedia Commons, Wensceslao set** | Yes | Yes | Yes (stays BY-SA) | "X.gif by Wensceslao, CC BY-SA 4.0, <URL> (modified)" | Push-ups, squats, sit-ups, jumping jacks, burpees, leg raises (+ high knees, skier jacks); plank static | **3.5** |
| 4 | **Feeel exercise images** (AGPL app, media CC BY-SA 4.0) | Yes | Yes | Yes (stays BY-SA) | Per-image strings from Feeel's `local_exercise_images.json` | ~19 relevant; multi-frame (2–4): burpees, squat thrusts, mountain climbers, leg raises, pike push-ups, pistol squats, lunges, floor dips | **3** |
| 5 | **LottieFiles free (Lottie Simple License)**, curated | Yes | **Ambiguous to no.** Help page bans standalone redistribution; licence text itself is share-alike-ish | Yes (derivatives stay under LSL) | Not required (encouraged) | ~10 moves in mixed styles; none for pull-up (usable), dips (bar), muscle-up, L-sit, HSPU, pistol, inverted row, hollow hold, mountain climber | **2** |

Honourable mentions:
- **Everkinetic**: CC BY-SA, 2-frame line art, about 8 of our moves. Rating 3 for static start/end.
- **Rive Community**: CC BY 4.0 is a clean licence, but there is almost no exercise content. It is a good place to *publish or commission* a rig.
- **Fab "134 calisthenics animations" pack**: paid, render-only, with a GPL-incompatibility clause.

---

## 2. Source-by-source

### 2.1 LottieFiles: free animations
- **URL:** https://lottiefiles.com/free-animations/push-ups (site is Cloudflare-protected; I inventoried it via LottieFiles' public GraphQL API `graphql.lottiefiles.com/2022-08`, `searchPublicAnimations` / `publicAnimationsByUser`) [V].
- **Licence [V].** The Lottie Simple License (FL 9.13.21), text as mirrored by Qt's attribution pages (https://doc.qt.io/qt-6/qtlottieanimation-attribution-happy-star.html) because lottiefiles.com/page/license returns a Cloudflare challenge:
  - Grant: "Permission is hereby granted, free of charge, to any person obtaining a copy of the public animation files available for download at the LottieFiles site ("Files") to download, reproduce, modify, publish, distribute, publicly display, and publicly digitally perform such Files, including for commercial purposes, provided that any display, publication, performance, or distribution of Files must contain (and be subject to) the same terms and conditions of this license."
  - Derivatives: "Modifications to Files are deemed derivative works and must also be expressly distributed under the same terms and conditions of this license."
  - No extra restrictions: "You may not purport to impose any additional or different terms or conditions on, or apply any technical measures that restrict exercise of, the rights granted under this license."
  - Anti-scraping: "This license does not include the right to collect or compile Files from LottieFiles to replicate or develop a similar or competing service."
  - Attribution: "Use of Files without attributing the creator(s) of the Files is permitted under this license, though attribution is strongly encouraged. If attributions are included, such attributions should be visible to the end user."
- **LottieFiles' own summary [V]** (https://help.lottiefiles.com/animation-licensing-basics-): allows commercial use "in business projects, websites, and apps", modification and distribution. Restrictions: "Cannot compile or scrape animations to create a competing service", **"Cannot redistribute as standalone animation files"**, "Cannot resell the original animation files". Also: "Always check the specific license on each animation page".
- **Verdicts.**
  - (a) Bundling in the app: **yes**.
  - (b) Public repo: **ambiguous, lean no**. The licence text arguably allows distribution if the LSL travels with the files, but LottieFiles' official gloss forbids standalone files, and a repo folder of `.json` files is exactly that.
  - (c) Modify: **yes**, but derivatives must carry the LSL. So recoloured files cannot be relabelled AGPL/CC.
- **Ambiguities.**
  1. The "standalone" gloss above.
  2. The "technical measures" clause versus App Store FairPlay, the same class of issue as GPL/CC BY-SA on the App Store. [I] Low practical risk because the files aren't encrypted, but it isn't zero.
  3. **Provenance.** Uploaders aren't vetted:
     - Creator `/buixuandinh` (Dinh Bui Xuan, about 24 exercise animations, the best set) has several files with a visible **"Runna App"** logo baked into the frames (e.g. *Box Jump Exercise*, *Press up position toe tap*). Runna is a commercial running/training app, so these look like client work re-posted by the animator; whether the animator could license them is unknown.
     - Creator `/wkpc5j44yer2eqq6` ("Daksh") posts the *same* artwork under new names (his "Plank" is Dinh's "T Plank", his "squat" is "Squat Reach", his "Push up" is "Military Push Ups"), i.e. re-uploads.
     - Several good semi-realistic files (*Russian Twists*, *Deadbug*, *Bulgarian Split Squat Jump*, *Jumping Lunges*, *Plank Low To High*, *spiderman push-up*) have **no creator** (deleted account). Their provenance is unknowable.
- **What exists (calisthenics-relevant, from my API inventory; full list in Appendix A):**

  | Exercise | Best candidates | Form notes from frame inspection |
  |---|---|---|
  | Push-up | Dinh "Military Push Ups" / "Wide arm" / "Staggered"; Blinix "Push Up"; Eike Ahlers "single push up" | Dinh: straight body, chest to floor, good. Blinix: OK. saagar "Pushup": hips piked/sagging, poor |
  | Squat | Dinh "Jumping squats", "Squat kicks", "Squat Reach" (no plain squat) | Decent depth |
  | Lunge | Dinh "Lunge"; Daksh "Lunges"/"Explosive Lunges"; ownerless "Jumping Lunges" | Good |
  | Plank | Blinix "Plank" (forearm); Dinh "T Plank" (variant) | OK |
  | Burpee | Dinh "Burpee and Jump" | Good (squat thrust + jump). Oyinloluwa "Burpee" is actually alternating lunges: **mislabelled** |
  | Jumping jack | Dinh "Jumping Jack"; kmwgasj8ez | OK |
  | Crunch / sit-up | saagar "Abs crunches", Vector Fitness "Man Doing Sit Up", Dinh "Reverse Crunches" | saagar's "Man with beard doing sit up" is actually a squat: **mislabelled** |
  | Leg raise | Daksh "leg raises"; Blinix "Flutter Kicks" | OK |
  | Glute bridge | "glute-bridge" by /wjdhhm3904v23ycp (abstract stick style) | OK motion, very different style |
  | Dips | saagar "Triceps Dips" (bench/chair) only | Acceptable bench dip |
  | Pull-up | directdesign22 "Pull Ups" (front view on assisted frame), animoox (cartoon ball), Blinix (figure barely reaches a tiny bar) | **None usable** |
  | Mountain climber, pistol, HSPU, muscle-up, L-sit, inverted row, hollow hold | none found | none |

- **Style consistency:** poor across creators. Within Dinh's set it is consistent (flat vector, orange tank top, side/3⁄4 view), but even that set mixes male and female figures and backgrounds.
- **Format:** Lottie JSON / dotLottie (vector, any resolution), plus GIF/MP4 previews at 640×640.
- **Usefulness: 2/5.**

### 2.2 Adobe Mixamo (render-only route)
- **URL:** https://www.mixamo.com. FAQ at https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html, which is 403 to bots; reposted at https://community.adobe.com/t5/mixamo-discussions/mixamo-faq-licensing-royalties-ownership-eula-and-tos/m-p/13234775 [V via the repost].
- **Motions available [V]** (via Mixamo's public product-search API): `Push Up`, `Idle To Push Up`, `Push Up To Idle`, `Jump Push Up`, `Burpee` (+ `Burpee Start`/`End`), `Jumping Jacks` (+ start/stop), `Air Squat`, `Air Squat Bent Arms`, `Situps` (+ transitions), `Bicycle Crunch`, `Circle Crunch`, `Plank` (+ start/end), `Box Jump`, `Hanging Idle`, `Jump To Hang`.
- **Not available:** pull-up, dips, lunge, mountain climber, leg raise, glute bridge, pistol, HSPU, muscle-up, L-sit, inverted row, hollow hold.
- **Licence quotes [V, community repost of Adobe FAQ]:**
  - Grant: "available for free, with no licensing or royalty fees, for unlimited commercial or non commercial use."
  - Allowed uses include "Video Games… Movies/Videos, Illustrations and Prints".
  - **Not allowed:** "Any type of free distribution of character or animation raw files."
  - Credit: "Do I have to give Adobe, Mixamo, or Fuse credit in my project? No."
  - Non-profit: "Can I use Fuse and Mixamo for non-profit, commercial, research, or school projects? Yes to all."
- **Verdicts.**
  - (a) Rendered output in the app: **yes**.
  - (b) Repo: rendered MP4/PNG/flattened vector **yes [I]**; raw FBX, `.blend` with Mixamo actions, or keyframe data lifted from Mixamo **no**.
  - (c) Modify: **yes**, for our own project.
- **Ambiguity.**
  - A Lottie that is a 2D *skeletal* rig driven by Mixamo keyframes is closer to "animation raw files" than a render. Keep Mixamo-derived data out of `exercises.py`-style source.
  - AGPL "Corresponding Source" can't include the Mixamo inputs, so document renders as separately licensed assets.
  - Needs an Adobe ID, which the user must create themselves.
  - Form: commercial mocap from one generic performer, cleaned, but not coach-verified.
- **Usefulness: 4/5.**

### 2.3 Wikimedia Commons
- **URL:** https://commons.wikimedia.org (API crawl of "Animations of physical exercises", "Fitness animations" and about 24 exercise categories).
- **Best set: Wensceslao, own work, 2020 [V via API extmetadata]:**
  - Files: https://commons.wikimedia.org/wiki/File:Pushups.gif, `Squats.gif`, `Situps.gif`, `Jumpingjacks.gif`, `Burpees.gif`, `Legraises.gif` (also `High knees`, `Skierjacks`, `Touchankles`, `Jumpingrope`; `Plank.png` is static).
  - Format: 640×480 GIF, 30–100 frames, white outline on black.
  - Licence: **CC BY-SA 4.0** (`{{self|cc-by-sa-4.0}}`, source `{{own}}`).
  - **Form [V, frame inspection]:**
    - The figures are rotoscoped from real video, so motion is anatomically real.
    - Push-up: straight body, chest near floor, full lockout.
    - Squat: full depth.
    - Burpee: squat thrust and stand.
    - Leg raise: to vertical.
    - Jumping jack: fine.
    - Sit-up: small range (crunch-like).
    - Outline style is easy to recolour (single colour on black).
- **Other usable files [V]:**
  - Danielflefil: bodyweight squat, narrow push-up, pike push-up. 1080×1080 GIF, CC BY-SA 4.0.
  - Taco fleur `Burpee.gif`: real person, 320×192, CC BY-SA 4.0.
  - Extremistpullup: `Pullup.gif` (CC BY-SA 3.0); `Muscle-up.gif` and one-arm/behind-neck pull-up (public domain). About 150 px, tiny.
  - FitnessScape WebMs: pull-ups and hanging leg raises, 720p, CC BY 3.0 via YouTube-CC.
  - US Army ACFT hand-release push-up WebM and Navy BUD/S push-ups/pull-ups: public domain (US government works).
  - CDC lunge GIF: public domain, 200×292.
  - Assorted others: Zimmermanns, Frank C. Müller, VideoPlasty.
- **Verdicts:** (a) **yes**; (b) **yes**; (c) **yes** (BY-SA adaptations stay BY-SA; BY needs attribution; PD free).
- **Attribution:**
  - Template: "Pushups.gif by Wensceslao, CC BY-SA 4.0, https://commons.wikimedia.org/wiki/File:Pushups.gif, recoloured/cropped".
  - BY-SA 4.0 §3 requires creator, licence and URI, and an indication of modifications.
- **Gaps:** mountain climbers, glute bridge, pistol, HSPU, L-sit, inverted row, hollow hold and bodyweight dips have no animation. Muscle-up and pull-up exist only as tiny real-person clips.
- **Usefulness: 3.5/5** (Wensceslao for 6 moves; the rest is mixed).

### 2.4 Feeel (open-source AGPL workout app)
- **URL:** https://gitlab.com/enjoyingfoss/feeel, path `assets/exercise_images/` (53 WebPs) [V].
- **Licence [V]:**
  - App code is AGPL-3.0.
  - Every image entry in `assets/json_supplements/local_exercise_images.json` reads "Licensed under the CC BY-SA 4.0 license", with a derivation chain. For example, mountainClimbers is derived from a triangulation by kettenfett of a CC BY 3.0 photo by Dr. Greg Wells; pushUps from a Pexels photo; pullUps from a public-domain USMC photo.
  - Feeel's AGPL §7 naming/branding terms apply to app forks, not the media [I].
- **Content and quality [V, frame inspection]:**
  - Low-poly triangulated photos on a 2048×2048 canvas.
  - **Animated WebP with only 2–4 frames:** burpees (4), squat thrusts, mountain climbers (4), leg raises (2), pike push-ups (2), pistol squats (2), reverse/split lunges, floor dips (2).
  - Push-ups, squats, jumping jacks, planks, crunches and pull-ups are **single frames**.
  - It reads as a pose slideshow, not smooth motion. Form looks right because it derives from real photos.
  - Style is consistent-ish: the same low-poly treatment, but different people and outfits.
- **Verdicts:** (a) yes, (b) yes, (c) yes (BY-SA).
- **Attribution:** use Feeel's per-image strings verbatim, plus "modified" if changed.
- **Usefulness: 3/5.**

### 2.5 Everkinetic (start/end line art)
- **URL:** https://github.com/everkinetic/data [V]. GitHub licence CC-BY-SA-4.0. README: "Open data project based on http://everkinetic.com created by Greg Priday."
- The original 2010 Commons uploads (e.g. `File:Close-triceps-pushup-1.png`) are `{{cc-by-sa-3.0}}`, and wger lists them as CC-BY-SA 3.
- **Content:** 293 exercises, 538 SVG + 542 PNG start ("relaxation") and end ("tension") frames, auto-traced colour line art in a consistent style.
- **Bodyweight coverage:** push-up variants, pull-ups, chin-ups, chest/bench/triceps dips, side plank, crunches, flat-bench leg raises; mostly weighted squats and lunges.
- **Missing:** burpee, mountain climber, jumping jack, front plank, glute bridge, pistol, HSPU, muscle-up, L-sit, inverted row, hollow hold.
- **Verdicts:** (a) yes, (b) yes, (c) yes (BY-SA). Two frames only, so you would need tweening or a crossfade.
- **Attribution:** "Illustration by Everkinetic (everkinetic.com, github.com/everkinetic/data), CC BY-SA 3.0 [4.0 for modified SVGs]".
- **Usefulness: 3/5** as static start/end, not animation.

### 2.6 wger
- **URL:** https://wger.de/api/v2/exerciseimage/ and /api/v2/video/; code at https://github.com/wger-project/wger [V].
- **README:** "Application Code: AGPL-3.0-or-later; Exercise/Ingredient Data: Creative Commons (see individual entries)".
- **Per-item licence fields:** `license`, `license_author`, `license_author_url`, `license_derivative_source_url`, `author_history`, plus `is_ai_generated` and `style`. Licence ids:
  - 1 = CC-BY-SA 3
  - 2 = CC-BY-SA 4
  - 3 = CC0
  - 4 = CC-BY 4
  - 5 = ODbL
- **Content [V]:**
  - 378 images (290 BY-SA 4, 88 BY-SA 3). Only 5 GIFs, none calisthenics. 42 are flagged AI-generated.
  - 78 videos, all CC-BY-SA 4 by "Goulart", mostly gym machines, 1080p `.MOV`. Calisthenics: "Dips" (3 videos) and "Pull-ups" (1, likely the assisted-machine clip).
  - Calisthenics *photos*: push-up, pull-up, dips, plank, pistol squat, inverted rows, glute bridge. Everkinetic 2-frame art for chin-up, crunches, bench dips, leg raises.
  - Some author fields ("Athlean-X", "Workout Guru") suggest re-uploads, so vet each item.
- **Verdicts:** (a)/(b)/(c) yes per item, keeping each licence and attribution.
- **Avoid** the AI-generated items: their provenance is unknown and could be derived from excluded commercial sets.
- **Usefulness: 2/5** (good metadata, little animation).

### 2.7 yuhonas/free-exercise-db (and wrkout/exercises.json)
- **URL:** https://github.com/yuhonas/free-exercise-db [V]. Repo is marked Unlicense; 873 exercises × 2 JPGs (1,746 images, start/end).
- **Provenance [V]:**
  - The upstream wrkout CONTRIBUTING.md says the images "have been scrapped off the internet, therefore l do not own the copy right for these images and would advise against using them in comercial projects".
  - wrkout issue #305 traced them to bodybuilding.com.
  - free-exercise-db issue #2, maintainer: "I actually have no idea where the images are from or if they are royalty free".
  - Issue #13 suggests ExRx.net as a source.
- **Verdicts:** (a) **no**, (b) **no**, (c) **no** for the images. The Unlicense can't cover scraped third-party images. Text metadata only.
- **Usefulness: 0/5** for media.

### 2.8 Other GitHub datasets and apps
- **exercemus/exercises** (MIT): no media at all [V]. 0/5.
- **hitmanrepo/open-exercise-illustrations**: https://github.com/hitmanrepo/open-exercise-illustrations [V].
  - CC0-1.0. 415 exercises, 796 WebP at 768×1024 (start/end, some mid/hold frames).
  - Covers essentially the whole target list, in one consistent faceless grey mannequin.
  - But the repo was **created 2026-10-03**, has 0 stars, an anonymous owner, and its README says "AI-generated illustrations. Not reviewed by a qualified coach".
  - Licence-wise (a)/(b)/(c) are all yes.
  - **Risk [I]:** the generating references are undisclosed and could be img2img of commercial sets, *including Gym visual/ExerciseDB*, whose terms forbid AI-derived versions. Static only.
  - 2/5. Use only for internal reference poses, if at all.
- **RepDB/exercise-dataset** [V]: AI-generated start/peak illustrations. The data licence says "In-app use only" and bans republishing as a dataset, with attribution required.
  - (a) yes; (b) risky/no.
  - 2/5.
- **LibreFit** (GPL-3.0) [V]: 1,823 AI-generated WebP start/end images, named like the scraped wrkout set. The maintainer admits "a large portion of the illustrations are inaccurate or anatomically off". 1/5.
- **hasaneyldrm/exercises-dataset**: "media © Gym visual". **Excluded.**
- **Mesh2Motion** (https://github.com/Mesh2Motion/mesh2motion-app) [V]:
  - `LICENSE-CC0.MD`: "All 3d models, blend files, rigs, animations" under CC0 1.0.
  - Relevant clips: Pushup, Jumping Jacks, Crawl. Small, but fully free, including raw files.
- **AssiamahS/opengym3d** (MIT) [S via the agent]: a Blender CI pipeline (MPFB2 + Mesh2Motion CC0, Mixamo marked "app-only"). A useful reference architecture, not a media pack.
- No other F-Droid/GitHub fitness app I checked ships open-licensed exercise *animations*: Flexify, CalisthenicsMemory, valens, open-7m-workout, 7-minutes-workout-android, barebone-workout and open-exercisedb ship none.

### 2.9 Motion-capture data to drive our own renders

| Source | Relevant motions | Licence (quote, link) | (a) app | (b) repo | (c) modify | Rating |
|---|---|---|---|---|---|---|
| **CMU Graphics Lab MoCap** http://mocap.cs.cmu.edu [V] | Jumping jacks, squats, side twists (subj. 13/14 and others); "Left_Lunges"/"Lunges"; "backflips, jump onto platform, handstands, vertical pushups"; "playground – climb, pull up"; cartwheels, stretches. ASF/AMC, C3D, 120 Hz; BVH conversions exist | FAQ: "The motion capture data may be copied, modified, or redistributed without permission." Home: "This dataset of motions is free for all uses… You may include this data in commercially-sold products, but you may not resell this data directly, even in converted form." Requested credit: "The data used in this project was obtained from mocap.cs.cmu.edu. The database was created with funding from NSF EIA-0196217." | Yes | Yes (raw + renders; free redistribution is fine, *reselling* data is not) | Yes | 4 |
| **HDM05** (Univ. Bonn) resources.mpi-inf.mpg.de/HDM05 [V via Wayback; live site 403] | Workout scenes: jumping jacks, squats, standing elbow-to-knee, push-ups, sit-ups, "Indian push-ups", lying arm/leg raises, rope skipping. C3D/ASF/AMC 120 Hz, some marker noise | "licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License"; cite TR CG-2007-2 | Yes (renders = adaptations, so BY-SA) | Yes, under BY-SA | Yes (ShareAlike) | 4 |
| **Mesh2Motion** [V] | Pushup, Jumping Jacks | CC0 | Yes | Yes | Yes | 2 |
| **Cologne MoCap DB** (TH Köln) https://mocap.web.th-koeln.de/about.php [V] | Contents not enumerated (search is WebGL; filters mention jumping jack / sport) | "The motion data files (BVH and C3D formats) and the annotations … are licensed under a Creative Commons Attribution 4.0 International License." | Yes | Yes | Yes | 2 (unverified content) |
| **OpenCap / OpenSim** https://simtk.org/projects/opencap [V via agent] | Squats, sit-to-stand, drop jumps | Apache-2.0 use agreement | Yes | Yes | Yes | 2 |
| **Mixamo** | see 2.2 | see 2.2 | Renders yes | Raw no | Yes | 4 (render-only) |
| **Fit3D** https://fit3d.imar.ro/legal [V via agent] | 37+ fitness exercises incl. push-ups (best fitness content anywhere) | "sole purpose of performing non-commercial scientific research, non-commercial education, or non-commercial artistic projects… shall not be copied, shared, distributed" | No | No | Internal | 1 (worth emailing licenses@imar.ro for an open-source exception) |
| **AMASS / SMPL** amass.is.tue.mpg.de/license.html [V via agent] | Re-processed CMU/HDM05/KIT etc. | Non-commercial *research/education/artistic*; "may not be reproduced, modified and/or made available in any form to any third party" | No | No | Internal | 1 |
| Motion-X, HumanML3D/KIT-ML, BEAT, Bandai Namco, SFU, AIST++, 100STYLE [V via agent] | Mostly no calisthenics | NC / research-only (Motion-X BY-NC-SA; Bandai Namco BY-NC; SFU "free for research purposes"), or CC BY with irrelevant content (100STYLE, AIST++ annotations) | No / irrelevant | No | — | 1 |
| ActorCore, MoCap Online, Rokoko, Unity Asset Store, Fab [V/S via agent] | Fab has a "134 calisthenics exercise animations" paid pack [S] | Renders allowed; raw redistribution banned. **Fab Standard License also bans combining Content with GPL / CC BY-SA-licensed material** | Renders yes | Raw no; Fab+AGPL questionable | Yes | 1–3 |
| **Sketchfab "CC-BY" Push Up / Burpee / Jumping Jacks uploads** [V via agent] | Many | Labelled CC BY, but names match Mixamo exactly and one says "animation provided by Mixamo". Uploaders can't relicense Mixamo | Do not rely | No | — | 0 |

**Body/character for 3D renders:**
- **MakeHuman / MPFB2.** Exports from an official, unmodified build may be used under CC0. Per the MakeHuman FAQ ("What changed regarding the license in 2020?", static.makehumancommunity.org), the AGPL-licensed output gets a CC0 option. Third-party community clothes/assets carry their own licences.
- **Quaternius / Kenney.** Characters and rigs are CC0 (no exercise motions).

### 2.10 Icon/illustration libraries (free tiers)

| Library | Key terms [V unless noted] | (a) | (b) | (c) | Rating |
|---|---|---|---|---|---|
| Lordicon | Free tier requires attribution; based on CC BY-ND 4.0 [I/S] | With credit | No | **No** (ND) | 0 |
| Flaticon / Freepik (Freepik terms now at magnific.com) | Use "conditioned upon… duly attributed"; no use "in a database, archive or … collection, set of clips, or library, for distribution"; Flaticon page 403 [S] | With credit | No | Limited | 0.5 |
| Storyset | Credit required; no inclusion in a library "for distribution or resale" | With credit | No | Yes | 0.5 |
| IconScout | Free assets need contributor credit; licence page 403 [S] | With credit | Likely no | ? | 0.5 |
| Icons8 (Ouch!) | Free tier needs a visible link; bans distribution allowing extraction "as stand-alone files" | With link | No | ? | 0 |
| unDraw | Free, no attribution; bans distributing assets "in packs" | Yes | No | Yes | 0.5 (static anyway) |
| Open Peeps / Humaaans | CC0 | Yes | Yes | Yes | 1.5 (static parts; could seed our own rig) |
| **Rive Community / Marketplace** | "Marketplace files are all shared under a CC BY license" (CC BY 4.0), per https://rive.app/docs/community/marketplace-overview | Yes | Yes | Yes | 2 (clean licence, almost no exercise content; e.g. "Rive Exercise 1" is a practice piece) |

### 2.11 Stock video/GIF sites

| Site | Terms [V] | Verdict |
|---|---|---|
| Pixabay | "download, use, copy, modify or adapt… commercial or non-commercial"; but "You cannot sell or distribute the Content… on a Standalone basis" | (a) probably OK; (b) risky (raw clips in repo = standalone); real-person footage, inconsistent. 1.5 |
| Pexels | "free to use", no attribution; "Don't redistribute… on other stock photo or wallpaper platforms" | (a) yes; (b) grey area. 2 |
| Coverr / Mixkit | No resale/competing service; Coverr bans "mobile apps builders"; Mixkit licence partly JS-only | (a) yes; (b) risky. 1 |
| Giphy | No reuse licence | No. 0 |

---

## 3. Cross-cutting legal notes

1. **Keep media licences separate from the AGPL code.** Add a REUSE-style `LICENSES/` folder or `apple/Media/ATTRIBUTION.md` listing every file's source, author, licence and modifications. Add an in-app Credits screen.
   - CC BY-SA media stays BY-SA as a separate work. It doesn't need to be AGPL and doesn't affect the code.
   - CC BY-SA 4.0 is one-way compatible with GPLv3, which only matters if media were merged into code.
2. **App Store versus "no technological measures" clauses.** CC BY-SA 3.0/4.0 and the Lottie Simple License both forbid applying technical measures that restrict the licensed rights. [I] Risk is low: FairPlay encrypts the executable, not bundled resources, and the same files are freely available in the public repo. It's the same class of question the AGPL app itself already faces on the App Store. Mention it in the attribution file.
3. **"Non-commercial" ≠ "research-only".** A free, ad-free app can plausibly be "non-commercial" under CC NC, but MPI/Fit3D/SFU grants are *research/education/artistic* only, so they don't fit. Also, AGPL lets anyone fork and sell the app, so NC assets in the repo would trap downstream users. **Keep NC and research-only data out entirely.**
4. **Provenance beats licence labels.** LottieFiles, Sketchfab and AI-generated sets often carry permissive labels on content the uploader didn't own:
   - the Runna watermark;
   - Mixamo re-uploads labelled CC BY;
   - AI images possibly derived from Gym visual/ExerciseDB, which is explicitly forbidden by their terms.
   Prefer sources whose authorship chain is documented (Commons own-work, Feeel's derivation strings, CMU/HDM05, our own work).
5. **Mixamo-derived data must stay out of committed source.** That includes keyframes transcribed into `exercises.py`. Only renders go into the repo.
6. **Form accuracy.**
   - Best from real-motion sources: Wensceslao rotoscopes, Feeel photo derivations, CMU/HDM05 mocap.
   - Generally OK in Mixamo.
   - Variable on LottieFiles (several mislabelled or wrong-form files: "Burpee" that is lunges, "sit up" that is a squat, piked "Pushup").
   - Unverified in AI sets.

## 4. Recommended plan

1. **Primary: keep building the in-house procedural rig** (`apple/anim/`). Output is wholly ours, consistent in style, and Lottie-native.
   - Use CMU and HDM05 mocap (and Mesh2Motion CC0) purely as *reference*: project sagittal-plane joint angles and timing for push-up, squat, lunge, jumping jack, sit-up, handstand push-up and pull-up to sanity-check the procedural poses.
   - CMU even permits committing the raw clips. HDM05-derived output must be BY-SA, so use it as reference only unless BY-SA output is acceptable.
   - For moves with no open mocap (dips, muscle-up, L-sit, hollow hold, inverted row, glute bridge, pistol, mountain climber), use the constraint solver plus a coach/physio review, or self-capture via phone video with MediaPipe/FreeMoCap (own footage = own copyright).
2. **Interim placeholders (attributed, CC BY-SA 4.0):** Wensceslao Commons GIFs for push-ups, squats, sit-ups, jumping jacks, burpees and leg raises. Feeel WebPs for mountain climbers, pistol squats, pike push-ups, floor dips, lunges, plank and pull-up stills.
3. **Optional:** Mixamo renders for push-up / burpee / jumping jacks / air squat / sit-up / bicycle crunch / plank if a 3D look is wanted. Never commit the FBX.
4. **Avoid:** free-exercise-db/wrkout images, hasaneyldrm, LibreFit/hitmanrepo/wger AI images, Sketchfab "CC BY" Mixamo copies, Giphy, NC/research datasets, Freepik/Flaticon/Lordicon/Icons8/Storyset. Use LottieFiles only bundled-only and hand-vetted.
5. **Optional outreach:**
   - Email Fit3D (licenses@imar.ro) asking for an open-source exception.
   - Ask Dinh Bui Xuan (LottieFiles) whether he holds rights to the Runna-branded files before using any of them.

## 5. Attribution templates

- **CMU:** "Motion reference: CMU Graphics Lab Motion Capture Database, mocap.cs.cmu.edu (created with funding from NSF EIA-0196217)."
- **HDM05:** "Motion data from Mocap Database HDM05 (Müller, Röder, Clausen, Eberhardt, Krüger, Weber; Univ. Bonn, TR CG-2007-2), CC BY-SA 3.0."
- **Wikimedia Commons:** "Pushups.gif by Wensceslao, https://commons.wikimedia.org/wiki/File:Pushups.gif, CC BY-SA 4.0 (https://creativecommons.org/licenses/by-sa/4.0/); recoloured and cropped."
- **Feeel:** copy the string from `local_exercise_images.json`, e.g. "Mountain climbers image by kettenfett / Feeel, derived from 'Mountain Climber' by Dr. Greg Wells (CC BY 3.0), CC BY-SA 4.0; modified."
- **Everkinetic:** "Illustration by Everkinetic (everkinetic.com, github.com/everkinetic/data), CC BY-SA 3.0; modified versions CC BY-SA 4.0."
- **LottieFiles (optional but encouraged; must be user-visible if given):** "'Military Push Ups' by Dinh Bui Xuan via LottieFiles, Lottie Simple License."
- **Mixamo:** none required ("Animations: Adobe Mixamo" optional).

---

## Appendix A: LottieFiles inventory (via public API, 2026-10-04)

**Dinh Bui Xuan** (`/buixuandinh`, 32 public files, about 24 exercise files; some carry a "Runna App" logo):
- *Burpee and Jump Exercise*: https://lottiefiles.com/animations/burpee-and-jump-exercise-gCOcxxnr1X
- *Military Push Ups*: https://lottiefiles.com/animations/military-push-ups-sFmjfnsBQ9
- *Wide_arm_push_up*: https://lottiefiles.com/animations/wide-arm-push-up-KD96z4DT4Y
- *Staggered_push_ups*: https://lottiefiles.com/animations/staggered-push-ups-zgWfOIvx3C
- *Jumping Jack*: https://lottiefiles.com/animations/jumping-jack-Q3NN7cRkd4
- *Jumping_squats*: https://lottiefiles.com/animations/jumping-squats-9hzVV8Ohi6
- *Lunge*: https://lottiefiles.com/animations/lunge-Ls3pMlE0a0
- *Split Jump Exercise*: https://lottiefiles.com/animations/split-jump-exercise-AHHpx1bumx
- *T Plank Exercise*: https://lottiefiles.com/animations/t-plank-exercise-g5qVU6RPYY
- *Press up position toe tap* (Runna logo): https://lottiefiles.com/animations/press-up-postion-toe-tap-KunqnEdK18
- *Box Jump Exercise* (Runna logo): https://lottiefiles.com/animations/box-jump-exercise-dbDFpRb3Go
- *Inchworm*: https://lottiefiles.com/animations/inchworm-oMKbWGAaDD
- *Reverse Crunches*: https://lottiefiles.com/animations/reverse-crunches-79P2FMTS7Z
- Also Squat kicks, Squat Reach, Cobras, Seated abs circles, Step Up On Chair, Single Leg Hip Rotation, Frog Press, Punches, Shoulder Stretch.

**Daksh** (`/wkpc5j44yer2eqq6`, 7 files, partly re-uploads of Dinh's artwork): Plank, Explosive Lunges, jumping jacks, squat, Lunges, Push up, leg raises.

**saagar shrestha** (`/saagarshrest`, consistent bearded-man style): Lunges, Side plank, Pushup (poor form), Triceps Dips (chair), Abs crunches, Push up with beard, "Man with beard doing sit up" (actually a squat), Wall sitting, Leg Up, High Stepping, Chair stand.

**Blinix Solutions** (`/blinixsolutions`): Push Up, Plank, Flutter Kicks, Pull ups (poor), plus gym moves.

**Vector Fitness Exercises** (`/vectorfitexercises`): 16 mostly gym (barbell/cable/dumbbell) moves plus "Man Doing Sit Up Exercise for ABS".

**Ownerless (deleted account), semi-realistic consistent style:** Russian Twists, Deadbug fitness exercise, Bulgarian Split Squat Jump (Right), Jumping Lunges, Plank Low To High, spiderman push-up, Side Hip Abduction.

**Searches with no relevant free result:** mountain climber(s), pistol squat, handstand, muscle up, L-sit, inverted row, hollow hold, pike push up, chin up, calf raise, bear crawl.
