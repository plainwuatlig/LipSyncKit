/// The 52 face blend shapes of Apple ARKit face tracking.
///
/// Spec: `ARFaceAnchor.BlendShapeLocation` (ARKit, `ARFaceAnchor.h`),
/// https://developer.apple.com/documentation/arkit/arfaceanchor/blendshapelocation
///
/// Raw values are ARKit's own strings (`ARFaceAnchor.BlendShapeLocation.jawOpen.rawValue == "jawOpen"`),
/// so a weight dictionary keyed by these maps 1:1 onto an ARKit-named rig. Declared here so the kit
/// never imports ARKit and builds where ARKit does not exist.
public enum ARKitBlendShape: String, CaseIterable, Codable, Hashable, Sendable {
    // Left eye
    case eyeBlinkLeft, eyeLookDownLeft, eyeLookInLeft, eyeLookOutLeft, eyeLookUpLeft, eyeSquintLeft, eyeWideLeft
    // Right eye
    case eyeBlinkRight, eyeLookDownRight, eyeLookInRight, eyeLookOutRight, eyeLookUpRight, eyeSquintRight, eyeWideRight
    // Mouth and jaw
    case jawForward, jawLeft, jawRight, jawOpen
    case mouthClose, mouthFunnel, mouthPucker, mouthLeft, mouthRight
    case mouthSmileLeft, mouthSmileRight, mouthFrownLeft, mouthFrownRight
    case mouthDimpleLeft, mouthDimpleRight, mouthStretchLeft, mouthStretchRight
    case mouthRollLower, mouthRollUpper, mouthShrugLower, mouthShrugUpper
    case mouthPressLeft, mouthPressRight, mouthLowerDownLeft, mouthLowerDownRight, mouthUpperUpLeft, mouthUpperUpRight
    // Eyebrows, cheeks and nose
    case browDownLeft, browDownRight, browInnerUp, browOuterUpLeft, browOuterUpRight
    case cheekPuff, cheekSquintLeft, cheekSquintRight
    case noseSneerLeft, noseSneerRight
    // Tongue
    case tongueOut
}
