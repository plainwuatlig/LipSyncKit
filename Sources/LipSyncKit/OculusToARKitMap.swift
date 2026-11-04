import Foundation

/// How each ``OculusViseme`` poses an ARKit-named face: viseme → ``ARKitBlendShape`` weights (0…1).
///
/// A rig whose mouth needs other weights supplies its own map, in code or as JSON:
///
/// ```json
/// { "PP": { "mouthPressLeft": 0.5, "mouthPressRight": 0.5 }, "aa": { "jawOpen": 0.8 } }
/// ```
///
/// Keys are ``OculusViseme`` and ``ARKitBlendShape`` raw values. A viseme absent from the map poses
/// nothing.
public struct OculusToARKitMap: Equatable, Sendable, Codable {
    public var poses: [OculusViseme: [ARKitBlendShape: Float]]

    public init(_ poses: [OculusViseme: [ARKitBlendShape: Float]]) {
        self.poses = poses
    }

    /// The pose of one viseme; empty when the map has none.
    public subscript(viseme: OculusViseme) -> [ARKitBlendShape: Float] {
        poses[viseme] ?? [:]
    }

    /// The default poses.
    ///
    /// Our own table, keyed by sound: for each viseme, the weights are those of the row of
    /// arenglisheducation's `CharacterVisemeTable.standard` whose IPA comment carries the same
    /// sounds (that table is keyed by Microsoft Azure viseme IDs; only its weights are reused, not
    /// its IDs). Changes against those rows:
    /// - `PP` adds `mouthPressLeft`/`mouthPressRight`: the source row closes the lips only by leaving
    ///   `jawOpen` at 0, which does not show.
    /// - `sil` is the rest pose (no weights); the source drove `mouthClose` at silence.
    /// - The source's VRM `Fcl_MTH_*` fallback is not carried over; it belongs to a VRM rig.
    /// The weights are a starting point, tuned by eye, not measured.
    public static let `default` = OculusToARKitMap([
        .sil: [:],
        // source row "p, b, m": jawOpen 0.0, plus lip press
        .PP: [.mouthPressLeft: 0.5, .mouthPressRight: 0.5],
        // source row "f, v"
        .FF: [.mouthRollLower: 0.5, .jawOpen: 0.1],
        // source row "ð"
        .TH: [.jawOpen: 0.1],
        // source row "d, t, n, θ"
        .DD: [.jawOpen: 0.2],
        // source row "k, g, ŋ"
        .kk: [.jawOpen: 0.2],
        // source row "ʃ, tʃ, dʒ, ʒ"
        .CH: [.mouthFunnel: 0.3, .jawOpen: 0.2],
        // source row "s, z"
        .SS: [.mouthStretchLeft: 0.2, .mouthStretchRight: 0.2],
        // source row "l"
        .nn: [.jawOpen: 0.3],
        // source row "ɹ"
        .RR: [.mouthPucker: 0.4, .jawOpen: 0.2],
        // source row "ɑ"
        .aa: [.jawOpen: 0.8],
        // source row "ɛ, ʊ"
        .E: [.jawOpen: 0.4],
        // source row "j, i, ɪ"
        .I: [.mouthStretchLeft: 0.5, .mouthStretchRight: 0.5, .jawOpen: 0.1],
        // source row "o"
        .O: [.mouthFunnel: 0.6, .jawOpen: 0.4],
        // source row "w, u"
        .U: [.mouthFunnel: 0.8, .jawOpen: 0.2],
    ])

    // MARK: Codable — string-keyed JSON objects, not Swift's array encoding of enum-keyed dictionaries.

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode([String: [String: Float]].self)
        var poses: [OculusViseme: [ARKitBlendShape: Float]] = [:]
        for (visemeName, rawPose) in raw {
            guard let viseme = OculusViseme(rawValue: visemeName) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown Oculus viseme \"\(visemeName)\"")
            }
            var pose: [ARKitBlendShape: Float] = [:]
            for (shapeName, weight) in rawPose {
                guard let shape = ARKitBlendShape(rawValue: shapeName) else {
                    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown ARKit blend shape \"\(shapeName)\"")
                }
                pose[shape] = weight
            }
            poses[viseme] = pose
        }
        self.poses = poses
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        let raw = Dictionary(uniqueKeysWithValues: poses.map { viseme, pose in
            (viseme.rawValue, Dictionary(uniqueKeysWithValues: pose.map { ($0.key.rawValue, $0.value) }))
        })
        try container.encode(raw)
    }
}
