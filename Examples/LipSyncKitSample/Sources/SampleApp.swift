import ARKit
import RealityKit
import SceneKit
import SwiftUI

@main
struct SampleApp: App {
    @StateObject private var speaker = Speaker()

    var body: some SwiftUI.Scene {
        WindowGroup {
            if ARFaceTrackingConfiguration.isSupported {
                VStack(spacing: 0) {
                    TabView {
                        SceneKitFaceView(speaker: speaker).tabItem { Label("SceneKit", systemImage: "cube") }
                        RealityKitFaceView(speaker: speaker).tabItem { Label("RealityKit", systemImage: "cube.transparent") }
                    }
                    Controls(speaker: speaker)
                }
            } else {
                Text("This sample shows Apple's ARKit face mesh, which needs a device with a TrueDepth front camera.")
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
    }
}

struct Controls: View {
    @ObservedObject var speaker: Speaker

    var body: some View {
        VStack(spacing: 8) {
            Picker("Source", selection: $speaker.source) {
                ForEach(Source.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            TextField("Text to speak", text: $speaker.text, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .disabled(speaker.source != .appleTTS)
            Button(speaker.isSpeaking ? "Stop" : "Speak") {
                speaker.isSpeaking ? speaker.stop() : speaker.speak()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

/// Calls `tick` once per screen refresh.
@MainActor
final class FrameTicker: NSObject {
    private var link: CADisplayLink?
    private let tick: () -> Void

    init(_ tick: @escaping () -> Void) {
        self.tick = tick
        super.init()
        let link = CADisplayLink(target: self, selector: #selector(step))
        link.add(to: .main, forMode: .common)
        self.link = link
    }

    @objc private func step() { tick() }

    func stop() { link?.invalidate() }
}

struct SceneKitFaceView: UIViewRepresentable {
    let speaker: Speaker

    final class Coordinator { var face: SceneKitFace?; var ticker: FrameTicker? }
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.backgroundColor = .white
        view.autoenablesDefaultLighting = true
        // Updating the face geometry does not by itself make SCNView draw a new frame.
        view.rendersContinuously = true
        let scene = SCNScene()
        view.scene = scene
        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.camera?.zNear = 0.01
        camera.position = SCNVector3(0, 0, 0.35)
        scene.rootNode.addChildNode(camera)
        view.pointOfView = camera
        if let device = view.device, let face = SceneKitFace(device: device) {
            scene.rootNode.addChildNode(face.node)
            context.coordinator.face = face
            context.coordinator.ticker = FrameTicker { [speaker] in face.apply(speaker.weights()) }
        }
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {}

    static func dismantleUIView(_ view: SCNView, coordinator: Coordinator) { coordinator.ticker?.stop() }
}

struct RealityKitFaceView: UIViewRepresentable {
    let speaker: Speaker

    final class Coordinator { var face: RealityKitFace?; var ticker: FrameTicker? }
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        view.environment.background = .color(.white)
        let anchor = AnchorEntity(world: .zero)
        let camera = PerspectiveCamera()
        camera.position = [0, 0, 0.35]
        anchor.addChild(camera)
        let light = DirectionalLight()
        light.look(at: .zero, from: [0.3, 0.3, 1], relativeTo: nil)
        anchor.addChild(light)
        view.scene.addAnchor(anchor)
        if let face = RealityKitFace() {
            anchor.addChild(face.entity)
            context.coordinator.face = face
            context.coordinator.ticker = FrameTicker { [speaker] in face.apply(speaker.weights()) }
        }
        return view
    }

    func updateUIView(_ view: ARView, context: Context) {}

    static func dismantleUIView(_ view: ARView, coordinator: Coordinator) { coordinator.ticker?.stop() }
}
