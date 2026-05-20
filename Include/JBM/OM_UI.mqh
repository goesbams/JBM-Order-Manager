//+------------------------------------------------------------------+
//|  OM_UI.mqh — Panel GUI                                           |
//|  TradingView-style order panel built with MQL5 chart objects     |
//|  Sections: Header · Order Type · Price · Qty · Exits ·           |
//|            Extra Settings · Order Info · Submit                  |
//+------------------------------------------------------------------+
#pragma once
#include <JBM/OM_Calc.mqh>
#include <JBM/OM_Exec.mqh>

// --- Panel color scheme ---
#define CLR_BG         C'30,30,30'
#define CLR_BG_LIGHT   C'45,45,45'
#define CLR_BUY        C'41,98,255'
#define CLR_SELL       C'220,50,50'
#define CLR_TEXT       clrWhite
#define CLR_TEXT_DIM   C'150,150,150'
#define CLR_BTN_SUBMIT C'41,98,255'
#define CLR_BORDER     C'70,70,70'
#define CLR_GREEN      C'0,200,100'
#define CLR_RED        C'220,50,50'

// --- Quantity modes ---
enum ENUM_QTY_MODE { QTY_UNITS, QTY_MARGIN_USD, QTY_PCT_BALANCE, QTY_RISK_USD, QTY_RISK_PCT };

// --- TP/SL modes ---
enum ENUM_EXIT_MODE { EXIT_PRICE, EXIT_PIPS, EXIT_PCT_PRICE, EXIT_REWARD_USD, EXIT_REWARD_PCT };

// --- Order type ---
enum ENUM_ORDER_TYPE_UI { OT_MARKET, OT_LIMIT, OT_STOP };

