//
//  AuthenticationManager.swift
//  SwiftFirebaseBootcamp
//
//  Created by Juan David Gutierrez Olarte on 18/09/25.
//

import Foundation
import FirebaseAuth

struct AuthDataResultModel {
    let uid: String
    let email: String?
    let photoURL: String?
    let isAnonymous: Bool
    
    init(user: User) {
        self.uid = user.uid
        self.email = user.email
        self.photoURL = user.photoURL?.absoluteString
        self.isAnonymous = user.isAnonymous
    }
}

enum AuthProviderOption: String {
    case email = "password"
    case google = "google.com"
    case apple = "apple.com"
}


final class AuthenticationManager: Sendable {
    
    static let shared = AuthenticationManager()
    private init () {}
    
    
    func getAuthenticatedUser() throws -> AuthDataResultModel {
        guard let user = Auth.auth().currentUser else {
            throw URLError(.badServerResponse)
        }
        
        return AuthDataResultModel(user: user)
    }
    
    // providers:
    // google.com
    // password = email
    func getProviders() throws -> [AuthProviderOption] {
        guard let providerData = Auth.auth().currentUser?.providerData else {
            throw URLError(.badServerResponse)
        }
        var providers: [AuthProviderOption] = []
        for provider in providerData {
            if let option = AuthProviderOption(rawValue: provider.providerID) {
                providers.append(option)
            } else {
//                fatalError() // this is a crash
                assertionFailure("Provider option not found: \(provider.providerID)")
            }
        }
        return providers
    }
    
    // MARK: SIGNOUT
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    // Añade este enum en el mismo archivo (arriba o junto a AuthenticationManager)
    enum SecureDeleteError: Error {
        case emailPasswordRequired
        case missingEmail
        case providerNotSupported
        case accountSwitchDetected
    }

    // MARK: DELETE
    
    func delete(reauthEmailPassword: String? = nil) async throws {
        // 1) Usuario actual
        guard let user = Auth.auth().currentUser else {
            throw URLError(.badURL)
        }
        let oldUID = user.uid

        // 2) Providers vinculados
        let providers = try getProviders()

        // 3) Reautenticación según provider (sin duplicar lógica)
        if providers.contains(.google) {
            // Usa tu helper para obtener tokens de Google
            let tokens = try await SignInGoogleHelper().signIn()
            let credential = GoogleAuthProvider.credential(
                withIDToken: tokens.idToken,
                accessToken: tokens.accessToken
            )
            try await user.reauthenticate(with: credential)
            
        } else if providers.contains(.apple) {
            // Usa tu helper para obtener tokens de Apple
            let tokens = try await SignInAppleHelper().startSignInWithAppleFlow()
            let credential = OAuthProvider.appleCredential(
                withIDToken: tokens.token,
                rawNonce: tokens.nonce,
                fullName: tokens.fullName
            )
            try await user.reauthenticate(with: credential)
            
        } else if providers.contains(.email) {
            // Email/password requiere password desde tu UI
            guard let email = user.email else { throw SecureDeleteError.missingEmail }
            guard let password = reauthEmailPassword, !password.isEmpty else {
                throw SecureDeleteError.emailPasswordRequired
            }
            
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            try await user.reauthenticate(with: credential)
            
        } else {
            throw SecureDeleteError.providerNotSupported
        }
        // 4) Seguridad extra: el UID NO debe cambiar
        let newUID = user.uid
        guard oldUID == newUID else {
            throw SecureDeleteError.accountSwitchDetected
        }
        try await user.delete()
    }
    
}

// MARK: SIGN IN Email

extension AuthenticationManager {
    @discardableResult
    func createUser(email: String, password: String) async throws -> AuthDataResultModel {
        let authDataResult = try await Auth.auth().createUser(withEmail: email, password: password)
        return AuthDataResultModel(user: authDataResult.user)
    }
    
    @discardableResult
    func signInUser(email: String, password: String) async throws -> AuthDataResultModel {
        let authDataResult = try await Auth.auth().signIn(withEmail: email,password: password)
        return AuthDataResultModel(user: authDataResult.user)
    }
    func resetPassword(email: String) async throws {
       try await Auth.auth().sendPasswordReset(withEmail: email)
    }
    
    func updateEmail(email: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw URLError(.badServerResponse)
        }
        try await user.sendEmailVerification(beforeUpdatingEmail: email)
    }
    
    func updatePassword(password: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw URLError(.badServerResponse)
        }
        
        try await user.updatePassword(to: password)
    }
    
}

// MARK: SIGN IN SSO

extension AuthenticationManager {
    
    @discardableResult
    func signInWithGoogle(tokens: GoogleSignInResultModel) async throws -> AuthDataResultModel {
        let credential = GoogleAuthProvider.credential(
            withIDToken: tokens.idToken,
            accessToken: tokens.accessToken)
        return try await signIn(credential: credential)
    }
    
    @discardableResult
    func signInWithApple(tokens: SignInWithAppleResult) async throws -> AuthDataResultModel {
        let credential = OAuthProvider.appleCredential(
            withIDToken: tokens.token,
            rawNonce: tokens.nonce,
            fullName: tokens.fullName)
        return try await signIn(credential: credential)
    }
    
    func signIn(credential: AuthCredential) async throws -> AuthDataResultModel {
        let authDataResult = try await Auth.auth().signIn(with: credential)
        return AuthDataResultModel(user: authDataResult.user)
    }
    
}

// MARK: ANONYMOUS & LINKING

extension AuthenticationManager {
    
    @discardableResult
    func signInAnonymous() async throws -> AuthDataResultModel {
        let authDataResult = try await Auth.auth().signInAnonymously()
        return AuthDataResultModel(user: authDataResult.user)
    }
    
    func linkEmail(email: String, password: String) async throws -> AuthDataResultModel {
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        return try await linkCredential(credential: credential)
    }
    
    func linkApple(tokens: SignInWithAppleResult) async throws -> AuthDataResultModel {
        let credential = OAuthProvider.appleCredential(
            withIDToken: tokens.token,
            rawNonce: tokens.nonce,
            fullName: tokens.fullName)
        return try await linkCredential(credential: credential)
    }
    
    func linkGoogle(tokens: GoogleSignInResultModel) async throws -> AuthDataResultModel {
        let credential = GoogleAuthProvider.credential(
            withIDToken: tokens.idToken,
            accessToken: tokens.accessToken)
        return try await linkCredential(credential: credential)
    }
    
    private func linkCredential(credential: AuthCredential) async throws -> AuthDataResultModel {
        guard let user = Auth.auth().currentUser else {
            throw URLError(.badServerResponse)
        }
        
        let authDataResult = try await user.link(with: credential)
        return AuthDataResultModel(user: authDataResult.user)
        
    }
    
}
