//+------------------------------------------------------------------+
//|                                                  MainStrategy5.mq5  |
//|                        Copyright 2024, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property strict
#property version "1.00"

#import "user32.dll"
   short GetAsyncKeyState(int vKey);
#import

#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Label.mqh>
#include <Controls\Edit.mqh>
#include <Controls\CheckBox.mqh>
#include <Trade\Trade.mqh>

// Глобални променливи
string g_entryHour = "09";
string g_entryMinute = "00";
double g_dev = 67.55;
double g_r1 = 1.0;
double g_r2 = 1.0;
double g_lot = 0.10;
long   g_period = 30;
double g_multiplier = 0.0001;
bool   g_liveMode = false;

CTrade trade;

//+------------------------------------------------------------------+
//| Calculator 2 Dialog                                              |
//+------------------------------------------------------------------+
class CCalculator2Dialog : public CAppDialog
{
public:
   CCheckBox    *m_chkTimeframes[6];
   CCheckBox    *m_chkHedge;
   CEdit        *m_edtEntryHour, *m_edtEntryMinute, *m_edtDev, *m_edtR1, *m_edtR2, *m_edtLot, *m_edtPeriod, *m_edtMultiplier;
   CEdit        *m_edtProfitCount, *m_edtLossCount, *m_edtTotalSum;
   CButton      *m_btnCalcDev, *m_btnRunTest, *m_btnClose, *m_btnStartLive;
   CButton      *m_btnR1[4], *m_btnR2[4];
   CLabel       *m_labels[11];
   datetime     m_tradeTimes[];
   int          m_currentTradeIndex;

   CCalculator2Dialog() : m_currentTradeIndex(-1) {}
   ~CCalculator2Dialog() {
      for(int i = 0; i < 6; i++) if(CheckPointer(m_chkTimeframes[i]) == POINTER_DYNAMIC) delete m_chkTimeframes[i];
      if(CheckPointer(m_chkHedge) == POINTER_DYNAMIC) delete m_chkHedge;
      if(CheckPointer(m_edtEntryHour) == POINTER_DYNAMIC) delete m_edtEntryHour;
      if(CheckPointer(m_edtEntryMinute) == POINTER_DYNAMIC) delete m_edtEntryMinute;
      if(CheckPointer(m_edtDev) == POINTER_DYNAMIC) delete m_edtDev;
      if(CheckPointer(m_edtR1) == POINTER_DYNAMIC) delete m_edtR1;
      if(CheckPointer(m_edtR2) == POINTER_DYNAMIC) delete m_edtR2;
      if(CheckPointer(m_edtLot) == POINTER_DYNAMIC) delete m_edtLot;
      if(CheckPointer(m_edtPeriod) == POINTER_DYNAMIC) delete m_edtPeriod;
      if(CheckPointer(m_edtMultiplier) == POINTER_DYNAMIC) delete m_edtMultiplier;
      if(CheckPointer(m_btnCalcDev) == POINTER_DYNAMIC) delete m_btnCalcDev;
      if(CheckPointer(m_btnRunTest) == POINTER_DYNAMIC) delete m_btnRunTest;
      if(CheckPointer(m_btnStartLive) == POINTER_DYNAMIC) delete m_btnStartLive;
      if(CheckPointer(m_edtProfitCount) == POINTER_DYNAMIC) delete m_edtProfitCount;
      if(CheckPointer(m_edtLossCount) == POINTER_DYNAMIC) delete m_edtLossCount;
      if(CheckPointer(m_edtTotalSum) == POINTER_DYNAMIC) delete m_edtTotalSum;
      if(CheckPointer(m_btnClose) == POINTER_DYNAMIC) delete m_btnClose;
      for(int i = 0; i < 4; i++) {
         if(CheckPointer(m_btnR1[i]) == POINTER_DYNAMIC) delete m_btnR1[i];
         if(CheckPointer(m_btnR2[i]) == POINTER_DYNAMIC) delete m_btnR2[i];
      }
      for(int i = 0; i < 11; i++) if(CheckPointer(m_labels[i]) == POINTER_DYNAMIC) delete m_labels[i];
   }

   virtual bool Create(const long chart, const string name, const int subwin);
   virtual bool CreateControls();
   void RunTest();
   double CalculateDev(ENUM_TIMEFRAMES tf);
   ENUM_TIMEFRAMES GetSelectedTimeframe();
   void NavigateToTrade(int direction);
   virtual bool OnEvent(const int id, const long &lparam, const double &dparam, const string &sparam);
   void SaveParameters();
   void LoadParameters();
   void SaveObjectsToFile();
   void LoadObjectsFromFile();
};

