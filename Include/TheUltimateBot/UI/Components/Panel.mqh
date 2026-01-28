//+------------------------------------------------------------------+
//|                                                    Panel.mqh |
//|                                  Copyright 2026, TheUltimateBot  |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property strict

class Panel {
private:
   string m_name;
public:
   Panel(string name, int x, int y, int w, int h) {
      m_name = "TheUltimateBot_Pnl_" + name;
      
      if(ObjectFind(0, m_name) < 0) {
         ObjectCreate(0, m_name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      }
      
      // Estilo "Cerberus Dark"
      ObjectSetInteger(0, m_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, m_name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, m_name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, m_name, OBJPROP_XSIZE, w);
      ObjectSetInteger(0, m_name, OBJPROP_YSIZE, h);
      ObjectSetInteger(0, m_name, OBJPROP_BGCOLOR, ColorToARGB(clrBlack, 200)); // Preto Transparente
      ObjectSetInteger(0, m_name, OBJPROP_COLOR, clrDimGray); // Borda
      ObjectSetInteger(0, m_name, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, m_name, OBJPROP_BACK, false);
      ObjectSetInteger(0, m_name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, m_name, OBJPROP_HIDDEN, true);
   }

   ~Panel() {
      ObjectDelete(0, m_name);
   }
};
//+------------------------------------------------------------------+