import Foundation

/// One point on an ``OculusVisemeTrack``: from `time` (seconds of audio) the mouth moves to
/// `viseme` at `weight` (0…1).
public struct OculusVisemeKeyframe: Equatable, Sendable {
    public var time: TimeInterval
    public var viseme: OculusViseme
    public var weight: Float

    public init(time: TimeInterval, viseme: OculusViseme, weight: Float = 1) {
        self.time = time
        self.viseme = viseme
        self.weight = weight
    }
}

/// The visemes of one utterance on its audio timeline, in time order.
public struct OculusVisemeTrack: Equatable, Sendable {
    /// In ascending `time`, at most one per instant.
    public let keyframes: [OculusVisemeKeyframe]

    /// A track for a finished utterance of known `duration`.
    ///
    /// Keyframes out of time order are dropped (a source may append trailing events at offset 0),
    /// a later keyframe at the same instant replaces the earlier one, and the track always closes
    /// with `sil` at `duration` so the mouth comes to rest.
    public init(keyframes raw: [OculusVisemeKeyframe], duration: TimeInterval) {
        var out: [OculusVisemeKeyframe] = []
        for keyframe in raw {
            if let last = out.last {
                if keyframe.time < last.time { continue }
                if keyframe.time == last.time { out[out.count - 1] = keyframe; continue }
            }
            out.append(keyframe)
        }
        if let last = out.last, last.time > duration {
            out.removeAll { $0.time > duration }
        }
        if out.last?.viseme != .sil || (out.last?.time ?? -1) < duration {
            out.append(OculusVisemeKeyframe(time: duration, viseme: .sil))
        }
        keyframes = out
    }

    /// A track still growing while speech plays (a source that reports a word at a time), with no
    /// known end. Keyframes are taken as given, in time order.
    public init(liveKeyframes: [OculusVisemeKeyframe]) {
        keyframes = liveKeyframes
    }
}