bool CCalculator2Dialog::Create(const long chart, const string name, const int subwin)
{
   if(!CAppDialog::Create(chart, name, subwin, 100, 100, 600, 550)) {
      Print("Failed to create CCalculator2Dialog");
      return false;
   }
   if(!CreateControls()) {
      Print("Failed to create controls for CCalculator2Dialog");
      return false;
   }
   LoadParameters();
   LoadObjectsFromFile();
   return true;
}

bool CCalculator2Dialog::CreateControls()
{
   int x = 20, y = 20, w = 100, h = 25;
   string labels[] = {"Timeframe", "Entry Hour", "Entry Min", "Dev", "R1", "R2", "Lot", "Period (days)", "Multiplier", "Profits", "Losses", "Total Sum"};
   for(int i = 0; i < 11; i++) {
      m_labels[i] = new CLabel();
      if(!m_labels[i].Create(0, "Label" + labels[i], 0, x, y + (i > 1 ? 40 : 0), x + w, y + h + (i > 1 ? 40 : 0))) return false;
      m_labels[i].Text(labels[i]);
      Add(m_labels[i]);
      if(i != 1) y += 40;
   }

   y = 20; x += 120;
   string tfs[] = {"M1", "M5", "M15", "H1", "H4", "D1"};
   for(int i = 0; i < 6; i++) {
      m_chkTimeframes[i] = new CCheckBox();
      if(!m_chkTimeframes[i].Create(0, "chkTF" + tfs[i], 0, x, y, x + 60, y + h)) return false;
      m_chkTimeframes[i].Text(tfs[i]);
      m_chkTimeframes[i].Checked(i == 3);
      Add(m_chkTimeframes[i]);
      y += 30;
   }

   m_chkHedge = new CCheckBox();
   if(!m_chkHedge.Create(0, "chkHedge", 0, x, y, x + 60, y + h)) return false;
   m_chkHedge.Text("Hedge");
   m_chkHedge.Checked(false);
   Add(m_chkHedge);

   y = 60; x += 80;
   m_edtEntryHour = new CEdit(); if(!m_edtEntryHour.Create(0, "edtEntryHour", 0, x, y, x + 40, y + h)) return false; m_edtEntryHour.Text(g_entryHour); Add(m_edtEntryHour);
   m_edtEntryMinute = new CEdit(); if(!m_edtEntryMinute.Create(0, "edtEntryMinute", 0, x + 50, y, x + 90, y + h)) return false; m_edtEntryMinute.Text(g_entryMinute); Add(m_edtEntryMinute); y += 40;
   m_edtDev = new CEdit(); if(!m_edtDev.Create(0, "edtDev", 0, x, y, x + w, y + h)) return false; m_edtDev.Text(DoubleToString(g_dev, 2)); Add(m_edtDev); y += 40;
   m_edtR1 = new CEdit(); if(!m_edtR1.Create(0, "edtR1", 0, x, y, x + 40, y + h)) return false; m_edtR1.Text(DoubleToString(g_r1, 0)); Add(m_edtR1);
   for(int i = 0; i < 4; i++) {
      m_btnR1[i] = new CButton();
      if(!m_btnR1[i].Create(0, "btnR1_" + IntegerToString(i + 1), 0, x + 50 + i * 30, y, x + 80 + i * 30, y + h)) return false;
      m_btnR1[i].Text(IntegerToString(i + 1));
      Add(m_btnR1[i]);
   }
   y += 40;
   m_edtR2 = new CEdit(); if(!m_edtR2.Create(0, "edtR2", 0, x, y, x + 40, y + h)) return false; m_edtR2.Text(DoubleToString(g_r2, 0)); Add(m_edtR2);
   for(int i = 0; i < 4; i++) {
      m_btnR2[i] = new CButton();
      if(!m_btnR2[i].Create(0, "btnR2_" + IntegerToString(i + 1), 0, x + 50 + i * 30, y, x + 80 + i * 30, y + h)) return false;
      m_btnR2[i].Text(IntegerToString(i + 1));
      Add(m_btnR2[i]);
   }
   y += 40;
   m_edtLot = new CEdit(); if(!m_edtLot.Create(0, "edtLot", 0, x, y, x + w, y + h)) return false; m_edtLot.Text(DoubleToString(g_lot, 2)); Add(m_edtLot); y += 40;
   m_edtPeriod = new CEdit(); if(!m_edtPeriod.Create(0, "edtPeriod", 0, x, y, x + w, y + h)) return false; m_edtPeriod.Text(IntegerToString(g_period)); Add(m_edtPeriod); y += 40;
   m_edtMultiplier = new CEdit(); if(!m_edtMultiplier.Create(0, "edtMultiplier", 0, x, y, x + w, y + h)) return false; m_edtMultiplier.Text(DoubleToString(g_multiplier, 6)); Add(m_edtMultiplier); y += 40;
   m_edtProfitCount = new CEdit(); if(!m_edtProfitCount.Create(0, "edtProfitCount", 0, x, y, x + w, y + h)) return false; m_edtProfitCount.Text("0"); Add(m_edtProfitCount); y += 40;
   m_edtLossCount = new CEdit(); if(!m_edtLossCount.Create(0, "edtLossCount", 0, x, y, x + w, y + h)) return false; m_edtLossCount.Text("0"); Add(m_edtLossCount); y += 40;
   m_edtTotalSum = new CEdit(); if(!m_edtTotalSum.Create(0, "edtTotalSum", 0, x, y, x + w, y + h)) return false; m_edtTotalSum.Text("0.0"); Add(m_edtTotalSum);

   y = 20; x += 120;
   m_btnCalcDev = new CButton(); if(!m_btnCalcDev.Create(0, "btnCalcDev", 0, x, y, x + w, y + h)) return false; m_btnCalcDev.Text("CalcDev"); Add(m_btnCalcDev); y += 300;
   m_btnStartLive = new CButton(); if(!m_btnStartLive.Create(0, "btnStartLive", 0, x, y, x + w, y + h)) return false; m_btnStartLive.Text("Start Live"); Add(m_btnStartLive); y += 40;
   m_btnRunTest = new CButton(); if(!m_btnRunTest.Create(0, "btnRunTest", 0, x, y, x + w, y + h)) return false; m_btnRunTest.Text("Run Test"); Add(m_btnRunTest); y += 40;
   m_btnClose = new CButton(); if(!m_btnClose.Create(0, "btnClose", 0, x, y, x + w, y + h)) return false; m_btnClose.Text("Close"); Add(m_btnClose);

   return true;
}

