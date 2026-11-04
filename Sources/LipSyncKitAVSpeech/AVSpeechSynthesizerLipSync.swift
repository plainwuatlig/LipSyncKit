import AVFoundation
import Foundation
import LipSyncKit

/// Speaks with Apple's `AVSpeechSynthesizer` and lip-syncs to it.
///
/// Spec: `AVSpeechSynthesizer` and `AVSpeechSynthesizerDelegate` (AVFAudio),
/// https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer
///
/// Apple's voices report when each word starts (`speechSynthesizer(_:willSpeakRangeOfSpeechString:utterance:)`)
/// but no phonemes (measured on iOS 18.7 and iOS 27.2, compact, Enhanced and Premium voices alike),
/// so each word's visemes are estimated from its spelling (``EnglishSpellingVisemes``) and spread
/// from the moment the word starts. The synthesizer plays its own audio, so the clock is the time
/// since speech started, not an audio position.
///
/// Call ``weights()`` once per rendered frame and apply the result to the rig.
@MainActor
public final class AVSpeechSynthesizerLipSync: NSObject {
    /// The synthesizer that speaks. Configure voices on the utterances you pass to ``speak(_:)``.
    public let synthesizer = AVSpeechSynthesizer()
    /// How the visemes pose the face.
    public var map: OculusToARKitMap
    /// Assumed length of a word, over which its visemes are spread.
    public var wordDuration: TimeInterval
    /// Called when an utterance finishes or is stopped.
    public var onFinish: (() -> Void)?

    public private(set) var isSpeaking = false

    private var text = ""
    /// Retained so its identity cannot be reused by a later utterance.
    private var utterance: AVSpeechUtterance?
    private var current: ObjectIdentifier? { utterance.map(ObjectIdentifier.init) }
    private var start: TimeInterval = 0
    private var keyframes: [OculusVisemeKeyframe] = []
    private let now: () -> TimeInterval

    public convenience init(map: OculusToARKitMap = .default, wordDuration: TimeInterval = 0.32) {
        self.init(map: map, wordDuration: wordDuration, clock: { ProcessInfo.processInfo.systemUptime })
    }

    init(map: OculusToARKitMap, wordDuration: TimeInterval, clock: @escaping () -> TimeInterval) {
        self.map = map
        self.wordDuration = wordDuration
        self.now = clock
        super.init()
        synthesizer.delegate = self
    }

    /// Stops anything speaking, then speaks `utterance`.
    public func speak(_ utterance: AVSpeechUtterance) {
        stop()
        begin(utterance)
        synthesizer.speak(utterance)
    }

    func begin(_ utterance: AVSpeechUtterance) {
        text = utterance.speechString
        self.utterance = utterance
        keyframes = []
        start = now()
        isSpeaking = true
    }

    /// Stops speech at once and brings the mouth to rest.
    public func stop() {
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        finish()
    }

    /// Seconds since the current utterance started speaking.
    public var elapsed: TimeInterval { isSpeaking ? now() - start : 0 }

    /// The face weights for this moment. Empty at rest.
    public func weights() -> [ARKitBlendShape: Float] {
        lipSync.weights(at: elapsed)
    }

    /// How much the mouth is speaking at this moment, 0…1.
    public func speechWeight() -> Float {
        lipSync.speechWeight(at: elapsed)
    }

    private var lipSync: LipSync {
        LipSync(track: OculusVisemeTrack(liveKeyframes: keyframes), map: map)
    }

    /// A word of the current utterance starts now.
    func wordStarted(_ range: NSRange, of utterance: ObjectIdentifier) {
        guard isSpeaking, utterance == current, let wordRange = Range(range, in: text) else { return }
        keyframes += EnglishSpellingVisemes.keyframes(forWord: String(text[wordRange]),
                                                      startingAt: elapsed,
                                                      wordDuration: wordDuration)
    }

    /// `utterance` ended. Events of an utterance already replaced by ``speak(_:)`` are ignored.
    func ended(_ utterance: ObjectIdentifier) {
        guard utterance == current else { return }
        finish()
    }

    private func finish() {
        guard isSpeaking else { return }
        isSpeaking = false
        utterance = nil
        keyframes = []
        onFinish?()
    }
}

extension AVSpeechSynthesizerLipSync: AVSpeechSynthesizerDelegate {
    // The delegate may be called off the main thread; each event hops to the main actor, carrying
    // only the utterance's identity.

    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                              willSpeakRangeOfSpeechString characterRange: NSRange,
                                              utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.wordStarted(characterRange, of: id) }
    }

    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.ended(id) }
    }

    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.ended(id) }
    }
}
