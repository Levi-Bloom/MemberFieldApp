import SwiftUI

struct SocietyNewsView: View {
    let session: SessionContext

    @State private var newsletters: [MemberNewsletterItem] = []
    @State private var isLoading = true

    private let portalService = PortalService()

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else if newsletters.isEmpty {
                    ContentUnavailableView(
                        "No news yet",
                        systemImage: "newspaper",
                        description: Text("Published newsletters from \(session.society.name) will appear here.")
                    )
                } else {
                    List(newsletters) { item in
                        NavigationLink {
                            NewsDetailView(newsletterID: item.id, session: session)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(item.title)
                                        .font(.subheadline.bold())
                                    Spacer()
                                    Text(item.relativeTime)
                                        .font(.caption)
                                }
                                Text(item.bodyPreview)
                                    .font(.caption)
                                    .lineLimit(3)
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color(.systemBackground))
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Society News")
            .refreshable { await load() }
            .task { await load() }
        }
        .brandPageBackground()
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            newsletters = try await portalService.fetchNewsletters(societyID: session.society.id)
        } catch {
            newsletters = []
        }
    }
}
