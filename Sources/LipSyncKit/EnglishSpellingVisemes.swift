import Foundation

/// Estimates ``OculusViseme``s from English spelling, for speech that comes with no viseme or
/// phoneme timing (only text, a duration, or word start times).
///
/// Our own rules, not a spec and not a pronunciation dictionary, ported from arenglisheducation's
/// `VisemeScheduler.parseVisemes` (itself from the player SDK's `newCharacter` branch): per word,
/// keep only the sounds the mouth shows most — the first letter, every vowel, the closed-lip
/// letters m/b/p, and the digraphs sh/ch/th — and merge repeats. Letters are mapped straight to
/// Oculus visemes. Expect rough shapes: spelling is not pronunciation.
public enum EnglishSpellingVisemes {
    /// The visemes of one word, in order. Empty for a word with no letters.
    public static func visemes(inWord word: String) -> [OculusViseme] {
        let letters = Array(word.lowercased().filter(\.isLetter))
        var visemes: [OculusViseme] = []
        var index = 0
        while index < letters.count {
            let letter = letters[index]
            var viseme: OculusViseme?
            if index + 1 < letters.count, let digraph = digraphs[String(letters[index...index + 1])] {
                viseme = digraph
                index += 1
            } else if index == 0 || vowels.contains(letter) || closedLips.contains(letter) {
                viseme = firstLetters[letter]
            }
            if let viseme, viseme != visemes.last { visemes.append(viseme) }
            index += 1
        }
        return visemes
    }

    /// Keyframes for one word that starts at `start` seconds, its visemes spread evenly over
    /// `wordDuration`. For a source that reports when each word starts but not how long it lasts.
    public static func keyframes(forWord word: String,
                                 startingAt start: TimeInterval,
                                 wordDuration: TimeInterval = 0.32) -> [OculusVisemeKeyframe] {
        let visemes = visemes(inWord: word)
        guard !visemes.isEmpty else { return [] }
        let step = wordDuration / Double(visemes.count)
        return visemes.enumerated().map { OculusVisemeKeyframe(time: start + step * Double($0.offset), viseme: $0.element) }
    }

    private static let vowels: Set<Character> = ["a", "e", "i", "o", "u", "y"]
    private static let closedLips: Set<Character> = ["m", "b", "p"]
    private static let digraphs: [String: OculusViseme] = ["sh": .CH, "ch": .CH, "th": .TH]
    private static let firstLetters: [Character: OculusViseme] = [
        "a": .aa, "e": .E, "i": .I, "o": .O, "u": .U, "y": .I,
        "m": .PP, "b": .PP, "p": .PP,
        "f": .FF, "v": .FF,
        "t": .DD, "d": .DD,
        "k": .kk, "g": .kk, "c": .kk, "q": .kk, "x": .kk,
        "s": .SS, "z": .SS,
        "n": .nn, "l": .nn,
        "r": .RR,
        "w": .U,
        "j": .CH,
        "h": .sil,
    ]
}

extension OculusVisemeTrack {
    /// A track estimated from English `text` spoken over `duration` seconds: each word's visemes
    /// (see ``EnglishSpellingVisemes``) spread evenly across the whole duration.
    public init(estimatingEnglish text: String, duration: TimeInterval) {
        let visemes = text.split(whereSeparator: \.isWhitespace).flatMap { EnglishSpellingVisemes.visemes(inWord: String($0)) }
        guard !visemes.isEmpty, duration > 0 else {
            self.init(keyframes: [], duration: max(0, duration))
            return
        }
        let step = duration / Double(visemes.count)
        self.init(keyframes: visemes.enumerated().map { OculusVisemeKeyframe(time: step * Double($0.offset), viseme: $0.element) },
                  duration: duration)
    }
}
