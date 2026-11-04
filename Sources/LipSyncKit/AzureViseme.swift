import Foundation

/// A viseme ID of Microsoft Azure AI Speech text to speech (0–21).
///
/// Spec: "Get facial position with viseme", Azure AI Speech,
/// https://learn.microsoft.com/en-us/azure/ai-services/speech-service/how-to-speech-synthesis-viseme
/// (table "viseme ID → typical IPA phonemes"; the page notes the phonemes vary by locale).
public struct AzureVisemeID: RawRepresentable, Hashable, Sendable {
    public let rawValue: Int

    /// Nil outside 0–21, the IDs the spec defines.
    public init?(rawValue: Int) {
        guard AzureVisemeID.oculusVisemes.indices.contains(rawValue) else { return nil }
        self.rawValue = rawValue
    }

    /// The ``OculusViseme`` this ID becomes.
    ///
    /// Our own mapping, by the IPA each spec gives: where an Azure ID groups sounds that Oculus
    /// splits, the ID's first sound decides; diphthongs take their first vowel; `h` has no Oculus
    /// shape and becomes `sil`.
    public var oculusViseme: OculusViseme { AzureVisemeID.oculusVisemes[rawValue] }

    private static let oculusVisemes: [OculusViseme] = [
        .sil, //  0 silence
        .aa,  //  1 æ, ə, ʌ
        .aa,  //  2 ɑ
        .O,   //  3 ɔ
        .E,   //  4 ɛ, ʊ
        .RR,  //  5 ɝ
        .I,   //  6 j, i, ɪ
        .U,   //  7 w, u
        .O,   //  8 o
        .aa,  //  9 aʊ
        .O,   // 10 ɔɪ
        .aa,  // 11 aɪ
        .sil, // 12 h
        .RR,  // 13 ɹ
        .nn,  // 14 l
        .SS,  // 15 s, z
        .CH,  // 16 ʃ, tʃ, dʒ, ʒ
        .TH,  // 17 ð
        .FF,  // 18 f, v
        .DD,  // 19 d, t, n, θ
        .kk,  // 20 k, g, ŋ
        .PP,  // 21 p, b, m
    ]
}

/// One Azure viseme event: from `audioOffset` seconds into the synthesized audio, viseme `id`.
public struct AzureVisemeEvent: Equatable, Sendable {
    public var audioOffset: TimeInterval
    public var id: AzureVisemeID

    public init(audioOffset: TimeInterval, id: AzureVisemeID) {
        self.audioOffset = audioOffset
        self.id = id
    }

    /// From the Speech SDK's `VisemeReceived` event, whose `AudioOffset` is in ticks of 100 ns.
    public init(audioOffsetTicks: Int64, id: AzureVisemeID) {
        self.init(audioOffset: TimeInterval(audioOffsetTicks) / 10_000_000, id: id)
    }

    /// From an offset in milliseconds, as a server that relays Azure's events may send it.
    public init(audioOffsetMilliseconds: Double, id: AzureVisemeID) {
        self.init(audioOffset: audioOffsetMilliseconds / 1000, id: id)
    }
}

extension OculusVisemeTrack {
    /// A track from Azure viseme events, for audio of `duration` seconds.
    public init(azureVisemes events: [AzureVisemeEvent], duration: TimeInterval) {
        self.init(keyframes: events.map { OculusVisemeKeyframe(time: $0.audioOffset, viseme: $0.id.oculusViseme) },
                  duration: duration)
    }
}
