//+------------------------------------------------------------------+
//|                                              StrategyManager.mqh |
//|                                  Copyright 2026, TheUltimateBot  |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property strict

#include "../Domain/ISignal.mqh"
#include "../Domain/MarketState.mqh"
#include "../Domain/ICommand.mqh"

class StrategyManager {
private:
   // Lista dinâmica de estratégias (ponteiros)
   ISignal* m_strategies[];
   
   // Helper para redimensionar array ao adicionar
   void AddToArray(ISignal* strategy) {
      int size = ArraySize(m_strategies);
      ArrayResize(m_strategies, size + 1);
      m_strategies[size] = strategy;
   }

public:
   // --- Destrutor: Limpa a memória das estratégias ---
   ~StrategyManager() {
      int total = ArraySize(m_strategies);
      for(int i=0; i<total; i++) {
         if(CheckPointer(m_strategies[i]) == POINTER_DYNAMIC) {
            delete m_strategies[i];
         }
      }
      ArrayFree(m_strategies);
   }

   // --- Registro de Beans (Injeção de Dependência) ---
   void Register(ISignal* strategy) {
      if(CheckPointer(strategy) != POINTER_INVALID) {
         AddToArray(strategy);
         PrintFormat(">>> Strategy Registered: %s", strategy.GetName());
      }
   }

   // --- O Loop Principal de Decisão ---
   void OnTick(MarketState &state) {
      int total = ArraySize(m_strategies);
      if(total == 0) return;

      // 1. Fase de Leilão: Quem dá o maior Score?
      ISignal* bestStrategy = NULL;
      double bestScore = -1.0;

      for(int i=0; i<total; i++) {
         double score = m_strategies[i].GetScore(state);
         
         // Debug do Score (útil para calibração)
         // PrintFormat("Strategy %s | Score: %.2f", m_strategies[i].GetName(), score);

         if(score > bestScore) {
            bestScore = score;
            bestStrategy = m_strategies[i];
         }
      }

      // 2. Filtro de Qualidade Mínima
      // Se a melhor estratégia tiver score baixo (ex: 0.4), não fazemos nada.
      if(bestScore < 0.5 || bestStrategy == NULL) {
         return; 
      }

      // 3. Execução da Vencedora
      // Apenas a vencedora tem direito de processar o Tick e gastar CPU
      ICommand* cmd = bestStrategy.Tick(state);
      
      if(cmd != NULL) {
         PrintFormat(">>> WINNER: %s (Score: %.2f)", bestStrategy.GetName(), bestScore);
         
         // Executa o comando (Envio da ordem)
         cmd.Execute();
         
         // Limpa a memória do comando após execução (Obrigatório em C++)
         delete cmd; 
      }
   }
};
//+------------------------------------------------------------------+