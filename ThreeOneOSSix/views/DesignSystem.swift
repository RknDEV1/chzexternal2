import SwiftUI

enum RakiThemeMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "Auto"
        case .light: return "Claro"
        case .dark: return "Escuro"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum RakiAccentVariant: String, CaseIterable, Identifiable {
    case red
    case pink
    case purple
    case cyan
    case green
    case amber

    var id: String { rawValue }

    var title: String {
        switch self {
        case .red: return "Vermelho"
        case .pink: return "Rosa"
        case .purple: return "Roxo"
        case .cyan: return "Ciano"
        case .green: return "Verde"
        case .amber: return "Âmbar"
        }
    }

    var color: Color {
        switch self {
        case .red: return Color(red: 0.92, green: 0.22, blue: 0.28)
        case .pink: return Color(red: 1.0, green: 0.16, blue: 0.58)
        case .purple: return Color(red: 0.55, green: 0.32, blue: 0.95)
        case .cyan: return Color(red: 0.15, green: 0.72, blue: 0.88)
        case .green: return Color(red: 0.18, green: 0.75, blue: 0.42)
        case .amber: return Color(red: 0.95, green: 0.62, blue: 0.18)
        }
    }
}

enum AppTheme {
    static var accent: Color {
        RakiAccentVariant(rawValue: UserDefaults.standard.string(forKey: "raki.accent.variant") ?? "pink")?.color
            ?? RakiAccentVariant.pink.color
    }

    static var pageBackground: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.012, green: 0.006, blue: 0.014, alpha: 1)
                : UIColor(red: 0.94, green: 0.95, blue: 0.98, alpha: 1)
        })
    }

    static let consoleBackground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.055, green: 0.012, blue: 0.045, alpha: 1)
            : UIColor.secondarySystemBackground
    })
    static let pageInset: CGFloat = 16
    static let rowIconSize: CGFloat = 17
    static let rowIconFrame: CGFloat = 28
    static let fileRowIconSize: CGFloat = 17
    static let fileRowIconFrame: CGFloat = 30
    static let fileRowHeight: CGFloat = 60
    static let appIconSize: CGFloat = 32
    static let emptyIconSize: CGFloat = 30
    static let selectionIconSize: CGFloat = 18
    static let contentCardCornerRadius: CGFloat = 18
    static let contentCardInset: CGFloat = 16
    static let contentCardPadding: CGFloat = 16
    static let panelCornerRadius: CGFloat = 18
    static let glassHighlight = LinearGradient(
        colors: [
            Color.white.opacity(0.22),
            Color(red: 1.0, green: 0.16, blue: 0.58).opacity(0.08),
            Color.clear
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

/// Raki's own liquid-glass surface: translucent material, soft highlight and
/// a restrained accent edge instead of copying another app's card treatment.
struct RakiPanel<Content: View>: View {
    var cornerRadius: CGFloat = AppTheme.panelCornerRadius
    var showAccentBar: Bool = false
    @ViewBuilder var content: () -> Content

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 0) {
            if showAccentBar {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(AppTheme.accent)
                    .frame(width: 3)
                    .padding(.vertical, 10)
                    .padding(.leading, 10)
            }

            content()
                .padding(showAccentBar ? EdgeInsets(top: 14, leading: 12, bottom: 14, trailing: 16) : EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(colorScheme == .dark ? AppTheme.consoleBackground.opacity(0.88) : Color.white.opacity(0.72))
        }
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(AppTheme.glassHighlight)
                .allowsHitTesting(false)
        }
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    colorScheme == .dark
                        ? Color.white.opacity(0.13)
                        : Color.black.opacity(0.08),
                    lineWidth: 0.85
                )
        }
        .shadow(
            color: colorScheme == .dark ? Color.black.opacity(0.28) : Color.black.opacity(0.10),
            radius: 10,
            y: 5
        )
    }
}

// Keep name for any remaining call sites during migration
typealias LiquidGlassCard = RakiPanelPlaceholder

struct RakiPanelPlaceholder<Content: View>: View {
    var cornerRadius: CGFloat = AppTheme.panelCornerRadius
    @ViewBuilder var content: () -> Content

    var body: some View {
        RakiPanel(cornerRadius: cornerRadius, showAccentBar: false, content: content)
    }
}

struct AppCardBorder: View {
    var body: some View {
        RoundedRectangle(
            cornerRadius: AppTheme.contentCardCornerRadius,
            style: .continuous
        )
        .strokeBorder(
            Color(uiColor: .separator).opacity(0.22),
            lineWidth: 0.5
        )
        .accessibilityHidden(true)
    }
}

struct AppRowIcon: View {
    let systemName: String
    var tint: Color = AppTheme.accent
    var symbolSize: CGFloat = AppTheme.rowIconSize
    var frameSize: CGFloat = AppTheme.rowIconFrame

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(tint.opacity(0.12))
            Image(systemName: systemName)
                .font(.system(size: symbolSize, weight: .medium))
                .foregroundStyle(tint)
        }
        .frame(width: frameSize, height: frameSize)
        .accessibilityHidden(true)
    }
}

struct AppSearchField: View {
    @Binding var text: String
    let prompt: String
    let clearLabel: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            TextField(prompt, text: $text)
                .font(.body)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(clearLabel)
            }
        }
        .padding(.horizontal, 11)
        .frame(minHeight: 36)
        .background(
            Color(uiColor: .secondarySystemFill),
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
        .padding(.horizontal, AppTheme.pageInset)
        .padding(.vertical, 8)
        .background(.bar)
    }
}

struct AppLogo: View {
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let icon = UIImage(named: "AppIcon60x60")
                ?? Bundle.main.path(forResource: "AppIcon60x60@2x", ofType: "png").flatMap(UIImage.init(contentsOfFile:))
                ?? UIImage(named: "AppIcon") {
                Image(uiImage: icon)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "bolt.horizontal.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.accent)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .accessibilityHidden(true)
    }
}
