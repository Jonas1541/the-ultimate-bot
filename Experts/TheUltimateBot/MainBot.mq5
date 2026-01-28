//+------------------------------------------------------------------+
//|                                                      MainBot.mq5 |
//|                                  Copyright 2026, TheUltimateBot  |
//|                                     https://www.yourdomain.com   |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property link      "https://www.yourdomain.com"
#property version   "1.04" // UI Scaling + Panic Button + Logging

// --- IMPORTS DO NÚCLEO (CORE) ---
#include <TheUltimateBot/Core/Kernel.mqh>

// --- IMPORTS DE SERVIÇOS E VALIDADORES ---
#include <TheUltimateBot/Services/Risk/ConservativeRisk.mqh>
#include <TheUltimateBot/Services/Time/TimeFilter.mqh>
#include <TheUltimateBot/Validators/DailyLossValidator.mqh>
#include <TheUltimateBot/Validators/TradingHoursValidator.mqh>
#include <TheUltimateBot/UI/Dashboard.mqh>

// --- IMPORTS DE ESTRATÉGIAS ---
// Usando a Híbrida (Cerberus) para garantir compatibilidade com Wine/Linux
#include <TheUltimateBot/Operations/Hybrid/CerberusStrategy.mqh>

// --- INPUTS: INTERFACE GRÁFICA (NOVO) ---
input group    "Interface Gráfica"
input double   Inp_UIScale     = 1.2;       // Fator de Escala (1.0 = Padrão, 1.3 = Grande)

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
Dashboard *g_dashboard;

//+------------------------------------------------------------------+
//| Expert initialization function (BOOTSTRAP)                       |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print(">>> [BOOT] SYSTEM STARTUP sequence initiated.");

   // 1. INICIALIZA O KERNEL
   g_kernel = Kernel::Get();

   // 2. CRIAÇÃO DOS SERVIÇOS AUXILIARES
   IMoney* moneyService = new ConservativeRisk(_Symbol, Inp_RiskPercent);
   TimeFilter* timeService = new TimeFilter(Inp_StartHour, Inp_StartMin, Inp_EndHour, Inp_EndMin);

   // 3. CRIAÇÃO DOS VALIDADORES
   TradingHoursValidator* timeValidator = new TradingHoursValidator(timeService);
   SessionContext* session = g_kernel.GetSession();
   DailyLossValidator* lossValidator = new DailyLossValidator(session, Inp_DailyLoss);

   // ---------------------------------------------------------
   // 4. CONFIGURAÇÃO DA ESTRATÉGIA "CERBERUS"
   // ---------------------------------------------------------
   CerberusStrategy* cerberus = new CerberusStrategy(_Symbol);
   
   // Injeção dos Filtros
   cerberus.AddValidator(timeValidator);
   cerberus.AddValidator(lossValidator);

   // ---------------------------------------------------------
   // 5. REGISTRO NO CÉREBRO
   // ---------------------------------------------------------
   g_kernel.GetManager().Register(cerberus);

   // --- INICIALIZA A UI (AGORA COM ESCALA) ---
   // Passamos o fator de escala definido no input
   g_dashboard = new Dashboard(g_kernel, Inp_UIScale);
   
   // Força habilitação de cliques e eventos de objeto
   ChartSetInteger(0, CHART_EVENT_OBJECT_CREATE, true);
   ChartSetInteger(0, CHART_EVENT_OBJECT_DELETE, true);
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true); // Opcional, para debug
   
   PrintFormat(">>> [BOOT] Config: Risk=%.1f%% | UI Scale=%.1f | Strategy: Cerberus", 
               Inp_RiskPercent, Inp_UIScale);
   
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function (SHUTDOWN)                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Print(">>> [SHUTDOWN] System halted.");
   
   if(CheckPointer(g_kernel) == POINTER_DYNAMIC) delete g_kernel;
   if(CheckPointer(g_dashboard) == POINTER_DYNAMIC) delete g_dashboard;
  }

//+------------------------------------------------------------------+
//| Expert tick function (EVENT LOOP)                                |
//+------------------------------------------------------------------+
void OnTick()
  {
   // 1. CÉREBRO: Processa Lógica de Mercado
   if(g_kernel != NULL) {
      g_kernel.OnTick();
   }

   // 2. OLHOS: Atualiza Interface e Logs
   if(g_dashboard != NULL) {
      g_dashboard.Update();
      
      // Lógica Simples de Log Visual
      if(PositionSelect(_Symbol)) {
         long type = PositionGetInteger(POSITION_TYPE);
         double profit = PositionGetDouble(POSITION_PROFIT);
         string typeStr = (type == POSITION_TYPE_BUY) ? "COMPRADO" : "VENDIDO";
         g_dashboard.Log(StringFormat("%s | Float: %.2f", typeStr, profit));
      } 
      else {
         g_dashboard.Log("Monitorando Mercado (Cerberus)...");
      }
      
      // --- FALLBACK (POLLING): Verifica manualmente o Botão de Pânico ---
      if(ObjectGetInteger(0, "TheUltimateBot_Btn_Panic", OBJPROP_STATE) == 1) {
         Print(">>> [POLLING UI] Panic Button Pressed!");
         
         ObjectSetInteger(0, "TheUltimateBot_Btn_Panic", OBJPROP_STATE, false);
         ChartRedraw();
         
         if(g_dashboard != NULL) g_dashboard.Log("!!! PÂNICO (VIA POLLING) !!!");
         
         if(g_kernel != NULL) {
             g_kernel.Panic();
             Alert("!!! SYSTEM PANIC PROTECTED (POLLING) !!!");
         }
      }
   }
  }

//+------------------------------------------------------------------+
//| Chart Event function (INTERAÇÃO UI)                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   // DEBUG BRUTO: Imprimir qualquer evento que não seja MouseMove (pra não floodar)
   if(id != CHARTEVENT_MOUSE_MOVE) {
      PrintFormat(">>> [EVENT] ID=%d | LParam=%d | DParam=%.2f | SParam='%s'", id, lparam, dparam, sparam);
   }

   // Detecta clique no Botão de Pânico
   if(id == CHARTEVENT_OBJECT_CLICK) {
       // DEBUG GLOBAL DE CLIQUES
       PrintFormat(">>> [UI DEBUG] Click Event Detected! Object: '%s'", sparam);
       
       if(StringFind(sparam, "Panic") >= 0) {
          Print(">>> [PANIC] CLICK CONFIRMED via StringFind match!");
          
          if(g_dashboard != NULL) g_dashboard.Log("!!! PÂNICO CONFIRMADO !!!");
          
          // Feedback visual: O botão volta ao estado normal (desapertado)
          ObjectSetInteger(0, "TheUltimateBot_Btn_Panic", OBJPROP_STATE, false);
          ChartRedraw();
          
          // Aciona o Kernel
          if(g_kernel != NULL) {
             g_kernel.Panic();
             Alert("!!! SYSTEM PANIC PROTECTED !!! ALL POSITIONS CLOSED.");
          }
       }
   }
  }
//+------------------------------------------------------------------+