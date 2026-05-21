//+------------------------------------------------------------------+
//|  OM_UI.mqh — Panel GUI (Full-Height Layout)                      |
//|  TradingView-style order panel — large, readable, full screen    |
//+------------------------------------------------------------------+
#ifndef OM_UI_MQH
#define OM_UI_MQH
#include <JBM/OM_Calc.mqh>
#include <JBM/OM_Exec.mqh>

// --- Color scheme ---
#define CLR_BG          C'22,26,30'
#define CLR_BG_SECT     C'32,36,42'
#define CLR_BG_INPUT    C'42,46,54'
#define CLR_BUY         C'41,98,255'
#define CLR_BUY_DIM     C'20,55,160'
#define CLR_SELL        C'210,45,45'
#define CLR_SELL_DIM    C'130,25,25'
#define CLR_TEXT        clrWhite
#define CLR_TEXT_DIM    C'140,148,160'
#define CLR_BORDER      C'55,62,72'
#define CLR_GREEN       C'0,210,100'
#define CLR_RED         C'220,60,60'
#define CLR_GOLD        C'255,200,60'
#define CLR_DIVIDER     C'45,50,60'

// --- Layout constants ---
#define PNL_WIDTH       340
#define ROW_H           32       // standard input row height
#define BTN_H           36       // button height
#define LBL_SZ          11       // label font size
#define HDR_SZ          13       // section header font size
#define SYM_SZ          16       // symbol font size
#define GAP             10       // section gap
#define PAD             12       // left padding

// --- Modes ---
enum ENUM_QTY_MODE  { QTY_UNITS, QTY_MARGIN_USD, QTY_PCT_BALANCE, QTY_RISK_USD, QTY_RISK_PCT };
enum ENUM_EXIT_MODE { EXIT_PRICE, EXIT_PIPS, EXIT_PCT_PRICE, EXIT_REWARD_USD, EXIT_REWARD_PCT };
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
   string            m_tif;
   double            m_entryPrice;
   double            m_qtyValue;
   double            m_tpValue;
   double            m_slValue;
   double            m_lots;

   // Derived
   double            m_tpPips, m_slPips;
   double            m_estProfit, m_estLoss;
   double            m_rr;
   double            m_tradeValue, m_marginReq, m_pipValue;

public:
   COrderPanel()
     {
      m_x = 5; m_y = 5; m_width = PNL_WIDTH; m_prefix = "JBM_OM_";
      m_isBuy = true; m_orderType = OT_LIMIT;
      m_qtyMode = QTY_RISK_PCT; m_tpMode = EXIT_PIPS; m_slMode = EXIT_PIPS;
      m_tpEnabled = true; m_slEnabled = true; m_tif = "GTC";
      m_entryPrice = 0; m_qtyValue = 1.0; m_tpValue = 50; m_slValue = 30;
      m_lots = 0; m_tpPips = 0; m_slPips = 0;
      m_estProfit = 0; m_estLoss = 0; m_rr = 0;
      m_tradeValue = 0; m_marginReq = 0; m_pipValue = 0;
      m_calc = NULL; m_exec = NULL;
     }

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

   void Destroy()   { ObjectsDeleteAll(0, m_prefix); }

   void OnTick()
     {
      _RecalcAll();
      _UpdatePriceDisplay();
      _UpdateOrderInfo();
      _UpdatePnLDisplay();
     }

   void Refresh()
     {
      _RecalcAll();
      _UpdateAll();
     }

   void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
     {
      if(id == CHARTEVENT_OBJECT_CLICK)
        {
         if(StringFind(sparam, m_prefix + "BTN_BUY")    >= 0) { m_isBuy = true;         _RecalcAll(); _UpdateAll(); }
         if(StringFind(sparam, m_prefix + "BTN_SELL")   >= 0) { m_isBuy = false;        _RecalcAll(); _UpdateAll(); }
         if(StringFind(sparam, m_prefix + "BTN_MKT")    >= 0) { m_orderType = OT_MARKET; _UpdateAll(); }
         if(StringFind(sparam, m_prefix + "BTN_LMT")    >= 0) { m_orderType = OT_LIMIT;  _UpdateAll(); }
         if(StringFind(sparam, m_prefix + "BTN_STP")    >= 0) { m_orderType = OT_STOP;   _UpdateAll(); }
         if(StringFind(sparam, m_prefix + "BTN_SUBMIT") >= 0) { _SubmitOrder(); }
         if(StringFind(sparam, m_prefix + "BTN_CLOSE")  >= 0) { Destroy(); ChartRedraw(); return; }
         if(StringFind(sparam, m_prefix + "TOG_TP")     >= 0) { m_tpEnabled = !m_tpEnabled; _UpdateAll(); }
         if(StringFind(sparam, m_prefix + "TOG_SL")     >= 0) { m_slEnabled = !m_slEnabled; _UpdateAll(); }
        }
      if(id == CHARTEVENT_OBJECT_ENDEDIT)
        {
         _ReadInputs(sparam);
         _RecalcAll();
         _UpdateAll();
        }
     }

