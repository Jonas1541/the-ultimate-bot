//+------------------------------------------------------------------+
//|                                             ConservativeRisk.mqh |
//|                                  Copyright 2026, TheUltimateBot  |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property strict

#include "../../Domain/IMoney.mqh"

class ConservativeRisk : public IMoney {
private:
   string m_symbol;
   double m_riskPercent; // Ex: 1.0 para 1%

public:
   ConservativeRisk(string symbol, double riskPercent) {
      m_symbol = symbol;
      m_riskPercent = riskPercent;
   }

   double GetLotSize(double entryPrice, double stopLossPrice) override {
      // 1. Calcula a distância do Stop em Pontos
      double slPoints = MathAbs(entryPrice - stopLossPrice);
      if(slPoints == 0) return 0.0;

      // 2. Busca dados financeiros do ativo
      double tickSize = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
      double tickValue = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
      double lotStep = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
      
      // Proteção contra divisão por zero
      if(tickSize == 0 || tickValue == 0) return lotStep;

      // 3. Quanto dinheiro temos na conta?
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      
      // 4. Quanto dinheiro podemos perder? (Ex: $1000 * 1% = $10)
      double riskMoney = balance * (m_riskPercent / 100.0);

      // 5. FÓRMULA MÁGICA:
      // Dinheiro = Lotes * (Distancia / TickSize) * TickValue
      // Logo: Lotes = Dinheiro / ((Distancia / TickSize) * TickValue)
      double rawLots = riskMoney / ((slPoints / tickSize) * tickValue);

      // 6. Arredonda para o passo do lote (Ex: 0.01 ou 1.0)
      double finalLots = MathFloor(rawLots / lotStep) * lotStep;
      
      // Garante lote mínimo
      double minLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
      double maxLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);
      
      if(finalLots < minLot) finalLots = minLot;
      if(finalLots > maxLot) finalLots = maxLot;

      return finalLots;
   }
};
//+------------------------------------------------------------------+