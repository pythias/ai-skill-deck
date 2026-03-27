import Foundation

struct SkillScanner {
    private let fileManager = FileManager.default

    func scanAll() throws -> (roots: [SkillRoot], skills: [SkillRecord]) {
        let roots = discoverRoots()
        var skills: [SkillRecord] = []

        for root in roots {
            guard fileManager.fileExists(atPath: root.url.path) else { continue }
            skills.append(contentsOf: try scanSkills(in: root))
        }

        skills.sort {
            if $0.root.title == $1.root.title {
                return $0.metadata.folderName.localizedCaseInsensitiveCompare($1.metadata.folderName) == .orderedAscending
            }
            return $0.root.title.localizedCaseInsensitiveCompare($1.root.title) == .orderedAscending
        }

        return (roots, skills)
    }

    private func discoverRoots() -> [SkillRoot] {
        let homeURL = fileManager.homeDirectoryForCurrentUser
        let codexHome = ProcessInfo.processInfo.environment["CODEX_HOME"].map { URL(fileURLWithPath: $0) }
            ?? homeURL.appendingPathComponent(".codex", isDirectory: true)

        let knownAgents: [(name: String, basePath: String, skillsSubdir: String)] = [
            ("OpenClaw", ".openclaw", "skills"),
            ("ClaudeCode", ".claude", "skills"),
            ("Cursor", ".cursor", "skills"),
            ("Windsurf", ".windsurf", "skills"),
            ("Aider", ".aider", "skills"),
            ("Agents", ".agents", "skills"),
        ]

        var roots: [SkillRoot] = []
        var seen = Set<String>()

        // Codex - use CODEX_HOME if set
        let codexSkillsURL = codexHome.appendingPathComponent("skills", isDirectory: true)
        let codexRootID = codexSkillsURL.path
        if seen.insert(codexRootID).inserted {
            roots.append(SkillRoot(
                title: "Codex Skills",
                url: codexSkillsURL,
                allowsMutations: true,
                isProtected: false,
                note: "Primary install location for Codex skills."
            ))
            let systemURL = codexSkillsURL.appendingPathComponent(".system", isDirectory: true)
            let systemID = systemURL.path
            if seen.insert(systemID).inserted {
                roots.append(SkillRoot(
                    title: "System Skills",
                    url: systemURL,
                    allowsMutations: false,
                    isProtected: true,
                    note: "Bundled system skills. Read-only in the app."
                ))
            }
        }

        // Other agents
        for agent in knownAgents {
            let baseURL = homeURL.appendingPathComponent(agent.basePath, isDirectory: true)
            let skillsURL = baseURL.appendingPathComponent(agent.skillsSubdir, isDirectory: true)
            let rootID = skillsURL.path

            guard seen.insert(rootID).inserted else { continue }

            roots.append(SkillRoot(
                title: "\(agent.name) Skills",
                url: skillsURL,
                allowsMutations: true,
                isProtected: false,
                note: "Skills for \(agent.name)."
            ))
        }

        if let workspaceRoot = findWorkspaceRoot() {
            let workspaceSkillsURL = workspaceRoot.appendingPathComponent("skill", isDirectory: true)
            let workspaceID = workspaceSkillsURL.path
            if seen.insert(workspaceID).inserted {
                roots.append(SkillRoot(
                    title: "Workspace Skills",
                    url: workspaceSkillsURL,
                    allowsMutations: true,
                    isProtected: false,
                    note: "Skill workspace discovered from the current project tree."
                ))
            }
        }

        return roots
    }

    private func findWorkspaceRoot() -> URL? {
        var cursor = URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)

        for _ in 0..<8 {
            let readme = cursor.appendingPathComponent("README.md")
            let skillDir = cursor.appendingPathComponent("skill", isDirectory: true)
            if fileManager.fileExists(atPath: readme.path), fileManager.fileExists(atPath: skillDir.path) {
                return cursor
            }
            cursor.deleteLastPathComponent()
        }

