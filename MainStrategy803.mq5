//+------------------------------------------------------------------+
//|                           15.03             MainStrategy803.mq5  |
//|                        Copyright 2024, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property strict
#property version "1.00"

#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Label.mqh>
#include <Controls\Edit.mqh>
#include <Controls\CheckBox.mqh>
#include <Trade\Trade.mqh>

// Глобални променливи
string g_entryHour = "09";
string g_entryMinute = "00";
double g_dev = 600.0; // Увеличена девиация за US30.c
double g_r1 = 1.0;
double g_r2 = 1.0;
double g_lot = 0.10;
long   g_period = 30;
double g_multiplier = 0.0001;
bool   g_liveMode = false;

// История на линиите за PREV/NEXT
struct TradeLine {
   double opPrice;
   double tpPrice;
   double slPrice;
   datetime startTime;
   datetime endTime;
   string prefix;
};
TradeLine tradeLines[];
int currentLineIndex = -1;

// Глобални обекти
CAppDialog MainWindow;
class CCalculator2Dialog;
CCalculator2Dialog *Calc2Dialog = NULL;
CButton *btnPrev = NULL;
CButton *btnNext = NULL;
CButton *btnClean = NULL;
CButton *btnTrade = NULL;
bool isInitialized = false;
CTrade trade;

// Помощна функция за създаване на бутони
void CreateControl(CAppDialog &dialog, string name, string text, int x, int y, int width, int height, color clr, int fontSize)
{
   CButton *btn = new CButton();
   if(btn.Create(0, name, 0, x, y, x + width, y + height)) {
      btn.Text(text);
      btn.ColorBackground(clr);
      btn.FontSize(fontSize);
      dialog.Add(btn);
   } else {
      delete btn;
   }
}

// Клас CTradeDialog
class CTradeDialog : public CAppDialog
{
private:
   CButton *m_btnCloseAll, *m_btnCloseBuy, *m_btnCloseSell;

public:
   CTradeDialog() {}
   ~CTradeDialog() {
      if(CheckPointer(m_btnCloseAll) == POINTER_DYNAMIC) delete m_btnCloseAll;
      if(CheckPointer(m_btnCloseBuy) == POINTER_DYNAMIC) delete m_btnCloseBuy;
      if(CheckPointer(m_btnCloseSell) == POINTER_DYNAMIC) delete m_btnCloseSell;
   }

   bool Create(const long chart, const string name, const int subwin) {
      if(!CAppDialog::Create(chart, name, subwin, 50, 50, 300, 150)) return false;
      if(!CreateControls()) return false;
      return true;
   }

private:
   bool CreateControls() {
      int x = 20, y = 20, w = 80, h = 25;
      m_btnCloseAll = new CButton();
      if(!m_btnCloseAll.Create(0, "btnCloseAll", 0, x, y, x + w, y + h)) return false;
      m_btnCloseAll.Text("Close All");
      Add(m_btnCloseAll);

      y += 30;
      m_btnCloseBuy = new CButton();
      if(!m_btnCloseBuy.Create(0, "btnCloseBuy", 0, x, y, x + w, y + h)) return false;
      m_btnCloseBuy.Text("Close Buy");
      Add(m_btnCloseBuy);

      y += 30;
      m_btnCloseSell = new CButton();
      if(!m_btnCloseSell.Create(0, "btnCloseSell", 0, x, y, x + w, y + h)) return false;
      m_btnCloseSell.Text("Close Sell");
      Add(m_btnCloseSell);

      return true;
   }

public:
   void OnClickCloseAll() {
      for(int i = PositionsTotal() - 1; i >= 0; i--) {
         ulong ticket = PositionGetTicket(i);
         if(PositionSelectByTicket(ticket)) trade.PositionClose(ticket);
      }
   }

   void OnClickCloseBuy() {
      for(int i = PositionsTotal() - 1; i >= 0; i--) {
         ulong ticket = PositionGetTicket(i);
         if(PositionSelectByTicket(ticket) && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
            trade.PositionClose(ticket);
         }
      }
   }

   void OnClickCloseSell() {
      for(int i = PositionsTotal() - 1; i >= 0; i--) {
         ulong ticket = PositionGetTicket(i);
         if(PositionSelectByTicket(ticket) && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
            trade.PositionClose(ticket);
         }
      }
   }
};

// Клас CCalculator2Dialog
class CCalculator2Dialog : public CAppDialog
{
public:
   CCheckBox    *m_chkTimeframes[7];
   CButton      *m_btnReverse[7];
   CCheckBox    *m_chkHedge;
   CEdit        *m_edtEntryHour, *m_edtEntryMinute, *m_edtDev, *m_edtR1, *m_edtR2, *m_edtLot, *m_edtPeriod, *m_edtMultiplier;
   CEdit        *m_edtProfitCount, *m_edtLossCount, *m_edtTotalSum;
   CButton      *m_btnCalcDev, *m_btnRunTest, *m_btnClose, *m_btnStartLive;
   CButton      *m_btnVariant1, *m_btnVariant2, *m_btnVariant3, *m_btnVariant4, *m_btnVariant5;
   CLabel       *m_labels[11];
   datetime     m_tradeTimes[];
   int          m_currentTradeIndex;
   bool         m_reverseLogic[7];

   CCalculator2Dialog() : m_currentTradeIndex(-1) {
      for(int i = 0; i < 7; i++) m_reverseLogic[i] = false;
   }

   ~CCalculator2Dialog() {
      for(int i = 0; i < 7; i++) {
         if(CheckPointer(m_chkTimeframes[i]) == POINTER_DYNAMIC) delete m_chkTimeframes[i];
         if(CheckPointer(m_btnReverse[i]) == POINTER_DYNAMIC) delete m_btnReverse[i];
      }
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
      if(CheckPointer(m_btnClose) == POINTER_DYNAMIC) delete m_btnClose;
      if(CheckPointer(m_btnVariant1) == POINTER_DYNAMIC) delete m_btnVariant1;
      if(CheckPointer(m_btnVariant2) == POINTER_DYNAMIC) delete m_btnVariant2;
      if(CheckPointer(m_btnVariant3) == POINTER_DYNAMIC) delete m_btnVariant3;
      if(CheckPointer(m_btnVariant4) == POINTER_DYNAMIC) delete m_btnVariant4;
      if(CheckPointer(m_btnVariant5) == POINTER_DYNAMIC) delete m_btnVariant5;
      if(CheckPointer(m_edtProfitCount) == POINTER_DYNAMIC) delete m_edtProfitCount;
      if(CheckPointer(m_edtLossCount) == POINTER_DYNAMIC) delete m_edtLossCount;
      if(CheckPointer(m_edtTotalSum) == POINTER_DYNAMIC) delete m_edtTotalSum;
      for(int i = 0; i < 11; i++) {
         if(CheckPointer(m_labels[i]) == POINTER_DYNAMIC) delete m_labels[i];
      }
   }

