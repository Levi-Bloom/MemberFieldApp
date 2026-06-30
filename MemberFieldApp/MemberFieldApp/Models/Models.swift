import Foundation

enum SocietyRole: String, Codable, Sendable {
    case admin
    case member

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        self = SocietyRole(rawValue: raw) ?? .member
    }
}

enum PersonStatus: String, Codable, Sendable {
    case invited, active, inactive, lapsed, banned

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        self = PersonStatus(rawValue: raw) ?? .active
    }
}

enum MembershipType: String, Codable, Sendable {
    case active
    case junior
    case lifetime
    case associate

    static func fromStorage(_ raw: String?) -> MembershipType? {
        guard let raw else { return nil }
        let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return nil }

        if normalized.hasPrefix("active") || normalized == "member" { return .active }
        if normalized.hasPrefix("junior") { return .junior }
        if normalized.hasPrefix("lifetime") { return .lifetime }
        if normalized.hasPrefix("associate") { return .associate }
        return nil
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .active
            return
        }
        let raw = try container.decode(String.self)
        self = Self.fromStorage(raw) ?? .active
    }
}

enum AnimalSex: String, Codable, CaseIterable, Sendable {
    case male, female, wether
}

enum LifeStatus: String, Codable, CaseIterable, Sendable {
    case alive, dead, unknown
}

enum RegistrationStatus: String, Codable, Sendable {
    case registered, pending, unregistered, rejected
}

enum MemberDuesStatus: String, Sendable {
    case current, outstanding, notApplicable = "not_applicable", lapsed, pending
}

struct MemberOnboardingState: Sendable {
    var needsProfile: Bool
    var needsPayment: Bool
}

struct SessionContext: Sendable {
    let userID: UUID
    let email: String
    let fullName: String?
    let avatarURL: String?
    let society: Society
    let role: SocietyRole
    let peopleID: UUID?
    let personFirstName: String?
    let personLastName: String?
    let memberOnboarding: MemberOnboardingState?

    var displayFirstName: String {
        personFirstName ?? fullName?.split(separator: " ").first.map(String.init) ?? "Member"
    }

    var isMember: Bool { role == .member }
}

struct Society: Codable, Identifiable, Sendable {
    let id: UUID
    let name: String
    let slug: String
    let breed: String
    let logoURL: String?
    let strapline: String?
    let contactEmail: String?
    let contactPhone: String?
    let address: String?
    let postcode: String?
    let website: String?
    let annualMembershipFeeCents: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, slug, breed, strapline, address, postcode, website
        case logoURL = "logo_url"
        case contactEmail = "contact_email"
        case contactPhone = "contact_phone"
        case annualMembershipFeeCents = "annual_membership_fee_cents"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decodeString(forKey: .name, default: "Society")
        slug = try container.decodeString(forKey: .slug, default: "society")
        breed = try container.decodeString(forKey: .breed, default: "Unknown")
        logoURL = try container.decodeIfPresent(String.self, forKey: .logoURL)
        strapline = try container.decodeIfPresent(String.self, forKey: .strapline)
        contactEmail = try container.decodeIfPresent(String.self, forKey: .contactEmail)
        contactPhone = try container.decodeIfPresent(String.self, forKey: .contactPhone)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        postcode = try container.decodeIfPresent(String.self, forKey: .postcode)
        website = try container.decodeIfPresent(String.self, forKey: .website)
        annualMembershipFeeCents = try container.decodeFlexibleInt(forKey: .annualMembershipFeeCents)
    }
}

struct Person: Codable, Identifiable, Sendable {
    let id: UUID
    let societyID: UUID
    let userID: UUID?
    var firstName: String
    var lastName: String
    var email: String
    var phone: String?
    var membershipNumber: String?
    var prefix: String?
    var farmName: String?
    var website: String?
    var address: String?
    var postcode: String?
    var country: String?
    var city: String?
    var state: String?
    var region: String?
    var subRegion: String?
    var ministryTag: String?
    var avatarURL: String?
    var status: PersonStatus
    var membershipType: MembershipType?
    var profileCompleted: Bool
    var membershipFeePaid: Bool
    var membershipFeePaidAt: String?
    var membershipPaymentProvider: String?
    var membershipPaymentReference: String?
    var joinedAt: String?
    var isRegistryMember: Bool?

