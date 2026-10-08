import SwiftUI

/// Every third-party source GymFree uses, the terms it is used under, and the authoritative
/// text of each. Researched and checked on 2026-10-08; see apple/research/COMPLIANCE.md §9.
extension LegalLinks {
    static let checked = "8 October 2026"

    // GymFree and openGym (AGPL-3.0-or-later).
    static let sourceCode = URL(string: "https://github.com/GalSomovic/openGym/tree/native-apple")!
    static let commits = URL(string: "https://github.com/GalSomovic/openGym/commits/native-apple")!
    static let openGym = URL(string: "https://github.com/DuarteSantos8/openGym")!
    static let openGymNotice = URL(string: "https://github.com/DuarteSantos8/openGym/blob/main/NOTICE.md")!
    static let agpl = URL(string: "https://www.gnu.org/licenses/agpl-3.0.html")!
    static let appleEULA = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    // Licence deeds.
    static let ccBySA3 = URL(string: "https://creativecommons.org/licenses/by-sa/3.0/")!
    static let ccBySA4 = URL(string: "https://creativecommons.org/licenses/by-sa/4.0/")!
    static let cc0 = URL(string: "https://creativecommons.org/publicdomain/zero/1.0/")!
    static let apache2 = URL(string: "https://www.apache.org/licenses/LICENSE-2.0")!
    static let mit = URL(string: "https://opensource.org/license/mit")!

    // Sources.
    static let dvidsCopyright = URL(string: "https://www.dvidshub.net/about/copyright")!
    static let dvidsFAQ = URL(string: "https://www.dvidshub.net/about/faq")!
    static let usGovernmentWorks = URL(string: "https://www.copyright.gov/title17/92chap1.html#105")!
    static let commonsPublicDomain = usGovernmentWorks
    static let commonsReuse = URL(string: "https://commons.wikimedia.org/wiki/Commons:Reusing_content_outside_Wikimedia")!
    static let wger = URL(string: "https://wger.de")!
    static let wgerLicences = URL(string: "https://wger.de/api/v2/license/")!
    static let feeel = URL(string: "https://gitlab.com/enjoyingfoss/feeel")!
    static let feeelImageLicences = URL(string: "https://gitlab.com/enjoyingfoss/feeel/-/blob/master/assets/json_supplements/local_exercise_images.json")!
    static let pixabayLicense = URL(string: "https://pixabay.com/service/license-summary/")!
    static let pixabayTerms = URL(string: "https://pixabay.com/service/terms/")!
    static let exerciseDBTerms = URL(string: "https://oss.exercisedb.dev/docs")!
    static let ascendAPI = URL(string: "https://ascendapi.com")!
    static let exercisesDataset = URL(string: "https://github.com/hasaneyldrm/exercises-dataset")!
    static let usda = URL(string: "https://fdc.nal.usda.gov/")!
    static let muscleMap = URL(string: "https://github.com/melihcolpan/MuscleMap")!
    static let lottie = URL(string: "https://github.com/airbnb/lottie-ios")!
    static let zipFoundation = URL(string: "https://github.com/weichsel/ZIPFoundation")!
    static let epoxy = URL(string: "https://github.com/airbnb/epoxy-ios")!
    static let lruCache = URL(string: "https://github.com/nicklockwood/LRUCache")!
}

/// The disclaimer DVIDS requires of everyone who uses Department of War footage, word for word
/// (dvidshub.net/about/copyright: "All users of DoW VI must display this non-DoW endorsement
/// disclaimer").
enum Disclaimers {
    static let dvids = "The appearance of U.S. Department of War (DoW) visual information does not imply or constitute DoW endorsement."
}

/// A licence text bundled with the app (Legal/Licenses/*.txt, the root LICENSE and NOTICE.md).
struct LicenceText: Hashable {
    let title: String
    let file: String

    static let agpl = LicenceText(title: "GNU Affero General Public License v3.0", file: "LICENSE")
    static let openGymNotice = LicenceText(title: "openGym notices", file: "NOTICE.md")
    static let apache2 = LicenceText(title: "Apache License 2.0", file: "Apache-2.0.txt")
    static let muscleMap = LicenceText(title: "MuscleMap: MIT License", file: "MIT-MuscleMap.txt")
    static let exercisesDataset = LicenceText(title: "exercises-dataset: MIT License", file: "MIT-exercises-dataset.txt")
    static let zipFoundation = LicenceText(title: "ZIPFoundation: MIT License", file: "MIT-ZIPFoundation.txt")
    static let lruCache = LicenceText(title: "LRUCache: MIT License", file: "MIT-LRUCache.txt")

