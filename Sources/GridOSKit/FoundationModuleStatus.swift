import Foundation

public struct FoundationModuleStatus: Identifiable, Equatable, Sendable {
    public enum State: String, Sendable {
        case scaffolded
        case pending
    }

    public let id: String
    public let title: String
    public let state: State
    public let detail: String

    public init(id: String, title: String, state: State, detail: String) {
        self.id = id
        self.title = title
        self.state = state
        self.detail = detail
    }
}
