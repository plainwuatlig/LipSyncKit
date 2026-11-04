import AVFoundation
import Foundation
import Testing
import LipSyncKit
@testable import LipSyncKitAVSpeech

@MainActor
@Suite struct AVSpeechSynthesizerLipSyncTests {
    final class Clock { var time: TimeInterval = 100 }

    func make(_ clock: Clock) -> AVSpeechSynthesizerLipSync {
        AVSpeechSynthesizerLipSync(map: .default, wordDuration: 0.3, clock: { clock.time })
    }

    @Test func restsUntilAWordStarts() {
        let clock = Clock()
        let lipSync = make(clock)
        let utterance = AVSpeechUtterance(string: "the fox")
        lipSync.begin(utterance)
        clock.time += 0.05
        #expect(lipSync.weights().isEmpty)
    }

    @Test func aWordPosesTheMouthFromWhenItStarts() {
        let clock = Clock()
        let lipSync = make(clock)
        let utterance = AVSpeechUtterance(string: "the fox")
        lipSync.begin(utterance)
        clock.time += 0.5
        lipSync.wordStarted(NSRange(location: 4, length: 3), of: ObjectIdentifier(utterance)) // "fox": FF, O
        clock.time += 0.2   // FF at 0.5, O at 0.65; now 0.7
        #expect(lipSync.weights()[.jawOpen] != nil)       // O opens the jaw
        #expect(lipSync.speechWeight() > 0)
    }

    @Test func finishingBringsTheMouthToRest() {
        let clock = Clock()
        let lipSync = make(clock)
        let utterance = AVSpeechUtterance(string: "mom")
        var finished = false
        lipSync.onFinish = { finished = true }
        lipSync.begin(utterance)
        lipSync.wordStarted(NSRange(location: 0, length: 3), of: ObjectIdentifier(utterance))
        clock.time += 0.1
        lipSync.ended(ObjectIdentifier(utterance))
        #expect(finished)
        #expect(!lipSync.isSpeaking)
        #expect(lipSync.weights().isEmpty)
    }

    @Test func eventsOfAReplacedUtteranceAreIgnored() {
        let clock = Clock()
        let lipSync = make(clock)
        let first = AVSpeechUtterance(string: "mom")
        let second = AVSpeechUtterance(string: "fox")
        lipSync.begin(first)
        lipSync.begin(second)
        lipSync.ended(ObjectIdentifier(first))                // late cancel of the first
        #expect(lipSync.isSpeaking)
        lipSync.wordStarted(NSRange(location: 0, length: 3), of: ObjectIdentifier(first))
        clock.time += 0.1
        #expect(lipSync.weights().isEmpty)
    }
}
