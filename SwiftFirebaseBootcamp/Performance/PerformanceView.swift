//
//  PerformanceView.swift
//  SwiftFirebaseBootcamp
//
//  Created by Juan David Gutierrez Olarte on 13/10/25.
//
import SwiftUI

struct PerformanceView: View {
    @Environment(\.performanceService) var performanceService
    
    // whenever I want to run a diagnosis of performance I cast the Performance Manager singleton and just add a name to the trace. This is only for appstart, foreground, background and loading duration.
    @State private var traceName: String = "performanceTest2"
    
    var body: some View {
        Text("Hello World")
            .task {
                await performanceService.start(traceName)
                do {
                    let data: Data = try await performanceService.trace(name: "loading_helloworld", attributes: ["test": "hello"]) {
                        try await performanceService.get(url: URL(string: "https://dummyjson.com/products")!)
                    }
                } catch {
                    print("Perf demo error:", error)
                }
            }
            .onDisappear{
                Task { await performanceService.stop(traceName) }
            }
    }
}

#Preview {
    PerformanceView()
}
