# JBM Order Manager — Development & Business Plan

> Last updated: 2026-05-20

---

## 1. Product Vision

TradingView-style order panel for MetaTrader 5 that auto-calculates lot size, margin,
pip value, and estimated P&L based on risk settings — sold as monthly subscription.

**Target users:** Forex retail traders, prop firm challengers (FTMO, MyForexFunds, etc.)
**Price:** $5/mo Basic · $9/mo Pro · $49 Lifetime

---

## 2. Phase 1 — MVP (Week 1–4)

### Goals
- Working order panel with all order types
- Auto-lot calculation from risk %
- Live P&L estimation before order placement
- Compatible: MT5, all brokers, all forex pairs + Gold + Indices

### Deliverables
- [ ] `OM_UI.mqh`     — Panel layout, buttons, input fields, dropdowns
- [ ] `OM_Calc.mqh`   — Pip value, trade value, margin, lot sizing, P&L
- [ ] `OM_Exec.mqh`   — Order execution (Market, Limit, Stop) + TP/SL
- [ ] `JBM_OrderManager.mq5` — Main EA wiring everything together

### Section Breakdown (from TradingView analysis)

#### Section 1 — Header & Price Display
```
[SYMBOL]   Bid: X.XXXXX   Ask: X.XXXXX   Spread: X.X pips
```

#### Section 2 — Order Type & Direction
```
[Market]  [Limit]  [Stop]
[  BUY  ]         [  SELL  ]
```

#### Section 3 — Price Input (Limit & Stop only)
```
Entry Price: [0.71354]   (Ask ± N pips shown)
```

#### Section 4 — Quantity / Lot Size
```
Mode:  [Units ▼]  [Margin USD ▼]  [% Balance ▼]  [Risk USD ▼]  [Risk % ▼]
Value: [1.00]  ↔  [7,135.40 USD]
```

#### Section 5 — Take Profit
```
TP: [ON/OFF]
Mode:  [Price ▼]  [Pips ▼]  [% Price ▼]  [Reward USD ▼]  [Reward % ▼]
Value: [0.70171]  |  [118.5 pips]
Est. Profit: +$11,850 USD
```

#### Section 6 — Stop Loss
```
SL: [ON/OFF]
Mode:  [Price ▼]  [Pips ▼]  [% Price ▼]  [Risk USD ▼]  [Risk % ▼]
Value: [0.72620]  |  [126.4 pips]
Est. Loss: -$12,640 USD
```

#### Section 7 — R:R Summary
```
R:R:    1 : 0.94
Risk:   $12,640  (12.2% balance)  ← warn if > 2%
Reward: $11,850  (11.4% balance)
```

#### Section 8 — Extra Settings
```
Time in Force: [Day ▼]  [Week ▼]  [Month ▼]  [GTD ▼]
```

#### Section 9 — Order Info
```
Trade Value:    713,540.00 USD
Margin Req:     7,135.40 USD
Available Margin: 103,798.31 USD
Leverage:       100:1
Pip Value:      100.00 USD
```

#### Section 10 — Submit Button
```
[ BUY 1,000,000 AUDUSD @ 0.71354 LIMIT ]
```

---

## 3. Phase 2 — Pro Features (Week 5–7)

- [ ] Real-time R:R ratio display
- [ ] Multi-entry: place 2–3 orders at different levels simultaneously
- [ ] Preset save/load (save favorite risk configs)
- [ ] Prop firm mode: block order if risk > max daily drawdown
- [ ] Keyboard shortcuts

---

## 4. Phase 3 — License + Distribution (Week 7–8)

### License System
```
Flow: Buy on Gumroad → get Key → input in EA → EA pings server → valid/invalid

Key format: JBM-XXXX-XXXX-XXXX-XXXX
Binding:    Account number (MT5) + max 2 accounts per key
Grace:      24h offline mode if server unreachable
```

### Server Stack
```
Backend:  FastAPI (Python) on VPS ($5/mo)
Database: Supabase (free tier)
Payment:  Gumroad or Lemon Squeezy (5% transaction fee)
```

### License Tiers
| Tier | Price | Accounts | Features |
|------|-------|----------|----------|
| Free | $0 | 1 demo | Market order only, no auto-lot |
| Basic | $5/mo | 2 | Phase 1 full |
| Pro | $9/mo | 3 | Phase 1 + 2 |
| Lifetime | $49 | 3 | All features forever |

---

## 5. Distribution Channels

1. **Gumroad** — primary launch (instant setup, handles payments)
2. **MQL5 Market** — secondary (built-in MT5 marketplace, 30% fee)
3. **Telegram** — community marketing (trader Indonesia groups)
4. **Website** — Phase 3 (jbmtrading.com or similar)

---

## 6. Formula Reference

```mql5
// Pip Value (universal — works for all instruments)
double PipValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE)
                * (PipSize / SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE));

// Trade Value
double TradeValue = Units * EntryPrice;

// Margin Required
double MarginReq = TradeValue / Leverage;
// OR use built-in:
double MarginReq; OrderCalcMargin(ORDER_TYPE_BUY, symbol, lots, price, MarginReq);

// Auto Lot from Risk %
double RiskAmount = AccountBalance * RiskPct / 100.0;
double Lots = RiskAmount / (SL_pips * PipValue);
Lots = NormalizeDouble(Lots, 2);

// Estimated P&L
double EstProfit = TP_pips * PipValue * Lots;
double EstLoss   = SL_pips * PipValue * Lots;
double RR        = TP_pips / SL_pips;
```

---

## 7. Weekly Timeline

| Week | Tasks |
|------|-------|
| 1 | GUI layout (OM_UI.mqh) — panel, buttons, input fields |
| 2 | Calculation engine (OM_Calc.mqh) — lot, pip value, margin, P&L |
| 3 | Order execution (OM_Exec.mqh) — Market/Limit/Stop + TP/SL |
| 4 | Integration + testing (MT5, multiple brokers, multiple symbols) |
| 5 | Phase 2 features — R:R display, prop firm mode |
| 6 | License system + server |
| 7 | Gumroad setup + landing page |
| 8 | Launch — Telegram groups, MQL5 forum |

---

## 8. Risk & Mitigation

| Risk | Mitigation |
|------|------------|
| Server down → EA blocked | 24h grace period offline mode |
| MQL5 Market rejection | Direct Gumroad distribution first |
| Key sharing/cracking | Bind to MT5 account number |
| Broker incompatibility | Test on IC Markets, Exness, FTMO |
| Low sales early | Free tier as lead magnet |
