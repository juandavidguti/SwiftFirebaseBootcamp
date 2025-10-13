//
//  SignInEmailViewModel.swift
//  SwiftFirebaseBootcamp
//
//  Created by Juan David Gutierrez Olarte on 29/09/25.
//

import SwiftUI

@MainActor
final class SignInEmailViewModel: ObservableObject, Sendable {
    
    @Published var email = ""
    @Published var password = ""
    
    func signUp() async throws {
        guard !email.isEmpty, !password.isEmpty else { // to create validation to make it more secure.
            print("No email or password found!")
            return
        }
        let authDataResult = try await AuthenticationManager.shared
            .createUser(email: email, password: password)
        let user = DBUser(auth: authDataResult)
        try await UserManager.shared.createNewUser(user: user)
        
    }
    
    func signIn() async throws {
        guard !email.isEmpty, !password.isEmpty else { // to create validation to make it more secure.
            print("No email or password found!")
            return
        }
        try await AuthenticationManager.shared
            .signInUser(email: email, password: password)
        
    }
    
}
