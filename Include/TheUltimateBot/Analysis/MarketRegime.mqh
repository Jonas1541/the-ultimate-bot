//+------------------------------------------------------------------+
//|                                                MarketRegime.mqh |
//|                                  Copyright 2026, TheUltimateBot  |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property strict

#include "../Domain/MarketState.mqh"
#include "../Domain/Types.mqh"

class MarketRegime {
private:
   int      m_handleADX;   // Indicador de Força de Tendência
   int      m_handleATR;   // Indicador de Volatilidade
   string   m_symbol;
   ENUM_TIMEFRAMES m_period;

   // Buffers para leitura
   double   m_buffADX[];
   double   m_buffPlusDI[];  // Força de Compra
   double   m_buffMinusDI[]; // Força de Venda
   double   m_buffATR[];

public:
   // --- Construtor: Prepara os indicadores ---
   MarketRegime(string symbol, ENUM_TIMEFRAMES period) {
      m_symbol = symbol;
      m_period = period;
      
      // ADX(14) para tendência
      m_handleADX = iADX(symbol, period, 14);
      
      // ATR(14) para volatilidade
      m_handleATR = iATR(symbol, period, 14);
      
      // Organiza arrays como Series (Indice 0 = atual)
      ArraySetAsSeries(m_buffADX, true);
      ArraySetAsSeries(m_buffPlusDI, true);
      ArraySetAsSeries(m_buffMinusDI, true);
      ArraySetAsSeries(m_buffATR, true);
   }

   // --- Destrutor ---
   ~MarketRegime() {
      IndicatorRelease(m_handleADX);
      IndicatorRelease(m_handleATR);
   }

   // --- O Método Principal: Diagnostica o Paciente ---
   void UpdateState(MarketState &state) {
      // 1. Atualiza dados do servidor
      state.ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      state.bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
      state.serverTime = TimeCurrent();
      
      if(CopyBuffer(m_handleADX, 0, 0, 2, m_buffADX) < 2) return;
      if(CopyBuffer(m_handleADX, 1, 0, 2, m_buffPlusDI) < 2) return; // +DI
      if(CopyBuffer(m_handleADX, 2, 0, 2, m_buffMinusDI) < 2) return; // -DI
      if(CopyBuffer(m_handleATR, 0, 0, 2, m_buffATR) < 2) return;

      double adx = m_buffADX[1]; // Valor do candle fechado
      double pDI = m_buffPlusDI[1];
      double mDI = m_buffMinusDI[1];
      double atr = m_buffATR[1];

      // 2. Preenche o DTO
      state.serverTime = TimeCurrent();
      state.atrValue = atr;
      state.volumeProjection = 1.0; // Placeholder (implementaremos Vol depois)
      state.isNewsEvent = false;    // Placeholder (precisa de calendário econômico)

      // 3. Define a TENDÊNCIA (Lógica do ADX)
      if(adx < 20.0) {
         state.trend = TREND_NEUTRAL; // Mercado sem força
      }
      else {
         // Mercado tem força, vamos ver a direção
         if(pDI > mDI) state.trend = TREND_BULLISH;
         else          state.trend = TREND_BEARISH;
      }

      // 4. Define a VOLATILIDADE (Simplificado baseada no ATR)
      // Aqui usamos uma regra simples: se ATR subiu muito, volatilidade alta
      // Num sistema real, comparariamos o ATR atual com a média do ATR passado
      state.volatility = VOL_NORMAL; 
      // (Futuramente melhoraremos isso com o VolatilityGauge)
   }
};
//+------------------------------------------------------------------+