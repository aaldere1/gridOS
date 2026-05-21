import XCTest
import UserNotifications
@testable import Integrations

final class LocalNotificationClientTests: XCTestCase {
    func testAuthorizationStateMapsNotDetermined() async {
        let client = LocalNotificationClient(
            center: RecordingUserNotificationCenterClient(authorizationStatus: .notDetermined)
        )

        let state = await client.authorizationState()

        XCTAssertEqual(state, .notDetermined)
    }

    func testAuthorizationStateMapsDeniedAuthorizedAndProvisional() async {
        let denied = LocalNotificationClient(
            center: RecordingUserNotificationCenterClient(authorizationStatus: .denied)
        )
        let authorized = LocalNotificationClient(
            center: RecordingUserNotificationCenterClient(authorizationStatus: .authorized)
        )
        let provisional = LocalNotificationClient(
            center: RecordingUserNotificationCenterClient(authorizationStatus: .provisional)
        )

        let deniedState = await denied.authorizationState()
        let authorizedState = await authorized.authorizationState()
        let provisionalState = await provisional.authorizationState()

        XCTAssertEqual(deniedState, .denied)
        XCTAssertEqual(authorizedState, .authorized)
        XCTAssertEqual(provisionalState, .provisional)
    }

    func testRequestAuthorizationMapsAuthorizedState() async {
        let center = RecordingUserNotificationCenterClient(
            authorizationStatus: .notDetermined,
            statusAfterAuthorization: .authorized
        )
        let client = LocalNotificationClient(center: center)

        let state = await client.requestAuthorization()
        let options = center.requestedAuthorizationOptions()

        XCTAssertEqual(state, .authorized)
        XCTAssertTrue(options?.contains(.alert) == true)
        XCTAssertTrue(options?.contains(.sound) == true)
    }

    func testWorkFinishedRequestUsesSanitizedContent() {
        let request = NotificationDeliveryRequest.gridOSWorkFinished(identifier: "gridos.work-finished.test")

        XCTAssertEqual(request.identifier, "gridos.work-finished.test")
        XCTAssertEqual(request.title, "gridOS work finished")
        XCTAssertEqual(request.body, "A long-running task completed in your workspace.")
        XCTAssertFalse(request.title.localizedCaseInsensitiveContains("/Users/"))
        XCTAssertFalse(request.body.localizedCaseInsensitiveContains("export "))
        XCTAssertFalse(request.body.localizedCaseInsensitiveContains("sk-"))
    }

    func testDeliverSchedulesNotificationRequest() async {
        let center = RecordingUserNotificationCenterClient(authorizationStatus: .authorized)
        let client = LocalNotificationClient(center: center)

        let result = await client.deliver(
            .gridOSWorkFinished(identifier: "gridos.work-finished.test")
        )
        let requests = center.addedNotificationRequests()

        XCTAssertEqual(result, .delivered)
        XCTAssertEqual(requests.count, 1)
        XCTAssertEqual(requests[0].identifier, "gridos.work-finished.test")
        XCTAssertEqual(requests[0].content.title, "gridOS work finished")
        XCTAssertEqual(requests[0].content.body, "A long-running task completed in your workspace.")
        XCTAssertNil(requests[0].trigger)
    }

    func testDeliverMapsFailureToProductResult() async {
        let center = RecordingUserNotificationCenterClient(
            authorizationStatus: .authorized,
            addError: TestNotificationError.deliveryFailed
        )
        let client = LocalNotificationClient(center: center)

        let result = await client.deliver(
            .gridOSWorkFinished(identifier: "gridos.work-finished.test")
        )

        XCTAssertFalse(result.delivered)
        XCTAssertEqual(result.message, "Integration unavailable. Check macOS permissions and try again.")
    }
}

private enum TestNotificationError: Error {
    case deliveryFailed
}

private final class RecordingUserNotificationCenterClient: UserNotificationCenterClient, @unchecked Sendable {
    private var authorizationStatus: UNAuthorizationStatus
    private let statusAfterAuthorization: UNAuthorizationStatus
    private let addError: Error?
    private var options: UNAuthorizationOptions?
    private var requests: [UNNotificationRequest] = []

    init(
        authorizationStatus: UNAuthorizationStatus,
        statusAfterAuthorization: UNAuthorizationStatus? = nil,
        addError: Error? = nil
    ) {
        self.authorizationStatus = authorizationStatus
        self.statusAfterAuthorization = statusAfterAuthorization ?? authorizationStatus
        self.addError = addError
    }

    func notificationSettings() async -> UserNotificationSettingsSnapshot {
        UserNotificationSettingsSnapshot(authorizationStatus: authorizationStatus)
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        self.options = options
        authorizationStatus = statusAfterAuthorization
        return authorizationStatus == .authorized || authorizationStatus == .provisional
    }

    func add(_ request: UNNotificationRequest) async throws {
        if let addError {
            throw addError
        }

        requests.append(request)
    }

    func requestedAuthorizationOptions() -> UNAuthorizationOptions? {
        options
    }

    func addedNotificationRequests() -> [UNNotificationRequest] {
        requests
    }
}
