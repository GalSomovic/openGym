import AVFoundation
import ImageIO
import Lottie
import SwiftUI
import UIKit

/// The ExerciseDB animations bundled with the app (apple/core/fetch-media.sh). Nothing is
/// downloaded at run time.
enum ExerciseMedia {
    static func url(_ exerciseId: String) -> URL? {
        Bundle.main.url(forResource: exerciseId, withExtension: "gif", subdirectory: "ExerciseGIFs")
    }

    static let credit = String(localized: "Exercise animations © AscendAPI (ExerciseDB)")
}

/// Decodes and caches the animations: a still first frame for lists, the whole loop for the
/// demo itself.
final class GIFStore: @unchecked Sendable {
    static let shared = GIFStore()
    private let stills = NSCache<NSString, UIImage>()
    private let loops = NSCache<NSString, UIImage>()

    private init() { loops.countLimit = 24 }

    func still(_ id: String) async -> UIImage? {
        if let hit = stills.object(forKey: id as NSString) { return hit }
        guard let url = ExerciseMedia.url(id) else { return nil }
        let image = await Task.detached(priority: .userInitiated) { () -> UIImage? in
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                  let frame = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
            return UIImage(cgImage: frame)
        }.value
        if let image { stills.setObject(image, forKey: id as NSString) }
        return image
    }

    func loop(_ id: String) async -> UIImage? {
        if let hit = loops.object(forKey: id as NSString) { return hit }
        guard let url = ExerciseMedia.url(id) else { return nil }
        let image = await Task.detached(priority: .userInitiated) { () -> UIImage? in
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
            let count = CGImageSourceGetCount(source)
            var frames: [UIImage] = []
            var duration = 0.0
            for i in 0..<count {
                guard let frame = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
                frames.append(UIImage(cgImage: frame))
                let props = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [CFString: Any]
                let gif = props?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
                let delay = (gif?[kCGImagePropertyGIFUnclampedDelayTime] as? Double)
                    ?? (gif?[kCGImagePropertyGIFDelayTime] as? Double) ?? 0.1
                duration += delay < 0.02 ? 0.1 : delay
            }
            return frames.count > 1 ? UIImage.animatedImage(with: frames, duration: duration) : frames.first
        }.value
        if let image { loops.setObject(image, forKey: id as NSString) }
        return image
    }
}

/// Which demo an exercise shows: GymFree's own animation where one exists, or the classic
/// ExerciseDB GIF. A global choice in Settings, overridden per exercise by the toggle on the demo.
enum AnimationStyle: String {
    case gymfree, classic

    static let defaultKey = "gf.animStyle"
    static let overridesKey = "gf.animOverrides"

    static func has(_ id: String) -> Bool {
        Bundle.main.url(forResource: id, withExtension: "json", subdirectory: "Animations") != nil
    }

    static func resolved(for id: String) -> AnimationStyle {
        let hasOwn = has(id), hasGIF = ExerciseMedia.url(id) != nil
        if !hasOwn { return .classic }
        if !hasGIF { return .gymfree }
        let overrides = UserDefaults.standard.dictionary(forKey: overridesKey) as? [String: String] ?? [:]
        let pick = overrides[id] ?? UserDefaults.standard.string(forKey: defaultKey) ?? AnimationStyle.gymfree.rawValue
        return AnimationStyle(rawValue: pick) ?? .gymfree
    }

    static func set(_ style: AnimationStyle, for id: String) {
        var overrides = UserDefaults.standard.dictionary(forKey: overridesKey) as? [String: String] ?? [:]
        overrides[id] = style.rawValue
        UserDefaults.standard.set(overrides, forKey: overridesKey)
    }
}

/// The dark stage GymFree's figures are drawn for, in light and dark mode alike.
let animationStage = Color(red: 0.106, green: 0.122, blue: 0.141)

/// An exercise's demo. Plays on its own unless Reduce Motion is on; then it holds still and
/// plays on a tap. `toggle` adds the switcher that cycles through every version available:
/// free real footage, the classic animation, illustrations, GymFree's own animation.
struct ExerciseAnimation: View {
    let exerciseId: String
    var animated = true
    var toggle = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var still: UIImage?
    @State private var loop: UIImage?
    @State private var poster: UIImage?
    @State private var playRequested = false
    @State private var options: [MediaOption] = []
    @State private var index = 0

