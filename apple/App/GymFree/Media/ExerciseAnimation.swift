import ImageIO
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

/// An exercise's demo. Plays on its own unless Reduce Motion is on; then it shows the first
/// frame and plays on a tap.
struct ExerciseAnimation: View {
    let exerciseId: String
    var animated = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var still: UIImage?
    @State private var loop: UIImage?
    @State private var playRequested = false

    private var playing: Bool { animated && (!reduceMotion || playRequested) }

    var body: some View {
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
            if animated, reduceMotion, !playRequested {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 44))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.55))
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .contentShape(Rectangle())
        .onTapGesture { if animated, reduceMotion { playRequested.toggle() } }
        .task(id: exerciseId) {
            still = await GIFStore.shared.still(exerciseId)
            if animated { loop = await GIFStore.shared.loop(exerciseId) }
        }
        .accessibilityElement()
        .accessibilityLabel(Text("Exercise demonstration"))
        .accessibilityAddTraits(.isImage)
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
