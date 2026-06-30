import SwiftUI

struct PortalHomeView: View {
    @Bindable var appState: AppState
    let session: SessionContext
    var onQuickAction: (QuickActionDestination) -> Void
    var onOpenAccount: () -> Void

    private let quickActionColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    quickActions
                }
                .padding()
            }
            .brandPageBackground()
            .navigationTitle("Member Portal")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onOpenAccount) {
                        Image(systemName: "person.crop.circle")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .accessibilityLabel("My Account")
                }
            }
            .refreshable { await appState.refreshSession() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Welcome back")
                .font(.caption.weight(.semibold))
            Text(session.displayFirstName)
                .font(.title.bold())
            societyUpdateLine
        }
        .foregroundStyle(AppTheme.primaryText)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: AppTheme.cardShadow, radius: 10, y: 5)
    }

    private var societyUpdateLine: some View {
        Text(societyUpdateAttributedString)
            .font(.subheadline)
    }

    private var societyUpdateAttributedString: AttributedString {
        var text = AttributedString("Here is what is happening in ")
        var societyName = AttributedString(session.society.name)
        societyName.font = .subheadline.bold()
        societyName.foregroundColor = UIColor(AppTheme.linkBlue)

        if let websiteURL = societyWebsiteURL {
            societyName.link = websiteURL
        }

        text.append(societyName)
        var suffix = AttributedString(".")
        suffix.foregroundColor = UIColor(AppTheme.primaryText)
        text.foregroundColor = UIColor(AppTheme.primaryText)
        text.append(suffix)
        return text
    }

    private var societyWebsiteURL: URL? {
        guard let website = session.society.website?.trimmingCharacters(in: .whitespacesAndNewlines),
              !website.isEmpty else {
            return nil
        }

        if website.lowercased().hasPrefix("http://") || website.lowercased().hasPrefix("https://") {
            return URL(string: website)
        }

        return URL(string: "https://\(website)")
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            LazyVGrid(columns: quickActionColumns, spacing: 12) {
                ForEach(PortalQuickActions.all) { action in
                    Button {
                        onQuickAction(action.destination)
                    } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Image(systemName: action.systemImage)
                                    .font(.body.weight(.semibold))
                                    .frame(width: 34, height: 34)
                                    .background(AppTheme.brandMuted, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                Text(action.label)
                                    .font(.caption.weight(.medium))
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
                        .padding(12)
                        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: AppTheme.cardShadow, radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct MemberInfoCard: View {
    let person: Person
    let dues: MemberDuesOverview
    let avatarURL: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Member Info")
                .font(.headline)

            HStack(spacing: 12) {
                MemberAvatarView(url: avatarURL, initials: MemberDuesCalculator.personInitials(person))
                VStack(alignment: .leading) {
                    Text(person.fullName).font(.subheadline.bold())
                    Text(person.email).font(.caption)
                }
            }

            HStack {
                BadgeView(text: dues.membershipTypeLabel, style: .primary)
                if dues.personStatusLabel.caseInsensitiveCompare(dues.membershipTypeLabel) != .orderedSame {
                    BadgeView(text: dues.personStatusLabel, style: .secondary)
                }
            }

            infoRow("Member no.", person.membershipNumber ?? "—")
            infoRow("Dues status", dues.duesStatusLabel)
            infoRow("Annual charge", dues.annualFeeLabel)
            infoRow("Last paid", MemberDuesCalculator.formatDate(dues.lastPaidAt))
            infoRow("Next due", MemberDuesCalculator.formatDate(dues.nextDueAt))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: AppTheme.cardShadow, radius: 10, y: 5)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.caption)
            Spacer()
            Text(value).font(.caption.bold())
        }
    }
}

struct MemberAvatarView: View {
    let url: String?
    let initials: String

    var body: some View {
        ZStack {
            Circle().fill(AppTheme.brandMuted)
            if let url, let imageURL = URL(string: url) {
                AsyncImage(url: imageURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Text(initials).font(.caption.bold()).foregroundStyle(AppTheme.brand)
                }
            } else {
                Text(initials).font(.caption.bold()).foregroundStyle(AppTheme.brand)
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(Circle())
    }
}

struct BadgeView: View {
    enum Style { case primary, secondary }
    let text: String
    let style: Style

    var body: some View {
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppTheme.brandMuted, in: Capsule())
            .foregroundStyle(AppTheme.brand)
    }
}
