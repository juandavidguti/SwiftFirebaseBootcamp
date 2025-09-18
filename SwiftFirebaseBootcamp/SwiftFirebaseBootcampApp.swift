//
//  SwiftFirebaseBootcampApp.swift
//  SwiftFirebaseBootcamp
//
//  Created by Juan David Gutierrez Olarte on 18/09/25.
//

import SwiftUI
import Firebase

@main
struct SwiftFirebaseBootcampApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        print("Configured Firebase!")
        return true
    }
}
