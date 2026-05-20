import Foundation

enum CommandIntelligenceCommandCenter {
    static func openCommandIntelligence() {
        post(.gridOSCommandIntelligenceOpen)
    }

    static func openCommandIntelligenceSettings() {
        post(.gridOSCommandIntelligenceOpenSettings)
    }

    private static func post(_ name: Notification.Name) {
        NotificationCenter.default.post(name: name, object: nil)
    }
}

extension Notification.Name {
    static let gridOSCommandIntelligenceOpen = Notification.Name("gridOS.commandIntelligence.open")
    static let gridOSCommandIntelligenceOpenSettings = Notification.Name("gridOS.commandIntelligence.openSettings")
}
