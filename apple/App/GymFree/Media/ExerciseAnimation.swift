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
/// plays on a tap. `toggle` shows the GymFree / Classic switch when both exist.
struct ExerciseAnimation: View {
    let exerciseId: String
    var animated = true
    var toggle = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var still: UIImage?
    @State private var loop: UIImage?
    @State private var playRequested = false
    @State private var style: AnimationStyle = .classic

    private var playing: Bool { animated && (!reduceMotion || playRequested) }
    private var both: Bool { AnimationStyle.has(exerciseId) && ExerciseMedia.url(exerciseId) != nil }

    var body: some View {
        ZStack {
            if style == .gymfree {
                animationStage
                LottieView(animation: .named(exerciseId, bundle: .main, subdirectory: "Animations"))
                    .playbackMode(playing ? .playing(.fromProgress(0, toProgress: 1, loopMode: .loop)) : .paused(at: .progress(0)))
                    .resizable()
                    .scaledToFit()
            } else {
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
            if animated, reduceMotion, !playRequested {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 44))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.55))
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .contentShape(Rectangle())
        .overlay(alignment: .bottomLeading) {
            if toggle && both { styleToggle.padding(8) }
        }
        .onTapGesture { if animated, reduceMotion { playRequested.toggle() } }
        .task(id: exerciseId) {
            style = AnimationStyle.resolved(for: exerciseId)
            guard style == .classic else { return }
            still = await GIFStore.shared.still(exerciseId)
            if animated { loop = await GIFStore.shared.loop(exerciseId) }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Exercise demonstration"))
    }

    private var styleToggle: some View {
        HStack(spacing: 0) {
            ForEach([AnimationStyle.gymfree, .classic], id: \.self) { s in
                Button {
                    AnimationStyle.set(s, for: exerciseId)
                    withAnimation(.snappy) { style = s }
                    if s == .classic, loop == nil {
                        Task {
                            still = await GIFStore.shared.still(exerciseId)
                            if animated { loop = await GIFStore.shared.loop(exerciseId) }
                        }
                    }
                } label: {
                    Text(s == .gymfree ? "GymFree" : "Classic")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 9).padding(.vertical, 5)
                        .foregroundStyle(style == s ? Color.black : Color.white)
                        .background(style == s ? Color.accentColor : Color.clear, in: .capsule)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(style == s ? .isSelected : [])
            }
        }
        .padding(2)
        .background(.black.opacity(0.55), in: .capsule)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Animation style"))
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
