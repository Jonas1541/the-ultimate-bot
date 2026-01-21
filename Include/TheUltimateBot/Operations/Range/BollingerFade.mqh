//+------------------------------------------------------------------+
//|                                                BollingerFade.mqh |
//|                                  Copyright 2026, TheUltimateBot  |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property strict

#include <TheUltimateBot/Domain/ISignal.mqh>
#include <TheUltimateBot/Domain/Types.mqh>
#include <TheUltimateBot/Domain/IMoney.mqh>
#include <TheUltimateBot/Commands/OpenOrderCommand.mqh>
#include <TheUltimateBot/Infrastructure/PositionService.mqh>

class BollingerFade : public ISignal {
private:
   int      m_handle;      // Handle do Indicador
   string   m_symbol;
   double   m_buffUpper[]; // Buffer da Banda Superior
   double   m_buffLower[]; // Buffer da Banda Inferior
   
   IMoney* m_money;       // Gestão de Risco

   double GetPoint() { return SymbolInfoDouble(m_symbol, SYMBOL_POINT); }

public:
   BollingerFade(string symbol, ENUM_TIMEFRAMES period, int bandsPeriod, double deviation, IMoney* money) {
      m_symbol = symbol;
      m_money = money;
      
      // Inicializa o indicador Bollinger Bands padrão do MT5
      m_handle = iBands(symbol, period, bandsPeriod, 0, deviation, PRICE_CLOSE);
      
      // Configura os arrays como Series (Índice 0 é o atual)
      ArraySetAsSeries(m_buffUpper, true);
      ArraySetAsSeries(m_buffLower, true);
   }

   ~BollingerFade() {
      IndicatorRelease(m_handle);
   }

   string GetName() override { return "Bollinger Bands Fade"; }

   // --- AQUI ESTÁ A LÓGICA DE SELEÇÃO ---
   double GetScore(MarketState &state) override {
      // 1. Filtros de Segurança (Horário, Loss, etc.)
      string reason;
      if(!ValidateAll(reason)) return 0.0;
      if(PositionService::Get().HasOpenPosition(m_symbol)) return 0.0;

      // 2. Regime de Mercado (COMPETIÇÃO)
      // Se a tendência for NEUTRA (Lateral), essa estratégia brilha -> Nota 0.9
      if(state.trend == TREND_NEUTRAL) {
         return 0.9;
      }
      
      // Se tiver tendência forte, Bollinger costuma quebrar -> Nota Baixa (0.2)
      // Assim, o StrategyManager vai preferir a MovingAvgCross (que daria 0.9 aqui)
      return 0.2; 
   }

   ICommand* Tick(MarketState &state) override {
      // Redundância
      string ignore;
      if(!ValidateAll(ignore)) return NULL;
      if(PositionService::Get().HasOpenPosition(m_symbol)) return NULL;

      // Lê os valores das bandas (Upper=1, Lower=2 no iBands)
      if(CopyBuffer(m_handle, 1, 0, 2, m_buffUpper) < 2) return NULL;
      if(CopyBuffer(m_handle, 2, 0, 2, m_buffLower) < 2) return NULL;

      double upper = m_buffUpper[0]; // Banda atual
      double lower = m_buffLower[0]; // Banda atual
      double price = state.bid;      // Preço atual
      double pt = GetPoint();

      // Lógica de VENDA (Tocou na Banda Superior)
      // Usamos preço > upper (Rompimento falso ou toque)
      if(state.bid >= upper) {
         double sl = state.bid + 150 * pt; // Stop curto acima da banda
         double tp = state.bid - 300 * pt; // Alvo no meio do caminho
         double lots = m_money.GetLotSize(state.bid, sl);

         return new OpenOrderCommand(m_symbol, ORDER_TYPE_SELL, lots, state.bid, sl, tp, "BB Fade Sell");
      }

      // Lógica de COMPRA (Tocou na Banda Inferior)
      if(state.ask <= lower) {
         double sl = state.ask - 150 * pt; // Stop curto abaixo da banda
         double tp = state.ask + 300 * pt;
         double lots = m_money.GetLotSize(state.ask, sl);

         return new OpenOrderCommand(m_symbol, ORDER_TYPE_BUY, lots, state.ask, sl, tp, "BB Fade Buy");
      }

      return NULL;
   }
};
//+------------------------------------------------------------------+