void CCalculator2Dialog::SaveParameters()
{
   g_entryHour = m_edtEntryHour.Text();
   g_entryMinute = m_edtEntryMinute.Text();
   g_dev = StringToDouble(m_edtDev.Text());
   g_r1 = StringToDouble(m_edtR1.Text());
   g_r2 = StringToDouble(m_edtR2.Text());
   g_lot = StringToDouble(m_edtLot.Text());
   g_period = StringToInteger(m_edtPeriod.Text());
   g_multiplier = StringToDouble(m_edtMultiplier.Text());
}

void CCalculator2Dialog::LoadParameters()
{
   m_edtEntryHour.Text(g_entryHour);
   m_edtEntryMinute.Text(g_entryMinute);
   m_edtDev.Text(DoubleToString(g_dev, 2));
   m_edtR1.Text(DoubleToString(g_r1, 0));
   m_edtR2.Text(DoubleToString(g_r2, 0));
   m_edtLot.Text(DoubleToString(g_lot, 2));
   m_edtPeriod.Text(IntegerToString(g_period));
   m_edtMultiplier.Text(DoubleToString(g_multiplier, 6));
}

double CCalculator2Dialog::CalculateDev(ENUM_TIMEFRAMES tf)
{
   double close = iClose(_Symbol, tf, 1);
   double low = iLow(_Symbol, tf, 1);
   double high = iHigh(_Symbol, tf, 1);
   if(close == 0 || low == 0 || high == 0) return 0.0;
   double dev = (close - low < high - close) ? (close - low) : (high - close);
   Print("DEV Calc: Close=", close, ", Low=", low, ", High=", high, ", DEV=", dev);
   return dev;
}

ENUM_TIMEFRAMES CCalculator2Dialog::GetSelectedTimeframe()
{
   ENUM_TIMEFRAMES tfs[] = {PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_H1, PERIOD_H4, PERIOD_D1};
   for(int i = 0; i < 6; i++) if(m_chkTimeframes[i].Checked()) return tfs[i];
   return PERIOD_H1;
}

