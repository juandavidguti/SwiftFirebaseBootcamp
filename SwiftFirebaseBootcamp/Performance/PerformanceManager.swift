//
//  PerformanceManager.swift
//  SwiftFirebaseBootcamp
//
//  Created by Juan David Gutierrez Olarte on 13/10/25.
//


import SwiftUI
import FirebasePerformance

// MARK: - Performance Service (SSV-friendly, no singletons)
actor PerformanceService {
    private var traces: [String: Trace] = [:]

    // Manual control (start / set attribute / stop)
    func start(_ name: String) {
        let trace = Performance.startTrace(name: name)
        traces[name] = trace
    }

    func set(_ name: String, value: String, for attribute: String) {
        traces[name]?.setValue(value, forAttribute: attribute)
    }

    func stop(_ name: String) {
        traces[name]?.stop()
        traces.removeValue(forKey: name)
    }

    // Scoped trace helper: measures the exact async work you pass in (no artificial delay)
    func trace<T>(name: String,attributes: [String: String] = [:],_ work: @Sendable () async throws -> T) async rethrows -> T {
        let trace = Performance.startTrace(name: name)
        for (key, value) in attributes {
            trace?.setValue(value, forAttribute: key)
        }
        defer { trace?.stop() }
        return try await work()
    }

    // MARK: - Network metrics
    // Wraps a real URLRequest with HTTPMetric and executes it via URLSession
    func monitor(request: URLRequest) async throws -> (Data, URLResponse) {
        guard let url = request.url else { throw URLError(.badURL) }
        
        // Try to create metric; if not possible, just perform the request
        let method = request.httpMethod ?? "GET"
        let httpMethod = HTTPMethod.get
        let metric = HTTPMetric(url: url, httpMethod: httpMethod)
        metric?.start()
        defer { metric?.stop() }
        let (data, response) = try await URLSession.shared.data(for: request)
        if let https = response as? HTTPURLResponse {
            metric?.responseCode = https.statusCode
        }
        return (data, response)
    }
    
    // Convenience for simple GETs
    func get(url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (data, _) = try await monitor(request: request)
        return data
    }
}

// MARK: - SwiftUI Environment injection (SSV)
private struct PerformanceServiceKey: EnvironmentKey {
    static let defaultValue: PerformanceService = PerformanceService()
}

extension EnvironmentValues {
    var performanceService: PerformanceService {
        get { self[PerformanceServiceKey.self] }
        set { self[PerformanceServiceKey.self] = newValue }
    }
}
