import Foundation
import Supabase

@MainActor
final class ProfileService {
    private var client: SupabaseClient { SupabaseManager.shared.client }

    func updateProfile(
        peopleID: UUID,
        userID: UUID,
        input: MemberProfileInput,
        markCompleted: Bool
    ) async throws {
        if markCompleted, (input.prefix ?? "").trimmingCharacters(in: .whitespaces).isEmpty {
            throw ProfileError.prefixRequired
        }

        var row: [String: AnyJSON] = [
            "first_name": .string(input.firstName),
            "last_name": .string(input.lastName),
            "phone": .string(input.phone),
            "address": .string(input.address),
            "postcode": input.postcode.map { .string($0) } ?? .null,
            "country": .string(input.country),
            "city": input.city.map { .string($0) } ?? .null,
            "state": input.state.map { .string($0) } ?? .null,
            "region": input.region.map { .string($0) } ?? .null,
            "sub_region": input.subRegion.map { .string($0) } ?? .null,
            "website": input.website.map { .string($0) } ?? .null,
            "prefix": input.prefix.map { .string($0) } ?? .null,
            "farm_name": input.farmName.map { .string($0) } ?? .null,
            "ministry_tag": input.ministryTag.map { .string($0) } ?? .null,
        ]

        if markCompleted {
            row["profile_completed"] = .bool(true)
        }

        try await client
            .from("people")
            .update(row)
            .eq("id", value: peopleID.uuidString)
            .eq("user_id", value: userID.uuidString)
            .execute()

        let fullName = "\(input.firstName) \(input.lastName)".trimmingCharacters(in: .whitespaces)
        try await client
            .from("profiles")
            .upsert(["id": AnyJSON.string(userID.uuidString), "full_name": .string(fullName)])
            .execute()
    }

    func completeMembershipPayment(
        peopleID: UUID,
        userID: UUID,
        societyID: UUID,
        annualFeeCents: Int
    ) async throws {
        let people: [PersonSummaryRow] = try await client
            .from("people")
            .select("profile_completed, membership_fee_paid")
            .eq("id", value: peopleID.uuidString)
            .eq("user_id", value: userID.uuidString)
            .limit(1)
            .execute()
            .value

        guard let person = people.first else { throw ProfileError.notFound }
        guard person.profileCompleted else { throw ProfileError.profileIncomplete }
        guard !person.membershipFeePaid else { throw ProfileError.alreadyPaid }

        let paidAt = ISO8601DateFormatter().string(from: Date())
        let provider = "placeholder"
        let reference = "mobile-\(UUID().uuidString.prefix(8))"

        try await client
            .from("people")
            .update([
                "membership_fee_paid": AnyJSON.bool(true),
                "membership_fee_paid_at": .string(paidAt),
                "membership_payment_provider": .string(provider),
                "membership_payment_reference": .string(String(reference)),
            ])
            .eq("id", value: peopleID.uuidString)
            .eq("user_id", value: userID.uuidString)
            .execute()

        _ = try? await client
            .from("member_membership_payments")
            .insert([
                "society_id": AnyJSON.string(societyID.uuidString),
                "person_id": AnyJSON.string(peopleID.uuidString),
                "amount_cents": .integer(annualFeeCents),
                "description": .string("Annual membership fee"),
                "status": .string("paid"),
                "payment_provider": .string(provider),
                "payment_reference": .string(String(reference)),
                "paid_at": .string(paidAt),
            ])
            .execute()
    }
}

enum ProfileError: LocalizedError {
    case prefixRequired
    case notFound
    case profileIncomplete
    case alreadyPaid

    var errorDescription: String? {
        switch self {
        case .prefixRequired: "Prefix is required."
        case .notFound: "Member record not found."
        case .profileIncomplete: "Complete your member profile before paying the membership fee."
        case .alreadyPaid: "Membership fee has already been paid."
        }
    }
}
