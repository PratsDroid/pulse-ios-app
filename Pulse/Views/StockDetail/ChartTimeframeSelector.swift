import SwiftUI

struct ChartTimeframeSelector: View {
    @Binding var selectedTimeframe: Constants.ChartTimeframe
    let onSelect: (Constants.ChartTimeframe) async -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Constants.ChartTimeframe.allCases, id: \.self) { timeframe in
                    TimeframeButton(
                        timeframe: timeframe,
                        isSelected: selectedTimeframe == timeframe
                    ) {
                        selectedTimeframe = timeframe
                        Task {
                            await onSelect(timeframe)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

private struct TimeframeButton: View {
    let timeframe: Constants.ChartTimeframe
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(timeframe.rawValue)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ? Color.blue : Color.clear
                )
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var selectedTimeframe: Constants.ChartTimeframe = .oneDay
    
    VStack {
        ChartTimeframeSelector(selectedTimeframe: $selectedTimeframe) { timeframe in
            print("Selected: \(timeframe.rawValue)")
        }
    }
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
