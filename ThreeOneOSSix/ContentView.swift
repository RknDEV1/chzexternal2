import SwiftUI

/// Tela única demonstrativa. Usa o design system já existente no projeto
/// (AppTheme, RakiPanel, RakiThemeMode e RakiAccentVariant).
struct ContentView: View {
    @AppStorage("raki.theme.mode") private var themeMode = RakiThemeMode.dark.rawValue
    @AppStorage("raki.accent.variant") private var accentVariant = RakiAccentVariant.pink.rawValue

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                statusCard

                VStack(alignment: .leading, spacing: 12) {
                    Text("Ações")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 2)

                    demoButton(
                        title: "Aplicar Atualização",
                        detail: "Indisponível nesta demonstração",
                        symbol: "arrow.down.circle.fill"
                    )

                    demoButton(
                        title: "Restaurar",
                        detail: "Indisponível nesta demonstração",
                        symbol: "arrow.uturn.backward.circle.fill"
                    )
                }

                Text("Demonstração visual — nenhuma ação será executada.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 2)
            }
            .padding(.horizontal, AppTheme.pageInset)
            .padding(.top, 24)
            .padding(.bottom, 32)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(AppTheme.pageBackground.ignoresSafeArea())
        .tint(AppTheme.accent)
        .preferredColorScheme(
            RakiThemeMode(rawValue: themeMode)?.colorScheme ?? .dark
        )
        .id(accentVariant + themeMode)
    }

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .fill(AppTheme.accent.opacity(0.16))
                    .frame(width: 54, height: 54)

                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Atualização")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.primary)

                Text("Utilitário local · demonstração")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.bottom, 2)
    }

    private var statusCard: some View {
        RakiPanel(showAccentBar: true) {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: "iphone")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 38, height: 38)
                    .background(AppTheme.accent.opacity(0.12), in: Circle())
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Modo demonstração")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("Os controles estão desativados.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Text("UI")
                    .font(.caption.weight(.bold))
                    .tracking(0.5)
                    .foregroundStyle(AppTheme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.accent.opacity(0.12), in: Capsule())
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func demoButton(
        title: String,
        detail: String,
        symbol: String
    ) -> some View {
        Button(action: {}) {
            RakiPanel(showAccentBar: true) {
                HStack(spacing: 13) {
                    Image(systemName: symbol)
                        .font(.system(size: 23, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 40, height: 40)
                        .background(AppTheme.accent.opacity(0.12), in: Circle())
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text(detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 6)

                    Image(systemName: "lock.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(true) // define EnvironmentValues.isEnabled como false
        .opacity(0.62)
        .accessibilityHint("Indisponível nesta demonstração.")
    }
}