    var text: String? {
        let ext = (file as NSString).pathExtension
        let name = (file as NSString).deletingPathExtension
        guard let url = Bundle.main.url(forResource: name, withExtension: ext.isEmpty ? nil : ext) else { return nil }
        return try? String(contentsOf: url, encoding: .utf8)
    }
}

/// One source of content in the app and the terms it is used under.
struct ContentSource: Identifiable {
    struct Ref: Hashable {
        let title: String
        let url: URL
    }

    let id: String
    let name: String
    /// What in GymFree comes from it.
    let use: LocalizedStringResource
    /// The licence or terms, by name.
    let licence: LocalizedStringResource
    /// What the licence lets anyone do, and what it asks, in plain words.
    let summary: LocalizedStringResource
    /// What GymFree does to meet it.
    let compliance: LocalizedStringResource
    /// Wording a source requires to be shown as is.
    var quote: String? = nil
    var links: [Ref] = []
    /// A bundled full text, when the licence asks for one to ship with the app.
    var text: LicenceText? = nil
    /// The source name in FreeMedia.json, for sources credited item by item.
    var mediaSource: String? = nil

    static let all: [ContentSource] = [
        ContentSource(
            id: "dvids", name: "DVIDS (U.S. Department of War)",
            use: "Most exercise videos: fitness clips filmed by the U.S. Marine Corps, Army, Navy and Air Force, published on DVIDS.",
            licence: "Public domain (U.S. government work), under the Department's conditions of use",
            summary: "Videos made by U.S. service members as part of their duties are not protected by copyright in the United States, so anyone may use them. The Department's conditions: don't use them in a way that suggests the Department endorses any person, business, product or service; everyone who uses them must show the disclaimer below; military names and insignia are trademarks; the people shown keep their privacy and publicity rights; and credit to whoever made the footage is requested.",
            compliance: "Every clip is credited to the unit or people who filmed it and links to its DVIDS page. GymFree is free, has no ads and doesn't use the clips in advertising. Clips are trimmed, resized and have no sound. The disclaimer is shown here and in About.",
            quote: Disclaimers.dvids,
            links: [Ref(title: "DVIDS: copyright, trademark and privacy information", url: LegalLinks.dvidsCopyright),
                    Ref(title: "DVIDS: FAQ (\"Is content on DVIDS copyrighted?\")", url: LegalLinks.dvidsFAQ),
                    Ref(title: "U.S. copyright law, 17 U.S.C. § 105", url: LegalLinks.usGovernmentWorks)],
            mediaSource: "DVIDS"),
        ContentSource(
            id: "commons", name: "Wikimedia Commons",
            use: "A few exercise videos and one illustration.",
            licence: "Each file's own licence: CC BY-SA 4.0, or public domain (U.S. Army)",
            summary: "CC BY-SA lets anyone share and adapt the work, even commercially, as long as they credit the author, link to the licence, say whether they changed it, and share their changed version under the same licence. Public-domain files have no conditions.",
            compliance: "Each item shows its author and licence and says it was modified (GIFs turned into video, trimmed and resized). Its Commons page, linked from the list, has the original. GymFree's modified versions are shared under the same licence.",
            links: [Ref(title: "CC BY-SA 4.0 licence", url: LegalLinks.ccBySA4),
                    Ref(title: "Wikimedia Commons: reusing content", url: LegalLinks.commonsReuse)],
            mediaSource: "Wikimedia Commons"),
        ContentSource(
            id: "wger", name: "wger Workout Manager",
            use: "Exercise videos and drawings contributed by the wger community.",
            licence: "CC BY-SA 3.0 or CC BY-SA 4.0 (each item's own)",
            summary: "Free to share and adapt, even commercially, if you credit the author, link to the licence, say whether you changed it, and share your changed version under the same licence.",
            compliance: "Each item shows its author and licence and says it was modified (trimmed, resized, re-encoded). Licences and authors come from wger's own records for each file. GymFree's modified versions are shared under the same licence.",
            links: [Ref(title: "CC BY-SA 4.0 licence", url: LegalLinks.ccBySA4),
                    Ref(title: "CC BY-SA 3.0 licence", url: LegalLinks.ccBySA3),
                    Ref(title: "wger: licences of its exercise media", url: LegalLinks.wgerLicences),
                    Ref(title: "wger.de", url: LegalLinks.wger)],
            mediaSource: "wger"),
        ContentSource(
            id: "feeel", name: "Feeel",
            use: "Low-poly exercise pictures from the Feeel workout app.",
            licence: "CC BY-SA 4.0 (the pictures; Feeel's code, which GymFree doesn't use, is AGPL-3.0)",
            summary: "Free to share and adapt, even commercially, if you credit the author, link to the licence, say whether you changed it, and share your changed version under the same licence. Many pictures are traced from other people's photos; each credit names them.",
            compliance: "Each picture keeps Feeel's full credit, including the photo it was made from, and says it was modified (put on a dark background, resized). GymFree's modified versions are shared under the same licence.",
            links: [Ref(title: "CC BY-SA 4.0 licence", url: LegalLinks.ccBySA4),
                    Ref(title: "Feeel: credits and licence of each picture", url: LegalLinks.feeelImageLicences),
                    Ref(title: "Feeel on GitLab", url: LegalLinks.feeel)],
            mediaSource: "Feeel"),
        ContentSource(
            id: "pixabay", name: "Pixabay",
            use: "Two exercise videos.",
            licence: "Pixabay Content License",
            summary: "Free to use and change, commercially or not, without credit. Not allowed: selling or sharing the files on their own, using them in a misleading way or one that harms the people shown, using content that shows trademarks or logos, or using it as a trademark.",
            compliance: "The videos appear only inside exercise demos, never as files on their own, and their creators are credited anyway.",
            links: [Ref(title: "Pixabay Content License (summary)", url: LegalLinks.pixabayLicense),
                    Ref(title: "Pixabay terms, section 5: Content License", url: LegalLinks.pixabayTerms)],
            mediaSource: "Pixabay"),
        ContentSource(
            id: "exercisedb", name: "ExerciseDB by AscendAPI",
            use: "The \"Classic\" exercise animations, and the exercise names, muscles and instructions that openGym's catalogue is built from.",
            licence: "ExerciseDB V1 free version: non-commercial use, credit required",
            summary: "AscendAPI's terms for the free V1 dataset allow personal projects, educational tools, non-commercial apps and community fitness platforms. Commercial or monetised products need a paid plan. Credit to AscendAPI is required in any project that uses it.",
            compliance: "GymFree is free, with no ads, no in-app purchases and nothing to pay for, and credits AscendAPI on every Classic animation and in the exercise library. The animations aren't part of GymFree's public source code. The exercise text reached openGym through the exercises-dataset project, under the MIT licence below; openGym's notice explains where the media comes from.",
            links: [Ref(title: "ExerciseDB V1 terms (\"Usage Restrictions\")", url: LegalLinks.exerciseDBTerms),
                    Ref(title: "AscendAPI", url: LegalLinks.ascendAPI),
                    Ref(title: "exercises-dataset", url: LegalLinks.exercisesDataset)],
            text: .exercisesDataset),
        ContentSource(
            id: "usda", name: "USDA FoodData Central",
            use: "The food database in calories & food: about 7,700 generic foods (Foundation Foods and SR Legacy).",
            licence: "Public domain (CC0 1.0)",
            summary: "No permission is needed. USDA asks that FoodData Central be named as the source.",
            compliance: "Credited in the food search and here: U.S. Department of Agriculture, Agricultural Research Service. FoodData Central. fdc.nal.usda.gov.",
            links: [Ref(title: "FoodData Central", url: LegalLinks.usda),
                    Ref(title: "CC0 1.0", url: LegalLinks.cc0)]),
        ContentSource(
            id: "musclemap", name: "MuscleMap by Melih Colpan",
            use: "The muscle outlines in the body diagrams (through openGym).",
            licence: "MIT License",
            summary: "Free to use, change and share, as long as the copyright notice and the licence text come with it.",
            compliance: "The full licence is included in the app, below and under Open-source licences.",
            links: [Ref(title: "MuscleMap on GitHub", url: LegalLinks.muscleMap)],
            text: .muscleMap),
        ContentSource(
            id: "gymfree", name: "GymFree",
            use: "GymFree's own exercise animations and everything else in the app.",
            licence: "GNU Affero General Public License v3.0 or later",
            summary: "Free software: you may use, study, share and change it. If you share it, changed or not, you must share its source under the same licence.",
            compliance: "The complete source code is public; see Open-source licences.",
            links: [Ref(title: "GymFree source code", url: LegalLinks.sourceCode)],
            text: .agpl),
    ]
}

