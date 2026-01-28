#include <TheUltimateBot/Domain/ISignal.mqh>
#include <TheUltimateBot/Domain/Types.mqh>
#include <TheUltimateBot/Commands/OpenOrderCommand.mqh>
#include <TheUltimateBot/Infrastructure/PositionService.mqh>
#include <TheUltimateBot/Domain/IMarketDataProvider.mqh> // <--- Interface
#include <TheUltimateBot/Infrastructure/MT5MarketDataProvider.mqh> // <--- Default Impl (Temporary instantiation if not injected)

class CerberusStrategy : public ISignal {
private:
   string m_symbol;
   ENUM_TIMEFRAMES m_signalTF;
   ENUM_TIMEFRAMES m_macroTF;
   int m_emaFast, m_emaSlow;
   int m_macroFast, m_macroSlow;
   
   int m_breakoutLookback;
   
   IMarketDataProvider* m_marketData; // <--- Dependência
   bool m_ownsData; // flag para saber se deletamos (caso criado internamente)

   double Pt() { return SymbolInfoDouble(m_symbol, SYMBOL_POINT); }

   // Lógica de Tendência usando o Provider
   int GetTrendScore(ENUM_TIMEFRAMES tf, int fast, int slow) {
      // Usa o provider para buscar as EMAs
      double valFast = m_marketData.GetEMA(m_symbol, tf, fast, 0);
      double valSlow = m_marketData.GetEMA(m_symbol, tf, slow, 0);

      if(valFast == 0.0 || valSlow == 0.0) return 0;

      if(valFast > valSlow) return 1;  // Alta
      if(valFast < valSlow) return -1; // Baixa
      return 0;
   }

   // Lógica de Rompimento usando o Provider
   int GetBreakoutDir() {
      MqlRates rates[];
      int lookback = m_breakoutLookback + 2;
      
      // Usa o provider para buscar candles
      if(m_marketData.GetRates(m_symbol, m_signalTF, lookback, rates) < lookback) return 0;

      double closeNow = rates[1].close; // Vela fechada anterior
      double highest = rates[2].high;
      double lowest  = rates[2].low;

      for(int i=2; i<lookback; i++) {
         if(rates[i].high > highest) highest = rates[i].high;
         if(rates[i].low < lowest) lowest = rates[i].low;
      }

      if(closeNow > highest) return 1; // Rompeu topo
      if(closeNow < lowest) return -1; // Rompeu fundo
      return 0;
   }

public:
   // Construtor: Agora aceita um Provider opcional (se NULL, cria o Default)
   CerberusStrategy(string symbol, IMarketDataProvider* provider = NULL) {
      m_symbol = symbol;
      
      if(provider == NULL) {
         m_marketData = new MT5MarketDataProvider();
         m_ownsData = true; // Somos donos, deletamos no destructor
      } else {
         m_marketData = provider;
         m_ownsData = false;
      }

      // Configurações Padrão
      m_signalTF = PERIOD_M1;
      m_macroTF  = PERIOD_M15;
      m_emaFast = 9; m_emaSlow = 21;
      m_macroFast = 50; m_macroSlow = 200;
      m_breakoutLookback = 20;
   }
   
   ~CerberusStrategy() {
      if(m_ownsData && CheckPointer(m_marketData) == POINTER_DYNAMIC) {
         delete m_marketData;
      }
   }

   string GetName() override { return "Cerberus (Hybrid Scalper)"; }

   double GetScore(MarketState &state) override {
      // 1. Filtros Básicos
      string reason;
      if(!ValidateAll(reason)) return 0.0;
      
      // 2. Se já tem posição, mantém prioridade
      if(PositionService::Get().HasOpenPosition(m_symbol)) return 1.0;

      // 3. Análise de Tendência
      int micro = GetTrendScore(m_signalTF, m_emaFast, m_emaSlow);
      int macro = GetTrendScore(m_macroTF, m_macroFast, m_macroSlow);

      if(micro == macro && micro != 0) return 0.95;
      
      return 0.1;
   }

   ICommand* Tick(MarketState &state) override {
      if(PositionService::Get().HasOpenPosition(m_symbol)) return NULL;

      string ignore;
      if(!ValidateAll(ignore)) return NULL;

      // --- LÓGICA DE SINAL ---
      int micro = GetTrendScore(m_signalTF, m_emaFast, m_emaSlow);
      int macro = GetTrendScore(m_macroTF, m_macroFast, m_macroSlow);
      int breakout = GetBreakoutDir();

      // CONFLUÊNCIA TRIPLA
      if(micro == 1 && macro == 1 && breakout == 1) {
         double sl = state.ask - 300 * Pt();
         double tp = state.ask + 100 * Pt();
         return new OpenOrderCommand(m_symbol, ORDER_TYPE_BUY, 1.0, state.ask, sl, tp, "Cerberus Buy");
      }

      if(micro == -1 && macro == -1 && breakout == -1) {
         double sl = state.bid + 300 * Pt();
         double tp = state.bid - 100 * Pt();
         return new OpenOrderCommand(m_symbol, ORDER_TYPE_SELL, 1.0, state.bid, sl, tp, "Cerberus Sell");
      }

      return NULL;
   }
};
//+------------------------------------------------------------------+