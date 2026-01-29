import Foundation

enum AIProvider: String, Codable, CaseIterable {
    case appleIntelligence = "Apple Intelligence"
    case gemini = "Gemini AI"
    case mock = "Mock Data"
    
    var icon: String {
        switch self {
        case .appleIntelligence: return "🧠"
        case .gemini: return "✨"
        case .mock: return "🎭"
        }
    }
    
    var subtitle: String {
        switch self {
        case .appleIntelligence: return "On-device, Private"
        case .gemini: return "Cloud-powered"
        case .mock: return "Sample Data"
        }
    }
    
    var description: String {
        switch self {
        case .appleIntelligence:
            return "Uses Apple's on-device AI for private, offline analysis"
        case .gemini:
            return "Uses Google's Gemini AI for advanced cloud-based analysis"
        case .mock:
            return "Uses sample data for development and testing"
        }
    }
}
