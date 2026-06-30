import SwiftUI

struct AccountHubView: View {
    @Bindable var appState: AppState
    let session: SessionContext

    private var dues: MemberDuesOverview? {
        guard let person = appState.person else { return nil }
        let fee = session.society.annualMembershipFeeCents ?? AppConfig.defaultAnnualMembershipFeeCents
        return MemberDuesCalculator.buildOverview(person: person, annualFeeCents: fee)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let person = appState.person, let dues {
                    MemberInfoCard(person: person, dues: dues, avatarURL: session.avatarURL)
                }

                VStack(spacing: 0) {
                    accountLink(
                        title: "Member Profile",
                        subtitle: "Update contact details and registry information.",
                        destination: ProfileSettingsView(appState: appState, session: session)
                    )
                    Divider().padding(.leading, 16)
                    accountLink(
                        title: "Membership",
                        subtitle: "View membership number, type, and dues status.",
                        destination: MembershipDetailsView(appState: appState, session: session)
                    )
                    Divider().padding(.leading, 16)
                    accountLink(
                        title: "Notifications",
                        subtitle: "View notification preferences.",
                        destination: NotificationsSettingsView()
                    )
                    Divider().padding(.leading, 16)
                    accountLink(
                        title: "Change Password",
                        subtitle: "Update the password used to sign in.",
                        destination: ChangePasswordView(appState: appState)
                    )
                }
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: AppTheme.cardShadow, radius: 10, y: 5)

                VStack(spacing: 0) {
                    accountLink(
                        title: "Learning Center",
                        subtitle: "Guides and resources for society members.",
                        destination: LearningCenterView(session: session)
                    )
                    Divider().padding(.leading, 16)
                    accountLink(
                        title: "Contact Society",
                        subtitle: "Reach your society administrators.",
                        destination: ContactSocietyView(session: session)
                    )
                }
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: AppTheme.cardShadow, radius: 10, y: 5)

                Button("Sign Out", role: .destructive) {
                    Task { await appState.signOut() }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .padding()
        }
        .brandPageBackground()
        .navigationTitle("Account")
        .refreshable { await appState.refreshSession() }
    }

    private func accountLink<D: View>(title: String, subtitle: String, destination: D) -> some View {
        NavigationLink {
            destination
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.medium))
                Text(subtitle)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
    }
}

struct ProfileSettingsView: View {
    @Bindable var appState: AppState
    let session: SessionContext

    @State private var form = MemberProfileInput(
        firstName: "", lastName: "", phone: "", address: "", country: "United States"
    )
    @State private var message: String?
    @State private var errorMessage: String?
    @State private var isSaving = false

    private let profileService = ProfileService()

    var body: some View {
        Form {
            MemberProfileFormFields(form: $form, requirePrefix: false)

            if let message {
                Section { Text(message).foregroundStyle(.green).font(.footnote) }
            }
            if let errorMessage {
                Section { Text(errorMessage).foregroundStyle(.red).font(.footnote) }
            }

            Section {
                Button("Save Profile") { Task { await save() } }
                    .disabled(isSaving)
            }
        }
        .navigationTitle("Member Profile")
        .task { prefill() }
    }

    private func prefill() {
        guard let person = appState.person else { return }
        form = MemberProfileInput(
            firstName: person.firstName,
            lastName: person.lastName,
            phone: person.phone ?? "",
            address: person.address ?? "",
            postcode: person.postcode,
            country: person.country ?? "United States",
            city: person.city,
            state: person.state,
            region: person.region,
            subRegion: person.subRegion,
            website: person.website,
            prefix: person.prefix,
            farmName: person.farmName,
            ministryTag: person.ministryTag
        )
    }

    private func save() async {
        guard let peopleID = session.peopleID else { return }
        isSaving = true
        message = nil
        errorMessage = nil
        defer { isSaving = false }

        do {
            try await profileService.updateProfile(
                peopleID: peopleID,
                userID: session.userID,
                input: form,
                markCompleted: false
            )
            await appState.refreshSession()
            message = "Member profile saved."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct MembershipDetailsView: View {
    @Bindable var appState: AppState
    let session: SessionContext

    private var dues: MemberDuesOverview? {
        guard let person = appState.person else { return nil }
        let fee = session.society.annualMembershipFeeCents ?? AppConfig.defaultAnnualMembershipFeeCents
        return MemberDuesCalculator.buildOverview(person: person, annualFeeCents: fee)
    }

    var body: some View {
        Form {
            if let person = appState.person, let dues {
                Section("Membership") {
                    LabeledContent("Member number", value: person.membershipNumber ?? "—")
                    LabeledContent("Email", value: person.email)
                    LabeledContent("Membership type", value: dues.membershipTypeLabel)
                    LabeledContent("Status", value: dues.personStatusLabel)
                    LabeledContent("Dues status", value: dues.duesStatusLabel)
                    LabeledContent("Annual charge", value: dues.annualFeeLabel)
                    LabeledContent("Last paid", value: MemberDuesCalculator.formatDate(dues.lastPaidAt))
                    LabeledContent("Next due", value: MemberDuesCalculator.formatDate(dues.nextDueAt))
                    if let method = dues.paymentMethod {
                        LabeledContent("Payment method", value: method)
                    }
                }
            }
        }
        .navigationTitle("Membership")
    }
}

struct NotificationsSettingsView: View {
    var body: some View {
        Form {
            Section {
                Label("Email notifications enabled", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Notification preferences are informational in the member portal. Full preference controls are coming soon.")
                    .font(.footnote)
            }
        }
        .navigationTitle("Notifications")
    }
}

struct ChangePasswordView: View {
    @Bindable var appState: AppState
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var message: String?
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("New password") {
                SecureField("Password", text: $password)
                SecureField("Confirm password", text: $confirmPassword)
            }

            if let message {
                Section { Text(message).foregroundStyle(.green).font(.footnote) }
            }
            if let errorMessage {
                Section { Text(errorMessage).foregroundStyle(.red).font(.footnote) }
            }

            Section {
                Button("Update Password") { Task { await save() } }
                    .disabled(password.count < 8 || password != confirmPassword)
            }
        }
        .navigationTitle("Change Password")
    }

    private func save() async {
        message = nil
        errorMessage = nil
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        do {
            try await appState.changePassword(password)
            message = "Password updated."
            password = ""
            confirmPassword = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
