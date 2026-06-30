import SwiftUI

struct LearningCenterView: View {
    let session: SessionContext

    private let categories = [
        ("Getting started", "Learn the basics of registering animals and managing your flock.", "graduationcap.fill"),
        ("Guides & documentation", "Step-by-step walkthroughs for common registry tasks.", "book.fill"),
        ("Video tutorials", "Watch how-to videos from your society and Origin Registry.", "play.rectangle.fill"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Guides, tutorials, and resources to help you get the most from your \(session.society.name) membership.")
                    .font(.subheadline)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
                    ForEach(categories, id: \.0) { title, description, icon in
                        learningCenterCard(title: title, description: description, icon: icon)
                    }

                    NavigationLink {
                        RegistryRulesView(session: session)
                    } label: {
                        learningCenterCard(
                            title: "Rules of Registry",
                            description: "Official recording rules for \(session.society.name).",
                            icon: "doc.text.fill"
                        )
                    }
                    .buttonStyle(.plain)
                }

                Text("More learning resources are coming soon. Check back for guides and tutorials from \(session.society.name).")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.background, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
        .brandPageBackground()
        .navigationTitle("Learning Center")
    }

    private func learningCenterCard(title: String, description: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.green)
                .padding(10)
                .background(Color.green.opacity(0.12), in: Circle())
            Text(title).font(.subheadline.bold())
            Text(description)
                .font(.caption)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary))
    }
}
