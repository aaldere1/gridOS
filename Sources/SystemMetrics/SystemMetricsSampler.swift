import Foundation

public protocol SystemMetricsSampler: Sendable {
    func snapshot(isActive: Bool) async -> SystemMetricsSnapshot
}

public actor LiveSystemMetricsSampler: SystemMetricsSampler {
    private let provider: NativeSystemMetricsProvider
    private let policy: SystemMetricsSamplingPolicy
    private var previousCPU: CPUCounterSample?
    private var previousNetwork: NetworkCounterSample?
    private var previousTopProcesses: [Int32: TopProcessCounterSample]
    private var lastSnapshot: SystemMetricsSnapshot?
    private var lastSnapshotDate: Date?

    public init(
        provider: NativeSystemMetricsProvider = NativeSystemMetricsProvider(),
        policy: SystemMetricsSamplingPolicy = .defaultValue
    ) {
        self.provider = provider
        self.policy = policy
        self.previousTopProcesses = [:]
    }

    public func snapshot(isActive: Bool) async -> SystemMetricsSnapshot {
        let now = Date()
        let cadence = policy.cadence(isActive: isActive, includesFastMetrics: true)

        if let lastSnapshot, let lastSnapshotDate {
            let age = now.timeIntervalSince(lastSnapshotDate)
            if age < cadence {
                return markSnapshotStale(
                    lastSnapshot,
                    age: age,
                    nextRefreshAfter: max(0.2, cadence - age)
                )
            }
        }

        let elapsed = lastSnapshotDate.map { max(0.001, now.timeIntervalSince($0)) } ?? cadence
        let cpu = provider.readCPU(previous: previousCPU)
        let network = provider.readNetwork(previous: previousNetwork, elapsed: elapsed)
        let topProcesses = provider.readTopProcesses(
            previous: previousTopProcesses,
            elapsed: elapsed,
            limit: 6
        )

        previousCPU = cpu.sample ?? previousCPU
        previousNetwork = network.sample ?? previousNetwork
        previousTopProcesses = topProcesses.samples

        let snapshot = SystemMetricsSnapshot(
            timestamp: now,
            cpu: cpu.metrics,
            memory: provider.readMemory(),
            disk: provider.readDisk(),
            network: network.metrics,
            battery: provider.readBattery(),
            thermal: provider.readThermal(),
            topProcesses: topProcesses.metrics,
            samplingState: SamplingState(
                lastUpdated: now,
                isStale: false,
                nextRefreshAfter: cadence,
                cadence: cadence
            )
        )

        lastSnapshot = snapshot
        lastSnapshotDate = now

        return snapshot
    }

    private func markSnapshotStale(
        _ snapshot: SystemMetricsSnapshot,
        age: TimeInterval,
        nextRefreshAfter: TimeInterval
    ) -> SystemMetricsSnapshot {
        SystemMetricsSnapshot(
            timestamp: snapshot.timestamp,
            cpu: stale(snapshot.cpu, age: age),
            memory: stale(snapshot.memory, age: age),
            disk: stale(snapshot.disk, age: age),
            network: stale(snapshot.network, age: age),
            battery: stale(snapshot.battery, age: age),
            thermal: stale(snapshot.thermal, age: age),
            topProcesses: stale(snapshot.topProcesses, age: age),
            samplingState: SamplingState(
                lastUpdated: snapshot.samplingState.lastUpdated,
                isStale: true,
                nextRefreshAfter: nextRefreshAfter,
                cadence: snapshot.samplingState.cadence,
                staleAge: age
            )
        )
    }

    private func stale<Value: Equatable & Sendable>(
        _ availability: SystemMetricAvailability<Value>,
        age: TimeInterval
    ) -> SystemMetricAvailability<Value> {
        switch availability {
        case .available(let value), .stale(let value, _):
            return .stale(value, age: age)
        case .unavailable(let reason):
            return .unavailable(reason: reason)
        }
    }
}

public struct PreviewSystemMetricsSampler: SystemMetricsSampler {
    private let previewSnapshot: SystemMetricsSnapshot

    public init(snapshot: SystemMetricsSnapshot = SystemMetricsPreviewData.snapshot) {
        self.previewSnapshot = snapshot
    }

    public func snapshot(isActive: Bool) async -> SystemMetricsSnapshot {
        previewSnapshot
    }
}

public enum SystemMetricsPreviewData {
    public static let snapshot = SystemMetricsSnapshot(
        timestamp: Date(timeIntervalSince1970: 1_800_000_000),
        cpu: .available(
            CPUMetrics(
                usagePercent: 18,
                userPercent: 11,
                systemPercent: 7,
                idlePercent: 82
            )
        ),
        memory: .available(
            MemoryMetrics(
                totalBytes: 24_000_000_000,
                usedBytes: 10_200_000_000,
                freeBytes: 13_800_000_000,
                usagePercent: 42.5,
                pressureDescription: "Normal"
            )
        ),
        disk: .available(
            DiskMetrics(
                volumeName: "Macintosh HD",
                totalBytes: 1_000_000_000_000,
                availableBytes: 362_000_000_000,
                importantAvailableBytes: 348_000_000_000,
                usagePercent: 63.8
            )
        ),
        network: .available(
            NetworkMetrics(
                receivedBytesPerSecond: 0,
                sentBytesPerSecond: 0,
                stateText: "Network idle"
            )
        ),
        battery: .unavailable(reason: "Battery unavailable"),
        thermal: .unavailable(reason: "Thermal unavailable"),
        topProcesses: .available([
            TopProcessMetrics(
                pid: 101,
                name: "gridOS",
                cpuPercent: 4.4,
                residentMemoryBytes: 168_000_000
            ),
            TopProcessMetrics(
                pid: 202,
                name: "WindowServer",
                cpuPercent: 2.1,
                residentMemoryBytes: 512_000_000
            )
        ]),
        samplingState: SamplingState(
            lastUpdated: Date(timeIntervalSince1970: 1_800_000_000),
            isStale: false,
            nextRefreshAfter: 1,
            cadence: 1
        )
    )
}
