//
//  SpiralModel.swift
//  voclimatespiral
//
//  Created by Yasuhito Nagatomo on 2023/08/19.
//

import UIKit
import RealityKit

@MainActor
final class SpiralModel {
    enum ModelConstant {
        static let ringBaseOffset: Float = -1.4 / 2.0 // [m] y-axis
        static let ringGap: Float = 0.01 // [m] y-axis
        static let ringWidth: Float = 0.01 // [m]
        static let ringRadius: Float = 0.5 // [m]
        static let ringRadiusOffset: Float = 0.25 // [m]

        // Year Label Models
        static let labelDepth: Float = 0.02 // [m] z-axis
        static let labelFontSize: CGFloat = 0.1
    }

    let baseEntity = Entity()

    private var ringModelEntities = [ModelEntity]()
    private var labelModelEntities = [ModelEntity]()
    private var simpleMaterials = [SimpleMaterial]()
    private let emitterEntity = ModelEntity()

    private var animatingStep = 0

    func generateModel() async {
        guard ringModelEntities.isEmpty else { return }

        let generationTask = Task { () -> Int in
            // Generate each model
            generateLabelModels()
            generateRingModels()
            return ringModelEntities.count
        }

        _ = await generationTask.value

        // Construct the whole model
        ringModelEntities.forEach { entity in
            baseEntity.addChild(entity)
        }
        labelModelEntities.forEach { entity in
            baseEntity.addChild(entity)
        }

        // Attach Component
        baseEntity.components.set(SpiralAnimationComponent())

        // Setup a Particle based on the preset particle, "Impact"
        var particle = ParticleEmitterComponent.Presets.impact
        particle.emitterShapeSize = SIMD3<Float>(0.8, 0.1, 0.8)
        particle.mainEmitter.birthRate = 20_000
        particle.mainEmitter.color = .constant(.single(UIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 0.8)))
        particle.simulationState = .pause
        emitterEntity.components.set(particle)
        let yOffset = ModelConstant.ringBaseOffset + Float(ClimateModel.data.count) * ModelConstant.ringGap
        emitterEntity.transform.translation = SIMD3<Float>(0, yOffset, 0)
        baseEntity.addChild(emitterEntity)
    }
}

// MARK: - Entity Generation

extension SpiralModel {
    private func generateLabelModels() {
        for index in 0 ..< ClimateModel.data.count { // ModelConstant.labelCount {
            let meshResource
            = MeshResource.generateText(String(ClimateModel.firstYear + index),
                extrusionDepth: ModelConstant.labelDepth, // [m] z axis
                font: .systemFont(ofSize: ModelConstant.labelFontSize),
                containerFrame: .zero // zero : large enough for the text,
                // , alignment: .left
                // lineBreakMode: CTLineBreakMode.byTruncatingTail
                )
            let aveTemperature = ClimateModel.average(index: index)
            let material = material(temperature: aveTemperature)
            let model = ModelEntity(mesh: meshResource, materials: [material])
            let yOffset = ModelConstant.ringBaseOffset
                            + Float(index) * ModelConstant.ringGap
            model.transform.translation = SIMD3<Float>(0.8, yOffset, 0)
            labelModelEntities.append(model)
        }
    }

