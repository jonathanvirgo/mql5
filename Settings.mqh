//+------------------------------------------------------------------+
//|                                                     Settings.mqh |
//|                                          AutoTraderBot Settings  |
//|                        All configurable input parameters for EA  |
//+------------------------------------------------------------------+
#property copyright "AutoTraderBot"
#property link      ""
#property strict

//+------------------------------------------------------------------+
//| ENUMS                                                            |
//+------------------------------------------------------------------+

// Chiến lược giao dịch
enum ENUM_STRATEGY
{
   STRATEGY_TREND_FOLLOWING = 0,  // Trend Following (MA Crossover + ADX)
   STRATEGY_SCALPING        = 1,  // Scalping (RSI + Bollinger Bands)
   STRATEGY_BREAKOUT        = 2,  // Breakout (Donchian Channel)
   STRATEGY_MEAN_REVERSION  = 3,  // Mean Reversion (RSI + BB Bounce)
   STRATEGY_GRID            = 4,  // Grid Trading
   STRATEGY_CUSTOM          = 5   // Custom Strategy (User Defined)
};

// Phương pháp tính lot
enum ENUM_LOT_MODE
{
   LOT_FIXED   = 0,  // Fixed Lot
   LOT_PERCENT = 1,  // Percent of Balance
   LOT_EQUITY  = 2   // Percent of Equity
};

// Loại MA
enum ENUM_MA_TYPE
{
   MA_SMA  = 0,  // Simple MA
   MA_EMA  = 1,  // Exponential MA
   MA_SMMA = 2,  // Smoothed MA
   MA_LWMA = 3   // Linear Weighted MA
};

// Tín hiệu Custom Strategy
enum ENUM_CUSTOM_SIGNAL
{
   CUSTOM_MA_RSI       = 0,  // MA + RSI Combo
   CUSTOM_MACD_BB      = 1,  // MACD + Bollinger Bands
   CUSTOM_ADX_STOCH    = 2,  // ADX + Stochastic
   CUSTOM_ICHIMOKU     = 3,  // Ichimoku Cloud
   CUSTOM_MULTI_TF     = 4   // Multi-Timeframe MA
};

//+------------------------------------------------------------------+
//| GENERAL SETTINGS                                                 |
//+------------------------------------------------------------------+
input string           InpSep0            = "════════ GENERAL ════════";     // ══ General Settings ══
input ENUM_STRATEGY    InpStrategy        = STRATEGY_TREND_FOLLOWING;        // Strategy
input int              InpMagicNumber     = 123456;                          // Magic Number
input string           InpComment         = "AutoTraderBot";                 // Order Comment
input ENUM_TIMEFRAMES  InpTimeframe       = PERIOD_H1;                       // Timeframe

//+------------------------------------------------------------------+
//| CUSTOM STRATEGY SETTINGS                                         |
//+------------------------------------------------------------------+
input string           InpSepCustom       = "════════ CUSTOM STRATEGY ════════"; // ══ Custom Strategy ══
input ENUM_CUSTOM_SIGNAL InpCustomSignal  = CUSTOM_MA_RSI;                   // Custom Signal Type
input int              InpCustomParam1    = 14;                              // Custom Param 1
input int              InpCustomParam2    = 28;                              // Custom Param 2
input int              InpCustomParam3    = 7;                               // Custom Param 3
input double           InpCustomLevel1    = 30.0;                            // Custom Level 1
input double           InpCustomLevel2    = 70.0;                            // Custom Level 2
input ENUM_TIMEFRAMES  InpCustomTF2       = PERIOD_H4;                       // Custom 2nd Timeframe (Multi-TF)

//+------------------------------------------------------------------+
//| MA SETTINGS                                                      |
//+------------------------------------------------------------------+
input string           InpSep1            = "════════ MOVING AVERAGE ════════"; // ══ Moving Average ══
input int              InpMA_FastPeriod   = 10;                              // Fast MA Period
input int              InpMA_SlowPeriod   = 50;                              // Slow MA Period
input ENUM_MA_TYPE     InpMA_Method       = MA_EMA;                          // MA Method
input ENUM_APPLIED_PRICE InpMA_Price      = PRICE_CLOSE;                     // MA Applied Price

