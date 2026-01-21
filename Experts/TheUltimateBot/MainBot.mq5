//+------------------------------------------------------------------+
//|                                                      MainBot.mq5 |
//|                                  Copyright 2026, TheUltimateBot  |
//|                                     https://www.yourdomain.com   |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property link      "https://www.yourdomain.com"
#property version   "1.02" // Atualizado para incluir Bollinger

// --- IMPORTS DO NÚCLEO (CORE) ---
#include <TheUltimateBot/Core/Kernel.mqh>

// --- IMPORTS DE OPERAÇÃO E SERVIÇOS ---
#include <TheUltimateBot/Operations/Trend/MovingAvgCross.mqh>
#include <TheUltimateBot/Operations/Range/BollingerFade.mqh> // <--- NOVO
#include <TheUltimateBot/Services/Risk/ConservativeRisk.mqh>
#include <TheUltimateBot/Services/Time/TimeFilter.mqh>
#include <TheUltimateBot/Validators/DailyLossValidator.mqh>
#include <TheUltimateBot/Validators/TradingHoursValidator.mqh>

// --- INPUTS: ESTRATÉGIA 1 (TENDÊNCIA) ---
input group    "Estratégia: Médias Móveis (Tendência)"
input int      Inp_FastMA     = 9;          // Média Rápida
input int      Inp_SlowMA     = 21;         // Média Lenta

// --- INPUTS: ESTRATÉGIA 2 (LATERALIDADE) ---
input group    "Estratégia: Bollinger Bands (Lateral)"
input int      Inp_BbPeriod   = 20;         // Período BB
input double   Inp_BbDev      = 2.0;        // Desvio Padrão

// --- INPUTS: GERENCIAMENTO DE RISCO ---
input group    "Gerenciamento de Risco"
input double   Inp_RiskPercent = 1.0;       // Risco por Trade (% do Saldo)

// --- INPUTS: SEGURANÇA GLOBAL ---
input group    "Segurança Global"
input double   Inp_DailyLoss   = 50.0;      // Limite de Perda Diária ($)

// --- INPUTS: HORÁRIO ---
input group    "Horário de Negociação"
input int      Inp_StartHour  = 9;          // Hora Início
input int      Inp_StartMin   = 15;         // Minuto Início
input int      Inp_EndHour    = 16;         // Hora Fim
input int      Inp_EndMin     = 30;         // Minuto Fim

// --- OBJETOS GLOBAIS ---
Kernel *g_kernel;

//+------------------------------------------------------------------+
//| Expert initialization function (BOOTSTRAP)                       |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print(">>> [BOOT] SYSTEM STARTUP sequence initiated.");

   // 1. INICIALIZA O KERNEL
   g_kernel = Kernel::Get();

   // 2. CRIAÇÃO DOS SERVIÇOS AUXILIARES (DEPENDENCY INJECTION)
   IMoney* moneyService = new ConservativeRisk(_Symbol, Inp_RiskPercent);
   TimeFilter* timeService = new TimeFilter(Inp_StartHour, Inp_StartMin, Inp_EndHour, Inp_EndMin);

   // 3. CRIAÇÃO DOS VALIDADORES (FILTROS COMPARTILHADOS)
   // Estes filtros serão usados por TODAS as estratégias
   
   // A. Validador de Horário
   TradingHoursValidator* timeValidator = new TradingHoursValidator(timeService);

   // B. Validador de Perda Diária (Segurança)
   SessionContext* session = g_kernel.GetSession();
   DailyLossValidator* lossValidator = new DailyLossValidator(session, Inp_DailyLoss);

   // ---------------------------------------------------------
   // 4. CONFIGURAÇÃO DAS ESTRATÉGIAS
   // ---------------------------------------------------------

   // --- ESTRATÉGIA A: TENDÊNCIA (Moving Avg) ---
   MovingAvgCross* strategyTrend = new MovingAvgCross(
      _Symbol, 
      PERIOD_M1, 
      Inp_FastMA, 
      Inp_SlowMA, 
      moneyService
   );
   // Injeção dos Filtros
   strategyTrend.AddValidator(timeValidator);
   strategyTrend.AddValidator(lossValidator);
   
   // --- ESTRATÉGIA B: LATERALIDADE (Bollinger) ---
   BollingerFade* strategyRange = new BollingerFade(
      _Symbol, 
      PERIOD_M1, 
      Inp_BbPeriod, 
      Inp_BbDev, 
      moneyService
   );
   // Injeção dos MESMOS Filtros (Reúso!)
   strategyRange.AddValidator(timeValidator);
   strategyRange.AddValidator(lossValidator);

   // ---------------------------------------------------------
   // 5. REGISTRO NO CÉREBRO (KERNEL/MANAGER)
   // ---------------------------------------------------------
   // Aqui nós apenas entregamos as opções.
   // O StrategyManager decidirá a cada tick qual delas tem o maior Score.
   
   g_kernel.GetManager().Register(strategyTrend);
   g_kernel.GetManager().Register(strategyRange);

   PrintFormat(">>> [BOOT] Config: Risk=%.1f%% | DailyLimit=$%.2f | Strategies Loaded: 2", 
               Inp_RiskPercent, Inp_DailyLoss);
   
   Print(">>> [BOOT] Kernel is ACTIVE. Waiting for ticks.");
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function (SHUTDOWN)                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Print(">>> [SHUTDOWN] System halted.");
   
   // O Destrutor do Kernel limpa Manager, Session e Strategies registradas
   if(CheckPointer(g_kernel) == POINTER_DYNAMIC) delete g_kernel;
   
   // Nota sobre vazamento de memória em testes:
   // Objetos como 'moneyService' e validadores que foram passados como ponteiros
   // mas não têm ownership explícito podem ficar na memória até o terminal fechar.
   // Em produção C++, usaríamos smart pointers. No MQL5, o SO limpa o processo.
  }

//+------------------------------------------------------------------+
//| Expert tick function (EVENT LOOP)                                |
//+------------------------------------------------------------------+
void OnTick()
  {
   // Simplesmente repassa o pulso para o Kernel processar a decisão
   if(g_kernel != NULL) {
      g_kernel.OnTick();
   }
  }
//+------------------------------------------------------------------+