void CCalculator2Dialog::RunTest()
{
   SaveParameters();
   ENUM_TIMEFRAMES tf = GetSelectedTimeframe();
   string entryTime = StringFormat("%02d:%02d", StringToInteger(g_entryHour), StringToInteger(g_entryMinute));
   double dev = g_dev;
   double r1 = g_r1;
   double r2 = g_r2;
   double lot = g_lot;
   long periodDays = g_period;
   double multiplier = g_multiplier;
   bool hedgeMode = m_chkHedge.Checked();

   double bid = 0.0, ask = 0.0;
   if(!SymbolInfoDouble(_Symbol, SYMBOL_BID, bid) || !SymbolInfoDouble(_Symbol, SYMBOL_ASK, ask)) {
      bid = iClose(_Symbol, tf, 0);
      ask = bid;
   }
   double spread = (ask - bid);

   long profitCount = 0, lossCount = 0;
   double totalSum = 0.0, avgProfit = 0.0, avgLoss = 0.0;
   datetime endTime = TimeCurrent();
   datetime startTime = endTime - (datetime)periodDays * 86400;

   if(iBars(_Symbol, tf) < periodDays + 1 || iBars(_Symbol, PERIOD_M1) < periodDays * 1440) {
      Print("Not enough historical data for ", _Symbol, " on ", EnumToString(tf), " or M1");
      return;
   }

   ArrayResize(m_tradeTimes, 0);

   for(datetime dt = startTime; dt <= endTime; dt += 86400) {
      string dtStr = TimeToString(dt, TIME_DATE);
      datetime entryDt = StringToTime(dtStr + " " + entryTime);
      long bar = iBarShift(_Symbol, tf, entryDt);
      if(bar < 0) continue;

      double close = iClose(_Symbol, tf, (int)bar);
      if(close == 0) continue;
      double btcPrice = close;
      double buyLevel = close + dev;
      double sellLevel = close - dev;
      double profitLevel = close + dev + dev * r1;
      double lossLevel = close - dev - dev * r2;
      double profitLevelBuy = buyLevel + dev * r1;
      double lossLevelBuy = buyLevel - dev * r2;
      double profitLevelSell = sellLevel - dev * r1;
      double lossLevelSell = sellLevel + dev * r2;

      string entryName = "Trade_Entry_" + TimeToString(entryDt);
      ObjectCreate(0, entryName, OBJ_VLINE, 0, entryDt, 0);
      ObjectSetInteger(0, entryName, OBJPROP_COLOR, clrYellow);
      ObjectSetInteger(0, entryName, OBJPROP_STYLE, STYLE_DOT);

      int size = ArraySize(m_tradeTimes);
      ArrayResize(m_tradeTimes, size + 1);
      m_tradeTimes[size] = entryDt;

      long m1StartBar = iBarShift(_Symbol, PERIOD_M1, entryDt);
      if(m1StartBar < 0) continue;

      bool hitBuy = false, hitSell = false, hitProfit = false, hitLoss = false;
      datetime endTimeM1 = 0;

      if(hedgeMode) {
         for(long i = m1StartBar; i >= 0 && !hitProfit && !hitLoss; i--) {
            double high = iHigh(_Symbol, PERIOD_M1, (int)i);
            double low = iLow(_Symbol, PERIOD_M1, (int)i);
            if(high == 0 || low == 0) break;

            if(!hitBuy && !hitSell) {
               if(high >= buyLevel) hitBuy = true;
               else if(low <= sellLevel) hitSell = true;
            }

            if(hitBuy) {
               if(high >= profitLevelBuy) {
                  hitProfit = true;
                  profitCount++;
                  double profit = (dev * r1 - spread) * lot * btcPrice;
                  totalSum += profit;
                  avgProfit += profit;
                  endTimeM1 = iTime(_Symbol, PERIOD_M1, (int)i);
               }
               else if(low <= lossLevelBuy) {
                  hitLoss = true;
                  lossCount++;
                  double loss = (dev * r2) * lot * btcPrice;
                  totalSum -= loss;
                  avgLoss += loss;
                  endTimeM1 = iTime(_Symbol, PERIOD_M1, (int)i);
               }
            }
            else if(hitSell) {
               if(low <= profitLevelSell) {
                  hitProfit = true;
                  profitCount++;
                  double profit = (dev * r1 - spread) * lot * btcPrice;
                  totalSum += profit;
                  avgProfit += profit;
                  endTimeM1 = iTime(_Symbol, PERIOD_M1, (int)i);
               }
               else if(high >= lossLevelSell) {
                  hitLoss = true;
                  lossCount++;
                  double loss = (dev * r2) * lot * btcPrice;
                  totalSum -= loss;
                  avgLoss += loss;
                  endTimeM1 = iTime(_Symbol, PERIOD_M1, (int)i);
               }
            }
         }
      }
      else {
         for(long i = m1StartBar; i >= 0 && !hitProfit && !hitLoss; i--) {
            double high = iHigh(_Symbol, PERIOD_M1, (int)i);
            double low = iLow(_Symbol, PERIOD_M1, (int)i);
            if(high == 0 || low == 0) break;
            if(high >= profitLevel) {
               hitProfit = true;
               profitCount++;
               double profit = (2 * dev * r1 - spread) * lot * btcPrice;
               totalSum += profit;
               avgProfit += profit;
               endTimeM1 = iTime(_Symbol, PERIOD_M1, (int)i);
            }
            else if(low <= lossLevel) {
               hitLoss = true;
               lossCount++;
               double loss = (2 * dev * r2) * lot * btcPrice;
               totalSum -= loss;
               avgLoss += loss;
               endTimeM1 = iTime(_Symbol, PERIOD_M1, (int)i);
            }
         }
      }

      if(!hitProfit && !hitLoss) {
         lossCount++;
         double loss = (2 * dev * r2) * lot * btcPrice;
         totalSum -= loss;
         avgLoss += loss;
         endTimeM1 = entryDt + 86400;
      }

      string entryTrend = "Trade_EntryT_" + TimeToString(entryDt);
      ObjectCreate(0, entryTrend, OBJ_TREND, 0, entryDt, close, endTimeM1, close);
      ObjectSetInteger(0, entryTrend, OBJPROP_COLOR, clrYellow);
      ObjectSetInteger(0, entryTrend, OBJPROP_RAY, false);

      string buyTrend = "Trade_BuyT_" + TimeToString(entryDt);
      ObjectCreate(0, buyTrend, OBJ_TREND, 0, entryDt, buyLevel, endTimeM1, buyLevel);
      ObjectSetInteger(0, buyTrend, OBJPROP_COLOR, clrBlue);
      ObjectSetInteger(0, buyTrend, OBJPROP_RAY, false);

      string sellTrend = "Trade_SellT_" + TimeToString(entryDt);
      ObjectCreate(0, sellTrend, OBJ_TREND, 0, entryDt, sellLevel, endTimeM1, sellLevel);
      ObjectSetInteger(0, sellTrend, OBJPROP_COLOR, clrRed);
      ObjectSetInteger(0, sellTrend, OBJPROP_RAY, false);
   }

   double baseSum = totalSum;
   totalSum *= multiplier;
   double winRate = profitCount > 0 ? (double)profitCount / (profitCount + lossCount) * 100 : 0;
   avgProfit = profitCount > 0 ? avgProfit / profitCount : 0;
   avgLoss = lossCount > 0 ? avgLoss / lossCount : 0;

   m_edtProfitCount.Text(IntegerToString(profitCount));
   m_edtLossCount.Text(IntegerToString(lossCount));
   m_edtTotalSum.Text(DoubleToString(totalSum, 2));
   Print("Test completed: DEV=", DoubleToString(dev, 2), ", Profits=", profitCount, ", Losses=", lossCount,
         ", Win Rate=", DoubleToString(winRate, 2), "%, Avg Profit=", DoubleToString(avgProfit, 2),
         ", Avg Loss=", DoubleToString(avgLoss, 2), ", Base Sum=", baseSum, " USD, Total Sum=", totalSum, " USD");
   m_currentTradeIndex = -1;
}

