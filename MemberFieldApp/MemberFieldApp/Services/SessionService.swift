import Foundation
import Supabase

enum SessionError: LocalizedError {
    case notAuthenticated
    case noMembership
    case societyNotFound

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: "You must sign in to continue."
        case .noMembership: "No society membership found for this account."
        case .societyNotFound: "Society not found."
        }
    }
}

@MainActor
final class SessionService {
    private var client: SupabaseClient { SupabaseManager.shared.client }

    func loadSessionContext() async throws -> SessionContext {
        let session = try await client.auth.session
        let user = session.user
        guard let email = user.email else { throw SessionError.notAuthenticated }

        let memberships: [SocietyMembershipRow] = try await client
            .from("society_members")
            .select("society_id, role")
            .eq("user_id", value: user.id.uuidString)
            .limit(1)
            .execute()
            .value

        guard let membership = memberships.first else { throw SessionError.noMembership }

        async let societyTask: Society = client
            .from("societies")
            .select("id, name, slug, breed, logo_url, strapline, contact_email, contact_phone, address, postcode, website, annual_membership_fee_cents")
            .eq("id", value: membership.societyID.uuidString)
            .single()
            .execute()
            .value

        async let personTask: [PersonSummaryRow] = client
            .from("people")
            .select("id, first_name, last_name, avatar_url, membership_type, is_registry_member, profile_completed, membership_fee_paid")
            .eq("society_id", value: membership.societyID.uuidString)
            .eq("user_id", value: user.id.uuidString)
            .limit(1)
            .execute()
            .value

        async let profileTask: [ProfileRow] = client
            .from("profiles")
            .select("full_name")
            .eq("id", value: user.id.uuidString)
            .limit(1)
            .execute()
            .value

        let society = try await societyTask
        let personRow = try await personTask.first
        let profile = try await profileTask.first

        let isRegistryMember = personRow?.isRegistryMember != false
        let peopleID = (personRow != nil && isRegistryMember) ? personRow?.id : nil

        var onboarding: MemberOnboardingState?
        if membership.role == .member, isRegistryMember, let personRow {
            onboarding = MemberOnboardingState(
                needsProfile: !personRow.profileCompleted,
                needsPayment: personRow.profileCompleted && !personRow.membershipFeePaid
            )
        }

        return SessionContext(
            userID: user.id,
            email: email,
            fullName: profile?.fullName,
            avatarURL: personRow?.avatarURL,
            society: society,
            role: membership.role,
            peopleID: peopleID,
            personFirstName: personRow?.firstName,
            personLastName: personRow?.lastName,
            memberOnboarding: onboarding
        )
    }
}
