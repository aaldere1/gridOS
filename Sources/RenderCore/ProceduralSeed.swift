import Foundation
import simd

public struct ProceduralSeed: Equatable, Sendable {
    public static let gridOSDefault = ProceduralSeed(stableString: "gridOS-render-core-default")

    public let value: UInt64

    public init(_ value: UInt64) {
        self.value = value == 0 ? 0xcbf29ce484222325 : value
    }

    public init(stableString: String) {
        var hash: UInt64 = 0xcbf29ce484222325

        for byte in stableString.utf8 {
            hash ^= UInt64(byte)
            hash &*= 0x100000001b3
        }

        self.init(hash)
    }

    public var normalizedVector: SIMD2<Float> {
        let upper = UInt32((value >> 32) & 0xffff_ffff)
        let lower = UInt32(value & 0xffff_ffff)
        let divisor = Float(UInt32.max)

        return SIMD2<Float>(
            Float(upper) / divisor,
            Float(lower) / divisor
        )
    }
}
