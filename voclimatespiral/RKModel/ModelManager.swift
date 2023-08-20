//
//  ModelManager.swift
//  voclimatespiral
//
//  Created by Yasuhito Nagatomo on 2023/08/19.
//

import RealityKit

@MainActor
final class ModelManager {
    static let shared = ModelManager()

    var spiralEntity: Entity {
        spiralModel.baseEntity
    }

    private init() {}
    private let spiralModel = SpiralModel()

    func setupSpiralModel() async {
        await spiralModel.generateModel()
        spiralModel.resetAnimation()
    }

    func playAnimation() {
        spiralModel.playAnimationNext()
    }

    func restartAnimation() {
        spiralModel.resetAnimation()
    }
}