   bool Create(const long chart, const string name, const int subwin)
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

private:
   bool CreateControls()
   {
      int x = 20, y = 20;
      int w = 100, h = 25;
      string labels[] = {"Timeframe", "Entry Hour", "Entry Min", "Dev", "R1", "R2", "Lot", "Period (days)", "Multiplier", "Profits", "Losses", "Total Sum"};
      for(int i = 0; i < 11; i++) {
         m_labels[i] = new CLabel();
         if(!m_labels[i].Create(0, "Label" + labels[i], 0, x, y + (i > 1 ? 40 : 0), x + w, y + h + (i > 1 ? 40 : 0))) return false;
         m_labels[i].Text(labels[i]);
         Add(m_labels[i]);
         if(i != 1) y += 40;
      }

      y = 20; x += 120;
      string tfs[] = {"M1", "M5", "M15", "M30", "H1", "H4", "D1"};
      for(int i = 0; i < 7; i++) {
         m_chkTimeframes[i] = new CCheckBox();
         if(!m_chkTimeframes[i].Create(0, "chkTF" + tfs[i], 0, x, y, x + 60, y + h)) return false;
         m_chkTimeframes[i].Text(tfs[i]);
         m_chkTimeframes[i].Checked(i == 4);
         Add(m_chkTimeframes[i]);

         m_btnReverse[i] = new CButton();
         if(!m_btnReverse[i].Create(0, "btnReverse" + tfs[i], 0, x + 70, y, x + 90, y + h)) return false;
         m_btnReverse[i].Text("R");
         m_btnReverse[i].ColorBackground(clrLightGray);
         Add(m_btnReverse[i]);
         y += 30;
      }

      m_chkHedge = new CCheckBox();
      if(!m_chkHedge.Create(0, "chkHedge", 0, x, y, x + 60, y + h)) return false;
      m_chkHedge.Text("Hedge");
      m_chkHedge.Checked(false);
      Add(m_chkHedge);

      y = 60; x += 80;
      m_edtEntryHour = new CEdit();
      if(!m_edtEntryHour.Create(0, "edtEntryHour", 0, x, y, x + 40, y + h)) return false;
      m_edtEntryHour.Text(g_entryHour);
      Add(m_edtEntryHour);

      m_edtEntryMinute = new CEdit();
      if(!m_edtEntryMinute.Create(0, "edtEntryMinute", 0, x + 50, y, x + 90, y + h)) return false;
      m_edtEntryMinute.Text(g_entryMinute);
      Add(m_edtEntryMinute);
      y += 40;

      m_edtDev = new CEdit();
      if(!m_edtDev.Create(0, "edtDev", 0, x, y, x + w, y + h)) return false;
      m_edtDev.Text(DoubleToString(g_dev, 2));
      Add(m_edtDev);
      y += 40;

      m_edtR1 = new CEdit();
      if(!m_edtR1.Create(0, "edtR1", 0, x, y, x + 40, y + h)) return false;
      m_edtR1.Text(DoubleToString(g_r1, 0));
      Add(m_edtR1);
      y += 40;

      m_edtR2 = new CEdit();
      if(!m_edtR2.Create(0, "edtR2", 0, x, y, x + 40, y + h)) return false;
      m_edtR2.Text(DoubleToString(g_r2, 0));
      Add(m_edtR2);
      y += 40;

      m_edtLot = new CEdit();
      if(!m_edtLot.Create(0, "edtLot", 0, x, y, x + w, y + h)) return false;
      m_edtLot.Text(DoubleToString(g_lot, 2));
      Add(m_edtLot);
      y += 40;

      m_edtPeriod = new CEdit();
      if(!m_edtPeriod.Create(0, "edtPeriod", 0, x, y, x + w, y + h)) return false;
      m_edtPeriod.Text(IntegerToString(g_period));
      Add(m_edtPeriod);
      y += 40;

      m_edtMultiplier = new CEdit();
      if(!m_edtMultiplier.Create(0, "edtMultiplier", 0, x, y, x + w, y + h)) return false;
      m_edtMultiplier.Text(DoubleToString(g_multiplier, 4));
      Add(m_edtMultiplier);
      y += 40;

      m_edtProfitCount = new CEdit();
      if(!m_edtProfitCount.Create(0, "edtProfitCount", 0, x, y, x + w, y + h)) return false;
      m_edtProfitCount.Text("0");
      Add(m_edtProfitCount);
      y += 40;

      m_edtLossCount = new CEdit();
      if(!m_edtLossCount.Create(0, "edtLossCount", 0, x, y, x + w, y + h)) return false;
      m_edtLossCount.Text("0");
      Add(m_edtLossCount);
      y += 40;

      m_edtTotalSum = new CEdit();
      if(!m_edtTotalSum.Create(0, "edtTotalSum", 0, x, y, x + w, y + h)) return false;
      m_edtTotalSum.Text("0.00");
      Add(m_edtTotalSum);

      y = 60; x += 120;
      m_btnCalcDev = new CButton();
      if(!m_btnCalcDev.Create(0, "btnCalcDev", 0, x, y, x + 80, y + 25)) return false;
      m_btnCalcDev.Text("CalcDev");
      Add(m_btnCalcDev);
      y += 30;

      m_btnStartLive = new CButton();
      if(!m_btnStartLive.Create(0, "btnStartLive", 0, x, y, x + 80, y + 25)) return false;
      m_btnStartLive.Text("Stop Live");
      Add(m_btnStartLive);
      y += 30;

      m_btnRunTest = new CButton();
      if(!m_btnRunTest.Create(0, "btnRunTest", 0, x, y, x + 80, y + 25)) return false;
      m_btnRunTest.Text("Run Test");
      Add(m_btnRunTest);
      y += 30;

      m_btnClose = new CButton();
      if(!m_btnClose.Create(0, "btnClose", 0, x, y, x + 80, y + 25)) return false;
      m_btnClose.Text("Close");
      Add(m_btnClose);
      y += 30;

      m_btnVariant1 = new CButton();
      if(!m_btnVariant1.Create(0, "btnVariant1", 0, x, y, x + 40, y + 25)) return false;
      m_btnVariant1.Text("1");
      Add(m_btnVariant1);
      x += 50;

      m_btnVariant2 = new CButton();
      if(!m_btnVariant2.Create(0, "btnVariant2", 0, x, y, x + 40, y + 25)) return false;
      m_btnVariant2.Text("2");
      Add(m_btnVariant2);
      x += 50;

      m_btnVariant3 = new CButton();
      if(!m_btnVariant3.Create(0, "btnVariant3", 0, x, y, x + 40, y + 25)) return false;
      m_btnVariant3.Text("3");
      Add(m_btnVariant3);
      x += 50;

      m_btnVariant4 = new CButton();
      if(!m_btnVariant4.Create(0, "btnVariant4", 0, x, y, x + 40, y + 25)) return false;
      m_btnVariant4.Text("4");
      Add(m_btnVariant4);
      x += 50;

      m_btnVariant5 = new CButton();
      if(!m_btnVariant5.Create(0, "btnVariant5", 0, x, y, x + 40, y + 25)) return false;
      m_btnVariant5.Text("5");
      Add(m_btnVariant5);

      return true;
   }

public:
   void LoadParameters() {
      m_edtEntryHour.Text(g_entryHour);
      m_edtEntryMinute.Text(g_entryMinute);
      m_edtDev.Text(DoubleToString(g_dev, 2));
      m_edtR1.Text(DoubleToString(g_r1, 0));
      m_edtR2.Text(DoubleToString(g_r2, 0));
      m_edtLot.Text(DoubleToString(g_lot, 2));
      m_edtPeriod.Text(IntegerToString(g_period));
      m_edtMultiplier.Text(DoubleToString(g_multiplier, 4));
      m_chkHedge.Checked(false);
   }