/// Settings → About → Licences & credits: each source, its licence in plain words, links to
/// the authoritative text, and, for media credited item by item, the full list.
struct LicencesView: View {
    var body: some View {
        List {
            Section {
                Text("GymFree is built from free and openly licensed work. Here is where each part comes from, the licence it is used under, what that licence asks, and what GymFree does about it. Links open the licence or terms themselves.")
                    .font(.subheadline)
            } footer: {
                Text("Licences and terms checked on \(LegalLinks.checked).")
            }
            ForEach(ContentSource.all) { source in
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(source.use).font(.subheadline)
                        Text(source.licence).font(.subheadline.weight(.semibold))
                            .accessibilityIdentifier("licences.\(source.id).licence")
                        Text(source.summary).font(.footnote)
                        Text(source.compliance).font(.footnote).foregroundStyle(.secondary)
                        if let quote = source.quote {
                            Text(verbatim: "“\(quote)”").font(.footnote.italic())
                                .accessibilityIdentifier("licences.\(source.id).quote")
                        }
                    }
                    .padding(.vertical, 4)
                    ForEach(source.links, id: \.self) { ref in
                        Link(destination: ref.url) {
                            Label(ref.title, systemImage: "safari").font(.subheadline)
                        }
                    }
                    if let text = source.text {
                        NavigationLink { LicenceTextView(licence: text) } label: {
                            Label("Full licence text", systemImage: "doc.plaintext").font(.subheadline)
                        }
                        .accessibilityIdentifier("licences.\(source.id).text")
                    }
                    if let media = source.mediaSource {
                        NavigationLink { MediaCreditsView(source: media) } label: {
                            Label("Every item: title, author, licence (\(MediaLibrary.creditCount(media)))",
                                  systemImage: "list.bullet.rectangle").font(.subheadline)
                        }
                        .accessibilityIdentifier("licences.\(source.id).items")
                    }
                } header: {
                    Text(source.name)
                }
            }
            Section {
                NavigationLink { OpenSourceLicencesView() } label: {
                    Label("Open-source licences", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                NavigationLink { LegalNoticesView() } label: {
                    Label("Terms & disclaimers", systemImage: "doc.text")
                }
            } header: {
                Text("Software")
            } footer: {
                Text("Names and logos of the organisations above belong to their owners and are used only to credit their work. None of them endorses GymFree.")
            }
        }
        .navigationTitle("Licences & credits")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// The code inside the app and its licences, each with its full text.
struct OpenSourceLicencesView: View {
    private struct Component: Identifiable {
        var id: String { name }
        let name: String
        let notice: String
        let licence: String
        let use: LocalizedStringResource
        let url: URL
        let text: LicenceText
    }

    private static let components: [Component] = [
        Component(name: "Lottie for iOS", notice: "Copyright 2018 Airbnb, Inc.", licence: "Apache License 2.0",
                  use: "Plays GymFree's exercise animations.", url: LegalLinks.lottie, text: .apache2),
        Component(name: "ZIPFoundation (inside Lottie)", notice: "Copyright (c) 2017-2025 Thomas Zoechling", licence: "MIT License",
                  use: "Part of Lottie.", url: LegalLinks.zipFoundation, text: .zipFoundation),
        Component(name: "EpoxyCore (inside Lottie)", notice: "Copyright 2018 Airbnb, Inc.", licence: "Apache License 2.0",
                  use: "Part of Lottie.", url: LegalLinks.epoxy, text: .apache2),
        Component(name: "LRUCache (inside Lottie)", notice: "Copyright (c) 2021 Nick Lockwood", licence: "MIT License",
                  use: "Part of Lottie.", url: LegalLinks.lruCache, text: .lruCache),
        Component(name: "MuscleMap", notice: "Copyright (c) 2026 Melih Colpan", licence: "MIT License",
                  use: "The muscle outlines of the body diagrams.", url: LegalLinks.muscleMap, text: .muscleMap),
        Component(name: "exercises-dataset", notice: "Copyright (c) 2026 Hasan Emir Yıldırım", licence: "MIT License (code and text; not its media)",
                  use: "The exercise names and instructions in openGym's catalogue (originally from ExerciseDB by AscendAPI).",
                  url: LegalLinks.exercisesDataset, text: .exercisesDataset),
    ]

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(verbatim: "openGym — Copyright (C) 2026 Duarte Santos").font(.subheadline.weight(.semibold))
                    Text(verbatim: "GymFree changes — Copyright (C) 2026 the GymFree contributors").font(.subheadline.weight(.semibold))
                    Text("GymFree is a modified version of openGym. It replaces openGym's web interface with a native iPhone and iPad app that runs openGym's own training engine, and adds guided workouts, exercise videos, walks with GPS, Apple Health, calories & food and more. The changes were made in 2026; the dated history of every change is public.")
                        .font(.footnote)
                    Text("This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.")
                        .font(.footnote)
                        .accessibilityIdentifier("openSource.agplNotice")
                    Text("openGym's author allows distribution through app stores as an additional permission under section 7 of the licence, provided the source code stays available under the AGPL. It is.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                NavigationLink { LicenceTextView(licence: .agpl) } label: {
                    Label("GNU AGPL v3.0: full text", systemImage: "doc.plaintext")
                }
                .accessibilityIdentifier("openSource.agpl")
                NavigationLink { LicenceTextView(licence: .openGymNotice) } label: {
                    Label("openGym notices and app-store permission", systemImage: "doc.plaintext")
                }
                Link(destination: LegalLinks.sourceCode) {
                    Label("Complete source code", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                Link(destination: LegalLinks.commits) {
                    Label("History of changes", systemImage: "clock.arrow.circlepath")
                }
                Link(destination: LegalLinks.openGym) {
                    Label("openGym by Duarte Santos", systemImage: "heart")
                }
            } header: {
                Text("GymFree and openGym: GNU AGPL v3.0 or later")
            }
            ForEach(Self.components) { c in
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(verbatim: c.notice).font(.footnote)
                        Text(verbatim: c.licence).font(.footnote.weight(.semibold))
                        Text(c.use).font(.footnote).foregroundStyle(.secondary)
                    }
                    NavigationLink { LicenceTextView(licence: c.text) } label: {
                        Label("Full licence text", systemImage: "doc.plaintext").font(.subheadline)
                    }
                    Link(destination: c.url) {
                        Label(c.url.host() == "github.com" ? "Source on GitHub" : c.url.absoluteString, systemImage: "safari").font(.subheadline)
                    }
                } header: {
                    Text(verbatim: c.name)
                }
            }
        }
        .navigationTitle("Open-source licences")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// A bundled licence, shown in full.
struct LicenceTextView: View {
    let licence: LicenceText

