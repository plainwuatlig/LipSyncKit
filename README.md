# LipSyncKit

Lip sync for Apple platforms. Speech timing goes in; ARKit face blend-shape weights come out, ready
for any rig whose mouth uses ARKit's names.

- **Format-agnostic.** No avatar format, renderer or speech service is assumed.
- **No dependencies.** The core uses Foundation only; Apple TTS support is a separate product.
- **The app owns the audio.** LipSyncKit plays nothing and runs no timer: each frame, you pass the
  current audio time and apply the weights it returns.

> Status: pre-1.0. The API may change between minor versions.

## Requirements

- iOS 16, macOS 13 or visionOS 1
- Swift 6 toolchain (Xcode 16 or later)

## Installation

Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/plainwuatlig/LipSyncKit.git", from: "0.1.0"),
],
targets: [
    .target(name: "MyApp", dependencies: [
        .product(name: "LipSyncKit", package: "LipSyncKit"),
        // Only if you lip-sync to Apple's text to speech:
        .product(name: "LipSyncKitAVSpeech", package: "LipSyncKit"),
    ]),
]
```

## How it works

```
speech timing ──▶ OculusVisemeTrack ──▶ LipSync ──▶ [ARKitBlendShape: Float] ──▶ your rig
 (Azure events,      (visemes on the      (samples at     (52 ARKit face shapes)
  text, word starts)  audio timeline)      audio time)
```

Two published vocabularies sit at the boundaries, and the types are named after them:

| Type | Spec |
|---|---|
| `OculusViseme` | The 15 visemes of Meta's Oculus Lipsync (`sil`, `PP`, `FF`, `TH`, `DD`, `kk`, `CH`, `SS`, `nn`, `RR`, `aa`, `E`, `I`, `O`, `U`) — [viseme reference](https://developers.meta.com/horizon/documentation/unity/audio-ovrlipsync-viseme-reference/) |
| `ARKitBlendShape` | The 52 `ARFaceAnchor.BlendShapeLocation` names of ARKit face tracking — [documentation](https://developer.apple.com/documentation/arkit/arfaceanchor/blendshapelocation). Raw values are ARKit's own strings; LipSyncKit does not import ARKit. |
| `AzureVisemeID` | Viseme IDs 0–21 of Azure AI Speech text to speech — [viseme table](https://learn.microsoft.com/en-us/azure/ai-services/speech-service/how-to-speech-synthesis-viseme) |

`OculusToARKitMap` poses each viseme on the face. `OculusToARKitMap.default` is LipSyncKit's own
table, tuned by eye; supply your own for a rig that needs other shapes.

## Usage

### From Azure viseme events

When a speech service gives exact viseme timing, use it:

```swift
import LipSyncKit

// From the Speech SDK's VisemeReceived events (AudioOffset in 100 ns ticks) ...
let events = received.map { AzureVisemeEvent(audioOffsetTicks: $0.audioOffset, id: AzureVisemeID(rawValue: $0.visemeId)!) }
// ... or from a server that relays them in milliseconds:
// AzureVisemeEvent(audioOffsetMilliseconds: 250, id: AzureVisemeID(rawValue: 21)!)

let lipSync = LipSync(track: OculusVisemeTrack(azureVisemes: events, duration: audioDuration))

// Each frame, at the playing audio's current time:
let weights = lipSync.weights(at: player.currentTime)
```

### From text and the audio's duration

When all you have is the text and how long the audio lasts, LipSyncKit estimates visemes from English
spelling and spreads them over the duration. The shapes are rough — spelling is not pronunciation —
but they follow the words.

```swift
let lipSync = LipSync(track: OculusVisemeTrack(estimatingEnglish: text, duration: audioDuration))
```

A source that reports when each word starts (but no visemes) can build the track as it plays:

```swift
keyframes += EnglishSpellingVisemes.keyframes(forWord: word, startingAt: elapsed)
let lipSync = LipSync(track: OculusVisemeTrack(liveKeyframes: keyframes))
```

### From Apple's text to speech

`LipSyncKitAVSpeech` speaks with `AVSpeechSynthesizer` and lip-syncs to it:

```swift
import AVFoundation
import LipSyncKitAVSpeech

let speech = AVSpeechSynthesizerLipSync()
speech.speak(AVSpeechUtterance(string: "Hello, how are you?"))

// Each frame:
let weights = speech.weights()
```

Apple's voices report when each word starts but no phonemes (checked on iOS 18.7 and iOS 27.2,
compact, Enhanced and Premium voices), so each word's visemes are estimated from its spelling.

### Applying the weights

The weights carry only the shapes the current mouth pose touches. Set every mouth shape your rig uses
each frame, and zero the ones that are absent. With a SceneKit `SCNMorpher` whose targets use ARKit's
names:

```swift
for shape in mouthShapes {                       // the ARKitBlendShape cases your rig has
    morpher.setWeight(CGFloat(weights[shape] ?? 0), forTargetNamed: shape.rawValue)
}
```

`speechWeight(at:)` (0 at rest, 1 while a viseme is fully on) helps blend speech over another facial
layer, such as an emotion.

### A map for your rig

```swift
var map = OculusToARKitMap.default
map.poses[.aa] = [.jawOpen: 0.7, .mouthLowerDownLeft: 0.3, .mouthLowerDownRight: 0.3]
let lipSync = LipSync(track: track, map: map)
```

Maps are `Codable`, keyed by the specs' names:

```json
{ "PP": { "mouthPressLeft": 0.5, "mouthPressRight": 0.5 }, "aa": { "jawOpen": 0.8 } }
```

## Sample app

`Examples/LipSyncKitSample` speaks typed text with Apple's text to speech, or plays a short series of
Azure-style viseme events, and shows the result on Apple's own ARKit face mesh, built from the weights
with `ARFaceGeometry(blendShapes:)` — no 3D asset and no camera session. It shows the same face in
SceneKit and RealityKit, with the adapters for both in the sample. It runs on devices with a TrueDepth
front camera.

```sh
cd Examples/LipSyncKitSample
open LipSyncKitSample.xcodeproj      # choose your signing team, then run on a device
```

The project is generated from `project.yml` with [XcodeGen](https://github.com/yonaskolb/XcodeGen).

## Limitations

- Spelling-based estimates are English only and approximate.
- No lip sync from audio alone (amplitude or spectral analysis).
- No emotion, blink or gaze layers; LipSyncKit drives the mouth.
- `AzureVisemeID.oculusViseme` is LipSyncKit's own mapping between the two specs, by the IPA each gives.

## License

MIT. See [LICENSE](LICENSE).
