import SwiftUI

@main
struct DisplayFilterApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        MenuBarExtra("Display Filter", systemImage: "sun.max.fill") {
            ContentView()
                .environmentObject(appState)
                .frame(width: 280)
        }
        .menuBarExtraStyle(.window)
    }
    
    init() {
        setupWorkspaceNotifications()
    }
    
    // Set up notifications for when the active space changes
    private func setupWorkspaceNotifications() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                reapplyAdjustments()
            }
        }
    }
    
    // Reapply adjustments to all screens
    private func reapplyAdjustments() {
        for screen in NSScreen.screens {
            let brightness = ColorAdjuster.shared.getCurrentBrightness(for: screen)
            let filterColor = ColorAdjuster.shared.getCurrentFilterColor(for: screen)
            let filterIntensity = ColorAdjuster.shared.getCurrentFilterIntensity(for: screen)
            ColorAdjuster.shared.setAdjustments(brightness: brightness, filterColor: filterColor, filterIntensity: filterIntensity, for: screen)
        }
    }
}

class AppState: ObservableObject {
    @Published var isFilterActive: Bool = false
}

// Note: The AppDelegate class seems unnecessary for this app structure and can be removed.