# 🤖 AutoTraderBot - MQL5 Expert Advisor

Bot giao dịch tự động hoàn toàn có thể tùy chỉnh cho MetaTrader 5 với **8 chiến lược giao dịch** (bao gồm **AI-powered**), **quản lý rủi ro nâng cao**, và **thông báo Telegram**.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![MQL5](https://img.shields.io/badge/MQL5-Expert%20Advisor-blue)](https://www.mql5.com)
[![Telegram](https://img.shields.io/badge/Telegram-Notifications-26A5E4?logo=telegram)](https://telegram.org)
[![AI](https://img.shields.io/badge/AI-Powered-ff6f00?logo=openai)](https://openai.com)

---

## ✨ Tính năng chính

### 📊 8 Chiến lược giao dịch
| Chiến lược | Mô tả | Indicators |
|-----------|-------|------------|
| **Trend Following** | Theo xu hướng thị trường | MA Crossover + ADX filter |
| **Scalping** | Giao dịch ngắn hạn, lợi nhuận nhỏ | RSI + Bollinger Bands |
| **Breakout** | Phá vỡ vùng hỗ trợ/kháng cự | Donchian Channel + ADX |
| **Mean Reversion** | Quay về giá trị trung bình | RSI bounce + BB bounce |
| **Grid Trading** | Đặt lệnh theo lưới giá | Grid spacing + MA direction |
| **Custom** | Tùy chỉnh theo ý bạn | 5 sub-strategies ⬇️ |
| **🤖 AI Only** | AI quyết định 100% | OpenAI / Gemini / Claude / DeepSeek |
| **🤖 AI Hybrid** | Technical + AI xác nhận | AI confirmation filter ⭐ |

#### Custom Sub-Strategies
- **MA + RSI Combo** - Kết hợp Moving Average và RSI với tham số tùy chỉnh
- **MACD + Bollinger Bands** - MACD crossover kết hợp vị trí giá so với BB
- **ADX + Stochastic** - Sức mạnh xu hướng + timing entry
- **Ichimoku Cloud** - Tenkan/Kijun cross với Cloud filter
- **Multi-Timeframe MA** - MA trên 2 khung thời gian phải đồng thuận

### 💰 Quản lý rủi ro toàn diện
- ✅ **Lot Sizing**: Fixed / % Balance / % Equity
- ✅ **Stop Loss / Take Profit**: Tính theo pips hoặc Risk:Reward ratio
- ✅ **Trailing Stop**: Tự động di chuyển SL theo lợi nhuận
- ✅ **Break Even**: Tự động chuyển SL về điểm hòa vốn
- ✅ **Max Orders**: Giới hạn số lệnh đồng thời
- ✅ **Daily Loss Limit**: Dừng giao dịch khi lỗ quá mức trong ngày
- ✅ **Max Drawdown**: Bảo vệ tài khoản khỏi drawdown lớn

### 🔔 Thông báo đa kênh
- 📱 **Telegram** - Thông báo chi tiết với emoji và HTML formatting
- 📧 **Email** - Gửi email khi có sự kiện quan trọng
- 🔊 **Sound Alert** - Phát âm thanh cảnh báo
- 📲 **MT5 Push Notification** - Thông báo đẩy trên mobile

### 📈 Dashboard trực quan
Dashboard hiển thị trên chart với thông tin real-time:
- Chiến lược đang sử dụng
- Balance / Equity / Free Margin
- Daily P/L và Floating P/L
- Số lệnh đang mở (Buy/Sell)
- Drawdown hiện tại
- Spread và trạng thái bot

### ⚙️ Bộ lọc giao dịch
- ⏰ **Time Filter** - Chỉ giao dịch trong khung giờ nhất định
- 📅 **Day Filter** - Chọn ngày trong tuần để giao dịch
- 📊 **Spread Filter** - Tránh giao dịch khi spread quá cao

---

## 📁 Cấu trúc dự án

```
mql5/
├── AutoTraderBot.mq5      # Main EA file (v2.00)
├── Settings.mqh           # 60+ input parameters
├── Strategy.mqh           # 8 trading strategies + 5 custom
├── AIStrategy.mqh         # 🤖 AI-powered strategy (NEW)
├── Indicators.mqh         # Indicator wrappers (MA, RSI, BB, MACD, ADX, Stoch, Ichimoku)
├── RiskManager.mqh        # Risk management & lot sizing
├── TradeManager.mqh       # Trade execution, trailing stop, break even
├── Utils.mqh              # Telegram, notifications, filters
└── Dashboard.mqh          # On-chart dashboard (with AI status)
```

---

## 🚀 Cài đặt

### Bước 1: Clone repository
```bash
git clone https://github.com/jonathanvirgo/mql5.git
```

### Bước 2: Copy files vào MetaTrader 5
1. Mở thư mục **Data Folder** của MT5: `File → Open Data Folder`
2. Copy toàn bộ files vào: `MQL5/Experts/AutoTraderBot/`

### Bước 3: Compile trong MetaEditor
1. Mở **MetaEditor** (F4 trong MT5)
2. Mở file `AutoTraderBot.mq5`
3. Nhấn **F7** để compile
4. Đảm bảo **0 errors** trong tab **Errors**

### Bước 4: Attach EA vào chart
1. Trong MT5, kéo **AutoTraderBot** từ **Navigator** vào chart
2. Tick ✅ **Allow Algo Trading** (góc trên bên phải)
3. Cấu hình settings trong tab **Inputs**

---

## 📱 Cấu hình Telegram

### Bước 1: Tạo Telegram Bot
1. Mở Telegram, tìm [@BotFather](https://t.me/botfather)
2. Gửi lệnh `/newbot` và làm theo hướng dẫn
3. Copy **Bot Token** (dạng: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)

### Bước 2: Lấy Chat ID
1. Gửi một tin nhắn bất kỳ cho bot vừa tạo
2. Truy cập URL: `https://api.telegram.org/bot<TOKEN>/getUpdates`
   - Thay `<TOKEN>` bằng Bot Token của bạn
3. Tìm `"chat":{"id":123456789}` và copy số **Chat ID**

### Bước 3: Cấu hình trong MT5
1. Mở **Tools → Options → Expert Advisors**
2. Tick ✅ **Allow WebRequest for listed URL**
3. Thêm URL: `https://api.telegram.org`
4. Nhấn **OK**

### Bước 4: Nhập thông tin vào EA
Trong tab **Inputs** của EA:
- `InpUseTelegram` = **true**
- `InpTelegramToken` = Bot Token của bạn
- `InpTelegramChatID` = Chat ID của bạn
- `InpTgNotifyEntry` = **true** (thông báo khi mở lệnh)
- `InpTgNotifyExit` = **true** (thông báo khi đóng lệnh)
- `InpTgNotifyDaily` = **true** (báo cáo tổng kết hàng ngày)

---

## 🤖 Cấu hình AI Strategy

### Hỗ trợ 5 AI Provider
| Provider | Model mặc định | Free tier? |
|----------|----------------|------------|
| **Gemini** | `gemini-2.0-flash` | ✅ Có |
| **OpenAI** | `gpt-4o-mini` | ❌ |
| **Claude** | `claude-sonnet-4-20250514` | ❌ |
| **DeepSeek** | `deepseek-chat` | ❌ |
| **Custom URL** | Tùy chỉnh | Tùy |

### Bước 1: Lấy API Key
- **Gemini (recommend)**: [ai.google.dev](https://ai.google.dev/) → Create API Key (miễn phí)
- **OpenAI**: [platform.openai.com](https://platform.openai.com/) → API Keys
- **Claude**: [console.anthropic.com](https://console.anthropic.com/) → API Keys
- **DeepSeek**: [platform.deepseek.com](https://platform.deepseek.com/) → API Keys

### Bước 2: Whitelist URL trong MT5
1. **Tools → Options → Expert Advisors → Allow WebRequest**
2. Thêm URL tương ứng:
   - Gemini: `https://generativelanguage.googleapis.com`
   - OpenAI: `https://api.openai.com`
   - Claude: `https://api.anthropic.com`
   - DeepSeek: `https://api.deepseek.com`

### Bước 3: Cấu hình trong EA
```
Strategy: AI Hybrid (recommended) hoặc AI Only
AI Provider: Google Gemini
API Key: <your-api-key>
Model Name: gemini-2.0-flash
Min Confidence: 60%
Cooldown: 60 (seconds)
Hybrid Base Strategy: Trend Following
```

### Cách AI hoạt động
1. **AI Only**: Bot gửi dữ liệu thị trường (OHLC + indicators) đến AI → AI trả về BUY/SELL/HOLD
2. **AI Hybrid** ⭐: Technical indicators tạo tín hiệu trước → AI chỉ xác nhận/từ chối → Giảm false signals

### Chi phí ước tính (Gemini Flash)
- H1: ~24 calls/ngày → **~$0.72/tháng**
- H4: ~6 calls/ngày → **~$0.18/tháng**

---

## ⚙️ Cấu hình Settings

Khi attach EA, bạn sẽ thấy panel settings được chia thành các nhóm:

### 🎯 General Settings
- **Strategy** - Chọn 1 trong 8 chiến lược (bao gồm AI)
- **Magic Number** - Số định danh duy nhất cho EA
- **Timeframe** - Khung thời gian giao dịch

### 🔧 Custom Strategy (nếu chọn Custom)
- **Custom Signal Type** - Chọn sub-strategy
- **Custom Param 1/2/3** - Tham số tùy chỉnh
- **Custom Level 1/2** - Ngưỡng tùy chỉnh

### 📊 Indicators
Mỗi indicator có các tham số riêng:
- **Moving Average**: Fast/Slow Period, Method, Applied Price
- **RSI**: Period, Overbought/Oversold levels
- **Bollinger Bands**: Period, Deviation
- **MACD**: Fast/Slow/Signal periods
- **ADX**: Period, Threshold
- **Donchian**: Period
- **Stochastic**: K/D Period, Slowing, Upper/Lower levels

### 💰 Risk Management
- **Lot Mode** - Fixed / % Balance / % Equity
- **Lot Size** - Kích thước lot (nếu Fixed)
- **Risk Percent** - % rủi ro (nếu % mode)
- **Max/Min Lot Size** - Giới hạn lot

### 🎯 Stop Loss / Take Profit
- **Use SL/TP** - Bật/tắt SL/TP
- **SL Pips** - Stop Loss tính theo pips
- **TP Pips** - Take Profit tính theo pips
- **Risk:Reward Ratio** - Tỷ lệ R:R (0 = dùng TP pips)

### 📈 Trailing Stop
- **Use Trailing** - Bật/tắt trailing stop
- **Trailing Start** - Bắt đầu trail sau X pips profit
- **Trailing Stop** - Khoảng cách SL theo giá
- **Trailing Step** - Bước di chuyển tối thiểu

### 🎲 Break Even
- **Use Break Even** - Bật/tắt break even
- **BE Pips** - Chuyển BE sau X pips profit
- **BE Lock Pips** - Khóa lợi nhuận X pips

### 📊 Order Limits
- **Max Orders** - Tổng số lệnh tối đa
- **Max Buy/Sell Orders** - Giới hạn theo hướng
- **Max Daily Loss** - Lỗ tối đa trong ngày ($)
- **Max Drawdown** - Drawdown tối đa (%)

### 🌐 Grid Settings (nếu dùng Grid strategy)
- **Grid Spacing** - Khoảng cách giữa các lệnh (pips)
- **Grid Max Levels** - Số tầng grid tối đa
- **Grid Multiplier** - Hệ số nhân lot

### ⏰ Trade Filters
- **Use Time Filter** - Bật/tắt lọc giờ
- **Start/End Hour** - Giờ bắt đầu/kết thúc giao dịch
- **Trade Monday/Tuesday/...** - Chọn ngày giao dịch
- **Max Spread** - Spread tối đa cho phép (points)

### 🔔 Notifications
- **Use Push/Email/Sound** - Bật/tắt từng loại thông báo
- **Sound File** - File âm thanh cảnh báo

### 📱 Telegram
- **Use Telegram** - Bật/tắt Telegram
- **Telegram Token** - Bot Token
- **Telegram Chat ID** - Chat ID
- **Notify Entry/Exit/Daily** - Chọn loại thông báo

### 📊 Dashboard
- **Show Dashboard** - Hiển thị dashboard trên chart
- **Dash X/Y** - Vị trí dashboard
- **Dash Color** - Màu chữ
- **Dash Bg Color** - Màu nền
- **Dash Font Size** - Kích thước font

### 🤖 AI Strategy
- **AI Provider** - Chọn OpenAI / Gemini / Claude / DeepSeek / Custom
- **API Key** - API key của provider
- **Model Name** - Tên model AI
- **Custom API URL** - URL cho Custom provider
- **Min Confidence %** - Ngưỡng confidence tối thiểu (0-100)
- **Candles to Send** - Số nến gửi cho AI phân tích
- **API Timeout** - Thời gian chờ response (giây)
- **Cooldown** - Thời gian tối thiểu giữa các lần gọi API (giây)
- **Hybrid Base Strategy** - Chiến lược technical cho mode Hybrid
- **Send AI to Telegram** - Gửi phân tích AI qua Telegram

---

## 📖 Ví dụ cấu hình

### Cấu hình 1: Scalping EURUSD M5
```
Strategy: Scalping
Timeframe: M5
Lot Mode: Percent of Balance
Risk Percent: 1.0%
SL Pips: 20
TP Pips: 40
Use Trailing: true
Trailing Start: 25
Trailing Stop: 15
Max Orders: 3
Time Filter: 08:00 - 20:00 (London + NY session)
```

### Cấu hình 2: Trend Following XAUUSD H1
```
Strategy: Trend Following
Timeframe: H1
Lot Mode: Fixed
Lot Size: 0.01
SL Pips: 50
TP Pips: 150 (R:R = 3:1)
Use Break Even: true
BE Pips: 30
Max Orders: 2
ADX Threshold: 25
```

### Cấu hình 3: Grid Trading GBPUSD M15
```
Strategy: Grid
Timeframe: M15
Lot Mode: Fixed
Lot Size: 0.01
Grid Spacing: 30 pips
Grid Max Levels: 5
Grid Multiplier: 1.5
Max Orders: 5
```

### Cấu hình 4: AI Hybrid XAUUSD H1 (với Gemini)
```
Strategy: AI Hybrid
Timeframe: H1
AI Provider: Google Gemini
API Key: <your-gemini-key>
Model: gemini-2.0-flash
Min Confidence: 65%
Cooldown: 60s
Hybrid Base: Trend Following
Lot Mode: Percent of Balance
Risk Percent: 1.0%
SL Pips: 50
TP Pips: 100
```

---

## ⚠️ Cảnh báo quan trọng

> [!CAUTION]
> **LUÔN TEST TRÊN TÀI KHOẢN DEMO TRƯỚC KHI SỬ DỤNG TIỀN THẬT!**

> [!WARNING]
> - Giao dịch tự động có rủi ro cao
> - Không có chiến lược nào đảm bảo lợi nhuận 100%
> - Luôn sử dụng Stop Loss
> - Không giao dịch với số tiền bạn không thể mất
> - Backtest kỹ lưỡng trước khi chạy live

> [!IMPORTANT]
> - Kiểm tra VPS/Internet ổn định nếu chạy 24/7
> - Theo dõi bot thường xuyên trong giai đoạn đầu
> - Cập nhật settings phù hợp với từng cặp tiền
> - Đọc kỹ tài liệu MQL5 để hiểu rõ cách hoạt động

---

## 🧪 Testing & Optimization

### Strategy Tester trong MT5
1. Nhấn **Ctrl+R** để mở Strategy Tester
2. Chọn **AutoTraderBot** trong Expert Advisor
3. Chọn Symbol, Period, Date range
4. Chọn **Every tick** hoặc **1 minute OHLC** cho độ chính xác cao
5. Nhấn **Start** để chạy backtest

### Optimization
1. Trong Strategy Tester, chọn tab **Settings**
2. Tick ✅ **Optimization**
3. Chọn các parameters cần optimize (double-click vào value)
4. Chọn **Genetic Algorithm** để tối ưu nhanh
5. Nhấn **Start**

---

## 🤝 Đóng góp

Contributions, issues và feature requests đều được chào đón!

1. Fork repository
2. Tạo branch mới (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Mở Pull Request

---

## 📝 License

Dự án này được phân phối dưới giấy phép MIT. Xem file `LICENSE` để biết thêm chi tiết.

---

## 📧 Liên hệ

- GitHub: [@jonathanvirgo](https://github.com/jonathanvirgo)
- Repository: [https://github.com/jonathanvirgo/mql5](https://github.com/jonathanvirgo/mql5)

---

## 🙏 Credits

- Phát triển bởi: AutoTraderBot Team
- MQL5 Documentation: [https://www.mql5.com/en/docs](https://www.mql5.com/en/docs)
- Telegram Bot API: [https://core.telegram.org/bots/api](https://core.telegram.org/bots/api)

---

<div align="center">

**⭐ Nếu thấy hữu ích, hãy cho repo một star! ⭐**

Made with ❤️ for MQL5 traders

</div>
