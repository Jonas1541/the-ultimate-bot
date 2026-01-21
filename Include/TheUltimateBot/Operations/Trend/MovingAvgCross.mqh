//+------------------------------------------------------------------+
//|                                             MovingAvgCross.mqh |
//|                                  Copyright 2026, TheUltimateBot  |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property strict

#include <TheUltimateBot/Domain/ISignal.mqh>
#include <TheUltimateBot/Domain/Types.mqh>
#include <TheUltimateBot/Domain/IMoney.mqh>
#include <TheUltimateBot/Commands/OpenOrderCommand.mqh>
#include <TheUltimateBot/Infrastructure/PositionService.mqh>

// Nota: Não precisamos mais incluir TimeFilter aqui!

class MovingAvgCross : public ISignal {
private:
   int      m_handleFast;
   int      m_handleSlow;
   string   m_symbol;
   double   m_buffFast[]; 
   double   m_buffSlow[];
   
   IMoney* m_money; 
   // Removemos m_time daqui. Ele agora vive dentro da lista m_validators da classe pai.

   double GetPoint() { return SymbolInfoDouble(m_symbol, SYMBOL_POINT); }

public:
   // CONSTRUTOR MAIS LIMPO
   MovingAvgCross(string symbol, ENUM_TIMEFRAMES period, int fastPeriod, int slowPeriod, IMoney* money) {
      m_symbol = symbol;
      m_money = money;
      
      m_handleFast = iMA(symbol, period, fastPeriod, 0, MODE_SMA, PRICE_CLOSE);
      m_handleSlow = iMA(symbol, period, slowPeriod, 0, MODE_SMA, PRICE_CLOSE);
      
      ArraySetAsSeries(m_buffFast, true);
      ArraySetAsSeries(m_buffSlow, true);
   }

   ~MovingAvgCross() {
      IndicatorRelease(m_handleFast);
      IndicatorRelease(m_handleSlow);
   }

   string GetName() override { return "Moving Average Crossover"; }

   double GetScore(MarketState &state) override {
      // 1. RODAR FILTROS (Horário, Loss, Spread, etc.)
      string reason = "";
      if(!ValidateAll(reason)) {
         // Opcional: Print("Bloqueado por: " + reason);
         return 0.0;
      }

      // 2. Filtro de Posição (ainda hardcoded por ser crítico de infra)
      if(PositionService::Get().HasOpenPosition(m_symbol)) return 0.0; 

      // 3. Filtro de Tendência
      if(state.trend == TREND_NEUTRAL) return 0.1; 
      
      return 0.9; 
   }

   ICommand* Tick(MarketState &state) override {
      // Redundância de segurança
      string ignore;
      if(!ValidateAll(ignore)) return NULL;
      if(PositionService::Get().HasOpenPosition(m_symbol)) return NULL;

      if(CopyBuffer(m_handleFast, 0, 0, 3, m_buffFast) < 3) return NULL;
      if(CopyBuffer(m_handleSlow, 0, 0, 3, m_buffSlow) < 3) return NULL;

      double fastNow = m_buffFast[1];
      double slowNow = m_buffSlow[1];
      double fastPrev = m_buffFast[2];
      double slowPrev = m_buffSlow[2];
      double pt = GetPoint(); 

      // COMPRA
      if(fastPrev <= slowPrev && fastNow > slowNow) {
         double sl = state.ask - 100 * pt;
         double tp = state.ask + 200 * pt;
         double lots = m_money.GetLotSize(state.ask, sl);

         return new OpenOrderCommand(m_symbol, ORDER_TYPE_BUY, lots, state.ask, sl, tp, "MACross Buy");
      }

      // VENDA
      if(fastPrev >= slowPrev && fastNow < slowNow) {
         double sl = state.bid + 100 * pt;
         double tp = state.bid - 200 * pt;
         double lots = m_money.GetLotSize(state.bid, sl);

         return new OpenOrderCommand(m_symbol, ORDER_TYPE_SELL, lots, state.bid, sl, tp, "MACross Sell");
      }

      return NULL;
   }
};
//+------------------------------------------------------------------+