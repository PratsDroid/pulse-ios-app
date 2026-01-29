import SwiftUI

struct PatternCard: View {
    let pattern: Pattern
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(pattern.name)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                significanceBadge
            }
            
            Text(pattern.description)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineSpacing(2)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(Constants.UI.cornerRadius)
    }
    
    private var significanceBadge: some View {
        Text(pattern.significance.rawValue.capitalized)
            .font(.caption2.weight(.semibold))
            .foregroundColor(significanceColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(significanceColor.opacity(0.15))
            .cornerRadius(4)
    }
    
    private var significanceColor: Color {
        switch pattern.significance {
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return .gray
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        PatternCard(pattern: Pattern(
            name: "Head and Shoulders",
            description: "A bearish reversal pattern indicating potential downward trend",
            significance: .high
        ))
        
        PatternCard(pattern: Pattern(
            name: "Double Bottom",
            description: "A bullish reversal pattern suggesting upward momentum",
            significance: .medium
        ))
    }
    .padding()
    .background(Color.appBackground)
}
