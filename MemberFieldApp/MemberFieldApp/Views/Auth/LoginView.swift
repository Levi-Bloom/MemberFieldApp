import SwiftUI

struct LoginView: View {
    @Bindable var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome back")
                            .font(.title2.bold())
                        Text("Sign in to manage your breed society registry.")
                            .font(.subheadline)
                    }

                    if !AppConfig.isConfigured {
                        Text("Add your Supabase URL and anon key in AppConfig.swift (from stockman-bellweather-labs `.env.local`).")
                            .font(.footnote)
                    }

                    VStack(spacing: 16) {
                        AuthField(title: "Email", text: $email, contentType: .username, keyboard: .emailAddress)
                        AuthField(title: "Password", text: $password, contentType: .password, isSecure: true)
                    }

                    if let error = appState.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    Button {
                        Task { await appState.signIn(email: email, password: password) }
                    } label: {
                        if appState.isBusy {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Sign In")
                        }
                    }
                    .buttonStyle(PrimaryBrandButtonStyle())
                    .disabled(email.isEmpty || password.isEmpty || appState.isBusy)
                }
                .brandCard()
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        appState.errorMessage = nil
                        dismiss()
                    }
                }
            }
        }
    }
}
