import XCTest
@testable import GridOSKit

final class GridOSAppPreferencesTests: XCTestCase {
    func testDefaultValueUsesProductionDefaults() {
        XCTAssertEqual(GridOSAppPreferences.defaultValue.shellPath, "/bin/zsh")
        XCTAssertEqual(GridOSAppPreferences.defaultValue.terminalFontSize, 13.0)
        XCTAssertEqual(GridOSAppPreferences.defaultValue.visualIntensity, 0.65)
        XCTAssertFalse(GridOSAppPreferences.defaultValue.reducedMotion)
    }

    func testEmptyShellPathFallsBackToDefaultShell() {
        let preferences = GridOSAppPreferences(shellPath: "   ")

        XCTAssertEqual(preferences.shellPath, GridOSAppPreferences.defaultShellPath)
    }

    func testFontSizeIsClamped() {
        XCTAssertEqual(GridOSAppPreferences.clampedFontSize(8), 10)
        XCTAssertEqual(GridOSAppPreferences.clampedFontSize(18), 18)
        XCTAssertEqual(GridOSAppPreferences.clampedFontSize(42), 24)

        XCTAssertEqual(GridOSAppPreferences(terminalFontSize: 8).terminalFontSize, 10)
        XCTAssertEqual(GridOSAppPreferences(terminalFontSize: 42).terminalFontSize, 24)
    }

    func testVisualIntensityIsClamped() {
        XCTAssertEqual(GridOSAppPreferences.clampedVisualIntensity(-1), 0)
        XCTAssertEqual(GridOSAppPreferences.clampedVisualIntensity(0.4), 0.4)
        XCTAssertEqual(GridOSAppPreferences.clampedVisualIntensity(2), 1)

        XCTAssertEqual(GridOSAppPreferences(visualIntensity: -1).visualIntensity, 0)
        XCTAssertEqual(GridOSAppPreferences(visualIntensity: 2).visualIntensity, 1)
    }

    func testReducedMotionPreferenceIsStored() {
        let preferences = GridOSAppPreferences(reducedMotion: true)

        XCTAssertTrue(preferences.reducedMotion)
    }

    func testVisualModePreferenceKeysUsePhaseFiveStorageNames() {
        XCTAssertEqual(GridOSAppPreferences.visualModeStorageKey, "appearance.visualMode")
        XCTAssertEqual(GridOSAppPreferences.installSeedStorageKey, "appearance.installSeed")
    }

    func testVisualModeRawDefaultsToTron() {
        XCTAssertEqual(GridOSAppPreferences.defaultVisualModeRawValue, "tron")
        XCTAssertEqual(GridOSAppPreferences.defaultInstallSeedRawValue, "")
        XCTAssertEqual(GridOSAppPreferences.supportedVisualModeRawValues, ["tron", "severance", "appleNative"])
    }

    func testVisualModeRawValueFallsBackToTron() {
        XCTAssertEqual(GridOSAppPreferences.normalizedVisualModeRawValue(""), "tron")
        XCTAssertEqual(GridOSAppPreferences.normalizedVisualModeRawValue("   "), "tron")
        XCTAssertEqual(GridOSAppPreferences.normalizedVisualModeRawValue("unknown"), "tron")
        XCTAssertEqual(GridOSAppPreferences.normalizedVisualModeRawValue("cyberpunk"), "tron")
        XCTAssertEqual(GridOSAppPreferences.normalizedVisualModeRawValue("matrix"), "tron")
        XCTAssertEqual(GridOSAppPreferences.normalizedVisualModeRawValue("tron"), "tron")
        XCTAssertEqual(GridOSAppPreferences.normalizedVisualModeRawValue(" severance "), "severance")
        XCTAssertEqual(GridOSAppPreferences.normalizedVisualModeRawValue("\nappleNative\t"), "appleNative")
    }

    func testVisualModeRawValueCyclesInPhaseFiveOrder() {
        XCTAssertEqual(GridOSAppPreferences.nextVisualModeRawValue(after: "tron"), "severance")
        XCTAssertEqual(GridOSAppPreferences.nextVisualModeRawValue(after: "severance"), "appleNative")
        XCTAssertEqual(GridOSAppPreferences.nextVisualModeRawValue(after: "appleNative"), "tron")
        XCTAssertEqual(GridOSAppPreferences.nextVisualModeRawValue(after: ""), "severance")
        XCTAssertEqual(GridOSAppPreferences.nextVisualModeRawValue(after: "matrix"), "severance")
    }

    func testInstallSeedRawValueIsTrimmed() {
        XCTAssertEqual(GridOSAppPreferences.normalizedInstallSeedRawValue(""), "")
        XCTAssertEqual(GridOSAppPreferences.normalizedInstallSeedRawValue("   "), "")
        XCTAssertEqual(GridOSAppPreferences.normalizedInstallSeedRawValue("\n install-a \t"), "install-a")
    }
}
