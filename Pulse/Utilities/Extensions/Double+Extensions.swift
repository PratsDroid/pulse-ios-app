import Foundation

extension Double {
    /// Format as currency (e.g., $182.52)
    var asCurrency: String {
        Constants.Format.priceFormatter.string(from: NSNumber(value: self)) ?? "$0.00"
    }
    
    /// Format as percentage (e.g., +1.30%)
    var asPercentage: String {
        let value = self / 100.0
        return Constants.Format.percentFormatter.string(from: NSNumber(value: value)) ?? "0.00%"
    }
    
    /// Format as compact number (e.g., 2.85T, 52.4M)
    var asCompactNumber: String {
        if self >= 1_000_000_000_000 {
            return String(format: "%.2fT", self / 1_000_000_000_000)
        } else if self >= 1_000_000_000 {
            return String(format: "%.2fB", self / 1_000_000_000)
        } else if self >= 1_000_000 {
            return String(format: "%.2fM", self / 1_000_000)
        } else if self >= 1_000 {
            return String(format: "%.2fK", self / 1_000)
        } else {
            return String(format: "%.2f", self)
        }
    }
    
    /// Format with commas (e.g., 52,430,000)
    var asFormattedNumber: String {
        Constants.Format.largeNumberFormatter.string(from: NSNumber(value: self)) ?? "0"
    }
}
