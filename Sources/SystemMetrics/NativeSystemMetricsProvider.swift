import Foundation
import Darwin
import IOKit.ps

public struct CPUCounterSample: Equatable, Sendable {
    public let user: UInt64
    public let system: UInt64
    public let idle: UInt64
    public let nice: UInt64

    public init(user: UInt64, system: UInt64, idle: UInt64, nice: UInt64) {
        self.user = user
        self.system = system
        self.idle = idle
        self.nice = nice
    }
}

public struct CPUReading: Equatable, Sendable {
    public let metrics: SystemMetricAvailability<CPUMetrics>
    public let sample: CPUCounterSample?

    public init(metrics: SystemMetricAvailability<CPUMetrics>, sample: CPUCounterSample?) {
        self.metrics = metrics
        self.sample = sample
    }
}

public struct NetworkCounterSample: Equatable, Sendable {
    public let receivedBytes: UInt64
    public let sentBytes: UInt64

    public init(receivedBytes: UInt64, sentBytes: UInt64) {
        self.receivedBytes = receivedBytes
        self.sentBytes = sentBytes
    }
}

public struct NetworkReading: Equatable, Sendable {
    public let metrics: SystemMetricAvailability<NetworkMetrics>
    public let sample: NetworkCounterSample?

    public init(metrics: SystemMetricAvailability<NetworkMetrics>, sample: NetworkCounterSample?) {
        self.metrics = metrics
        self.sample = sample
    }
}

public struct TopProcessCounterSample: Equatable, Sendable {
    public let pid: Int32
    public let totalTime: UInt64

    public init(pid: Int32, totalTime: UInt64) {
        self.pid = pid
        self.totalTime = totalTime
    }
}

public struct TopProcessesReading: Equatable, Sendable {
    public let metrics: SystemMetricAvailability<[TopProcessMetrics]>
    public let samples: [Int32: TopProcessCounterSample]

    public init(
        metrics: SystemMetricAvailability<[TopProcessMetrics]>,
        samples: [Int32: TopProcessCounterSample]
    ) {
        self.metrics = metrics
        self.samples = samples
    }
}

public struct NativeSystemMetricsProvider: Sendable {
    public init() {}

    public func readCPU(previous: CPUCounterSample?) -> CPUReading {
        var processorCount: natural_t = 0
        var cpuInfoCount: mach_msg_type_number_t = 0
        var cpuInfo: processor_info_array_t?
        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &processorCount,
            &cpuInfo,
            &cpuInfoCount
        )

        guard result == KERN_SUCCESS, let cpuInfo, processorCount > 0 else {
            return CPUReading(metrics: .unavailable(reason: "CPU unavailable"), sample: nil)
        }

