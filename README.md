# Stock Tracking App - iOS

A modern iOS stock market tracking application built with SwiftUI, featuring real-time stock data, interactive charts, and AI-powered technical analysis.

## 🎯 Project Status: Phase 1 Complete

**Phase 1 - Foundation** ✅
- Complete project structure with MVVM architecture
- Polygon.io API integration with caching
- Watchlist view with pull-to-refresh
- Stock detail view with interactive charts
- Stock search functionality
- Comprehensive error handling

## 📱 Features

### Current Features (Phase 1)
- **Watchlist Management**
  - View tracked stocks with real-time prices
  - Mini sparkline charts for quick trend visualization
  - Color-coded gains/losses
  - Pull-to-refresh for data updates
  - Search and add new stocks
  - Swipe to delete from watchlist

- **Stock Details**
  - Large, prominent price display
  - Market status indicator (open/closed)
  - Interactive price charts with multiple timeframes (1D, 5D, 1M, 3M, 6M, YTD, 1Y, ALL)
  - Touch to view specific price points
  - Key statistics including:
    - 52-week range with visual slider
    - Volume and average volume
    - Market cap
    - P/E ratio
    - Previous close and open prices

- **Modern UI/UX**
  - Dark theme optimized
  - Smooth animations and transitions
  - Loading states with skeleton screens
  - Error handling with retry options
  - Haptic feedback (ready for implementation)

### Coming Soon
- **Phase 2**: Core Data persistence, enhanced charts
- **Phase 3**: AI-powered technical analysis (Apple Intelligence or Gemini)
- **Phase 4**: Notes and saved analyses
- **Phase 5**: Testing and App Store launch

## 🛠 Tech Stack

- **UI Framework**: SwiftUI
- **Architecture**: MVVM
- **Concurrency**: Swift async/await, Combine
- **Charts**: Swift Charts framework
- **API**: Polygon.io (stock market data)
- **iOS Version**: iOS 17+
- **Language**: Swift 5.9+

## 📋 Prerequisites

