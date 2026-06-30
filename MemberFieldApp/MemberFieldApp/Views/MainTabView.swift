import SwiftUI

struct MainTabView: View {
    @Bindable var appState: AppState
    let session: SessionContext

    @State private var selectedTab = 0
    @State private var quickActionDestination: QuickActionDestination?

    var body: some View {
        TabView(selection: $selectedTab) {
            PortalHomeView(
                appState: appState,
                session: session,
                onQuickAction: handleQuickAction,
                onOpenAccount: openAccount
            )
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(0)

            AnimalsListView(
                appState: appState,
                session: session,
                initialMode: quickActionMode,
                openNewRegistration: quickActionDestination == .newRegistration
            )
                .tabItem { Label("My Animals", systemImage: "pawprint.fill") }
                .tag(1)

            SocietyNewsView(session: session)
                .tabItem { Label("News", systemImage: "newspaper.fill") }
                .tag(2)

            AccountTabView(appState: appState, session: session)
                .tabItem { Label("Account", systemImage: "person.crop.circle.fill") }
                .tag(3)
        }
        .onChange(of: selectedTab) { _, newValue in
            if newValue != 1 { quickActionDestination = nil }
        }
    }

    private var quickActionMode: AnimalsListView.Mode? {
        guard let destination = quickActionDestination else { return nil }
        switch destination {
        case .transfer: return .transfer
        case .castrate: return .castrate
        case .death: return .death
        case .saleHireAI: return .saleHireAI
        case .checkMate: return .checkMate
        default: return nil
        }
    }

    private func handleQuickAction(_ destination: QuickActionDestination) {
        switch destination {
        case .myAnimals:
            selectedTab = 1
        case .newRegistration:
            selectedTab = 1
            quickActionDestination = .newRegistration
        default:
            selectedTab = 1
            quickActionDestination = destination
        }
    }

    private func openAccount() {
        selectedTab = 3
    }
}

struct AccountTabView: View {
    @Bindable var appState: AppState
    let session: SessionContext

    var body: some View {
        NavigationStack {
            AccountHubView(appState: appState, session: session)
        }
    }
}
