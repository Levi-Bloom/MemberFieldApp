import SwiftUI
import UIKit

struct AnimalFormView: View {
    @Bindable var appState: AppState
    let session: SessionContext
    var onComplete: () -> Void

    @State private var name = ""
    @State private var animalType = AnimalConstants.defaultType
    @State private var sex: AnimalSex = .female
    @State private var lifeStatus: LifeStatus = .alive
    @State private var dateOfBirth = Date()
    @State private var scrapieTag = ""
    @State private var farmTag = ""
    @State private var description = ""
    @State private var notes = ""
    @State private var forSale = false
    @State private var forHire = false
    @State private var errorMessage: String?
    @State private var isSubmitting = false
    @State private var showSuccessAlert = false
    @State private var submittedAnimalName = ""
    @State private var animalPhoto: UIImage?

    @Environment(\.dismiss) private var dismiss
    private let animalService = AnimalService()

    var body: some View {
        Form {
            AnimalPhotoPickerSection(selectedImage: $animalPhoto)

            Section("Animal") {
                TextField("Name", text: $name)
                Picker("Type", selection: $animalType) {
                    ForEach(AnimalConstants.typeOptions(including: nil), id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                .pickerStyle(.menu)
                Picker("Sex", selection: $sex) {
                    ForEach(AnimalSex.allCases, id: \.self) { value in
                        Text(value.rawValue.capitalized).tag(value)
                    }
                }
                Picker("Life status", selection: $lifeStatus) {
                    ForEach(LifeStatus.allCases, id: \.self) { value in
                        Text(value.rawValue.capitalized).tag(value)
                    }
                }
                DatePicker("Date of birth", selection: $dateOfBirth, displayedComponents: .date)
            }

            Section("Tags") {
                TextField("Scrapie tag", text: $scrapieTag)
                TextField("Farm tag", text: $farmTag)
            }

            Section("Availability") {
                Toggle("For Sale", isOn: $forSale)
                Toggle("For Hire", isOn: $forHire)
            }

            Section("Notes") {
                TextField("Description", text: $description, axis: .vertical)
                TextField("Notes", text: $notes, axis: .vertical)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage).foregroundStyle(.red).font(.footnote)
                }
            }

            Section {
                Text("New registrations are submitted as pending for admin approval.")
                    .font(.footnote)
            }

            Section {
                Button {
                    Task { await submit() }
                } label: {
                    if isSubmitting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Submit")
                    }
                }
                .buttonStyle(PrimaryBrandButtonStyle())
                .disabled(isSubmitting || !canSubmit)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("New Registration")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
        .alert("Registration Submitted", isPresented: $showSuccessAlert) {
            Button("OK") {
                onComplete()
                dismiss()
            }
        } message: {
            Text("\(submittedAnimalName) has been submitted and is pending admin approval.")
        }
        .onAppear {
            animalType = AnimalConstants.defaultType
        }
    }

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !animalType.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func submit() async {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]

        let input = AnimalFormInput(
            name: name,
            animalType: animalType,
            sex: sex,
            lifeStatus: lifeStatus,
            dateOfBirth: formatter.string(from: dateOfBirth),
            scrapieTag: scrapieTag.isEmpty ? nil : scrapieTag,
            farmTag: farmTag.isEmpty ? nil : farmTag,
            description: description.isEmpty ? nil : description,
            notes: notes.isEmpty ? nil : notes,
            forSale: forSale,
            forHire: forHire
        )

        do {
            let created = try await animalService.createAnimal(context: session, input: input)
            if let animalPhoto {
                try AnimalPhotoStore.save(animalPhoto, for: created.id)
            }
            submittedAnimalName = created.name
            showSuccessAlert = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
