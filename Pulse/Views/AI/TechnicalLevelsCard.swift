import SwiftUI

struct TechnicalLevelsCard: View {
    let levels: [TechnicalLevel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Key Technical Levels", systemImage: "chart.line.uptrend.xyaxis")
                .font(.headline)
            
            if levels.isEmpty {
                Text("No significant levels detected")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Level Type")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("Price")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .trailing)
                        
                        Text("Significance")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.secondary.opacity(0.08))
                    
                    // Levels
                    ForEach(levels) { level in
                        HStack(alignment: .top, spacing: 12) {
                            Text(level.type.rawValue)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("$\(level.price, specifier: "%.2f")")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(levelColor(for: level.type))
                                .frame(width: 80, alignment: .trailing)
                            
                            Text(level.significance)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        
                        if level.id != levels.last?.id {
                            Divider()
                                .padding(.leading, 12)
                        }
                    }
                }
                .background(Color.cardBackground)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                )
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(Constants.UI.cornerRadius)
    }
    
    private func levelColor(for type: LevelType) -> Color {
        switch type {
        case .majorResistance, .nearResistance, .minorResistance:
            return .red
        case .strongSupport, .pivotSupport, .minorSupport:
            return .green
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            TechnicalLevelsCard(levels: [
                TechnicalLevel(type: .majorResistance, price: 100.00, significance: "52-week high, psychological barrier"),
                TechnicalLevel(type: .nearResistance, price: 73.00, significance: "50-day MA; needs to regain bullish momentum"),
                TechnicalLevel(type: .pivotSupport, price: 68.50, significance: "Held multiple times"),
                TechnicalLevel(type: .strongSupport, price: 66.00, significance: "200-day MA; drop below would signal long-term trend change")
            ])
            
            TechnicalLevelsCard(levels: [])
        }
        .padding()
    }
    .background(Color.appBackground)
}
