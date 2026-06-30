import Foundation

extension KeyedDecodingContainer {
    func decodeBool(forKey key: Key, default defaultValue: Bool = false) throws -> Bool {
        if let value = try decodeIfPresent(Bool.self, forKey: key) {
            return value
        }
        if let intValue = try decodeIfPresent(Int.self, forKey: key) {
            return intValue != 0
        }
        if let stringValue = try decodeIfPresent(String.self, forKey: key) {
            switch stringValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "true", "t", "yes", "y", "1": return true
            case "false", "f", "no", "n", "0": return false
            default: return defaultValue
            }
        }
        return defaultValue
    }

    func decodeFlexibleInt(forKey key: Key) throws -> Int? {
        if let value = try decodeIfPresent(Int.self, forKey: key) {
            return value
        }
        if let doubleValue = try decodeIfPresent(Double.self, forKey: key) {
            return Int(doubleValue)
        }
        if let stringValue = try decodeIfPresent(String.self, forKey: key),
           let intValue = Int(stringValue.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return intValue
        }
        return nil
    }

    func decodeString(forKey key: Key, default defaultValue: String = "") throws -> String {
        if let value = try decodeIfPresent(String.self, forKey: key)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !value.isEmpty {
            return value
        }
        return defaultValue
    }
}

extension DecodingError {
    var memberPortalDescription: String {
        switch self {
        case .keyNotFound(let key, let context):
            "Missing field \"\(key.stringValue)\" in \(context.codingPathDescription)."
        case .typeMismatch(let type, let context):
            "Unexpected format for \"\(context.codingPathDescription)\" (expected \(type))."
        case .valueNotFound(let type, let context):
            "Missing value for \"\(context.codingPathDescription)\" (expected \(type))."
        case .dataCorrupted(let context):
            "Invalid data for \"\(context.codingPathDescription)\": \(context.debugDescription)"
        @unknown default:
            localizedDescription
        }
    }
}

private extension CodingKey {
    var pathDescription: String { stringValue }
}

private extension DecodingError.Context {
    var codingPathDescription: String {
        let path = codingPath.map(\.stringValue).filter { !$0.isEmpty }
        return path.isEmpty ? "response" : path.joined(separator: ".")
    }
}

enum MemberPortalError: LocalizedError {
    case decode(String)

    var errorDescription: String? {
        switch self {
        case .decode(let message):
            "We couldn't load your account data (\(message)). Try again or contact your society administrator."
        }
    }
}

enum MemberPortalErrorMapper {
    static func userMessage(for error: Error) -> String {
        if let sessionError = error as? SessionError {
            return sessionError.localizedDescription
        }
        if let authError = error as? AuthError {
            return authError.localizedDescription
        }
        if let decodingError = error as? DecodingError {
            return MemberPortalError.decode(decodingError.memberPortalDescription).errorDescription
                ?? decodingError.localizedDescription
        }
        return error.localizedDescription
    }
}
