import Foundation

public enum VisualMode: String, CaseIterable, Equatable, Sendable, Identifiable {
    case tron
    case matrix
    case amberCRT
    case redline
    case severance
    case appleNative

    public static let defaultMode: VisualMode = .tron

    public var id: String {
        rawValue
    }

    public var displayName: String {
        switch self {
        case .tron:
            "Tron"
        case .matrix:
            "Matrix"
        case .amberCRT:
            "Amber CRT"
        case .redline:
            "Redline"
        case .severance:
            "Severance"
        case .appleNative:
            "Apple-native"
        }
    }

    public var next: VisualMode {
        switch self {
        case .tron:
            .matrix
        case .matrix:
            .amberCRT
        case .amberCRT:
            .redline
        case .redline:
            .severance
        case .severance:
            .appleNative
        case .appleNative:
            .tron
        }
    }

    public var shaderValue: Float {
        switch self {
        case .tron:
            0
        case .matrix:
            3
        case .amberCRT:
            4
        case .redline:
            5
        case .severance:
            1
        case .appleNative:
            2
        }
    }

    public var theme: VisualTheme {
        switch self {
        case .tron:
            .tron
        case .matrix:
            .matrix
        case .amberCRT:
            .amberCRT
        case .redline:
            .redline
        case .severance:
            .severance
        case .appleNative:
            .appleNative
        }
    }
}

public struct VisualIdentity: Equatable, Sendable {
    public static let `default` = VisualIdentity(
        mode: .tron,
        seed: .gridOSDefault
    )

    public let mode: VisualMode
    public let seed: ProceduralSeed

    public init(mode: VisualMode, seed: ProceduralSeed) {
        self.mode = mode
        self.seed = seed
    }

    public init(mode: VisualMode = .defaultMode, installSeed: String) {
        self.init(
            mode: mode,
            seed: .installDerived(installSeed: installSeed, mode: mode)
        )
    }

    public var displaySignature: String {
        let high = UInt16((seed.value >> 48) & 0xffff)
        let low = UInt16((seed.value >> 32) & 0xffff)
        return String(format: "%04X-%04X", high, low)
    }
}
