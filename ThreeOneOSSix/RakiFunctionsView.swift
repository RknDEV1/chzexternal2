import UIKit
import SwiftUI

struct RakiFunctionsView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var store: PatchProjectStore
    @State private var isWorking = false
    @State private var actionAlert: PatchStoreAlert?
    @State private var diagnosticText = "Pronto para testar"
    @State private var diagnosticDetails = "Toque em uma ação para iniciar o diagnóstico."

    private var patch: PatchLibraryItem? { store.items.first }

    private var isActive: Bool {
        guard let patch else { return false }
        return DevicePatchService.latestReceipt(projectID: patch.id) != nil
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    header
                    statusCard
                    actionCard
                    diagnosticCard
                    footer
                }
                .padding(.horizontal, 22)
                .padding(.top, 24)
                .padding(.bottom, 28)
            }
        }
        .alert(item: $actionAlert) { alert in
            Alert(
                title: Text(language.text(alert.titleKey)),
                message: Text(alert.message(language: language)),
                dismissButton: .default(Text("OK"))
            )
        }
        .task { store.reload() }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text("Chz Inject")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.top, 6)
    }

    private var statusCard: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(isActive ? Color.green : Color.white.opacity(0.35))
                .frame(width: 10, height: 10)
                .shadow(color: isActive ? .green.opacity(0.8) : .clear, radius: 8)

            VStack(alignment: .leading, spacing: 3) {
                Text("HS Pescoço")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                Text(isActive ? "STATUS  •  ATIVADO" : "STATUS  •  DESATIVADO")
                    .font(.caption.weight(.semibold))
                    .tracking(0.8)
                    .foregroundStyle(isActive ? Color.green : .secondary)
            }

            Spacer()

            Image(systemName: isActive ? "checkmark.seal.fill" : "lock.shield")
                .font(.title3)
                .foregroundStyle(isActive ? Color.green : AppTheme.accent)
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        }
    }

    private var actionCard: some View {
        VStack(spacing: 13) {
            actionButton(
                title: "ATIVAR HS",
                symbol: "checkmark.shield.fill",
                enabled: patch != nil && !isActive && !isWorking,
                filled: true
            ) {
                guard let patch else { return }
                runPatch(patch, enable: true)
            }

            actionButton(
                title: "DESATIVAR HS",
                symbol: "arrow.counterclockwise.circle",
                enabled: patch != nil && isActive && !isWorking,
                filled: false
            ) {
                guard let patch else { return }
                runPatch(patch, enable: false)
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AppTheme.accent.opacity(0.24), lineWidth: 1)
        }
    }

    private var diagnosticCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("DIAGNÓSTICO", systemImage: "stethoscope")
                    .font(.caption.weight(.bold))
                    .tracking(0.8)
                    .foregroundStyle(AppTheme.accent)
                Spacer()
                Text(diagnosticText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(diagnosticText == "Falha" ? .red : .secondary)
            }
            Text(diagnosticDetails)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1) }
    }

    private func actionButton(
        title: String,
        symbol: String,
        enabled: Bool,
        filled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.headline.weight(.bold))
                .tracking(0.5)
                .foregroundStyle(filled && enabled ? Color.black : (enabled ? AppTheme.accent : .white.opacity(0.30)))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(filled && enabled ? AppTheme.accent : Color.clear)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(enabled ? AppTheme.accent : Color.white.opacity(0.12), lineWidth: 1.4)
                }
                .shadow(color: filled && enabled ? AppTheme.accent.opacity(0.35) : .clear, radius: 16, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.55)
    }

    private var footer: some View {
        HStack(spacing: 7) {
            Image(systemName: "shield.checkered")
            Text("CHZ INJECT  •  HS PESCOÇO")
        }
        .font(.caption2.weight(.semibold))
        .tracking(0.8)
        .foregroundStyle(.secondary)
        .textCase(.uppercase)
    }

    private func runPatch(_ item: PatchLibraryItem, enable: Bool) {
        guard !isWorking, let baseProject = item.project else {
            actionAlert = PatchStoreAlert(titleKey: "common.failed", messageKey: "patch.error.apply")
            return
        }

        isWorking = true
        diagnosticText = "Verificando"
        diagnosticDetails = diagnosticSummary(for: baseProject, action: enable ? "ativação" : "desativação")

        Task.detached(priority: .userInitiated) {
            do {
                if enable {
                    let sourceProject = item.summary.schemaVersion >= 2 && item.canInspectContents
                        ? try PatchProjectLibrary.synchronizeWorkspace(item: item)
                        : baseProject
                    let resolution = try DevicePatchService.resolveInstalledTarget(for: sourceProject)
                    let project = resolution.project
                    let remapState = resolution.wasRemapped ? "sim" : "não"
                    await MainActor.run {
                        diagnosticDetails = "App selecionado: \(resolution.appName)\nBundle ID usado: \(resolution.bundleID)\nID remapeado automaticamente: \(remapState)"
                    }
                    for bundleID in project.allBundleIdentifiers {
                        await MainActor.run {
                            diagnosticText = "Container"
                            diagnosticDetails = "Bundle ID: \(bundleID)\nProcurando container…"
                        }
                        guard let root = ContainerStore.resolveAppContainerPath(bundleID: bundleID) else {
                            throw PatchPackageError.targetAppUnavailable(bundleID)
                        }
                        for rule in project.rules where rule.bundleID == bundleID {
                            let target = URL(fileURLWithPath: root, isDirectory: true).appendingPathComponent(rule.relativePath)
                            let exists = FileManager.default.fileExists(atPath: target.path)
                            let fileState = exists ? "encontrado" : "não encontrado"
                            await MainActor.run {
                                diagnosticDetails = "Bundle ID: \(bundleID)\nAlvo: \(rule.relativePath)\nContainer encontrado\nArquivo: \(fileState)"
                            }
                            guard exists else {
                                throw PatchPackageError.targetAppUnavailable("arquivo não encontrado: \(rule.relativePath)")
                            }
                        }
                    }
                    await MainActor.run {
                        diagnosticText = "Aplicando"
                        diagnosticDetails = "Container e arquivo-alvo encontrados. Copiando patch…"
                    }
                    _ = try DevicePatchService.apply(project: project)
                    await MainActor.run {
                        store.reload()
                        isWorking = false
                        diagnosticText = "Sucesso"
                        diagnosticDetails = "Patch aplicado e backup criado."
                        actionAlert = PatchStoreAlert(titleKey: "common.done", messageKey: "patch.applied_message")
                    }
                } else {
                    guard let receipt = DevicePatchService.latestReceipt(projectID: item.id) else {
                        throw PatchPackageError.invalidProject
                    }
                    await MainActor.run {
                        diagnosticText = "Removendo"
                        diagnosticDetails = "Recibo encontrado. Restaurando arquivo original…"
                    }
                    try DevicePatchService.restore(receipt: receipt, allowChangedTargets: true)
                    await MainActor.run {
                        store.reload()
                        isWorking = false
                        diagnosticText = "Sucesso"
                        diagnosticDetails = "Arquivo original restaurado."
                        actionAlert = PatchStoreAlert(titleKey: "common.done", messageKey: "patch.restored_message")
                    }
                }
            } catch let error as PatchPackageError {
                await MainActor.run {
                    diagnosticText = "Falha"
                    diagnosticDetails = diagnosticErrorText(error, action: enable ? "ativação" : "desativação")
                    isWorking = false
                    actionAlert = PatchStoreAlert(
                        titleKey: "common.failed",
                        messageKey: error.localizationKey,
                        messageArgument: error.localizationArgument
                    )
                }
            } catch {
                await MainActor.run {
                    diagnosticText = "Falha"
                    diagnosticDetails = "Erro inesperado na \(enable ? "ativação" : "desativação"): \(error.localizedDescription)"
                    isWorking = false
                    actionAlert = PatchStoreAlert(
                        titleKey: "common.failed",
                        messageKey: enable ? "patch.error.apply" : "patch.error.restore"
                    )
                }
            }
        }
    }
    private func diagnosticSummary(for project: PatchProject, action: String) -> String {
        let targets = project.rules.map { "\($0.bundleID):\($0.relativePath)" }.joined(separator: "\n")
        return "iOS: \(UIDevice.current.systemVersion)\nAção: \(action)\nAlvo:\n\(targets)"
    }

    private func diagnosticErrorText(_ error: PatchPackageError, action: String) -> String {
        if case .applyFailedDetail(let detail) = error {
            return "Erro técnico: applyFailed\nAção: \(action)\nDetalhe: \(detail)"
        }
        if case .applyFailed = error {
            return "Erro técnico: applyFailed\nAção: \(action)\nContainer e arquivo-alvo foram localizados, mas a cópia/backup falhou. Verifique permissão de escrita e se o jogo está fechado."
        }
        var text = "Erro técnico: \(String(describing: error))\nAção: \(action)"
        if let argument = error.localizationArgument { text += "\nDetalhe: \(argument)" }
        return text
    }

}
