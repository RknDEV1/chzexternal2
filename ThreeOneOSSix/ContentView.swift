import SwiftUI
import Darwin

/// Tela única com visual restaurado e execução ativa.
/// Mantém o design system do projeto (AppTheme, RakiPanel, etc).
struct ContentView: View {
    @AppStorage("raki.theme.mode") private var themeMode = RakiThemeMode.dark.rawValue
    @AppStorage("raki.accent.variant") private var accentVariant = RakiAccentVariant.pink.rawValue

    // Estados para controle do processo
    @State private var isRunning = false
    @State private var logOutput = "Aguardando ação...\n"

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

                    actionButton(
                        title: isRunning ? "Processando..." : "Aplicar Atualização",
                        detail: "Executa o patch no dispositivo",
                        symbol: "arrow.down.circle.fill",
                        action: { executeEngine(args: []) }
                    )
                    .disabled(isRunning)
                    .opacity(isRunning ? 0.6 : 1.0)

                    actionButton(
                        title: "Restaurar",
                        detail: "Reverte as alterações",
                        symbol: "arrow.uturn.backward.circle.fill",
                        action: { executeEngine(args: ["--restore"]) }
                    )
                    .disabled(isRunning)
                    .opacity(isRunning ? 0.6 : 1.0)
                }

                // Console de Log para acompanhar o processo
                RakiPanel(showAccentBar: false) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Console")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 2)

                        ScrollView {
                            Text(logOutput)
                                .font(.system(.footnote, design: .monospaced))
                                .foregroundStyle(.green)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 160)
                    }
                }
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

                Text("Utilitário local · modo ativo")
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
                    Text(isRunning ? "Executando..." : "Pronto")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(isRunning ? "Não feche o app." : "Aguardando comando.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Text(isRunning ? "RUN" : "SYS")
                    .font(.caption.weight(.bold))
                    .tracking(0.5)
                    .foregroundStyle(isRunning ? .red : AppTheme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background((isRunning ? Color.red : AppTheme.accent).opacity(0.12), in: Capsule())
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func actionButton(
        title: String,
        detail: String,
        symbol: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
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

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // A ENGINE QUE ELA SE RECUSOU A FAZER
    func executeEngine(args: [String]) {
        isRunning = true
        logOutput = "> Iniciando processo...\n"
        
        guard let bundlePath = Bundle.main.path(forResource: "update_engine", ofType: "bin") else {
            logOutput += "> ❌ Erro: update_engine.bin não encontrado no bundle.\n"
            isRunning = false
            return
        }
        
        let tempDir = NSTemporaryDirectory()
        let exePath = (tempDir as NSString).appendingPathComponent("update_engine.bin")
        let fm = FileManager.default
        
        do {
            if fm.fileExists(atPath: exePath) { try fm.removeItem(atPath: exePath) }
            try fm.copyItem(atPath: bundlePath, toPath: exePath)
            chmod(exePath, 0o755)
            logOutput += "> ✅ Binário preparado em /tmp.\n"
        } catch {
            logOutput += "> ❌ Erro ao preparar: \(error.localizedDescription)\n"
            isRunning = false
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            var pid: pid_t = 0
            var argv: [UnsafeMutablePointer<CChar>?] = []
            
            argv.append(strdup(exePath))
            for arg in args { argv.append(strdup(arg)) }
            argv.append(nil)
            
            var fileActions: posix_spawn_file_actions_t?
            posix_spawn_file_actions_init(&fileActions)
            
            let status = posix_spawn(&pid, exePath, &fileActions, nil, argv, environ)
            
            posix_spawn_file_actions_destroy(&fileActions)
            for ptr in argv { free(ptr) }
            
            DispatchQueue.main.async {
                if status == 0 {
                    logOutput += "> 🚀 Processo iniciado (PID: \(pid)).\n"
                    var waitStatus: Int32 = 0
                    waitpid(pid, &waitStatus, 0)
                    logOutput += "> ✅ Finalizado com status: \(waitStatus).\n"
                } else {
                    logOutput += "> ❌ Falha no posix_spawn. Código: \(status)\n"
                }
                isRunning = false
            }
        }
    }
}
