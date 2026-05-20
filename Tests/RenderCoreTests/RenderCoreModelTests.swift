import Metal
import XCTest
@testable import RenderCore

final class RenderCoreModelTests: XCTestCase {
    func testProceduralSeedIsDeterministicForStableString() {
        let first = ProceduralSeed(stableString: "install-a")
        let second = ProceduralSeed(stableString: "install-a")
        let different = ProceduralSeed(stableString: "install-b")

        XCTAssertEqual(first, second)
        XCTAssertNotEqual(first, different)
    }

    func testProceduralSeedNormalizesIntoUnitVector() {
        let vector = ProceduralSeed(stableString: "gridOS").normalizedVector

        XCTAssertGreaterThanOrEqual(vector.x, 0)
        XCTAssertLessThanOrEqual(vector.x, 1)
        XCTAssertGreaterThanOrEqual(vector.y, 0)
        XCTAssertLessThanOrEqual(vector.y, 1)
    }

    func testRenderEventClampsMagnitude() {
        XCTAssertEqual(RenderEvent.clampedMagnitude(-1), 0)
        XCTAssertEqual(RenderEvent.clampedMagnitude(0.42), 0.42)
        XCTAssertEqual(RenderEvent.clampedMagnitude(4), 1)

        let event = RenderEvent(sequence: 1, kind: .terminalOutput, magnitude: 8)
        XCTAssertEqual(event.magnitude, 1)
    }

    func testVisualEffectConfigurationClampsIntensity() {
        XCTAssertEqual(VisualEffectConfiguration(intensity: -1).intensity, 0)
        XCTAssertEqual(VisualEffectConfiguration(intensity: 0.4).intensity, 0.4)
        XCTAssertEqual(VisualEffectConfiguration(intensity: 2).intensity, 1)
    }

    func testReducedMotionSuppressesPulseMagnitude() {
        let animated = VisualEffectConfiguration(intensity: 0.5, reducedMotion: false)
        let reduced = VisualEffectConfiguration(intensity: 0.5, reducedMotion: true)

        XCTAssertEqual(animated.pulseMagnitude(for: 0.8), 0.4)
        XCTAssertEqual(reduced.pulseMagnitude(for: 0.8), 0)
    }

    func testVisualModesExposePhaseFiveCases() {
        XCTAssertEqual(VisualMode.allCases, [.tron, .severance, .appleNative])
        XCTAssertEqual(VisualMode.allCases.map(\.rawValue), ["tron", "severance", "appleNative"])
        XCTAssertEqual(VisualMode.allCases.map(\.displayName), ["Tron", "Severance", "Apple-native"])
        XCTAssertEqual(VisualMode.allCases.map(\.shaderValue), [0, 1, 2])
    }

    func testDefaultVisualIdentityUsesTronMode() {
        XCTAssertEqual(VisualMode.defaultMode, .tron)
        XCTAssertEqual(VisualIdentity.default.mode, .tron)
        XCTAssertEqual(VisualIdentity.default.seed, .gridOSDefault)
    }

    func testVisualModeCyclesInPhaseFiveOrder() {
        XCTAssertEqual(VisualMode.tron.next, .severance)
        XCTAssertEqual(VisualMode.severance.next, .appleNative)
        XCTAssertEqual(VisualMode.appleNative.next, .tron)
    }

