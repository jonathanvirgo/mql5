//+------------------------------------------------------------------+
//|                                                   AIStrategy.mqh |
//|                      AI-Powered Trading Strategy                 |
//|                 Calls AI API for trade confirmation             |
//+------------------------------------------------------------------+
#property copyright "AutoTraderBot"
#property strict

//+------------------------------------------------------------------+
//| AI response cache                                                |
//+------------------------------------------------------------------+
int    g_aiLastSignal      = SIGNAL_NONE;
int    g_aiLastConfidence   = 0;
string g_aiLastReason       = "";
datetime g_aiLastCallTime   = 0;
bool   g_aiAvailable        = true;

//+------------------------------------------------------------------+
//| Build market data string for AI prompt                           |
//+------------------------------------------------------------------+
string BuildMarketData(string symbol, ENUM_TIMEFRAMES tf, int candles = 10)
{
   double open[], high[], low[], close[];
   long   volume[];
   
   if(CopyOpen(symbol, tf, 1, candles, open)   != candles) return "";
   if(CopyHigh(symbol, tf, 1, candles, high)   != candles) return "";
   if(CopyLow(symbol, tf, 1, candles, low)     != candles) return "";
   if(CopyClose(symbol, tf, 1, candles, close) != candles) return "";
   if(CopyTickVolume(symbol, tf, 1, candles, volume) != candles) return "";
   
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   
   string data = "";
   
   // OHLC data as comma-separated
   data += "OHLCV (newest first):\n";
   for(int i = candles - 1; i >= 0; i--)
   {
      data += "  " + DoubleToString(open[i], digits) + ", " 
                   + DoubleToString(high[i], digits) + ", "
                   + DoubleToString(low[i], digits) + ", "
                   + DoubleToString(close[i], digits) + ", "
                   + IntegerToString(volume[i]) + "\n";
   }
   
   return data;
}

//+------------------------------------------------------------------+
//| Build indicator summary for AI                                   |
//+------------------------------------------------------------------+
string BuildIndicatorSummary()
{
   string ind = "INDICATORS:\n";
   
   ind += "  MA(" + IntegerToString(InpMA_FastPeriod) + "): " + DoubleToString(GetMA_Fast(1), 5) + "\n";
   ind += "  MA(" + IntegerToString(InpMA_SlowPeriod) + "): " + DoubleToString(GetMA_Slow(1), 5) + "\n";
   ind += "  RSI(" + IntegerToString(InpRSI_Period) + "): " + DoubleToString(GetRSI(1), 1) + "\n";
   ind += "  MACD: " + DoubleToString(GetMACD_Main(1), 6) + " Signal: " + DoubleToString(GetMACD_Signal(1), 6) + "\n";
   ind += "  ADX: " + DoubleToString(GetADX(1), 1) + " +DI: " + DoubleToString(GetADX_PlusDI(1), 1) + " -DI: " + DoubleToString(GetADX_MinusDI(1), 1) + "\n";
   ind += "  BB Upper: " + DoubleToString(GetBB_Upper(1), 5) + " Mid: " + DoubleToString(GetBB_Middle(1), 5) + " Lower: " + DoubleToString(GetBB_Lower(1), 5) + "\n";
   ind += "  Stoch K: " + DoubleToString(GetStoch_K(1), 1) + " D: " + DoubleToString(GetStoch_D(1), 1) + "\n";
   
   return ind;
}

//+------------------------------------------------------------------+
//| Build the AI prompt                                              |
//+------------------------------------------------------------------+
string BuildAIPrompt(string symbol, ENUM_TIMEFRAMES tf)
{
   string marketData = BuildMarketData(symbol, tf, InpAI_Candles);
   string indicators = BuildIndicatorSummary();
   
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double spread = (double)SymbolInfoInteger(symbol, SYMBOL_SPREAD);
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   
   string prompt = "";
   
   prompt += "You are a professional forex/crypto trading analyst. ";
   prompt += "Analyze the market data and provide a trading signal.\n\n";
   
   prompt += "SYMBOL: " + symbol + "\n";
   prompt += "TIMEFRAME: " + EnumToString(tf) + "\n";
   prompt += "CURRENT BID: " + DoubleToString(bid, digits) + "\n";
   prompt += "CURRENT ASK: " + DoubleToString(ask, digits) + "\n";
   prompt += "SPREAD: " + DoubleToString(spread, 0) + " points\n\n";
   
   prompt += marketData + "\n";
   prompt += indicators + "\n";
   
   prompt += "Based on the data above, provide your analysis.\n";
   prompt += "Respond in EXACTLY this format (nothing else):\n";
   prompt += "ACTION: BUY or SELL or HOLD\n";
   prompt += "CONFIDENCE: 0 to 100\n";
   prompt += "REASON: one line reason\n";
   
   return prompt;
}

