import Foundation

public enum GridOSProduct {
    public static let name = "gridOS"
    public static var version: String {
        metadataValue("CFBundleShortVersionString", fallback: "0.0.0")
    }

    public static var build: String {
        metadataValue("CFBundleVersion", fallback: "0")
    }

    public static let productionPromise = "Native macOS terminal cockpit. Fast shell first; spectacle only when it earns its keep."

    private static func metadataValue(_ key: String, fallback: String) -> String {
        let bundles = [
            Bundle.main,
            Bundle(for: GridOSProductBundleMarker.self)
        ]

        return bundles.lazy
            .compactMap { bundle -> String? in
                guard
                    let identifier = bundle.bundleIdentifier,
                    identifier == "com.aaldere1.gridos" || identifier.hasPrefix("com.aaldere1.gridos.")
                else {
                    return nil
                }

                return bundle.object(forInfoDictionaryKey: key) as? String
            }
            .first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ?? fallback
    }
}

private final class GridOSProductBundleMarker {}
