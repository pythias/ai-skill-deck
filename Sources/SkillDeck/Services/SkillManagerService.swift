import AppKit
import Foundation

struct SkillManagerError: LocalizedError {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? { message }
}

final class SkillManagerService {
    private let fileManager = FileManager.default

    func revealSkill(at url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func importSkill(from sourceURL: URL, to destinationRoot: URL) throws {
        let destinationURL = destinationRoot.appendingPathComponent(sourceURL.lastPathComponent, isDirectory: true)

        guard fileManager.fileExists(atPath: destinationURL.path) == false else {
            throw SkillManagerError("A skill with that folder name already exists in the target skills folder.")
        }

        try fileManager.copyItem(at: sourceURL, to: destinationURL)
    }

    func upgradeSkill(at targetURL: URL, from sourceURL: URL) throws {
        let tempBase = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let backupURL = tempBase.appendingPathComponent("backup", isDirectory: true)

        try fileManager.createDirectory(at: tempBase, withIntermediateDirectories: true)
        try fileManager.copyItem(at: targetURL, to: backupURL)

        do {
            try fileManager.removeItem(at: targetURL)
            try fileManager.copyItem(at: sourceURL, to: targetURL)
            try? fileManager.removeItem(at: tempBase)
        } catch {
            try? fileManager.removeItem(at: targetURL)
            try? fileManager.copyItem(at: backupURL, to: targetURL)
            throw error
        }
    }

    func deleteSkill(at url: URL) throws {
        try fileManager.removeItem(at: url)
    }

    @MainActor
    func chooseSkillFolder(title: String) throws -> URL {
        let panel = NSOpenPanel()
        panel.title = title
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select"

        guard panel.runModal() == .OK, let url = panel.url else {
            throw CancellationError()
        }

        let skillFile = url.appendingPathComponent("SKILL.md")
        guard fileManager.fileExists(atPath: skillFile.path) else {
            throw SkillManagerError("Selected folder is not a skill. SKILL.md is missing.")
        }

        return url
    }

    func ensurePrimarySkillRoot() throws -> URL {
        let homeURL = fileManager.homeDirectoryForCurrentUser
        let codexHome = ProcessInfo.processInfo.environment["CODEX_HOME"].map(URL.init(fileURLWithPath:))
            ?? homeURL.appendingPathComponent(".codex", isDirectory: true)
        let skillsRoot = codexHome.appendingPathComponent("skills", isDirectory: true)
        try fileManager.createDirectory(at: skillsRoot, withIntermediateDirectories: true)
        return skillsRoot
    }
}
