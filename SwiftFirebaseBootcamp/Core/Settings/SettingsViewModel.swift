//
//  SettingsViewModel.swift
//  SwiftFirebaseBootcamp
//
//  Created by Juan David Gutierrez Olarte on 22/09/25.
//

import Foundation
import FirebaseAuth

@MainActor
@Observable final class SettingsViewModel {

  var authProviders: [AuthProviderOption] = []
    var authUser: AuthDataResultModel? = nil


    // MARK: UI for DELETE FLOW
    var showDeleteConfirm = false
    var showPasswordSheet = false
    var typedPassword = ""
    var isWorking = false
    var formError: String? = nil
    
    // MARK: - UI state for Link Email
    var showLinkEmailSheet = false
    var linkEmail = ""
    var linkPassword = ""
    var linkFormError: String? = nil
    var linkIsWorking = false

    // MARK: - UI state for Update Email
    var showUpdateEmailSheet = false
    var newEmail = ""
    var updateFormError: String? = nil
    var updateIsWorking = false
    var updateEmailCurrentPassword = ""

    // MARK: - UI state for Update Password
    var showUpdatePasswordSheet = false
    var currentPassword = ""
    var newPassword = ""
    var confirmNewPassword = ""
    var updatePassFormError: String? = nil
    var updatePassIsWorking = false

    // MARK: - UI state for generic success feedback
    var showInfoAlert = false
    var infoAlertMessage: String? = nil

    // MARK: - UI state for generic error feedback
    var showErrorAlert = false
    var errorAlertTitle: String = "Something went wrong"
    var errorAlertMessage: String? = nil

    // MARK: - Actions

    func beginLinkEmail() {
        linkEmail = ""
        linkPassword = ""
        linkFormError = nil
        showLinkEmailSheet = true
    }

    func submitLinkEmail() async {
        guard !linkIsWorking else { return }
        linkIsWorking = true
        defer { linkIsWorking = false }

        // Validación mínima
        guard linkEmail.contains("@"), linkEmail.contains(".") else {
            linkFormError = "Please enter a valid email."
            return
        }
        guard linkPassword.count >= 6 else {
            linkFormError = "Password must be at least 6 characters."
            return
        }

        do {
            // Intento directo
            _ = try await AuthenticationManager.shared.linkEmail(email: linkEmail, password: linkPassword)
            // Éxito
            showLinkEmailSheet = false
            linkFormError = nil
            loadAuthProviders()

        } catch {
            if let ns = error as NSError?, ns.domain == AuthErrorDomain,
               let code = AuthErrorCode(rawValue: ns.code) {
                switch code {
                case .requiresRecentLogin:
                    do {
                        try await reauthWithCurrentProvider()
                        let _ = try await AuthenticationManager.shared.linkEmail(email: linkEmail, password: linkPassword)
                        showLinkEmailSheet = false
                        linkFormError = nil
                        loadAuthProviders()
                    } catch {
                        linkFormError = decodeAuthError(error)
                    }
                    return
                case .credentialAlreadyInUse:
                    showError("This credential is already associated with a different user account. If it's yours, sign in instead and then link from Settings.", title: "Can't link email")
                    return
                case .emailAlreadyInUse:
                    showError("This email is already in use. If it's yours, try signing in instead.", title: "Can't link email")
                    return
                default:
                    break
                }
            }
            linkFormError = decodeAuthError(error)
        }
    }

    func beginUpdateEmail(currentEmail: String?) {
        newEmail = currentEmail ?? ""
        updateEmailCurrentPassword = ""
        updateFormError = nil
        showUpdateEmailSheet = true
    }

