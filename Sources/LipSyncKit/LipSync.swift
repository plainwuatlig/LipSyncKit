import Foundation

/// Turns an ``OculusVisemeTrack`` into ARKit face weights at any moment of the audio.
///
/// The app owns playback and its clock: each frame it passes the current audio time and applies
/// the returned weights to its rig. Nothing here plays audio or runs a timer.
///
/// Between keyframes the incoming viseme ramps in over ``attack`` while the previous one fades out
/// over ``release``.
public struct LipSync: Sendable {
    public var track: OculusVisemeTrack
    public var map: OculusToARKitMap
    /// Seconds for a viseme to reach full weight.
    public var attack: TimeInterval
    /// Seconds for the previous viseme to fade out.
    public var release: TimeInterval

    public init(track: OculusVisemeTrack,
                map: OculusToARKitMap = .default,
                attack: TimeInterval = 0.040,
                release: TimeInterval = 0.080) {
        self.track = track
        self.map = map
        self.attack = attack
        self.release = release
    }

    /// The viseme mix at `audioTime`: each viseme's current weight (0…1).
    public func visemes(at audioTime: TimeInterval) -> [OculusViseme: Float] {
        let keyframes = track.keyframes
        guard let index = keyframes.lastIndex(where: { $0.time <= audioTime }) else { return [:] }
        let current = keyframes[index]
        let elapsed = audioTime - current.time
        var mix: [OculusViseme: Float] = [:]
        mix[current.viseme, default: 0] += Float(ramp(elapsed, over: attack)) * current.weight
        if index > 0 {
            let previous = keyframes[index - 1]
            let fading = Float(1 - ramp(elapsed, over: release)) * previous.weight
            if fading > 0 { mix[previous.viseme, default: 0] += fading }
        }
        return mix.mapValues { min(1, $0) }
    }

    /// The ARKit face weights at `audioTime`, each 0…1. Shapes the current mix does not touch are
    /// absent; an app that drives a rig every frame resets those to 0 itself.
    public func weights(at audioTime: TimeInterval) -> [ARKitBlendShape: Float] {
        var weights: [ARKitBlendShape: Float] = [:]
        for (viseme, visemeWeight) in visemes(at: audioTime) where visemeWeight > 0 {
            for (shape, shapeWeight) in map[viseme] {
                weights[shape, default: 0] += shapeWeight * visemeWeight
            }
        }
        return weights.mapValues { min(1, $0) }
    }

    /// How much the mouth is speaking at `audioTime`: 0 at rest, 1 when a non-silent viseme is fully
    /// on. An app blending speech over another facial layer (an emotion) can weigh by it.
    public func speechWeight(at audioTime: TimeInterval) -> Float {
        min(1, visemes(at: audioTime).filter { $0.key != .sil }.values.reduce(0, +))
    }

    private func ramp(_ elapsed: TimeInterval, over span: TimeInterval) -> TimeInterval {
        guard span > 0 else { return 1 }
        return min(1, max(0, elapsed / span))
    }
}
