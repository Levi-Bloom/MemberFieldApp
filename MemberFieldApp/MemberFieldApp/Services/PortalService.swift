import Foundation
import Supabase

@MainActor
final class PortalService {
    private var client: SupabaseClient { SupabaseManager.shared.client }

    func fetchNewsletters(societyID: UUID) async throws -> [MemberNewsletterItem] {
        let newsletters: [SocietyNewsletter] = try await client
            .from("society_newsletters")
            .select()
            .eq("society_id", value: societyID.uuidString)
            .eq("status", value: "published")
            .order("published_at", ascending: false)
            .execute()
            .value

        return newsletters.compactMap { item in
            guard let publishedAt = item.publishedAt else { return nil }
            let preview = MemberDuesCalculator.truncate(
                MemberDuesCalculator.stripHTML(item.body)
            )
            return MemberNewsletterItem(
                id: item.id,
                title: item.subject,
                bodyPreview: preview,
                publishedAt: ISO8601DateFormatter.parseFlexible(publishedAt) ?? Date(),
                relativeTime: MemberDuesCalculator.relativeTime(from: publishedAt)
            )
        }
    }

    func fetchNewsletter(id: UUID, societyID: UUID) async throws -> SocietyNewsletter? {
        let newsletters: [SocietyNewsletter] = try await client
            .from("society_newsletters")
            .select()
            .eq("id", value: id.uuidString)
            .eq("society_id", value: societyID.uuidString)
            .eq("status", value: "published")
            .limit(1)
            .execute()
            .value
        return newsletters.first
    }

    func fetchPerson(peopleID: UUID, userID: UUID) async throws -> Person {
        try await client
            .from("people")
            .select(
                "id, society_id, user_id, first_name, last_name, email, phone, membership_number, prefix, farm_name, website, address, postcode, country, city, state, region, sub_region, ministry_tag, avatar_url, status, membership_type, profile_completed, membership_fee_paid, membership_fee_paid_at, membership_payment_provider, membership_payment_reference, joined_at, is_registry_member"
            )
            .eq("id", value: peopleID.uuidString)
            .eq("user_id", value: userID.uuidString)
            .single()
            .execute()
            .value
    }
}
