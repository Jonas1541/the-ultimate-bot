//+------------------------------------------------------------------+
//|                                                  SimpleLabel.mqh |
//|                                  Copyright 2026, TheUltimateBot  |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property strict

class SimpleLabel {
private:
   string m_name;
   
public:
   SimpleLabel(string name, int x, int y, int fontSize=10, color clr=clrWhite) {
      m_name = "TheUltimateBot_Lbl_" + name;
      
      // Cria o objeto se não existir
      if(ObjectFind(0, m_name) < 0) {
         ObjectCreate(0, m_name, OBJ_LABEL, 0, 0, 0);
      }
      
      // Configuração Visual
      ObjectSetInteger(0, m_name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, m_name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, m_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetString(0, m_name, OBJPROP_FONT, "Consolas");
      ObjectSetInteger(0, m_name, OBJPROP_FONTSIZE, fontSize);
      ObjectSetInteger(0, m_name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, m_name, OBJPROP_BACK, false);
      ObjectSetInteger(0, m_name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, m_name, OBJPROP_HIDDEN, true); // Não aparece na lista de objetos (Ctrl+B)
   }

   ~SimpleLabel() {
      // Auto-limpeza: Se o objeto deletar, some da tela
      ObjectDelete(0, m_name);
   }

   void SetText(string text) {
      ObjectSetString(0, m_name, OBJPROP_TEXT, text);
   }

   void SetColor(color clr) {
      ObjectSetInteger(0, m_name, OBJPROP_COLOR, clr);
   }
};
//+------------------------------------------------------------------+