import SwiftUI

struct RootView: View {
    @Bindable var appState: AppState

    var body: some View {
        Group {
            switch appState.route {
            case .loading:
                ZStack {
                    AppTheme.pageGradient.ignoresSafeArea()
                    ProgressView("Loading…")
                        .tint(AppTheme.brand)
                }
            case .splash:
                SplashView(appState: appState)
            case .onboardingProfile:
                MemberProfileOnboardingView(appState: appState)
            case .onboardingPayment:
                MembershipPaymentView(appState: appState)
            case .main:
                if let session = appState.session {
                    MainTabView(appState: appState, session: session)
                } else {
                    ProgressView()
                        .tint(AppTheme.brand)
                }
            }
        }
        .animation(.easeInOut, value: appState.route)
    }
}
