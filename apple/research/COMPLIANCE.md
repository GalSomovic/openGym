# GymFree: App Store compliance, health notice, support resources, privacy

Researched and checked on **2026-10-05**. Every rule below links to Apple's own page. Every helpline was checked on the organisation's own website that day; the raw pages were fetched where a summary might miss a number. **Re-check the helplines and Apple's guidelines before each release**: opening hours and numbers change, and so do the guidelines.

What GymFree is, for this purpose: a free iPhone/iPad fitness app with no ads, no in-app purchases, no analytics, no accounts, no servers and no network requests. It offers workout logging and guided workouts, a plan builder with a PAR-Q-style health check, optional calorie and macro targets with a food log (gated: no targets under 18, in pregnancy or with an eating-disorder history), and body-weight tracking. Apple Health (HealthKit) read/write and GPS walk tracking are coming. All data stays on the device, plus Apple Health if the user turns it on.

---

## 1. Apple's rules that apply, and what GymFree does about each

Source: [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/).

| Guideline | What it requires | GymFree |
|---|---|---|
| **1.4.1 Medical apps** | Medical apps that could give inaccurate information get closer scrutiny. Accuracy claims about health measurements need a disclosed method, and apps should "remind users to check with a doctor in addition to using the app and before making medical decisions". | GymFree makes no measurement claims and doesn't diagnose. It shows a one-time health notice, the full notice under Settings → About → Health & safety, and "not medical advice" in the footers of the plan builder and calories & food. Calorie estimates are labelled approximate (within about 10–15% to start). |
| **1.5 Developer information** | The app and its Support URL must give an easy way to contact you. | About → "Help and feedback" opens the GitHub issues page, which is also the Support URL. The privacy policy has a contact section. |
| **2.3.6 Age rating** | Answer the age-rating questions honestly. | See §4. |
| **2.5.1 Software requirements** | Use frameworks for their intended purpose and say so in the description, e.g. "HealthKit should be used for health and fitness purposes and integrate with the Health app". | When HealthKit ships, say so in the App Store description, e.g. "Optionally saves workouts and body weight to Apple Health". |
| **2.5.4 Multitasking** | Background services only for their intended purpose (audio, location, …). | GymFree already uses background audio for spoken cues. Background location must run only during a tracked walk. |
| **5.1.1(i) Privacy policy** | A privacy-policy link in App Store Connect **and** inside the app, easy to find. It must say what is collected, how and why, how third parties protect it, retention and deletion, and how to revoke consent or ask for deletion. | `apple/PRIVACY.md` covers each point. It's bundled into the app (About → Privacy policy, and Health & safety → Privacy), with a link to the web copy. |
| **5.1.1(ii) Permission** | Get consent for any data collection, offer an easy way to withdraw it, and write clear, complete purpose strings. | GymFree collects nothing. iOS permissions (HealthKit, location) are optional and can be revoked in iOS Settings. See the purpose strings in §5. |
| **5.1.1(iii)–(iv) Minimisation and access** | Ask only for data the feature needs, and don't trick or force consent. | Location is asked for only when a walk starts, and Health only when the user turns it on. Neither is needed to train. |
| **5.1.1(v) Sign-in** | Don't require a login without significant account-based features. | There are no accounts. |
| **5.1.2(vi)** | Data from HealthKit (and similar) may not be used for marketing, advertising or use-based data mining, including by third parties. | GymFree has no ads or third parties, and its HealthKit data never leaves the device through GymFree. |
| **5.1.3(i) Health and health research** | No use or disclosure of health and fitness data for advertising, marketing or data mining. "You must disclose the specific health data that you are collecting from the device." | The privacy policy lists the data types: workouts, body weight, walking routes. The iOS Health sheet shows the exact types. **When HealthKit lands, update PRIVACY.md with the final list of read/write types.** |
| **5.1.3(ii)** | Don't write false or inaccurate data into HealthKit, and "may not store personal health information in iCloud". | Write only what the user really logged. **No GymFree iCloud sync of health data**: the roadmap's "optional iCloud sync" (apple/README.md, phase 6) would put body weight, food logs and health-check answers in iCloud, which this rule forbids. Either drop it, or exclude every health field (body weight, food, nutrition profile, health-check answers) from anything synced, and get it reviewed. iOS device backups are controlled by the user and are not app iCloud storage. |
| **5.1.3(iii)–(iv)** | Rules for health research. | Not applicable: GymFree runs no research. |
| **5.1.5 Location** | Use location only when directly relevant, and notify and get consent first. | Walk tracking only, with consent, kept on the device. |

