//+------------------------------------------------------------------+
//|                                                    Dashboard.mqh |
//|                                  Copyright 2026, TheUltimateBot  |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property strict

#include "../Core/Kernel.mqh"
#include "Components/SimpleLabel.mqh"

class Dashboard {
private:
   // Elementos da Interface
   SimpleLabel* m_lblTitle;
   SimpleLabel* m_lblTime;
   SimpleLabel* m_lblProfit;
   SimpleLabel* m_lblRegime;
   SimpleLabel* m_lblStrategy;
   
   Kernel* m_kernel; // Referência ao cérebro para ler dados

public:
   Dashboard(Kernel* kernel) {
      m_kernel = kernel;
      
      // Layout (X, Y)
      int x = 20;
      int yStart = 20;
      int step = 20;

      // 1. Título
      m_lblTitle = new SimpleLabel("Title", x, yStart, 12, clrGold);
      m_lblTitle.SetText(":: TheUltimateBot v1.02 ::");

      // 2. Horário Servidor
      m_lblTime = new SimpleLabel("Time", x, yStart + step*1, 10, clrGray);

      // 3. Lucro do Dia (Destaque)
      m_lblProfit = new SimpleLabel("Profit", x, yStart + step*2, 11, clrWhite);

      // 4. Regime de Mercado (Diagnóstico)
      m_lblRegime = new SimpleLabel("Regime", x, yStart + step*4, 10, clrLightSkyBlue);
      
      // 5. Estratégia Ativa (O que ele quer fazer)
      m_lblStrategy = new SimpleLabel("Strat", x, yStart + step*5, 10, clrLightSlateGray);
   }

   ~Dashboard() {
      if(CheckPointer(m_lblTitle) == POINTER_DYNAMIC) delete m_lblTitle;
      if(CheckPointer(m_lblTime) == POINTER_DYNAMIC) delete m_lblTime;
      if(CheckPointer(m_lblProfit) == POINTER_DYNAMIC) delete m_lblProfit;
      if(CheckPointer(m_lblRegime) == POINTER_DYNAMIC) delete m_lblRegime;
      if(CheckPointer(m_lblStrategy) == POINTER_DYNAMIC) delete m_lblStrategy;
   }

   // Chamado a cada Tick para redesenhar a tela
   void Update() {
      if(m_kernel == NULL) return;

      // --- DADOS DO TEMPO ---
      m_lblTime.SetText("Server Time: " + TimeToString(TimeCurrent(), TIME_SECONDS));

      // --- DADOS FINANCEIROS ---
      double profit = m_kernel.GetSession().GetDailyProfit();
      string profitText = StringFormat("Daily P/L: $ %.2f", profit);
      m_lblProfit.SetText(profitText);
      
      // Cor condicional: Verde se lucro, Vermelho se prejuízo
      if(profit >= 0) m_lblProfit.SetColor(clrLimeGreen);
      else m_lblProfit.SetColor(clrTomato);

      // --- DADOS DE INTELIGÊNCIA ---
      // Como o MarketState não é público direto, acessamos via lógica (futuramente podemos expor getters no Kernel)
      // Por enquanto, vamos mostrar o status geral
      m_lblRegime.SetText("[Diagnóstico] System Running...");

      // Força o MT5 a redesenhar a tela imediatamente
      ChartRedraw();
   }
};
//+------------------------------------------------------------------+