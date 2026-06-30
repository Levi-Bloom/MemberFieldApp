import SwiftUI

struct NewsDetailView: View {
    let newsletterID: UUID
    let session: SessionContext

    @State private var newsletter: SocietyNewsletter?
    @State private var isLoading = true

    private let portalService = PortalService()

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView().padding()
            } else if let newsletter {
                VStack(alignment: .leading, spacing: 16) {
                    Text(newsletter.subject)
                        .font(.title2.bold())
                    if let publishedAt = newsletter.publishedAt {
                        Text(MemberDuesCalculator.formatDate(publishedAt))
                            .font(.caption)
                    }
                    Text(MemberDuesCalculator.stripHTML(newsletter.body))
                        .font(.body)
                }
                .padding()
            } else {
                ContentUnavailableView("Article not found", systemImage: "newspaper")
            }
        }
        .navigationTitle("News")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        newsletter = try? await portalService.fetchNewsletter(id: newsletterID, societyID: session.society.id)
    }
}
