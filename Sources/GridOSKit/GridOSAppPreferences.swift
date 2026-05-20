import Foundation

public struct GridOSAppPreferences: Equatable, Sendable {
    public static let defaultShellPath = "/bin/zsh"
    public static let defaultTerminalFontSize = 13.0
    public static let defaultVisualIntensity = 0.65
    public static let visualModeStorageKey = "appearance.visualMode"
    public static let installSeedStorageKey = "appearance.installSeed"
    public static let defaultVisualModeRawValue = "tron"
    public static let defaultInstallSeedRawValue = ""
    public static let supportedVisualModeRawValues = ["tron", "severance", "appleNative"]
    public static let fontSizeRange = 10.0...24.0
    public static let visualIntensityRange = 0.0...1.0

    public var shellPath: String
    public var terminalFontSize: Double
    public var visualIntensity: Double
    public var reducedMotion: Bool

    public init(
        shellPath: String = defaultShellPath,
        terminalFontSize: Double = defaultTerminalFontSize,
        visualIntensity: Double = defaultVisualIntensity,
        reducedMotion: Bool = false
    ) {
        let trimmedShellPath = shellPath.trimmingCharacters(in: .whitespacesAndNewlines)

        self.shellPath = trimmedShellPath.isEmpty ? Self.defaultShellPath : trimmedShellPath
        self.terminalFontSize = Self.clampedFontSize(terminalFontSize)
        self.visualIntensity = Self.clampedVisualIntensity(visualIntensity)
        self.reducedMotion = reducedMotion
    }

    public static func clampedFontSize(_ fontSize: Double) -> Double {
        min(fontSizeRange.upperBound, max(fontSizeRange.lowerBound, fontSize))
    }

    public static func clampedVisualIntensity(_ visualIntensity: Double) -> Double {
        min(visualIntensityRange.upperBound, max(visualIntensityRange.lowerBound, visualIntensity))
    }

    public static func normalizedVisualModeRawValue(_ rawValue: String) -> String {
        let trimmedRawValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)

        guard supportedVisualModeRawValues.contains(trimmedRawValue) else {
            return defaultVisualModeRawValue
        }

        return trimmedRawValue
    }

    public static func nextVisualModeRawValue(after rawValue: String) -> String {
        let normalizedRawValue = normalizedVisualModeRawValue(rawValue)
        let currentIndex = supportedVisualModeRawValues.firstIndex(of: normalizedRawValue) ?? 0
        let nextIndex = supportedVisualModeRawValues.index(after: currentIndex)

        guard nextIndex < supportedVisualModeRawValues.endIndex else {
            return supportedVisualModeRawValues[0]
        }

        return supportedVisualModeRawValues[nextIndex]
    }

    public static func normalizedInstallSeedRawValue(_ rawValue: String) -> String {
        rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static let defaultValue = GridOSAppPreferences()
}
