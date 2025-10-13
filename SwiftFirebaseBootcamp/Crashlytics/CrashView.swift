//
//  CrashView.swift
//  SwiftFirebaseBootcamp
//
//  Created by Juan David Gutierrez Olarte on 5/10/25.
//

import SwiftUI

struct CrashView: View {
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack {
                Button("click me 1") {
                    CrashManager.shared.addLog(msg: "button_1_clicked")

                    let myString: String? = nil
                    
                    guard let myString else {
                        CrashManager.shared.sendNonFatal(error: URLError(.dataNotAllowed))
                        return
                    }
                    
                    let string2 = myString
                }
                
                Button("Click me 2") {
                    CrashManager.shared.addLog(msg: "button_2_clicked")

                    fatalError("Crash was triggered")
                }
                
                Button("CLick me 3") {
                    CrashManager.shared.addLog(msg: "button_3_clicked")

                    let array: [String] = []
                    let item = array[0]
                }
            }
        }
        .onAppear {
            CrashManager.shared.setUserId(userId: "ABC123")
            CrashManager.shared.setIsPremiumValue(isPremium: true)
            CrashManager.shared.addLog(msg: "crash view appeared")
            CrashManager.shared.addLog(msg: "crash_view_appeared on user's screen.")
        }
    }
}

#Preview {
    CrashView()
}
