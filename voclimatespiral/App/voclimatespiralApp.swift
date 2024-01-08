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

        WindowGroup("", id: "web") {
            WebpageView()
        }
        .windowStyle(.plain)
        .defaultSize(width: 400, height: 600)
    }
}