//+------------------------------------------------------------------+
//| Build JSON request body for different AI providers               |
//+------------------------------------------------------------------+
string BuildRequestBody(string prompt)
{
   string body = "";
   
   // Escape special characters in prompt for JSON
   string escapedPrompt = prompt;
   StringReplace(escapedPrompt, "\\", "\\\\");
   StringReplace(escapedPrompt, "\"", "\\\"");
   StringReplace(escapedPrompt, "\n", "\\n");
   StringReplace(escapedPrompt, "\r", "");
   StringReplace(escapedPrompt, "\t", "\\t");
   
   switch(InpAI_Provider)
   {
      case AI_OPENAI:
         body = "{\"model\":\"" + InpAI_Model + "\","
                "\"messages\":[{\"role\":\"user\",\"content\":\"" + escapedPrompt + "\"}],"
                "\"max_tokens\":150,\"temperature\":0.3}";
         break;
         
      case AI_GEMINI:
         body = "{\"contents\":[{\"parts\":[{\"text\":\"" + escapedPrompt + "\"}]}],"
                "\"generationConfig\":{\"maxOutputTokens\":150,\"temperature\":0.3}}";
         break;
         
      case AI_CLAUDE:
         body = "{\"model\":\"" + InpAI_Model + "\","
                "\"max_tokens\":150,"
                "\"messages\":[{\"role\":\"user\",\"content\":\"" + escapedPrompt + "\"}]}";
         break;
         
      case AI_DEEPSEEK:
         body = "{\"model\":\"" + InpAI_Model + "\","
                "\"messages\":[{\"role\":\"user\",\"content\":\"" + escapedPrompt + "\"}],"
                "\"max_tokens\":150,\"temperature\":0.3}";
         break;
         
      case AI_CUSTOM_URL:
         // OpenAI-compatible format (most local servers use this)
         body = "{\"model\":\"" + InpAI_Model + "\","
                "\"messages\":[{\"role\":\"user\",\"content\":\"" + escapedPrompt + "\"}],"
                "\"max_tokens\":150,\"temperature\":0.3}";
         break;
   }
   
   return body;
}

//+------------------------------------------------------------------+
//| Get API URL for the selected provider                            |
//+------------------------------------------------------------------+
string GetAIApiUrl()
{
   switch(InpAI_Provider)
   {
      case AI_OPENAI:
         return "https://api.openai.com/v1/chat/completions";
         
      case AI_GEMINI:
         return "https://generativelanguage.googleapis.com/v1beta/models/" 
                + InpAI_Model + ":generateContent?key=" + InpAI_ApiKey;
         
      case AI_CLAUDE:
         return "https://api.anthropic.com/v1/messages";
         
      case AI_DEEPSEEK:
         return "https://api.deepseek.com/v1/chat/completions";
         
      case AI_CUSTOM_URL:
         return InpAI_CustomURL;
   }
   
   return "";
}

//+------------------------------------------------------------------+
//| Build HTTP headers for the selected provider                     |
//+------------------------------------------------------------------+
string GetAIHeaders()
{
   string headers = "Content-Type: application/json\r\n";
   
   switch(InpAI_Provider)
   {
      case AI_OPENAI:
         headers += "Authorization: Bearer " + InpAI_ApiKey + "\r\n";
         break;
      
      case AI_GEMINI:
         // API key is in URL for Gemini
         break;
         
      case AI_CLAUDE:
         headers += "x-api-key: " + InpAI_ApiKey + "\r\n";
         headers += "anthropic-version: 2023-06-01\r\n";
         break;
         
      case AI_DEEPSEEK:
         headers += "Authorization: Bearer " + InpAI_ApiKey + "\r\n";
         break;
         
      case AI_CUSTOM_URL:
         if(InpAI_ApiKey != "")
            headers += "Authorization: Bearer " + InpAI_ApiKey + "\r\n";
         break;
   }
   
   return headers;
}

