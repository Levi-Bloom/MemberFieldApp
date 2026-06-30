import SwiftUI

struct OriginLogoView: View {
    var maxWidth: CGFloat = 180

    var body: some View {
        Image("OriginLogo")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: maxWidth)
            .accessibilityLabel("Origin")
    }
}
