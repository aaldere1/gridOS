import Foundation

public enum SystemMetricAvailability<Value: Equatable & Sendable>: Equatable, Sendable {
    case available(Value)
    case stale(Value, age: TimeInterval)
    case unavailable(reason: String)

    public var isAvailable: Bool {
        if case .available = self {
            return true
        }

        return false
    }

    public var isStale: Bool {
        if case .stale = self {
            return true
        }

        return false
    }

    public var unavailableReason: String? {
        if case .unavailable(let reason) = self {
            return reason
        }

        return nil
    }

    public var displayState: String {
        switch self {
        case .available:
            return "Available"
        case .stale:
            return "Stale"
        case .unavailable(let reason):
            return reason
        }
    }

    public var value: Value? {
        switch self {
        case .available(let value), .stale(let value, _):
            return value
        case .unavailable:
            return nil
        }
    }
}
