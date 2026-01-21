//+------------------------------------------------------------------+
//|                                                       Kernel.mqh |
//|                                  Copyright 2026, TheUltimateBot  |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property strict

#include "../Domain/MarketState.mqh"
#include "../Analysis/MarketRegime.mqh"
#include "StrategyManager.mqh"
#include "SessionContext.mqh"
#include "CommandInvoker.mqh" // <--- Novo Include

class Kernel {
private:
   MarketState* m_state;
   MarketRegime* m_regime;
   StrategyManager* m_manager;
   SessionContext* m_session;
   CommandInvoker* m_invoker; // <--- O Kernel segura o Invoker
   
   static Kernel* s_instance;
   
   Kernel() {
      Print(">>> [KERNEL] Booting Core Systems...");
      
      m_state     = new MarketState();
      m_regime    = new MarketRegime(_Symbol, PERIOD_M5);
      m_session   = new SessionContext();
      
      // 1. Cria o Invoker
      m_invoker   = new CommandInvoker();
      
      // 2. Passa o Invoker para o Manager
      m_manager   = new StrategyManager(m_invoker);
   }

public:
   ~Kernel() {
      if(CheckPointer(m_manager) == POINTER_DYNAMIC) delete m_manager;
      if(CheckPointer(m_regime) == POINTER_DYNAMIC) delete m_regime;
      if(CheckPointer(m_state) == POINTER_DYNAMIC) delete m_state;
      if(CheckPointer(m_session) == POINTER_DYNAMIC) delete m_session;
      if(CheckPointer(m_invoker) == POINTER_DYNAMIC) delete m_invoker; // Limpeza
      
      if(CheckPointer(s_instance) == POINTER_DYNAMIC) {
         delete s_instance;
         s_instance = NULL;
      }
   }

   static Kernel* Get() {
      if(s_instance == NULL) s_instance = new Kernel();
      return s_instance;
   }

   StrategyManager* GetManager() { return m_manager; }
   SessionContext* GetSession() { return m_session; }

   void OnTick() {
      // 1. Atualiza Sessão
      m_session.Update();

      // 2. Atualiza Percepção
      m_regime.UpdateState(m_state);

      // 3. Decide e Executa (Manager usa o Invoker internamente)
      m_manager.OnTick(m_state);
   }
};

Kernel* Kernel::s_instance = NULL;
//+------------------------------------------------------------------+