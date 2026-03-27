import SwiftUI

@main
struct SkillDeckApp: App {
    @State private var model: AppModel

    init() {
        _model = State(initialValue: AppModel())
    }

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .frame(minWidth: 1120, minHeight: 720)
        }
        .windowStyle(.hiddenTitleBar)
    }
}
