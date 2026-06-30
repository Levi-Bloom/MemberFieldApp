import Foundation
import Supabase

enum AuthError: LocalizedError {
    case notConfigured
    case invalidCredentials
    case message(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            "Configure Supabase credentials in AppConfig.swift or environment variables."
        case .invalidCredentials:
            "Invalid email or password."
        case .message(let text):
            text
        }
    }
}

@MainActor
final class AuthService {
    private var client: SupabaseClient { SupabaseManager.shared.client }

    func signIn(email: String, password: String) async throws {
        guard AppConfig.isConfigured else { throw AuthError.notConfigured }
        do {
            _ = try await client.auth.signIn(email: email.trimmingCharacters(in: .whitespaces), password: password)
        } catch {
            throw AuthError.message(error.localizedDescription)
        }
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func changePassword(newPassword: String) async throws {
        guard AppConfig.isConfigured else { throw AuthError.notConfigured }
        try await client.auth.update(user: UserAttributes(password: newPassword))
    }

    func currentUserID() async -> UUID? {
        try? await client.auth.session.user.id
    }

    func currentUserEmail() async -> String? {
        try? await client.auth.session.user.email
    }

    func observeAuthState(onChange: @escaping (UUID?) -> Void) -> Task<Void, Never> {
        Task {
            for await (_, session) in client.auth.authStateChanges {
                onChange(session?.user.id)
            }
        }
    }
}
