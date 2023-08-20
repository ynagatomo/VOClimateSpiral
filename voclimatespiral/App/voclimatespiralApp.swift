//
//  voclimatespiralApp.swift
//  voclimatespiral
//
//  Created by Yasuhito Nagatomo on 2023/08/19.
//

import SwiftUI

@main
struct VOClimateSpiralApp: App {

    init() {
        SpiralAnimationComponent.registerComponent()
        SpiralAnimationSystem.registerSystem()
    }

    var body: some Scene {
        WindowGroup("", id: "main") {
            ContentView()
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 4000, height: 3000, depth: 3000)

        WindowGroup("", id: "web") {
            WebpageView()
        }
        .windowStyle(.plain)
        .defaultSize(width: 400, height: 600)
    }
}
