import Foundation

enum AIAnalysisType: String, CaseIterable, Identifiable {
    case general = "General Analysis"
    case monthForecast = "1-Month Forecast"
    case weekForecast = "1-Week Forecast"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .general: return "brain.head.profile"
        case .monthForecast: return "calendar"
        case .weekForecast: return "calendar.badge.clock"
        }
    }
    
    var description: String {
        switch self {
        case .general:
            return "Comprehensive AI analysis with technical indicators and patterns"
        case .monthForecast:
            return "30-day technical forecast with monthly support/resistance levels"
        case .weekForecast:
            return "7-day technical forecast with short-term momentum analysis"
        }
    }
}