        return nil
    }

    private func scanSkills(in root: SkillRoot) throws -> [SkillRecord] {
        let entries = try fileManager.contentsOfDirectory(
            at: root.url,
            includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )

        return try entries.compactMap { entry in
            let values = try entry.resourceValues(forKeys: [.isDirectoryKey, .contentModificationDateKey])
            guard values.isDirectory == true else { return nil }
            let skillFile = entry.appendingPathComponent("SKILL.md")
            guard fileManager.fileExists(atPath: skillFile.path) else { return nil }

            let metadata = try parseMetadata(in: entry)
            let audit = try auditSkill(at: entry, metadata: metadata, root: root)
            let fileCount = countFiles(in: entry)

            return SkillRecord(
                url: entry,
                root: root,
                metadata: metadata,
                audit: audit,
                fileCount: fileCount,
                updatedAt: values.contentModificationDate
            )
        }
    }

    private func parseMetadata(in skillURL: URL) throws -> SkillMetadata {
        let skillMarkdown = try String(contentsOf: skillURL.appendingPathComponent("SKILL.md"), encoding: .utf8)
        let frontmatter = extractFrontmatter(from: skillMarkdown)

        let folderName = skillURL.lastPathComponent
        let skillName = frontmatter["name"] ?? folderName
        let description = frontmatter["description"] ?? "Missing description"
        let hasTodoMarkers = skillMarkdown.localizedCaseInsensitiveContains("[TODO")
            || skillMarkdown.localizedCaseInsensitiveContains("todo:")
            || description.localizedCaseInsensitiveContains("[TODO")

        let openAIYamlURL = skillURL.appendingPathComponent("agents/openai.yaml")
        let openAIYaml = try? String(contentsOf: openAIYamlURL, encoding: .utf8)

        return SkillMetadata(
            folderName: folderName,
            skillName: skillName,
            description: description,
            displayName: value(in: openAIYaml, for: "display_name"),
            shortDescription: value(in: openAIYaml, for: "short_description"),
            defaultPrompt: value(in: openAIYaml, for: "default_prompt"),
            hasOpenAIYaml: openAIYaml != nil,
            hasScripts: fileManager.fileExists(atPath: skillURL.appendingPathComponent("scripts").path),
            hasReferences: fileManager.fileExists(atPath: skillURL.appendingPathComponent("references").path),
            hasAssets: fileManager.fileExists(atPath: skillURL.appendingPathComponent("assets").path),
            hasTodoMarkers: hasTodoMarkers
        )
    }

    private func extractFrontmatter(from markdown: String) -> [String: String] {
        let trimmed = markdown.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("---") else { return [:] }

        let segments = trimmed.components(separatedBy: "\n---")
        guard segments.count >= 2 else { return [:] }

        let yamlBlock = segments[0]
            .replacingOccurrences(of: "---\n", with: "")
            .replacingOccurrences(of: "---", with: "")

        var result: [String: String] = [:]
        for line in yamlBlock.split(separator: "\n") {
            guard let colonIndex = line.firstIndex(of: ":") else { continue }
            let key = line[..<colonIndex].trimmingCharacters(in: .whitespaces)
            let value = line[line.index(after: colonIndex)...].trimmingCharacters(in: .whitespaces)
            result[key] = value.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        }
        return result
    }

    private func value(in yaml: String?, for key: String) -> String? {
        guard let yaml else { return nil }
        guard let line = yaml.split(separator: "\n").first(where: { $0.trimmingCharacters(in: .whitespaces).hasPrefix("\(key):") }) else {
            return nil
        }
        guard let colonIndex = line.firstIndex(of: ":") else { return nil }
        return line[line.index(after: colonIndex)...]
            .trimmingCharacters(in: .whitespaces)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
    }

    private func auditSkill(at skillURL: URL, metadata: SkillMetadata, root: SkillRoot) throws -> SkillAudit {
        var findings: [String] = []
        var suggestions: [String] = []
        var risk: RiskLevel = .low

        if root.isProtected {
            findings.append("Protected root. Delete and in-place upgrade actions are disabled.")
        }

        if !metadata.hasOpenAIYaml {
            suggestions.append("Add agents/openai.yaml so the skill has UI metadata and a default prompt.")
        }

        if metadata.hasTodoMarkers {
            suggestions.append("Remove TODO placeholders from SKILL.md or metadata before shipping.")
            risk = max(risk, .medium)
        }

        if metadata.description.count < 32 {
            suggestions.append("Expand the SKILL.md description so triggering is more reliable.")
        }

        if metadata.shortDescription == nil {
            suggestions.append("Add interface.short_description for faster scanning in the UI.")
        }

        if metadata.defaultPrompt == nil {
            suggestions.append("Add interface.default_prompt so invocation has a sensible starting prompt.")
        }

        let suspiciousPatterns: [(pattern: String, finding: String, level: RiskLevel)] = [
            ("rm -rf", "Contains destructive shell deletion patterns.", .high),
            ("curl | sh", "Pipes network downloads directly into a shell.", .high),
            ("wget | sh", "Pipes downloaded content directly into a shell.", .high),
            ("sudo ", "Requests elevated privileges inside skill resources.", .high),
            ("osascript", "Uses AppleScript automation that can control the local desktop.", .medium),
            ("open ", "Launches local apps or URLs via shell commands.", .medium),
            ("subprocess", "Runs subprocesses from script resources.", .medium),
            ("eval(", "Evaluates dynamic code at runtime.", .high),
            ("exec(", "Executes dynamic code at runtime.", .high),
            ("requests.get(", "Performs outbound network requests.", .medium),
            ("urllib.request", "Performs outbound network requests.", .medium)
        ]

        for content in try loadAuditedTextFiles(in: skillURL) {
            let lowercased = content.lowercased()
            for pattern in suspiciousPatterns where lowercased.contains(pattern.pattern) {
                findings.append(pattern.finding)
                risk = max(risk, pattern.level)
            }
        }

        findings = Array(NSOrderedSet(array: findings)) as? [String] ?? findings
        suggestions = Array(NSOrderedSet(array: suggestions)) as? [String] ?? suggestions

        return SkillAudit(riskLevel: risk, findings: findings, upgradeSuggestions: suggestions)
    }

    private func loadAuditedTextFiles(in skillURL: URL) throws -> [String] {
        guard let enumerator = fileManager.enumerator(
            at: skillURL,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        let allowedExtensions = Set(["md", "py", "sh", "swift", "yaml", "yml", "json", "txt", "rb"])
        var contents: [String] = []

        for case let fileURL as URL in enumerator {
            let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
            guard values.isRegularFile == true else { continue }
            guard allowedExtensions.contains(fileURL.pathExtension.lowercased()) else { continue }
            guard (values.fileSize ?? 0) < 256_000 else { continue }

            if let text = try? String(contentsOf: fileURL, encoding: .utf8) {
                contents.append(text)
            }
        }

        return contents
    }

    private func countFiles(in url: URL) -> Int {
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey]) else {
            return 0
        }

        var count = 0
        for case let fileURL as URL in enumerator {
            let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey])
            if values?.isRegularFile == true {
                count += 1
            }
        }
        return count
    }
}