    func submitUpdateEmail() async {
        guard !updateIsWorking else { return }
        updateIsWorking = true
        defer { updateIsWorking = false }

        guard newEmail.contains("@"), newEmail.contains(".") else {
            updateFormError = "Please enter a valid email."
            return
        }
        do {
            // If the account uses email/password, require current password and reauthenticate first
            if authProviders.contains(.email) {
                guard !updateEmailCurrentPassword.isEmpty else {
                    updateFormError = "Please enter your current password."
                    return
                }
                let currentEmail = authUser?.email ?? Auth.auth().currentUser?.email
                guard let currentEmail else {
                    updateFormError = "No email found for this account."
                    return
                }
                let cred = EmailAuthProvider.credential(withEmail: currentEmail, password: updateEmailCurrentPassword)
                try await Auth.auth().currentUser?.reauthenticate(with: cred)
            }
            try await AuthenticationManager.shared.updateEmail(email: newEmail)
            // Se envía un email de verificación al NUEVO email; el cambio se aplica cuando lo confirme.
            showUpdateEmailSheet = false
            updateFormError = nil
            loadAuthUser()
            loadAuthProviders()
            showInfo("We sent a verification link to \(newEmail). Please confirm it to complete the change.")
        } catch {
            if let ns = error as NSError?, ns.domain == AuthErrorDomain,
               let code = AuthErrorCode(rawValue: ns.code), code == .requiresRecentLogin {
                do {
                    try await reauthWithCurrentProvider()
                    try await AuthenticationManager.shared.updateEmail(email: newEmail)
                    showUpdateEmailSheet = false
                    updateFormError = nil
                    loadAuthUser()
                    loadAuthProviders()
                    showInfo("We sent a verification link to \(newEmail). Please confirm it to complete the change.")
                } catch {
                    updateFormError = decodeAuthError(error)
                }
            } else {
                updateFormError = decodeAuthError(error)
            }
        }
    }

    // MARK: LOAD
    func loadAuthProviders()  {
        if let providers = try? AuthenticationManager.shared.getProviders() {
            authProviders = providers
        }
    }
    
    func loadAuthUser()  {
        self.authUser = try? AuthenticationManager.shared.getAuthenticatedUser()
    }
    
// MARK: SIGNOUT & RESET PASS
    func signOut() throws {
        try AuthenticationManager.shared.signOut()
    }

    func resetPassword() async throws {
        let authUser = try AuthenticationManager.shared.getAuthenticatedUser()
        guard let email = authUser.email else { throw URLError(.fileDoesNotExist) }
        try await AuthenticationManager.shared.resetPassword(email: email)
        showInfo("Check your email to reset your password.")
    }

    func updatePassword() async throws {
        // Open Update Password sheet instead of hardcoding a value
        updatePassFormError = nil
        currentPassword = ""
        newPassword = ""
        confirmNewPassword = ""
        showUpdatePasswordSheet = true
    }
    
    /// Validates inputs, reauthenticates with the current password, then updates to the new password.
    func submitUpdatePassword() async {
        guard !updatePassIsWorking else { return }
        updatePassIsWorking = true
        defer { updatePassIsWorking = false }

        // Must have email/password provider linked
        guard authProviders.contains(.email) else {
            updatePassFormError = "Email & password are not linked to this account."
            return
        }
        // Validate fields
        guard !currentPassword.isEmpty else {
            updatePassFormError = "Please enter your current password."
            return
        }
        guard newPassword.count >= 6 else {
            updatePassFormError = "New password must be at least 6 characters."
            return
        }
        guard newPassword == confirmNewPassword else {
            updatePassFormError = "New passwords do not match."
            return
        }
        guard let email = authUser?.email ?? Auth.auth().currentUser?.email else {
            updatePassFormError = "No email found for this account."
            return
        }

        do {
            // Reauthenticate with current password
            let cred = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
            try await Auth.auth().currentUser?.reauthenticate(with: cred)
            // Update to new password
            try await AuthenticationManager.shared.updatePassword(password: newPassword)
            // Success: close sheet and clear state
            showUpdatePasswordSheet = false
            updatePassFormError = nil
            currentPassword = ""
            newPassword = ""
            confirmNewPassword = ""
            showInfo("Your password has been updated.")
        } catch {
            if let ns = error as NSError?, ns.domain == AuthErrorDomain,
               let code = AuthErrorCode(rawValue: ns.code) {
                switch code {
                    case .wrongPassword:
                        updatePassFormError = "Incorrect current password."
                    case .requiresRecentLogin:
                        updatePassFormError = "Please sign in again and retry."
                    case .invalidCredential:
                        updatePassFormError = "Incorrect current password."
                    default:
                        updatePassFormError = error.localizedDescription
                }
            } else {
                updatePassFormError = error.localizedDescription
            }
        }
    }
    
    // MARK: LINKING ACCOUNTS
    
    func linkGoogleAccount() async throws {
        let helper = SignInGoogleHelper()
        let tokens = try await helper.signIn()
        self.authUser  = try await AuthenticationManager.shared.linkGoogle(tokens: tokens)
        loadAuthProviders()
    }
    
