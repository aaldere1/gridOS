import Foundation

public struct SystemMetricsSnapshot: Equatable, Sendable {
    public let timestamp: Date
    public let cpu: SystemMetricAvailability<CPUMetrics>
    public let memory: SystemMetricAvailability<MemoryMetrics>
    public let disk: SystemMetricAvailability<DiskMetrics>
    public let network: SystemMetricAvailability<NetworkMetrics>
    public let battery: SystemMetricAvailability<BatteryMetrics>
    public let thermal: SystemMetricAvailability<ThermalMetrics>
    public let topProcesses: SystemMetricAvailability<[TopProcessMetrics]>
    public let samplingState: SamplingState

    public init(
        timestamp: Date,
        cpu: SystemMetricAvailability<CPUMetrics>,
        memory: SystemMetricAvailability<MemoryMetrics>,
        disk: SystemMetricAvailability<DiskMetrics>,
        network: SystemMetricAvailability<NetworkMetrics>,
        battery: SystemMetricAvailability<BatteryMetrics>,
        thermal: SystemMetricAvailability<ThermalMetrics>,
        topProcesses: SystemMetricAvailability<[TopProcessMetrics]>,
        samplingState: SamplingState
    ) {
        self.timestamp = timestamp
        self.cpu = cpu
        self.memory = memory
        self.disk = disk
        self.network = network
        self.battery = battery
        self.thermal = thermal
        self.topProcesses = topProcesses
        self.samplingState = samplingState
    }
}

public struct CPUMetrics: Equatable, Sendable {
    public let usagePercent: Double
    public let userPercent: Double
    public let systemPercent: Double
    public let idlePercent: Double
    public let nicePercent: Double

    public init(
        usagePercent: Double,
        userPercent: Double,
        systemPercent: Double,
        idlePercent: Double,
        nicePercent: Double = 0
    ) {
        self.usagePercent = usagePercent
        self.userPercent = userPercent
        self.systemPercent = systemPercent
        self.idlePercent = idlePercent
        self.nicePercent = nicePercent
    }
}

public struct MemoryMetrics: Equatable, Sendable {
    public let totalBytes: UInt64
    public let usedBytes: UInt64
    public let freeBytes: UInt64
    public let usagePercent: Double
    public let pressureDescription: String

    public init(
        totalBytes: UInt64,
        usedBytes: UInt64,
        freeBytes: UInt64,
        usagePercent: Double,
        pressureDescription: String
    ) {
        self.totalBytes = totalBytes
        self.usedBytes = usedBytes
        self.freeBytes = freeBytes
        self.usagePercent = usagePercent
        self.pressureDescription = pressureDescription
    }
}

public struct DiskMetrics: Equatable, Sendable {
    public let volumeName: String
    public let totalBytes: UInt64
    public let availableBytes: UInt64
    public let importantAvailableBytes: UInt64
    public let usagePercent: Double

    public init(
        volumeName: String,
        totalBytes: UInt64,
        availableBytes: UInt64,
        importantAvailableBytes: UInt64,
        usagePercent: Double
    ) {
        self.volumeName = volumeName
        self.totalBytes = totalBytes
        self.availableBytes = availableBytes
        self.importantAvailableBytes = importantAvailableBytes
        self.usagePercent = usagePercent
    }
}

public struct NetworkMetrics: Equatable, Sendable {
    public let receivedBytesPerSecond: Double
    public let sentBytesPerSecond: Double
    public let stateText: String

    public init(
        receivedBytesPerSecond: Double,
        sentBytesPerSecond: Double,
        stateText: String
    ) {
        self.receivedBytesPerSecond = receivedBytesPerSecond
        self.sentBytesPerSecond = sentBytesPerSecond
        self.stateText = stateText
    }
}

public struct BatteryMetrics: Equatable, Sendable {
    public let levelPercent: Double?
    public let isCharging: Bool
    public let powerSourceDescription: String
    public let stateText: String

    public init(
        levelPercent: Double?,
        isCharging: Bool,
        powerSourceDescription: String,
        stateText: String
    ) {
        self.levelPercent = levelPercent
        self.isCharging = isCharging
        self.powerSourceDescription = powerSourceDescription
        self.stateText = stateText
    }
}

public struct ThermalMetrics: Equatable, Sendable {
    public let state: String
    public let stateText: String

    public init(state: String, stateText: String) {
        self.state = state
        self.stateText = stateText
    }
}

public struct TopProcessMetrics: Equatable, Sendable, Identifiable {
    public let pid: Int32
    public let name: String
    public let cpuPercent: Double
    public let residentMemoryBytes: UInt64

    public var id: Int32 { pid }

    public init(
        pid: Int32,
        name: String,
        cpuPercent: Double,
        residentMemoryBytes: UInt64
    ) {
        self.pid = pid
        self.name = name
        self.cpuPercent = cpuPercent
        self.residentMemoryBytes = residentMemoryBytes
    }
}

public struct SamplingState: Equatable, Sendable {
    public let lastUpdated: Date
    public let isStale: Bool
    public let nextRefreshAfter: TimeInterval
    public let cadence: TimeInterval
    public let staleAge: TimeInterval?

    public init(
        lastUpdated: Date,
        isStale: Bool,
        nextRefreshAfter: TimeInterval,
        cadence: TimeInterval,
        staleAge: TimeInterval? = nil
    ) {
        self.lastUpdated = lastUpdated
        self.isStale = isStale
        self.nextRefreshAfter = nextRefreshAfter
        self.cadence = cadence
        self.staleAge = staleAge
    }
}
