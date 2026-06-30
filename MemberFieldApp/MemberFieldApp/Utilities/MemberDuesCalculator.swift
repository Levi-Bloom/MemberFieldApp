import Foundation

enum MemberDuesCalculator {
    static func buildOverview(person: Person, annualFeeCents: Int) -> MemberDuesOverview {
        let membershipType = person.membershipType ?? .active
        let duesStatus = resolveStatus(person: person)
        let feeCents = membershipType == .lifetime ? 0 : annualFeeCents

        return MemberDuesOverview(
            personStatusLabel: formatPersonStatus(person.status),
            membershipTypeLabel: formatMembershipType(membershipType),
            duesStatus: duesStatus,
            duesStatusLabel: duesStatusLabel(duesStatus),
            annualFeeCents: feeCents,
            annualFeeLabel: membershipType == .lifetime ? "No annual charge" : formatCurrency(feeCents),
            lastPaidAt: person.membershipFeePaidAt,
            nextDueAt: membershipType == .lifetime ? nil : computeNextDueAt(person: person),
            paymentMethod: formatPaymentMethod(person.membershipPaymentProvider)
        )
    }

    static func resolveStatus(person: Person) -> MemberDuesStatus {
        if person.membershipType == .lifetime { return .notApplicable }
        if person.status == .lapsed { return .lapsed }
        if person.status == .invited { return .pending }
        if !person.membershipFeePaid { return .outstanding }

        if let nextDue = computeNextDueAt(person: person),
           let date = parseDate(nextDue),
           date < Date() {
            return .outstanding
        }
        return .current
    }

    static func computeNextDueAt(person: Person) -> String? {
        let anchor = person.membershipFeePaidAt ?? person.joinedAt
        guard let anchor, let date = parseDate(anchor) else { return nil }
        guard let nextDue = Calendar.current.date(byAdding: .year, value: 1, to: date) else { return nil }
        return DateFormatter.storage.string(from: nextDue)
    }

    static func formatPersonStatus(_ status: PersonStatus) -> String {
        switch status {
        case .invited: "Invited"
        case .active: "Current"
        case .inactive: "Inactive"
        case .lapsed: "Lapsed"
        case .banned: "Banned"
        }
    }

    static func formatMembershipType(_ type: MembershipType) -> String {
        switch type {
        case .active: "Active"
        case .junior: "Junior"
        case .lifetime: "Lifetime"
        case .associate: "Associate"
        }
    }

    static func duesStatusLabel(_ status: MemberDuesStatus) -> String {
        switch status {
        case .current: "Current"
        case .outstanding: "Outstanding"
        case .notApplicable: "Not applicable"
        case .lapsed: "Lapsed"
        case .pending: "Pending"
        }
    }

    static func formatCurrency(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: Double(cents) / 100)) ?? "$\(cents / 100)"
    }

    static func formatPaymentMethod(_ value: String?) -> String? {
        guard let value, !value.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        let normalized = value.lowercased()
        if normalized == "manual" || normalized == "manually" { return "Manual" }
        if normalized.contains("standing") { return "Standing order" }
        if normalized.contains("stripe") { return "Card" }
        return value
    }

    static func formatDate(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "—" }
        guard let date = parseDate(value) else { return "—" }
        return DateFormatter.display.string(from: date)
    }

    static func parseDate(_ value: String) -> Date? {
        if let date = ISO8601DateFormatter.parseFlexible(value) { return date }

        let dateOnly = DateFormatter()
        dateOnly.dateFormat = "yyyy-MM-dd"
        dateOnly.locale = Locale(identifier: "en_US_POSIX")
        if let date = dateOnly.date(from: String(value.prefix(10))) { return date }

        let postgres = DateFormatter()
        postgres.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        postgres.locale = Locale(identifier: "en_US_POSIX")
        postgres.timeZone = TimeZone(secondsFromGMT: 0)
        if let date = postgres.date(from: value) { return date }

        return nil
    }

    static func relativeTime(from isoDate: String) -> String {
        guard let date = ISO8601DateFormatter.flexible.date(from: isoDate) else { return "" }
        let diff = Int(Date().timeIntervalSince(date))
        let minutes = diff / 60
        let hours = minutes / 60
        let days = hours / 24
        let weeks = days / 7
        if minutes < 1 { return "now" }
        if minutes < 60 { return "\(minutes)m ago" }
        if hours < 24 { return "\(hours)h ago" }
        if days < 7 { return "\(days)d ago" }
        if weeks < 4 { return "\(weeks)w ago" }
        let months = days / 30
        if months < 12 { return "\(months)mo ago" }
        return "\(days / 365)y ago"
    }

    static func stripHTML(_ html: String) -> String {
        html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func truncate(_ text: String, maxLength: Int = 220) -> String {
        guard text.count > maxLength else { return text }
        return String(text.prefix(maxLength)).trimmingCharacters(in: .whitespacesAndNewlines) + "…"
    }

    static func personInitials(_ person: Person) -> String {
        let first = person.firstName.first.map(String.init) ?? ""
        let last = person.lastName.first.map(String.init) ?? ""
        let value = (first + last).uppercased()
        return value.isEmpty ? "?" : value
    }

    static func formatPhone(_ phone: String?) -> String? {
        guard let phone, !phone.isEmpty else { return nil }
        let digits = phone.filter(\.isNumber)
        guard digits.count == 10 else { return phone }
        let area = digits.prefix(3)
        let mid = digits.dropFirst(3).prefix(3)
        let last = digits.suffix(4)
        return "(\(area)) \(mid)-\(last)"
    }
}

extension ISO8601DateFormatter {
    static let flexible: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}

extension DateFormatter {
    static let display: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static let storage: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter
    }()
}

extension ISO8601DateFormatter {
    static func parseFlexible(_ value: String) -> Date? {
        if let date = flexible.date(from: value) { return date }
        let basic = ISO8601DateFormatter()
        basic.formatOptions = [.withInternetDateTime]
        if let date = basic.date(from: value) { return date }
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return withFraction.date(from: value)
    }
}
