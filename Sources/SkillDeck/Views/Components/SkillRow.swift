import SwiftUI

struct SkillRow: View {
    let skill: SkillRecord

    var body: some View {
        HStack(spacing: 12) {
            // Agent icon
            Circle()
                .fill(agentGradient)
                .frame(width: 36, height: 36)
                .overlay {
                    Text(String(skill.root.title.prefix(1)))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }

            // Skill info
            VStack(alignment: .leading, spacing: 3) {
                Text(skill.metadata.displayName ?? skill.metadata.folderName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(riskColor)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(skill.root.title)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if skill.metadata.hasScripts {
                        Image(systemName: "terminal")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                    if skill.metadata.hasAssets {
                        Image(systemName: "photo.stack")
                            .font(.caption2)
                            .foregroundStyle(.purple)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }

    private var agentGradient: LinearGradient {
        let color = agentColor
        return LinearGradient(
            colors: [color, color.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var agentColor: Color {
        switch skill.root.title {
        case let title where title.contains("Codex"): return .blue
        case let title where title.contains("Claude"): return .purple
        case let title where title.contains("Cursor"): return .cyan
        case let title where title.contains("Windsurf"): return .mint
        case let title where title.contains("OpenClaw"): return .orange
        case let title where title.contains("Aider"): return .green
        case let title where title.contains("Workspace"): return .pink
        default: return .gray
        }
    }

    private var riskColor: Color {
        switch skill.audit.riskLevel {
        case .low: return .primary
        case .medium: return .orange
        case .high: return .red
        }
    }
}
