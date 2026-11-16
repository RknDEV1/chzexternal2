import Foundation

enum DevicePatchService {
    static func apply(project: PatchProject) throws -> PatchTransactionReceipt {
        let resolvedProject = try resolveTargets(project: project)
        let bundleIDs = orderedBundleIdentifiers(in: resolvedProject)
        return try withResolvedContainers(bundleIDs: bundleIDs) { roots in
            try PatchTransaction.apply(
                project: resolvedProject,
                backupRoot: try PatchProjectLibrary.backupRootURL(),
                containerResolver: { bundleID in
                    guard let root = roots[bundleID] else {
                        throw PatchPackageError.targetAppUnavailable(bundleID)
                    }
                    return root
                },
                backupCenter: .shared
            )
        }
    }

    /// Game updates can move a cache file while keeping its filename unchanged.
    /// Remap only when exactly one regular, non-symlink candidate exists.
    static func resolveTargets(project: PatchProject) throws -> PatchProject {
        var resolvedRules: [PatchRule] = []
        let fileManager = FileManager.default

        for rule in project.rules {
            guard let rootPath = ContainerStore.resolveAppContainerPath(bundleID: rule.bundleID) else {
                throw PatchPackageError.targetAppUnavailable(rule.bundleID)
            }
            let root = PatchPathValidator.canonicalFileURL(
                URL(fileURLWithPath: rootPath, isDirectory: true)
            )
            let requested = try PatchPathValidator.resolveContainedTargetURL(
                relativePath: rule.relativePath,
                containerRoot: root
            )
            if fileManager.fileExists(atPath: requested.path) {
                resolvedRules.append(rule)
                continue
            }

            if let manualRelative = matchingManualProjectTarget(
                rule: rule,
                projectID: project.id,
                root: root,
                fileManager: fileManager
            ) {
                resolvedRules.append(PatchRule(
                    id: rule.id,
                    bundleID: rule.bundleID,
                    relativePath: manualRelative,
                    replacementFilename: rule.replacementFilename,
                    replacementData: rule.replacementData
                ))
                log("patch: reused manual target \(rule.relativePath) -> \(manualRelative)")
                continue
            }

            let candidates = matchingFileCandidates(
                filename: rule.replacementFilename,
                root: root,
                fileManager: fileManager
            )
            guard candidates.count == 1, let candidate = candidates.first else {
                let detail = candidates.isEmpty
                    ? "nenhum candidato encontrado"
                    : "\(candidates.count) candidatos encontrados"
                throw PatchPackageError.targetAppUnavailable(
                    "arquivo não encontrado: \(rule.relativePath) (\(detail))"
                )
            }
            let relative = String(candidate.path.dropFirst(root.path.count + 1))
            resolvedRules.append(PatchRule(
                id: rule.id,
                bundleID: rule.bundleID,
                relativePath: relative,
                replacementFilename: rule.replacementFilename,
                replacementData: rule.replacementData
            ))
            log("patch: remapped missing target \(rule.relativePath) -> \(relative)")
        }

        var resolved = project
        resolved.rules = resolvedRules
        return resolved
    }

    private static func matchingManualProjectTarget(
        rule: PatchRule,
        projectID: UUID,
        root: URL,
        fileManager: FileManager
    ) -> String? {
        for item in PatchProjectLibrary.load(fileManager: fileManager) {
            guard let otherProject = item.project, otherProject.id != projectID else { continue }
            for otherRule in otherProject.rules where
                otherRule.bundleID == rule.bundleID &&
                otherRule.replacementData == rule.replacementData
            {
                guard let candidate = try? PatchPathValidator.resolveContainedTargetURL(
                    relativePath: otherRule.relativePath,
                    containerRoot: root
                ),
                let values = try? candidate.resourceValues(
                    forKeys: [.isRegularFileKey, .isSymbolicLinkKey]
                ),
                values.isRegularFile == true,
                values.isSymbolicLink != true else { continue }
                return otherRule.relativePath
            }
        }
        return nil
    }