    func testVisualThemesCarryDistinctTokenBundles() {
        XCTAssertEqual(
            VisualMode.tron.theme.palette.background,
            VisualColor(red: 0.004, green: 0.007, blue: 0.011, alpha: 1)
        )
        XCTAssertEqual(
            VisualMode.tron.theme.palette.primaryAccent,
            VisualColor(red: 0.10, green: 0.72, blue: 0.78, alpha: 1)
        )
        XCTAssertEqual(
            VisualMode.tron.theme.palette.secondaryAccent,
            VisualColor(red: 0.12, green: 0.24, blue: 0.46, alpha: 1)
        )
        XCTAssertEqual(
            VisualMode.tron.theme.palette.statusAccent,
            VisualColor(red: 0.95, green: 0.52, blue: 0.20, alpha: 1)
        )
        XCTAssertEqual(
            VisualMode.tron.theme.motion,
            VisualMotionProfile(
                idleDriftRate: 0.18,
                eventGain: 1.00,
                pulseDecay: 0.42,
                maxPulseDuration: 1.40,
                detailDensity: 0.92
            )
        )

        XCTAssertEqual(
            VisualMode.severance.theme.palette.background,
            VisualColor(red: 0.010, green: 0.011, blue: 0.010, alpha: 1)
        )
        XCTAssertEqual(
            VisualMode.severance.theme.palette.primaryAccent,
            VisualColor(red: 0.78, green: 0.84, blue: 0.76, alpha: 1)
        )
        XCTAssertEqual(
            VisualMode.severance.theme.palette.secondaryAccent,
            VisualColor(red: 0.30, green: 0.34, blue: 0.30, alpha: 1)
        )
        XCTAssertEqual(
            VisualMode.severance.theme.palette.statusAccent,
            VisualColor(red: 0.62, green: 0.68, blue: 0.56, alpha: 1)
        )
        XCTAssertEqual(
            VisualMode.severance.theme.motion,
            VisualMotionProfile(
                idleDriftRate: 0.025,
                eventGain: 0.22,
                pulseDecay: 0.88,
                maxPulseDuration: 0.45,
                detailDensity: 0.28
            )
        )

        XCTAssertEqual(
            VisualMode.appleNative.theme.palette.background,
            VisualColor(red: 0.015, green: 0.017, blue: 0.020, alpha: 1)
        )
        XCTAssertEqual(
            VisualMode.appleNative.theme.palette.primaryAccent,
            VisualColor(red: 0.38, green: 0.68, blue: 1.00, alpha: 1)
        )
        XCTAssertEqual(
            VisualMode.appleNative.theme.palette.secondaryAccent,
            VisualColor(red: 0.26, green: 0.32, blue: 0.42, alpha: 1)
        )
        XCTAssertEqual(
            VisualMode.appleNative.theme.palette.statusAccent,
            VisualColor(red: 0.97, green: 0.73, blue: 0.30, alpha: 1)
        )
        XCTAssertEqual(
            VisualMode.appleNative.theme.motion,
            VisualMotionProfile(
                idleDriftRate: 0.06,
                eventGain: 0.38,
                pulseDecay: 0.62,
                maxPulseDuration: 0.75,
                detailDensity: 0.48
            )
        )

        XCTAssertNotEqual(VisualMode.tron.theme.signature, VisualMode.severance.theme.signature)
        XCTAssertNotEqual(VisualMode.tron.theme.signature, VisualMode.appleNative.theme.signature)
        XCTAssertNotEqual(VisualMode.severance.theme.signature, VisualMode.appleNative.theme.signature)

        XCTAssertNotEqual(VisualMode.tron.theme.motion, VisualMode.severance.theme.motion)
        XCTAssertNotEqual(VisualMode.tron.theme.motion, VisualMode.appleNative.theme.motion)
        XCTAssertNotEqual(VisualMode.severance.theme.motion, VisualMode.appleNative.theme.motion)
    }

    func testInstallDerivedSeedIsStableAndModeSpecific() {
        let first = ProceduralSeed.installDerived(installSeed: "install-a", mode: .tron)
        let second = ProceduralSeed.installDerived(installSeed: "install-a", mode: .tron)
        let differentMode = ProceduralSeed.installDerived(installSeed: "install-a", mode: .severance)

        XCTAssertEqual(first, second)
        XCTAssertNotEqual(first, differentMode)
    }

    func testInstallDerivedSeedIsInstallSpecificWithinSameMode() {
        let first = ProceduralSeed.installDerived(installSeed: "install-a", mode: .appleNative)
        let second = ProceduralSeed.installDerived(installSeed: "install-b", mode: .appleNative)

        XCTAssertNotEqual(first, second)
    }

    func testVisualIdentityCanDeriveInstallSpecificSeeds() {
        let identity = VisualIdentity(mode: .severance, installSeed: "alpha")

        XCTAssertEqual(identity.mode, .severance)
        XCTAssertEqual(identity.seed, .installDerived(installSeed: "alpha", mode: .severance))
    }

    func testReducedMotionSuppressesPulseMagnitudeForEveryMode() {
        for mode in VisualMode.allCases {
            XCTAssertEqual(
                mode.theme.motion.pulseMagnitude(for: 1, intensity: 1, reducedMotion: true),
                0
            )
        }
    }

    func testMetalShaderSourceCompilesWhenDeviceIsAvailable() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("Metal device unavailable in this test environment.")
        }

        XCTAssertNoThrow(try device.makeLibrary(source: MetalBackgroundRenderer.shaderSource, options: nil))
    }
}
