import XCTest
import GridOSKit
@testable import Integrations

final class MacIntegrationModelsTests: XCTestCase {
    func testDefaultPreferencesStartWithOptInIntegrationsDisabled() {
        let preferences = MacIntegrationPreferences.defaultValue

        XCTAssertFalse(preferences.showMenuBarExtra)
        XCTAssertFalse(preferences.notificationsEnabled)
        XCTAssertFalse(preferences.indexWorkspaceMetadata)
        XCTAssertEqual(GridOSAppPreferences.showMenuBarExtraStorageKey, "integrations.showMenuBarExtra")
    }

    func testMenuBarRecentDirectoryUsesBasenameDisplayName() {
        let directory = MenuBarRecentDirectory(path: "/Users/example/Projects/gridOS")

        XCTAssertEqual(directory.path, "/Users/example/Projects/gridOS")
        XCTAssertEqual(directory.displayName, "gridOS")
        XCTAssertEqual(directory.id, "/Users/example/Projects/gridOS")
    }

    func testMenuBarActionRegistryContainsRequiredActions() {
        XCTAssertTrue(MenuBarAction.allCases.contains(.openGridOS))
        XCTAssertTrue(MenuBarAction.allCases.contains(.openSettings))
        XCTAssertTrue(MenuBarAction.allCases.contains(.quitGridOS))
        XCTAssertTrue(MenuBarAction.allCases.contains(.openRecentDirectory))
    }

    func testNotificationAuthorizationStatesCoverMacOSValues() {
        XCTAssertEqual(NotificationAuthorizationState.notDetermined.rawValue, "notDetermined")
        XCTAssertEqual(NotificationAuthorizationState.denied.rawValue, "denied")
        XCTAssertEqual(NotificationAuthorizationState.authorized.rawValue, "authorized")
        XCTAssertEqual(NotificationAuthorizationState.provisional.rawValue, "provisional")
        XCTAssertEqual(NotificationAuthorizationState.ephemeral.rawValue, "ephemeral")
    }

    func testNotificationDeliveryRequestIsEquatableAndSanitized() {
        let request = NotificationDeliveryRequest.gridOSWorkFinished(identifier: "gridos.work-finished.test")

        XCTAssertEqual(
            request,
            NotificationDeliveryRequest(
                identifier: "gridos.work-finished.test",
                title: "gridOS work finished",
                body: "A long-running task completed in your workspace."
            )
        )
        XCTAssertFalse(request.title.localizedCaseInsensitiveContains("sk-"))
        XCTAssertFalse(request.body.localizedCaseInsensitiveContains("/Users/"))
        XCTAssertFalse(request.body.localizedCaseInsensitiveContains("export "))
    }
}