    enum CodingKeys: String, CodingKey {
        case id, email, phone, prefix, address, postcode, country, city, state, region, website, status
        case societyID = "society_id"
        case userID = "user_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case membershipNumber = "membership_number"
        case farmName = "farm_name"
        case subRegion = "sub_region"
        case ministryTag = "ministry_tag"
        case avatarURL = "avatar_url"
        case membershipType = "membership_type"
        case profileCompleted = "profile_completed"
        case membershipFeePaid = "membership_fee_paid"
        case membershipFeePaidAt = "membership_fee_paid_at"
        case membershipPaymentProvider = "membership_payment_provider"
        case membershipPaymentReference = "membership_payment_reference"
        case joinedAt = "joined_at"
        case isRegistryMember = "is_registry_member"
    }

    var fullName: String { "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces) }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        societyID = try container.decode(UUID.self, forKey: .societyID)
        userID = try container.decodeIfPresent(UUID.self, forKey: .userID)
        firstName = try container.decodeString(forKey: .firstName, default: "Member")
        lastName = try container.decodeString(forKey: .lastName)
        email = try container.decodeString(forKey: .email, default: "")
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        membershipNumber = try container.decodeIfPresent(String.self, forKey: .membershipNumber)
        prefix = try container.decodeIfPresent(String.self, forKey: .prefix)
        farmName = try container.decodeIfPresent(String.self, forKey: .farmName)
        website = try container.decodeIfPresent(String.self, forKey: .website)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        postcode = try container.decodeIfPresent(String.self, forKey: .postcode)
        country = try container.decodeIfPresent(String.self, forKey: .country)
        city = try container.decodeIfPresent(String.self, forKey: .city)
        state = try container.decodeIfPresent(String.self, forKey: .state)
        region = try container.decodeIfPresent(String.self, forKey: .region)
        subRegion = try container.decodeIfPresent(String.self, forKey: .subRegion)
        ministryTag = try container.decodeIfPresent(String.self, forKey: .ministryTag)
        avatarURL = try container.decodeIfPresent(String.self, forKey: .avatarURL)
        status = try container.decode(PersonStatus.self, forKey: .status)
        if let rawMembershipType = try container.decodeIfPresent(String.self, forKey: .membershipType) {
            membershipType = MembershipType.fromStorage(rawMembershipType)
        } else {
            membershipType = nil
        }
        profileCompleted = try container.decodeBool(forKey: .profileCompleted)
        membershipFeePaid = try container.decodeBool(forKey: .membershipFeePaid)
        membershipFeePaidAt = try container.decodeIfPresent(String.self, forKey: .membershipFeePaidAt)
        membershipPaymentProvider = try container.decodeIfPresent(String.self, forKey: .membershipPaymentProvider)
        membershipPaymentReference = try container.decodeIfPresent(String.self, forKey: .membershipPaymentReference)
        joinedAt = try container.decodeIfPresent(String.self, forKey: .joinedAt)
        isRegistryMember = try container.decodeIfPresent(Bool.self, forKey: .isRegistryMember)
    }
}

struct SocietyNewsletter: Codable, Identifiable, Sendable {
    let id: UUID
    let societyID: UUID
    let title: String
    let subject: String
    let body: String
    let status: String
    let publishedAt: String?
    let authorDisplay: String

    enum CodingKeys: String, CodingKey {
        case id, title, subject, body, status
        case societyID = "society_id"
        case publishedAt = "published_at"
        case authorDisplay = "author_display"
    }
}

struct MemberNewsletterItem: Identifiable, Sendable {
    let id: UUID
    let title: String
    let bodyPreview: String
    let publishedAt: Date
    let relativeTime: String
}

