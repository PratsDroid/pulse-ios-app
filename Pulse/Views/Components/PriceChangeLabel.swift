import SwiftUI

struct PriceChangeLabel: View {
    let change: Double
    let changePercent: Double
    let showIcon: Bool
    
    init(change: Double, changePercent: Double, showIcon: Bool = true) {
        self.change = change
        self.changePercent = changePercent
        self.showIcon = showIcon
    }
    
    private var isPositive: Bool {
        change >= 0
    }
    
    private var color: Color {
        Color.forChange(change)
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if showIcon {
                Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption2.weight(.semibold))
            }
            
            Text(change.asCurrency)
                .font(.subheadline.weight(.semibold))
            
            Text("(\(changePercent.asPercentage))")
                .font(.subheadline)
        }
        .foregroundColor(color)
    }
}

#Preview {
    VStack(spacing: 20) {
        PriceChangeLabel(change: 2.34, changePercent: 1.30)
        PriceChangeLabel(change: -1.23, changePercent: -0.85)
        PriceChangeLabel(change: 0, changePercent: 0)
    }
    .padding()
    .background(Color.appBackground)
}
