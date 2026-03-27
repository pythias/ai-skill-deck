import SwiftUI

struct SkillDetailView: View {
    let skill: SkillRecord
    var onRefresh: (() -> Void)?
    @State private var showDeleteConfirmation = false
    @State private var showUpgradeSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Circle()
                            .fill(agentGradient)
                            .frame(width: 48, height: 48)
                            .overlay {
                                Text(String(skill.root.title.prefix(1)))
                                    .font(.title2.weight(.semibold))
                                    .foregroundStyle(.white)
                            }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(skill.metadata.displayName ?? skill.metadata.folderName)
                                .font(.title2.weight(.semibold))
                            HStack(spacing: 8) {
                                Text(skill.root.title)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text("•")
                                    .foregroundStyle(.secondary)
                                Text(skill.audit.riskLevel.title)
                                    .font(.subheadline)
                                    .foregroundStyle(riskColor)
                            }
                        }

                        Spacer()
                    }

                    Text(skill.metadata.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))

                // Action buttons
                HStack(spacing: 12) {
                    Button(action: { NSWorkspace.shared.activateFileViewerSelecting([skill.url]) }) {
                        Label("Show in Finder", systemImage: "folder")
                    }

                    if skill.canMutate {
                        Button(action: { showUpgradeSheet = true }) {
                            Label("Upgrade", systemImage: "arrow.triangle.2.circlepath")
                        }

                        Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .buttonStyle(.bordered)

                // Quick stats
                HStack(spacing: 12) {
                    QuickStat(title: "Files", value: "\(skill.fileCount)", icon: "doc")
                    QuickStat(title: "Scripts", value: skill.metadata.hasScripts ? "Yes" : "No", icon: "terminal")
                    QuickStat(title: "References", value: skill.metadata.hasReferences ? "Yes" : "No", icon: "book")
                    QuickStat(title: "Assets", value: skill.metadata.hasAssets ? "Yes" : "No", icon: "photo")
                }

                // Path section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Location")
                        .font(.headline)

                    VStack(spacing: 0) {
                        HStack {
                            Text(skill.url.path)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button(action: { NSWorkspace.shared.activateFileViewerSelecting([skill.url]) }) {
                                Image(systemName: "arrow.up.forward.square")
                            }
                            .buttonStyle(.plain)
                        }
                        .padding()
                    }
                    .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
                }

                // Findings section
                if !skill.audit.findings.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.shield.fill")
                                .foregroundStyle(.orange)
                            Text("Safety Findings")
                                .font(.headline)
                        }

                        VStack(spacing: 0) {
                            ForEach(skill.audit.findings, id: \.self) { finding in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.orange)
                                        .font(.caption)
                                    Text(finding)
                                        .font(.subheadline)
                                    Spacer()
                                }
                                .padding()
                                if finding != skill.audit.findings.last {
                                    Divider()
                                }
                            }
                        }
                        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
                    }
                }

                // Suggestions section
                if !skill.audit.upgradeSuggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundStyle(.blue)
                            Text("Upgrade Suggestions")
                                .font(.headline)
                        }

                        VStack(spacing: 0) {
                            ForEach(skill.audit.upgradeSuggestions, id: \.self) { suggestion in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundStyle(.yellow)
                                        .font(.caption)
                                    Text(suggestion)
                                        .font(.subheadline)
                                    Spacer()
                                }
                                .padding()
                                if suggestion != skill.audit.upgradeSuggestions.last {
                                    Divider()
                                }
                            }
                        }
                        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
                    }
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle(skill.metadata.displayName ?? skill.metadata.folderName)
        .confirmationDialog("Delete Skill", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task {
                    try? FileManager.default.removeItem(at: skill.url)
                    onRefresh?()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \"\(skill.metadata.displayName ?? skill.metadata.folderName)\"? This action cannot be undone.")
        }
        .sheet(isPresented: $showUpgradeSheet) {
            UpgradeSheet(skill: skill, onComplete: onRefresh)
        }
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

    private var riskSystemImage: String {
        switch skill.audit.riskLevel {
        case .low: return "checkmark.shield.fill"
        case .medium: return "exclamationmark.shield.fill"
        case .high: return "xmark.shield.fill"
        }
    }

    private var riskColor: Color {
        switch skill.audit.riskLevel {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

struct QuickStat: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct UpgradeSheet: View {
    let skill: SkillRecord
    var onComplete: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Upgrade Skill")
                .font(.headline)
            Text("Select the folder containing the upgraded version of this skill.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Select Folder...") {
                // TODO: Implement upgrade
                dismiss()
            }
            Button("Cancel", role: .cancel) {
                dismiss()
            }
        }
        .padding(24)
        .frame(width: 300)
    }
}