//+------------------------------------------------------------------+
//| RSI SETTINGS                                                     |
//+------------------------------------------------------------------+
input string           InpSep2            = "════════ RSI ════════";         // ══ RSI ══
input int              InpRSI_Period      = 14;                              // RSI Period
input double           InpRSI_Overbought  = 70.0;                           // RSI Overbought Level
input double           InpRSI_Oversold    = 30.0;                           // RSI Oversold Level

//+------------------------------------------------------------------+
//| BOLLINGER BANDS SETTINGS                                         |
//+------------------------------------------------------------------+
input string           InpSep3            = "════════ BOLLINGER BANDS ════════"; // ══ Bollinger Bands ══
input int              InpBB_Period       = 20;                              // BB Period
input double           InpBB_Deviation    = 2.0;                            // BB Deviation

//+------------------------------------------------------------------+
//| MACD SETTINGS                                                    |
//+------------------------------------------------------------------+
input string           InpSep4            = "════════ MACD ════════";        // ══ MACD ══
input int              InpMACD_Fast       = 12;                              // MACD Fast EMA
input int              InpMACD_Slow       = 26;                              // MACD Slow EMA
input int              InpMACD_Signal     = 9;                               // MACD Signal

//+------------------------------------------------------------------+
//| ADX SETTINGS                                                     |
//+------------------------------------------------------------------+
input string           InpSep5            = "════════ ADX ════════";         // ══ ADX ══
input int              InpADX_Period      = 14;                              // ADX Period
input double           InpADX_Threshold   = 25.0;                           // ADX Threshold (min trend strength)

//+------------------------------------------------------------------+
//| DONCHIAN CHANNEL SETTINGS                                        |
//+------------------------------------------------------------------+
input string           InpSep6            = "════════ DONCHIAN ════════";    // ══ Donchian Channel ══
input int              InpDonchian_Period = 20;                              // Donchian Period

//+------------------------------------------------------------------+
//| STOCHASTIC SETTINGS                                              |
//+------------------------------------------------------------------+
input string           InpSep6b           = "════════ STOCHASTIC ════════";  // ══ Stochastic ══
input int              InpStoch_KPeriod   = 5;                               // Stochastic %K Period
input int              InpStoch_DPeriod   = 3;                               // Stochastic %D Period
input int              InpStoch_Slowing   = 3;                               // Stochastic Slowing
input double           InpStoch_Upper     = 80.0;                            // Stochastic Upper Level
input double           InpStoch_Lower     = 20.0;                            // Stochastic Lower Level

//+------------------------------------------------------------------+
//| RISK MANAGEMENT                                                  |
//+------------------------------------------------------------------+
input string           InpSep7            = "════════ RISK MANAGEMENT ════════"; // ══ Risk Management ══
input ENUM_LOT_MODE    InpLotMode         = LOT_FIXED;                       // Lot Mode
input double           InpLotSize         = 0.01;                            // Fixed Lot Size
input double           InpRiskPercent     = 1.0;                             // Risk % (for Percent mode)
input double           InpMaxLotSize      = 10.0;                            // Max Lot Size
input double           InpMinLotSize      = 0.01;                            // Min Lot Size

//+------------------------------------------------------------------+
//| STOP LOSS / TAKE PROFIT                                          |
//+------------------------------------------------------------------+
input string           InpSep8            = "════════ SL / TP ════════";     // ══ Stop Loss / Take Profit ══
input bool             InpUseSL           = true;                            // Use Stop Loss
input double           InpSL_Pips         = 50.0;                            // Stop Loss (Pips)
input bool             InpUseTP           = true;                            // Use Take Profit
input double           InpTP_Pips         = 100.0;                           // Take Profit (Pips)
input double           InpRiskReward      = 0.0;                             // Risk:Reward Ratio (0=use TP pips)

//+------------------------------------------------------------------+
//| TRAILING STOP                                                    |
//+------------------------------------------------------------------+
input string           InpSep9            = "════════ TRAILING STOP ════════"; // ══ Trailing Stop ══
input bool             InpUseTrailing     = false;                           // Use Trailing Stop
input double           InpTrailingStart   = 30.0;                            // Trailing Start (Pips in profit)
input double           InpTrailingStop    = 20.0;                            // Trailing Stop (Pips)
input double           InpTrailingStep    = 5.0;                             // Trailing Step (Pips)

