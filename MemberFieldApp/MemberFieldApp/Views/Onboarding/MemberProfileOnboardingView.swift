import SwiftUI

struct MemberProfileOnboardingView: View {
    @Bindable var appState: AppState
    @State private var form = MemberProfileInput(
        firstName: "",
        lastName: "",
        phone: "",
        address: "",
        country: "United States"
    )
    @State private var errorMessage: String?
    @State private var isSaving = false

    private let profileService = ProfileService()

    var body: some View {
        NavigationStack {
            Form {
                Section("Complete your profile") {
                    Text("Before accessing the member portal, complete your registry profile.")
                        .font(.footnote)
                }

                MemberProfileFormFields(form: $form, requirePrefix: true)

                if let errorMessage {
                    Section {
                        Text(errorMessage).foregroundStyle(.red).font(.footnote)
                    }
                }

                Section {
                    Button("Continue") { Task { await save() } }
                        .disabled(isSaving || !isValid)
                }
            }
            .navigationTitle("Member Profile")
            .task { prefill() }
        }
    }

    private var isValid: Bool {
        !form.firstName.isEmpty && !form.lastName.isEmpty && !form.phone.isEmpty
            && !form.address.isEmpty && !(form.prefix ?? "").trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func prefill() {
        guard let session = appState.session else { return }
        form.firstName = session.personFirstName ?? ""
        form.lastName = session.personLastName ?? ""
    }

    private func save() async {
        guard let session = appState.session, let peopleID = session.peopleID else { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            try await profileService.updateProfile(
                peopleID: peopleID,
                userID: session.userID,
                input: form,
                markCompleted: true
            )
            await appState.refreshSession()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
