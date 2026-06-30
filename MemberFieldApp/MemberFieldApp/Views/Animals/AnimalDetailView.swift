import MessageUI
import SwiftUI
import UIKit

struct AnimalDetailView: View {
    let session: SessionContext
    @State var animal: Animal

    @State private var showPhotoEdit = false
    @State private var showTransferRequest = false
    @State private var showDeathConfirmation = false
    @State private var showCastrationConfirmation = false
    @State private var isSubmittingAction = false
    @State private var actionErrorMessage: String?
    @State private var isGeneratingCertificate = false
    @State private var showMailComposer = false
    @State private var certificatePDFData: Data?
    @State private var certificateFilename = "pedigree-certificate.pdf"

    private let animalService = AnimalService()
    private let certificateService = AnimalCertificateService()

    private var canReportCastration: Bool {
        animal.sex == .male && animal.lifeStatus != .dead
    }

    private var canReportDeath: Bool {
        animal.lifeStatus != .dead
    }

    var body: some View {
        List {
            if let photo = AnimalPhotoStore.load(for: animal.id) {
                Section {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }

            Section("Details") {
                LabeledContent("Tag", value: animal.tagNumber)
                LabeledContent("Name", value: animal.name)
                LabeledContent("Type", value: animal.animalType ?? "—")
                LabeledContent("Sex", value: animal.sex.rawValue.capitalized)
                LabeledContent("Registration", value: animal.registrationStatus.rawValue.capitalized)
                LabeledContent("Life Status", value: animal.lifeStatus.rawValue.capitalized)
                if let dob = animal.dateOfBirth {
                    LabeledContent("Date of Birth", value: MemberDuesCalculator.formatDate(dob))
                }
                if let scrapie = animal.scrapieTag, !scrapie.isEmpty {
                    LabeledContent("Scrapie Tag", value: scrapie)
                }
            }

            Section("Pedigree Snapshot") {
                AnimalPedigreeSectionView(session: session, animal: animal)
                    .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
            }

            if let farm = animal.farmTag, !farm.isEmpty {
                Section {
                    LabeledContent("Farm Tag", value: farm)
                }
            }

            if animal.forSale == true || animal.forHire == true {
                Section("Availability") {
                    if animal.forSale == true { Label("For Sale", systemImage: "tag.fill") }
                    if animal.forHire == true { Label("For Hire", systemImage: "hand.raised.fill") }
                }
            }

            if let description = animal.description, !description.isEmpty {
                Section("Description") {
                    Text(description)
                }
            }

            if let notes = animal.notes, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                }
            }

            Section {
                VStack(spacing: 12) {
                    Button {
                        showPhotoEdit = true
                    } label: {
                        Text("Change Photo")
                    }
                    .buttonStyle(SecondaryBrandButtonStyle())

                    Button {
                        showTransferRequest = true
                    } label: {
                        Text("Request Transfer")
                    }
                    .buttonStyle(SecondaryBrandButtonStyle())

                    Button {
                        Task { await printCertificate() }
                    } label: {
                        if isGeneratingCertificate {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Print Certificate")
                        }
                    }
                    .buttonStyle(SecondaryBrandButtonStyle())
                    .disabled(isGeneratingCertificate || isSubmittingAction)

                    Button {
                        Task { await emailCertificate() }
                    } label: {
                        Text("Email Certificate")
                    }
                    .buttonStyle(SecondaryBrandButtonStyle())
                    .disabled(isGeneratingCertificate || isSubmittingAction)

                    if canReportCastration {
                        Button {
                            showCastrationConfirmation = true
                        } label: {
                            Text("Report Castration")
                        }
                        .buttonStyle(SecondaryBrandButtonStyle())
                        .disabled(isSubmittingAction)
                    }

                    if canReportDeath {
                        Button {
                            showDeathConfirmation = true
                        } label: {
                            Text("Report Death")
                        }
                        .buttonStyle(OutlineBrandButtonStyle())
                        .disabled(isSubmittingAction)
                    }
                }
                .padding(.vertical, 4)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
            } header: {
                Text("Updates")
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    if !canReportCastration {
                        Text("Report Castration is available for male animals only.")
                    }
                    if !canReportDeath {
                        Text("This animal is already marked deceased.")
                    }
                    Text("Contact your society administrator to change registration details, tags, or availability flags.")
                }
            }
        }
        .navigationTitle(animal.name)
        .sheet(isPresented: $showPhotoEdit) {
            NavigationStack {
                AnimalPhotoEditView(animalID: animal.id) {
                    Task { await reloadAnimal() }
                }
            }
        }
        .sheet(isPresented: $showTransferRequest) {
            NavigationStack {
                AnimalTransferRequestView(
                    session: session,
                    animal: animal
                ) {
                    Task { await reloadAnimal() }
                }
            }
        }
        .alert("Report death for \(animal.name)?", isPresented: $showDeathConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Report Death", role: .destructive) {
                Task { await reportDeath() }
            }
        } message: {
            Text("This will mark \(animal.tagNumber) as deceased in your registry.")
        }
        .alert("Report castration for \(animal.name)?", isPresented: $showCastrationConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Report Castration") {
                Task { await reportCastration() }
            }
        } message: {
            Text("This will update \(animal.tagNumber) to wether.")
        }
        .alert("Could Not Update", isPresented: .constant(actionErrorMessage != nil)) {
            Button("OK") { actionErrorMessage = nil }
        } message: {
            Text(actionErrorMessage ?? "")
        }
        .sheet(isPresented: $showMailComposer) {
            if let certificatePDFData {
                MailComposeView(
                    recipients: [session.email],
                    subject: "Registration certificate for \(animal.tagNumber)",
                    messageBody: "Attached is the registration certificate for \(animal.name) (\(animal.tagNumber)).",
                    attachmentData: certificatePDFData,
                    attachmentMimeType: "application/pdf",
                    attachmentFileName: certificateFilename
                ) {
                    showMailComposer = false
                    self.certificatePDFData = nil
                }
            }
        }
    }

    private func printCertificate() async {
        do {
            let pdfData = try await loadCertificatePDF()
            presentPrintDialog(with: pdfData)
        } catch {
            actionErrorMessage = error.localizedDescription
        }
    }

    private func emailCertificate() async {
        guard MFMailComposeViewController.canSendMail() else {
            actionErrorMessage = AnimalCertificateError.mailUnavailable.localizedDescription
            return
        }

        do {
            certificatePDFData = try await loadCertificatePDF()
            showMailComposer = true
        } catch {
            actionErrorMessage = error.localizedDescription
        }
    }

    private func loadCertificatePDF() async throws -> Data {
        isGeneratingCertificate = true
        defer { isGeneratingCertificate = false }

        let payload = try await certificateService.fetchPayload(
            animalID: animal.id,
            society: session.society
        )
        certificateFilename = certificateService.certificateFilename(for: payload.tagNumber)
        return certificateService.generatePDF(payload: payload)
    }

    @MainActor
    private func presentPrintDialog(with pdfData: Data) {
        let controller = UIPrintInteractionController.shared
        controller.printingItem = pdfData
        controller.present(animated: true)
    }

    private func reloadAnimal() async {
        if let refreshed = try? await animalService.fetchAnimal(id: animal.id, societyID: session.society.id) {
            animal = refreshed
        }
    }

    private func reportDeath() async {
        isSubmittingAction = true
        defer { isSubmittingAction = false }

        do {
            try await animalService.markLifeStatus(animals: [animal], context: session, lifeStatus: .dead)
            await reloadAnimal()
        } catch {
            actionErrorMessage = error.localizedDescription
        }
    }

    private func reportCastration() async {
        isSubmittingAction = true
        defer { isSubmittingAction = false }

        do {
            try await animalService.updateSexToWether(animals: [animal], context: session)
            await reloadAnimal()
        } catch {
            actionErrorMessage = error.localizedDescription
        }
    }
}