//+------------------------------------------------------------------+
//| BREAK EVEN                                                       |
//+------------------------------------------------------------------+
input string           InpSep10           = "════════ BREAK EVEN ════════";  // ══ Break Even ══
input bool             InpUseBreakEven    = false;                           // Use Break Even
input double           InpBE_Pips         = 20.0;                            // Break Even After (Pips profit)
input double           InpBE_LockPips     = 2.0;                             // Lock Profit (Pips above entry)

//+------------------------------------------------------------------+
//| ORDER LIMITS                                                     |
//+------------------------------------------------------------------+
input string           InpSep11           = "════════ ORDER LIMITS ════════"; // ══ Order Limits ══
input int              InpMaxOrders       = 3;                               // Max Open Orders
input int              InpMaxBuyOrders    = 2;                               // Max Buy Orders (0=unlimited)
input int              InpMaxSellOrders   = 2;                               // Max Sell Orders (0=unlimited)
input double           InpMaxDailyLoss    = 0.0;                             // Max Daily Loss $ (0=disabled)
input double           InpMaxDrawdown     = 0.0;                             // Max Drawdown % (0=disabled)

//+------------------------------------------------------------------+
//| GRID SETTINGS                                                    |
//+------------------------------------------------------------------+
input string           InpSep12           = "════════ GRID ════════";        // ══ Grid Settings ══
input double           InpGridSpacing     = 30.0;                            // Grid Spacing (Pips)
input int              InpGridMaxLevels   = 5;                               // Grid Max Levels
input double           InpGridMultiplier  = 1.0;                             // Grid Lot Multiplier

//+------------------------------------------------------------------+
//| TRADE FILTERS                                                    |
//+------------------------------------------------------------------+
input string           InpSep13           = "════════ TRADE FILTERS ════════"; // ══ Trade Filters ══
input bool             InpUseTimeFilter   = false;                           // Use Time Filter
input int              InpStartHour       = 8;                               // Trading Start Hour (Server time)
input int              InpEndHour         = 20;                              // Trading End Hour (Server time)
input bool             InpTradeMonday     = true;                            // Trade on Monday
input bool             InpTradeTuesday    = true;                            // Trade on Tuesday
input bool             InpTradeWednesday  = true;                            // Trade on Wednesday
input bool             InpTradeThursday   = true;                            // Trade on Thursday
input bool             InpTradeFriday     = true;                            // Trade on Friday
input double           InpMaxSpread       = 0.0;                             // Max Spread (Points, 0=no limit)

//+------------------------------------------------------------------+
//| NOTIFICATIONS                                                    |
//+------------------------------------------------------------------+
input string           InpSep14           = "════════ NOTIFICATIONS ════════"; // ══ Notifications ══
input bool             InpUsePush         = false;                           // Send Push Notification
input bool             InpUseEmail        = false;                           // Send Email
input bool             InpUseSound        = true;                            // Play Sound
input string           InpSoundFile       = "alert.wav";                     // Sound File

//+------------------------------------------------------------------+
//| TELEGRAM SETTINGS                                                |
//+------------------------------------------------------------------+
input string           InpSep15           = "════════ TELEGRAM ════════";    // ══ Telegram ══
input bool             InpUseTelegram     = false;                           // Send Telegram Notification
input string           InpTelegramToken   = "";                              // Bot Token
input string           InpTelegramChatID  = "";                              // Chat ID
input bool             InpTgNotifyEntry   = true;                            // Notify on Entry
input bool             InpTgNotifyExit    = true;                            // Notify on Exit
input bool             InpTgNotifyDaily   = false;                           // Daily Summary Report

//+------------------------------------------------------------------+
//| DASHBOARD                                                        |
//+------------------------------------------------------------------+
input string           InpSep16           = "════════ DASHBOARD ════════";   // ══ Dashboard ══
input bool             InpShowDashboard   = true;                            // Show Dashboard on Chart
input int              InpDashX           = 10;                              // Dashboard X Position
input int              InpDashY           = 30;                              // Dashboard Y Position
input color            InpDashColor       = clrWhite;                        // Dashboard Text Color
input color            InpDashBgColor     = C'20,20,30';                     // Dashboard Background Color
input int              InpDashFontSize    = 9;                               // Dashboard Font Size
