public enum VisualMode: String, CaseIterable, Equatable, Sendable {
    case signalField

    public var displayName: String {
        switch self {
        case .signalField:
            "Signal Field"
        }
    }

    var shaderValue: Float {
        switch self {
        case .signalField:
            0
        }
    }
}

public struct VisualIdentity: Equatable, Sendable {
    public static let `default` = VisualIdentity(
        mode: .signalField,
        seed: .gridOSDefault
    )

    public let mode: VisualMode
    public let seed: ProceduralSeed

    public init(mode: VisualMode, seed: ProceduralSeed) {
        self.mode = mode
        self.seed = seed
    }
}
