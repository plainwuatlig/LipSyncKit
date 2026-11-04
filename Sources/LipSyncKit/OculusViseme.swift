/// The 15 visemes of Meta's Oculus Lipsync (OVRLipSync), in the order of its viseme reference.
///
/// Spec: "Viseme Reference", Oculus Lipsync for Unity,
/// https://developers.meta.com/horizon/documentation/unity/audio-ovrlipsync-viseme-reference/
/// (the page carries an end-of-life notice; the 15-viseme set remains in wide use, for example as
/// the `viseme_*` morph targets of Ready Player Me avatars).
///
/// Raw values are the spec's names verbatim. The phonemes on each case are the spec's own
/// examples, which it says are only a subset.
public enum OculusViseme: String, CaseIterable, Codable, Hashable, Sendable {
    /// Silence; no emphasised production.
    case sil
    /// p, b, m — "put", "bat", "mat".
    case PP
    /// f, v — "fat", "vat".
    case FF
    /// th — "think", "that".
    case TH
    /// t, d — "tip", "doll".
    case DD
    /// k, g — "call", "gas".
    case kk
    /// tʃ, dʒ, ʃ — "chair", "join", "she".
    case CH
    /// s, z — "sir", "zeal".
    case SS
    /// n, l — "lot", "not".
    case nn
    /// r — "red".
    case RR
    /// ɑː — "car".
    case aa
    /// e — "bed".
    case E
    /// ih — "tip".
    case I
    /// oh — "toe".
    case O
    /// ou — "book".
    case U
}