void CCalculator2Dialog::NavigateToTrade(int direction)
{
   int totalTrades = ArraySize(m_tradeTimes);
   if(totalTrades == 0) return;

   m_currentTradeIndex += direction;
   if(m_currentTradeIndex < 0) m_currentTradeIndex = 0;
   if(m_currentTradeIndex >= totalTrades) m_currentTradeIndex = totalTrades - 1;

   datetime targetTime = m_tradeTimes[m_currentTradeIndex];
   int barsToShift = iBarShift(_Symbol, Period(), targetTime);
   ChartSetInteger(0, CHART_AUTOSCROLL, false);
   ChartNavigate(0, CHART_END, -barsToShift);
   ChartRedraw();
}

void CCalculator2Dialog::SaveObjectsToFile()
{
   int file = FileOpen("TradeObjects.txt", FILE_WRITE | FILE_TXT);
   if(file == INVALID_HANDLE) {
      Print("Failed to open file for saving objects");
      return;
   }

   int total = ObjectsTotal(0, 0, -1);
   for(int i = 0; i < total; i++) {
      string name = ObjectName(0, i);
      if(StringFind(name, "Trade_") != 0 && StringFind(name, "Trend_") != 0) continue;

      ENUM_OBJECT type = (ENUM_OBJECT)ObjectGetInteger(0, name, OBJPROP_TYPE);
      datetime time1 = (datetime)ObjectGetInteger(0, name, OBJPROP_TIME, 0);
      double price1 = ObjectGetDouble(0, name, OBJPROP_PRICE, 0);
      datetime time2 = (datetime)ObjectGetInteger(0, name, OBJPROP_TIME, 1);
      double price2 = ObjectGetDouble(0, name, OBJPROP_PRICE, 1);
      color clr = (color)ObjectGetInteger(0, name, OBJPROP_COLOR);
      int style = (int)ObjectGetInteger(0, name, OBJPROP_STYLE);
      bool fill = (bool)ObjectGetInteger(0, name, OBJPROP_FILL);

      FileWrite(file, name, (int)type, time1, price1, time2, price2, clr, style, fill);
   }
   FileClose(file);
   Print("Objects saved to file");
}

