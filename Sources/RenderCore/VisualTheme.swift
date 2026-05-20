import Foundation

public struct VisualColor: Equatable, Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

public struct VisualPalette: Equatable, Sendable {
    public let background: VisualColor
    public let primaryAccent: VisualColor
    public let secondaryAccent: VisualColor
    public let statusAccent: VisualColor

    public init(
        background: VisualColor,
        primaryAccent: VisualColor,
        secondaryAccent: VisualColor,
        statusAccent: VisualColor
    ) {
        self.background = background
        self.primaryAccent = primaryAccent
        self.secondaryAccent = secondaryAccent
        self.statusAccent = statusAccent
    }
}

public struct VisualPanelStyle: Equatable, Sendable {
    public let backgroundOpacity: Double
    public let borderOpacity: Double
    public let separatorOpacity: Double
    public let cornerRadius: Double

    public init(
        backgroundOpacity: Double,
        borderOpacity: Double,
        separatorOpacity: Double,
        cornerRadius: Double
    ) {
        self.backgroundOpacity = backgroundOpacity
        self.borderOpacity = borderOpacity
        self.separatorOpacity = separatorOpacity
        self.cornerRadius = cornerRadius
    }
}

public struct VisualTerminalChrome: Equatable, Sendable {
    public let backgroundOpacity: Double
    public let foregroundOpacity: Double
    public let cursorGlowOpacity: Double
    public let selectionOpacity: Double

    public init(
        backgroundOpacity: Double,
        foregroundOpacity: Double,
        cursorGlowOpacity: Double,
        selectionOpacity: Double
    ) {
        self.backgroundOpacity = backgroundOpacity
        self.foregroundOpacity = foregroundOpacity
        self.cursorGlowOpacity = cursorGlowOpacity
        self.selectionOpacity = selectionOpacity
    }
}

public struct VisualMotionProfile: Equatable, Sendable {
    public let idleDriftRate: Double
    public let eventGain: Double
    public let pulseDecay: Double
    public let maxPulseDuration: Double
    public let detailDensity: Double

    public init(
        idleDriftRate: Double,
        eventGain: Double,
        pulseDecay: Double,
        maxPulseDuration: Double,
        detailDensity: Double
    ) {
        self.idleDriftRate = idleDriftRate
        self.eventGain = eventGain
        self.pulseDecay = pulseDecay
        self.maxPulseDuration = maxPulseDuration
        self.detailDensity = detailDensity
    }

    public func pulseMagnitude(
        for eventMagnitude: Double,
        intensity: Double,
        reducedMotion: Bool
    ) -> Double {
        guard !reducedMotion else {
            return 0
        }

        let clampedEventMagnitude = min(1, max(0, eventMagnitude))
        let clampedIntensity = min(1, max(0, intensity))
        return clampedEventMagnitude * clampedIntensity * eventGain
    }
}

public struct VisualShaderProfile: Equatable, Sendable {
    public let shaderValue: Float
    public let fieldScale: Double
    public let glowIntensity: Double
    public let lineIntensity: Double
    public let grainIntensity: Double

    public init(
        shaderValue: Float,
        fieldScale: Double,
        glowIntensity: Double,
        lineIntensity: Double,
        grainIntensity: Double
    ) {
        self.shaderValue = shaderValue
        self.fieldScale = fieldScale
        self.glowIntensity = glowIntensity
        self.lineIntensity = lineIntensity
        self.grainIntensity = grainIntensity
    }
}

public struct VisualTheme: Equatable, Sendable {
    public let signature: String
    public let palette: VisualPalette
    public let panel: VisualPanelStyle
    public let terminal: VisualTerminalChrome
    public let motion: VisualMotionProfile
    public let shader: VisualShaderProfile

    public init(
        signature: String,
        palette: VisualPalette,
        panel: VisualPanelStyle,
        terminal: VisualTerminalChrome,
        motion: VisualMotionProfile,
        shader: VisualShaderProfile
    ) {
        self.signature = signature
        self.palette = palette
        self.panel = panel
        self.terminal = terminal
        self.motion = motion
        self.shader = shader
    }

