import SwiftUI

enum AppTheme {
    static let brand = Color(red: 93 / 255, green: 143 / 255, blue: 234 / 255)
    static let linkBlue = Color(red: 26 / 255, green: 58 / 255, blue: 124 / 255)
    static let brandMuted = Color(red: 93 / 255, green: 143 / 255, blue: 234 / 255).opacity(0.12)
    static let brandSoft = Color(red: 238 / 255, green: 243 / 255, blue: 253 / 255)
    static let primaryText = Color.black
    static let cardShadow = Color.black.opacity(0.06)
    static let pageBackground = Color(.systemGroupedBackground)

    static var pageGradient: LinearGradient {
        LinearGradient(
            colors: [brandSoft, Color(.systemBackground)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [brand.opacity(0.92), brand.opacity(0.72)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct BrandPageBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                AppTheme.pageBackground
                    .ignoresSafeArea()
            }
    }
}

struct BrandCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: AppTheme.cardShadow, radius: 16, y: 8)
    }
}

struct PrimaryBrandButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(AppTheme.brand.opacity(configuration.isPressed ? 0.85 : 1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryBrandButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(AppTheme.brand)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(AppTheme.brandMuted, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct OutlineBrandButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(AppTheme.primaryText)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppTheme.brand, lineWidth: 2)
                    .opacity(configuration.isPressed ? 0.7 : 1)
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct DestructiveBrandButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(Color.red.opacity(configuration.isPressed ? 0.85 : 1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct AuthField: View {
    let title: String
    @Binding var text: String
    var contentType: UITextContentType?
    var keyboard: UIKeyboardType = .default
    var isSecure = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)

            Group {
                if isSecure {
                    SecureField(title, text: $text)
                } else {
                    TextField(title, text: $text)
                        .keyboardType(keyboard)
                        .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
                }
            }
            .textContentType(contentType)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

extension View {
    func brandPageBackground() -> some View {
        modifier(BrandPageBackground())
    }

    func brandCard() -> some View {
        modifier(BrandCard())
    }

    func memberPortalText() -> some View {
        foregroundStyle(AppTheme.primaryText)
    }
}
