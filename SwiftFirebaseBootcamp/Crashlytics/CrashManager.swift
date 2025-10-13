//
//  CrashManager.swift
//  SwiftFirebaseBootcamp
//
//  Created by Juan David Gutierrez Olarte on 13/10/25.
//

import SwiftUI
import FirebaseCrashlytics

final class CrashManager {
    @MainActor static let shared = CrashManager()
    
    private init() {}
    
    func setUserId(userId: String) {
        Crashlytics.crashlytics().setUserID(userId)
    }
    
    private func setValue(value: String, key: String) {
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
    }
    
    func setIsPremiumValue(isPremium: Bool) {
        setValue(value: isPremium.description.lowercased(), key: "user_is_premium")
    }
    
    func addLog(msg: String){
        Crashlytics.crashlytics().log(msg)
    }
    
    func sendNonFatal(error: Error){
        Crashlytics.crashlytics().record(error: error)
    }
}
