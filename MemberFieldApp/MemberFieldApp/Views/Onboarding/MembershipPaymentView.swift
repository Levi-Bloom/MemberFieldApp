import SwiftUI

struct MembershipPaymentView: View {
    @Bindable var appState: AppState
    @State private var errorMessage: String?
    @State private var isPaying = false

    private let profileService = ProfileService()

    private var feeCents: Int {
        appState.session?.society.annualMembershipFeeCents ?? AppConfig.defaultAnnualMembershipFeeCents
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "creditcard.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)

                Text("Annual Membership Fee")
                    .font(.title2.bold())

                Text(MemberDuesCalculator.formatCurrency(feeCents))
                    .font(.largeTitle.bold())

                Text("Complete your membership payment to access the member portal. Payment is simulated in development, matching the web portal placeholder provider.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                        .padding(.horizontal)
                }

                Button {
                    Task { await pay() }
                } label: {
                    if isPaying {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Pay Membership Fee")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Membership Payment")
        }
    }

    private func pay() async {
        guard let session = appState.session, let peopleID = session.peopleID else { return }
        isPaying = true
        errorMessage = nil
        defer { isPaying = false }

        do {
            try await profileService.completeMembershipPayment(
                peopleID: peopleID,
                userID: session.userID,
                societyID: session.society.id,
                annualFeeCents: feeCents
            )
            await appState.refreshSession()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