**HealthKit, from [Protecting user privacy](https://developer.apple.com/documentation/healthkit/protecting-user-privacy):**
- Include `NSHealthShareUsageDescription` (read) and `NSHealthUpdateUsageDescription` (write), or the app crashes when it asks for access.
- Use HealthKit only for health and fitness, and make that clear in both the marketing text and the UI.
- Never use HealthKit data for advertising.
- Never disclose it to third parties without express permission, and then only to health or fitness services.
- Never sell it.
- Clearly disclose how the data is used.
- **A privacy policy is required** for any HealthKit app.
- An app can't tell when read access was denied: it just sees no data. Design for that.

**[Privacy manifest / required-reason APIs](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api):** since 1 May 2024, App Store Connect rejects uploads that use required-reason APIs without a stated reason. GymFree uses `UserDefaults` (`@AppStorage`) for its own preferences. `apple/App/GymFree/PrivacyInfo.xcprivacy` declares reason `CA92.1`, no tracking and no collected data. Lottie ships its own manifest. If file-timestamp, disk-space or boot-time APIs are added later, add their reasons too.

## 2. App Privacy "nutrition label" (App Store Connect → App Privacy)

From [App privacy details](https://developer.apple.com/app-store/app-privacy-details/):
- "Collect" means "transmitting data off the device in a way that allows you and/or your third-party partners to access it for a period longer than what is necessary to service the transmitted request in real time".
- "Data that is processed only on device is not 'collected' and does not need to be disclosed."
- Data in HealthKit stays in the user's Health store on the device, so it is not collected by the developer either.
- "You are not responsible for disclosing data collected by Apple." That covers crash reports Apple shares when the user opts in under Analytics & Improvements.

Answers:
1. **"Do you or your third-party partners collect data from this app?" → No.** The label then reads **"Data Not Collected"**.
2. **Privacy Policy URL (required, even with no data):** `https://github.com/GalSomovic/openGym/blob/native-apple/apple/PRIVACY.md`. This works once `gf-legal` is merged into `native-apple` and pushed. The in-app link `LegalLinks.privacyPolicy` uses the same URL; change both together if you host it elsewhere (for example GitHub Pages).
3. **Tracking:** none, so App Tracking Transparency is not needed.

Re-answer this if GymFree ever adds any network feature: sync, a food database lookup, crash reporting, or remote media.

## 3. Release checklist

- [ ] Merge and push so the privacy-policy URL resolves, then open it in a private browser window to check.
- [ ] App Store Connect → App Information: **Privacy Policy URL** (above). Optional: **User Privacy Choices URL** (leave empty).
- [ ] App Store Connect → version: **Support URL** = `https://github.com/GalSomovic/openGym/issues`. Make sure Issues are enabled on the fork, or use a page with a contact email.
- [ ] App Privacy: **Data Not Collected** (§2).
- [ ] Age rating: §4.
- [ ] Category: Health & Fitness (already set in project.yml as `public.app-category.healthcare-fitness`).
- [ ] Business → **Digital Services Act trader status**. Every account must declare it before submitting. A free app with no monetisation, run by an individual, is usually "not a trader"; EU users are then told that some consumer rights may not apply. ([Apple: DSA compliance](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-eu-digital-services-act-compliance-information))
- [ ] Regulated medical device declaration (App Information): **No**. GymFree is not a medical device and makes no diagnostic claims.
- [ ] Encryption: `ITSAppUsesNonExemptEncryption = NO` (already set).
- [ ] When HealthKit ships:
  - add the HealthKit capability and entitlement and the two usage strings (§5);
  - list the exact read/write types in PRIVACY.md;
  - mention Apple Health in the description;
  - offer an in-app way to stop syncing.
- [ ] When walk tracking ships:
  - `NSLocationWhenInUseUsageDescription`;
  - `UIBackgroundModes: location` only if tracking continues with the screen locked (show the blue indicator, stop updates when the walk ends);
  - no "Always" permission.
- [ ] Re-verify every helpline in `Helplines.swift` against §6 (hours especially).
- [ ] Review notes for App Review: "No account and no network. Health notice: Plan → Make me a plan, or Settings → Calories & food. Health & safety: Settings → About GymFree → Health & safety."

## 4. Age rating answers

From [Age ratings values and definitions](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions) and [Age ratings](https://developer.apple.com/help/app-store-connect/reference/age-ratings), as of 2025: the tiers are 4+, 9+, 13+, 16+ and 18+.

- **Health or Wellness Topics**: "self-care or lifestyle recommendations. May include: calorie tracking, dieting advice, or exercise recommendations." → **Yes**. On its own this puts an app at **9+**.
- **Medical or Treatment Information**: "diagnoses or guidance around the management of medical conditions … medication guidance, emergency medical care, or treatment information." → **None**. GymFree doesn't diagnose or manage conditions; the health check only makes plans gentler and points people to a doctor. Answering "Infrequent" would give 13+, and "Frequent" 16+.
- Unrestricted web access: **No**. Links open Safari; there is no in-app browser.
- User-generated content, messaging, advertising, social media, gambling, contests, loot boxes: **No**.
- Mature themes, violence, sexuality: **None**.
- Parental controls and age assurance: **No**.

Expected result: **9+**. A conservative override to 13+ is reasonable, because calorie targets are not offered to under-18s anyway.

## 5. Usage strings to add later (draft)

- `NSHealthShareUsageDescription`: "GymFree reads your body weight and workouts from Apple Health to show them next to your training. Nothing leaves your iPhone."
- `NSHealthUpdateUsageDescription`: "GymFree saves the workouts, walks and body weight you log to Apple Health, so your other health apps can see them."
- `NSLocationWhenInUseUsageDescription`: "GymFree uses your location only while you track a walk, to measure its distance and route. It stays on your iPhone."
- (Existing) `NSAlarmKitUsageDescription`: already in project.yml.

## 6. Eating-disorder support resources (verified 2026-10-05)

Shown in the app by `Helpline.split(for: Locale.current.region)`: the phone's region first, then every other country, then the international directory. There are no premium-rate numbers. Freephone numbers (UK 0808, AU 1800, IT 800, NZ 0800) use national-format `tel:` links because they work only inside their country.

| Region | Service | Number | URL shown | Notes | Source checked |
|---|---|---|---|---|---|
| US | ANAD Helpline | 1-888-375-7767 | anad.org/eating-disorder-helpline | Free peer support. Mon–Fri 9am–9pm CT. | [anad.org/eating-disorder-helpline](https://anad.org/eating-disorder-helpline/) |
| US | National Alliance for Eating Disorders | (866) 662-1235 | allianceforeatingdisorders.com | Answered by therapists. Mon–Fri 9am–7pm ET. | [allianceforeatingdisorders.com](https://www.allianceforeatingdisorders.com/) |
| GB | Beat | 0808 801 0677 (England)<br>Scotland 0808 801 0432<br>Wales 0808 801 0433<br>NI 0808 801 0434 | beateatingdisorders.org.uk | Free. Mon–Fri 3pm–8pm. | [Beat helplines](https://www.beateatingdisorders.org.uk/get-information-and-support/get-help-for-myself/i-need-support-now/helplines/) |
| IE | Bodywhys | 01 210 7906 | bodywhys.ie | Volunteer-run, set sessions (morning or evening by day). | [bodywhys.ie/supports/helpline](https://www.bodywhys.ie/supports/helpline/) |
| CA | NEDIC | 1-866-633-4220 (toll-free)<br>Toronto 416-340-4156 | nedic.ca | Phone Mon–Fri (ET), plus live chat. The site's two pages disagree on weekend hours, so the app doesn't state them. | [nedic.ca](https://nedic.ca/), [nedic.ca/contact](https://nedic.ca/contact/) |
| AU | Butterfly National Helpline | 1800 33 4673 (1800 ED HOPE) | butterfly.org.au | 7 days, 8am–midnight AET. Interpreter via 131 450. | [butterfly.org.au/get-support/helpline](https://butterfly.org.au/get-support/helpline/) |
| NZ | 1737 Need to talk? | call or text 1737 | 1737.org.nz | 24/7 counsellors. A general mental-health line, included because EDANZ is for families. | [1737.org.nz](https://1737.org.nz/) |
| NZ | EDANZ | 0800 2 EDANZ (0800 233 269) | ed.org.nz | For **families and carers** only; not health professionals. | [ed.org.nz/contact-us](https://www.ed.org.nz/contact-us) |
| IL | Enosh – Eating Disorders Information Centre (אנוש – מרכז המידע להפרעות אכילה) | 074-7556155 (also *5873) | enosh.org.il/he/eating-disorders | Hebrew. Sun–Thu 08:00–15:30. Not an emergency line. The `tel:` link uses the 074 number because iOS won't dial `*` codes from links. | [enosh.org.il](https://www.enosh.org.il/he/eating-disorders/) |
| IL | ERAN (ער״ן) emotional first aid | 1201 | eran.org.il | 24/7, anonymous. Hebrew, Arabic, English, Russian, Amharic. General emotional support. | [eran.org.il](https://www.eran.org.il/) |
| DE | BIÖG Telefonberatung Essstörungen (formerly BZgA) | 0221 892031 | essstoerungen.bioeg.de | Mon–Thu 10–22, Fri–Sun 10–18. Normal call rate to Cologne. The BZgA was renamed BIÖG in 2025; the old bzga-essstoerungen.de domain is gone. | [essstoerungen.bioeg.de](https://essstoerungen.bioeg.de/) |
| FR | Anorexie Boulimie Info Écoute (FFAB) | 09 69 325 900 | ffab.fr | Normal rate. Mon, Tue, Thu, Fri 16–18. The old **0810 037 037** is a surcharged number (€0.06/min) that FFAB replaced in May 2023; **don't use it**. | [ffab.fr permanence téléphonique](https://www.ffab.fr/trouver-de-l-aide/permanence-telephonique) |
| ES | ACAB (Associació contra l'Anorèxia i la Bulímia) | 93 454 91 09 | acab.org | Barcelona-based, not national. Mon–Thu 10–13 and 16–19, Fri 10–13. Normal rate. | [acab.org](https://www.acab.org/) |
| IT | SOS Disturbi Alimentari – Numero Verde | 800 180 969 | sosdisturbialimentari.it | Freephone, Mon–Fri 9–21. Set up by the Presidenza del Consiglio and the ISS; run within USL Umbria 1. | [sosdisturbialimentari.it](https://sosdisturbialimentari.it/) |
| NL | Proud2Bme | (web chat, no phone) | proud2bme.nl | Chat daily 19:00–21:00, plus a forum. | [proud2bme.nl](https://www.proud2bme.nl/) |
| Any | Find A Helpline (ThroughLine) | — | findahelpline.com | Free directory with an "Eating & body image" topic filter. | [findahelpline.com](https://findahelpline.com/), [example topic page](https://findahelpline.com/countries/fr/topics/eating-body-image) |

**Dropped or not used:**
- **NEDA (US):** its helpline closed in 2023 and the replacement chatbot was withdrawn. The NEDA site lists no helpline now, and it is a separate organisation from the National Alliance.
- **Netherlands phone lines:**
  - WEET: the site didn't load, and the number appeared only in a 2021 PDF.
  - MIND Hulplijn 0900 1450: the site returned 403, and 0900 numbers are normally premium-rate.
  - Ixta Noa lists locations only, with no helpline.
- **Spain:**
  - ADANER Madrid: seen only in search snippets.
  - Fundación ANAR: a children's line, not specific to eating disorders, and not verified.
  - Línea 024 (Ministerio de Sanidad, 24/7 crisis): verified, but it is a general crisis line, so it was left out as out of scope.
- **Israel:** no current "Ahat" or "Mivaz" helpline was found. The Israeli Association of Eating Disorders is a professional body with no helpline.

**Wording rules** (NUTRITION.md §10):
- Neutral and kind, with no alarm language.
- "Support", not "treatment".
- The eating-disorder support always sits one tap from:
  - the calories & food stop screen ("Support and helplines");
  - the calories & food health-check footer;
  - the plan builder health check;
  - About.

## 7. Health notice: what, where, why

**Text** (`HealthNotice.points`), modelled on PAR-Q+ guidance ([eparmedx.com](https://eparmedx.com/), 2025 edition), the ACSM 2015 screening update ([Riebe 2015](https://pubmed.ncbi.nlm.nih.gov/26473759/)), the stop-and-seek-care symptoms in TRAINING.md §8.1, and the disclaimer in NUTRITION.md §10.7, written in plain words rather than legalese:
1. General fitness and nutrition information, not medical advice; doesn't diagnose or treat.
2. Check with a doctor before starting exercise or changing diet, especially with a condition, medicine, pregnancy or recent birth, or a history of an eating disorder.
3. Stop and get help for chest pain or pressure, faintness or dizziness, unusual breathlessness, a racing or irregular heartbeat, or sharp pain.
4. It doesn't replace a professional who knows you.

**When it is shown:** once per install, the first time the user opens the **plan builder** or **calories & food**, whichever comes first. It is a sheet with a single OK button and can also be swiped away. Why this timing:
- These are the two features that make health-related recommendations and ask health questions, so the reminder appears where Apple's 1.4.1 "check with a doctor" applies, and is read in context rather than skipped among launch screens.
- Logging workouts and building routines, the app's basic flow, is never interrupted.
- The same text is always available in Settings → About → Health & safety, and short "not medical advice" footers stay on both features.
- In debug builds, `-GFReset YES` clears the flag (as on a fresh install) so UI tests are deterministic.

## 8. Implementation map

- `apple/App/GymFree/Legal/HealthNotice.swift`: the notice text and the one-time sheet (`.healthNoticeOnce()`).
- `apple/App/GymFree/Legal/HealthSafetyView.swift`: Settings → About → Health & safety.
- `apple/App/GymFree/Legal/Helplines.swift`: the helpline directory (§6) and the region ordering.
- `apple/App/GymFree/Legal/PrivacyPolicyView.swift`: renders the bundled `apple/PRIVACY.md`, plus the policy and support URLs.
- `apple/App/GymFree/PrivacyInfo.xcprivacy`: the privacy manifest.
- Links from About (`SettingsView.swift`), calories & food (`Nutrition.swift`: stop screen for "ed", health-check footer) and the plan builder health-check footer (`PlanBuilder.swift`).
- `apple/App/GymFreeUITests/HealthSafetyTests.swift`: covers region ordering (GB, then US), the privacy policy, the notice, and the support links from calories & food.
