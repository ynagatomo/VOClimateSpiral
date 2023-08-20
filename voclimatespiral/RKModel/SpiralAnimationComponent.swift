//
//  SpiralAnimationComponent.swift
//  voclimatespiral
//
//  Created by Yasuhito Nagatomo on 2023/08/19.
//

import RealityKit
import RealityKitContent

public struct SpiralAnimationComponent: Component, Codable {
}

public struct SpiralAnimationSystem: System {
    private let frameSpeed = 3 // 5
    private var frameCount = 0

    public init(scene: RealityKit.Scene) {}

    public mutating func update(context: SceneUpdateContext) {
        frameCount += 1
        if frameCount > frameSpeed {
            ModelManager.shared.playAnimation()
            frameCount = 0
        }
    }
}
