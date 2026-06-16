import Foundation

public struct GridOSAppPreferences: Equatable, Sendable {
    public static let defaultShellPath = "/bin/zsh"
    public static let defaultTerminalFontSize = 13.0
    public static let defaultVisualIntensity = 0.65
    public static let visualModeStorageKey = "appearance.visualMode"
    public static let installSeedStorageKey = "appearance.installSeed"
    public static let commandIntelligenceProviderStorageKey = "commandIntelligence.providerID"
    public static let commandIntelligenceModelStorageKey = "commandIntelligence.modelID"
    public static let showMenuBarExtraStorageKey = "integrations.showMenuBarExtra"
    public static let notificationsEnabledStorageKey = "integrations.notificationsEnabled"
    public static let indexWorkspaceMetadataStorageKey = "integrations.indexWorkspaceMetadata"
    public static let privacySafetyLaunchAcceptedStorageKey = "privacy.safetyLaunchAccepted"
    public static let defaultVisualModeRawValue = "tron"
    public static let defaultInstallSeedRawValue = ""
    public static let defaultCommandIntelligenceProviderID = "anthropic"
    public static let defaultCommandIntelligenceModelID = "claude-sonnet-4-20250514"
    public static let defaultOpenAICommandIntelligenceModelID = "gpt-5.2"
    public static let defaultDeepSeekCommandIntelligenceModelID = "deepseek-v4-flash"
    public static let defaultXAICommandIntelligenceModelID = "grok-4.3"
    public static let menuBarExtraAvailable = false
    public static let defaultShowMenuBarExtra = false
    public static let defaultNotificationsEnabled = false
    public static let defaultIndexWorkspaceMetadata = false
    public static let defaultPrivacySafetyLaunchAccepted = false
    public static let supportedVisualModeRawValues = ["tron", "matrix", "amberCRT", "redline", "severance", "appleNative"]
    public static let supportedCommandIntelligenceProviderIDs = ["anthropic", "openai", "deepseek", "xai"]
    public static let supportedCommandIntelligenceModelIDs = [
        "claude-opus-4-1-20250805",
        "claude-sonnet-4-20250514",
        "claude-3-7-sonnet-20250219",
        "claude-3-5-haiku-20241022",
        "gpt-5.2",
        "gpt-5",
        "gpt-5-mini",
        "gpt-5-nano",
        "deepseek-v4-flash",
        "deepseek-v4-pro",
        "grok-4.3",
        "grok-build-0.1"
    ]
    public static let fontSizeRange = 10.0...24.0
    public static let visualIntensityRange = 0.0...1.0

    public var shellPath: String
    public var terminalFontSize: Double
    public var visualIntensity: Double
    public var reducedMotion: Bool
    public var privacySafetyLaunchAccepted: Bool

    public init(
        shellPath: String = defaultShellPath,
        terminalFontSize: Double = defaultTerminalFontSize,
        visualIntensity: Double = defaultVisualIntensity,
        reducedMotion: Bool = false,
        privacySafetyLaunchAccepted: Bool = defaultPrivacySafetyLaunchAccepted
    ) {
        let trimmedShellPath = shellPath.trimmingCharacters(in: .whitespacesAndNewlines)

        self.shellPath = trimmedShellPath.isEmpty ? Self.defaultShellPath : trimmedShellPath
        self.terminalFontSize = Self.clampedFontSize(terminalFontSize)
        self.visualIntensity = Self.clampedVisualIntensity(visualIntensity)
        self.reducedMotion = reducedMotion
        self.privacySafetyLaunchAccepted = privacySafetyLaunchAccepted
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

    public static func normalizedCommandIntelligenceProviderID(_ rawValue: String) -> String {
        let trimmedRawValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)

        guard supportedCommandIntelligenceProviderIDs.contains(trimmedRawValue) else {
            return defaultCommandIntelligenceProviderID
        }

        return trimmedRawValue
    }

    public static func normalizedCommandIntelligenceModelID(_ rawValue: String) -> String {
        normalizedCommandIntelligenceModelID(rawValue, providerID: defaultCommandIntelligenceProviderID)
    }

    public static func defaultCommandIntelligenceModelID(for providerID: String) -> String {
        switch normalizedCommandIntelligenceProviderID(providerID) {
        case "openai":
            return defaultOpenAICommandIntelligenceModelID
        case "deepseek":
            return defaultDeepSeekCommandIntelligenceModelID
        case "xai":
            return defaultXAICommandIntelligenceModelID
        default:
            return defaultCommandIntelligenceModelID
        }
    }

    public static func normalizedCommandIntelligenceModelID(_ rawValue: String, providerID: String) -> String {
        let trimmedRawValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedRawValue.isEmpty else {
            return defaultCommandIntelligenceModelID(for: providerID)
        }

        return trimmedRawValue
    }

    public static let defaultValue = GridOSAppPreferences()
}
