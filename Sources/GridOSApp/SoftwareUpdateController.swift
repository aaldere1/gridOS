import Combine
import Foundation
import Sparkle
import SwiftUI

@MainActor
struct SoftwareUpdateInfo: Equatable {
    let displayVersion: String
    let buildVersion: String

    var displayName: String {
        if displayVersion == buildVersion {
            return displayVersion
        }

        return "\(displayVersion) (\(buildVersion))"
    }
}

@MainActor
enum SoftwareUpdateAvailability: Equatable {
    case unknown
    case checking
    case current
    case available(SoftwareUpdateInfo)

    var availableUpdate: SoftwareUpdateInfo? {
        guard case let .available(update) = self else {
            return nil
        }

        return update
    }

    var isChecking: Bool {
        guard case .checking = self else {
            return false
        }

        return true
    }

    var statusDescription: String {
        switch self {
        case .unknown:
            return "Update availability has not been checked this session."
        case .checking:
            return "Checking GitHub releases through Sparkle."
        case .current:
            return "gridOS is up to date."
        case let .available(update):
            return "gridOS \(update.displayName) is available."
        }
    }
}

@MainActor
final class SoftwareUpdateController: NSObject, ObservableObject, SPUUpdaterDelegate {
    static let shared = SoftwareUpdateController()

    @Published private(set) var availability: SoftwareUpdateAvailability = .unknown
    @Published private(set) var canCheckForUpdates = false

    private let lastAvailabilityRefreshDefaultsKey = "softwareUpdate.lastAvailabilityRefreshDate"
    private let availabilityRefreshInterval: TimeInterval = 6 * 60 * 60

    private(set) lazy var updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: self,
        userDriverDelegate: nil
    )

    private override init() {
        super.init()
        _ = updaterController

        canCheckForUpdates = updater.canCheckForUpdates
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }

    var updater: SPUUpdater {
        updaterController.updater
    }

    func checkForUpdates() {
        guard canCheckForUpdates else {
            return
        }

        updater.checkForUpdates()
    }

    func refreshAvailabilityIfNeeded(now: Date = Date()) {
        guard updater.automaticallyChecksForUpdates,
              canCheckForUpdates,
              !availability.isChecking else {
            return
        }

        guard let lastRefreshDate = UserDefaults.standard.object(
            forKey: lastAvailabilityRefreshDefaultsKey
        ) as? Date else {
            refreshUpdateAvailability(now: now)
            return
        }

        if now.timeIntervalSince(lastRefreshDate) >= availabilityRefreshInterval {
            refreshUpdateAvailability(now: now)
        }
    }

    func refreshUpdateAvailability(now: Date = Date()) {
        guard canCheckForUpdates else {
            return
        }

        availability = .checking
        UserDefaults.standard.set(now, forKey: lastAvailabilityRefreshDefaultsKey)
        updater.checkForUpdateInformation()
    }

    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        availability = .available(
            SoftwareUpdateInfo(
                displayVersion: item.displayVersionString,
                buildVersion: item.versionString
            )
        )
    }

    func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        availability = .current
    }

    func updaterDidNotFindUpdate(_ updater: SPUUpdater, error: Error) {
        availability = .current
    }

    func updater(
        _ updater: SPUUpdater,
        didFinishUpdateCycleFor updateCheck: SPUUpdateCheck,
        error: Error?
    ) {
        if availability.isChecking {
            availability = error == nil ? .current : .unknown
        }
    }
}

struct CheckForUpdatesView: View {
    @ObservedObject private var controller: SoftwareUpdateController

    init(controller: SoftwareUpdateController = .shared) {
        _controller = ObservedObject(wrappedValue: controller)
    }

    var body: some View {
        Button("Check for Updates...") {
            controller.checkForUpdates()
        }
        .disabled(!controller.canCheckForUpdates)
    }
}

struct SoftwareUpdateSettingsView: View {
    @ObservedObject private var controller: SoftwareUpdateController
    @State private var automaticallyChecksForUpdates: Bool
    @State private var automaticallyDownloadsUpdates: Bool

    private let updater: SPUUpdater

    init(controller: SoftwareUpdateController = .shared) {
        self.updater = controller.updater
        _controller = ObservedObject(wrappedValue: controller)
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

            Text(controller.availability.statusDescription)
                .foregroundStyle(controller.availability.availableUpdate == nil ? .secondary : .primary)
                .accessibilityLabel("Update status")

            HStack {
                Button(updateActionTitle) {
                    controller.checkForUpdates()
                }
                .disabled(!controller.canCheckForUpdates)
                .accessibilityLabel(updateActionTitle)

                Button(controller.availability.isChecking ? "Checking..." : "Refresh Update Status") {
                    controller.refreshUpdateAvailability()
                }
                .disabled(!controller.canCheckForUpdates || controller.availability.isChecking)
                .accessibilityLabel("Refresh Update Status")
            }

            Text("Updates use signed GitHub release assets. Anonymous system profiling is off.")
                .foregroundStyle(.secondary)
        }
    }

    private var updateActionTitle: String {
        if let update = controller.availability.availableUpdate {
            return "Update to \(update.displayName)..."
        }

        return "Check for Updates..."
    }
}
