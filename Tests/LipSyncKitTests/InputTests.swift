import Foundation
import Testing
@testable import LipSyncKit

@Suite struct AzureInput {
    @Test func definesExactlyTheTwentyTwoIDsOfTheSpec() {
        #expect((0...21).allSatisfy { AzureVisemeID(rawValue: $0) != nil })
        #expect(AzureVisemeID(rawValue: -1) == nil)
        #expect(AzureVisemeID(rawValue: 22) == nil)
    }

    @Test func mapsByIPA() {
        func oculus(_ id: Int) -> OculusViseme { AzureVisemeID(rawValue: id)!.oculusViseme }
        #expect(oculus(0) == .sil)
        #expect(oculus(2) == .aa)  // ɑ
        #expect(oculus(6) == .I)   // j, i, ɪ
        #expect(oculus(7) == .U)   // w, u
        #expect(oculus(12) == .sil) // h
        #expect(oculus(17) == .TH) // ð
        #expect(oculus(19) == .DD) // d, t, n, θ
        #expect(oculus(21) == .PP) // p, b, m
    }

    @Test func convertsSDKTicksAndMilliseconds() {
        let id = AzureVisemeID(rawValue: 2)!
        #expect(AzureVisemeEvent(audioOffsetTicks: 5_000_000, id: id).audioOffset == 0.5)
        #expect(AzureVisemeEvent(audioOffsetMilliseconds: 250, id: id).audioOffset == 0.25)
    }

    @Test func buildsATrack() {
        func event(_ ms: Double, _ id: Int) -> AzureVisemeEvent {
            AzureVisemeEvent(audioOffsetMilliseconds: ms, id: AzureVisemeID(rawValue: id)!)
        }
        let track = OculusVisemeTrack(azureVisemes: [event(0, 21), event(100, 2), event(0, 0)], duration: 0.4)
        #expect(track.keyframes.map(\.viseme) == [.PP, .aa, .sil])
        #expect(track.keyframes.map(\.time) == [0, 0.1, 0.4])
    }
}

@Suite struct EnglishSpellingInput {
    @Test func keepsFirstLetterVowelsClosedLipsAndDigraphs() {
        #expect(EnglishSpellingVisemes.visemes(inWord: "mom") == [.PP, .O, .PP])
        #expect(EnglishSpellingVisemes.visemes(inWord: "the") == [.TH, .E])
        #expect(EnglishSpellingVisemes.visemes(inWord: "She") == [.CH, .E])
        #expect(EnglishSpellingVisemes.visemes(inWord: "fox") == [.FF, .O])
    }

    @Test func mergesRepeatsAndIgnoresPunctuation() {
        #expect(EnglishSpellingVisemes.visemes(inWord: "book.") == [.PP, .O])
        #expect(EnglishSpellingVisemes.visemes(inWord: "...").isEmpty)
    }

    @Test func spreadsAWordOverItsDuration() {
        let keyframes = EnglishSpellingVisemes.keyframes(forWord: "mom", startingAt: 1.0, wordDuration: 0.3)
        #expect(keyframes.map(\.viseme) == [.PP, .O, .PP])
        #expect(zip(keyframes.map(\.time), [1.0, 1.1, 1.2]).allSatisfy { abs($0 - $1) < 1e-9 })
    }

    @Test func estimatesATrackFromText() {
        let track = OculusVisemeTrack(estimatingEnglish: "the fox", duration: 1.0)
        #expect(track.keyframes.map(\.viseme) == [.TH, .E, .FF, .O, .sil])
        #expect(track.keyframes.map(\.time) == [0, 0.25, 0.5, 0.75, 1.0])
    }

    @Test func emptyTextIsSilence() {
        let track = OculusVisemeTrack(estimatingEnglish: "  ", duration: 1.0)
        #expect(track.keyframes.map(\.viseme) == [.sil])
    }
}
