//+------------------------------------------------------------------+
//|                                             MovingAvgCross.mqh |
//|                                  Copyright 2026, TheUltimateBot  |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property strict

#include <TheUltimateBot/Domain/ISignal.mqh>
#include <TheUltimateBot/Domain/Types.mqh>
#include <TheUltimateBot/Commands/OpenOrderCommand.mqh>

class MovingAvgCross : public ISignal {
private:
   int      m_handleFast;
   int      m_handleSlow;
   string   m_symbol;
   double   m_buffFast[]; 
   double   m_buffSlow[];

   // CORREÇÃO 1: Helper para pegar o valor do Point de forma segura
   double GetPoint() {
      return SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   }

public:
   MovingAvgCross(string symbol, ENUM_TIMEFRAMES period, int fastPeriod, int slowPeriod) {
      m_symbol = symbol;
      
      // Inicializa médias móveis (SMA no fechamento)
      m_handleFast = iMA(symbol, period, fastPeriod, 0, MODE_SMA, PRICE_CLOSE);
      m_handleSlow = iMA(symbol, period, slowPeriod, 0, MODE_SMA, PRICE_CLOSE);
      
      ArraySetAsSeries(m_buffFast, true);
      ArraySetAsSeries(m_buffSlow, true);
   }

   ~MovingAvgCross() {
      IndicatorRelease(m_handleFast);
      IndicatorRelease(m_handleSlow);
   }

   string GetName() override {
      return "Moving Average Crossover";
   }

   double GetScore(MarketState &state) override {
      // Verifica se os Enums estão acessíveis via Types.mqh
      if(state.trend == TREND_NEUTRAL) return 0.1; 
      if(state.volatility == VOL_EXTREME) return 0.0;
      return 0.9; 
   }

   ICommand* Tick(MarketState &state) override {
      if(CopyBuffer(m_handleFast, 0, 0, 3, m_buffFast) < 3) return NULL;
      if(CopyBuffer(m_handleSlow, 0, 0, 3, m_buffSlow) < 3) return NULL;

      double fastNow = m_buffFast[1];
      double slowNow = m_buffSlow[1];
      double fastPrev = m_buffFast[2];
      double slowPrev = m_buffSlow[2];

      // CORREÇÃO 2: Uso de GetPoint() no lugar de _Point
      double pt = GetPoint(); 

      // Cruzamento de COMPRA
      if(fastPrev <= slowPrev && fastNow > slowNow) {
         return new OpenOrderCommand(
            m_symbol, 
            ORDER_TYPE_BUY, 
            1.0,           
            state.ask,     
            state.ask - 100 * pt, // Stop Loss corrigido
            state.ask + 200 * pt, // Take Profit corrigido
            "MACross Buy"
         );
      }

      // Cruzamento de VENDA
      if(fastPrev >= slowPrev && fastNow < slowNow) {
         return new OpenOrderCommand(
            m_symbol, 
            ORDER_TYPE_SELL, 
            1.0, 
            state.bid,
            state.bid + 100 * pt,
            state.bid - 200 * pt,
            "MACross Sell"
         );
      }

      return NULL;
   }
};
//+------------------------------------------------------------------+