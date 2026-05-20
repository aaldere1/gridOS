import XCTest
@testable import SystemMetrics

final class SystemMetricsModelTests: XCTestCase {
    func testAvailabilityStatesExposeDisplayState() {
        let metrics = CPUMetrics(
            usagePercent: 22,
            userPercent: 14,
            systemPercent: 8,
            idlePercent: 78
        )

        let available = SystemMetricAvailability.available(metrics)
        XCTAssertTrue(available.isAvailable)
        XCTAssertFalse(available.isStale)
        XCTAssertNil(available.unavailableReason)
        XCTAssertEqual(available.displayState, "Available")

        let stale = SystemMetricAvailability.stale(metrics, age: 4)
        XCTAssertFalse(stale.isAvailable)
        XCTAssertTrue(stale.isStale)
        XCTAssertNil(stale.unavailableReason)
        XCTAssertEqual(stale.displayState, "Stale")

        let unavailable = SystemMetricAvailability<CPUMetrics>.unavailable(reason: "CPU unavailable")
        XCTAssertFalse(unavailable.isAvailable)
        XCTAssertFalse(unavailable.isStale)
        XCTAssertEqual(unavailable.unavailableReason, "CPU unavailable")
        XCTAssertEqual(unavailable.displayState, "CPU unavailable")
    }

    func testGracefulCopyStringsAreStable() {
        let battery = SystemMetricAvailability<BatteryMetrics>.unavailable(reason: "Battery unavailable")
        let thermal = SystemMetricAvailability<ThermalMetrics>.unavailable(reason: "Thermal unavailable")
        let network = NetworkMetrics(
            receivedBytesPerSecond: 0,
            sentBytesPerSecond: 0,
            stateText: "Network idle"
        )
        let topProcesses = SystemMetricAvailability<[TopProcessMetrics]>.unavailable(reason: "No process data")

        XCTAssertEqual(battery.displayState, "Battery unavailable")
        XCTAssertEqual(thermal.displayState, "Thermal unavailable")
        XCTAssertEqual(network.stateText, "Network idle")
        XCTAssertEqual(topProcesses.displayState, "No process data")
    }

    func testSnapshotCarriesAllMetricFields() {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let snapshot = SystemMetricsSnapshot(
            timestamp: date,
            cpu: .available(
                CPUMetrics(
                    usagePercent: 20,
                    userPercent: 12,
                    systemPercent: 8,
                    idlePercent: 80
                )
            ),
            memory: .available(
                MemoryMetrics(
                    totalBytes: 16_000,
                    usedBytes: 9_000,
                    freeBytes: 7_000,
                    usagePercent: 56.25,
                    pressureDescription: "Normal"
                )
            ),
            disk: .available(
                DiskMetrics(
                    volumeName: "Macintosh HD",
                    totalBytes: 100_000,
                    availableBytes: 30_000,
                    importantAvailableBytes: 28_000,
                    usagePercent: 70
                )
            ),
            network: .available(
                NetworkMetrics(
                    receivedBytesPerSecond: 128,
                    sentBytesPerSecond: 64,
                    stateText: "128 B/s down"
                )
            ),
            battery: .unavailable(reason: "Battery unavailable"),
            thermal: .unavailable(reason: "Thermal unavailable"),
            topProcesses: .available([
                TopProcessMetrics(
                    pid: 42,
                    name: "gridOS",
                    cpuPercent: 4.5,
                    residentMemoryBytes: 256_000
                )
            ]),
            samplingState: SamplingState(
                lastUpdated: date,
                isStale: false,
                nextRefreshAfter: 1,
                cadence: 1
            )
        )

        XCTAssertEqual(snapshot.timestamp, date)
        XCTAssertEqual(snapshot.cpu.value?.usagePercent, 20)
        XCTAssertEqual(snapshot.memory.value?.pressureDescription, "Normal")
        XCTAssertEqual(snapshot.disk.value?.volumeName, "Macintosh HD")
        XCTAssertEqual(snapshot.network.value?.sentBytesPerSecond, 64)
        XCTAssertEqual(snapshot.battery.displayState, "Battery unavailable")
        XCTAssertEqual(snapshot.thermal.displayState, "Thermal unavailable")
        XCTAssertEqual(snapshot.topProcesses.value?.first?.name, "gridOS")
        XCTAssertEqual(snapshot.samplingState.nextRefreshAfter, 1)
    }
}
