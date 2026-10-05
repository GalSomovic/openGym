import AVFoundation
import SwiftUI
import UIKit

/// One way to show an exercise: the classic ExerciseDB animation, GymFree's own animation,
/// or a free, openly licensed video or picture sequence (apple/mediatools/fetch_free.py).
struct MediaOption: Identifiable, Hashable {
    enum Kind: Hashable { case classic, gymfree, video(URL), frames([URL]) }

    let id: String
    let kind: Kind
    let source: String
    let credit: String?
    let link: URL?

    /// The label on the switcher: what it is and where it comes from.
    var label: String {
        switch kind {
        case .classic: String(localized: "Classic")
        case .gymfree: String(localized: "GymFree animation")
        case .video: String(localized: "Video · \(source)")
        case .frames: String(localized: "Illustration · \(source)")
        }
    }
}

/// The free media index (FreeMedia.json) and the choice made per exercise.
enum MediaLibrary {
    private struct Entry: Decodable {
        let id: String
        let kind: String
        let files: [String]
        let source: String
        let license: String?
        let author: String?
        let link: String?
    }

    private static let index: [String: [Entry]] = {
        guard let url = Bundle.main.url(forResource: "FreeMedia", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return [:] }
        return (try? JSONDecoder().decode([String: [Entry]].self, from: data)) ?? [:]
    }()

    private static func file(_ path: String) -> URL? {
        let name = (path as NSString).lastPathComponent
        let dir = "Free/" + (path as NSString).deletingLastPathComponent
        return Bundle.main.url(forResource: (name as NSString).deletingPathExtension,
                               withExtension: (name as NSString).pathExtension, subdirectory: dir)
    }

    /// Every option for an exercise, in the default order: real footage first (DVIDS, then the
    /// rest), then the classic animation, illustrations, and GymFree's own animation.
    static func options(for id: String) -> [MediaOption] {
        var videos: [MediaOption] = [], frames: [MediaOption] = []
        for e in index[id] ?? [] {
            let credit = [e.author, e.license].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
            let link = e.link.flatMap(URL.init(string:))
            if e.kind == "video", let url = e.files.first.flatMap(file) {
                videos.append(MediaOption(id: e.id, kind: .video(url), source: e.source, credit: credit, link: link))
            } else {
                let urls = e.files.compactMap(file)
                if !urls.isEmpty {
                    frames.append(MediaOption(id: e.id, kind: .frames(urls), source: e.source, credit: credit, link: link))
                }
            }
        }
        // DVIDS footage (US military trainers, real gyms) is the clearest, so it leads.
        let rank = ["DVIDS": 0, "Pixabay": 1, "wger": 2]
        var out = videos.enumerated()
            .sorted { (rank[$0.element.source] ?? 3, $0.offset) < (rank[$1.element.source] ?? 3, $1.offset) }
            .map(\.element)
        if ExerciseMedia.url(id) != nil {
            out.append(MediaOption(id: "classic", kind: .classic, source: "ExerciseDB", credit: ExerciseMedia.credit,
                                   link: URL(string: "https://oss.exercisedb.dev")))
        }
        out += frames
        if AnimationStyle.has(id) {
            out.append(MediaOption(id: "gymfree", kind: .gymfree, source: "GymFree", credit: String(localized: "GymFree, AGPL-3.0"), link: nil))
        }
        return out
    }

    struct Credit: Identifiable, Hashable {
        let id: String
        let title: String
        let source: String
        let credit: String
        let link: URL?
    }

    /// Every free item with its author and licence, for the credits screen.
    static var credits: [Credit] {
        var seen = Set<String>()
        var out: [Credit] = []
        for e in index.values.flatMap({ $0 }) where seen.insert(e.id).inserted {
            out.append(Credit(id: e.id, title: e.id, source: e.source,
                              credit: [e.author, e.license].compactMap { $0 }.joined(separator: " · "),
                              link: e.link.flatMap(URL.init(string:))))
        }
        return out.sorted { ($0.source, $0.id) < ($1.source, $1.id) }
    }

    private static let choiceKey = "gf.mediaChoice"

    static func chosen(for id: String, in options: [MediaOption]) -> Int {
        let saved = (UserDefaults.standard.dictionary(forKey: choiceKey) as? [String: String])?[id]
        return options.firstIndex { $0.id == saved } ?? 0
    }

    static func choose(_ option: MediaOption, for id: String) {
        var d = UserDefaults.standard.dictionary(forKey: choiceKey) as? [String: String] ?? [:]
        d[id] = option.id
        UserDefaults.standard.set(d, forKey: choiceKey)
    }
}

/// A muted video that loops forever, fitted to its box.
struct LoopingVideo: UIViewRepresentable {
    let url: URL
    var playing = true

    final class PlayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
        var looper: AVPlayerLooper?
        var url: URL?
        var playing = true

        override init(frame: CGRect) {
            super.init(frame: frame)
            // Another app's audio starting, a call, or a trip to the background can pause the
            // player; pick the loop up again so the demo never sits frozen. (Selector observers
            // are removed by the system when the view goes away.)
            let center = NotificationCenter.default
            for name in [AVAudioSession.interruptionNotification, UIApplication.didBecomeActiveNotification,
                         AVAudioSession.mediaServicesWereResetNotification] {
                center.addObserver(self, selector: #selector(resumeFromNotification), name: name, object: nil)
            }
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        @objc private func resumeFromNotification() {
            DispatchQueue.main.async { [weak self] in self?.resume() }
        }

        func resume() {
            guard playing, let player = playerLayer.player, player.timeControlStatus != .playing else { return }
            player.play()
        }
    }

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.backgroundColor = .black
        view.playerLayer.videoGravity = .resizeAspect
        return view
    }

    func updateUIView(_ view: PlayerView, context: Context) {
        if view.url != url {
            let player = AVQueuePlayer()
            player.isMuted = true
            player.audiovisualBackgroundPlaybackPolicy = .pauses
            player.preventsDisplaySleepDuringVideoPlayback = false
            view.looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(url: url))
            view.playerLayer.player = player
            view.url = url
        }
        view.playing = playing
        if playing { view.playerLayer.player?.play() } else { view.playerLayer.player?.pause() }
    }

    static func dismantleUIView(_ view: PlayerView, coordinator: ()) {
        view.playerLayer.player?.pause()
        view.looper = nil
    }
}

/// A short picture sequence (start, end, and any steps between), stepping on a beat.
struct FrameSequence: View {
    let urls: [URL]
    var playing = true
    @State private var images: [UIImage] = []

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.8)) { ctx in
            let i = images.isEmpty || !playing ? 0 : Int(ctx.date.timeIntervalSinceReferenceDate / 0.8) % images.count
            ZStack {
                Color.black
                if let im = images[safe: i] {
                    Image(uiImage: im).resizable().scaledToFit()
                        .transition(.opacity)
                        .id(i)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: i)
        }
        .task(id: urls) {
            images = urls.compactMap { UIImage(contentsOfFile: $0.path) }
        }
    }
}