   void SaveParameters() {
      g_entryHour = m_edtEntryHour.Text();
      g_entryMinute = m_edtEntryMinute.Text();
      g_dev = StringToDouble(m_edtDev.Text());
      g_r1 = StringToDouble(m_edtR1.Text());
      g_r2 = StringToDouble(m_edtR2.Text());
      g_lot = StringToDouble(m_edtLot.Text());
      g_period = StringToInteger(m_edtPeriod.Text());
      g_multiplier = StringToDouble(m_edtMultiplier.Text());
      g_liveMode = (m_btnStartLive.Text() == "Stop Live");
   }

   void LoadObjectsFromFile() {}
   void SaveObjectsToFile() {}
};

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
      CreateControl(MainWindow, "btnClean", "CLEAN", 130, 10, 50, 25, clrRed, 8);
      CreateControl(MainWindow, "btnTrade", "TRADE", 190, 10, 50, 25, clrBlue, 8);

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

      LoadInputParameters();
   } else {
      Print("Reinitializing after timeframe change");
      MainWindow.Show();
      if(CheckPointer(Calc2Dialog) != POINTER_INVALID) Calc2Dialog.LoadObjectsFromFile();
   }

   Print("OnInit completed successfully");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert Deinitialization                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("Deinit reason: ", reason);
   if(reason == REASON_REMOVE || reason == REASON_RECOMPILE) {
      if(CheckPointer(Calc2Dialog) != POINTER_INVALID) Calc2Dialog.SaveObjectsToFile();
      SaveInputParameters();
   }
   if(reason == REASON_REMOVE) {
      Print("Expert manually removed");
      if(CheckPointer(Calc2Dialog) == POINTER_DYNAMIC) { delete Calc2Dialog; Calc2Dialog = NULL; }
      if(CheckPointer(btnPrev) == POINTER_DYNAMIC) { delete btnPrev; btnPrev = NULL; }
      if(CheckPointer(btnNext) == POINTER_DYNAMIC) { delete btnNext; btnNext = NULL; }
      if(CheckPointer(btnClean) == POINTER_DYNAMIC) { delete btnClean; btnClean = NULL; }
      if(CheckPointer(btnTrade) == POINTER_DYNAMIC) { delete btnTrade; btnTrade = NULL; }
      MainWindow.Destroy();
      isInitialized = false;
   }
   Print("OnDeinit completed");
}

//+------------------------------------------------------------------+
//| Save Input Parameters to File                                    |
//+------------------------------------------------------------------+
void SaveInputParameters()
{
   int handle = FileOpen("MainStrategy801_settings.txt", FILE_WRITE|FILE_TXT);
   if(handle == INVALID_HANDLE) {
      Print("Failed to save parameters to file");
      return;
   }
   FileWrite(handle, g_entryHour);
   FileWrite(handle, g_entryMinute);
   FileWrite(handle, DoubleToString(g_dev, 2));
   FileWrite(handle, DoubleToString(g_r1, 2));
   FileWrite(handle, DoubleToString(g_r2, 2));
   FileWrite(handle, DoubleToString(g_lot, 2));
   FileWrite(handle, IntegerToString(g_period));
   FileWrite(handle, DoubleToString(g_multiplier, 4));
   FileWrite(handle, g_liveMode ? "true" : "false");
   FileClose(handle);
   Print("Parameters saved to file");
}

//+------------------------------------------------------------------+
//| Load Input Parameters from File                                  |
//+------------------------------------------------------------------+
void LoadInputParameters()
{
   int handle = FileOpen("MainStrategy801_settings.txt", FILE_READ|FILE_TXT);
   if(handle == INVALID_HANDLE) {
      Print("Failed to load parameters, using defaults");
      return;
   }
   g_entryHour = FileReadString(handle);
   g_entryMinute = FileReadString(handle);
   g_dev = StringToDouble(FileReadString(handle));
   g_r1 = StringToDouble(FileReadString(handle));
   g_r2 = StringToDouble(FileReadString(handle));
   g_lot = StringToDouble(FileReadString(handle));
   g_period = StringToInteger(FileReadString(handle));
   g_multiplier = StringToDouble(FileReadString(handle));
   string liveMode = FileReadString(handle);
   g_liveMode = (liveMode == "true");
   FileClose(handle);
   Print("Parameters loaded from file");
}

//+------------------------------------------------------------------+
//| Calculate Deviation                                              |
//+------------------------------------------------------------------+
double CalculateDeviation(ENUM_TIMEFRAMES tf)
{
   double high[], low[];
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   CopyHigh(Symbol(), tf, 1, 10, high);
   CopyLow(Symbol(), tf, 1, 10, low);
   double avgRange = 0;
   for(int i = 0; i < 10; i++) {
      avgRange += high[i] - low[i];
   }
   avgRange /= 10;
   return avgRange * 2; // Удвояваме за по-голям обхват
}

