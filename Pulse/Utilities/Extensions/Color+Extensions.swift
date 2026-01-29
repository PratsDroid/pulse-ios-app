import SwiftUI

extension Color {
    /// Adaptive background color for light/dark mode
    static let appBackground = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 18/255, green: 18/255, blue: 18/255, alpha: 1)
            : UIColor(red: 242/255, green: 242/255, blue: 247/255, alpha: 1)
    })
    
    /// Adaptive card background for light/dark mode
    static let cardBackground = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 28/255, green: 28/255, blue: 30/255, alpha: 1)
            : UIColor.white
    })
    
    /// Adaptive positive green for light/dark mode
    static let positiveGreen = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0, green: 200/255, blue: 83/255, alpha: 1)
            : UIColor(red: 0, green: 150/255, blue: 60/255, alpha: 1)
    })
    
    /// Adaptive negative red for light/dark mode
    static let negativeRed = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 1, green: 23/255, blue: 68/255, alpha: 1)
            : UIColor(red: 200/255, green: 0, blue: 50/255, alpha: 1)
    })
    
    /// Get color based on positive/negative value
    static func forChange(_ value: Double) -> Color {
        value >= 0 ? .positiveGreen : .negativeRed
    }
}