    func linkAppleAccount() async throws {
        let helper = SignInAppleHelper()
        let tokens = try await helper.startSignInWithAppleFlow()
        self.authUser = try await AuthenticationManager.shared.linkApple(tokens: tokens)
        loadAuthProviders()
    }
    
    
    // MARK: - DELETE FLOW

    /// Usuario pulsa “Delete” y confirma en el alert.
    func startDeleteFlow(onSignedOut: @escaping () -> Void) async {
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }

        do {
            // Llama a TU único punto de verdad:
            // - Si Google/Apple, reauth interna con credential y borra
            // - Si email-only y falta password, lanzará SecureDeleteError.emailPasswordRequired
            try await AuthenticationManager.shared.delete(reauthEmailPassword: nil)
            try AuthenticationManager.shared.signOut()
            onSignedOut()
        } catch let error as AuthenticationManager.SecureDeleteError {
            switch error {
            case .emailPasswordRequired:
                // Pedimos contraseña en sheet
                typedPassword = ""
                formError = nil
                showPasswordSheet = true
            default:
                // accountSwitchDetected / not supported / missingEmail, etc.
                formError = error.localizedDescription
                print("Delete flow error:", error)
            }
        } catch {
            formError = error.localizedDescription
            print("Delete failed:", error)
        }
    }

    // MARK: CONFIRMATION RE-AUTH
    /// Usuario escribe password en la sheet y confirma.
    func confirmDeleteWithPassword(onSignedOut: @escaping () -> Void) async {
        guard !typedPassword.isEmpty else {
            formError = "Please enter your password."
            return
        }

        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }

        do {
            try await AuthenticationManager.shared.delete(reauthEmailPassword: typedPassword)
            try AuthenticationManager.shared.signOut()
            showPasswordSheet = false
            onSignedOut()
        } catch {
            // Opcional: decodificar errores de Firebase para UX más clara
            if let ns = error as NSError?,
               ns.domain == AuthErrorDomain,
               ns.code == AuthErrorCode.wrongPassword.rawValue {
                formError = "Incorrect password. Please try again."
            } else {
                formError = error.localizedDescription
            }
            print("Delete with password error:", error)
        }
    }
    
    // MARK: RESET EMAIL AND PASS
    
    /// Reautentica con el provider actual (Google/Apple). No necesita password.
    private func reauthWithCurrentProvider() async throws {
        let providers = try AuthenticationManager.shared.getProviders()
        if providers.contains(.google) {
            let tokens = try await SignInGoogleHelper().signIn()
            let credential = GoogleAuthProvider.credential(withIDToken: tokens.idToken, accessToken: tokens.accessToken)
            try await Auth.auth().currentUser?.reauthenticate(with: credential)
        } else if providers.contains(.apple) {
            let tokens = try await SignInAppleHelper().startSignInWithAppleFlow()
            let credential = OAuthProvider.appleCredential(withIDToken: tokens.token, rawNonce: tokens.nonce, fullName: tokens.fullName)
            try await Auth.auth().currentUser?.reauthenticate(with: credential)
        } else {
            // Si el usuario ya es email/password, la reauth típica es pidiendo de nuevo la contraseña.
            // Puedes reutilizar tu password sheet si quieres cubrir este caso aquí también.
            throw NSError(domain: AuthErrorDomain, code: AuthErrorCode.operationNotAllowed.rawValue)
        }
    }

    /// Mensajes de error más claros
    private func decodeAuthError(_ error: Error) -> String {
        guard let ns = error as NSError?, ns.domain == AuthErrorDomain,
              let code = AuthErrorCode(rawValue: ns.code) else {
            return error.localizedDescription
        }
        switch code {
            case .emailAlreadyInUse:
                return "This email is already in use."
            case .credentialAlreadyInUse:
                return "This credential is already associated with a different user account."
            case .invalidEmail:
                return "The email address is badly formatted."
            case .weakPassword:
                return "Password is too weak."
            case .requiresRecentLogin:
                return "For security, please re-authenticate and try again."
            case .invalidCredential:
                return "Incorrect password. Please try again."
            default:
                return error.localizedDescription
        }
    }

    // MARK: - Generic info feedback helper
    func showInfo(_ message: String) {
        infoAlertMessage = message
        showInfoAlert = true
    }
    
    // MARK: - Generic error feedback helper
    func showError(_ message: String, title: String = "Something went wrong") {
        // Ensure info alert is not showing simultaneously
        showInfoAlert = false
        errorAlertTitle = title
        errorAlertMessage = message
        showErrorAlert = true
    }
}
