//+------------------------------------------------------------------+
//|                                                        Types.mqh |
//|                                  Copyright 2026, TheUltimateBot  |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property strict

// Define a tendência macro do mercado
enum ETrendState {
   TREND_NEUTRAL  = 0, // Lateral ou indefinido
   TREND_BULLISH  = 1, // Tendência de Alta
   TREND_BEARISH  = 2  // Tendência de Baixa
};

// Define o nível de agressividade/volatilidade
enum EVolatilityState {
   VOL_LOW     = 0,    // Mercado lento/morto
   VOL_NORMAL  = 1,    // Fluxo padrão
   VOL_HIGH    = 2,    // Alta volatilidade
   VOL_EXTREME = 3     // Notícias/Crash (Perigo!)
};

// Define o resultado de uma operação (para logs e estatísticas)
enum ETradeResult {
   RESULT_PENDING,
   RESULT_WIN,
   RESULT_LOSS,
   RESULT_BREAKEVEN
};

// Estrutura auxiliar para preços (evita passar ask/bid soltos)
struct MarketQuote {
   double bid;
   double ask;
   datetime time;
};
//+------------------------------------------------------------------+
