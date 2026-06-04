import Foundation

@MainActor
final class AppTerminationGuard {
    static let shared = AppTerminationGuard()

    var shouldTerminateHandler: (() -> Bool)?

    private init() {}

    func shouldTerminate() -> Bool {
        shouldTerminateHandler?() ?? true
    }
}
