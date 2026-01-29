import Foundation

extension Date {
    /// Format as "Jan 27, 2026"
    var asShortDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    /// Format as "3:42 PM"
    var asTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    /// Format as "Jan 27, 3:42 PM"
    var asDateTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    /// Format as "2026-01-27" for API calls
    var asAPIDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
    
    /// Get relative time (e.g., "2 hours ago", "Just now")
    var asRelativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Check if date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// Get start of day
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}
