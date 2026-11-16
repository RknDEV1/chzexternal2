import SwiftUI

struct ContentView: View {
    @AppStorage("raki.theme.mode") private var themeMode = RakiThemeMode.dark.rawValue
    @AppStorage("raki.accent.variant") private var accentVariant = RakiAccentVariant.pink.rawValue

    var body: some View {
        RakiFunctionsView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.pageBackground.ignoresSafeArea())
            .tint(AppTheme.accent)
            .preferredColorScheme(RakiThemeMode(rawValue: themeMode)?.colorScheme ?? .dark)
            .id(accentVariant + themeMode)
    }
}
