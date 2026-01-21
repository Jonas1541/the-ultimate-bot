// ... Imports anteriores ...
#include <TheUltimateBot/Core/Kernel.mqh>
#include <TheUltimateBot/Operations/Trend/MovingAvgCross.mqh>
#include <TheUltimateBot/Services/Risk/ConservativeRisk.mqh>
#include <TheUltimateBot/Services/Time/TimeFilter.mqh>
#include <TheUltimateBot/Validators/DailyLossValidator.mqh>

// NOVO IMPORT
#include <TheUltimateBot/Validators/TradingHoursValidator.mqh>

// ... Inputs (Manter iguais) ...
// (Vou omitir os inputs aqui pra economizar espaço, mantenha os que você já tem)
input group    "Estratégia: Médias Móveis"
input int      Inp_FastMA     = 9;
input int      Inp_SlowMA     = 21;
input group    "Gerenciamento de Risco"
input double   Inp_RiskPercent = 1.0;
input group    "Segurança Global"
input double   Inp_DailyLoss   = 50.0;
input group    "Horário de Negociação"
input int      Inp_StartHour  = 9;
input int      Inp_StartMin   = 15;
input int      Inp_EndHour    = 16;
input int      Inp_EndMin     = 30;

Kernel *g_kernel;

int OnInit()
  {
   Print(">>> [BOOT] SYSTEM STARTUP sequence initiated.");

   g_kernel = Kernel::Get();

   // --- SERVIÇOS ---
   IMoney* moneyService = new ConservativeRisk(_Symbol, Inp_RiskPercent);
   TimeFilter* timeService = new TimeFilter(Inp_StartHour, Inp_StartMin, Inp_EndHour, Inp_EndMin);

   // --- VALIDADORES (FILTROS) ---
   // 1. Cria o Validador de Horário (Envelopando o serviço de tempo)
   TradingHoursValidator* timeValidator = new TradingHoursValidator(timeService);

   // 2. Cria o Validador de Loss (Usando a sessão do Kernel)
   DailyLossValidator* lossValidator = new DailyLossValidator(g_kernel.GetSession(), Inp_DailyLoss);

   // --- ESTRATÉGIA ---
   MovingAvgCross* strategy = new MovingAvgCross(
      _Symbol, 
      PERIOD_M1, 
      Inp_FastMA, 
      Inp_SlowMA, 
      moneyService
      // Note: Não passamos mais o timeService no construtor!
   );
   
   // --- PLUGANDO OS FILTROS NA ESTRATÉGIA ---
   // Aqui mora a flexibilidade: Podemos adicionar quantos quisermos
   strategy.AddValidator(timeValidator);
   strategy.AddValidator(lossValidator);

   // Registra no Gerente
   g_kernel.GetManager().Register(strategy);

   Print(">>> [BOOT] Kernel ACTIVE. Validators Configured.");
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   if(CheckPointer(g_kernel) == POINTER_DYNAMIC) delete g_kernel;
   // Nota: Em C++ real, deveríamos limpar os validadores se a estratégia não for dona deles.
   // No MQL5, o SO limpa ao fechar, então para simplificar não faremos a limpeza manual fina aqui.
  }

void OnTick()
  {
   if(g_kernel != NULL) g_kernel.OnTick();
  }