//
//  SettingsView.swift
//  SwiftFirebaseBootcamp
//
//  Created by Juan David Gutierrez Olarte on 18/09/25.
//

import SwiftUI

struct SettingsView: View {
    //MARK: BODY
    @State private var viewModel = SettingsViewModel()
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
            
            Button(role: .destructive) {
                viewModel.showDeleteConfirm = true
            } label: {
                Text("Delete account")
            }
            
            if viewModel.authProviders.contains(.email) {
                emailSection
            }
            
            if (viewModel.authUser?.isAnonymous ?? false) && viewModel.authProviders.isEmpty {
                anonymousSection
            }
            
        }
        .onAppear{
            viewModel.loadAuthProviders()
            viewModel.loadAuthUser()
        }
        .navigationTitle("Settings")
        // Alert de confirmación (usa tu helper existente)
        .destructiveConfirm(
            isPresented: $viewModel.showDeleteConfirm,
            config: DestructiveConfirmConfig(
                title: "Permanently delete your account?",
                message: "This action will permanently delete your account and associated profile data from our servers. This cannot be undone."
            )
        ) {
            Task {
                await viewModel.startDeleteFlow {
                    // onSignedOut:
                    showSignInView = true
                }
            }
        }
        
        // Sheet para password (email-only)
        .sheet(isPresented: $viewModel.showPasswordSheet) {
            passwordReauthSheet
        }
        .sheet(isPresented: $viewModel.showLinkEmailSheet) {
            linkEmailSheet
        }
        .sheet(isPresented: $viewModel.showUpdateEmailSheet) {
            updateEmailSheet
        }
        .sheet(isPresented: $viewModel.showUpdatePasswordSheet) {
            updatePasswordSheet
        }
        .alert("All set", isPresented: $viewModel.showInfoAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.infoAlertMessage ?? "")
        }
        .alert(viewModel.errorAlertTitle, isPresented: $viewModel.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorAlertMessage ?? "")
        }
    }
}

// MARK: PREVIEW

#Preview {
    NavigationStack{
        SettingsView(showSignInView: .constant(false))
    }
}

// MARK: EMAIL SECTION

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
                        viewModel.showError(error.localizedDescription, title: "Couldn't reset password")
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
                        viewModel.showError(error.localizedDescription, title: "Couldn't update password")
                    }
                }
            }
            Button("Update Email") {
                viewModel.beginUpdateEmail(currentEmail: viewModel.authUser?.email)

            }
        } header: {
            Text("Email functions")
        }
    }
    private var passwordReauthSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Removed duplicate heading
                Text("For security, please re-enter your password to delete your account.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                SecureField("Password", text: $viewModel.typedPassword)
                    .textContentType(.password)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                if let msg = viewModel.formError, !msg.isEmpty {
                    Text(msg)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                }

                HStack {
                    Button("Cancel") {
                        viewModel.showPasswordSheet = false
                        viewModel.typedPassword = ""
                        viewModel.formError = nil
                    }
                    .frame(maxWidth: .infinity)

                    Button("Continue", role: .destructive) {
                        Task {
                            await viewModel.confirmDeleteWithPassword {
                                // onSignedOut:
                                showSignInView = true
                            }
                        }
                    }
                    .disabled(viewModel.typedPassword.isEmpty)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)

                Spacer(minLength: 12)
            }
            .navigationTitle("Re-authenticate")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.fraction(0.42), .medium])
            .presentationDragIndicator(.visible)
        }
    }
    // MARK: ANONYMOUS SECTION
    private var anonymousSection: some View {
        Section {
            Button("Link Google Account") {
                Task {
                    do {
                        try await viewModel.linkGoogleAccount()
                        print("GOOGLE LINKED")
                    }
                    catch {
                        print("Error: \(error)")
                        viewModel.showError(error.localizedDescription, title: "Couldn't link Google account")
                    }
                }
            }
            
            Button("Link Apple Account") {
                Task {
                    do {
                        try await viewModel.linkAppleAccount()
                        print("APPLE LINKED")
                    }
                    catch {
                        print("Error: \(error)")
                        viewModel.showError(error.localizedDescription, title: "Couldn't link Apple account")
                    }
                }
            }
            Button("Link Email Account") {
                viewModel.beginLinkEmail()
            }
        } header: {
            Text("Create Account")
        }
    }
    
    // MARK: - Link Email Sheet
    
    private var linkEmailSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Removed duplicate heading
                TextField("Email", text: $viewModel.linkEmail)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                SecureField("New password", text: $viewModel.linkPassword)
                    .textContentType(.newPassword)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                if let msg = viewModel.linkFormError, !msg.isEmpty {
                    Text(msg)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                }

                HStack {
                    Button("Cancel", role: .destructive) {
                        viewModel.showLinkEmailSheet = false
                    }
                    .frame(maxWidth: .infinity)

                    Button("Link") {
                        Task { await viewModel.submitLinkEmail() }
                    }
                    .disabled(viewModel.linkEmail.isEmpty || viewModel.linkPassword.isEmpty || viewModel.linkIsWorking)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)

                Spacer(minLength: 12)
            }
            .navigationTitle("Add email login")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.fraction(0.4), .medium])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Update Email Sheet
    private var updateEmailSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Removed duplicate heading
                TextField("New email", text: $viewModel.newEmail)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                if viewModel.authProviders.contains(.email) {
                    Text("For security, please enter your current password.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    SecureField("Current password", text: $viewModel.updateEmailCurrentPassword)
                        .textContentType(.password)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                }

                Text("We’ll send a verification email to your new address. The change completes after you confirm the link.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if let msg = viewModel.updateFormError, !msg.isEmpty {
                    Text(msg)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                }

                HStack {
                    Button("Cancel") {
                        viewModel.showUpdateEmailSheet = false
                    }
                    .frame(maxWidth: .infinity)

                    Button("Send verification") {
                        Task { await viewModel.submitUpdateEmail() }
                    }
                    .disabled(viewModel.updateIsWorking ||
                              viewModel.newEmail.isEmpty ||
                              (viewModel.authProviders.contains(.email) && viewModel.updateEmailCurrentPassword.isEmpty))
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)

                Spacer(minLength: 12)
            }
            .navigationTitle("Update email")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.fraction(0.4)])
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Update Password Sheet
    private var updatePasswordSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Removed duplicate heading
                SecureField("Current password", text: $viewModel.currentPassword)
                    .textContentType(.password)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                SecureField("New password", text: $viewModel.newPassword)
                    .textContentType(.newPassword)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                SecureField("Confirm new password", text: $viewModel.confirmNewPassword)
                    .textContentType(.newPassword)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                if let msg = viewModel.updatePassFormError, !msg.isEmpty {
                    Text(msg)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                }

                HStack {
                    Button("Cancel") {
                        viewModel.showUpdatePasswordSheet = false
                        viewModel.currentPassword = ""
                        viewModel.newPassword = ""
                        viewModel.confirmNewPassword = ""
                        viewModel.updatePassFormError = nil
                    }
                    .frame(maxWidth: .infinity)

                    Button("Update") {
                        Task { await viewModel.submitUpdatePassword() }
                    }
                    .disabled(viewModel.updatePassIsWorking || viewModel.currentPassword.isEmpty || viewModel.newPassword.isEmpty || viewModel.confirmNewPassword.isEmpty)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)

                Spacer(minLength: 12)
            }
            .navigationTitle("Update password")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.fraction(0.4)])
            .presentationDragIndicator(.visible)
        }
    }
    
    
}
