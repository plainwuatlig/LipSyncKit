# Map: LipSyncKit

Charted 2026-11-04 by Plain with an agent. Every "Settled" line is Plain's ruling of that date.

## Destination

LipSyncKit **0.1** is tagged on GitHub, and **arenglisheducation speaks through it** on the
LiG iPhone Xs Max (`00008020-001A1C1E1A78002E`).

## Settled

- **Name and home**: LipSyncKit, `github.com/plainwuatlig/LipSyncKit`, MIT, iOS 16+
  (the floor comes from `AVSpeechSynthesizer.writeUtterance`).
- **Not tied to any avatar format.** Not part of VRMKit; VRM is just one possible rig.
- **Core output**: ARKit-52 blend-shape weights over time. Visemes are one way in, not the contract.
- **Native formats first**: Oculus-15 visemes for the input side, ARKit-52 blend shapes for the output side.
  Every other format converts into or out of these two, later.
- **0.1 sources**: Azure viseme ids, Apple TTS phoneme markers, text-only fallback.
- **Audio**: the kit plays nothing. The app owns playback and passes in the audio time.
  An optional `SpeechPlayer` helper covers the Apple TTS route.
- **Renderer adapters** (SceneKit, RealityKit) live in the **sample app**, not in the kit.
- **English first.**
- **Test device**: LiG iPhone Xs Max, for now.
- **No ADRs or principles** at this stage.

## Notes

- **Reference only**: the VRM spike's lip-sync work in `~/Working/ai/plain/vrm-spike/`
  (`lipsync/`, and `VRMRuntime/Sources/VRMRuntime/Core/LipSync/`). Its ADR 0001 was written for a VRM
  library and is **invalid here**. What carries over as code: the Oculus-15 enum, track, sampler,
  Azure→Oculus table, and text scheduler.
- **arenglisheducation today**: the server's `audio_reply.visemes` (Azure ids) are parsed but never
  played. `Model/AIAudio/VisemeScheduler.swift` and `Model/Character/CharacterVisemeTable.swift`
  (Azure ids → ARKit names) are what the kit replaces.
- **Apple TTS** (iOS 27.2 SDK headers): `AVSpeechSynthesisMarker.Mark.phoneme` with `byteSampleOffset`.
  `writeUtterance(_:toBufferCallback:toMarkerCallback:)` is iOS 16; `willSpeakMarker` is iOS 17.
  **Unverified**: whether the built-in voices actually emit `.phoneme` markers.
- **Audio attached to an AR object**: SceneKit `SCNAudioPlayer` exposes its `AVAudioNode`.
  RealityKit `AudioPlaybackController` has **no public playback position** (only `__playbackPosition`),
  so the sample starts the audio with `play(at: AVAudioTime)` and counts time from the host clock.
- **Spec survey** (sources checked 2026-11-04):
  - Input side: Azure viseme events (22 ids, plus optional 60 fps × 55 blend-shape frames),
    Polly speech marks, Apple markers, Rhubarb A–H+X, MPEG-4 (14 visemes).
  - Output side: ARKit-52, Oculus-15 morphs, VRM-5 vowels, Live2D `ParamMouthOpenY`/`ParamMouthForm`.
- **Prior art**: no Swift lip-sync library. Closest: met4citizen/TalkingHead (JS, Oculus visemes),
  hecomi/uLipSync (Unity), DanielSWolf/rhubarb-lip-sync (C++ CLI).

## Frontier

1. **Device check**: do the built-in en-US voices emit `.phoneme` markers through `writeUtterance` on the
   Xs Max? If so, in what alphabet and at what density? The answer shapes the Apple source.
2. **Core**: types, sampler, the Oculus-15 → ARKit-52 table, Swift Testing.
3. **Sources**: Azure ids, Apple phonemes, text fallback.
4. **Sample app** with SceneKit and RealityKit adapters.
5. **arenglisheducation** speaking through the kit on the Xs Max.
6. **Tag 0.1.**

## Not yet specified

- Where the Oculus-15 → ARKit-52 weights come from. arenglisheducation's `CharacterVisemeTable`
  is a candidate seed.
- The source of the phoneme (IPA) → Oculus-15 table.
- Swift tools version and Swift 6 strict concurrency.
- A redistributable rig with ARKit-52 shapes for the sample app.

## Out of scope

- Lip-sync from audio analysis (amplitude, MFCC).
- Emotion, blink and gaze layers.
- Texture-swap mouths.
- Live2D and VRM profiles, until after 0.1.
- Android.
