import SwiftUI

struct SplashView: View {
    @Bindable var appState: AppState
    @State private var showLoginSheet = false

    var body: some View {
        ZStack {
            AppTheme.pageGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 20) {
                    OriginLogoView(maxWidth: 220)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 32)
                        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .shadow(color: AppTheme.cardShadow, radius: 20, y: 10)

                    VStack(spacing: 8) {
                        Text("Member Portal")
                            .font(.title3.weight(.semibold))
                        Text("Access your society registry, animals, and account from anywhere.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                }

                Spacer()

                VStack(spacing: 12) {
                    if let error = appState.errorMessage, !showLoginSheet {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Button("Log In") {
                        appState.errorMessage = nil
                        showLoginSheet = true
                    }
                    .buttonStyle(PrimaryBrandButtonStyle())
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
        .sheet(isPresented: $showLoginSheet) {
            LoginView(appState: appState)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: appState.route) { _, route in
            if route != .splash {
                showLoginSheet = false
            }
        }
    }
}
