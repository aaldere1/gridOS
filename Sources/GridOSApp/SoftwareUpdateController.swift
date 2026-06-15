import Combine
import Sparkle
import SwiftUI

@MainActor
final class SoftwareUpdateController {
    static let shared = SoftwareUpdateController()

    let updaterController: SPUStandardUpdaterController

    private init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    var updater: SPUUpdater {
        updaterController.updater
    }
}

@MainActor
final class CheckForUpdatesViewModel: ObservableObject {
    @Published var canCheckForUpdates: Bool

    init(updater: SPUUpdater) {
        canCheckForUpdates = updater.canCheckForUpdates
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }
}

struct CheckForUpdatesView: View {
    @StateObject private var viewModel: CheckForUpdatesViewModel

    private let updater: SPUUpdater

    init(controller: SoftwareUpdateController = .shared) {
        let updater = controller.updater
        self.updater = updater
        _viewModel = StateObject(wrappedValue: CheckForUpdatesViewModel(updater: updater))
    }

    var body: some View {
        Button("Check for Updates...") {
            updater.checkForUpdates()
        }
        .disabled(!viewModel.canCheckForUpdates)
    }
}

struct SoftwareUpdateSettingsView: View {
    @StateObject private var viewModel: CheckForUpdatesViewModel
    @State private var automaticallyChecksForUpdates: Bool
    @State private var automaticallyDownloadsUpdates: Bool

    private let updater: SPUUpdater

    init(controller: SoftwareUpdateController = .shared) {
        let updater = controller.updater
        self.updater = updater
        _viewModel = StateObject(wrappedValue: CheckForUpdatesViewModel(updater: updater))
        _automaticallyChecksForUpdates = State(initialValue: updater.automaticallyChecksForUpdates)
        _automaticallyDownloadsUpdates = State(initialValue: updater.automaticallyDownloadsUpdates)
    }

    var body: some View {
        Section("Software Updates") {
            Toggle("Automatically check for updates", isOn: $automaticallyChecksForUpdates)
                .onChange(of: automaticallyChecksForUpdates) { _, newValue in
                    updater.automaticallyChecksForUpdates = newValue
                    if !newValue {
                        automaticallyDownloadsUpdates = false
                        updater.automaticallyDownloadsUpdates = false
                    }
                }
                .accessibilityLabel("Automatically check for updates")
                .accessibilityValue(automaticallyChecksForUpdates ? "On" : "Off")

            Toggle("Automatically download and install updates", isOn: $automaticallyDownloadsUpdates)
                .disabled(!automaticallyChecksForUpdates)
                .onChange(of: automaticallyDownloadsUpdates) { _, newValue in
                    updater.automaticallyDownloadsUpdates = newValue
                }
                .accessibilityLabel("Automatically download and install updates")
                .accessibilityValue(automaticallyDownloadsUpdates ? "On" : "Off")

            Button("Check for Updates...") {
                updater.checkForUpdates()
            }
            .disabled(!viewModel.canCheckForUpdates)
            .accessibilityLabel("Check for Updates")

            Text("Updates use signed GitHub release assets. Anonymous system profiling is off.")
                .foregroundStyle(.secondary)
        }
    }
}