private:
   //+------------------------------------------------------------------+
   //--- Build panel (full chart height, wide layout)
   void _BuildPanel()
     {
      int chartH = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
      int x = m_x;
      int y = m_y;
      int w = m_width;
      int h = chartH - m_y - 5;    // fill chart height

      // === BACKGROUND ===
      _Rect(m_prefix + "BG", x, y, w, h, CLR_BG, CLR_BORDER);

      int cy = y + GAP;             // current Y cursor

      // ─────────────────────────────────────────
      // SECTION 1 — Symbol + Bid/Ask  +  [X] close
      // ─────────────────────────────────────────
      _Label(m_prefix + "LBL_SYMBOL", x + PAD, cy, Symbol(), SYM_SZ, CLR_TEXT, true);
      // Close button — top-right corner of panel
      _Button(m_prefix + "BTN_CLOSE", x + w - 32, y + 4, 26, 26, "X", C'80,30,30', CLR_TEXT);
      cy += 26;
      _Label(m_prefix + "LBL_BID", x + PAD,       cy, "Bid: --",   LBL_SZ, CLR_SELL,     false);
      _Label(m_prefix + "LBL_ASK", x + PAD + 110, cy, "Ask: --",   LBL_SZ, CLR_BUY,      false);
      _Label(m_prefix + "LBL_SPR", x + PAD + 220, cy, "Sprd: --",  LBL_SZ, CLR_TEXT_DIM, false);
      cy += 28;

      _Divider(x, cy, w); cy += 8;

      // ─────────────────────────────────────────
      // SECTION 2 — BUY / SELL
      // ─────────────────────────────────────────
      int bw = (w - 3*PAD) / 2;
      _Button(m_prefix + "BTN_BUY",  x + PAD,          cy, bw, BTN_H + 4, "BUY",  CLR_BUY,  CLR_TEXT);
      _Button(m_prefix + "BTN_SELL", x + PAD + bw + PAD, cy, bw, BTN_H + 4, "SELL", CLR_SELL, CLR_TEXT);
      cy += BTN_H + 4 + GAP;

      // ─────────────────────────────────────────
      // SECTION 3 — Order Type tabs
      // ─────────────────────────────────────────
      int tw = (w - 2*PAD) / 3;
      _Button(m_prefix + "BTN_MKT", x + PAD,          cy, tw - 2, BTN_H - 4, "Market", CLR_BG_SECT, CLR_TEXT);
      _Button(m_prefix + "BTN_LMT", x + PAD + tw,     cy, tw - 2, BTN_H - 4, "Limit",  CLR_BG_SECT, CLR_TEXT);
      _Button(m_prefix + "BTN_STP", x + PAD + tw*2,   cy, tw - 2, BTN_H - 4, "Stop",   CLR_BG_SECT, CLR_TEXT);
      cy += BTN_H + GAP;

      // ─────────────────────────────────────────
      // SECTION 4 — Entry Price (Limit/Stop only)
      // ─────────────────────────────────────────
      _Label(m_prefix + "LBL_PRICE", x + PAD, cy, "Entry Price", LBL_SZ, CLR_TEXT_DIM, false);
      cy += 18;
      _Edit(m_prefix + "EDT_PRICE", x + PAD, cy, w - 2*PAD, ROW_H, "0.00000");
      cy += ROW_H + GAP;

      // ─────────────────────────────────────────
      // SECTION 5 — Quantity
      // ─────────────────────────────────────────
      _Label(m_prefix + "LBL_QTY", x + PAD, cy, "Quantity  [Risk % ▼]", LBL_SZ, CLR_TEXT_DIM, false);
      cy += 18;
      int ew = (w - 3*PAD) / 2;
      _Edit(m_prefix + "EDT_QTY",     x + PAD,          cy, ew, ROW_H, "1.0");
      _Label(m_prefix + "LBL_QTY_EQ", x + PAD*2 + ew,   cy + 8, "= 0.00 USD", LBL_SZ, CLR_TEXT_DIM, false);
      cy += ROW_H + GAP + 4;

      _Divider(x, cy, w); cy += GAP;

      // ─────────────────────────────────────────
      // SECTION 6 — Exits header
      // ─────────────────────────────────────────
      _Label(m_prefix + "LBL_EXITS", x + PAD, cy, "Exits", HDR_SZ, CLR_TEXT, true);
      cy += 24;

      // --- Take Profit ---
      _Label(m_prefix + "LBL_TP", x + PAD, cy, "Take Profit  [Price ▼]", LBL_SZ, CLR_TEXT_DIM, false);
      _Button(m_prefix + "TOG_TP", x + w - PAD - 52, cy - 2, 52, 22, "OFF", CLR_BG_SECT, CLR_TEXT_DIM);
      cy += 22;
      _Edit(m_prefix + "EDT_TP", x + PAD, cy, ew, ROW_H, "0.00000");
      _Label(m_prefix + "LBL_TP_PIPS", x + PAD*2 + ew, cy + 8, "0.0 pips", LBL_SZ, CLR_TEXT_DIM, false);
      cy += ROW_H + 6;
      _Label(m_prefix + "LBL_TP_PNL", x + PAD, cy, "Est. Profit: --", LBL_SZ, CLR_GREEN, false);
      cy += 22 + GAP;

      // --- Stop Loss ---
      _Label(m_prefix + "LBL_SL", x + PAD, cy, "Stop Loss  [Price ▼]", LBL_SZ, CLR_TEXT_DIM, false);
      _Button(m_prefix + "TOG_SL", x + w - PAD - 52, cy - 2, 52, 22, "OFF", CLR_BG_SECT, CLR_TEXT_DIM);
      cy += 22;
      _Edit(m_prefix + "EDT_SL", x + PAD, cy, ew, ROW_H, "0.00000");
      _Label(m_prefix + "LBL_SL_PIPS", x + PAD*2 + ew, cy + 8, "0.0 pips", LBL_SZ, CLR_TEXT_DIM, false);
      cy += ROW_H + 6;
      _Label(m_prefix + "LBL_SL_PNL", x + PAD, cy, "Est. Loss: --", LBL_SZ, CLR_RED, false);
      cy += 22 + GAP;

      // ─────────────────────────────────────────
      // SECTION 7 — R:R Summary box
      // ─────────────────────────────────────────
      _Rect(m_prefix + "BG_RR", x + PAD, cy, w - 2*PAD, 42, CLR_BG_SECT, CLR_BORDER);
      _Label(m_prefix + "LBL_RR1", x + PAD + 8, cy + 6,  "R:R: --",        LBL_SZ, CLR_GOLD,     false);
      _Label(m_prefix + "LBL_RR2", x + PAD + 8, cy + 22, "Risk: --  |  Reward: --", LBL_SZ, CLR_TEXT_DIM, false);
      cy += 42 + GAP;

      _Divider(x, cy, w); cy += GAP;

      // ─────────────────────────────────────────
      // SECTION 8 — Extra Settings
      // ─────────────────────────────────────────
      _Label(m_prefix + "LBL_TIF_HDR", x + PAD, cy, "Time in Force", LBL_SZ, CLR_TEXT_DIM, false);
      _Label(m_prefix + "LBL_TIF",     x + PAD + 160, cy, "[Week ▼]", LBL_SZ, CLR_TEXT, false);
      cy += 26 + GAP;

      _Divider(x, cy, w); cy += GAP;

      // ─────────────────────────────────────────
      // SECTION 9 — Order Info
      // ─────────────────────────────────────────
      _Label(m_prefix + "LBL_INFO_HDR", x + PAD, cy, "Order Info", HDR_SZ, CLR_TEXT, true);
      cy += 26;

      int lx1 = x + PAD;
      int lx2 = x + PAD + 155;
      int ls  = LBL_SZ;
      int lr  = 22;    // row height for info rows

      _Label(m_prefix + "LBL_TRDVAL_K", lx1, cy, "Trade Value:",  ls, CLR_TEXT_DIM, false);
      _Label(m_prefix + "LBL_TRDVAL",   lx2, cy, "--",            ls, CLR_TEXT,     false);
      cy += lr;
      _Label(m_prefix + "LBL_MARGIN_K", lx1, cy, "Margin Req:",   ls, CLR_TEXT_DIM, false);
      _Label(m_prefix + "LBL_MARGIN",   lx2, cy, "--",            ls, CLR_TEXT,     false);
      cy += lr;
      _Label(m_prefix + "LBL_AVAIL_K",  lx1, cy, "Avail Margin:", ls, CLR_TEXT_DIM, false);
      _Label(m_prefix + "LBL_AVAIL",    lx2, cy, "--",            ls, CLR_TEXT,     false);
      cy += lr;
      _Label(m_prefix + "LBL_LEV_K",    lx1, cy, "Leverage:",     ls, CLR_TEXT_DIM, false);
      _Label(m_prefix + "LBL_LEV",      lx2, cy, "--",            ls, CLR_TEXT,     false);
      cy += lr;
      _Label(m_prefix + "LBL_PIPVAL_K", lx1, cy, "Pip Value:",    ls, CLR_TEXT_DIM, false);
      _Label(m_prefix + "LBL_PIPVAL",   lx2, cy, "--",            ls, CLR_TEXT,     false);
      cy += lr + GAP;

      // ─────────────────────────────────────────
      // SECTION 10 — Submit button (pinned near bottom)
      // ─────────────────────────────────────────
      int submitY = y + h - BTN_H - 14 - GAP;
      _Divider(x, submitY - GAP, w);
      _Button(m_prefix + "BTN_SUBMIT", x + PAD, submitY, w - 2*PAD, BTN_H + 6, "BUY @ --", CLR_BUY, CLR_TEXT);

      ChartRedraw();
     }

   //--- Recalculate all derived values
   void _RecalcAll()
     {
      if(!m_calc) return;
      string sym = Symbol();
      if(m_orderType == OT_MARKET)
         m_entryPrice = m_isBuy ? SymbolInfoDouble(sym, SYMBOL_ASK)
                                : SymbolInfoDouble(sym, SYMBOL_BID);

      double slPips = (m_slEnabled && m_slValue > 0)
                      ? (m_slMode == EXIT_PIPS ? m_slValue : m_calc.PriceToPips(m_entryPrice, m_slValue))
                      : 0;

      switch(m_qtyMode)
        {
         case QTY_UNITS:       m_lots = m_calc.NormalizeLots(m_qtyValue); break;
         case QTY_RISK_PCT:    m_lots = (slPips > 0) ? m_calc.GetLotFromRiskPct(m_qtyValue, slPips, m_entryPrice) : 0; break;
         case QTY_RISK_USD:    m_lots = (slPips > 0) ? m_calc.GetLotFromRiskUSD(m_qtyValue, slPips) : 0; break;
         case QTY_MARGIN_USD:  m_lots = m_calc.GetLotFromMarginUSD(m_qtyValue, m_isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, m_entryPrice); break;
         case QTY_PCT_BALANCE: m_lots = m_calc.GetLotFromBalancePct(m_qtyValue, m_isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, m_entryPrice); break;
        }

      if(m_tpEnabled && m_tpValue > 0)
        {
         m_tpPips    = (m_tpMode == EXIT_PIPS) ? m_tpValue : m_calc.PriceToPips(m_entryPrice, m_tpValue);
         m_estProfit = m_calc.EstimateProfit(m_lots, m_tpPips);
        }
      else { m_tpPips = 0; m_estProfit = 0; }

      if(m_slEnabled && m_slValue > 0)
        {
         m_slPips  = slPips;
         m_estLoss = m_calc.EstimateProfit(m_lots, m_slPips);
        }
      else { m_slPips = 0; m_estLoss = 0; }

      m_rr         = m_calc.GetRR(m_tpPips, m_slPips);
      m_pipValue   = m_calc.GetPipValue(m_lots);
      m_tradeValue = m_calc.GetTradeValue(m_lots, m_entryPrice);
      m_marginReq  = m_calc.GetMarginRequired(m_isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, m_lots, m_entryPrice);
     }

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
      string sym  = Symbol();
      int    digs = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
      double bid  = SymbolInfoDouble(sym, SYMBOL_BID);
      double ask  = SymbolInfoDouble(sym, SYMBOL_ASK);
      double sprd = (ask - bid) / m_calc.GetPipSize();
      _SetLabel(m_prefix + "LBL_BID", "Bid: " + DoubleToString(bid, digs));
      _SetLabel(m_prefix + "LBL_ASK", "Ask: " + DoubleToString(ask, digs));
      _SetLabel(m_prefix + "LBL_SPR", "Sprd: " + DoubleToString(sprd, 1));
     }

   void _UpdateOrderInfo()
     {
      _SetLabel(m_prefix + "LBL_TRDVAL", DoubleToString(m_tradeValue, 2) + " USD");
      _SetLabel(m_prefix + "LBL_MARGIN", DoubleToString(m_marginReq, 2)  + " USD");
      _SetLabel(m_prefix + "LBL_AVAIL",  DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_FREE), 2) + " USD");
      _SetLabel(m_prefix + "LBL_LEV",    IntegerToString((int)AccountInfoInteger(ACCOUNT_LEVERAGE)) + ":1");
      _SetLabel(m_prefix + "LBL_PIPVAL", DoubleToString(m_pipValue, 2) + " USD");
     }

   void _UpdatePnLDisplay()
     {
      string tpStr = m_tpEnabled
         ? "+" + DoubleToString(m_estProfit, 2) + " USD   (" + DoubleToString(m_tpPips, 1) + " pips)"
         : "OFF";
      string slStr = m_slEnabled
         ? "-" + DoubleToString(m_estLoss,  2) + " USD   (" + DoubleToString(m_slPips, 1) + " pips)"
         : "OFF";
      string rrStr = "R:R  1 : " + DoubleToString(m_rr, 2);
      string rsStr = "Risk  -" + DoubleToString(m_estLoss, 0) + " USD   |   Reward  +" + DoubleToString(m_estProfit, 0) + " USD";

      _SetLabel(m_prefix + "LBL_TP_PIPS", DoubleToString(m_tpPips, 1) + " pips");
      _SetLabel(m_prefix + "LBL_SL_PIPS", DoubleToString(m_slPips, 1) + " pips");
      _SetLabel(m_prefix + "LBL_TP_PNL",  "Est. Profit:  " + tpStr);
      _SetLabel(m_prefix + "LBL_SL_PNL",  "Est. Loss:    " + slStr);
      _SetLabel(m_prefix + "LBL_RR1",     rrStr);
      _SetLabel(m_prefix + "LBL_RR2",     rsStr);
     }

   void _UpdateSubmitButton()
     {
      string sym  = Symbol();
      int    digs = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
      string dir  = m_isBuy ? "BUY" : "SELL";
      string typ  = (m_orderType == OT_MARKET) ? "MARKET"
                  : (m_orderType == OT_LIMIT)  ? "LIMIT" : "STOP";
      string txt  = dir + "  " + DoubleToString(m_lots, 2) + " lots"
                  + "  @  " + DoubleToString(m_entryPrice, digs) + "  " + typ;
      _SetButton(m_prefix + "BTN_SUBMIT", txt);
      _SetBtnColor(m_prefix + "BTN_SUBMIT", m_isBuy ? CLR_BUY : CLR_SELL);
     }

   void _UpdateDirectionButtons()
     {
      _SetBtnColor(m_prefix + "BTN_BUY",  m_isBuy  ? CLR_BUY  : CLR_BUY_DIM);
      _SetBtnColor(m_prefix + "BTN_SELL", !m_isBuy ? CLR_SELL : CLR_SELL_DIM);
     }

   void _UpdateOrderTypeButtons()
     {
      color active   = C'55,62,80';
      color inactive = CLR_BG_SECT;
      _SetBtnColor(m_prefix + "BTN_MKT", m_orderType == OT_MARKET ? active : inactive);
      _SetBtnColor(m_prefix + "BTN_LMT", m_orderType == OT_LIMIT  ? active : inactive);
      _SetBtnColor(m_prefix + "BTN_STP", m_orderType == OT_STOP   ? active : inactive);
      long showFlag = (m_orderType != OT_MARKET) ? -1 : 0;
      ObjectSetInteger(0, m_prefix + "EDT_PRICE", OBJPROP_TIMEFRAMES, showFlag);
      ObjectSetInteger(0, m_prefix + "LBL_PRICE", OBJPROP_TIMEFRAMES, showFlag);
     }

   void _UpdateToggleButtons()
     {
      _SetButton(m_prefix + "TOG_TP", m_tpEnabled ? "ON" : "OFF");
      _SetBtnColor(m_prefix + "TOG_TP", m_tpEnabled ? CLR_GREEN : CLR_BG_SECT);
      _SetButton(m_prefix + "TOG_SL", m_slEnabled ? "ON" : "OFF");
      _SetBtnColor(m_prefix + "TOG_SL", m_slEnabled ? CLR_GREEN : CLR_BG_SECT);
     }

   void _ReadInputs(string objName)
     {
      string val = ObjectGetString(0, objName, OBJPROP_TEXT);
      if(objName == m_prefix + "EDT_PRICE") m_entryPrice = StringToDouble(val);
      if(objName == m_prefix + "EDT_QTY")   m_qtyValue   = StringToDouble(val);
      if(objName == m_prefix + "EDT_TP")    m_tpValue    = StringToDouble(val);
      if(objName == m_prefix + "EDT_SL")    m_slValue    = StringToDouble(val);
     }

   void _SubmitOrder()
     {
      if(!m_exec || m_lots <= 0) { Alert("JBM-OM: Invalid lot size"); return; }
      double sl = (m_slEnabled && m_slValue > 0) ? m_slValue : 0;
      double tp = (m_tpEnabled && m_tpValue > 0) ? m_tpValue : 0;
      if(m_calc)
        {
         if(m_slMode == EXIT_PIPS && sl > 0)
            sl = m_isBuy ? m_entryPrice - sl * m_calc.GetPipSize()
                         : m_entryPrice + sl * m_calc.GetPipSize();
         if(m_tpMode == EXIT_PIPS && tp > 0)
            tp = m_isBuy ? m_entryPrice + tp * m_calc.GetPipSize()
                         : m_entryPrice - tp * m_calc.GetPipSize();
        }
      datetime expiry = m_exec.GetExpiry(m_tif);
      switch(m_orderType)
        {
         case OT_MARKET: m_exec.PlaceMarket(m_isBuy, m_lots, sl, tp); break;
         case OT_LIMIT:  m_exec.PlaceLimit (m_isBuy, m_lots, m_entryPrice, sl, tp, expiry); break;
         case OT_STOP:   m_exec.PlaceStop  (m_isBuy, m_lots, m_entryPrice, sl, tp, expiry); break;
        }
     }

   //+------------------------------------------------------------------+
   //--- Object helpers
   void _Rect(string name, int x, int y, int w, int h, color bg, color border)
     {
      ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE,    x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE,    y);
      ObjectSetInteger(0, name, OBJPROP_XSIZE,        w);
      ObjectSetInteger(0, name, OBJPROP_YSIZE,        h);
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR,      bg);
      ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, border);
      ObjectSetInteger(0, name, OBJPROP_CORNER,       CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_BACK,         false);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE,   false);
      ObjectSetInteger(0, name, OBJPROP_ZORDER,       1);
     }

   void _Divider(int x, int y, int w)
     {
      _Rect(m_prefix + "DIV_" + IntegerToString(y), x + PAD, y, w - 2*PAD, 1, CLR_DIVIDER, CLR_DIVIDER);
     }

   void _Label(string name, int x, int y, string text, int sz, color clr, bool bold)
     {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE,  x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE,  y);
      ObjectSetString (0, name, OBJPROP_TEXT,        text);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE,    sz);
      ObjectSetString (0, name, OBJPROP_FONT,        bold ? "Arial Bold" : "Arial");
      ObjectSetInteger(0, name, OBJPROP_COLOR,       clr);
      ObjectSetInteger(0, name, OBJPROP_CORNER,      CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE,  false);
      ObjectSetInteger(0, name, OBJPROP_ZORDER,      5);
     }

   void _Button(string name, int x, int y, int w, int h, string text, color bg, color tc)
     {
      ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE,  x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE,  y);
      ObjectSetInteger(0, name, OBJPROP_XSIZE,      w);
      ObjectSetInteger(0, name, OBJPROP_YSIZE,      h);
      ObjectSetString (0, name, OBJPROP_TEXT,        text);
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR,     bg);
      ObjectSetInteger(0, name, OBJPROP_COLOR,       tc);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE,    LBL_SZ);
      ObjectSetString (0, name, OBJPROP_FONT,        "Arial Bold");
      ObjectSetInteger(0, name, OBJPROP_CORNER,      CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE,  false);
      ObjectSetInteger(0, name, OBJPROP_ZORDER,      5);
     }

   void _Edit(string name, int x, int y, int w, int h, string val)
     {
      ObjectCreate(0, name, OBJ_EDIT, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE,  x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE,  y);
      ObjectSetInteger(0, name, OBJPROP_XSIZE,      w);
      ObjectSetInteger(0, name, OBJPROP_YSIZE,      h);
      ObjectSetString (0, name, OBJPROP_TEXT,        val);
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR,     CLR_BG_INPUT);
      ObjectSetInteger(0, name, OBJPROP_COLOR,       CLR_TEXT);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE,    LBL_SZ);
      ObjectSetInteger(0, name, OBJPROP_CORNER,      CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE,  false);
      ObjectSetInteger(0, name, OBJPROP_ZORDER,      5);
     }

   void _SetLabel (string n, string t) { ObjectSetString (0, n, OBJPROP_TEXT,   t); }
   void _SetButton (string n, string t) { ObjectSetString (0, n, OBJPROP_TEXT,   t); }
   void _SetBtnColor(string n, color  c) { ObjectSetInteger(0, n, OBJPROP_BGCOLOR, c); }
  };

#endif // OM_UI_MQH
