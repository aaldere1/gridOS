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

    func testDefaultVisualIdentityUsesSignalFieldMode() {
        XCTAssertEqual(VisualIdentity.default.mode, .signalField)
        XCTAssertEqual(VisualIdentity.default.seed, .gridOSDefault)
    }

    func testMetalShaderSourceCompilesWhenDeviceIsAvailable() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("Metal device unavailable in this test environment.")
        }

        XCTAssertNoThrow(try device.makeLibrary(source: MetalBackgroundRenderer.shaderSource, options: nil))
    }
}
