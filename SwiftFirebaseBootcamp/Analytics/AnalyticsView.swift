//
//  AnalyticsView.swift
//  SwiftFirebaseBootcamp
//
//  Created by Juan David Gutierrez Olarte on 13/10/25.
//
import SwiftUI
import FirebaseAnalytics

@MainActor
final class AnalyticsMAnager {
    static let shared = AnalyticsMAnager()
    private init(){}
    
    func logEvent(name: String, params: [String : Any]? = nil) {
        Analytics.logEvent(name, parameters: params)
    }
    
    func setUserId(userId: String) {
        Analytics.setUserID(userId)
    }
    func setUserProperty(value: String?, property: String) {
//        AnalyticsEventPurchase
        Analytics.setUserProperty(value, forName: property)
    }
}

struct AnalyticsView: View {
    var body: some View {
        VStack(spacing: 40) {
            Button("Click me") {
                AnalyticsMAnager.shared.logEvent(name: "AnalyticsView_ButtonClick")
            }
            Button("Click me too") {
                AnalyticsMAnager.shared.logEvent(name: "AnalyticsView_SecondaryButtonClick", params: [
                    "screen_title" : "Hello, world"
                ])
            }
        }
        .analyticsScreen(name: "analyticsView")
        .onAppear {
            AnalyticsMAnager.shared.logEvent(name: "AnalyticsView_Appear")
        }
        .onDisappear {
            AnalyticsMAnager.shared.logEvent(name: "AnalyticsView_Disappear")
            AnalyticsMAnager.shared.setUserId(userId: "ABC123")
            AnalyticsMAnager.shared.setUserProperty(value: true.description, property: "user_is_premium")
        }
    }
}

#Preview {
    AnalyticsView()
}
