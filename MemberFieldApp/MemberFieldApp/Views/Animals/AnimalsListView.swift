import SwiftUI

struct AnimalsListView: View {
    enum Mode: String {
        case transfer, castrate, death, saleHireAI, checkMate
    }

    @Bindable var appState: AppState
    let session: SessionContext
    var initialMode: Mode?
    var openNewRegistration = false

    @State private var animals: [Animal] = []
    @State private var selectedIDs = Set<UUID>()
    @State private var mode: Mode?
    @State private var isLoading = true
    @State private var showNewAnimal = false
    @State private var errorMessage: String?
    @State private var forSale = false
    @State private var forHire = false
    @State private var transferRecipient: PersonSummaryRow?
    @State private var members: [PersonSummaryRow] = []
    @State private var searchText = ""

    private let animalService = AnimalService()

    private var filteredAnimals: [Animal] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return animals }
        return animals.filter { matchesSearch($0, query: query) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else if animals.isEmpty {
                    ContentUnavailableView(
                        "No animals yet",
                        systemImage: "pawprint",
                        description: Text("Register your first animal using the + button.")
                    )
                } else if filteredAnimals.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else if mode != nil {
                    List(filteredAnimals, selection: $selectedIDs) { animal in
                        AnimalRow(
                            animal: animal,
                            isSelected: selectedIDs.contains(animal.id),
                            showSelectionIndicator: true
                        )
                        .listRowBackground(Color(.systemBackground))
                    }
                    .environment(\.editMode, .constant(.active))
                    .scrollContentBackground(.hidden)
                } else {
                    List(filteredAnimals) { animal in
                        NavigationLink(value: animal.id) {
                            AnimalRow(animal: animal, isSelected: false, showSelectionIndicator: false)
                        }
                        .listRowBackground(Color(.systemBackground))
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(modeTitle)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search by reg no, name, or tag"
            )
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if mode != nil {
                        Button("Cancel") { mode = nil; selectedIDs.removeAll() }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNewAnimal = true } label: {
                        Image(systemName: "plus")
                    }
                }
                if mode != nil {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Text("\(selectedIDs.count) selected")
                        Spacer()
                        Button(applyButtonTitle) { Task { await applyMode() } }
                            .disabled(selectedIDs.isEmpty)
                    }
                }
            }
            .navigationDestination(for: UUID.self) { id in
                if let animal = animals.first(where: { $0.id == id }) {
                    AnimalDetailView(
                        session: session,
                        animal: animal
                    )
                }
            }
            .sheet(isPresented: $showNewAnimal) {
                NavigationStack {
                    AnimalFormView(appState: appState, session: session) {
                        showNewAnimal = false
                        Task { await load() }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if mode == .transfer || mode == .saleHireAI {
                    modeControls
                }
            }
            .refreshable { await load() }
            .task {
                mode = initialMode
                if openNewRegistration { showNewAnimal = true }
                await load()
                if mode == .transfer, let peopleID = session.peopleID {
                    members = (try? await animalService.fetchSocietyMembers(societyID: session.society.id, excluding: peopleID)) ?? []
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .brandPageBackground()
    }

    @ViewBuilder
    private var modeControls: some View {
        if mode == .transfer {
            Picker("Transfer to", selection: $transferRecipient) {
                Text("Select member").tag(Optional<PersonSummaryRow>.none)
                ForEach(members, id: \.id) { member in
                    Text("\(member.firstName) \(member.lastName)").tag(Optional(member))
                }
            }
            .pickerStyle(.menu)
            .padding()
            .background(.bar)
        } else if mode == .saleHireAI {
            VStack {
                Toggle("For Sale", isOn: $forSale)
                Toggle("For Hire", isOn: $forHire)
            }
            .padding()
            .background(.bar)
        }
    }

    private var modeTitle: String {
        switch mode {
        case .transfer: "Transfer Animals"
        case .castrate: "Castrates"
        case .death: "Deaths"
        case .saleHireAI: "Sale / Hire"
        case .checkMate: "Check Mate"
        case .none: "My Animals"
        }
    }

    private var applyButtonTitle: String {
        switch mode {
        case .transfer: "Request Transfer"
        case .castrate: "Mark Castrated"
        case .death: "Mark Deceased"
        case .saleHireAI: "Update Flags"
        case .checkMate: "Open Selected"
        case .none: "Apply"
        }
    }

    private func load() async {
        guard let peopleID = session.peopleID else { return }
        isLoading = true
        defer { isLoading = false }
        animals = (try? await animalService.fetchMyAnimals(societyID: session.society.id, ownerID: peopleID)) ?? []
    }

    private func matchesSearch(_ animal: Animal, query: String) -> Bool {
        let normalizedQuery = query.lowercased()
        let searchableValues = [
            animal.tagNumber,
            animal.name,
            animal.scrapieTag,
            animal.farmTag,
            animal.animalType,
            animal.description,
            animal.notes,
            animal.status,
            animal.sex.rawValue,
            animal.registrationStatus.rawValue,
            animal.lifeStatus.rawValue,
        ]

        return searchableValues.contains { value in
            guard let value else { return false }
            return value.lowercased().contains(normalizedQuery)
        }
    }

    private func applyMode() async {
        let selected = animals.filter { selectedIDs.contains($0.id) }
        guard !selected.isEmpty else { return }

        do {
            switch mode {
            case .castrate:
                try await animalService.updateSexToWether(animals: selected, context: session)
            case .death:
                try await animalService.markLifeStatus(animals: selected, context: session, lifeStatus: .dead)
            case .saleHireAI:
                try await animalService.updateSaleFlags(
                    animals: selected, context: session,
                    forSale: forSale, forHire: forHire
                )
            case .transfer:
                guard let recipient = transferRecipient else {
                    errorMessage = "Select a member to transfer to."
                    return
                }
                let date = ISO8601DateFormatter().string(from: Date())
                for animal in selected {
                    try await animalService.requestTransfer(
                        animal: animal,
                        context: session,
                        recipientID: recipient.id,
                        effectiveDate: date,
                        notes: nil
                    )
                }
            case .checkMate:
                break
            case .none:
                break
            }
            mode = nil
            selectedIDs.removeAll()
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct AnimalRow: View {
    let animal: Animal
    let isSelected: Bool
    var showSelectionIndicator: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            if let photo = AnimalPhotoStore.load(for: animal.id) {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(animal.tagNumber) · \(animal.name)")
                    .font(.subheadline.bold())
                HStack(spacing: 8) {
                    Text(animal.sex.rawValue.capitalized)
                    Text(animal.registrationStatus.rawValue.capitalized)
                    Text(animal.lifeStatus.rawValue.capitalized)
                }
                .font(.caption)
            }
            Spacer()
            if showSelectionIndicator && isSelected {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            }
        }
    }
}
