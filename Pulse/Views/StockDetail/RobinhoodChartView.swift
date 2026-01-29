import SwiftUI
import Charts

/// Robinhood-style interactive stock chart with smooth curves and gradient fill
struct RobinhoodChartView: View {
    let data: [PricePoint]
    let isPositive: Bool
    let onPeriodChange: ((TimePeriod) -> Void)?
    
    @State private var selectedPoint: PricePoint?
    @State private var selectedPeriod: TimePeriod = .oneDay
    @GestureState private var isDragging = false
    
    init(data: [PricePoint], isPositive: Bool, onPeriodChange: ((TimePeriod) -> Void)? = nil) {
        self.data = data
        self.isPositive = isPositive
        self.onPeriodChange = onPeriodChange
    }
    
    enum TimePeriod: String, CaseIterable {
        case oneDay = "1D"
        case fiveDay = "5D"
        case oneMonth = "1M"
        case threeMonth = "3M"
        case sixMonth = "6M"
        case yearToDate = "YTD"
        
        var days: Int {
            switch self {
            case .oneDay: return 1
            case .fiveDay: return 5
            case .oneMonth: return 30
            case .threeMonth: return 90
            case .sixMonth: return 180
            case .yearToDate:
                let now = Date()
                let startOfYear = Calendar.current.date(from: Calendar.current.dateComponents([.year], from: now))!
                return Calendar.current.dateComponents([.day], from: startOfYear, to: now).day ?? 0
            }
        }
    }
    
    private var filteredData: [PricePoint] {
        guard !data.isEmpty else {
            print("⚠️ CHART: No data available")
            return []
        }
        
        // Calculate how many days of data we actually have
        let dates = data.map { $0.date }
        if let oldestDate = dates.min(),
           let newestDate = dates.max() {
            let actualDays = Calendar.current.dateComponents([.day], from: oldestDate, to: newestDate).day ?? 0
            
            // If we have less data than the selected period, just show all data
            if actualDays < selectedPeriod.days {
                print("✅ CHART: Have \(actualDays) days (\(data.count) points) from \(oldestDate) to \(newestDate), showing all (period wants \(selectedPeriod.days) days)")
                return data
            }
        }
        
        // Otherwise, filter to the selected period
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -selectedPeriod.days, to: Date()) ?? Date()
        let filtered = data.filter { $0.date >= cutoffDate }
        
        // If filtering removes all data, just use all available data
        if filtered.isEmpty {
            print("⚠️ CHART: Filtered data is empty, using all \(data.count) points")
            return data
        }
        
        print("✅ CHART: Showing \(filtered.count) of \(data.count) points for period \(selectedPeriod.rawValue)")
        return filtered
    }
    
    private var minPrice: Double {
        filteredData.map { $0.low }.min() ?? 0
    }
    
    private var maxPrice: Double {
        filteredData.map { $0.high }.max() ?? 0
    }
    
    private var currentPrice: Double {
        selectedPoint?.close ?? filteredData.last?.close ?? 0
    }
    
    private var priceChange: Double {
        guard let first = filteredData.first?.close,
              let current = selectedPoint?.close ?? filteredData.last?.close else {
            return 0
        }
        return current - first
    }
    
    private var priceChangePercent: Double {
        guard let first = filteredData.first?.close else { return 0 }
        return (priceChange / first) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Price header
            priceHeader
                .padding(.horizontal)
                .padding(.top, 16)
            
            // Time period selector
            timePeriodSelector
                .padding(.horizontal)
                .padding(.top, 16)
            
            // Chart
            chartView
                .frame(height: 280)
                .padding(.top, 24)
            
            // Date labels
            dateLabels
                .padding(.horizontal)
                .padding(.top, 8)
        }
        .background(Color.cardBackground)
        .cornerRadius(Constants.UI.cornerRadius)
    }
    
    private var priceHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Current price
            Text(currentPrice.asCurrency)
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.primary)
            
            // Price change
            HStack(spacing: 4) {
                Image(systemName: priceChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption.bold())
                
                Text("\(abs(priceChange).asCurrency) (\(abs(priceChangePercent), specifier: "%.2f")%)")
                    .font(.subheadline.weight(.medium))
            }
            .foregroundColor(priceChange >= 0 ? Constants.Colors.positiveGreen : Constants.Colors.negativeRed)
            
            // Date/time info
            if let selected = selectedPoint {
                Text(formatDateTime(selected.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
        }
    }
    
    private var timePeriodSelector: some View {
        HStack(spacing: 0) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPeriod = period
                        selectedPoint = nil
                        onPeriodChange?(period)
                    }
                } label: {
                    Text(period.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(selectedPeriod == period ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selectedPeriod == period ? Color.blue : Color.clear)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(4)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var chartView: some View {
        Chart {
            ForEach(filteredData) { point in
                // Gradient fill area
                AreaMark(
                    x: .value("Date", point.date),
                    yStart: .value("Min", minPrice),
                    yEnd: .value("Price", point.close)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            (isPositive ? Constants.Colors.positiveGreen : Constants.Colors.negativeRed).opacity(0.25),
                            (isPositive ? Constants.Colors.positiveGreen : Constants.Colors.negativeRed).opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
                
                // Line
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Price", point.close)
                )
                .foregroundStyle(isPositive ? Constants.Colors.positiveGreen : Constants.Colors.negativeRed)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)
                
                // Touch indicator
                if let selected = selectedPoint, selected.id == point.id {
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Price", point.close)
                    )
                    .foregroundStyle(.white)
                    .symbolSize(120)
                    .annotation(position: .top, spacing: 8) {
                        VStack(spacing: 2) {
                            Text(point.close.asCurrency)
                                .font(.caption.bold())
                                .foregroundColor(.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.cardBackground.opacity(0.9))
                                .cornerRadius(6)
                                .shadow(radius: 2)
                        }
                    }
                }
            }
        }
        .chartYScale(domain: minPrice * 0.998...maxPrice * 1.002)
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { value in
                AxisValueLabel {
                    if let price = value.as(Double.self) {
                        Text(price.asCurrency)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.secondary.opacity(0.2))
            }
        }
        .chartBackground { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let location = value.location
                                if let date: Date = proxy.value(atX: location.x) {
                                    // Find closest data point
                                    if let closest = filteredData.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }) {
                                        selectedPoint = closest
                                    }
                                }
                            }
                            .onEnded { _ in
                                // Keep the last selected point or clear after a delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    selectedPoint = nil
                                }
                            }
                    )
            }
        }
    }
    
    private var dateLabels: some View {
        HStack {
            if let first = filteredData.first {
                Text(formatDate(first.date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if filteredData.count > 1, let last = filteredData.last {
                Text(formatDate(last.date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        switch selectedPeriod {
        case .oneDay:
            formatter.dateFormat = "h:mm a"
        case .fiveDay:
            formatter.dateFormat = "MMM d"
        case .oneMonth, .threeMonth:
            formatter.dateFormat = "MMM d"
        case .sixMonth, .yearToDate:
            formatter.dateFormat = "MMM d"
        }
        
        return formatter.string(from: date)
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}

#Preview {
    VStack {
        RobinhoodChartView(
            data: PricePoint.generateSampleData(days: 180, basePrice: 191.52),
            isPositive: true
        )
        .padding()
    }
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