struct MemberDuesOverview: Sendable {
    let personStatusLabel: String
    let membershipTypeLabel: String
    let duesStatus: MemberDuesStatus
    let duesStatusLabel: String
    let annualFeeCents: Int
    let annualFeeLabel: String
    let lastPaidAt: String?
    let nextDueAt: String?
    let paymentMethod: String?
}

struct Animal: Codable, Identifiable, Sendable {
    let id: UUID
    let societyID: UUID
    let tagNumber: String
    var name: String
    var animalType: String?
    var registrationStatus: RegistrationStatus
    var sex: AnimalSex
    var dateOfBirth: String?
    var lifeStatus: LifeStatus
    var status: String
    var scrapieTag: String?
    var farmTag: String?
    var description: String?
    var ownerID: UUID
    var breederID: UUID?
    var sireID: UUID?
    var damID: UUID?
    var forSale: Bool?
    var forHire: Bool?
    var forAi: Bool?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case id, name, sex, status, description, notes
        case societyID = "society_id"
        case tagNumber = "tag_number"
        case animalType = "animal_type"
        case registrationStatus = "registration_status"
        case dateOfBirth = "date_of_birth"
        case lifeStatus = "life_status"
        case scrapieTag = "scrapie_tag"
        case farmTag = "farm_tag"
        case ownerID = "owner_id"
        case breederID = "breeder_id"
        case sireID = "sire_id"
        case damID = "dam_id"
        case forSale = "for_sale"
        case forHire = "for_hire"
        case forAi = "for_ai"
    }
}

struct PortalQuickAction: Identifiable, Sendable {
    let id: String
    let label: String
    let systemImage: String
    let destination: QuickActionDestination
}

enum QuickActionDestination: Sendable {
    case myAnimals
    case newRegistration
    case transfer
    case castrate
    case death
    case saleHireAI
    case checkMate
}

struct AnimalFormInput: Sendable {
    var name: String
    var animalType: String
    var sex: AnimalSex
    var lifeStatus: LifeStatus = .alive
    var dateOfBirth: String?
    var scrapieTag: String?
    var farmTag: String?
    var description: String?
    var notes: String?
    var forSale: Bool = false
    var forHire: Bool = false
}

typealias CreateAnimalInput = AnimalFormInput

struct MemberProfileInput: Sendable {
    var firstName: String
    var lastName: String
    var phone: String
    var address: String
    var postcode: String?
    var country: String
    var city: String?
    var state: String?
    var region: String?
    var subRegion: String?
    var website: String?
    var prefix: String?
    var farmName: String?
    var ministryTag: String?
}

struct SocietyMembershipRow: Codable, Sendable {
    let societyID: UUID
    let role: SocietyRole

    enum CodingKeys: String, CodingKey {
        case role
        case societyID = "society_id"
    }
}

struct PersonSummaryRow: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let firstName: String
    let lastName: String
    let avatarURL: String?
    let membershipType: MembershipType?
    let isRegistryMember: Bool?
    let profileCompleted: Bool
    let membershipFeePaid: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case avatarURL = "avatar_url"
        case membershipType = "membership_type"
        case isRegistryMember = "is_registry_member"
        case profileCompleted = "profile_completed"
        case membershipFeePaid = "membership_fee_paid"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        firstName = try container.decodeString(forKey: .firstName, default: "Member")
        lastName = try container.decodeString(forKey: .lastName)
        avatarURL = try container.decodeIfPresent(String.self, forKey: .avatarURL)
        if let rawMembershipType = try container.decodeIfPresent(String.self, forKey: .membershipType) {
            membershipType = MembershipType.fromStorage(rawMembershipType)
        } else {
            membershipType = nil
        }
        isRegistryMember = try container.decodeIfPresent(Bool.self, forKey: .isRegistryMember)
        profileCompleted = try container.decodeBool(forKey: .profileCompleted)
        membershipFeePaid = try container.decodeBool(forKey: .membershipFeePaid)
    }
}

struct ProfileRow: Codable, Sendable {
    let fullName: String?

    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
    }
}

struct AllocateTagResponse: Codable, Sendable {
    let tagNumber: String?

    enum CodingKeys: String, CodingKey {
        case tagNumber = "tag_number"
    }
}