void CCalculator2Dialog::LoadObjectsFromFile()
{
   if(!FileIsExist("TradeObjects.txt")) return;

   int file = FileOpen("TradeObjects.txt", FILE_READ | FILE_TXT);
   if(file == INVALID_HANDLE) {
      Print("Failed to open file for loading objects");
      return;
   }

   while(!FileIsEnding(file)) {
      string name = FileReadString(file);
      ENUM_OBJECT type = (ENUM_OBJECT)FileReadNumber(file);
      datetime time1 = (datetime)FileReadNumber(file);
      double price1 = FileReadNumber(file);
      datetime time2 = (datetime)FileReadNumber(file);
      double price2 = FileReadNumber(file);
      color clr = (color)FileReadNumber(file);
      int style = (int)FileReadNumber(file);
      bool fill = (bool)FileReadNumber(file);

      ObjectCreate(0, name, type, 0, time1, price1, time2, price2);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name, OBJPROP_STYLE, style);
      if(type == OBJ_RECTANGLE) ObjectSetInteger(0, name, OBJPROP_FILL, fill);
      ObjectSetInteger(0, name, OBJPROP_RAY, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, true);
      ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
   }
   FileClose(file);
   Print("Objects loaded from file");
}

bool CCalculator2Dialog::OnEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sparam == "btnCalcDev") {
         ENUM_TIMEFRAMES tf = GetSelectedTimeframe();
         double dev = CalculateDev(tf);
         m_edtDev.Text(DoubleToString(dev, 5));
         SaveParameters();
         return true;
      }
      if(sparam == "btnRunTest") {
         RunTest();
         return true;
      }
      if(sparam == "btnStartLive") {
         g_liveMode = !g_liveMode;
         m_btnStartLive.Text(g_liveMode ? "Stop Live" : "Start Live");
         Print("Live mode ", (g_liveMode ? "enabled" : "disabled"));
         return true;
      }
      if(sparam == "btnClose") {
         Hide();
         ChartRedraw();
         return true;
      }
      for(int i = 0; i < 4; i++) {
         if(sparam == "btnR1_" + IntegerToString(i + 1)) {
            m_edtR1.Text(IntegerToString(i + 1));
            SaveParameters();
            return true;
         }
         if(sparam == "btnR2_" + IntegerToString(i + 1)) {
            m_edtR2.Text(IntegerToString(i + 1));
            SaveParameters();
            return true;
         }
      }
   }
   return CAppDialog::OnEvent(id, lparam, dparam, sparam);
}

//+------------------------------------------------------------------+
//| Глобални обекти                                                  |
//+------------------------------------------------------------------+
CAppDialog MainWindow;
CCalculator2Dialog *Calc2Dialog = NULL;
CButton *btnPrev = NULL;
CButton *btnNext = NULL;
bool isInitialized = false;

