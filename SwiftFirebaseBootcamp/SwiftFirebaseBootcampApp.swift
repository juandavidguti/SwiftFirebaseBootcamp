//
//  SwiftFirebaseBootcampApp.swift
//  SwiftFirebaseBootcamp
//
//  Created by Juan David Gutierrez Olarte on 18/09/25.
//

import SwiftUI
import Firebase
import GoogleSignIn

@main
struct SwiftFirebaseBootcampApp: App {
    
    // Without App Delegate
//    init() {
//        FirebaseApp.configure()
//        print("configure Firebase!")
//    }
    
    // With App delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
                RootView()
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
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Forward the URL to Google Sign-In to complete the auth flow (needed for some return paths)
        return GIDSignIn.sharedInstance.handle(url)
    }
}
