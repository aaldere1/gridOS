import Foundation

public enum CommandIntelligenceFailure: Error, Equatable, Sendable {
    public static let openSettingsRecoveryAction = "Open AI Command Helper Settings"
    public static let retryRecoveryAction = "Retry Request"

    case noProviderKey(requestID: String? = nil)
    case cancelledBeforeSend(requestID: String? = nil)
    case offline(underlyingDescription: String? = nil, requestID: String? = nil)
    case rateLimited(providerMessage: String? = nil, requestID: String? = nil)
    case providerError(message: String? = nil, requestID: String? = nil)
    case providerRefusal(message: String? = nil, requestID: String? = nil)
    case invalidProviderResponse(underlyingDescription: String? = nil, requestID: String? = nil)
    case truncatedResponse(providerMessage: String? = nil, requestID: String? = nil)
    case redactionBlocked(reasons: [String], requestID: String? = nil)
    case unsupportedSelection(requestID: String? = nil)

    public var title: String {
        switch self {
        case .noProviderKey:
            "Provider not configured"
        case .offline:
            "Provider unreachable"
        case .rateLimited:
            "Provider is busy"
        case .redactionBlocked:
            "Context needs review"
        case .unsupportedSelection:
            "Selection unavailable"
        case .cancelledBeforeSend:
            "Request cancelled"
        case .providerError, .providerRefusal, .invalidProviderResponse, .truncatedResponse:
            "AI Command Helper is unavailable"
        }
    }

    public var message: String {
        switch self {
        case .noProviderKey:
            "Add a provider key in Settings to use AI Command Helper. The terminal still works normally."
        case .cancelledBeforeSend:
            "Nothing was sent."
        case .offline:
            "Check your connection or try again later. Nothing was sent after the failure."
        case .rateLimited:
            "Wait a moment and try again. The terminal is still available."
        case .providerError, .providerRefusal, .invalidProviderResponse, .truncatedResponse:
            "Try again or continue in the terminal without assistance."
        case .redactionBlocked:
            "Sensitive content was detected that cannot be safely sent. Remove it or continue manually."
        case .unsupportedSelection:
            "Paste the output into the field to continue."
        }
    }

    public var recoveryAction: String? {
        switch self {
        case .noProviderKey:
            Self.openSettingsRecoveryAction
        case .offline, .rateLimited, .providerError, .providerRefusal, .invalidProviderResponse, .truncatedResponse:
            Self.retryRecoveryAction
        case .redactionBlocked:
            "Edit Context"
        case .cancelledBeforeSend, .unsupportedSelection:
            nil
        }
    }

    public var requestID: String? {
        switch self {
        case let .noProviderKey(requestID),
             let .cancelledBeforeSend(requestID),
             let .unsupportedSelection(requestID):
            requestID
        case let .offline(_, requestID),
             let .rateLimited(_, requestID),
             let .providerError(_, requestID),
             let .providerRefusal(_, requestID),
             let .invalidProviderResponse(_, requestID),
             let .truncatedResponse(_, requestID),
             let .redactionBlocked(_, requestID):
            requestID
        }
    }
}
