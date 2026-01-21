//+------------------------------------------------------------------+
//|                                           StrategyManager.mqh |
//|                                  Copyright 2026, TheUltimateBot  |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property strict

#include "../Domain/ISignal.mqh"
#include "../Domain/MarketState.mqh"
#include "CommandInvoker.mqh"

class StrategyManager {
private:
   ISignal* m_strategies[]; 
   CommandInvoker* m_invoker;     

public:
   StrategyManager(CommandInvoker* invoker) {
      m_invoker = invoker;
   }

   ~StrategyManager() {
      int total = ArraySize(m_strategies);
      for(int i=0; i<total; i++) {
         if(CheckPointer(m_strategies[i]) == POINTER_DYNAMIC) delete m_strategies[i];
      }
      ArrayFree(m_strategies);
   }

   void Register(ISignal* strategy) {
      int size = ArraySize(m_strategies);
      ArrayResize(m_strategies, size + 1);
      m_strategies[size] = strategy;
   }

   // --- AQUI ESTÁ A MÁGICA DA SELEÇÃO ---
   void OnTick(MarketState &state) {
      int total = ArraySize(m_strategies);
      if(total == 0) return;

      ISignal* bestStrategy = NULL;
      double bestScore = -1.0;

      // 1. RODADA DE QUALIFICAÇÃO (Ranking)
      // Pergunta a nota para todos, mas não executa nada ainda.
      for(int i=0; i<total; i++) {
         double score = m_strategies[i].GetScore(state);
         
         // Debug para vermos a competição no log
         // PrintFormat("Strat: %s | Score: %.2f", m_strategies[i].GetName(), score);

         if(score > bestScore) {
            bestScore = score;
            bestStrategy = m_strategies[i];
         }
      }

      // 2. RODADA DE EXECUÇÃO (Winner Takes All)
      // Apenas a melhor estratégia do momento ganha o direito de analisar o tick
      // Definimos um piso mínimo (ex: 0.5) para evitar operar em confusão total
      if(bestStrategy != NULL && bestScore >= 0.5) {
         
         // Só agora chamamos o Tick() da vencedora
         ICommand* command = bestStrategy.Tick(state);
         
         if(command != NULL) {
            PrintFormat(">>> [MANAGER] WINNER: %s (Score: %.2f) -> Executing...", 
                        bestStrategy.GetName(), bestScore);
            m_invoker.Execute(command);
         }
      }
   }
};
//+------------------------------------------------------------------+