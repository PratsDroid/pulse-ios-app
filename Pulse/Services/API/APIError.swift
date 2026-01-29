import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidData
    case networkError(Error)
    case decodingError(Error)
    case serverError(statusCode: Int, message: String?)
    case rateLimitExceeded
    case unauthorized
    case notFound
    case missingAPIKey
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .invalidData:
            return "Invalid data received"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode data: \(error.localizedDescription)"
        case .serverError(let statusCode, let message):
            return "Server error (\(statusCode)): \(message ?? "Unknown error")"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .unauthorized:
            return "Unauthorized. Please check your API key."
        case .notFound:
            return "Resource not found"
        case .missingAPIKey:
            return "API key is missing. Please configure your API key."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Please check your internet connection and try again."
        case .rateLimitExceeded:
            return "You've made too many requests. Please wait a moment before trying again."
        case .unauthorized:
            return "Please verify your API key is correct."
        case .missingAPIKey:
            return "Add your API key to the app configuration."
        default:
            return "Please try again later."
        }
    }
}
