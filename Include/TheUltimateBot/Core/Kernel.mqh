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
#include "CommandInvoker.mqh" 
#include "../Infrastructure/FileLogger.mqh" // <--- Novo

class Kernel {
private:
   MarketState* m_state;
   MarketRegime* m_regime;
   StrategyManager* m_manager;
   SessionContext* m_session;
   CommandInvoker* m_invoker;
   FileLogger* m_logger; // <--- Logger Global
   bool m_isHalted;      // <--- Flag de Parada de Emergência
   
   static Kernel* s_instance;
   
   Kernel() {
      Print(">>> [KERNEL] Booting Core Systems...");
      
      // 0. Inicializa Logger primeiro
      m_logger = new FileLogger();
      m_logger.Log("[KERNEL] Initializing subsystem...");

      m_state     = new MarketState();
      m_regime    = new MarketRegime(_Symbol, PERIOD_M5);
      m_session   = new SessionContext();
      m_invoker   = new CommandInvoker();
      m_manager   = new StrategyManager(m_invoker);
      m_isHalted  = false; // Sistema inicia operante
   }

public:
   ~Kernel() {
      if(CheckPointer(m_manager) == POINTER_DYNAMIC) delete m_manager;
      if(CheckPointer(m_regime) == POINTER_DYNAMIC) delete m_regime;
      if(CheckPointer(m_state) == POINTER_DYNAMIC) delete m_state;
      if(CheckPointer(m_session) == POINTER_DYNAMIC) delete m_session;
      if(CheckPointer(m_invoker) == POINTER_DYNAMIC) delete m_invoker;
      if(CheckPointer(m_logger) == POINTER_DYNAMIC) delete m_logger; // Tchau Logger
      
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
   ILogger* GetLogger() { return m_logger; } // getter útil
   bool IsHalted() { return m_isHalted; }

   void OnTick() {
      // 0. Verifica Parada de Emergência
      if(m_isHalted) {
         // Opcional: Tentar fechar novamente caso algo tenha ficado aberto
         // Mas por enquanto, apenas retorna para não abrir novas ordens.
         return; 
      }

      // 1. Atualiza Sessão
      m_session.Update();

      // 2. Atualiza Percepção
      m_regime.UpdateState(m_state);

      // 3. Decide e Executa
      m_manager.OnTick(m_state);
   }

   // Função de Pânico acessível globalmente
   void Panic() {
      if(m_logger != NULL) m_logger.Error("[KERNEL] PANIC SIGNAL RECEIVED. STOPPING EVERYTHING.");
      else Print(">>> [KERNEL] PANIC SIGNAL RECEIVED. STOPPING EVERYTHING.");
      
      // 1. Fecha tudo
      m_manager.PanicCloseAll();
      
      // 2. Trava o sistema permanentemente
      m_isHalted = true;
      Print(">>> [KERNEL] SYSTEM HALTED. RESTART REQUIRED.");
   }
};

Kernel* Kernel::s_instance = NULL;
//+------------------------------------------------------------------+