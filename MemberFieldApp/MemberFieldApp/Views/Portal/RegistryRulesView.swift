import SwiftUI

struct RegistryRulesView: View {
    let session: SessionContext

    private var rulesText: String {
        RegistryRulesTextProvider.personalizedRulesText(societyName: session.society.name)
    }

    var body: some View {
        ScrollView {
            Text(rulesText)
                .font(.body)
                .foregroundStyle(AppTheme.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .brandPageBackground()
        .navigationTitle("Rules of Registry")
        .navigationBarTitleDisplayMode(.inline)
    }
}