        defer {
            let byteCount = vm_size_t(Int(cpuInfoCount) * MemoryLayout<integer_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: cpuInfo)), byteCount)
        }

        var user: UInt64 = 0
        var system: UInt64 = 0
        var idle: UInt64 = 0
        var nice: UInt64 = 0
        let stateCount = Int(CPU_STATE_MAX)

        for index in 0..<Int(processorCount) {
            let offset = index * stateCount
            user += UInt64(max(0, cpuInfo[offset + Int(CPU_STATE_USER)]))
            system += UInt64(max(0, cpuInfo[offset + Int(CPU_STATE_SYSTEM)]))
            idle += UInt64(max(0, cpuInfo[offset + Int(CPU_STATE_IDLE)]))
            nice += UInt64(max(0, cpuInfo[offset + Int(CPU_STATE_NICE)]))
        }

        let sample = CPUCounterSample(user: user, system: system, idle: idle, nice: nice)
        let metrics: CPUMetrics

        if let previous {
            metrics = CPUMetrics.percent(
                user: tickDelta(current: sample.user, previous: previous.user),
                system: tickDelta(current: sample.system, previous: previous.system),
                idle: tickDelta(current: sample.idle, previous: previous.idle),
                nice: tickDelta(current: sample.nice, previous: previous.nice)
            )
        } else {
            metrics = CPUMetrics.percent(user: 0, system: 0, idle: 1, nice: 0)
        }

        return CPUReading(metrics: .available(metrics), sample: sample)
    }

    public func readMemory() -> SystemMetricAvailability<MemoryMetrics> {
        var pageSize: vm_size_t = 0
        guard host_page_size(mach_host_self(), &pageSize) == KERN_SUCCESS else {
            return .unavailable(reason: "Memory unavailable")
        }

        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPointer in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, reboundPointer, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return .unavailable(reason: "Memory unavailable")
        }

        let pageBytes = UInt64(pageSize)
        let activeBytes = UInt64(stats.active_count) * pageBytes
        let inactiveBytes = UInt64(stats.inactive_count) * pageBytes
        let wiredBytes = UInt64(stats.wire_count) * pageBytes
        let compressedBytes = UInt64(stats.compressor_page_count) * pageBytes
        let usedBytes = activeBytes + inactiveBytes + wiredBytes + compressedBytes
        let totalBytes = ProcessInfo.processInfo.physicalMemory
        let clampedUsedBytes = min(totalBytes, usedBytes)
        let freeBytes = totalBytes > clampedUsedBytes ? totalBytes - clampedUsedBytes : 0
        let usagePercent = totalBytes > 0 ? (Double(clampedUsedBytes) / Double(totalBytes)) * 100 : 0

        return .available(
            MemoryMetrics(
                totalBytes: totalBytes,
                usedBytes: clampedUsedBytes,
                freeBytes: freeBytes,
                usagePercent: min(100, max(0, usagePercent)),
                pressureDescription: "Normal"
            )
        )
    }

    public func readDisk(url: URL = URL(fileURLWithPath: "/")) -> SystemMetricAvailability<DiskMetrics> {
        do {
            let keys: Set<URLResourceKey> = [
                .volumeNameKey,
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityKey,
                .volumeAvailableCapacityForImportantUsageKey
            ]
            let values = try url.resourceValues(forKeys: keys)

            guard let totalCapacity = values.volumeTotalCapacity, totalCapacity > 0 else {
                return .unavailable(reason: "Disk unavailable")
            }

            let totalBytes = UInt64(totalCapacity)
            let availableBytes = UInt64(max(0, values.volumeAvailableCapacity ?? 0))
            let importantAvailable = values.volumeAvailableCapacityForImportantUsage ?? Int64(availableBytes)
            let importantAvailableBytes = UInt64(max(0, importantAvailable))
            let usedBytes = totalBytes > availableBytes ? totalBytes - availableBytes : 0
            let usagePercent = (Double(usedBytes) / Double(totalBytes)) * 100

            return .available(
                DiskMetrics(
                    volumeName: values.volumeName ?? url.path,
                    totalBytes: totalBytes,
                    availableBytes: availableBytes,
                    importantAvailableBytes: importantAvailableBytes,
                    usagePercent: min(100, max(0, usagePercent))
                )
            )
        } catch {
            return .unavailable(reason: "Disk unavailable")
        }
    }

    public func readNetwork(previous: NetworkCounterSample?, elapsed: TimeInterval) -> NetworkReading {
        var interfaces: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&interfaces) == 0, let firstInterface = interfaces else {
            return NetworkReading(metrics: .unavailable(reason: "Network unavailable"), sample: nil)
        }

        defer {
            freeifaddrs(interfaces)
        }

        var receivedBytes: UInt64 = 0
        var sentBytes: UInt64 = 0
        var interfacePointer: UnsafeMutablePointer<ifaddrs>? = firstInterface

        while let currentInterface = interfacePointer {
            let interface = currentInterface.pointee
            if isEligibleNetworkInterface(interface),
               let data = interface.ifa_data?.assumingMemoryBound(to: if_data.self) {
                receivedBytes += UInt64(data.pointee.ifi_ibytes)
                sentBytes += UInt64(data.pointee.ifi_obytes)
            }

            interfacePointer = interface.ifa_next
        }

        let sample = NetworkCounterSample(receivedBytes: receivedBytes, sentBytes: sentBytes)
        let receivedPerSecond = NetworkMetrics.throughput(
            previousBytes: previous?.receivedBytes ?? receivedBytes,
            currentBytes: receivedBytes,
            elapsed: elapsed
        )
        let sentPerSecond = NetworkMetrics.throughput(
            previousBytes: previous?.sentBytes ?? sentBytes,
            currentBytes: sentBytes,
            elapsed: elapsed
        )
        let stateText = receivedPerSecond + sentPerSecond > 0 ? "Network active" : "Network idle"

        return NetworkReading(
            metrics: .available(
                NetworkMetrics(
                    receivedBytesPerSecond: receivedPerSecond,
                    sentBytesPerSecond: sentPerSecond,
                    stateText: stateText
                )
            ),
            sample: sample
        )
    }

    public func readBattery() -> SystemMetricAvailability<BatteryMetrics> {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let powerSources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef],
              !powerSources.isEmpty else {
            return .unavailable(reason: "Battery unavailable")
        }

        for powerSource in powerSources {
            guard let description = IOPSGetPowerSourceDescription(info, powerSource)?
                .takeUnretainedValue() as? [String: Any],
                let currentCapacity = description[kIOPSCurrentCapacityKey as String] as? Int,
                let maximumCapacity = description[kIOPSMaxCapacityKey as String] as? Int,
                maximumCapacity > 0 else {
                continue
            }

            let percent = (Double(currentCapacity) / Double(maximumCapacity)) * 100
            let isCharging = description[kIOPSIsChargingKey as String] as? Bool ?? false
            let powerSourceState = description[kIOPSPowerSourceStateKey as String] as? String ?? "Power"
            let stateText = isCharging ? "Charging" : powerSourceState

            return .available(
                BatteryMetrics(
                    levelPercent: min(100, max(0, percent)),
                    isCharging: isCharging,
                    powerSourceDescription: powerSourceState,
                    stateText: stateText
                )
            )
        }

        return .unavailable(reason: "Battery unavailable")
    }

    public func readThermal() -> SystemMetricAvailability<ThermalMetrics> {
        let thermalState = ProcessInfo.processInfo.thermalState

        switch thermalState {
        case .nominal:
            return .available(ThermalMetrics(state: "nominal", stateText: "Nominal"))
        case .fair:
            return .available(ThermalMetrics(state: "fair", stateText: "Fair"))
        case .serious:
            return .available(ThermalMetrics(state: "serious", stateText: "Serious"))
        case .critical:
            return .available(ThermalMetrics(state: "critical", stateText: "Critical"))
        @unknown default:
            return .unavailable(reason: "Thermal unavailable")
        }
    }

    public func readTopProcesses(
        previous: [Int32: TopProcessCounterSample],
        elapsed: TimeInterval,
        limit: Int
    ) -> TopProcessesReading {
        let byteCount = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
        guard byteCount > 0 else {
            return TopProcessesReading(metrics: .unavailable(reason: "No process data"), samples: [:])
        }

        let capacity = Int(byteCount) / MemoryLayout<pid_t>.stride
        var pids = [pid_t](repeating: 0, count: capacity)
        let actualByteCount = pids.withUnsafeMutableBufferPointer { buffer in
            proc_listpids(UInt32(PROC_ALL_PIDS), 0, buffer.baseAddress, byteCount)
        }
        let actualCount = max(0, Int(actualByteCount) / MemoryLayout<pid_t>.stride)
        let processorCount = ProcessInfo.processInfo.processorCount
        var samples: [Int32: TopProcessCounterSample] = [:]
        var metrics: [TopProcessMetrics] = []

        for pid in pids.prefix(actualCount) where pid > 0 {
            guard let process = processMetrics(
                pid: pid,
                previous: previous[pid],
                elapsed: elapsed,
                processorCount: processorCount
            ) else {
                continue
            }

            samples[pid] = TopProcessCounterSample(pid: pid, totalTime: process.totalTime)
            metrics.append(process.metrics)
        }

        return Self.boundedTopProcessReading(metrics: metrics, samples: samples, limit: limit)
    }

    static func boundedTopProcessReading(
        metrics: [TopProcessMetrics],
        samples: [Int32: TopProcessCounterSample],
        limit: Int
    ) -> TopProcessesReading {
        let visibleLimit = max(0, limit)
        let sortedMetrics = metrics.sorted { lhs, rhs in
            if lhs.cpuPercent == rhs.cpuPercent {
                return lhs.residentMemoryBytes > rhs.residentMemoryBytes
            }

            return lhs.cpuPercent > rhs.cpuPercent
        }
        let topProcesses = Array(sortedMetrics.prefix(visibleLimit))
        let retainedSampleLimit = max(visibleLimit * 8, visibleLimit)
        let retainedPIDs = Set(sortedMetrics.prefix(retainedSampleLimit).map(\.pid))
        let boundedSamples = samples.filter { retainedPIDs.contains($0.key) }

        guard !topProcesses.isEmpty else {
            return TopProcessesReading(metrics: .unavailable(reason: "No process data"), samples: boundedSamples)
        }

        return TopProcessesReading(metrics: .available(topProcesses), samples: boundedSamples)
    }

    private func processMetrics(
        pid: pid_t,
        previous: TopProcessCounterSample?,
        elapsed: TimeInterval,
        processorCount: Int
    ) -> (metrics: TopProcessMetrics, totalTime: UInt64)? {
        var taskInfo = proc_taskinfo()
        let taskInfoSize = MemoryLayout<proc_taskinfo>.stride
        let result = withUnsafeMutablePointer(to: &taskInfo) { pointer in
            pointer.withMemoryRebound(to: UInt8.self, capacity: taskInfoSize) { reboundPointer in
                proc_pidinfo(pid, PROC_PIDTASKINFO, 0, reboundPointer, Int32(taskInfoSize))
            }
        }

        guard result == Int32(taskInfoSize) else {
            return nil
        }

        var nameBuffer = [CChar](repeating: 0, count: 1_024)
        let nameLength = nameBuffer.withUnsafeMutableBufferPointer { buffer in
            proc_name(pid, buffer.baseAddress, UInt32(buffer.count))
        }
        let name: String
        if nameLength > 0 {
            let nameBytes = nameBuffer.prefix(Int(nameLength)).map { UInt8(bitPattern: $0) }
            name = String(decoding: nameBytes, as: UTF8.self)
        } else {
            name = "pid \(pid)"
        }
        let totalTime = UInt64(taskInfo.pti_total_user) + UInt64(taskInfo.pti_total_system)
        let cpuPercent = TopProcessMetrics.cpuPercent(
            previousTotalTime: previous?.totalTime ?? totalTime,
            currentTotalTime: totalTime,
            elapsed: elapsed,
            processorCount: processorCount
        )

        return (
            metrics: TopProcessMetrics(
                pid: pid,
                name: name,
                cpuPercent: cpuPercent,
                residentMemoryBytes: UInt64(taskInfo.pti_resident_size)
            ),
            totalTime: totalTime
        )
    }

    private func isEligibleNetworkInterface(_ interface: ifaddrs) -> Bool {
        guard let address = interface.ifa_addr,
              address.pointee.sa_family == UInt8(AF_LINK) else {
            return false
        }

        let flags = interface.ifa_flags
        return flags & UInt32(IFF_UP) != 0 && flags & UInt32(IFF_LOOPBACK) == 0
    }

    private func tickDelta(current: UInt64, previous: UInt64) -> Int64 {
        guard current >= previous else {
            return -1
        }

        return Int64(min(UInt64(Int64.max), current - previous))
    }
}