//+------------------------------------------------------------------+
class COrderPanel
  {
private:
   int               m_x, m_y;
   int               m_width;
   string            m_prefix;

   COrderCalc        *m_calc;
   COrderExec        *m_exec;

   // State
   bool              m_isBuy;
   ENUM_ORDER_TYPE_UI m_orderType;
   ENUM_QTY_MODE     m_qtyMode;
   ENUM_EXIT_MODE    m_tpMode;
   ENUM_EXIT_MODE    m_slMode;
   bool              m_tpEnabled;
   bool              m_slEnabled;
   string            m_tif;           // "GTC", "Day", "Week", "Month"

   double            m_entryPrice;
   double            m_qtyValue;
   double            m_tpValue;
   double            m_slValue;
   double            m_lots;          // calculated lots

   // Derived P&L
   double            m_tpPips, m_slPips;
   double            m_estProfit, m_estLoss;
   double            m_rr;
   double            m_tradeValue, m_marginReq, m_pipValue;

public:
   COrderPanel() : m_x(20), m_y(50), m_width(280), m_prefix("JBM_OM_"),
                   m_isBuy(true), m_orderType(OT_LIMIT),
                   m_qtyMode(QTY_RISK_PCT), m_tpMode(EXIT_PIPS), m_slMode(EXIT_PIPS),
                   m_tpEnabled(true), m_slEnabled(true), m_tif("GTC"),
                   m_entryPrice(0), m_qtyValue(1.0), m_tpValue(50), m_slValue(30),
                   m_calc(NULL), m_exec(NULL) {}

   void SetCalc(COrderCalc &calc) { m_calc = &calc; }
   void SetExec(COrderExec &exec) { m_exec = &exec; }

   //+------------------------------------------------------------------+
   bool Create(int x, int y)
     {
      m_x = x; m_y = y;
      string sym = Symbol();
      if(m_calc) m_calc.SetSymbol(sym);
      if(m_exec) m_exec.SetSymbol(sym);
      m_entryPrice = SymbolInfoDouble(sym, m_isBuy ? SYMBOL_ASK : SYMBOL_BID);

      _BuildPanel();
      Refresh();
      return true;
     }

   //+------------------------------------------------------------------+
   void Destroy()
     {
      ObjectsDeleteAll(0, m_prefix);
     }

   //+------------------------------------------------------------------+
   void OnTick()
     {
      _RecalcAll();
      _UpdatePriceDisplay();
      _UpdateOrderInfo();
      _UpdatePnLDisplay();
     }

   //+------------------------------------------------------------------+
   void Refresh()
     {
      _RecalcAll();
      _UpdateAll();
     }

   //+------------------------------------------------------------------+
   void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
     {
      if(id == CHARTEVENT_OBJECT_CLICK)
        {
         if(StringFind(sparam, m_prefix + "BTN_BUY") >= 0)    { m_isBuy = true;  _RecalcAll(); _UpdateAll(); }
         if(StringFind(sparam, m_prefix + "BTN_SELL") >= 0)   { m_isBuy = false; _RecalcAll(); _UpdateAll(); }
         if(StringFind(sparam, m_prefix + "BTN_MKT") >= 0)    { m_orderType = OT_MARKET; _UpdateAll(); }
         if(StringFind(sparam, m_prefix + "BTN_LMT") >= 0)    { m_orderType = OT_LIMIT;  _UpdateAll(); }
         if(StringFind(sparam, m_prefix + "BTN_STP") >= 0)    { m_orderType = OT_STOP;   _UpdateAll(); }
         if(StringFind(sparam, m_prefix + "BTN_SUBMIT") >= 0) { _SubmitOrder(); }
         if(StringFind(sparam, m_prefix + "TOG_TP") >= 0)     { m_tpEnabled = !m_tpEnabled; _UpdateAll(); }
         if(StringFind(sparam, m_prefix + "TOG_SL") >= 0)     { m_slEnabled = !m_slEnabled; _UpdateAll(); }
        }

      if(id == CHARTEVENT_OBJECT_ENDEDIT)
        {
         _ReadInputs(sparam);
         _RecalcAll();
         _UpdateAll();
        }
     }

   //+------------------------------------------------------------------+
private:
   //--- Build all panel objects (called once on Create)
   void _BuildPanel()
     {
      int y = m_y;
      int w = m_width;
      int x = m_x;

      // Background
      _Rect(m_prefix + "BG", x, y, w, 520, CLR_BG, CLR_BORDER);

      // --- Header ---
      _Label(m_prefix + "LBL_SYMBOL", x + 10, y + 8,  Symbol(), 13, CLR_TEXT, true);
      _Label(m_prefix + "LBL_BID",    x + 10, y + 28, "Bid: --", 10, CLR_SELL, false);
      _Label(m_prefix + "LBL_ASK",    x + 90, y + 28, "Ask: --", 10, CLR_BUY,  false);
      _Label(m_prefix + "LBL_SPR",    x + 180,y + 28, "Sprd: --", 10, CLR_TEXT_DIM, false);
      y += 55;

      // --- Buy / Sell buttons ---
      _Button(m_prefix + "BTN_BUY",  x + 5,        y, (w/2) - 8,  30, "BUY",  CLR_BUY,  CLR_TEXT);
      _Button(m_prefix + "BTN_SELL", x + (w/2) + 3, y, (w/2) - 8, 30, "SELL", CLR_SELL, CLR_TEXT);
      y += 38;

      // --- Order type tabs ---
      _Button(m_prefix + "BTN_MKT", x + 5,        y, (w/3) - 6, 25, "Market", CLR_BG_LIGHT, CLR_TEXT);
      _Button(m_prefix + "BTN_LMT", x + (w/3),    y, (w/3) - 4, 25, "Limit",  CLR_BG_LIGHT, CLR_TEXT);
      _Button(m_prefix + "BTN_STP", x + (w/3)*2+2,y, (w/3) - 6, 25, "Stop",   CLR_BG_LIGHT, CLR_TEXT);
      y += 35;

      // --- Entry Price (Limit/Stop) ---
      _Label(m_prefix + "LBL_PRICE", x + 10, y, "Entry Price", 9, CLR_TEXT_DIM, false);
      y += 16;
      _Edit(m_prefix + "EDT_PRICE", x + 5, y, w - 10, 24, "0.00000");
      y += 32;

      // --- Quantity ---
      _Label(m_prefix + "LBL_QTY", x + 10, y, "Quantity [Risk % ▼]", 9, CLR_TEXT_DIM, false);
      y += 16;
      _Edit(m_prefix + "EDT_QTY", x + 5, y, (w/2) - 8, 24, "1.0");
      _Label(m_prefix + "LBL_QTY_USD", x + (w/2) + 5, y + 5, "0.00 USD", 9, CLR_TEXT_DIM, false);
      y += 35;

      // --- EXITS header ---
      _Label(m_prefix + "LBL_EXITS", x + 10, y, "Exits", 10, CLR_TEXT, true);
      y += 22;

      // --- Take Profit ---
      _Label(m_prefix + "LBL_TP",     x + 10, y, "Take profit [Price ▼]", 9, CLR_TEXT_DIM, false);
      _Button(m_prefix + "TOG_TP",    x + w - 50, y - 2, 44, 18, "OFF", CLR_BG_LIGHT, CLR_TEXT_DIM);
      y += 18;
      _Edit(m_prefix + "EDT_TP",      x + 5, y, (w/2) - 8, 24, "0.00000");
      _Label(m_prefix + "LBL_TP_PIPS",x + (w/2) + 5, y + 5, "0.0 pips", 9, CLR_TEXT_DIM, false);
      y += 26;
      _Label(m_prefix + "LBL_TP_PNL", x + 10, y, "Est. Profit: --", 9, CLR_GREEN, false);
      y += 22;

      // --- Stop Loss ---
      _Label(m_prefix + "LBL_SL",     x + 10, y, "Stop loss [Price ▼]", 9, CLR_TEXT_DIM, false);
      _Button(m_prefix + "TOG_SL",    x + w - 50, y - 2, 44, 18, "OFF", CLR_BG_LIGHT, CLR_TEXT_DIM);
      y += 18;
      _Edit(m_prefix + "EDT_SL",      x + 5, y, (w/2) - 8, 24, "0.00000");
      _Label(m_prefix + "LBL_SL_PIPS",x + (w/2) + 5, y + 5, "0.0 pips", 9, CLR_TEXT_DIM, false);
      y += 26;
      _Label(m_prefix + "LBL_SL_PNL", x + 10, y, "Est. Loss: --", 9, CLR_RED, false);
      y += 22;

      // --- R:R Summary ---
      _Rect(m_prefix + "BG_RR", x + 5, y, w - 10, 30, CLR_BG_LIGHT, CLR_BORDER);
      _Label(m_prefix + "LBL_RR", x + 12, y + 8, "R:R: --   Risk: -- USD   Reward: -- USD", 9, CLR_TEXT_DIM, false);
      y += 38;

      // --- Extra settings ---
      _Label(m_prefix + "LBL_TIF", x + 10, y, "Time in Force: [Week ▼]", 9, CLR_TEXT_DIM, false);
      y += 22;

      // --- Order Info ---
      _Label(m_prefix + "LBL_INFO_HDR",  x + 10, y, "Order Info", 10, CLR_TEXT, true);
      y += 20;
      _Label(m_prefix + "LBL_TRDVAL",  x + 10, y,       "Trade Value:   --", 9, CLR_TEXT_DIM, false);
      y += 16;
      _Label(m_prefix + "LBL_MARGIN",  x + 10, y,       "Margin Req:    --", 9, CLR_TEXT_DIM, false);
      y += 16;
      _Label(m_prefix + "LBL_AVAIL",   x + 10, y,       "Avail Margin:  --", 9, CLR_TEXT_DIM, false);
      y += 16;
      _Label(m_prefix + "LBL_LEV",     x + 10, y,       "Leverage:      --", 9, CLR_TEXT_DIM, false);
      y += 16;
      _Label(m_prefix + "LBL_PIPVAL",  x + 10, y,       "Pip Value:     --", 9, CLR_TEXT_DIM, false);
      y += 24;

      // --- Submit button ---
      _Button(m_prefix + "BTN_SUBMIT", x + 5, y, w - 10, 38, "BUY @ --", CLR_BTN_SUBMIT, CLR_TEXT);

      ChartRedraw();
     }

   //--- Recalculate all derived values
   void _RecalcAll()
     {
      if(!m_calc) return;
      string sym = Symbol();

      double bid = SymbolInfoDouble(sym, SYMBOL_BID);
      double ask = SymbolInfoDouble(sym, SYMBOL_ASK);

      if(m_orderType == OT_MARKET)
         m_entryPrice = m_isBuy ? ask : bid;

      // Lots
      double slPips = (m_slEnabled && m_slValue > 0)
                      ? (m_slMode == EXIT_PIPS ? m_slValue : m_calc.PriceToPips(m_entryPrice, m_slValue))
                      : 0;

      switch(m_qtyMode)
        {
         case QTY_UNITS:
            m_lots = m_calc.NormalizeLots(m_qtyValue);
            break;
         case QTY_RISK_PCT:
            m_lots = (slPips > 0) ? m_calc.GetLotFromRiskPct(m_qtyValue, slPips, m_entryPrice) : 0;
            break;
         case QTY_RISK_USD:
            m_lots = (slPips > 0) ? m_calc.GetLotFromRiskUSD(m_qtyValue, slPips) : 0;
            break;
         case QTY_MARGIN_USD:
            m_lots = m_calc.GetLotFromMarginUSD(m_qtyValue,
                        m_isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, m_entryPrice);
            break;
         case QTY_PCT_BALANCE:
            m_lots = m_calc.GetLotFromBalancePct(m_qtyValue,
                        m_isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, m_entryPrice);
            break;
        }

      // TP pips
      if(m_tpEnabled && m_tpValue > 0)
        {
         m_tpPips    = (m_tpMode == EXIT_PIPS) ? m_tpValue : m_calc.PriceToPips(m_entryPrice, m_tpValue);
         m_estProfit = m_calc.EstimateProfit(m_lots, m_tpPips);
        }
      else { m_tpPips = 0; m_estProfit = 0; }

      // SL pips
      if(m_slEnabled && m_slValue > 0)
        {
         m_slPips  = slPips;
         m_estLoss = m_calc.EstimateProfit(m_lots, m_slPips);
        }
      else { m_slPips = 0; m_estLoss = 0; }

      m_rr         = m_calc.GetRR(m_tpPips, m_slPips);
      m_pipValue   = m_calc.GetPipValue(m_lots);
      m_tradeValue = m_calc.GetTradeValue(m_lots, m_entryPrice);
      m_marginReq  = m_calc.GetMarginRequired(
                        m_isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, m_lots, m_entryPrice);
     }

   //--- Update all display elements
   void _UpdateAll()
     {
      _UpdatePriceDisplay();
      _UpdateOrderInfo();
      _UpdatePnLDisplay();
      _UpdateSubmitButton();
      _UpdateDirectionButtons();
      _UpdateOrderTypeButtons();
      _UpdateToggleButtons();
      ChartRedraw();
     }

   void _UpdatePriceDisplay()
     {
      string sym = Symbol();
      double bid = SymbolInfoDouble(sym, SYMBOL_BID);
      double ask = SymbolInfoDouble(sym, SYMBOL_ASK);
      int    digs = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
      double sprd = (ask - bid) / m_calc.GetPipSize();

      _SetLabelText(m_prefix + "LBL_BID", "Bid: " + DoubleToString(bid, digs));
      _SetLabelText(m_prefix + "LBL_ASK", "Ask: " + DoubleToString(ask, digs));
      _SetLabelText(m_prefix + "LBL_SPR", "Sprd: " + DoubleToString(sprd, 1) + " pips");
     }

   void _UpdateOrderInfo()
     {
      string avail = DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_FREE), 2);
      string lev   = IntegerToString((int)AccountInfoInteger(ACCOUNT_LEVERAGE));

      _SetLabelText(m_prefix + "LBL_TRDVAL", "Trade Value:   " + DoubleToString(m_tradeValue, 2) + " USD");
      _SetLabelText(m_prefix + "LBL_MARGIN", "Margin Req:    " + DoubleToString(m_marginReq, 2) + " USD");
      _SetLabelText(m_prefix + "LBL_AVAIL",  "Avail Margin:  " + avail + " USD");
      _SetLabelText(m_prefix + "LBL_LEV",    "Leverage:      " + lev + ":1");
      _SetLabelText(m_prefix + "LBL_PIPVAL", "Pip Value:     " + DoubleToString(m_pipValue, 2) + " USD");
     }

   void _UpdatePnLDisplay()
     {
      string tpText = m_tpEnabled
         ? "Est. Profit: +" + DoubleToString(m_estProfit, 2) + " USD  (" + DoubleToString(m_tpPips, 1) + " pips)"
         : "Take Profit: OFF";
      string slText = m_slEnabled
         ? "Est. Loss:  -" + DoubleToString(m_estLoss, 2) + " USD  (" + DoubleToString(m_slPips, 1) + " pips)"
         : "Stop Loss: OFF";
      string rrText = "R:R: 1:" + DoubleToString(m_rr, 2)
                    + "   Risk: " + DoubleToString(m_estLoss, 0) + " USD"
                    + "   Reward: " + DoubleToString(m_estProfit, 0) + " USD";

      _SetLabelText(m_prefix + "LBL_TP_PIPS", DoubleToString(m_tpPips, 1) + " pips");
      _SetLabelText(m_prefix + "LBL_SL_PIPS", DoubleToString(m_slPips, 1) + " pips");
      _SetLabelText(m_prefix + "LBL_TP_PNL", tpText);
      _SetLabelText(m_prefix + "LBL_SL_PNL", slText);
      _SetLabelText(m_prefix + "LBL_RR", rrText);
     }

   void _UpdateSubmitButton()
     {
      string sym  = Symbol();
      int    digs = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
      string dir  = m_isBuy ? "BUY" : "SELL";
      string type = (m_orderType == OT_MARKET) ? "MARKET"
                  : (m_orderType == OT_LIMIT)  ? "LIMIT" : "STOP";
      string text = dir + " " + DoubleToString(m_lots, 2) + " lots"
                  + " @ " + DoubleToString(m_entryPrice, digs) + " " + type;

      _SetButtonText(m_prefix + "BTN_SUBMIT", text);
      _SetButtonColor(m_prefix + "BTN_SUBMIT", m_isBuy ? CLR_BUY : CLR_SELL);
     }

   void _UpdateDirectionButtons()
     {
      _SetButtonColor(m_prefix + "BTN_BUY",  m_isBuy  ? CLR_BUY      : CLR_BG_LIGHT);
      _SetButtonColor(m_prefix + "BTN_SELL", !m_isBuy ? CLR_SELL     : CLR_BG_LIGHT);
     }

   void _UpdateOrderTypeButtons()
     {
      color active = CLR_TEXT; color inactive = CLR_BG_LIGHT;
      _SetButtonColor(m_prefix + "BTN_MKT", m_orderType == OT_MARKET ? C'60,60,80' : inactive);
      _SetButtonColor(m_prefix + "BTN_LMT", m_orderType == OT_LIMIT  ? C'60,60,80' : inactive);
      _SetButtonColor(m_prefix + "BTN_STP", m_orderType == OT_STOP   ? C'60,60,80' : inactive);

      // Show/hide price input
      bool showPrice = (m_orderType != OT_MARKET);
      ObjectSetInteger(0, m_prefix + "EDT_PRICE", OBJPROP_TIMEFRAMES,
                       showPrice ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS);
      ObjectSetInteger(0, m_prefix + "LBL_PRICE", OBJPROP_TIMEFRAMES,
                       showPrice ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS);
     }

   void _UpdateToggleButtons()
     {
      _SetButtonText(m_prefix + "TOG_TP", m_tpEnabled ? "ON" : "OFF");
      _SetButtonColor(m_prefix + "TOG_TP", m_tpEnabled ? CLR_GREEN : CLR_BG_LIGHT);
      _SetButtonText(m_prefix + "TOG_SL", m_slEnabled ? "ON" : "OFF");
      _SetButtonColor(m_prefix + "TOG_SL", m_slEnabled ? CLR_GREEN : CLR_BG_LIGHT);
     }

   //--- Read edited inputs
   void _ReadInputs(string objName)
     {
      string val = ObjectGetString(0, objName, OBJPROP_TEXT);
      if(objName == m_prefix + "EDT_PRICE") m_entryPrice = StringToDouble(val);
      if(objName == m_prefix + "EDT_QTY")   m_qtyValue   = StringToDouble(val);
      if(objName == m_prefix + "EDT_TP")    m_tpValue    = StringToDouble(val);
      if(objName == m_prefix + "EDT_SL")    m_slValue    = StringToDouble(val);
     }

   //--- Submit order
   void _SubmitOrder()
     {
      if(!m_exec || m_lots <= 0) { Alert("Invalid lot size"); return; }

      double sl = (m_slEnabled && m_slValue > 0) ? m_slValue : 0;
      double tp = (m_tpEnabled && m_tpValue > 0) ? m_tpValue : 0;

      // Convert pips to price if needed
      if(m_slMode == EXIT_PIPS && sl > 0)
         sl = m_isBuy ? m_entryPrice - sl * m_calc.GetPipSize()
                      : m_entryPrice + sl * m_calc.GetPipSize();
      if(m_tpMode == EXIT_PIPS && tp > 0)
         tp = m_isBuy ? m_entryPrice + tp * m_calc.GetPipSize()
                      : m_entryPrice - tp * m_calc.GetPipSize();

      datetime expiry = m_exec.GetExpiry(m_tif);

      switch(m_orderType)
        {
         case OT_MARKET: m_exec.PlaceMarket(m_isBuy, m_lots, sl, tp); break;
         case OT_LIMIT:  m_exec.PlaceLimit (m_isBuy, m_lots, m_entryPrice, sl, tp, expiry); break;
         case OT_STOP:   m_exec.PlaceStop  (m_isBuy, m_lots, m_entryPrice, sl, tp, expiry); break;
        }
     }

   //+------------------------------------------------------------------+
   //--- Helper: create objects
   void _Rect(string name, int x, int y, int w, int h, color bg, color border)
     {
      ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE,  x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE,  y);
      ObjectSetInteger(0, name, OBJPROP_XSIZE,      w);
      ObjectSetInteger(0, name, OBJPROP_YSIZE,      h);
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR,    bg);
      ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, border);
      ObjectSetInteger(0, name, OBJPROP_CORNER,     CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_BACK,       false);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
     }

   void _Label(string name, int x, int y, string text, int fontSize, color clr, bool bold)
     {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE,  x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE,  y);
      ObjectSetString (0, name, OBJPROP_TEXT,        text);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE,    fontSize);
      ObjectSetString (0, name, OBJPROP_FONT,        bold ? "Arial Bold" : "Arial");
      ObjectSetInteger(0, name, OBJPROP_COLOR,       clr);
      ObjectSetInteger(0, name, OBJPROP_CORNER,      CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE,  false);
     }

   void _Button(string name, int x, int y, int w, int h, string text, color bg, color textClr)
     {
      ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE,  x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE,  y);
      ObjectSetInteger(0, name, OBJPROP_XSIZE,      w);
      ObjectSetInteger(0, name, OBJPROP_YSIZE,      h);
      ObjectSetString (0, name, OBJPROP_TEXT,        text);
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR,     bg);
      ObjectSetInteger(0, name, OBJPROP_COLOR,       textClr);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE,    9);
      ObjectSetInteger(0, name, OBJPROP_CORNER,      CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE,  false);
     }

   void _Edit(string name, int x, int y, int w, int h, string defaultVal)
     {
      ObjectCreate(0, name, OBJ_EDIT, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE,  x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE,  y);
      ObjectSetInteger(0, name, OBJPROP_XSIZE,      w);
      ObjectSetInteger(0, name, OBJPROP_YSIZE,      h);
      ObjectSetString (0, name, OBJPROP_TEXT,        defaultVal);
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR,     CLR_BG_LIGHT);
      ObjectSetInteger(0, name, OBJPROP_COLOR,       CLR_TEXT);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE,    9);
      ObjectSetInteger(0, name, OBJPROP_CORNER,      CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE,  false);
     }

   void _SetLabelText(string name, string text)
     { ObjectSetString(0, name, OBJPROP_TEXT, text); }

   void _SetButtonText(string name, string text)
     { ObjectSetString(0, name, OBJPROP_TEXT, text); }

   void _SetButtonColor(string name, color bg)
     { ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg); }
  };