    // swiftlint:disable function_body_length
    // swiftlint:disable identifier_name
    private func generateRingModels() {
        var lastPositions: [SIMD3<Float>] = []
        for year in 0 ..< ClimateModel.data.count {
            var positions: [SIMD3<Float>] = lastPositions
            var indexes: [UInt32] = []
            let edgeCount = lastPositions.isEmpty ? 11 : 12

            for month in 0 ..< 12 {
                let temperature = ClimateModel.data[year][month]
                let length = ModelConstant.ringRadius
                                + ModelConstant.ringRadiusOffset * temperature
                let length1 = length + ModelConstant.ringWidth / 2.0
                let length2 = length - ModelConstant.ringWidth / 2.0
                let theta = Float.pi / 2 - Float.pi / 6 * Float(month)
                let yOffset = ModelConstant.ringBaseOffset
                                + Float(year) * ModelConstant.ringGap
                                + Float(month) * ModelConstant.ringGap / 12.0

                let x1 = length1 * cosf(theta)
                let z1 = -length1 * sinf(theta)
                let y1 = yOffset + ModelConstant.ringWidth / 2.0
                let y3 = yOffset - ModelConstant.ringWidth / 2.0

                let x2 = length2 * cosf(theta)
                let z2 = -length2 * sinf(theta)
                let y2 = yOffset + ModelConstant.ringWidth / 2.0
                let y4 = yOffset - ModelConstant.ringWidth / 2.0

                positions.append(SIMD3<Float>(x1, y1, z1)) // #0
                positions.append(SIMD3<Float>(x2, y2, z2)) // #1
                positions.append(SIMD3<Float>(x1, y3, z1)) // #2
                positions.append(SIMD3<Float>(x2, y4, z2)) // #3

                if month == 11 {
                    lastPositions = []
                    lastPositions.append(SIMD3<Float>(x1, y1, z1)) // #0
                    lastPositions.append(SIMD3<Float>(x2, y2, z2)) // #1
                    lastPositions.append(SIMD3<Float>(x1, y3, z1)) // #2
                    lastPositions.append(SIMD3<Float>(x2, y4, z2)) // #3
                }
            }

            for edge in 0 ..< edgeCount {
                let stride = UInt32(edge * 4)
                indexes.append(contentsOf: [4 + stride, 0 + stride, 5 + stride,
                                            5 + stride, 0 + stride, 1 + stride,
                                            5 + stride, 1 + stride, 7 + stride,
                                            7 + stride, 1 + stride, 3 + stride,
                                            7 + stride, 3 + stride, 6 + stride,
                                            6 + stride, 3 + stride, 2 + stride,
                                            6 + stride, 2 + stride, 4 + stride,
                                            4 + stride, 2 + stride, 0 + stride])
            }

            var descriptor = MeshDescriptor()
            descriptor.positions = MeshBuffers.Positions(positions)
            descriptor.primitives = .triangles(indexes)
            descriptor.materials = .allFaces(0) // .perFace([0])

            let aveTemperature = ClimateModel.average(index: year)
            if let meshResource = try? MeshResource.generate(from: [descriptor]) {
                let model = ModelEntity(mesh: meshResource,
                                        materials: [material(temperature: aveTemperature, alpha: 0.5)])

//                model.modelDebugOptions = ModelDebugOptionsComponent(visualizationMode: .normal)

                ringModelEntities.append(model)
            } else {
                fatalError("failed to generate meshResource.")
            }
        }
    }
    // swiftlint:enable identifier_name
    // swiftlint:enable function_body_length
}

// MARK: - Animation

extension SpiralModel {
    func resetAnimation() {
        animatingStep = 0
        ringModelEntities.forEach { entity in
            entity.isEnabled = false
        }
        labelModelEntities.forEach { entity in
            entity.isEnabled = false
        }
        emitterEntity.components[ParticleEmitterComponent.self]?.simulationState = .pause
    }

    func playAnimationNext() {
        guard animatingStep < ringModelEntities.count else { return }
        guard animatingStep < labelModelEntities.count else { return }

        ringModelEntities[animatingStep].isEnabled = true
        if animatingStep % 10 == 0 {
            labelModelEntities[animatingStep].isEnabled = true
        }
        //    if animatingStep != 0 {
        //        labelModelEntities[animatingStep - 1].isEnabled = false
        //    }

        animatingStep += 1

        // When the animation ends, start playing the particle.
        if animatingStep == ringModelEntities.count {
            emitterEntity.components[ParticleEmitterComponent.self]?.simulationState = .play
        }
    }
}

// MARK: - Helper

