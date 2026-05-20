import XCTest
@testable import SystemMetrics

final class SystemMetricsDeltaTests: XCTestCase {
    func testCPUPercentUsesDelta() {
        let metrics = CPUMetrics.percent(
            user: 30,
            system: 20,
            idle: 50,
            nice: 0
        )

        XCTAssertEqual(metrics.usagePercent, 50, accuracy: 0.001)
        XCTAssertEqual(metrics.userPercent, 30, accuracy: 0.001)
        XCTAssertEqual(metrics.systemPercent, 20, accuracy: 0.001)
        XCTAssertEqual(metrics.idlePercent, 50, accuracy: 0.001)
    }

    func testNetworkThroughputUsesDelta() {
        let throughput = NetworkMetrics.throughput(
            previousBytes: 1_000,
            currentBytes: 3_000,
            elapsed: 2
        )

        XCTAssertEqual(throughput, 1_000, accuracy: 0.001)
    }

    func testTopProcessCPUPercentUsesDelta() {
        let percent = TopProcessMetrics.cpuPercent(
            previousTotalTime: 1_000_000_000,
            currentTotalTime: 2_500_000_000,
            elapsed: 3,
            processorCount: 4
        )

        XCTAssertEqual(percent, 50, accuracy: 0.001)
    }

    func testNegativeAndImpossibleDeltasClampToZero() {
        XCTAssertEqual(
            CPUMetrics.percent(user: -5, system: 0, idle: 5).usagePercent,
            0,
            accuracy: 0.001
        )
        XCTAssertEqual(
            NetworkMetrics.throughput(previousBytes: 3_000, currentBytes: 1_000, elapsed: 1),
            0,
            accuracy: 0.001
        )
        XCTAssertEqual(
            TopProcessMetrics.cpuPercent(
                previousTotalTime: 3_000,
                currentTotalTime: 1_000,
                elapsed: 1,
                processorCount: 8
            ),
            0,
            accuracy: 0.001
        )
    }

    func testPercentCalculationsAreCapped() {
        let hostCPU = CPUMetrics.percent(user: 1_000, system: 1_000, idle: 0, nice: 1_000)
        let processCPU = TopProcessMetrics.cpuPercent(
            previousTotalTime: 0,
            currentTotalTime: 10_000_000_000,
            elapsed: 1,
            processorCount: 2
        )

        XCTAssertEqual(hostCPU.usagePercent, 100, accuracy: 0.001)
        XCTAssertEqual(processCPU, 200, accuracy: 0.001)
    }
}
