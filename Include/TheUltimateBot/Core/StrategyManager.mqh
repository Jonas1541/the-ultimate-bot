//+------------------------------------------------------------------+
//|                                           StrategyManager.mqh |
//|                                  Copyright 2026, TheUltimateBot  |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property strict

#include "../Commands/ClosePositionCommand.mqh" // <--- Novo Include
#include "../Domain/ISignal.mqh"
#include "../Domain/MarketState.mqh"
#include "../Infrastructure/PositionService.mqh" // <--- Para listar posições
#include "CommandInvoker.mqh"

class StrategyManager {
private:
  ISignal *m_strategies[];
  CommandInvoker *m_invoker;

  // State Tracking for Logs
  string m_lastStrategyName;

public:
  StrategyManager(CommandInvoker *invoker) {
    m_invoker = invoker;
    m_lastStrategyName = "";
  }

  ~StrategyManager() {
    int total = ArraySize(m_strategies);
    for (int i = 0; i < total; i++) {
      if (CheckPointer(m_strategies[i]) == POINTER_DYNAMIC)
        delete m_strategies[i];
    }
    ArrayFree(m_strategies);
  }

  void Register(ISignal *strategy) {
    int size = ArraySize(m_strategies);
    ArrayResize(m_strategies, size + 1);
    m_strategies[size] = strategy;
  }

  // --- AQUI ESTÁ A MÁGICA DA SELEÇÃO ---
  void OnTick(MarketState &state) {
    int total = ArraySize(m_strategies);
    if (total == 0)
      return;

    ISignal *bestStrategy = NULL;
    double bestScore = -1.0;

    for (int i = 0; i < total; i++) {
      double score = m_strategies[i].GetScore(state);
      if (score > bestScore) {
        bestScore = score;
        bestStrategy = m_strategies[i];
      }
    }

    if (bestStrategy != NULL) {
      // --- LOG 1: DETECTA MUDANÇA DE ESTRATÉGIA ---
      // Se a melhor estratégia mudou desde o último tick, loga no diário
      if (bestStrategy.GetName() != m_lastStrategyName) {
        PrintFormat(">>> [STRATEGY SWITCH] New Leader: '%s' (Score: %.2f)",
                    bestStrategy.GetName(), bestScore);
        m_lastStrategyName = bestStrategy.GetName();
      }

      if (bestScore >= 0.5) {
        // --- AQUI GERAMOS O COMANDO ---
        ICommand *command = bestStrategy.Tick(state);

        if (command != NULL) {
          // --- LOG 2: EXECUÇÃO DE OPERAÇÃO ---
          PrintFormat(">>> [TRADE EXECUTION] Strategy: '%s' | Score: %.2f | "
                      "Action: TRIGGERED",
                      bestStrategy.GetName(), bestScore);

          m_invoker.Execute(command);
        }
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

    for (int i = 0; i < total; i++) {
      // Cria e executa imediatamente o comando de fechamento
      ICommand *cmd = new ClosePositionCommand(tickets[i]);
      m_invoker.Execute(cmd);
    }
  }
};
//+------------------------------------------------------------------+