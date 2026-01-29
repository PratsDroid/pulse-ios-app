import SwiftUI

struct AIAnalysisView: View {
    @StateObject private var viewModel: AIAnalysisViewModel
    @Environment(\.dismiss) private var dismiss
    let stock: Stock
    let analysisType: AIAnalysisType
    
    init(stock: Stock, priceHistory: [PricePoint], analysisType: AIAnalysisType = .general) {
        self.stock = stock
        self.analysisType = analysisType
        _viewModel = StateObject(wrappedValue: AIAnalysisViewModel(
            stock: stock,
            priceHistory: priceHistory,
            analysisType: analysisType
        ))
    }
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            if viewModel.isLoading {
                LoadingView(message: "Analyzing stock...")
            } else if let analysis = viewModel.analysis {
                ScrollView {
                    VStack(spacing: 20) {
                        // AI Provider Selector
                        providerSelector
                        
                        // Market Sentiment
                        sentimentCard(analysis.sentiment)
                        
                        // Cache Info Footer
                        cacheInfoFooter(analysis)
                       
                        // Summary
                        summarySection(analysis.summary)
                        
                        // Key Points
                        keyPointsSection(analysis.keyPoints)
                        
                        // Patterns
                        if !analysis.patterns.isEmpty {
                            patternsSection(analysis.patterns)
                        }
                        
                        // Technical Levels
                        if !analysis.technicalLevels.isEmpty {
                            TechnicalLevelsCard(levels: analysis.technicalLevels)
                        }
                        
                        // Recommendation
                        recommendationSection(analysis.recommendation, confidence: analysis.confidence)
                    }
                    .padding()
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
        }
        .navigationTitle(analysisType.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .task {
            await viewModel.loadAnalysis(type: analysisType)
        }
        .alert("Error", isPresented: $viewModel.showError, presenting: viewModel.error) { error in
            Button("OK", role: .cancel) {}
            Button("Retry") {
                Task {
                    await viewModel.refresh()
                }
            }
        } message: { error in
            Text(error.localizedDescription)
        }
    }
    
    private var providerSelector: some View {
        VStack(spacing: 8) {
            Picker("AI Provider", selection: $viewModel.selectedProvider) {
                if AppleIntelligenceService.isAvailable() {
                    Text("Apple Intelligence").tag(AIProvider.appleIntelligence)
                }
                if !Constants.API.geminiAPIKey.isEmpty {
                    Text("Gemini AI").tag(AIProvider.gemini)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: viewModel.selectedProvider) { oldValue, newValue in
                Task {
                    await viewModel.loadAnalysis(forceProvider: newValue)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func summarySection(_ summary: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Summary")
                .font(.headline.weight(.semibold))
                .foregroundColor(.primary)
            
            Text(summary)
                .font(.body)
                .foregroundColor(.primary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(Constants.UI.cornerRadius)
    }
    
    private func keyPointsSection(_ points: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Insights")
                .font(.headline.weight(.semibold))
                .foregroundColor(.primary)
            
            ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "\(index + 1).circle.fill")
                        .font(.body)
                        .foregroundColor(.blue)
                    
                    Text(point)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(Constants.UI.cornerRadius)
    }
    
    private func patternsSection(_ patterns: [Pattern]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detected Patterns")
                .font(.headline.weight(.semibold))
                .foregroundColor(.primary)
                .padding(.horizontal)
            
            ForEach(patterns) { pattern in
                PatternCard(pattern: pattern)
            }
        }
    }
    
    private func cacheInfoFooter(_ analysis: AIAnalysis) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "clock")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text("Updated \(analysis.fetchedAt.asRelativeTime)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button {
                Task {
                    await viewModel.refresh()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                    Text("Refresh")
                        .font(.caption.weight(.medium))
                }
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.secondary.opacity(0.06))
        .cornerRadius(10)
    }
    
    private func recommendationSection(_ recommendation: String, confidence: Double) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recommendation")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(Int(confidence * 100))% confidence")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
            }
            
            Text(recommendation)
                .font(.body)
                .foregroundColor(.primary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(Constants.UI.cornerRadius)
    }
    
    // MARK: - Sentiment Card
    
    private func sentimentCard(_ sentiment: Sentiment) -> some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(sentimentColor(for: sentiment).opacity(0.12))
                    .frame(width: 44, height: 44)
                
                Image(systemName: sentimentIconName(for: sentiment))
                    .font(.body.weight(.semibold))
                    .foregroundColor(sentimentColor(for: sentiment))
            }
            
            // Text
            VStack(alignment: .leading, spacing: 3) {
                Text(sentimentTitle(for: sentiment))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                
                Text(sentimentDescription(for: sentiment))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(Constants.UI.cornerRadius)
    }
    
    private func sentimentTitle(for sentiment: Sentiment) -> String {
        switch sentiment {
        case .bullish: return "Bullish Outlook"
        case .bearish: return "Bearish Outlook"
        case .neutral: return "Neutral Outlook"
        }
    }
    
    private func sentimentDescription(for sentiment: Sentiment) -> String {
        switch sentiment {
        case .bullish: return "Positive momentum, potential upside"
        case .bearish: return "Negative momentum, potential downside"
        case .neutral: return "Balanced signals, consolidation expected"
        }
    }
    
    // MARK: - Analysis Header (Deprecated)
    
    private func analysisHeader(_ analysis: AIAnalysis) -> some View {
        HStack(alignment: .center, spacing: 12) {
            // Provider Info
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(providerColor(for: analysis.provider).opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: providerIconName(for: analysis.provider))
                        .font(.body.weight(.semibold))
                        .foregroundColor(providerColor(for: analysis.provider))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(analysis.provider.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    
                    Text(analysis.provider.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Sentiment Pill
            HStack(spacing: 6) {
                Image(systemName: sentimentIconName(for: analysis.sentiment))
                    .font(.caption.weight(.semibold))
                
                Text(analysis.sentiment.rawValue.capitalized)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundColor(sentimentColor(for: analysis.sentiment))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(sentimentColor(for: analysis.sentiment).opacity(0.1))
            .cornerRadius(12)
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(Constants.UI.cornerRadius)
    }
    
    // MARK: - Helper Methods
    
    private func providerIconName(for provider: AIProvider) -> String {
        switch provider {
        case .appleIntelligence: return "brain.head.profile"
        case .gemini: return "sparkles"
        case .mock: return "testtube.2"
        }
    }
    
    private func providerColor(for provider: AIProvider) -> Color {
        switch provider {
        case .appleIntelligence: return .blue
        case .gemini: return .purple
        case .mock: return .gray
        }
    }
    
    private func sentimentIconName(for sentiment: Sentiment) -> String {
        switch sentiment {
        case .bullish: return "arrow.up.right"
        case .bearish: return "arrow.down.right"
        case .neutral: return "arrow.right"
        }
    }
    
    private func sentimentColor(for sentiment: Sentiment) -> Color {
        switch sentiment {
        case .bullish: return .positiveGreen
        case .bearish: return .negativeRed
        case .neutral: return .secondary
        }
    }
}

#Preview {
    NavigationStack {
        AIAnalysisView(
            stock: Stock.sample,
            priceHistory: PricePoint.generateSampleData(days: 30, basePrice: 150)
        )
    }
}
