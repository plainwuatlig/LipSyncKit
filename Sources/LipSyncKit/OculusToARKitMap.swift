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

    /// The default poses: LipSyncKit's own table, one pose per viseme, chosen for the sounds each
    /// viseme stands for. `sil` is the rest pose; `PP` presses the lips together. Tuned by eye, not
    /// measured: a rig that needs other shapes supplies its own map.
    public static let `default` = OculusToARKitMap([
        .sil: [:],
        .PP: [.mouthPressLeft: 0.5, .mouthPressRight: 0.5],
        .FF: [.mouthRollLower: 0.5, .jawOpen: 0.1],
        .TH: [.jawOpen: 0.1],
        .DD: [.jawOpen: 0.2],
        .kk: [.jawOpen: 0.2],
        .CH: [.mouthFunnel: 0.3, .jawOpen: 0.2],
        .SS: [.mouthStretchLeft: 0.2, .mouthStretchRight: 0.2],
        .nn: [.jawOpen: 0.3],
        .RR: [.mouthPucker: 0.4, .jawOpen: 0.2],
        .aa: [.jawOpen: 0.8],
        .E: [.jawOpen: 0.4],
        .I: [.mouthStretchLeft: 0.5, .mouthStretchRight: 0.5, .jawOpen: 0.1],
        .O: [.mouthFunnel: 0.6, .jawOpen: 0.4],
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
