//
//  SettingsView.swift
//  SwiftFirebaseBootcamp
//
//  Created by Juan David Gutierrez Olarte on 18/09/25.
//

import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    
    func signOut() throws {
        try AuthenticationManager.shared.signOut()
    }
    
    func resetPassword() async throws {
        let authUser = try AuthenticationManager.shared.getAuthenticatedUser()
        
        guard let email = authUser.email else {
            throw URLError(.fileDoesNotExist)
        }
        try await AuthenticationManager.shared.resetPassword(email: email)
    }
    
    // this is for quick purposes. We should have validation and UI.
    func updateEmail() async throws {
        let email = "newEmail@example.com"
        try await AuthenticationManager.shared.updateEmail(email: email)
    }
    
    func updatePassword() async throws {
        let password = "AHdig1323"
        try await AuthenticationManager.shared.updateEmail(email: password)
    }
}


struct SettingsView: View {
    
    @StateObject private var viewModel = SettingsViewModel()
    @Binding var showSignInView: Bool
    
    var body: some View {
        List {
            Button("Log out") {
                Task {
                    do {
                        try viewModel.signOut()
                        showSignInView = true
                    }
                    catch {
                        print("Error: \(error)")
                    }
                }
            }
            emailSection
            
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack{
        SettingsView(showSignInView: .constant(false))
    }
}

extension SettingsView {
    private var emailSection: some View {
        Section {
            Button("Reset Password") {
                Task {
                    do {
                        try await viewModel.resetPassword()
                        print("Password reset")
                    }
                    catch {
                        print("Error: \(error)")
                    }
                }
            }
            
            Button("Update Password") {
                Task {
                    do {
                        try await viewModel.updatePassword()
                        print("Password UPDATED")
                    }
                    catch {
                        print("Error: \(error)")
                    }
                }
            }
            Button("Update Email") {
                Task {
                    do {
                        try await viewModel.updateEmail()
                        print("EMAIL UPDATED")
                    }
                    catch {
                        print("Error: \(error)")
                    }
                }
            }
        } header: {
            Text("Email functions")
        }
    }
}