//+------------------------------------------------------------------+
//| Call AI API and get response                                     |
//+------------------------------------------------------------------+
string CallAIApi(string symbol, ENUM_TIMEFRAMES tf)
{
   string prompt = BuildAIPrompt(symbol, tf);
   string body   = BuildRequestBody(prompt);
   string url    = GetAIApiUrl();
   string headers = GetAIHeaders();
   
   if(url == "")
   {
      Print("AI ERROR: Invalid provider URL");
      return "";
   }
   
   // Convert body string to char array
   char bodyData[];
   StringToCharArray(body, bodyData, 0, StringLen(body), CP_UTF8);
   
   // Remove null terminator that StringToCharArray adds
   if(ArraySize(bodyData) > 0 && bodyData[ArraySize(bodyData) - 1] == 0)
      ArrayResize(bodyData, ArraySize(bodyData) - 1);
   
   char   result[];
   string resultHeaders;
   
   int timeout = InpAI_Timeout * 1000;
   
   LogMessage("AI: Calling " + EnumToString(InpAI_Provider) + " API...");
   
   int res = WebRequest("POST", url, headers, timeout, bodyData, result, resultHeaders);
   
   if(res == -1)
   {
      int error = GetLastError();
      if(error == 4014)
      {
         Print("AI ERROR: Add the AI API URL to Tools > Options > Expert Advisors > Allow WebRequest");
         Print("AI ERROR: URL needed: ", url);
      }
      else
      {
         Print("AI ERROR: WebRequest failed, error=", error);
      }
      g_aiAvailable = false;
      return "";
   }
   
   string response = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
   
   if(res != 200)
   {
      Print("AI ERROR: HTTP ", res, " Response: ", StringSubstr(response, 0, 500));
      g_aiAvailable = false;
      return "";
   }
   
   g_aiAvailable = true;
   return response;
}

//+------------------------------------------------------------------+
//| Extract text content from AI response JSON                       |
//+------------------------------------------------------------------+
string ExtractAIContent(string response)
{
   string content = "";
   
   switch(InpAI_Provider)
   {
      case AI_OPENAI:
      case AI_DEEPSEEK:
      case AI_CUSTOM_URL:
      {
         // Find "content":"..." in the response
         int pos = StringFind(response, "\"content\":");
         if(pos >= 0)
         {
            // Skip to the opening quote of the value
            pos = StringFind(response, "\"", pos + 10);
            if(pos >= 0)
            {
               pos++; // Skip opening quote
               int endPos = FindUnescapedQuote(response, pos);
               if(endPos > pos)
               {
                  content = StringSubstr(response, pos, endPos - pos);
               }
            }
         }
         break;
      }
      
      case AI_GEMINI:
      {
         // Gemini: find "text":"..." 
         int pos = StringFind(response, "\"text\":");
         if(pos >= 0)
         {
            pos = StringFind(response, "\"", pos + 7);
            if(pos >= 0)
            {
               pos++;
               int endPos = FindUnescapedQuote(response, pos);
               if(endPos > pos)
               {
                  content = StringSubstr(response, pos, endPos - pos);
               }
            }
         }
         break;
      }
      
      case AI_CLAUDE:
      {
         // Claude: find "text":"..." inside content array
         int pos = StringFind(response, "\"text\":");
         if(pos >= 0)
         {
            pos = StringFind(response, "\"", pos + 7);
            if(pos >= 0)
            {
               pos++;
               int endPos = FindUnescapedQuote(response, pos);
               if(endPos > pos)
               {
                  content = StringSubstr(response, pos, endPos - pos);
               }
            }
         }
         break;
      }
   }
   
   // Unescape JSON string
   StringReplace(content, "\\n", "\n");
   StringReplace(content, "\\\"", "\"");
   StringReplace(content, "\\\\", "\\");
   StringReplace(content, "\\t", "\t");
   
   return content;
}

