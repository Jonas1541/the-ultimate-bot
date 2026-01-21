//+------------------------------------------------------------------+
//|                                                      MainBot.mq5 |
//|                                  Copyright 2026, TheUltimateBot  |
//|                                     https://www.yourdomain.com   |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property link      "https://www.yourdomain.com"
#property version   "1.00"

// --- IMPORTS ---
// Usamos <...> para buscar direto na pasta MQL5/Include
#include <TheUltimateBot/Core/StrategyManager.mqh>
#include <TheUltimateBot/Analysis/MarketRegime.mqh>
#include <TheUltimateBot/Domain/MarketState.mqh>

// Import das Estratégias ("Beans") que vamos registrar
#include <TheUltimateBot/Operations/Trend/MovingAvgCross.mqh>

// --- INPUTS DO USUÁRIO ---
// Parâmetros configuráveis na janela do robô
input group    "Estratégia: Médias Móveis"
input int      Inp_FastMA     = 9;          // Periodo Média Rápida
input int      Inp_SlowMA     = 21;         // Periodo Média Lenta

// --- OBJETOS GLOBAIS (SINGLETONS) ---
// Em C++, precisamos gerenciar esses ponteiros manualmente
StrategyManager *g_manager;
MarketRegime    *g_regime;
MarketState     *g_state;

//+------------------------------------------------------------------+
//| Expert initialization function (O "Main" do programa)            |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print(">>> [BOOT] INICIANDO THE ULTIMATE BOT...");

   // 1. Inicializa o DTO de Estado (O objeto que trafega dados)
   g_state = new MarketState();

   // 2. Inicializa o Analisador de Mercado (O "Olho")
   // Configurado para olhar o Timeframe M5 para definir a tendência macro
   g_regime = new MarketRegime(_Symbol, PERIOD_M5);

   // 3. Inicializa o Gerente de Estratégias (O "Cérebro")
   g_manager = new StrategyManager();

   // --- INJEÇÃO DE DEPENDÊNCIA (Manual) ---
   // Aqui registramos os "Beans" no nosso Container.
   // Estamos criando a estratégia de Cruzamento para rodar no M1 (scalping)
   // mas respeitando a tendência do M5 (que o g_regime analisa)
   
   MovingAvgCross *maStrategy = new MovingAvgCross(_Symbol, PERIOD_M1, Inp_FastMA, Inp_SlowMA);
   g_manager.Register(maStrategy);

   Print(">>> [BOOT] SISTEMA PRONTO. AGUARDANDO TICKS.");
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function (Desligamento)                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Print(">>> [SHUTDOWN] DESLIGANDO SISTEMA E LIMPANDO MEMÓRIA...");
   
   // Limpeza de memória rigorosa (Evita Memory Leaks na VPS)
   if(CheckPointer(g_manager) == POINTER_DYNAMIC) delete g_manager;
   if(CheckPointer(g_regime) == POINTER_DYNAMIC) delete g_regime;
   if(CheckPointer(g_state) == POINTER_DYNAMIC) delete g_state;
  }

//+------------------------------------------------------------------+
//| Expert tick function (O Loop Infinito)                           |
//+------------------------------------------------------------------+
void OnTick()
  {
   // 1. ANÁLISE: Atualiza a visão de mercado
   // O Regime lê os indicadores (ADX, ATR) e preenche o g_state
   g_regime.UpdateState(g_state);

   // 2. DECISÃO E EXECUÇÃO
   // O Gerente passa o g_state para as estratégias e pergunta:
   // "Quem quer operar neste cenário?" -> Executa a vencedora.
   g_manager.OnTick(g_state);
  }
//+------------------------------------------------------------------+