    public static let tron = VisualTheme(
        signature: "tron.cyber-grid.v1",
        palette: VisualPalette(
            background: VisualColor(red: 0.004, green: 0.007, blue: 0.011, alpha: 1),
            primaryAccent: VisualColor(red: 0.10, green: 0.72, blue: 0.78, alpha: 1),
            secondaryAccent: VisualColor(red: 0.12, green: 0.24, blue: 0.46, alpha: 1),
            statusAccent: VisualColor(red: 0.95, green: 0.52, blue: 0.20, alpha: 1)
        ),
        panel: VisualPanelStyle(
            backgroundOpacity: 0.30,
            borderOpacity: 0.24,
            separatorOpacity: 0.18,
            cornerRadius: 6
        ),
        terminal: VisualTerminalChrome(
            backgroundOpacity: 0.72,
            foregroundOpacity: 0.94,
            cursorGlowOpacity: 0.70,
            selectionOpacity: 0.34
        ),
        motion: VisualMotionProfile(
            idleDriftRate: 0.18,
            eventGain: 1.00,
            pulseDecay: 0.42,
            maxPulseDuration: 1.40,
            detailDensity: 0.92
        ),
        shader: VisualShaderProfile(
            shaderValue: 0,
            fieldScale: 1.00,
            glowIntensity: 1.00,
            lineIntensity: 1.00,
            grainIntensity: 0.22
        )
    )

    public static let severance = VisualTheme(
        signature: "severance.corporate-grid.v1",
        palette: VisualPalette(
            background: VisualColor(red: 0.010, green: 0.011, blue: 0.010, alpha: 1),
            primaryAccent: VisualColor(red: 0.78, green: 0.84, blue: 0.76, alpha: 1),
            secondaryAccent: VisualColor(red: 0.30, green: 0.34, blue: 0.30, alpha: 1),
            statusAccent: VisualColor(red: 0.62, green: 0.68, blue: 0.56, alpha: 1)
        ),
        panel: VisualPanelStyle(
            backgroundOpacity: 0.36,
            borderOpacity: 0.16,
            separatorOpacity: 0.22,
            cornerRadius: 3
        ),
        terminal: VisualTerminalChrome(
            backgroundOpacity: 0.78,
            foregroundOpacity: 0.90,
            cursorGlowOpacity: 0.18,
            selectionOpacity: 0.20
        ),
        motion: VisualMotionProfile(
            idleDriftRate: 0.025,
            eventGain: 0.22,
            pulseDecay: 0.88,
            maxPulseDuration: 0.45,
            detailDensity: 0.28
        ),
        shader: VisualShaderProfile(
            shaderValue: 1,
            fieldScale: 0.55,
            glowIntensity: 0.20,
            lineIntensity: 0.36,
            grainIntensity: 0.08
        )
    )

    public static let appleNative = VisualTheme(
        signature: "apple-native.dark-material.v1",
        palette: VisualPalette(
            background: VisualColor(red: 0.015, green: 0.017, blue: 0.020, alpha: 1),
            primaryAccent: VisualColor(red: 0.38, green: 0.68, blue: 1.00, alpha: 1),
            secondaryAccent: VisualColor(red: 0.26, green: 0.32, blue: 0.42, alpha: 1),
            statusAccent: VisualColor(red: 0.97, green: 0.73, blue: 0.30, alpha: 1)
        ),
        panel: VisualPanelStyle(
            backgroundOpacity: 0.32,
            borderOpacity: 0.14,
            separatorOpacity: 0.16,
            cornerRadius: 8
        ),
        terminal: VisualTerminalChrome(
            backgroundOpacity: 0.74,
            foregroundOpacity: 0.92,
            cursorGlowOpacity: 0.28,
            selectionOpacity: 0.24
        ),
        motion: VisualMotionProfile(
            idleDriftRate: 0.06,
            eventGain: 0.38,
            pulseDecay: 0.62,
            maxPulseDuration: 0.75,
            detailDensity: 0.48
        ),
        shader: VisualShaderProfile(
            shaderValue: 2,
            fieldScale: 0.72,
            glowIntensity: 0.42,
            lineIntensity: 0.24,
            grainIntensity: 0.12
        )
    )
}
