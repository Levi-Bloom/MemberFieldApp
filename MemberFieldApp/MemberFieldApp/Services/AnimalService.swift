import Foundation
import Supabase

@MainActor
final class AnimalService {
    private var client: SupabaseClient { SupabaseManager.shared.client }

    func fetchMyAnimals(societyID: UUID, ownerID: UUID) async throws -> [Animal] {
        try await client
            .from("animals")
            .select()
            .eq("society_id", value: societyID.uuidString)
            .eq("owner_id", value: ownerID.uuidString)
            .order("tag_number")
            .execute()
            .value
    }

    func fetchAnimal(id: UUID, societyID: UUID) async throws -> Animal {
        try await client
            .from("animals")
            .select()
            .eq("id", value: id.uuidString)
            .eq("society_id", value: societyID.uuidString)
            .single()
            .execute()
            .value
    }

    func createAnimal(
        context: SessionContext,
        input: CreateAnimalInput
    ) async throws -> Animal {
        guard let peopleID = context.peopleID else { throw AnimalServiceError.unauthorized }

        let tagNumber: String = try await client
            .rpc("allocate_registration_number", params: ["p_society_id": context.society.id.uuidString])
            .execute()
            .value

        let legacyStatus: String = switch input.lifeStatus {
        case .alive: "active"
        case .dead: "deceased"
        case .unknown: "inactive"
        }

        let row: [String: AnyJSON] = [
            "society_id": .string(context.society.id.uuidString),
            "tag_number": .string(tagNumber),
            "name": .string(input.name),
            "animal_type": .string(input.animalType),
            "registration_status": .string("pending"),
            "sex": .string(input.sex.rawValue),
            "date_of_birth": input.dateOfBirth.map { .string($0) } ?? .null,
            "life_status": .string(input.lifeStatus.rawValue),
            "status": .string(legacyStatus),
            "scrapie_tag": input.scrapieTag.map { .string($0) } ?? .null,
            "farm_tag": input.farmTag.map { .string($0) } ?? .null,
            "description": input.description.map { .string($0) } ?? .null,
            "owner_id": .string(peopleID.uuidString),
            "breeder_id": .string(peopleID.uuidString),
            "created_by": .string(context.userID.uuidString),
            "notes": input.notes.map { .string($0) } ?? .null,
            "for_sale": .bool(input.forSale),
            "for_hire": .bool(input.forHire),
            "for_ai": .bool(false),
            "visibility": .string("visible"),
        ]

        return try await client
            .from("animals")
            .insert(row)
            .select()
            .single()
            .execute()
            .value
    }

    func updateAnimal(
        animal: Animal,
        context: SessionContext,
        updates: [String: AnyJSON]
    ) async throws {
        guard animal.ownerID == context.peopleID else { throw AnimalServiceError.unauthorized }

        try await client
            .from("animals")
            .update(updates)
            .eq("id", value: animal.id.uuidString)
            .eq("society_id", value: context.society.id.uuidString)
            .execute()
    }

    func markLifeStatus(
        animals: [Animal],
        context: SessionContext,
        lifeStatus: LifeStatus
    ) async throws {
        let status = switch lifeStatus {
        case .alive: "active"
        case .dead: "deceased"
        case .unknown: "inactive"
        }

        for animal in animals {
            guard animal.ownerID == context.peopleID else { continue }
            try await updateAnimal(
                animal: animal,
                context: context,
                updates: [
                    "life_status": .string(lifeStatus.rawValue),
                    "status": .string(status),
                ]
            )
        }
    }

    func updateSexToWether(
        animals: [Animal],
        context: SessionContext
    ) async throws {
        for animal in animals where animal.sex == .male {
            guard animal.ownerID == context.peopleID else { continue }
            try await updateAnimal(
                animal: animal,
                context: context,
                updates: ["sex": .string(AnimalSex.wether.rawValue)]
            )
        }
    }

    func updateSaleFlags(
        animals: [Animal],
        context: SessionContext,
        forSale: Bool,
        forHire: Bool
    ) async throws {
        for animal in animals {
            guard animal.ownerID == context.peopleID else { continue }
            try await updateAnimal(
                animal: animal,
                context: context,
                updates: [
                    "for_sale": .bool(forSale),
                    "for_hire": .bool(forHire),
                ]
            )
        }
    }

    func requestTransfer(
        animal: Animal,
        context: SessionContext,
        recipientID: UUID,
        effectiveDate: String,
        notes: String?
    ) async throws {
        guard animal.ownerID == context.peopleID else { throw AnimalServiceError.unauthorized }

        let display = [context.personFirstName, context.personLastName]
            .compactMap { $0 }
            .joined(separator: " ")

        try await client
            .from("animal_registry_requests")
            .insert([
                "animal_id": AnyJSON.string(animal.id.uuidString),
                "society_id": AnyJSON.string(context.society.id.uuidString),
                "request_type": .string("transfer"),
                "status": .string("pending"),
                "summary": .string("Transfer to member"),
                "details": .object([
                    "recipient_id": .string(recipientID.uuidString),
                    "effective_date": .string(effectiveDate),
                    "notes": notes.map { .string($0) } ?? .null,
                ]),
                "requested_by": .string(context.userID.uuidString),
                "requester_display": .string(display.isEmpty ? "Member" : display),
            ])
            .execute()
    }

    func fetchSocietyMembers(societyID: UUID, excluding peopleID: UUID) async throws -> [PersonSummaryRow] {
        try await client
            .from("people")
            .select("id, first_name, last_name, avatar_url, membership_type, is_registry_member, profile_completed, membership_fee_paid")
            .eq("society_id", value: societyID.uuidString)
            .neq("id", value: peopleID.uuidString)
            .eq("status", value: "active")
            .order("last_name")
            .execute()
            .value
    }
}

enum AnimalServiceError: LocalizedError {
    case unauthorized
    case validation(String)

    var errorDescription: String? {
        switch self {
        case .unauthorized: "You can only manage your own animals."
        case .validation(let message): message
        }
    }
}
