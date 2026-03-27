import SwiftUI

struct ContentView: View {
    @Bindable var model: AppModel
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Header stats
                HStack(spacing: 12) {
                    StatCard(title: "Skills", value: "\(model.skills.count)")
                    StatCard(title: "Agents", value: "\(model.roots.count)")
                    StatCard(title: "High Risk", value: "\(model.skills.filter { $0.audit.riskLevel == .high }.count)")
                }
                .padding()

                Divider()

                // Skill list
                List(selection: $model.selectedSkillID) {
                    ForEach(model.filteredSkills, id: \.id) { skill in
                        SkillRow(skill: skill)
                            .tag(skill.id)
                    }
                }
                .listStyle(.sidebar)
                .navigationTitle("Skills")
            }
        } detail: {
            if let skill = model.selectedSkill {
                SkillDetailView(skill: skill, onRefresh: { Task { await model.refresh() } })
            } else {
                ContentUnavailableView(
                    "No Skill Selected",
                    systemImage: "square.stack.3d.up.slash",
                    description: Text("Select a skill from the sidebar to view details.")
                )
            }
        }
        .searchable(text: $model.searchText, prompt: "Search skills")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { Task { await model.refresh() } }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .keyboardShortcut("r")
            }
        }
        .task {
            if model.skills.isEmpty {
                await model.refresh()
            }
        }
        .alert("SkillDeck Error", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { newValue in
                if newValue == false {
                    model.errorMessage = nil
                }
            }
        )) {
            Button("Close", role: .cancel) {
                model.errorMessage = nil
            }
        } message: {
            Text(model.errorMessage ?? "")
        }
        .confirmationDialog("Delete Skill", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task { await model.deleteSelectedSkill() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let skill = model.selectedSkill {
                Text("Are you sure you want to delete \"\(skill.metadata.displayName ?? skill.metadata.folderName)\"? This action cannot be undone.")
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.semibold))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
    }
}
