import Foundation

public enum RenderEventKind: String, Equatable, Sendable {
    case startup
    case terminalInput
    case terminalOutput
    case terminalResize
    case processLifecycle
}

public struct RenderEvent: Equatable, Sendable {
    public let sequence: UInt64
    public let kind: RenderEventKind
    public let magnitude: Double
    public let timestamp: TimeInterval

    public init(
        sequence: UInt64,
        kind: RenderEventKind,
        magnitude: Double,
        timestamp: TimeInterval = Date().timeIntervalSince1970
    ) {
        self.sequence = sequence
        self.kind = kind
        self.magnitude = Self.clampedMagnitude(magnitude)
        self.timestamp = timestamp
    }

    public static func clampedMagnitude(_ magnitude: Double) -> Double {
        min(1, max(0, magnitude))
    }
}
