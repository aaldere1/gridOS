import Foundation

public struct SystemMetricsSamplingPolicy: Equatable, Sendable {
    public let fastCadence: TimeInterval
    public let slowCadence: TimeInterval
    public let backgroundCadence: TimeInterval
    public let fastStaleThreshold: TimeInterval
    public let slowStaleThreshold: TimeInterval

    public static let defaultValue = SystemMetricsSamplingPolicy()

    public init(
        fastCadence: TimeInterval = 10.0,
        slowCadence: TimeInterval = 30.0,
        backgroundCadence: TimeInterval = 5.0,
        fastStaleThreshold: TimeInterval = 15.0,
        slowStaleThreshold: TimeInterval = 60.0
    ) {
        self.fastCadence = fastCadence
        self.slowCadence = slowCadence
        self.backgroundCadence = backgroundCadence
        self.fastStaleThreshold = fastStaleThreshold
        self.slowStaleThreshold = slowStaleThreshold
    }

    public func cadence(isActive: Bool, includesFastMetrics: Bool) -> TimeInterval {
        guard isActive else {
            return backgroundCadence
        }

        return includesFastMetrics ? fastCadence : slowCadence
    }

    public func staleThreshold(includesFastMetrics: Bool) -> TimeInterval {
        includesFastMetrics ? fastStaleThreshold : slowStaleThreshold
    }
}
