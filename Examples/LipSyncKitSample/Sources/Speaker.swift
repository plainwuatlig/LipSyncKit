import AVFoundation
import Foundation
import LipSyncKit
import LipSyncKitAVSpeech

/// The two ways the sample makes the face speak.
enum Source: String, CaseIterable, Identifiable {
    /// Apple's text to speech; visemes estimated per word from spelling.
    case appleTTS = "Apple TTS"
    /// A hand-made list of Azure viseme events for "hello world", no audio: shows the exact-timing
    /// path an app takes when its server relays Azure's events.
    case azureEvents = "Azure events"
    var id: String { rawValue }
}

@MainActor
final class Speaker: ObservableObject {
    @Published var text = "Hello, my name is Leo. The quick brown fox jumps over the lazy dog."
    @Published var source: Source = .appleTTS
    @Published private(set) var isSpeaking = false

    private let apple = AVSpeechSynthesizerLipSync()
    private var azure: LipSync?
    private var azureStart: TimeInterval = 0
    private var azureDuration: TimeInterval = 0

    init() {
        apple.onFinish = { [weak self] in self?.isSpeaking = false }
    }

    func speak() {
        stop()
        switch source {
        case .appleTTS:
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            apple.speak(utterance)
        case .azureEvents:
            let (events, duration) = Speaker.helloWorldAzureEvents
            azure = LipSync(track: OculusVisemeTrack(azureVisemes: events, duration: duration))
            azureStart = ProcessInfo.processInfo.systemUptime
            azureDuration = duration
        }
        isSpeaking = true
    }

    func stop() {
        apple.stop()
        azure = nil
        isSpeaking = false
    }

    /// Called once per rendered frame.
    func weights() -> [ARKitBlendShape: Float] {
        switch source {
        case .appleTTS:
            return apple.weights()
        case .azureEvents:
            guard let azure else { return [:] }
            let elapsed = ProcessInfo.processInfo.systemUptime - azureStart
            if elapsed > azureDuration + 0.2 { self.azure = nil; isSpeaking = false }
            return azure.weights(at: elapsed)
        }
    }

    /// "hello world" as Azure viseme IDs, timed by hand from its IPA (h ə l oʊ w ɝ l d). Not Azure
    /// output; a stand-in so the sample needs no Azure account.
    static let helloWorldAzureEvents: ([AzureVisemeEvent], TimeInterval) = {
        let timeline: [(ms: Double, id: Int)] = [
            (0, 12), (70, 1), (150, 14), (240, 8), (420, 7), (500, 5), (610, 14), (700, 19), (800, 0),
        ]
        let events = timeline.map { AzureVisemeEvent(audioOffsetMilliseconds: $0.ms, id: AzureVisemeID(rawValue: $0.id)!) }
        return (events, 0.9)
    }()
}
