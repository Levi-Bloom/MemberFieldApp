import SwiftUI

@main
struct MemberFieldAppApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView(appState: appState)
                .onAppear { appState.bootstrap() }
                .preferredColorScheme(.light)
                .tint(AppTheme.primaryText)
                .memberPortalText()
        }
    }
}
