import Foundation
import Testing
@testable import LipSyncKit

@Suite struct SpecNames {
    @Test func oculusVisemesAreTheFifteenOfTheReferenceInOrder() {
        #expect(OculusViseme.allCases.map(\.rawValue) ==
                ["sil", "PP", "FF", "TH", "DD", "kk", "CH", "SS", "nn", "RR", "aa", "E", "I", "O", "U"])
    }

    @Test func arkitBlendShapesAreTheFiftyTwoOfARFaceAnchor() {
        #expect(ARKitBlendShape.allCases.count == 52)
        #expect(Set(ARKitBlendShape.allCases.map(\.rawValue)).count == 52)
        #expect(ARKitBlendShape.jawOpen.rawValue == "jawOpen")
        #expect(ARKitBlendShape.mouthPressLeft.rawValue == "mouthPressLeft")
    }
}

@Suite struct Track {
    @Test func dropsOutOfOrderKeyframesAndClosesWithSilence() {
        let track = OculusVisemeTrack(keyframes: [
            .init(time: 0.0, viseme: .PP),
            .init(time: 0.1, viseme: .aa),
            .init(time: 0.0, viseme: .sil),   // trailing event at offset 0
        ], duration: 0.5)
        #expect(track.keyframes.map(\.viseme) == [.PP, .aa, .sil])
        #expect(track.keyframes.last?.time == 0.5)
    }

    @Test func laterKeyframeAtSameInstantWins() {
        let track = OculusVisemeTrack(keyframes: [
            .init(time: 0.1, viseme: .aa),
            .init(time: 0.1, viseme: .O),
        ], duration: 0.3)
        #expect(track.keyframes.map(\.viseme) == [.O, .sil])
    }

    @Test func keyframesPastTheEndAreDropped() {
        let track = OculusVisemeTrack(keyframes: [
            .init(time: 0.1, viseme: .aa),
            .init(time: 0.9, viseme: .O),
        ], duration: 0.5)
        #expect(track.keyframes.map(\.viseme) == [.aa, .sil])
    }

    @Test func doesNotDuplicateAClosingSilenceAtTheEnd() {
        let track = OculusVisemeTrack(keyframes: [
            .init(time: 0.1, viseme: .aa),
            .init(time: 0.5, viseme: .sil),
        ], duration: 0.5)
        #expect(track.keyframes.count == 2)
    }
}

@Suite struct Sampling {
    let lipSync = LipSync(track: OculusVisemeTrack(keyframes: [
        .init(time: 1.0, viseme: .aa),
        .init(time: 2.0, viseme: .O),
    ], duration: 3.0))

    @Test func restBeforeTheFirstKeyframe() {
        #expect(lipSync.weights(at: 0.5).isEmpty)
        #expect(lipSync.speechWeight(at: 0.5) == 0)
    }

    @Test func rampsInOverTheAttack() {
        // 20 ms into a 40 ms attack: aa at half weight, jawOpen 0.8 × 0.5
        #expect(abs(lipSync.weights(at: 1.020)[.jawOpen]! - 0.4) < 1e-4)
        #expect(lipSync.weights(at: 1.5)[.jawOpen] == 0.8)
        #expect(lipSync.speechWeight(at: 1.5) == 1)
    }

    @Test func previousVisemeFadesOutOverTheRelease() {
        // 40 ms after O starts: O fully in (attack 40 ms), aa at half (release 80 ms)
        let mix = lipSync.visemes(at: 2.040)
        #expect(abs(mix[.O]! - 1) < 1e-4)
        #expect(abs(mix[.aa]! - 0.5) < 1e-4)
        // jawOpen = O 0.4 × 1 + aa 0.8 × 0.5
        #expect(abs(lipSync.weights(at: 2.040)[.jawOpen]! - 0.8) < 1e-4)
        #expect(lipSync.visemes(at: 2.2)[.aa] == nil)
    }

    @Test func weightsNeverExceedOne() {
        let loud = LipSync(track: OculusVisemeTrack(keyframes: [
            .init(time: 0, viseme: .aa), .init(time: 0.01, viseme: .aa),
        ], duration: 1), map: OculusToARKitMap([.aa: [.jawOpen: 0.9]]))
        #expect(loud.weights(at: 0.02)[.jawOpen]! <= 1)
    }

    @Test func comesToRestAfterTheClosingSilence() {
        #expect(lipSync.weights(at: 3.5).isEmpty)
        #expect(lipSync.speechWeight(at: 3.5) == 0)
    }
}

@Suite struct MapJSON {
    @Test func roundTrips() throws {
        let data = try JSONEncoder().encode(OculusToARKitMap.default)
        let decoded = try JSONDecoder().decode(OculusToARKitMap.self, from: data)
        #expect(decoded == .default)
    }

    @Test func readsStringKeyedJSON() throws {
        let json = #"{ "PP": { "mouthPressLeft": 0.5 }, "aa": { "jawOpen": 0.8 } }"#
        let map = try JSONDecoder().decode(OculusToARKitMap.self, from: Data(json.utf8))
        #expect(map[.PP] == [.mouthPressLeft: 0.5])
        #expect(map[.aa] == [.jawOpen: 0.8])
        #expect(map[.O].isEmpty)
    }

    @Test func rejectsNamesOutsideTheSpecs() {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(OculusToARKitMap.self, from: Data(#"{ "ih": {} }"#.utf8))
        }
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(OculusToARKitMap.self, from: Data(#"{ "aa": { "Fcl_MTH_A": 1 } }"#.utf8))
        }
    }

    @Test func defaultMapPosesEveryVisemeButSilence() {
        for viseme in OculusViseme.allCases where viseme != .sil {
            #expect(!OculusToARKitMap.default[viseme].isEmpty, "\(viseme) has no pose")
        }
        #expect(OculusToARKitMap.default[.sil].isEmpty)
    }
}
