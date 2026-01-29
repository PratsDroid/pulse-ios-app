import SwiftUI

struct SentimentBadge: View {
    let sentiment: Sentiment
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(textColor)
            
            Text(sentiment.rawValue.capitalized)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(textColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(backgroundColor)
        .cornerRadius(10)
    }
    
    private var iconName: String {
        switch sentiment {
        case .bullish: return "arrow.up.right"
        case .bearish: return "arrow.down.right"
        case .neutral: return "arrow.right"
        }
    }
    
    private var textColor: Color {
        switch sentiment {
        case .bullish: return Color.positiveGreen
        case .bearish: return Color.negativeRed
        case .neutral: return .secondary
        }
    }
    
    private var backgroundColor: Color {
        switch sentiment {
        case .bullish:
            return Color.positiveGreen.opacity(0.12)
        case .bearish:
            return Color.negativeRed.opacity(0.12)
        case .neutral:
            return Color.secondary.opacity(0.12)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        SentimentBadge(sentiment: .bullish)
        SentimentBadge(sentiment: .bearish)
        SentimentBadge(sentiment: .neutral)
    }
    .padding()
    .background(Color.appBackground)
}