    var body: some View {
        ScrollView {
            Group {
                if let text = licence.text {
                    Text(verbatim: text)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .accessibilityIdentifier("licence.text")
                } else {
                    Text("This licence text is missing from the app.").foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle(Text(verbatim: licence.title))
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Settings → About → Terms & disclaimers: short, plain and honest.
struct LegalNoticesView: View {
    var body: some View {
        List {
            Section("No warranty") {
                Text("GymFree is provided \"as is\", free of charge, without warranty of any kind. This program comes with ABSOLUTELY NO WARRANTY, as set out in sections 15 and 16 of the GNU AGPL.")
                NavigationLink { LicenceTextView(licence: .agpl) } label: { Text("GNU AGPL v3.0: full text") }
            }
            Section("Health") {
                Text("GymFree gives general fitness and nutrition information, not medical advice. Check with a doctor before you start, and stop if something feels wrong. You exercise at your own risk.")
                NavigationLink { HealthSafetyView() } label: { Text("Health & safety") }
            }
            Section("Limitation of liability") {
                Text("As far as the law allows, the people who make GymFree are not liable for any injury, loss or damage that comes from using it. Nothing here takes away rights you have under the law of your country that can't be excluded.")
            }
            Section("Terms of use") {
                Text("The App Store version is licensed to you under Apple's standard licence agreement (EULA). It doesn't limit your rights under the GNU AGPL to GymFree's source code.")
                Link("Apple Standard EULA", destination: LegalLinks.appleEULA)
            }
            Section("No endorsement") {
                Text("GymFree is an independent app. It is not affiliated with, sponsored by or endorsed by the U.S. Department of War (Department of Defense), the U.S. Marine Corps, Army, Navy or Air Force, DVIDS, the U.S. Department of Agriculture, AscendAPI or ExerciseDB, wger, the Wikimedia Foundation, Feeel, Pixabay, Airbnb or Apple. It isn't an official openGym app either: it is an independent version of it.")
                Text(verbatim: Disclaimers.dvids).italic()
                    .accessibilityIdentifier("legal.dvidsDisclaimer")
            }
            Section("Trademarks") {
                Text("Names, logos, insignia and uniforms that appear in the app or its videos belong to their owners. They are shown only to credit where content comes from or because they appear in the original footage, never to suggest a connection. Apple, iPhone, iPad and Apple Health are trademarks of Apple Inc.")
            }
            Section("Contact") {
                Link("Help and feedback", destination: LegalLinks.support)
            }
        }
        .font(.subheadline)
        .navigationTitle("Terms & disclaimers")
        .navigationBarTitleDisplayMode(.inline)
    }
}
