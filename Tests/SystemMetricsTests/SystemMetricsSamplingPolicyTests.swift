import XCTest
@testable import SystemMetrics

final class SystemMetricsSamplingPolicyTests: XCTestCase {
    func testDefaultCadences() {
        let policy = SystemMetricsSamplingPolicy.defaultValue

        XCTAssertEqual(policy.fastCadence, 10.0)
        XCTAssertEqual(policy.slowCadence, 30.0)
        XCTAssertEqual(policy.backgroundCadence, 5.0)
        XCTAssertEqual(policy.fastStaleThreshold, 15.0)
        XCTAssertEqual(policy.slowStaleThreshold, 60.0)
    }

    func testCadenceUsesActiveAndBackgroundState() {
        let policy = SystemMetricsSamplingPolicy.defaultValue

        XCTAssertEqual(policy.cadence(isActive: true, includesFastMetrics: true), 10.0)
        XCTAssertEqual(policy.cadence(isActive: true, includesFastMetrics: false), 30.0)
        XCTAssertEqual(policy.cadence(isActive: false, includesFastMetrics: true), 5.0)
        XCTAssertEqual(policy.cadence(isActive: false, includesFastMetrics: false), 5.0)
    }

    func testStaleThresholdUsesFastAndSlowMetricGroups() {
        let policy = SystemMetricsSamplingPolicy.defaultValue

        XCTAssertEqual(policy.staleThreshold(includesFastMetrics: true), 15.0)
        XCTAssertEqual(policy.staleThreshold(includesFastMetrics: false), 60.0)
    }
}