//+------------------------------------------------------------------+
//| Expert Initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("OnInit called");

   if(!isInitialized) {
      if(!MainWindow.Create(0, "Trading Assistant PRO", 0, 220, 20, 700, 85)) {
         Print("Failed to create MainWindow");
         return(INIT_FAILED);
      }
      MainWindow.Show();

      CreateControl(MainWindow, "btnCalc2", "CALC2", 70, 10, 50, 25, clrYellowGreen, 8);

      btnPrev = new CButton();
      if(!btnPrev.Create(0, "btnPrev", 0, 250, 10, 300, 35)) {
         Print("Failed to create btnPrev");
         delete btnPrev; btnPrev = NULL;
      } else {
         btnPrev.Text("Prev");
         btnPrev.ColorBackground(clrLightGray);
         MainWindow.Add(btnPrev);
      }

      btnNext = new CButton();
      if(!btnNext.Create(0, "btnNext", 0, 310, 10, 360, 35)) {
         Print("Failed to create btnNext");
         delete btnNext; btnNext = NULL;
      } else {
         btnNext.Text("Next");
         btnNext.ColorBackground(clrLightGray);
         MainWindow.Add(btnNext);
      }

      if(CheckPointer(Calc2Dialog) == POINTER_DYNAMIC) delete Calc2Dialog;
      Calc2Dialog = new CCalculator2Dialog();
      if(!Calc2Dialog || !Calc2Dialog.Create(0, "Calc2Dialog", 0)) {
         Print("Failed to create Calc2Dialog");
         delete Calc2Dialog; Calc2Dialog = NULL;
         MainWindow.Destroy();
         return(INIT_FAILED);
      }

      MainWindow.Add(Calc2Dialog);
      Calc2Dialog.Hide();
      MainWindow.Run();
      isInitialized = true;
   }
   else {
      Print("Reinitializing after timeframe change");
      MainWindow.Show();
      if(CheckPointer(Calc2Dialog) != POINTER_INVALID) Calc2Dialog.LoadObjectsFromFile();
   }

   Print("OnInit completed successfully");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Create Control                                                   |
//+------------------------------------------------------------------+
void CreateControl(CAppDialog &parent, const string name, const string text,
                  int x, int y, int w, int h, color bgclr, int fontsize)
{
   CButton *btn = new CButton();
   if(btn.Create(0, name, 0, x, y, x + w, y + h)) {
      btn.Text(text);
      btn.ColorBackground(bgclr);
      btn.FontSize(fontsize);
      parent.Add(btn);
   }
   else {
      Print("Failed to create button: ", name);
      delete btn;
   }
}

//+------------------------------------------------------------------+
//| Chart Event Handler                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(CheckPointer(Calc2Dialog) == POINTER_INVALID) return;

   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sparam == "btnCalc2") Calc2Dialog.Show();
      else if(sparam == "btnPrev") Calc2Dialog.NavigateToTrade(-1);
      else if(sparam == "btnNext") Calc2Dialog.NavigateToTrade(1);
      ChartRedraw();
   }
   else if(id == CHARTEVENT_MOUSE_MOVE) {
      datetime dt;
      double MousePrice;
      int window;
      if(ChartXYToTimePrice(0, int(lparam), int(dparam), window, dt, MousePrice)) {
         MousePrice = NormalizeDouble(MousePrice, _Digits);
         if(((int)sparam & 1) != 0) { // Ляв клик
            string prefix = "";
            if(GetAsyncKeyState(66) != 0) prefix = "Buy"; // B
            else if(GetAsyncKeyState(83) != 0) prefix = "Sel"; // S
            if(prefix != "") {
               string timeStr = TimeToString(TimeCurrent(), TIME_MINUTES);
               string tName = "Trend_" + prefix + "_" + timeStr;
               ObjectCreate(0, tName, OBJ_HLINE, 0, 0, MousePrice); // Хоризонтална линия
               ObjectSetInteger(0, tName, OBJPROP_COLOR, prefix == "Buy" ? clrBlue : clrRed);
               ObjectSetInteger(0, tName, OBJPROP_STYLE, STYLE_SOLID);
               ObjectSetInteger(0, tName, OBJPROP_SELECTABLE, true);
            }
         }
      }
   }
   else if(id == CHARTEVENT_KEYDOWN) {
      if(lparam == 88) { // X
         if(GetAsyncKeyState(17) != 0) { // Ctrl + X - за бъдеща логика
            // Празно засега
         }
         else if(GetAsyncKeyState(18) != 0) { // Alt + X - чисти B/S линии
            ClearAllLines();
         }
         else { // Само X - маха последната линия
            string lastBuy = FindLatestLine("Trend_Buy_");
            string lastSell = FindLatestLine("Trend_Sel_");
            string lastLine = (lastBuy != "" && lastSell != "") 
               ? (StringToTime(lastBuy) > StringToTime(lastSell) ? lastBuy : lastSell) 
               : (lastBuy != "" ? lastBuy : lastSell);
            if(lastLine != "") ObjectDelete(0, lastLine);
         }
         ChartRedraw();
      }
   }
   Calc2Dialog.OnEvent(id, lparam, dparam, sparam);
}

