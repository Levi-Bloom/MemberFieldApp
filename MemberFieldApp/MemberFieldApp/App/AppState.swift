import Foundation
import Observation
import Supabase

enum AppRoute: Equatable {
    case loading
    case splash
    case onboardingProfile
    case onboardingPayment
    case main
}

@MainActor
@Observable
final class AppState {
    var route: AppRoute = .loading
    var session: SessionContext?
    var person: Person?
    var errorMessage: String?
    var isBusy = false

    private let authService = AuthService()
    private let sessionService = SessionService()
    private let portalService = PortalService()
    private var authObserver: Task<Void, Never>?

    func bootstrap() {
        authObserver?.cancel()
        authObserver = authService.observeAuthState { [weak self] userID in
            Task { @MainActor in
                if userID != nil {
                    await self?.refreshSession()
                } else {
                    self?.session = nil
                    self?.person = nil
                    self?.route = .splash
                }
            }
        }
        Task { await refreshSession() }
    }

    func refreshSession() async {
        isBusy = true
        defer { isBusy = false }
        errorMessage = nil

        do {
            let context = try await sessionService.loadSessionContext()
            session = context

            if let peopleID = context.peopleID {
                person = try await portalService.fetchPerson(peopleID: peopleID, userID: context.userID)
            }

            route = resolveRoute(for: context)
        } catch {
            session = nil
            person = nil
            route = .splash
            if await shouldShowSessionError(for: error) {
                errorMessage = MemberPortalErrorMapper.userMessage(for: error)
            }
        }
    }

    func signIn(email: String, password: String) async {
        isBusy = true
        defer { isBusy = false }
        errorMessage = nil

        do {
            try await authService.signIn(email: email, password: password)
            await refreshSession()
            if route == .splash, session == nil, errorMessage == nil {
                errorMessage = "Signed in, but your account could not be loaded. Try again or contact your society administrator."
            }
        } catch {
            errorMessage = MemberPortalErrorMapper.userMessage(for: error)
        }
    }

    func signOut() async {
        isBusy = true
        defer { isBusy = false }
        try? await authService.signOut()
        session = nil
        person = nil
        route = .splash
    }

    func changePassword(_ password: String) async throws {
        try await authService.changePassword(newPassword: password)
    }

    private func resolveRoute(for context: SessionContext) -> AppRoute {
        if let onboarding = context.memberOnboarding {
            if onboarding.needsProfile { return .onboardingProfile }
            if onboarding.needsPayment { return .onboardingPayment }
        }
        return .main
    }

    private func shouldShowSessionError(for error: Error) async -> Bool {
        if error is SessionError { return true }
        if await authService.currentUserID() != nil { return true }
        let message = error.localizedDescription.lowercased()
        return message.contains("session") || message.contains("auth")
    }
}