    private static func matchingFileCandidates(
        filename: String,
        root: URL,
        fileManager: FileManager
    ) -> [URL] {
        guard !filename.isEmpty,
              let enumerator = fileManager.enumerator(
                at: root,
                includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey],
                options: [.skipsHiddenFiles]
              ) else { return [] }

        var results: [URL] = []
        for case let candidate as URL in enumerator {
            guard candidate.lastPathComponent == filename,
                  candidate.path.hasPrefix(root.path + "/"),
                  let values = try? candidate.resourceValues(
                    forKeys: [.isRegularFileKey, .isSymbolicLinkKey]
                  ),
                  values.isRegularFile == true,
                  values.isSymbolicLink != true else { continue }
            results.append(PatchPathValidator.canonicalFileURL(candidate))
            if results.count > 1 { break }
        }
        return results
    }

    static func inspectRestore(receipt: PatchTransactionReceipt) throws -> PatchRestoreInspection {
        let bundleIDs = try PatchTransaction.requiredBundleIdentifiers(for: receipt)
        return try withResolvedContainers(bundleIDs: bundleIDs) { roots in
            try PatchTransaction.inspectRestore(
                receipt: receipt,
                containerResolver: { bundleID in
                    guard let root = roots[bundleID] else {
                        throw PatchPackageError.targetAppUnavailable(bundleID)
                    }
                    return root
                }
            )
        }
    }

    static func restore(
        receipt: PatchTransactionReceipt,
        allowChangedTargets: Bool = false
    ) throws {
        let bundleIDs = try PatchTransaction.requiredBundleIdentifiers(for: receipt)
        try withResolvedContainers(bundleIDs: bundleIDs) { roots in
            try PatchTransaction.restore(
                receipt: receipt,
                allowChangedTargets: allowChangedTargets,
                containerResolver: { bundleID in
                    guard let root = roots[bundleID] else {
                        throw PatchPackageError.targetAppUnavailable(bundleID)
                    }
                    return root
                }
            )
        }
    }

    static func resetToAppliedState(
        receipt: PatchTransactionReceipt,
        project: PatchProject
    ) throws {
        let bundleIDs = try PatchTransaction.requiredBundleIdentifiers(for: receipt)
        try withResolvedContainers(bundleIDs: bundleIDs) { roots in
            try PatchTransaction.resetToAppliedState(
                receipt: receipt,
                fallbackProject: project,
                containerResolver: { bundleID in
                    guard let root = roots[bundleID] else {
                        throw PatchPackageError.targetAppUnavailable(bundleID)
                    }
                    return root
                }
            )
        }
    }

    static func latestReceipt(projectID: UUID) -> PatchTransactionReceipt? {
        guard let backupRoot = try? PatchProjectLibrary.backupRootURL() else { return nil }
        return PatchTransaction.latestReceipt(projectID: projectID, backupRoot: backupRoot)
    }

    private static func orderedBundleIdentifiers(in project: PatchProject) -> [String] {
        project.allBundleIdentifiers
    }

    private static func withResolvedContainers<T>(
        bundleIDs: [String],
        operation: ([String: URL]) throws -> T
    ) throws -> T {
        var roots: [String: URL] = [:]
        var grants: [Int64] = []
        defer {
            for grant in grants { SandboxAccess.release(grant) }
        }

        for bundleID in bundleIDs {
            guard let path = ContainerStore.resolveAppContainerPath(bundleID: bundleID),
                  ContainerStore.isApplicationContainerPath(path) else {
                throw PatchPackageError.targetAppUnavailable(bundleID)
            }
            // Keep the token for the whole transaction; a release before the
            // copy/restore would revoke it on bad_query.
            let grant = ContainerStore.grantContainerAccess(path)
            if grant >= 0 { grants.append(grant) }
            roots[bundleID] = PatchPathValidator.canonicalFileURL(URL(fileURLWithPath: path, isDirectory: true))
        }
        return try operation(roots)
    }
}