//+------------------------------------------------------------------+
//| Expert Deinitialization                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("Deinit reason: ", reason);
   if(reason == REASON_REMOVE || reason == REASON_RECOMPILE) {
      if(CheckPointer(Calc2Dialog) != POINTER_INVALID) Calc2Dialog.SaveObjectsToFile();
   }
   if(reason == REASON_REMOVE) {
      Print("Expert manually removed");
      if(CheckPointer(Calc2Dialog) == POINTER_DYNAMIC) { delete Calc2Dialog; Calc2Dialog = NULL; }
      if(CheckPointer(btnPrev) == POINTER_DYNAMIC) { delete btnPrev; btnPrev = NULL; }
      if(CheckPointer(btnNext) == POINTER_DYNAMIC) { delete btnNext; btnNext = NULL; }
      MainWindow.Destroy();
      isInitialized = false;
   }
   Print("OnDeinit completed");
}

//+------------------------------------------------------------------+
//| Live Trading Logic                                               |
//+------------------------------------------------------------------+
void OpenLivePosition(bool isBuy, double price, double sl, double tp, string comment = "", long magic = 0)
{
   double lot = g_lot;
   if(isBuy) {
      if(!trade.Buy(lot, _Symbol, price, sl, tp, comment)) {
         Print("Buy order failed: Error=", GetLastError());
      } else {
         trade.SetExpertMagicNumber(magic);
         Print("Buy order placed at ", price);
      }
   } else {
      if(!trade.Sell(lot, _Symbol, price, sl, tp, comment)) {
         Print("Sell order failed: Error=", GetLastError());
      } else {
         trade.SetExpertMagicNumber(magic);
         Print("Sell order placed at ", price);
      }
   }
}

void OnTick()
{
   if(!g_liveMode) return;

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   bool hedgeMode = CheckPointer(Calc2Dialog) != POINTER_INVALID && Calc2Dialog.m_chkHedge.Checked();

   string buyTrend = FindLatestLine("Trend_Buy_");
   string sellTrend = FindLatestLine("Trend_Sel_");
   double buyPrice = buyTrend != "" ? ObjectGetDouble(0, buyTrend, OBJPROP_PRICE, 0) : 0;
   double sellPrice = sellTrend != "" ? ObjectGetDouble(0, sellTrend, OBJPROP_PRICE, 0) : 0;

   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(buyPrice > 0 && MathAbs(buyPrice - ask) <= SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 10) {
      OpenLivePosition(true, ask, 0, 0, "HedgeBuy", 12345); // Без SL/TP, с хедж
      if(!hedgeMode) ObjectDelete(0, buyTrend);
   }
   else if(sellPrice > 0 && MathAbs(sellPrice - bid) <= SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 10) {
      OpenLivePosition(false, bid, 0, 0, "HedgeSell", 12345); // Без SL/TP, с хедж
      if(!hedgeMode) ObjectDelete(0, sellTrend);
   }

   if(hedgeMode && PositionSelect(_Symbol)) {
      long posType = PositionGetInteger(POSITION_TYPE);
      if(posType == POSITION_TYPE_BUY && sellPrice > 0 && MathAbs(sellPrice - bid) <= SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 10) {
         OpenLivePosition(false, bid, 0, 0, "HedgeSell", 12345);
      }
      else if(posType == POSITION_TYPE_SELL && buyPrice > 0 && MathAbs(buyPrice - ask) <= SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 10) {
         OpenLivePosition(true, ask, 0, 0, "HedgeBuy", 12345);
      }
   }
}

string FindLatestLine(string prefix)
{
   string latestName = "";
   datetime latestTime = 0;
   int total = ObjectsTotal(0, 0, -1);
   for(int i = total - 1; i >= 0; i--) {
      string name = ObjectName(0, i);
      if(StringFind(name, prefix) == 0) {
         datetime time = (datetime)StringToTime(StringSubstr(name, StringLen(prefix)));
         if(time > latestTime) {
            latestTime = time;
            latestName = name;
         }
      }
   }
   return latestName;
}

void ClearAllLines()
{
   int total = ObjectsTotal(0, 0, -1);
   for(int i = total - 1; i >= 0; i--) {
      string name = ObjectName(0, i);
      if(StringFind(name, "Trend_") == 0) {
         ObjectDelete(0, name);
      }
   }
}