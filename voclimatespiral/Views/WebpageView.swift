//
//  WebpageView.swift
//  voclimatespiral
//
//  Created by Yasuhito Nagatomo on 2023/08/19.
//

import SwiftUI
import WebKit

struct WebpageView: View {
    let nasaURL = "https://www.nasa.gov/press-release/nasa-clocks-july-2023-as-hottest-month-on-record-ever-since-1880"

    var body: some View {
        WebView(url: URL(string: nasaURL)!)
    }
}

#Preview {
    WebpageView()
}

struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
}
