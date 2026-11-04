// The renderer adapters: how an app turns LipSyncKit's ARKit weights into a moving face.
// They live in the sample, not the kit, so each app can write its own for its own rig.
//
// The face here is Apple's own ARKit face mesh, built from the weights with
// `ARFaceGeometry(blendShapes:)`. It needs no camera session and no 3D asset, but only devices
// that support ARKit face tracking (a TrueDepth front camera) provide it.

import ARKit
import LipSyncKit
import RealityKit
import SceneKit

/// LipSyncKit weights → ARKit's blend-shape dictionary. The names are ARKit's own strings.
func arkitBlendShapes(_ weights: [ARKitBlendShape: Float]) -> [ARFaceAnchor.BlendShapeLocation: NSNumber] {
    Dictionary(uniqueKeysWithValues: weights.map { (ARFaceAnchor.BlendShapeLocation(rawValue: $0.key.rawValue), NSNumber(value: $0.value)) })
}

/// Drives an `ARSCNFaceGeometry` in SceneKit.
@MainActor
final class SceneKitFace {
    let node: SCNNode
    private let geometry: ARSCNFaceGeometry

    init?(device: MTLDevice) {
        guard let geometry = ARSCNFaceGeometry(device: device) else { return nil }
        geometry.firstMaterial?.diffuse.contents = UIColor(red: 0.95, green: 0.8, blue: 0.7, alpha: 1)
        geometry.firstMaterial?.lightingModel = .physicallyBased
        self.geometry = geometry
        node = SCNNode(geometry: geometry)
    }

    func apply(_ weights: [ARKitBlendShape: Float]) {
        guard let face = ARFaceGeometry(blendShapes: arkitBlendShapes(weights)) else { return }
        geometry.update(from: face)
    }
}

/// Drives a RealityKit `ModelEntity` whose mesh is rebuilt from the face geometry each frame.
@MainActor
final class RealityKitFace {
    let entity: ModelEntity
    private let triangles: [UInt32]

    init?() {
        guard let neutral = ARFaceGeometry(blendShapes: [:]) else { return nil }
        triangles = neutral.triangleIndices.map { UInt32($0) }
        let material = SimpleMaterial(color: UIColor(red: 0.95, green: 0.8, blue: 0.7, alpha: 1), roughness: 0.6, isMetallic: false)
        guard let mesh = try? MeshResource.generate(from: [RealityKitFace.descriptor(neutral.vertices, triangles)]) else { return nil }
        entity = ModelEntity(mesh: mesh, materials: [material])
    }

    func apply(_ weights: [ARKitBlendShape: Float]) {
        guard let face = ARFaceGeometry(blendShapes: arkitBlendShapes(weights)),
              let mesh = try? MeshResource.generate(from: [RealityKitFace.descriptor(face.vertices, triangles)]) else { return }
        entity.model?.mesh = mesh
    }

    /// Positions plus smooth per-vertex normals (the face geometry carries none for RealityKit).
    private static func descriptor(_ positions: [SIMD3<Float>], _ triangles: [UInt32]) -> MeshDescriptor {
        var normals = [SIMD3<Float>](repeating: .zero, count: positions.count)
        for t in stride(from: 0, to: triangles.count, by: 3) {
            let (a, b, c) = (Int(triangles[t]), Int(triangles[t + 1]), Int(triangles[t + 2]))
            let n = simd_cross(positions[b] - positions[a], positions[c] - positions[a])
            normals[a] += n; normals[b] += n; normals[c] += n
        }
        var descriptor = MeshDescriptor(name: "face")
        descriptor.positions = MeshBuffers.Positions(positions)
        descriptor.normals = MeshBuffers.Normals(normals.map { simd_length($0) > 0 ? simd_normalize($0) : $0 })
        descriptor.primitives = .triangles(triangles)
        return descriptor
    }
}