1. **Xcode 15.0+** with iOS 17+ SDK
2. **Polygon.io API Key** (free tier available)
   - Sign up at [polygon.io](https://polygon.io)
   - Free tier includes delayed stock data (perfect for development)

## 🚀 Setup Instructions

### 1. Clone or Copy the Project

The project is located in `/Users/sonu/Code/Pulse/StockApp/`

### 2. Create Xcode Project

1. Open Xcode
2. Create a new iOS App project:
   - Product Name: `StockApp`
   - Interface: SwiftUI
   - Language: Swift
   - Minimum Deployment: iOS 17.0

3. Replace the default files with the provided source files

### 3. Configure API Key

**Option A: Environment Variable (Recommended for Development)**
```bash
export POLYGON_API_KEY="your_api_key_here"
```

**Option B: Create Config.plist**
1. Create a new Property List file named `Config.plist`
2. Add your API key:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>POLYGON_API_KEY</key>
    <string>your_api_key_here</string>
</dict>
</plist>
```

3. Update `Constants.swift` to read from Config.plist:
```swift
static var polygonAPIKey: String {
    if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
       let config = NSDictionary(contentsOfFile: path),
       let key = config["POLYGON_API_KEY"] as? String {
        return key
    }
    return ProcessInfo.processInfo.environment["POLYGON_API_KEY"] ?? ""
}
```

**⚠️ Important**: Never commit your API key to version control. Add `Config.plist` to `.gitignore`.

### 4. Project Structure

```
StockApp/
├── App/
│   └── StockAppApp.swift              # Main app entry point
├── Models/
│   ├── Stock.swift                    # Stock data model
│   ├── PricePoint.swift               # OHLCV data for charts
│   ├── Watchlist.swift                # Watchlist model
│   └── StockSearchResult.swift        # Search results model
├── Views/
│   ├── Home/
│   │   ├── WatchlistView.swift        # Main watchlist screen
│   │   ├── StockRowView.swift         # Individual stock row
│   │   └── StockSearchView.swift      # Stock search interface
│   ├── StockDetail/
│   │   ├── StockDetailView.swift      # Stock detail screen
│   │   ├── StockHeaderView.swift      # Price header
│   │   ├── ChartView.swift            # Interactive chart
│   │   ├── ChartTimeframeSelector.swift
│   │   └── KeyStatisticsView.swift    # Statistics section
│   └── Components/
│       ├── SparklineChart.swift       # Mini chart component
│       ├── PriceChangeLabel.swift     # Price change display
│       ├── LoadingView.swift          # Loading state
│       └── ErrorView.swift            # Error state
├── ViewModels/
│   ├── WatchlistViewModel.swift       # Watchlist logic
│   └── StockDetailViewModel.swift     # Stock detail logic
├── Services/
│   └── API/
│       ├── PolygonAPIService.swift    # Polygon.io integration
│       ├── NetworkManager.swift       # Network layer
│       └── APIError.swift             # Error handling
└── Utilities/
    ├── Constants.swift                # App constants
    └── Extensions/
        ├── Double+Extensions.swift    # Number formatting
        ├── Date+Extensions.swift      # Date formatting
        └── Color+Extensions.swift     # Color utilities
```

## 🎨 Design Features

- **Dark Mode First**: Optimized for dark theme with professional trading app aesthetics
- **Color Coding**: Green for gains, red for losses (customizable)
- **Smooth Animations**: Fluid transitions and interactions
- **Responsive Charts**: Interactive price charts with touch selection
- **Modern Typography**: SF Pro with proper hierarchy
- **Accessibility**: VoiceOver support, Dynamic Type ready

## 📊 API Integration

### Polygon.io Endpoints Used

1. **Previous Close**: `/v2/aggs/ticker/{ticker}/prev`
   - Get latest daily data for a stock

2. **Historical Data**: `/v2/aggs/ticker/{ticker}/range/1/day/{from}/{to}`
   - Fetch price history for charts

3. **Stock Search**: `/v3/reference/tickers?search={query}`
   - Search for stocks by ticker or name

4. **Ticker Details**: `/v3/reference/tickers/{ticker}`
   - Get company information and metadata

### Caching Strategy

- Stock quotes cached for 1 minute
- Historical data cached for 1 minute
- Automatic cache invalidation on refresh

### Rate Limiting

The free tier of Polygon.io has rate limits:
- 5 API calls per minute
- The app implements caching to minimize API calls
- Error handling for rate limit exceeded (429 status)

## 🧪 Testing

### Manual Testing Checklist

- [ ] Launch app and view watchlist
- [ ] Pull to refresh watchlist
- [ ] Search for a stock (try "AAPL", "GOOGL", "MSFT")
- [ ] Add stock to watchlist
- [ ] Tap stock to view details
- [ ] Change chart timeframes
- [ ] Touch chart to see price details
- [ ] Swipe to delete stock from watchlist
- [ ] Test with no internet connection (error handling)

### Sample Test Stocks

- **AAPL** - Apple Inc.
- **GOOGL** - Alphabet Inc.
- **MSFT** - Microsoft Corporation
- **NVDA** - NVIDIA Corporation
- **TSLA** - Tesla, Inc.
- **AMZN** - Amazon.com Inc.
- **META** - Meta Platforms Inc.

## 🔧 Troubleshooting

### "Missing API Key" Error
- Ensure your Polygon.io API key is set via environment variable or Config.plist
- Verify the key is correct by testing it at [polygon.io](https://polygon.io/dashboard)

### "Rate Limit Exceeded" Error
- Free tier has 5 calls/minute limit
- Wait a minute before making more requests
- Consider upgrading to a paid plan for production use

### Charts Not Loading
- Check internet connection
- Verify API key is valid
- Check Xcode console for detailed error messages

### Build Errors
- Ensure you're using Xcode 15.0+ with iOS 17+ SDK
- Clean build folder (Cmd+Shift+K)
- Delete derived data

## 📝 Development Notes

### Architecture Decisions

1. **MVVM Pattern**: Clear separation of concerns, testable business logic
2. **Actor for API Service**: Thread-safe caching and network calls
3. **Async/Await**: Modern Swift concurrency for clean async code
4. **Combine**: Reactive state management in ViewModels
5. **Swift Charts**: Native charting framework for performance

### Code Style

- SwiftLint compatible (ready for linting)
- Comprehensive documentation comments
- Proper error handling throughout
- Accessibility labels on all interactive elements

## 🚀 Next Steps

### Phase 2 - Core Features
- Implement Core Data for persistence
- Enhanced chart interactions (pinch to zoom, pan)
- Real-time price updates (WebSocket)
- Multiple watchlists

### Phase 3 - AI Integration
- Technical indicators calculation (RSI, MACD, Moving Averages)
- Apple Intelligence integration for on-device analysis
- Gemini API integration as fallback
- AI-powered insights and recommendations

### Phase 4 - Notes & Polish
- Rich text note editor
- Link notes to stocks and analyses
- Tag system with AI suggestions
- Export and sharing features

### Phase 5 - Launch
- Comprehensive unit and UI tests
- Performance optimization
- App Store assets and screenshots
- Beta testing via TestFlight

## 📄 License

This is a development project. Add your license here.

## 🤝 Contributing

This is currently a solo project. Contribution guidelines to be added.

## 📧 Contact

Add your contact information here.

---

**Built with ❤️ using SwiftUI**
# pulse-ios-app
# pulse-ios-app