//+------------------------------------------------------------------+
//| Expert Tick Function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   if(g_liveMode) {
      for(int i = 0; i < 7; i++) {
         if(Calc2Dialog.m_chkTimeframes[i].Checked()) {
            bool reverse = Calc2Dialog.m_reverseLogic[i];
            if(Calc2Dialog.m_btnVariant3.ColorBackground() == clrGreen) LiveMod3L(i, reverse);
            if(Calc2Dialog.m_btnVariant4.ColorBackground() == clrGreen) LiveMod4L(i, reverse);
            if(Calc2Dialog.m_btnVariant5.ColorBackground() == clrGreen) LiveMod5L(i);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| RunMod3L - 3 линии в Run режим                                   |
//+------------------------------------------------------------------+
void RunMod3L(int tfIndex, bool reverse)
{
   ENUM_TIMEFRAMES tf;
   switch(tfIndex) {
      case 0: tf = PERIOD_M1; break;
      case 1: tf = PERIOD_M5; break;
      case 2: tf = PERIOD_M15; break;
      case 3: tf = PERIOD_M30; break;
      case 4: tf = PERIOD_H1; break;
      case 5: tf = PERIOD_H4; break;
      case 6: tf = PERIOD_D1; break;
      default: return;
   }

   double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   double dev = g_dev;

   double opPriceB = bid;
   double tpPriceB = bid + dev;
   double slPriceB = bid - dev;
   double opPriceS = bid;
   double tpPriceS = bid - dev;
   double slPriceS = bid + dev;

   double opPrice = reverse ? opPriceS : opPriceB;
   double tpPrice = reverse ? tpPriceS : tpPriceB;
   double slPrice = reverse ? slPriceS : slPriceB;

   datetime time = TimeCurrent();
   datetime endTime = time + PeriodSeconds(tf) * 100;
   string prefix = "Run3L_" + IntegerToString(tfIndex) + "_";

   ObjectCreate(0, prefix + "op", OBJ_HLINE, 0, 0, opPrice);
   ObjectSetInteger(0, prefix + "op", OBJPROP_COLOR, clrYellow);
   ObjectSetInteger(0, prefix + "op", OBJPROP_STYLE, STYLE_SOLID);

   ObjectCreate(0, prefix + "tp", OBJ_HLINE, 0, 0, tpPrice);
   ObjectSetInteger(0, prefix + "tp", OBJPROP_COLOR, clrLime);
   ObjectSetInteger(0, prefix + "tp", OBJPROP_STYLE, STYLE_SOLID);

   ObjectCreate(0, prefix + "sl", OBJ_HLINE, 0, 0, slPrice);
   ObjectSetInteger(0, prefix + "sl", OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, prefix + "sl", OBJPROP_STYLE, STYLE_SOLID);

   for(int i = 1; i <= 100; i++) {
      double currentClose = iClose(Symbol(), tf, i);
      if(currentClose >= tpPrice || currentClose <= slPrice) {
         endTime = iTime(Symbol(), tf, i);
         double result = (currentClose >= tpPrice) ? dev : -dev;
         int profitCount = StringToInteger(Calc2Dialog.m_edtProfitCount.Text());
         int lossCount = StringToInteger(Calc2Dialog.m_edtLossCount.Text());
         double totalSum = StringToDouble(Calc2Dialog.m_edtTotalSum.Text());
         if(result > 0) profitCount++; else lossCount++;
         totalSum += result;
         Calc2Dialog.m_edtProfitCount.Text(IntegerToString(profitCount));
         Calc2Dialog.m_edtLossCount.Text(IntegerToString(lossCount));
         Calc2Dialog.m_edtTotalSum.Text(DoubleToString(totalSum, 2));
         break;
      }
   }

   ObjectCreate(0, prefix + "op_trend", OBJ_TREND, 0, time, opPrice, endTime, opPrice);
   ObjectSetInteger(0, prefix + "op_trend", OBJPROP_COLOR, clrYellow);
   ObjectSetInteger(0, prefix + "op_trend", OBJPROP_RAY, false);

   ObjectCreate(0, prefix + "tp_trend", OBJ_TREND, 0, time, tpPrice, endTime, tpPrice);
   ObjectSetInteger(0, prefix + "tp_trend", OBJPROP_COLOR, clrLime);
   ObjectSetInteger(0, prefix + "tp_trend", OBJPROP_RAY, false);

   ObjectCreate(0, prefix + "sl_trend", OBJ_TREND, 0, time, slPrice, endTime, slPrice);
   ObjectSetInteger(0, prefix + "sl_trend", OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, prefix + "sl_trend", OBJPROP_RAY, false);

   // Запазване в историята
   ArrayResize(tradeLines, ArraySize(tradeLines) + 1);
   tradeLines[ArraySize(tradeLines) - 1].opPrice = opPrice;
   tradeLines[ArraySize(tradeLines) - 1].tpPrice = tpPrice;
   tradeLines[ArraySize(tradeLines) - 1].slPrice = slPrice;
   tradeLines[ArraySize(tradeLines) - 1].startTime = time;
   tradeLines[ArraySize(tradeLines) - 1].endTime = endTime;
   tradeLines[ArraySize(tradeLines) - 1].prefix = prefix;
   currentLineIndex = ArraySize(tradeLines) - 1;
}

//+------------------------------------------------------------------+
//| RunMod4L - 4 линии в Run режим                                   |
//+------------------------------------------------------------------+
void RunMod4L(int tfIndex, bool reverse)
{
   ENUM_TIMEFRAMES tf;
   switch(tfIndex) {
      case 0: tf = PERIOD_M1; break;
      case 1: tf = PERIOD_M5; break;
      case 2: tf = PERIOD_M15; break;
      case 3: tf = PERIOD_M30; break;
      case 4: tf = PERIOD_H1; break;
      case 5: tf = PERIOD_H4; break;
      case 6: tf = PERIOD_D1; break;
      default: return;
   }

   double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   double dev = g_dev;

   double opPrice = bid;
   double BH1 = bid + dev;
   double SH2 = bid - dev;
   double SH3p = bid + 3 * dev;
   double BH4p = bid - 3 * dev;

   if(reverse) {
      BH1 = bid - dev;
      SH2 = bid + dev;
      SH3p = bid - 3 * dev;
      BH4p = bid + 3 * dev;
   }

   datetime time = TimeCurrent();
   datetime endTime = time + PeriodSeconds(tf) * 100;
   string prefix = "Run4L_" + IntegerToString(tfIndex) + "_";

   ObjectCreate(0, prefix + "op", OBJ_HLINE, 0, 0, opPrice);
   ObjectSetInteger(0, prefix + "op", OBJPROP_COLOR, clrYellow);
   ObjectSetInteger(0, prefix + "op", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, prefix + "op", OBJPROP_SELECTED, true);

   ObjectCreate(0, prefix + "BH1", OBJ_HLINE, 0, 0, BH1);
   ObjectSetInteger(0, prefix + "BH1", OBJPROP_COLOR, clrLime);
   ObjectSetInteger(0, prefix + "BH1", OBJPROP_STYLE, STYLE_SOLID);

   ObjectCreate(0, prefix + "SH2", OBJ_HLINE, 0, 0, SH2);
   ObjectSetInteger(0, prefix + "SH2", OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, prefix + "SH2", OBJPROP_STYLE, STYLE_SOLID);

   ObjectCreate(0, prefix + "SH3p", OBJ_HLINE, 0, 0, SH3p);
   ObjectSetInteger(0, prefix + "SH3p", OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, prefix + "SH3p", OBJPROP_STYLE, STYLE_SOLID);

   ObjectCreate(0, prefix + "BH4p", OBJ_HLINE, 0, 0, BH4p);
   ObjectSetInteger(0, prefix + "BH4p", OBJPROP_COLOR, clrLime);
   ObjectSetInteger(0, prefix + "BH4p", OBJPROP_STYLE, STYLE_SOLID);

   int hitCount = 0;
   double result = 0.0;
   for(int i = 1; i <= 100 && hitCount < 2; i++) {
      double currentClose = iClose(Symbol(), tf, i);
      bool hitBH1 = currentClose >= BH1;
      bool hitSH2 = currentClose <= SH2;
      bool hitSH3p = currentClose >= SH3p;
      bool hitBH4p = currentClose <= BH4p;

      if(hitBH1 || hitSH2 || hitSH3p || hitBH4p) {
         hitCount++;
         if(hitCount == 1) {
            if(hitBH1) result -= dev;
            if(hitSH2) result += dev;
         }
         if(hitCount == 2) {
            if(hitSH3p) result += 2 * dev;
            if(hitBH4p) result -= 2 * dev;
            endTime = iTime(Symbol(), tf, i);
            int profitCount = StringToInteger(Calc2Dialog.m_edtProfitCount.Text());
            int lossCount = StringToInteger(Calc2Dialog.m_edtLossCount.Text());
            double totalSum = StringToDouble(Calc2Dialog.m_edtTotalSum.Text());
            if(result > 0) profitCount++; else lossCount++;
            totalSum += result;
            Calc2Dialog.m_edtProfitCount.Text(IntegerToString(profitCount));
            Calc2Dialog.m_edtLossCount.Text(IntegerToString(lossCount));
            Calc2Dialog.m_edtTotalSum.Text(DoubleToString(totalSum, 2));
            break;
         }
      }
   }

   ObjectCreate(0, prefix + "op_trend", OBJ_TREND, 0, time, opPrice, endTime, opPrice);
   ObjectSetInteger(0, prefix + "op_trend", OBJPROP_COLOR, clrYellow);
   ObjectSetInteger(0, prefix + "op_trend", OBJPROP_RAY, false);

   ObjectCreate(0, prefix + "BH1_trend", OBJ_TREND, 0, time, BH1, endTime, BH1);
   ObjectSetInteger(0, prefix + "BH1_trend", OBJPROP_COLOR, clrLime);
   ObjectSetInteger(0, prefix + "BH1_trend", OBJPROP_RAY, false);

   ObjectCreate(0, prefix + "SH2_trend", OBJ_TREND, 0, time, SH2, endTime, SH2);
   ObjectSetInteger(0, prefix + "SH2_trend", OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, prefix + "SH2_trend", OBJPROP_RAY, false);

   ObjectCreate(0, prefix + "SH3p_trend", OBJ_TREND, 0, time, SH3p, endTime, SH3p);
   ObjectSetInteger(0, prefix + "SH3p_trend", OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, prefix + "SH3p_trend", OBJPROP_RAY, false);

   ObjectCreate(0, prefix + "BH4p_trend", OBJ_TREND, 0, time, BH4p, endTime, BH4p);
   ObjectSetInteger(0, prefix + "BH4p_trend", OBJPROP_COLOR, clrLime);
   ObjectSetInteger(0, prefix + "BH4p_trend", OBJPROP_RAY, false);

   // Запазване в историята
   ArrayResize(tradeLines, ArraySize(tradeLines) + 1);
   tradeLines[ArraySize(tradeLines) - 1].opPrice = opPrice;
   tradeLines[ArraySize(tradeLines) - 1].tpPrice = BH1;
   tradeLines[ArraySize(tradeLines) - 1].slPrice = SH2;
   tradeLines[ArraySize(tradeLines) - 1].startTime = time;
   tradeLines[ArraySize(tradeLines) - 1].endTime = endTime;
   tradeLines[ArraySize(tradeLines) - 1].prefix = prefix;
   currentLineIndex = ArraySize(tradeLines) - 1;
}

//+------------------------------------------------------------------+
//| LiveMod3L - 3 линии в Live режим                                 |
//+------------------------------------------------------------------+
void LiveMod3L(int tfIndex, bool reverse)
{
   ENUM_TIMEFRAMES tf;
   switch(tfIndex) {
      case 0: tf = PERIOD_M1; break;
      case 1: tf = PERIOD_M5; break;
      case 2: tf = PERIOD_M15; break;
      case 3: tf = PERIOD_M30; break;
      case 4: tf = PERIOD_H1; break;
      case 5: tf = PERIOD_H4; break;
      case 6: tf = PERIOD_D1; break;
      default: return;
   }

   double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   double dev = g_dev;

   double opPriceB = bid;
   double tpPriceB = bid + dev;
   double slPriceB = bid - dev;
   double opPriceS = bid;
   double tpPriceS = bid - dev;
   double slPriceS = bid + dev;

   double opPrice = reverse ? opPriceS : opPriceB;
   double tpPrice = reverse ? tpPriceS : tpPriceB;
   double slPrice = reverse ? slPriceS : slPriceB;

   datetime time = TimeCurrent();
   datetime endTime = time + PeriodSeconds(tf) * 100;
   string prefix = "Live3L_" + IntegerToString(tfIndex) + "_";

   ObjectCreate(0, prefix + "op", OBJ_HLINE, 0, 0, opPrice);
   ObjectSetInteger(0, prefix + "op", OBJPROP_COLOR, clrYellow);
   ObjectSetInteger(0, prefix + "op", OBJPROP_STYLE, STYLE_SOLID);

   ObjectCreate(0, prefix + "tp", OBJ_HLINE, 0, 0, tpPrice);
   ObjectSetInteger(0, prefix + "tp", OBJPROP_COLOR, clrLime);
   ObjectSetInteger(0, prefix + "tp", OBJPROP_STYLE, STYLE_SOLID);

   ObjectCreate(0, prefix + "sl", OBJ_HLINE, 0, 0, slPrice);
   ObjectSetInteger(0, prefix + "sl", OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, prefix + "sl", OBJPROP_STYLE, STYLE_SOLID);

   // Ограничение за броя на позициите
   int maxPositions = 1;
   int openPositions = 0;
   for(int i = 0; i < PositionsTotal(); i++) {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket) && StringFind(PositionGetString(POSITION_COMMENT), prefix) >= 0) {
         openPositions++;
      }
   }

   if(bid >= opPrice && openPositions < maxPositions && !PositionSelectByTicket(GetTicket(prefix))) {
      if(!reverse) trade.Buy(g_lot, Symbol(), bid, slPrice, tpPrice, prefix);
      else trade.Sell(g_lot, Symbol(), bid, slPrice, tpPrice, prefix);
   }

   if(PositionSelectByTicket(GetTicket(prefix))) {
      double currentPrice = SymbolInfoDouble(Symbol(), SYMBOL_BID);
      if(currentPrice >= tpPrice || currentPrice <= slPrice) {
         endTime = TimeCurrent();
         trade.PositionClose(GetTicket(prefix));
      }
   }

   ObjectCreate(0, prefix + "op_trend", OBJ_TREND, 0, time, opPrice, endTime, opPrice);
   ObjectSetInteger(0, prefix + "op_trend", OBJPROP_COLOR, clrYellow);
   ObjectSetInteger(0, prefix + "op_trend", OBJPROP_RAY, false);

   ObjectCreate(0, prefix + "tp_trend", OBJ_TREND, 0, time, tpPrice, endTime, tpPrice);
   ObjectSetInteger(0, prefix + "tp_trend", OBJPROP_COLOR, clrLime);
   ObjectSetInteger(0, prefix + "tp_trend", OBJPROP_RAY, false);

   ObjectCreate(0, prefix + "sl_trend", OBJ_TREND, 0, time, slPrice, endTime, slPrice);
   ObjectSetInteger(0, prefix + "sl_trend", OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, prefix + "sl_trend", OBJPROP_RAY, false);

   // Запазване в историята
   ArrayResize(tradeLines, ArraySize(tradeLines) + 1);
   tradeLines[ArraySize(tradeLines) - 1].opPrice = opPrice;
   tradeLines[ArraySize(tradeLines) - 1].tpPrice = tpPrice;
   tradeLines[ArraySize(tradeLines) - 1].slPrice = slPrice;
   tradeLines[ArraySize(tradeLines) - 1].startTime = time;
   tradeLines[ArraySize(tradeLines) - 1].endTime = endTime;
   tradeLines[ArraySize(tradeLines) - 1].prefix = prefix;
   currentLineIndex = ArraySize(tradeLines) - 1;
}

