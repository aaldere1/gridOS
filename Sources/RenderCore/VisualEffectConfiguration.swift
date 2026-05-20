import Foundation

public struct VisualEffectConfiguration: Equatable, Sendable {
    public static let defaultValue = VisualEffectConfiguration()

    public let intensity: Double
    public let reducedMotion: Bool

    public init(intensity: Double = 0.65, reducedMotion: Bool = false) {
        self.intensity = min(1, max(0, intensity))
        self.reducedMotion = reducedMotion
    }

    public func pulseMagnitude(for eventMagnitude: Double) -> Double {
        guard !reducedMotion else {
            return 0
        }

        let clampedEventMagnitude = min(1, max(0, eventMagnitude))
        return intensity * clampedEventMagnitude
    }
}
