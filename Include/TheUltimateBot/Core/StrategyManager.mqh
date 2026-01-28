//+------------------------------------------------------------------+
//|                                           StrategyManager.mqh |
//|                                  Copyright 2026, TheUltimateBot  |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property strict

#include "../Domain/ISignal.mqh"
#include "../Domain/MarketState.mqh"
#include "../Domain/MarketState.mqh"
#include "../Commands/ClosePositionCommand.mqh" // <--- Novo Include
#include "../Infrastructure/PositionService.mqh" // <--- Para listar posições
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

      for(int i=0; i<total; i++) {
         double score = m_strategies[i].GetScore(state);
         if(score > bestScore) {
            bestScore = score;
            bestStrategy = m_strategies[i];
         }
      }

      if(bestStrategy != NULL && bestScore >= 0.5) {
         // --- AQUI GERAMOS O COMANDO ---
         ICommand* command = bestStrategy.Tick(state);
         
         if(command != NULL) {
            // LOG NO DIÁRIO (Aparece na aba Diário)
            PrintFormat(">>> [TRADE] Strategy '%s' (Score %.2f) TRIGGERED COMMAND", 
                        bestStrategy.GetName(), bestScore);
            
            m_invoker.Execute(command);
         }
      }
   }

   // --- MODO PÂNICO ---
   void PanicCloseAll() {
      Print(">>> [STRATEGY MANAGER] !!! EXECUTING PANIC CLOSE ALL !!!");
      
      ulong tickets[];
      PositionService::Get().GetOpenTickets(tickets);
      
      int total = ArraySize(tickets);
      PrintFormat(">>> [PANIC] Found %d open positions to close.", total);
      
      for(int i=0; i<total; i++) {
         // Cria e executa imediatamente o comando de fechamento
         ICommand* cmd = new ClosePositionCommand(tickets[i]);
         m_invoker.Execute(cmd);
      }
   }
};
//+------------------------------------------------------------------+