//+------------------------------------------------------------------+
//| LiveMod4L - 4 линии в Live режим                                 |
//+------------------------------------------------------------------+
void LiveMod4L(int tfIndex, bool reverse)
{
   ENUM_TIMEFRAMES tf;
   switch(tfIndex) {
      case 0: tf = PERIOD_M1; break;
      case 1: tf = PERIOD_M5; break;
      case 2: tf = PERIOD_M15; break;
      case 3: tf = PERIOD_M30; break;
      case 4: tf = PERIOD_H1; break;
      case 5: tf = PERIOD_H4; break;
      case 6: tf = PERIOD_D1; break;
      default: return;
   }

   double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   double dev = g_dev;

   double opPrice = bid;
   double BH1 = bid + dev;
   double SH2 = bid - dev;
   double SH3p = bid + 3 * dev;
   double BH4p = bid - 3 * dev;

   if(reverse) {
      BH1 = bid - dev;
      SH2 = bid + dev;
      SH3p = bid - 3 * dev;
      BH4p = bid + 3 * dev;
   }

   datetime time = TimeCurrent();
   datetime endTime = time + PeriodSeconds(tf) * 100;
   string prefix = "Live4L_" + IntegerToString(tfIndex) + "_";

   ObjectCreate(0, prefix + "op", OBJ_HLINE, 0, 0, opPrice);
   ObjectSetInteger(0, prefix + "op", OBJPROP_COLOR, clrYellow);
   ObjectSetInteger(0, prefix + "op", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, prefix + "op", OBJPROP_SELECTED, true);

   ObjectCreate(0, prefix + "BH1", OBJ_HLINE, 0, 0, BH1);
   ObjectSetInteger(0, prefix + "BH1", OBJPROP_COLOR, clrLime);
   ObjectSetInteger(0, prefix + "BH1", OBJPROP_STYLE, STYLE_SOLID);

   ObjectCreate(0, prefix + "SH2", OBJ_HLINE, 0, 0, SH2);
   ObjectSetInteger(0, prefix + "SH2", OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, prefix + "SH2", OBJPROP_STYLE, STYLE_SOLID);

   ObjectCreate(0, prefix + "SH3p", OBJ_HLINE, 0, 0, SH3p);
   ObjectSetInteger(0, prefix + "SH3p", OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, prefix + "SH3p", OBJPROP_STYLE, STYLE_SOLID);

   ObjectCreate(0, prefix + "BH4p", OBJ_HLINE, 0, 0, BH4p);
   ObjectSetInteger(0, prefix + "BH4p", OBJPROP_COLOR, clrLime);
   ObjectSetInteger(0, prefix + "BH4p", OBJPROP_STYLE, STYLE_SOLID);

   // Ограничение за броя на позициите
   int maxPositions = 1;
   int openPositions = 0;
   for(int i = 0; i < PositionsTotal(); i++) {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket) && StringFind(PositionGetString(POSITION_COMMENT), prefix) >= 0) {
         openPositions++;
      }
   }

   int hitCount = 0;
   for(int i = 0; i < 100 && hitCount < 2; i++) {
      double currentPrice = bid;
      bool hitBH1 = currentPrice >= BH1 && openPositions < maxPositions && !PositionSelectByTicket(GetTicket(prefix + "BH1"));
      bool hitSH2 = currentPrice <= SH2 && openPositions < maxPositions && !PositionSelectByTicket(GetTicket(prefix + "SH2"));
      bool hitSH3p = currentPrice >= SH3p && openPositions < maxPositions && !PositionSelectByTicket(GetTicket(prefix + "SH3p"));
      bool hitBH4p = currentPrice <= BH4p && openPositions < maxPositions && !PositionSelectByTicket(GetTicket(prefix + "BH4p"));

      if(hitBH1) {
         trade.Buy(g_lot, Symbol(), currentPrice, BH4p, SH3p, prefix + "BH1");
         CreateProfitButton(prefix + "BH1", currentPrice, clrLime);
         hitCount++;
         openPositions++;
      }
      if(hitSH2) {
         trade.Sell(g_lot, Symbol(), currentPrice, SH3p, BH4p, prefix + "SH2");
         CreateProfitButton(prefix + "SH2", currentPrice, clrRed);
         hitCount++;
         openPositions++;
      }
      if(hitSH3p) {
         trade.Sell(g_lot, Symbol(), currentPrice, SH2, BH1, prefix + "SH3p");
         CreateProfitButton(prefix + "SH3p", currentPrice, clrRed);
         hitCount++;
         openPositions++;
      }
      if(hitBH4p) {
         trade.Buy(g_lot, Symbol(), currentPrice, BH1, SH2, prefix + "BH4p");
         CreateProfitButton(prefix + "BH4p", currentPrice, clrLime);
         hitCount++;
         openPositions++;
      }

      if(hitCount == 2) {
         endTime = TimeCurrent();
         break;
      }
   }

   if(hitCount >= 2) {
      ObjectDelete(0, prefix + "op");
      ObjectDelete(0, prefix + "BH1");
      ObjectDelete(0, prefix + "SH2");
      ObjectDelete(0, prefix + "SH3p");
      ObjectDelete(0, prefix + "BH4p");
   }

   // Запазване в историята
   ArrayResize(tradeLines, ArraySize(tradeLines) + 1);
   tradeLines[ArraySize(tradeLines) - 1].opPrice = opPrice;
   tradeLines[ArraySize(tradeLines) - 1].tpPrice = BH1;
   tradeLines[ArraySize(tradeLines) - 1].slPrice = SH2;
   tradeLines[ArraySize(tradeLines) - 1].startTime = time;
   tradeLines[ArraySize(tradeLines) - 1].endTime = endTime;
   tradeLines[ArraySize(tradeLines) - 1].prefix = prefix;
   currentLineIndex = ArraySize(tradeLines) - 1;
}

