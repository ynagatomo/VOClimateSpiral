//
//  ContentView.swift
//  voclimatespiral
//
//  Created by Yasuhito Nagatomo on 2023/08/19.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @Environment(\.openWindow) private var openWindow
    @State private var showClimateSpiral = false

    var body: some View {
        VStack {
            VStack {
                Text("Tap the button below to see the Climate Spiral.")
                    .padding(.vertical, 24)

                Toggle("Show Climate Spiral", isOn: $showClimateSpiral)
                    .toggleStyle(.button)
            }
            .padding(44)
            .glassBackgroundEffect()

            if showClimateSpiral {
                RealityView { content in
                    // note: this empty Scene is needed at this moment (I don't know why.)
                    if let scene = try? await Entity(named: "Scene", in: realityKitContentBundle) {
                        content.add(scene)
                    }

                    // generate the Climate Spiral geometry and attach it to the content
                    await ModelManager.shared.setupSpiralModel()
                    let entity = ModelManager.shared.spiralEntity
                    entity.transform.translation = SIMD3<Float>(0.7, 0, 0) // offset for the control panel
                    content.add(entity)
                }
                .frame(width: 200, height: 400)
            } else {
                Color(.clear)                    // Spacer to place the control panel at the same position
                    .frame(width: 200, height: 400)
            }
        }
        .onAppear {
            openWindow(id: "web")   // Shows related information with a WebView
        }
    }
}

#Preview {
    ContentView()
}
