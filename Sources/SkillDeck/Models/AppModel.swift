import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    // MARK: - Published State

    var roots: [SkillRoot] = []
    var skills: [SkillRecord] = []
    var selectedSkillID: SkillRecord.ID?
    var searchText = ""
    var isRefreshing = false
    var errorMessage: String?
    var infoMessage = "Ready."

    // MARK: - Private Properties

    private let scanner = SkillScanner()
    private let skillManager = SkillManagerService()

    // MARK: - Computed Properties

    var filteredSkills: [SkillRecord] {
        guard !searchText.isEmpty else { return skills }
        return skills.filter {
            $0.metadata.folderName.localizedCaseInsensitiveContains(searchText)
                || $0.metadata.skillName.localizedCaseInsensitiveContains(searchText)
                || $0.metadata.description.localizedCaseInsensitiveContains(searchText)
                || ($0.metadata.displayName?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var selectedSkill: SkillRecord? {
        guard let selectedSkillID else { return filteredSkills.first }
        return skills.first { $0.id == selectedSkillID }
    }

    // MARK: - Actions

    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let snapshot = try await Task.detached(priority: .userInitiated) {
                try SkillScanner().scanAll()
            }.value

            roots = snapshot.roots
            skills = snapshot.skills
            if selectedSkillID == nil {
                selectedSkillID = skills.first?.id
            } else if skills.contains(where: { $0.id == selectedSkillID }) == false {
                selectedSkillID = skills.first?.id
            }
            infoMessage = "Loaded \(skills.count) skills across \(roots.count) roots."
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func revealSelectedSkill() {
        guard let url = selectedSkill?.url else { return }
        skillManager.revealSkill(at: url)
    }

    func importSkill() async {
        do {
            let sourceURL = try skillManager.chooseSkillFolder(title: "Import Skill")
            let destinationRoot = try skillManager.ensurePrimarySkillRoot()
            try skillManager.importSkill(from: sourceURL, to: destinationRoot)
            infoMessage = "Imported \(sourceURL.lastPathComponent) into \(destinationRoot.path)."
            await refresh()
        } catch {
            if let error = error as? CancellationError {
                _ = error
                return
            }
            errorMessage = error.localizedDescription
        }
    }

    func upgradeSelectedSkill() async {
        guard let selectedSkill, selectedSkill.canMutate else {
            errorMessage = "Select a writable skill before upgrading."
            return
        }

        do {
            let sourceURL = try skillManager.chooseSkillFolder(title: "Upgrade Skill From Folder")
            try skillManager.upgradeSkill(at: selectedSkill.url, from: sourceURL)
            infoMessage = "Upgraded \(selectedSkill.metadata.folderName) from \(sourceURL.path)."
            await refresh()
        } catch {
            if let error = error as? CancellationError {
                _ = error
                return
            }
            errorMessage = error.localizedDescription
        }
    }

    func deleteSelectedSkill() async {
        guard let selectedSkill, selectedSkill.canMutate else {
            errorMessage = "Select a writable skill before deleting."
            return
        }

        do {
            try skillManager.deleteSkill(at: selectedSkill.url)
            infoMessage = "Deleted \(selectedSkill.metadata.folderName)."
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
