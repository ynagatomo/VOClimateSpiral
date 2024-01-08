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
        ZStack {
            if showClimateSpiral {
                RealityView { content in
                    await ModelManager.shared.setupSpiralModel()
                    let entity = ModelManager.shared.spiralEntity
                    content.add(entity)
                    entity.scale = SIMD3<Float>(repeating: 0.4)
                }
            }

            VStack {
                Spacer()
                VStack {
                    Text("Tap the button below to see the Climate Spiral.")
                        .padding(.vertical, 24)
                    Toggle("Show Climate Spiral", isOn: $showClimateSpiral)
                        .toggleStyle(.button)
                }
                .padding(44)
                .glassBackgroundEffect()
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
