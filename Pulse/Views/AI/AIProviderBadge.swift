import SwiftUI

struct AIProviderBadge: View {
    let provider: AIProvider
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.body.weight(.medium))
                .foregroundColor(iconColor)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(provider.rawValue)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                
                Text(provider.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(backgroundColor)
        .cornerRadius(10)
    }
    
    private var iconName: String {
        switch provider {
        case .appleIntelligence: return "brain.head.profile"
        case .gemini: return "sparkles"
        case .mock: return "testtube.2"
        }
    }
    
    private var iconColor: Color {
        switch provider {
        case .appleIntelligence: return .blue
        case .gemini: return .purple
        case .mock: return .gray
        }
    }
    
    private var backgroundColor: Color {
        switch provider {
        case .appleIntelligence:
            return Color.blue.opacity(0.12)
        case .gemini:
            return Color.purple.opacity(0.12)
        case .mock:
            return Color.gray.opacity(0.12)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        AIProviderBadge(provider: .appleIntelligence)
        AIProviderBadge(provider: .gemini)
        AIProviderBadge(provider: .mock)
    }
    .padding()
    .background(Color.appBackground)
}
