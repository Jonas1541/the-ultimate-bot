//+------------------------------------------------------------------+
//|                                             BreakoutStrategy.mqh |
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

class BreakoutStrategy : public ISignal {
private:
   string m_symbol;
   ENUM_TIMEFRAMES m_signalTF;
   int m_lookback;

   IMarketDataProvider* m_marketData;
   bool m_ownsData;

   double Pt() { return SymbolInfoDouble(m_symbol, SYMBOL_POINT); }

   // Breakout Helper
   int GetBreakoutDirection() {
      MqlRates rates[];
      int count = m_lookback + 2; 
      
      // Use Provider
      if(m_marketData.GetRates(m_symbol, m_signalTF, count, rates) < count) return 0;

      double closeNow = rates[1].close; // Previous closed candle
      // Previous High/Low (excluding the "closeNow" candle itself? logic uses lookback from i=2)
      // If we look at previous closed candle (rates[1]), we compare it against range [2...lookback]
      
      double highest = rates[2].high;
      double lowest  = rates[2].low;

      for(int i=2; i<count; i++) {
         if(rates[i].high > highest) highest = rates[i].high;
         if(rates[i].low < lowest) lowest = rates[i].low;
      }

      if(closeNow > highest) return 1; // Breakout High
      if(closeNow < lowest) return -1; // Breakout Low
      return 0;
   }

public:
   BreakoutStrategy(string symbol, IMarketDataProvider* provider = NULL) {
      m_symbol = symbol;
      
      if(provider == NULL) {
         m_marketData = new MT5MarketDataProvider();
         m_ownsData = true;
      } else {
         m_marketData = provider;
         m_ownsData = false;
      }

      m_signalTF = PERIOD_M1;
      m_lookback = 20; // 20 Candles breakout
   }
   
   ~BreakoutStrategy() {
      if(m_ownsData && CheckPointer(m_marketData) == POINTER_DYNAMIC) {
         delete m_marketData;
      }
   }

   string GetName() override { return "Impulse Breakout"; }

   double GetScore(MarketState &state) override {
      string reason;
      if(!ValidateAll(reason)) return 0.0;
      
      if(PositionService::Get().HasOpenPosition(m_symbol)) return 0.0;

      int dir = GetBreakoutDirection();
      
      if(dir != 0) {
         return 85.0; // Higher priority than Trend (65.0)
      }
      
      return 0.0;
   }

   ICommand* Tick(MarketState &state) override {
      string ignore;
      if(!ValidateAll(ignore)) return NULL;
      
      if(PositionService::Get().HasOpenPosition(m_symbol)) return NULL;

      int dir = GetBreakoutDirection();

      if(dir == 1) {
         // BUY Breakout
         double sl = state.ask - 200 * Pt(); // Tighter stop on breakout?
         double tp = state.ask + 400 * Pt(); // Let it run
         return new OpenOrderCommand(m_symbol, ORDER_TYPE_BUY, 1.0, state.ask, sl, tp, "Breakout Buy");
      }

      if(dir == -1) {
         // SELL Breakout
         double sl = state.bid + 200 * Pt();
         double tp = state.bid - 400 * Pt();
         return new OpenOrderCommand(m_symbol, ORDER_TYPE_SELL, 1.0, state.bid, sl, tp, "Breakout Sell");
      }

      return NULL;
   }
};