//+------------------------------------------------------------------+
//| Find next unescaped quote in string                              |
//+------------------------------------------------------------------+
int FindUnescapedQuote(string text, int startPos)
{
   int len = StringLen(text);
   for(int i = startPos; i < len; i++)
   {
      if(StringGetCharacter(text, i) == '"')
      {
         // Check if escaped
         if(i > 0 && StringGetCharacter(text, i - 1) == '\\')
         {
            // Check if the backslash itself is escaped
            if(i > 1 && StringGetCharacter(text, i - 2) == '\\')
               return i; // Double escaped = real quote
            continue; // Single escaped, skip
         }
         return i;
      }
   }
   return -1;
}

//+------------------------------------------------------------------+
//| Parse AI response to extract signal                              |
//+------------------------------------------------------------------+
int ParseAIResponse(string content)
{
   if(content == "")
   {
      LogMessage("AI: Empty response");
      return SIGNAL_NONE;
   }
   
   // Convert to uppercase for easier parsing
   string upper = content;
   StringToUpper(upper);
   
   // Parse ACTION
   string action = "HOLD";
   int actionPos = StringFind(upper, "ACTION:");
   if(actionPos >= 0)
   {
      string actionLine = StringSubstr(upper, actionPos + 7, 20);
      StringTrimLeft(actionLine);
      
      if(StringFind(actionLine, "BUY") == 0)
         action = "BUY";
      else if(StringFind(actionLine, "SELL") == 0)
         action = "SELL";
      else
         action = "HOLD";
   }
   else
   {
      // Fallback: search for keywords
      if(StringFind(upper, "BUY") >= 0 && StringFind(upper, "SELL") < 0)
         action = "BUY";
      else if(StringFind(upper, "SELL") >= 0 && StringFind(upper, "BUY") < 0)
         action = "SELL";
   }
   
   // Parse CONFIDENCE
   int confidence = 0;
   int confPos = StringFind(upper, "CONFIDENCE:");
   if(confPos >= 0)
   {
      string confStr = StringSubstr(content, confPos + 11, 10);
      StringTrimLeft(confStr);
      
      // Extract number
      string numStr = "";
      for(int i = 0; i < StringLen(confStr); i++)
      {
         ushort ch = StringGetCharacter(confStr, i);
         if(ch >= '0' && ch <= '9')
            numStr += CharToString((uchar)ch);
         else if(StringLen(numStr) > 0)
            break;
      }
      
      if(numStr != "")
         confidence = (int)StringToInteger(numStr);
   }
   
   // Parse REASON
   string reason = "";
   int reasonPos = StringFind(upper, "REASON:");
   if(reasonPos >= 0)
   {
      reason = StringSubstr(content, reasonPos + 7);
      StringTrimLeft(reason);
      // Take first line only
      int nlPos = StringFind(reason, "\n");
      if(nlPos > 0)
         reason = StringSubstr(reason, 0, nlPos);
   }
   
   // Store results
   g_aiLastConfidence = confidence;
   g_aiLastReason = reason;
   
   LogMessage("AI Signal: " + action + " | Confidence: " + IntegerToString(confidence) + "% | " + reason);
   
   // Check confidence threshold
   if(confidence < InpAI_Confidence)
   {
      LogMessage("AI: Confidence " + IntegerToString(confidence) + "% below threshold " + IntegerToString(InpAI_Confidence) + "%. SKIPPING.");
      g_aiLastSignal = SIGNAL_NONE;
      return SIGNAL_NONE;
   }
   
   // Return signal
   if(action == "BUY")
   {
      g_aiLastSignal = SIGNAL_BUY;
      return SIGNAL_BUY;
   }
   else if(action == "SELL")
   {
      g_aiLastSignal = SIGNAL_SELL;
      return SIGNAL_SELL;
   }
   
   g_aiLastSignal = SIGNAL_NONE;
   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| Main AI Signal function                                          |
//+------------------------------------------------------------------+
int SignalAI(string symbol, ENUM_TIMEFRAMES tf)
{
   // Rate limiting: only call every N seconds
   if(TimeCurrent() - g_aiLastCallTime < InpAI_Cooldown)
   {
      return g_aiLastSignal; // Return cached signal
   }
   
   // Call AI API
   string response = CallAIApi(symbol, tf);
   g_aiLastCallTime = TimeCurrent();
   
   if(response == "")
   {
      Print("AI: No response, returning NONE");
      return SIGNAL_NONE;
   }
   
   // Extract content from JSON response
   string content = ExtractAIContent(response);
   
   if(content == "")
   {
      Print("AI: Could not extract content from response");
      Print("AI: Raw response (first 500 chars): ", StringSubstr(response, 0, 500));
      return SIGNAL_NONE;
   }
   
   // Parse and return signal
   return ParseAIResponse(content);
}

//+------------------------------------------------------------------+
//| Hybrid: Technical + AI Confirmation                              |
//| Uses technical analysis for signal, AI for confirmation          |
//+------------------------------------------------------------------+
int SignalAI_Hybrid(string symbol, ENUM_TIMEFRAMES tf)
{
   // First get technical signal using the selected base strategy
   int techSignal = SIGNAL_NONE;
   
   switch(InpAI_BaseStrategy)
   {
      case AI_BASE_TREND:      techSignal = SignalTrendFollowing(symbol, tf); break;
      case AI_BASE_SCALPING:   techSignal = SignalScalping(symbol, tf); break;
      case AI_BASE_BREAKOUT:   techSignal = SignalBreakout(symbol, tf); break;
      case AI_BASE_REVERSION:  techSignal = SignalMeanReversion(symbol, tf); break;
      case AI_BASE_CUSTOM:     techSignal = SignalCustom(symbol, tf); break;
   }
   
   // If no technical signal, no need to call AI
   if(techSignal == SIGNAL_NONE)
      return SIGNAL_NONE;
   
   // Rate limiting check
   if(TimeCurrent() - g_aiLastCallTime < InpAI_Cooldown)
   {
      // Use cached AI result
      if(g_aiLastSignal == techSignal)
         return techSignal;
      else
         return SIGNAL_NONE;
   }
   
   LogMessage("AI Hybrid: Technical signal = " + (techSignal == SIGNAL_BUY ? "BUY" : "SELL") + ". Asking AI for confirmation...");
   
   // Call AI to confirm
   int aiSignal = SignalAI(symbol, tf);
   
   // Both must agree
   if(aiSignal == techSignal)
   {
      LogMessage("AI Hybrid: ✅ AI CONFIRMS " + (techSignal == SIGNAL_BUY ? "BUY" : "SELL") + 
                 " (confidence: " + IntegerToString(g_aiLastConfidence) + "%)");
      return techSignal;
   }
   else
   {
      LogMessage("AI Hybrid: ❌ AI REJECTS signal. Tech=" + 
                 (techSignal == SIGNAL_BUY ? "BUY" : "SELL") + 
                 " AI=" + (aiSignal == SIGNAL_BUY ? "BUY" : (aiSignal == SIGNAL_SELL ? "SELL" : "HOLD")));
      return SIGNAL_NONE;
   }
}

//+------------------------------------------------------------------+
//| Send AI analysis to Telegram (optional)                          |
//+------------------------------------------------------------------+
void SendAIAnalysisToTelegram(string symbol, string action, int confidence, string reason)
{
   if(!InpUseTelegram || !InpAI_TgNotify) return;
   
   string emoji = "🤖";
   if(action == "BUY") emoji = "🟢🤖";
   else if(action == "SELL") emoji = "🔴🤖";
   
   string msg = "<b>" + emoji + " AI ANALYSIS</b>\n";
   msg += "━━━━━━━━━━━━━━\n";
   msg += "📊 <b>Symbol:</b> " + symbol + "\n";
   msg += "🎯 <b>Action:</b> " + action + "\n";
   msg += "📈 <b>Confidence:</b> " + IntegerToString(confidence) + "%\n";
   msg += "💡 <b>Reason:</b> " + reason + "\n";
   msg += "━━━━━━━━━━━━━━\n";
   msg += "🤖 <i>AI Provider: " + EnumToString(InpAI_Provider) + "</i>";
   
   SendTelegram(msg);
}
