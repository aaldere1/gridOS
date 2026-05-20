import Foundation

public struct GridOSAppPreferences: Equatable, Sendable {
    public static let defaultShellPath = "/bin/zsh"
    public static let defaultTerminalFontSize = 13.0
    public static let defaultVisualIntensity = 0.65
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

    public static let defaultValue = GridOSAppPreferences()
}
