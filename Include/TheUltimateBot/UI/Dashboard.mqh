//+------------------------------------------------------------------+
//|                                                    Dashboard.mqh |
//|                                  Copyright 2026, TheUltimateBot  |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property strict

#include "../Core/Kernel.mqh"
#include "Components/SimpleLabel.mqh"
#include "Components/Panel.mqh"

class Dashboard {
private:
   Kernel* m_kernel;
   double  m_scale; // Fator de escala (ex: 1.0, 1.5)
   
   // Layout Elements
   Panel* m_bg;
   SimpleLabel* m_lblTitle;
   SimpleLabel* m_lblStrategy;
   SimpleLabel* m_lblStatus;
   SimpleLabel* m_lblProfitHeader;
   SimpleLabel* m_lblProfitValue;
   SimpleLabel* m_lblStats;
   SimpleLabel* m_lblLastLog; // <--- NOVO: Mostra o log na tela
   
   string m_btnName;

   // Função auxiliar para escalar coordenadas e tamanhos
   int S(int value) { return (int)(value * m_scale); }
   // Função auxiliar para escalar fonte (cresce mais agressivamente)
   int F(int value) { return (int)(MathMax(10, value * m_scale)); }

public:
   Dashboard(Kernel* kernel, double scaleFactor=1.0) {
      m_kernel = kernel;
      m_scale = scaleFactor;
      m_btnName = "TheUltimateBot_Btn_Panic";
      
      // Layout Base (Expandido Agressivamente)
      int xBase = 50; 
      int yBase = 50;
      int width = 500; // Gigante
      int height = 400; // Gigante
      
      // 1. Fundo Escuro
      m_bg = new Panel("MainBG", S(xBase), S(yBase), S(width), S(height));

      // 2. Cabeçalho
      m_lblTitle = new SimpleLabel("Header", S(xBase+10), S(yBase+10), F(11), clrWhite, "Segoe UI Semibold");
      m_lblTitle.SetText("ULTIMATE BOT v1.04");

      // 3. Estratégia (Aumentado mais ainda)
      m_lblStrategy = new SimpleLabel("Strat", S(xBase+10), S(yBase+60), F(9), clrSilver, "Segoe UI");

      // 4. Status (Mais para baixo)
      m_lblStatus = new SimpleLabel("Status", S(xBase+10), S(yBase+95), F(9), clrLime, "Segoe UI");

      // 5. Lucro (Mais para baixo)
      m_lblProfitHeader = new SimpleLabel("GainLbl", S(xBase+10), S(yBase+140), F(10), clrWhite, "Segoe UI");
      m_lblProfitHeader.SetText("Resultado do Dia:");
      
      m_lblProfitValue = new SimpleLabel("GainVal", S(xBase+10), S(yBase+175), F(18), clrGold, "Segoe UI Bold");

      // 6. Último Log (Bem mais para baixo)
      m_lblLastLog = new SimpleLabel("Log", S(xBase+15), S(yBase+260), F(8), clrLightCyan, "Consolas");
      m_lblLastLog.SetText("> Inicializando...");

      // 7. Stats (Fundo do painel)
      m_lblStats = new SimpleLabel("Stats", S(xBase+15), S(yBase+300), F(8), clrGray, "Consolas");

      // 8. Botão Pânico (Margem segura)
      if(ObjectFind(0, m_btnName) < 0) ObjectCreate(0, m_btnName, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, m_btnName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, m_btnName, OBJPROP_XDISTANCE, S(xBase+15));
      ObjectSetInteger(0, m_btnName, OBJPROP_YDISTANCE, S(yBase+340));
      ObjectSetInteger(0, m_btnName, OBJPROP_XSIZE, S(width-30));
      ObjectSetInteger(0, m_btnName, OBJPROP_YSIZE, S(40)); // Botão maior
      ObjectSetInteger(0, m_btnName, OBJPROP_BGCOLOR, clrRed);
      ObjectSetInteger(0, m_btnName, OBJPROP_COLOR, clrWhite);
      ObjectSetString(0, m_btnName, OBJPROP_TEXT, "PÂNICO: FECHAR TUDO");
      ObjectSetInteger(0, m_btnName, OBJPROP_HIDDEN, false); // Força visibilidade para teste
      ObjectSetInteger(0, m_btnName, OBJPROP_ZORDER, 100); // Garante que fique "por cima" de tudo
   }

   ~Dashboard() {
      if(CheckPointer(m_bg) == POINTER_DYNAMIC) delete m_bg;
      if(CheckPointer(m_lblTitle) == POINTER_DYNAMIC) delete m_lblTitle;
      if(CheckPointer(m_lblStrategy) == POINTER_DYNAMIC) delete m_lblStrategy;
      if(CheckPointer(m_lblStatus) == POINTER_DYNAMIC) delete m_lblStatus;
      if(CheckPointer(m_lblProfitHeader) == POINTER_DYNAMIC) delete m_lblProfitHeader;
      if(CheckPointer(m_lblProfitValue) == POINTER_DYNAMIC) delete m_lblProfitValue;
      if(CheckPointer(m_lblStats) == POINTER_DYNAMIC) delete m_lblStats;
      if(CheckPointer(m_lblLastLog) == POINTER_DYNAMIC) delete m_lblLastLog;
      ObjectDelete(0, m_btnName);
   }

   void Update() {
      if(m_kernel == NULL) return;

      // --- LUCRO ---
      double profit = m_kernel.GetSession().GetDailyProfit();
      m_lblProfitValue.SetText(StringFormat("R$ %.2f", profit));
      if(profit > 0) m_lblProfitValue.SetColor(clrLime);
      else if(profit < 0) m_lblProfitValue.SetColor(clrTomato);
      else m_lblProfitValue.SetColor(clrGold);

      // --- STATUS ESTRATÉGIA ---
      // Acessando o nome da estratégia via Kernel (precisaremos expor isso no próximo passo)
      // Por enquanto, hardcoded para o teste
      m_lblStrategy.SetText("Mode: Cerberus Hybrid");
      if(m_kernel.IsHalted()) {
         m_lblStatus.SetText("System: !!! HALTED !!!");
         m_lblStatus.SetColor(clrRed);
      } else {
         m_lblStatus.SetText("System: ACTIVE | Monitoring...");
         m_lblStatus.SetColor(clrLime);
      }

      // --- HORA ---
      m_lblStats.SetText("Srv: " + TimeToString(TimeCurrent(), TIME_SECONDS));
      
      // Força o redesenho COMPLETO do gráfico para garantir que o texto atualize
      ChartRedraw();
   }
   
   // Método público para enviar logs para a tela
   void Log(string message) {
      m_lblLastLog.SetText("> " + message);
   }
};
//+------------------------------------------------------------------+