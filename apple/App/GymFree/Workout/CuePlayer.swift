import AVFoundation
import UIKit

/// Chimes and spoken cues that play over whatever music is already going. The audio session
/// is only active while a cue sounds: `.playback` with `.mixWithOthers` and `.duckOthers`
/// lowers the other app's music instead of stopping it, and deactivating with
/// `.notifyOthersOnDeactivation` brings it straight back up.
@MainActor
final class CuePlayer: NSObject, AVSpeechSynthesizerDelegate {
    /// openGym's `sound` setting.
    var enabled = true
    /// Speak cues ("Rest over", "Set 2 of 4") as well as chiming.
    var voice = true

    private let engine = AVAudioEngine()
    private let node = AVAudioPlayerNode()
    /// The engine is wired on the first chime, not at launch: touching the audio graph at launch
    /// blocks on the system audio service, and a stuck service would take the whole app down.
    private var wired = false
    private let speech = AVSpeechSynthesizer()
    private var pending = 0
    private var releaseTask: Task<Void, Never>?

    override init() {
        super.init()
        speech.delegate = self
    }

    private func wireIfNeeded() {
        guard !wired else { return }
        wired = true
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: Self.format)
    }

    private static let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!

    /// The short tick when a set is checked off.
    func tick() { tones([(1040, 0.12)]) }
    /// Rest over: three rising notes, like openGym's finish chime.
    func restOver() { tones([(880, 0.15), (1100, 0.15), (1320, 0.3)], gap: 0.03) }
    /// The last seconds of a rest or a hold.
    func countdown() { tones([(660, 0.08)]) }
    /// Workout finished.
    func finished() { tones([(880, 0.15), (1100, 0.15), (1320, 0.35)], gap: 0.03) }

    func say(_ text: String) {
        guard enabled, voice, !text.isEmpty else { return }
        guard acquire() else { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: Locale.preferredLanguages.first)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 1.05
        pending += 1
        speech.speak(utterance)
    }

    private func tones(_ notes: [(Double, Double)], gap: Double = 0.02) {
        guard enabled, acquire() else { return }
        let buffer = Self.render(notes, gap: gap)
        do {
            wireIfNeeded()
            if !engine.isRunning { try engine.start() }
            pending += 1
            node.scheduleBuffer(buffer) { [weak self] in
                Task { @MainActor in self?.done() }
            }
            node.play()
        } catch {
            release()
        }
    }

    /// Sine notes with a soft attack and release, so they do not click.
    private static func render(_ notes: [(Double, Double)], gap: Double) -> AVAudioPCMBuffer {
        let rate = format.sampleRate
        let total = notes.reduce(0) { $0 + $1.1 + gap }
        let frames = AVAudioFrameCount(total * rate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
        buffer.frameLength = frames
        let data = buffer.floatChannelData![0]
        var at = 0
        for (freq, dur) in notes {
            let n = Int(dur * rate)
            for i in 0..<n where at + i < Int(frames) {
                let t = Double(i) / rate
                let env = min(1, t / 0.01) * min(1, (dur - t) / 0.06)
                data[at + i] = Float(sin(2 * .pi * freq * t) * 0.35 * max(0, env))
            }
            at += n + Int(gap * rate)
        }
        return buffer
    }

    private func acquire() -> Bool {
        releaseTask?.cancel()
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .voicePrompt, options: [.mixWithOthers, .duckOthers])
            try session.setActive(true)
            return true
        } catch {
            return false
        }
    }

    private func done() {
        pending = max(0, pending - 1)
        if pending == 0 { release() }
    }

    /// A moment after the last cue, so back-to-back cues do not pump the music up and down.
    private func release() {
        releaseTask?.cancel()
        releaseTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled, let self, self.pending == 0 else { return }
            self.engine.pause()
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            Self.mixWithMusic()
        }
    }

    /// The app's resting audio mode: mixes with whatever music is playing and never stops it, so
    /// the silent demo videos can play over it. Set at launch and again after every cue.
    static func mixWithMusic() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.done() }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in self.done() }
    }
}
