import SwiftUI
import UIKit

struct AnimalPhotoEditView: View {
    let animalID: UUID
    var onComplete: () -> Void

    @State private var animalPhoto: UIImage?
    @State private var shouldDeletePhoto = false
    @State private var errorMessage: String?
    @State private var isSaving = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            AnimalPhotoPickerSection(
                selectedImage: $animalPhoto,
                existingAnimalID: animalID,
                onPhotoRemoved: { shouldDeletePhoto = true },
                onPhotoSelected: { shouldDeletePhoto = false }
            )

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }
        }
        .navigationTitle("Change Photo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { Task { await save() } }
                    .disabled(isSaving)
            }
        }
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            if let animalPhoto {
                try AnimalPhotoStore.save(animalPhoto, for: animalID)
            } else if shouldDeletePhoto {
                AnimalPhotoStore.delete(for: animalID)
            }
            onComplete()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct AnimalTransferRequestView: View {
    let session: SessionContext
    let animal: Animal
    var onComplete: () -> Void

    @State private var recipient: PersonSummaryRow?
    @State private var members: [PersonSummaryRow] = []
    @State private var errorMessage: String?
    @State private var isSubmitting = false

    @Environment(\.dismiss) private var dismiss
    private let animalService = AnimalService()

    var body: some View {
        Form {
            Section {
                Text("Submit a transfer request for \(animal.name) (\(animal.tagNumber)). An administrator will review it.")
                    .font(.footnote)
            }

            Section("Transfer to") {
                Picker("Member", selection: $recipient) {
                    Text("Select member").tag(Optional<PersonSummaryRow>.none)
                    ForEach(members, id: \.id) { member in
                        Text("\(member.firstName) \(member.lastName)").tag(Optional(member))
                    }
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }
        }
        .navigationTitle("Request Transfer")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Submit") { Task { await submit() } }
                    .disabled(isSubmitting || recipient == nil)
            }
        }
        .task {
            guard let peopleID = session.peopleID else { return }
            members = (try? await animalService.fetchSocietyMembers(
                societyID: session.society.id,
                excluding: peopleID
            )) ?? []
        }
    }

    private func submit() async {
        guard let recipient else { return }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            let date = ISO8601DateFormatter().string(from: Date())
            try await animalService.requestTransfer(
                animal: animal,
                context: session,
                recipientID: recipient.id,
                effectiveDate: date,
                notes: nil
            )
            onComplete()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