    private var playing: Bool { animated && (!reduceMotion || playRequested) }
    private var current: MediaOption? { options[safe: index] }

    var body: some View {
        ZStack {
            content
            if animated, reduceMotion, !playRequested {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 44))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.55))
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) {
            if toggle, let current { switcher(current) }
        }
        .onTapGesture { if animated, reduceMotion { playRequested.toggle() } }
        .task(id: exerciseId) {
            options = MediaLibrary.options(for: exerciseId)
            index = MediaLibrary.chosen(for: exerciseId, in: options)
            await prepare()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Exercise demonstration"))
    }

    @ViewBuilder
    private var content: some View {
        switch current?.kind {
        case .gymfree:
            ZStack {
                animationStage
                LottieView(animation: .named(exerciseId, bundle: .main, subdirectory: "Animations"))
                    .playbackMode(playing ? .playing(.fromProgress(0, toProgress: 1, loopMode: .loop)) : .paused(at: .progress(0)))
                    .resizable()
                    .scaledToFit()
            }
        case .video(let url):
            if animated {
                LoopingVideo(url: url, playing: playing)
            } else {
                ZStack { Color.black; if let poster { Image(uiImage: poster).resizable().scaledToFit() } }
            }
        case .frames(let urls):
            FrameSequence(urls: animated ? urls : Array(urls.prefix(1)), playing: playing)
        case .classic, nil:
            ZStack {
                Color.white
                if playing, let loop {
                    AnimatedImageView(image: loop)
                } else if let still {
                    Image(uiImage: still).resizable().scaledToFit()
                } else if ExerciseMedia.url(exerciseId) == nil {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func switcher(_ option: MediaOption) -> some View {
        VStack(spacing: 3) {
            if options.count > 1 {
                HStack(spacing: 6) {
                    Button { step(-1) } label: { Image(systemName: "chevron.backward").frame(width: 30, height: 26) }
                        .accessibilityLabel(Text("Previous version"))
                    Text("\(option.label)  \(index + 1)/\(options.count)")
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                    Button { step(1) } label: { Image(systemName: "chevron.forward").frame(width: 30, height: 26) }
                        .accessibilityLabel(Text("Next version"))
                }
            }
            if let credit = option.credit, !credit.isEmpty {
                Text(credit).font(.system(size: 9)).lineLimit(2).multilineTextAlignment(.center).opacity(0.85)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8).padding(.vertical, 6)
        .background(.black.opacity(0.55), in: .rect(cornerRadius: 12))
        .padding(8)
    }

    private func step(_ d: Int) {
        guard !options.isEmpty else { return }
        index = (index + d + options.count) % options.count
        if let o = current { MediaLibrary.choose(o, for: exerciseId) }
        Task { await prepare() }
    }

    private func prepare() async {
        switch current?.kind {
        case .classic:
            still = await GIFStore.shared.still(exerciseId)
            if animated { loop = await GIFStore.shared.loop(exerciseId) }
        case .video(let url) where !animated:
            poster = await VideoPosters.shared.poster(url)
        default:
            break
        }
    }
}

/// First frames of the free videos, for list thumbnails.
final class VideoPosters: @unchecked Sendable {
    static let shared = VideoPosters()
    private let cache = NSCache<NSURL, UIImage>()

    func poster(_ url: URL) async -> UIImage? {
        if let hit = cache.object(forKey: url as NSURL) { return hit }
        let gen = AVAssetImageGenerator(asset: AVURLAsset(url: url))
        gen.appliesPreferredTrackTransform = true
        gen.maximumSize = CGSize(width: 240, height: 240)
        guard let cg = try? await gen.image(at: CMTime(seconds: 0.5, preferredTimescale: 600)).image else { return nil }
        let image = UIImage(cgImage: cg)
        cache.setObject(image, forKey: url as NSURL)
        return image
    }
}

private struct AnimatedImageView: UIViewRepresentable {
    let image: UIImage

    func makeUIView(context: Context) -> UIImageView {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return view
    }

    func updateUIView(_ view: UIImageView, context: Context) {
        if view.image !== image { view.image = image }
    }
}

/// The small still used in lists.
struct ExerciseThumb: View {
    let exerciseId: String
    var size: CGFloat = 52

    var body: some View {
        ExerciseAnimation(exerciseId: exerciseId, animated: false)
            .frame(width: size, height: size)
            .clipShape(.rect(cornerRadius: size * 0.22))
    }
}
