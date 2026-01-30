//+------------------------------------------------------------------+
//|                                                TrendStrategy.mqh |
//|                                  Copyright 2026, TheUltimateBot  |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property strict

#include <TheUltimateBot/Domain/ISignal.mqh>
#include <TheUltimateBot/Domain/Types.mqh>
#include <TheUltimateBot/Commands/OpenOrderCommand.mqh>
#include <TheUltimateBot/Infrastructure/PositionService.mqh>
#include <TheUltimateBot/Domain/IMarketDataProvider.mqh>
#include <TheUltimateBot/Infrastructure/MT5MarketDataProvider.mqh>

class TrendStrategy : public ISignal {
private:
   string m_symbol;
   ENUM_TIMEFRAMES m_signalTF;
   ENUM_TIMEFRAMES m_macroTF;
   
   // EMAs settings
   int m_emaFast; 
   int m_emaSlow;
   int m_macroFast; 
   int m_macroSlow;

   IMarketDataProvider* m_marketData;
   bool m_ownsData;

   double Pt() { return SymbolInfoDouble(m_symbol, SYMBOL_POINT); }

   // Trend Helper
   int GetTrendDirection(ENUM_TIMEFRAMES tf, int fast, int slow) {
      double valFast = m_marketData.GetEMA(m_symbol, tf, fast, 0);
      double valSlow = m_marketData.GetEMA(m_symbol, tf, slow, 0);

      if(valFast == 0.0 || valSlow == 0.0) return 0;

      if(valFast > valSlow) return 1;  // Bullish
      if(valFast < valSlow) return -1; // Bearish
      return 0;
   }

public:
   TrendStrategy(string symbol, IMarketDataProvider* provider = NULL) {
      m_symbol = symbol;
      
      if(provider == NULL) {
         m_marketData = new MT5MarketDataProvider();
         m_ownsData = true;
      } else {
         m_marketData = provider;
         m_ownsData = false;
      }

      // Default Settings (Matches previous Cerberus logic)
      m_signalTF = PERIOD_M1;
      m_macroTF  = PERIOD_M15;
      m_emaFast = 9; m_emaSlow = 21;
      m_macroFast = 50; m_macroSlow = 200;
   }
   
   ~TrendStrategy() {
      if(m_ownsData && CheckPointer(m_marketData) == POINTER_DYNAMIC) {
         delete m_marketData;
      }
   }

   string GetName() override { return "Trend Follower (EMA)"; }

   double GetScore(MarketState &state) override {
      // 1. Basic Validation
      string reason;
      if(!ValidateAll(reason)) return 0.0;
      
      // 2. If already managing a trade for this symbol, keep control? 
      // For now, if position exists, let's say we are "holding" the trend.
      if(PositionService::Get().HasOpenPosition(m_symbol)) return 0.0; // Let someone else manage or ignore? 
      // Actually, standard logic: if we have position, we might want to return high score to "manage" it, 
      // but current architecture selects strategy for *Entry*. 
      // If "HasOpenPosition" is true, StrategyManager returns early usually or we return 0 to not open duplicate.
      // Let's return 0.0 to avoid stacking for now.
      
      int micro = GetTrendDirection(m_signalTF, m_emaFast, m_emaSlow);
      int macro = GetTrendDirection(m_macroTF, m_macroFast, m_macroSlow);

      // Alignment Logic
      if(micro == macro && micro != 0) {
         return 65.0; // Good score, but Breakout (80+) will override it if present.
      }
      
      return 0.0;
   }

   ICommand* Tick(MarketState &state) override {
      string ignore;
      if(!ValidateAll(ignore)) return NULL;
      
      if(PositionService::Get().HasOpenPosition(m_symbol)) return NULL;

      int micro = GetTrendDirection(m_signalTF, m_emaFast, m_emaSlow);
      int macro = GetTrendDirection(m_macroTF, m_macroFast, m_macroSlow);

      // Only trade if fully aligned
      if(micro == 1 && macro == 1) {
         // BUY logic (Simplified SL/TP for now, needs resizing later)
         double sl = state.ask - 300 * Pt();
         double tp = state.ask + 300 * Pt(); 
         return new OpenOrderCommand(m_symbol, ORDER_TYPE_BUY, 1.0, state.ask, sl, tp, "Trend Buy");
      }

      if(micro == -1 && macro == -1) {
         // SELL logic
         double sl = state.bid + 300 * Pt();
         double tp = state.bid - 300 * Pt();
         return new OpenOrderCommand(m_symbol, ORDER_TYPE_SELL, 1.0, state.bid, sl, tp, "Trend Sell");
      }

      return NULL;
   }
};
