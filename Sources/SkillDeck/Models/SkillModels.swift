import Foundation

struct SkillRoot: Identifiable, Hashable, Sendable {
    let title: String
    let url: URL
    let allowsMutations: Bool
    let isProtected: Bool
    let note: String

    var id: String { url.path }
}

enum RiskLevel: Int, Comparable, Sendable {
    case low = 0
    case medium = 1
    case high = 2

    static func < (lhs: RiskLevel, rhs: RiskLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var title: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
}

struct SkillAudit: Hashable, Sendable {
    let riskLevel: RiskLevel
    let findings: [String]
    let upgradeSuggestions: [String]
}

struct SkillRecord: Identifiable, Hashable, Sendable {
    let url: URL
    let root: SkillRoot
    let metadata: SkillMetadata
    let audit: SkillAudit
    let fileCount: Int
    let updatedAt: Date?

    var id: String { url.path }
    var canMutate: Bool { root.allowsMutations && !root.isProtected }
}

struct SkillMetadata: Hashable, Sendable {
    let folderName: String
    let skillName: String
    let description: String
    let displayName: String?
    let shortDescription: String?
    let defaultPrompt: String?
    let hasOpenAIYaml: Bool
    let hasScripts: Bool
    let hasReferences: Bool
    let hasAssets: Bool
    let hasTodoMarkers: Bool
}