//+------------------------------------------------------------------+
//| LiveMod5L - Ръчно задаване на B/S линии                          |
//+------------------------------------------------------------------+
void LiveMod5L(int tfIndex)
{
   // Тази функция ще се изпълнява при кликване върху графиката
   // Засега ще добавим само базова логика
   Print("Variant 5 selected - awaiting manual line placement");
}

//+------------------------------------------------------------------+
//| Помощни функции                                                  |
//+------------------------------------------------------------------+
ulong GetTicket(string prefix)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket)) {
         string comment = PositionGetString(POSITION_COMMENT);
         if(StringFind(comment, prefix) >= 0) return ticket;
      }
   }
   return 0;
}

void CreateProfitButton(string name, double price, color clr)
{
   string btnName = name + "_profit";
   ObjectCreate(0, btnName, OBJ_BUTTON, 0, 0, price);
   ObjectSetInteger(0, btnName, OBJPROP_COLOR, clr);
   ObjectSetString(0, btnName, OBJPROP_TEXT, DoubleToString(price, 2));
   ObjectSetInteger(0, btnName, OBJPROP_XDISTANCE, 50);
   ObjectSetInteger(0, btnName, OBJPROP_YDISTANCE, 50);
}

//+------------------------------------------------------------------+
//| Обработчик на събития                                            |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   static CTradeDialog tradeDialog;
   static bool tradeDialogCreated = false;

   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sparam == "btnCalc2") {
         Calc2Dialog.Show();
      }
      else if(sparam == "btnClean") {
         ObjectsDeleteAll(0, "Run3L_");
         ObjectsDeleteAll(0, "Run4L_");
         ObjectsDeleteAll(0, "Live3L_");
         ObjectsDeleteAll(0, "Live4L_");
         Calc2Dialog.m_edtProfitCount.Text("0");
         Calc2Dialog.m_edtLossCount.Text("0");
         Calc2Dialog.m_edtTotalSum.Text("0.00");
         ArrayResize(tradeLines, 0);
         currentLineIndex = -1;
      }
      else if(sparam == "btnTrade") {
         if(!tradeDialogCreated) {
            tradeDialog.Create(0, "Trade", 0);
            tradeDialogCreated = true;
         }
         tradeDialog.Show();
      }
      else if(sparam == "btnCloseAll") {
         tradeDialog.OnClickCloseAll();
      }
      else if(sparam == "btnCloseBuy") {
         tradeDialog.OnClickCloseBuy();
      }
      else if(sparam == "btnCloseSell") {
         tradeDialog.OnClickCloseSell();
      }
      else if(sparam == "btnClose") {
         Calc2Dialog.SaveParameters();
         Calc2Dialog.SaveObjectsToFile();
         Calc2Dialog.Hide();
      }
      else if(sparam == "btnRunTest") {
         for(int i = 0; i < 7; i++) {
            if(Calc2Dialog.m_chkTimeframes[i].Checked()) {
               bool reverse = Calc2Dialog.m_reverseLogic[i];
               if(Calc2Dialog.m_btnVariant3.ColorBackground() == clrGreen) RunMod3L(i, reverse);
               if(Calc2Dialog.m_btnVariant4.ColorBackground() == clrGreen) RunMod4L(i, reverse);
            }
         }
      }
      else if(sparam == "btnStartLive") {
         if(g_liveMode) {
            g_liveMode = false;
            Calc2Dialog.m_btnStartLive.Text("Start Live");
         } else {
            g_liveMode = true;
            Calc2Dialog.m_btnStartLive.Text("Stop Live");
         }
      }
      else if(sparam == "btnCalcDev") {
         ENUM_TIMEFRAMES tf = PERIOD_H1;
         for(int i = 0; i < 7; i++) {
            if(Calc2Dialog.m_chkTimeframes[i].Checked()) {
               switch(i) {
                  case 0: tf = PERIOD_M1; break;
                  case 1: tf = PERIOD_M5; break;
                  case 2: tf = PERIOD_M15; break;
                  case 3: tf = PERIOD_M30; break;
                  case 4: tf = PERIOD_H1; break;
                  case 5: tf = PERIOD_H4; break;
                  case 6: tf = PERIOD_D1; break;
               }
               break;
            }
         }
         g_dev = CalculateDeviation(tf);
         Calc2Dialog.m_edtDev.Text(DoubleToString(g_dev, 2));
      }
      else if(sparam == "btnPrev") {
         if(currentLineIndex > 0) {
            currentLineIndex--;
            TradeLine line = tradeLines[currentLineIndex];
            ChartSetSymbolPeriod(0, Symbol(), PERIOD_H1);
            ChartNavigate(0, CHART_END, -(TimeCurrent() - line.startTime) / PeriodSeconds(PERIOD_H1));
         }
      }
      else if(sparam == "btnNext") {
         if(currentLineIndex < ArraySize(tradeLines) - 1) {
            currentLineIndex++;
            TradeLine line = tradeLines[currentLineIndex];
            ChartSetSymbolPeriod(0, Symbol(), PERIOD_H1);
            ChartNavigate(0, CHART_END, -(TimeCurrent() - line.startTime) / PeriodSeconds(PERIOD_H1));
         }
      }
      else if(StringFind(sparam, "btnReverse") >= 0) {
         for(int i = 0; i < 7; i++) {
            if(sparam == "btnReverse" + Calc2Dialog.m_chkTimeframes[i].Text()) {
               Calc2Dialog.m_reverseLogic[i] = !Calc2Dialog.m_reverseLogic[i];
               Calc2Dialog.m_btnReverse[i].ColorBackground(Calc2Dialog.m_reverseLogic[i] ? clrRed : clrLightGray);
            }
         }
      }
      else if(sparam == "btnVariant1" || sparam == "btnVariant2" || sparam == "btnVariant3" || sparam == "btnVariant4" || sparam == "btnVariant5") {
         Calc2Dialog.m_btnVariant1.ColorBackground(clrLightGray);
         Calc2Dialog.m_btnVariant2.ColorBackground(clrLightGray);
         Calc2Dialog.m_btnVariant3.ColorBackground(clrLightGray);
         Calc2Dialog.m_btnVariant4.ColorBackground(clrLightGray);
         Calc2Dialog.m_btnVariant5.ColorBackground(clrLightGray);
         if(sparam == "btnVariant1") Calc2Dialog.m_btnVariant1.ColorBackground(clrGreen);
         if(sparam == "btnVariant2") Calc2Dialog.m_btnVariant2.ColorBackground(clrGreen);
         if(sparam == "btnVariant3") Calc2Dialog.m_btnVariant3.ColorBackground(clrGreen);
         if(sparam == "btnVariant4") Calc2Dialog.m_btnVariant4.ColorBackground(clrGreen);
         if(sparam == "btnVariant5") Calc2Dialog.m_btnVariant5.ColorBackground(clrGreen);
      }
   }
   else if(id == CHARTEVENT_OBJECT_CHANGE) {
      for(int i = 0; i < 7; i++) {
         string prefix = "Run4L_" + IntegerToString(i) + "_";
         if(ObjectGetInteger(0, prefix + "op", OBJPROP_SELECTED)) {
            double newOpPrice = ObjectGetDouble(0, prefix + "op", OBJPROP_PRICE);
            double dev = g_dev;
            ObjectSetDouble(0, prefix + "BH1", OBJPROP_PRICE, newOpPrice + dev);
            ObjectSetDouble(0, prefix + "SH2", OBJPROP_PRICE, newOpPrice - dev);
            ObjectSetDouble(0, prefix + "SH3p", OBJPROP_PRICE, newOpPrice + 3 * dev);
            ObjectSetDouble(0, prefix + "BH4p", OBJPROP_PRICE, newOpPrice - 3 * dev);
         }
         prefix = "Live4L_" + IntegerToString(i) + "_";
         if(ObjectGetInteger(0, prefix + "op", OBJPROP_SELECTED)) {
            double newOpPrice = ObjectGetDouble(0, prefix + "op", OBJPROP_PRICE);
            double dev = g_dev;
            ObjectSetDouble(0, prefix + "BH1", OBJPROP_PRICE, newOpPrice + dev);
            ObjectSetDouble(0, prefix + "SH2", OBJPROP_PRICE, newOpPrice - dev);
            ObjectSetDouble(0, prefix + "SH3p", OBJPROP_PRICE, newOpPrice + 3 * dev);
            ObjectSetDouble(0, prefix + "BH4p", OBJPROP_PRICE, newOpPrice - 3 * dev);
         }
      }
   }
   else if(id == CHARTEVENT_CLICK && Calc2Dialog.m_btnVariant5.ColorBackground() == clrGreen) {
      // Ръчно задаване на линии
      double price = ChartPriceOnDropped();
      datetime time = ChartTimeOnDropped();
      string prefix = "Manual_" + IntegerToString(TimeCurrent()) + "_";
      
      ObjectCreate(0, prefix + "line", OBJ_HLINE, 0, 0, price);
      ObjectSetInteger(0, prefix + "line", OBJPROP_COLOR, clrYellow);
      ObjectSetInteger(0, prefix + "line", OBJPROP_STYLE, STYLE_SOLID);
      
      // Добавяне към историята
      ArrayResize(tradeLines, ArraySize(tradeLines) + 1);
      tradeLines[ArraySize(tradeLines) - 1].opPrice = price;
      tradeLines[ArraySize(tradeLines) - 1].tpPrice = price + g_dev;
      tradeLines[ArraySize(tradeLines) - 1].slPrice = price - g_dev;
      tradeLines[ArraySize(tradeLines) - 1].startTime = time;
      tradeLines[ArraySize(tradeLines) - 1].endTime = time + PeriodSeconds(PERIOD_H1) * 100;
      tradeLines[ArraySize(tradeLines) - 1].prefix = prefix;
      currentLineIndex = ArraySize(tradeLines) - 1;
   }
}

//  край на файла  ///ендГРОК
