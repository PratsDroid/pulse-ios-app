import Foundation

enum AIError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case rateLimitExceeded
    case networkError(Error)
    case parsingError
    case invalidRequest
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Gemini API key not configured"
        case .invalidResponse:
            return "Invalid response from AI service"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .parsingError:
            return "Failed to parse AI response"
        case .invalidRequest:
            return "Invalid request parameters"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .missingAPIKey:
            return "Please add your Gemini API key in Config.plist"
        case .invalidResponse, .parsingError:
            return "Please try again"
        case .rateLimitExceeded:
            return "Wait a moment and try again"
        case .networkError:
            return "Check your internet connection"
        case .invalidRequest:
            return "Please check the stock data and try again"
        }
    }
}
