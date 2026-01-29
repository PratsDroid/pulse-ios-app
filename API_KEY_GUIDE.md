# API Key Configuration Guide

## How the API Key System Works

Your Pulse app uses a **hybrid multi-provider strategy** for optimal performance:

1. **Config.plist** (if it exists) ← **EASIEST METHOD**
2. **Environment Variable** (fallback)

## 🎯 Hybrid Provider Strategy

The app intelligently selects the best provider for each request:

| Request Type | Primary | Fallback 1 | Fallback 2 |
|-------------|---------|------------|------------|
| **Stock Quotes** | Finnhub (60/min) | Twelve Data | Polygon |
| **Historical Charts** | Twelve Data | Polygon | - |
| **Technical Indicators** | Twelve Data | - | - |
| **Search** | Finnhub | Twelve Data | Polygon |

## Supported API Providers

### **Finnhub** (Primary for Quotes)
- **Purpose**: Real-time stock quotes, company profiles, search
- **Free Tier**: 60 calls/minute (very generous!)
- **Best For**: Watchlist updates, real-time prices
- **Limitation**: No historical candles on free tier

### **Twelve Data** (Primary for Charts)
- **Purpose**: Historical data, technical indicators
- **Free Tier**: 8 calls/minute, 800 calls/day
- **Best For**: Stock charts, RSI, MACD, technical analysis
- **Exclusive**: 100+ built-in technical indicators

### **Polygon.io** (Fallback)
- **Purpose**: Backup provider
- **Free Tier**: 5 calls/minute
- **Best For**: Emergency fallback when others fail

## Code Location

The API keys are fetched in [`Utilities/Constants.swift`](file:///Users/sonu/Code/Pulse/Pulse/Utilities/Constants.swift)

## ✅ Method 1: Config.plist (RECOMMENDED)

### Steps:
1. Open `Config.plist` in Xcode
2. Add your API keys:
   - `FINNHUB_API_KEY` - Get free key from [finnhub.io](https://finnhub.io/register)
   - `TWELVE_DATA_API_KEY` - Get free key from [twelvedata.com](https://twelvedata.com/register)
   - `POLYGON_API_KEY` - (Optional) From [polygon.io](https://polygon.io)
   - `GEMINI_API_KEY` - (Optional) From [Google AI Studio](https://makersuite.google.com/app/apikey)
3. Make sure it's checked under **Target Membership** in File Inspector
4. That's it!

**File location**: `/Users/sonu/Code/Pulse/Pulse/Config.plist`

**⚠️ Important**: Add `Config.plist` to `.gitignore`:
```bash
echo "Config.plist" >> .gitignore
```

## Method 2: Xcode Scheme Environment Variables

1. **Product → Scheme → Edit Scheme** (or `Cmd+<`)
2. Select **Run** → **Arguments** tab
3. Under "Environment Variables", add:
   - `FINNHUB_API_KEY` = your_finnhub_key
   - `POLYGON_API_KEY` = your_polygon_key (optional)
   - `GEMINI_API_KEY` = your_gemini_key (optional)

## Getting API Keys

### Finnhub (Primary Provider)
1. Sign up at [finnhub.io/register](https://finnhub.io/register)
2. Go to dashboard to get your API key
3. **Free tier**: 60 API calls/minute (real-time data!)

### Polygon.io (Fallback)
1. Sign up at [polygon.io](https://polygon.io)
2. Get API key from dashboard
3. **Free tier**: 5 calls/minute

### Gemini AI (For Analysis)
1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create API key
3. **Free tier**: 60 requests/minute

## How It's Used in Code

The API key is accessed throughout the app via:

```swift
Constants.API.polygonAPIKey
```

**Used in:**
- [`Services/API/PolygonAPIService.swift`](file:///Users/sonu/Code/Pulse/Pulse/Services/API/PolygonAPIService.swift) - Line 9

Example:
```swift
private var apiKey: String {
    Constants.API.polygonAPIKey  // ← Fetches from Config.plist or env var
}
```

Then used in API calls:
```swift
let url = "\(baseURL)/v2/aggs/ticker/\(ticker)/prev?apiKey=\(apiKey)"
```

## Verify It's Working

Build and run your app. If you see stock data, the API key is working! ✅

If you see "Missing API Key" error:
1. Check that `Config.plist` is added to your Xcode target
2. Or set the environment variable in Xcode scheme
3. Clean build folder (`Cmd+Shift+K`) and rebuild

## Your Current Setup

✅ **Config.plist created** with your API key  
✅ **Constants.swift updated** to read from Config.plist  
✅ **Ready to use!**

Just make sure `Config.plist` is added to your Xcode project target and you're all set!