extension SpiralModel {
    //    SIMD3<Float>(0.0, 0.0, 1.0), // blue   -1.0 [Celsius]
    //    SIMD3<Float>(0.0, 1.0, 1.0), // cyan   -0.5
    //    SIMD3<Float>(1.0, 1.0, 1.0), // white   0.0
    //    SIMD3<Float>(1.0, 0.5, 0.0), // orange  0.5
    //    SIMD3<Float>(1.0, 0.0, 0.0)]  // red    1.0
    private func material(temperature: Float, alpha: CGFloat = 1.0) -> SimpleMaterial {
        var red: CGFloat, green: CGFloat, blue: CGFloat
        if temperature <= -1.0 { // blue
            red = 0.0
            green = 0.0
            blue = 1.0
        } else if temperature <= -0.5 { // blue -> cyan
            let temp = (temperature + 1.0) * 2.0
            red = 0.0
            green = CGFloat(temp)
            blue = 1.0
        } else if temperature <= 0 { // cyan -> white
            let temp = (temperature + 0.5) * 2.0
            red = CGFloat(temp)
            green = 1.0
            blue = 1.0
        } else if temperature <= 0.5 { // white -> orange
            red = 1.0
            green = 1.0 - CGFloat(temperature)
            blue = 1.0 - CGFloat(temperature * 2.0)
        } else if temperature <= 1.0 { // orange -> red
            let temp = temperature - 0.5
            red = 1.0
            green = 0.5 - CGFloat(temp)
            blue = 0.0
        } else { // red
            red = 1.0
            green = 0.0
            blue = 0.0
        }

        return SimpleMaterial(color: UIColor(red: red, green: green, blue: blue, alpha: alpha),
                              isMetallic: false)
    }

    // swiftlint:disable identifier_name
    private func generateCircleModel(radius: Float, width: Float, color: UIColor)
    -> ModelEntity {
        var positions: [SIMD3<Float>] = []
        var indexes: [UInt32] = []
        let edgeCount = 12

        for month in 0 ... 12 {
            let length = radius
            let length1 = length + width / 2.0
            let length2 = length - width / 2.0
            let theta = Float.pi / 2 - Float.pi / 6 * Float(month)
            let yOffset: Float = 0.0

            let x1 = length1 * cosf(theta)
            let z1 = -length1 * sinf(theta)
            let y1 = yOffset + width / 2.0
            let y3 = yOffset - width / 2.0

            let x2 = length2 * cosf(theta)
            let z2 = -length2 * sinf(theta)
            let y2 = yOffset + width / 2.0
            let y4 = yOffset - width / 2.0

            positions.append(SIMD3<Float>(x1, y1, z1)) // #0
            positions.append(SIMD3<Float>(x2, y2, z2)) // #1
            positions.append(SIMD3<Float>(x1, y3, z1)) // #2
            positions.append(SIMD3<Float>(x2, y4, z2)) // #3
        }

        for edge in 0 ..< edgeCount {
            let stride = UInt32(edge * 4)
            indexes.append(contentsOf: [4 + stride, 0 + stride, 5 + stride,
                                        5 + stride, 0 + stride, 1 + stride,
                                        5 + stride, 1 + stride, 7 + stride,
                                        7 + stride, 1 + stride, 3 + stride,
                                        7 + stride, 3 + stride, 6 + stride,
                                        6 + stride, 3 + stride, 2 + stride,
                                        6 + stride, 2 + stride, 4 + stride,
                                        4 + stride, 2 + stride, 0 + stride])
        }

        var descriptor = MeshDescriptor()
        descriptor.positions = MeshBuffers.Positions(positions)
        descriptor.primitives = .triangles(indexes)
        descriptor.materials = .allFaces(0) // .perFace([0])

        var model: ModelEntity
        if let meshResource = try? MeshResource.generate(from: [descriptor]) {
            let material = SimpleMaterial(color: color, isMetallic: false)
            model = ModelEntity(mesh: meshResource, materials: [material])
        } else {
            fatalError("failed to generate meshResource.")
        }

        return model
    }
    // swiftlint:enable identifier_name
}
