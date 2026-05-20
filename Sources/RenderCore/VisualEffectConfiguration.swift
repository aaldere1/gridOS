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
        pulseMagnitude(
            for: eventMagnitude,
            motionProfile: VisualMode.defaultMode.theme.motion
        )
    }

    public func pulseMagnitude(
        for eventMagnitude: Double,
        motionProfile: VisualMotionProfile
    ) -> Double {
        guard !reducedMotion else {
            return 0
        }

        return motionProfile.pulseMagnitude(
            for: eventMagnitude,
            intensity: intensity,
            reducedMotion: reducedMotion
        )
    }
}
