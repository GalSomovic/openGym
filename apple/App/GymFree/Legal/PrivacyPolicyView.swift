import SwiftUI

enum LegalLinks {
    /// The public copy of apple/PRIVACY.md: the App Store Connect privacy-policy URL.
    static let privacyPolicy = URL(string: "https://github.com/GalSomovic/openGym/blob/native-apple/apple/PRIVACY.md")!
    static let support = URL(string: "https://github.com/GalSomovic/openGym/issues")!
}

/// The privacy policy, from the copy of apple/PRIVACY.md bundled with the app, so it reads
/// the same offline as on the web (App Review 5.1.1(i): "within the app in an easily
/// accessible manner"). A tiny Markdown reader: #/## headings, "- " bullets, paragraphs.
struct PrivacyPolicyView: View {
    private enum Block: Hashable { case title(String), heading(String), bullet(String), text(String) }

    private static let blocks: [Block] = {
        guard let url = Bundle.main.url(forResource: "PRIVACY", withExtension: "md"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        return text.components(separatedBy: "\n\n").flatMap { para -> [Block] in
            let lines = para.split(separator: "\n").map(String.init)
            guard let first = lines.first else { return [] }
            if first.hasPrefix("## ") { return [.heading(String(first.dropFirst(3)))] }
            if first.hasPrefix("# ") { return [.title(String(first.dropFirst(2)))] }
            if first.hasPrefix("- ") { return lines.map { .bullet(String($0.dropFirst(2))) } }
            return [.text(lines.joined(separator: " "))]
        }
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Self.blocks, id: \.self) { block in
                    switch block {
                    case .title(let s): Text(s).font(.title2.weight(.bold))
                    case .heading(let s): Text(s).font(.headline).padding(.top, 8)
                    case .bullet(let s):
                        Label { Text(Self.inline(s)) } icon: {
                            Image(systemName: "circle.fill").font(.system(size: 5)).foregroundStyle(.secondary)
                        }
                        .labelStyle(BulletLabelStyle())
                    case .text(let s): Text(Self.inline(s))
                    }
                }
                if Self.blocks.isEmpty {
                    Link("Read the privacy policy online", destination: LegalLinks.privacyPolicy)
                }
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle("Privacy policy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                ShareLink(item: LegalLinks.privacyPolicy) { Image(systemName: "square.and.arrow.up") }
                    .accessibilityLabel("Share the privacy policy link")
            }
        }
    }

    /// Bold and links, as written in the Markdown file.
    private static func inline(_ s: String) -> AttributedString {
        (try? AttributedString(markdown: s, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(s)
    }
}
