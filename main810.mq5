//+------------------------------------------------------------------+
//|                                                  MainStrategy803.mq5  |
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

#include "deff2.mqh" //  15
/*
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
input bool reverse = false; // 31


struct TradeLine { // 35
   double opPriceB, opPriceS; // 36
   double tpPriceB, tpPriceS; // 37
   double slPriceB, slPriceS; // 38
   double BH1, SH2, SH3p, BH4p; // 39
   datetime startTime, endTime; // 40
   string prefix; // 41
   double opPrice;
   double tpPrice;
   double slPrice;
   
}; // 42


TradeLine tradeLines[];
int currentLineIndex = -1;*/

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


 void NavigateToTrade(int direction);
 void RunTest2() ;
 double CalculateDev(ENUM_TIMEFRAMES tf);
 ENUM_TIMEFRAMES GetSelectedTimeframe();
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
void OnTick2222()
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
   
   if(sparam == "btnRunTest") {
      Calc2Dialog.RunTest2();
      return;
   }


   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sparam == "btnCalc2") Calc2Dialog.Show();
      else if(sparam == "btnPrev") Calc2Dialog.NavigateToTrade(-1);
      else if(sparam == "btnNext") Calc2Dialog.NavigateToTrade(1);
      else if(sparam == "btnClean") ClearAllLines();
      ChartRedraw();
   }


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

void ClearAllLines()
{
   int total = ObjectsTotal(0, 0, -1);
   for(int i = total - 1; i >= 0; i--) {
      string name = ObjectName(0, i);
      if(StringFind(name, "Trend_") == 0 || StringFind(name, "YellowLine_") == 0 || 
         StringFind(name, "Line") == 0 || StringFind(name, "Arrow") == 0 || 
         StringFind(name, "Rect_") == 0 || StringFind(name, "Marker_") == 0 || 
         StringFind(name, "Action_") == 0) {
         ObjectDelete(0, name);
      }
      if(StringFind(name, "Trade_Entry2_") == 0 || 
         StringFind(name, "Trade_EntryT2_") == 0 || 
         StringFind(name, "Trade_BuyT2_") == 0 || 
         StringFind(name, "Trade_SellT2_") == 0 || 
         StringFind(name, "HedgeLine2_") == 0 ||
         StringFind(name, "Trade_Entry_") == 0 || 
         StringFind(name, "Trade_EntryT_") == 0 || 
         StringFind(name, "Trade_BuyT_") == 0 || 
         StringFind(name, "Trade_SellT_") == 0) {
         ObjectDelete(0, name);
      }
   }
   ChartRedraw();
}



void CCalculator2Dialog::RunTest2()
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

      string entryName = "Trade_Entry2_" + TimeToString(entryDt);
      ObjectCreate(0, entryName, OBJ_VLINE, 0, entryDt, 0);
      ObjectSetInteger(0, entryName, OBJPROP_COLOR, clrYellow);
      ObjectSetInteger(0, entryName, OBJPROP_STYLE, STYLE_DOT);

      int size = ArraySize(m_tradeTimes);
      ArrayResize(m_tradeTimes, size + 1);
      m_tradeTimes[size] = entryDt;

      long m1StartBar = iBarShift(_Symbol, PERIOD_M1, entryDt);
      if(m1StartBar < 0) continue;

      bool hitBuy = false, hitSell = false, hitProfit = false, hitLoss = false;
      datetime endTimeM1 = entryDt;

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

         // Добавяне на 4 линии в хедж режима като OBJ_TREND
         double levels[4] = {buyLevel, profitLevelBuy, lossLevelBuy, sellLevel};
         for(int i = 0; i < 4; i++) {
            string hName = "HedgeLine2_" + IntegerToString(i + 1) + "_" + TimeToString(entryDt);
            ObjectCreate(0, hName, OBJ_TREND, 0, entryDt, levels[i], endTimeM1, levels[i]);
            if(i == 0 || i == 1) ObjectSetInteger(0, hName, OBJPROP_COLOR, clrAqua);
            else ObjectSetInteger(0, hName, OBJPROP_COLOR, clrAqua);
            ObjectSetInteger(0, hName, OBJPROP_RAY, false);
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
         datetime endOfDay = entryDt + 86400;
         long endBar = iBarShift(_Symbol, PERIOD_M1, endOfDay, true);
         if(endBar >= 0) {
            endTimeM1 = iTime(_Symbol, PERIOD_M1, (int)endBar);
         } else {
            endTimeM1 = endOfDay;
         }
      }

      // Жълта линия от entryDt до endTimeM1
      string entryTrend = "Trade_EntryT2_" + TimeToString(entryDt);
      ObjectCreate(0, entryTrend, OBJ_TREND, 0, entryDt, close, endTimeM1, close);
      ObjectSetInteger(0, entryTrend, OBJPROP_COLOR, clrYellow);
      ObjectSetInteger(0, entryTrend, OBJPROP_RAY, false);

      // Аква линия от entryDt до endTimeM1
      string buyTrend = "Trade_BuyT2_" + TimeToString(entryDt);
      ObjectCreate(0, buyTrend, OBJ_TREND, 0, entryDt, buyLevel, endTimeM1, buyLevel);
      ObjectSetInteger(0, buyTrend, OBJPROP_COLOR, clrAqua);
      ObjectSetInteger(0, buyTrend, OBJPROP_RAY, false);

      // Червена линия от entryDt до endTimeM1
      string sellTrend = "Trade_SellT2_" + TimeToString(entryDt);
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
   Print("Test2 completed: DEV=", DoubleToString(dev, 2), ", Profits=", profitCount, ", Losses=", lossCount,
         ", Win Rate=", DoubleToString(winRate, 2), "%, Avg Profit=", DoubleToString(avgProfit, 2),
         ", Avg Loss=", DoubleToString(avgLoss, 2), ", Base Sum=", baseSum, " USD, Total Sum=", totalSum, " USD");
   m_currentTradeIndex = -1;
}


ENUM_TIMEFRAMES CCalculator2Dialog::GetSelectedTimeframe()
{
   ENUM_TIMEFRAMES tfs[] = {PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_H1, PERIOD_H4, PERIOD_D1};
   for(int i = 0; i < 6; i++) if(m_chkTimeframes[i].Checked()) return tfs[i];
   return PERIOD_H1;
}


/*
/////************************************************************************************


void RunMod3L(double bid) { // 117
   static bool isProcessed = false; // 118
   static datetime lastTime; // 119
   datetime time = TimeCurrent(); // 120

   if(lastTime == time) return; // 121
   lastTime = time; // 122

   if(!isProcessed) { // 123
      double opPrice = bid; // 124
      double tpPrice = reverse ? opPrice - g_dev : opPrice + g_dev; // 125
      double slPrice = reverse ? opPrice + g_dev : opPrice - g_dev; // 126
      string prefix = "Run3L_" + IntegerToString(time); // 127

      CreateLine(prefix + "_op", opPrice, clrYellow, 0, 0); // 128
      CreateLine(prefix + "_tp", tpPrice, clrLime, 0, 0); // 129
      CreateLine(prefix + "_sl", slPrice, clrRed, 0, 0); // 130

      int size = ArraySize(tradeLines); // 131
      ArrayResize(tradeLines, size + 1); // 132
      tradeLines[size].opPriceB = opPrice; // 133
      tradeLines[size].tpPriceB = tpPrice; // 134
      tradeLines[size].slPriceB = slPrice; // 135
      tradeLines[size].startTime = time; // 136
      tradeLines[size].prefix = prefix; // 137

      isProcessed = true; // 138

      MqlRates rates[]; // 139
      ArraySetAsSeries(rates, true); // 140
      int copied = CopyRates(g_symb, PERIOD_H1, 0, 100, rates); // 141
      if(copied <= 0) return; // 142

      for(int i = 0; i < copied; i++) { // 143
         double high = rates[i].high; // 144
         double low = rates[i].low; // 145

         if(high >= tpPrice) { // 146
            tradeLines[size].endTime = rates[i].time; // 147
            profitCount++; // 148
            totalSum += g_dev; // 149
            break; // 150
         } // 151
         else if(low <= slPrice) { // 152
            tradeLines[size].endTime = rates[i].time; // 153
            lossCount++; // 154
            totalSum -= g_dev; // 155
            break; // 156
         } // 157
      } // 158

      if(tradeLines[size].endTime != 0) { // 159
         CreateTrendLine(prefix + "_op_trend", opPrice, tradeLines[size].startTime, tradeLines[size].endTime, clrYellow); // 160
         CreateTrendLine(prefix + "_tp_trend", tpPrice, tradeLines[size].startTime, tradeLines[size].endTime, clrLime); // 161
         CreateTrendLine(prefix + "_sl_trend", slPrice, tradeLines[size].startTime, tradeLines[size].endTime, clrRed); // 162
         ObjectDelete(0, prefix + "_op"); // 163
         ObjectDelete(0, prefix + "_tp"); // 164
         ObjectDelete(0, prefix + "_sl"); // 165
         isProcessed = false; // 166
      } // 167
   } // 168
} // 169

void RunMod4L(double bid) { // 170
   static bool isProcessed = false; // 171
   static datetime lastTime; // 172
   datetime time = TimeCurrent(); // 173

   if(lastTime == time) return; // 174
   lastTime = time; // 175

   if(!isProcessed) { // 176
      double opPrice = bid; // 177
      double BH1 = reverse ? opPrice - g_dev : opPrice + g_dev; // 178
      double SH2 = reverse ? opPrice + g_dev : opPrice - g_dev; // 179
      double SH3p = reverse ? opPrice - 2 * g_dev : opPrice + 2 * g_dev; // 180
      double BH4p = reverse ? opPrice + 2 * g_dev : opPrice - 2 * g_dev; // 181
      string prefix = "Run4L_" + IntegerToString(time); // 182

      CreateLine(prefix + "_op", opPrice, clrYellow, 0, 0); // 183
      CreateLine(prefix + "_BH1", BH1, clrLime, 0, 0); // 184
      CreateLine(prefix + "_SH2", SH2, clrRed, 0, 0); // 185
      CreateLine(prefix + "_SH3p", SH3p, clrRed, 0, 0); // 186
      CreateLine(prefix + "_BH4p", BH4p, clrLime, 0, 0); // 187

      int size = ArraySize(tradeLines); // 188
      ArrayResize(tradeLines, size + 1); // 189
      tradeLines[size].opPriceB = opPrice; // 190
      tradeLines[size].BH1 = BH1; // 191
      tradeLines[size].SH2 = SH2; // 192
      tradeLines[size].SH3p = SH3p; // 193
      tradeLines[size].BH4p = BH4p; // 194
      tradeLines[size].startTime = time; // 195
      tradeLines[size].prefix = prefix; // 196

      isProcessed = true; // 197

      MqlRates rates[]; // 198
      ArraySetAsSeries(rates, true); // 199
      int copied = CopyRates(g_symb, PERIOD_H1, 0, 100, rates); // 200
      if(copied <= 0) return; // 201

      int hitCount = 0; // 202
      for(int i = 0; i < copied && hitCount < 2; i++) { // 203
         double high = rates[i].high; // 204
         double low = rates[i].low; // 205

         if(high >= BH1 && hitCount == 0) { // 206
            hitCount++; // 207
            totalSum += g_dev; // 208
         } // 209
         else if(low <= SH2 && hitCount == 0) { // 210
            hitCount++; // 211
            totalSum -= g_dev; // 212
         } // 213
         else if(high >= SH3p && hitCount == 1) { // 214
            hitCount++; // 215
            totalSum += 2 * g_dev; // 216
            tradeLines[size].endTime = rates[i].time; // 217
            profitCount++; // 218
            break; // 219
         } // 220
         else if(low <= BH4p && hitCount == 1) { // 221
            hitCount++; // 222
            totalSum -= 2 * g_dev; // 223
            tradeLines[size].endTime = rates[i].time; // 224
            lossCount++; // 225
            break; // 226
         } // 227
      } // 228

      if(tradeLines[size].endTime != 0) { // 229
         CreateTrendLine(prefix + "_op_trend", opPrice, tradeLines[size].startTime, tradeLines[size].endTime, clrYellow); // 230
         CreateTrendLine(prefix + "_BH1_trend", BH1, tradeLines[size].startTime, tradeLines[size].endTime, clrLime); // 231
         CreateTrendLine(prefix + "_SH2_trend", SH2, tradeLines[size].startTime, tradeLines[size].endTime, clrRed); // 232
         CreateTrendLine(prefix + "_SH3p_trend", SH3p, tradeLines[size].startTime, tradeLines[size].endTime, clrRed); // 233
         CreateTrendLine(prefix + "_BH4p_trend", BH4p, tradeLines[size].startTime, tradeLines[size].endTime, clrLime); // 234
         ObjectDelete(0, prefix + "_op"); // 235
         ObjectDelete(0, prefix + "_BH1"); // 236
         ObjectDelete(0, prefix + "_SH2"); // 237
         ObjectDelete(0, prefix + "_SH3p"); // 238
         ObjectDelete(0, prefix + "_BH4p"); // 239
         isProcessed = false; // 240
      } // 241
   } // 242
} // 243

void LiveMod3L(double bid) { // 244
   static bool isProcessed = false; // 245
   static datetime lastTime; // 246
   datetime time = TimeCurrent(); // 247

   if(lastTime == time) return; // 248
   lastTime = time; // 249

   if(!isProcessed) { // 250
      double opPrice = bid; // 251
      double tpPrice = reverse ? opPrice - g_dev : opPrice + g_dev; // 252
      double slPrice = reverse ? opPrice + g_dev : opPrice - g_dev; // 253
      string prefix = "Live3L_" + IntegerToString(time); // 254

      CreateLine(prefix + "_op", opPrice, clrYellow, 0, 0); // 255
      CreateLine(prefix + "_tp", tpPrice, clrLime, 0, 0); // 256
      CreateLine(prefix + "_sl", slPrice, clrRed, 0, 0); // 257

      int size = ArraySize(tradeLines); // 258
      ArrayResize(tradeLines, size + 1); // 259
      tradeLines[size].opPriceB = opPrice; // 260
      tradeLines[size].tpPriceB = tpPrice; // 261
      tradeLines[size].slPriceB = slPrice; // 262
      tradeLines[size].startTime = time; // 263
      tradeLines[size].prefix = prefix; // 264

      if(PositionSelect(g_symb) == false) { // 265
         MqlTradeRequest request = {0}; // 266
         MqlTradeResult result = {0}; // 267
         request.action = TRADE_ACTION_DEAL; // 268
         request.symbol = g_symb; // 269
         request.volume = g_lot; // 270
         request.type = reverse ? ORDER_TYPE_SELL : ORDER_TYPE_BUY; // 271
         request.price = opPrice; // 272
         request.sl = slPrice; // 273
         request.tp = tpPrice; // 274
         OrderSend(request, result); // 275
      } // 276

      isProcessed = true; // 277
   } // 278

   if(isProcessed) { // 279
      int size = ArraySize(tradeLines) - 1; // 280
      if(bid >= tradeLines[size].tpPriceB || bid <= tradeLines[size].slPriceB) { // 281
         tradeLines[size].endTime = TimeCurrent(); // 282
         CreateTrendLine(tradeLines[size].prefix + "_op_trend", tradeLines[size].opPriceB, tradeLines[size].startTime, tradeLines[size].endTime, clrYellow); // 283
         CreateTrendLine(tradeLines[size].prefix + "_tp_trend", tradeLines[size].tpPriceB, tradeLines[size].startTime, tradeLines[size].endTime, clrLime); // 284
         CreateTrendLine(tradeLines[size].prefix + "_sl_trend", tradeLines[size].slPriceB, tradeLines[size].startTime, tradeLines[size].endTime, clrRed); // 285
         ObjectDelete(0, tradeLines[size].prefix + "_op"); // 286
         ObjectDelete(0, prefix + "_tp"); // 287
         ObjectDelete(0, tradeLines[size].prefix + "_sl"); // 288
         double profit = PositionGetDouble(POSITION_PROFIT); // 289
         UpdateProfitLabel(profit); // 290
         isProcessed = false; // 291
      } // 292
   } // 293
} // 294

void LiveMod4L(double bid) { // 295
   static bool isProcessed = false; // 296
   static datetime lastTime; // 297
   static int hitCount = 0; // 298
   datetime time = TimeCurrent(); // 299

   if(lastTime == time) return; // 300
   lastTime = time; // 301

   if(!isProcessed) { // 302
      double opPrice = bid; // 303
      double BH1 = reverse ? opPrice - g_dev : opPrice + g_dev; // 304
      double SH2 = reverse ? opPrice + g_dev : opPrice - g_dev; // 305
      double SH3p = reverse ? opPrice - 2 * g_dev : opPrice + 2 * g_dev; // 306
      double BH4p = reverse ? opPrice + 2 * g_dev : opPrice - 2 * g_dev; // 307
      string prefix = "Live4L_" + IntegerToString(time); // 308

      CreateLine(prefix + "_op", opPrice, clrYellow, 0, 0); // 309
      CreateLine(prefix + "_BH1", BH1, clrLime, 0, 0); // 310
      CreateLine(prefix + "_SH2", SH2, clrRed, 0, 0); // 311
      CreateLine(prefix + "_SH3p", SH3p, clrRed, 0, 0); // 312
      CreateLine(prefix + "_BH4p", BH4p, clrLime, 0, 0); // 313

      int size = ArraySize(tradeLines); // 314
      ArrayResize(tradeLines, size + 1); // 315
      tradeLines[size].opPriceB = opPrice; // 316
      tradeLines[size].BH1 = BH1; // 317
      tradeLines[size].SH2 = SH2; // 318
      tradeLines[size].SH3p = SH3p; // 319
      tradeLines[size].BH4p = BH4p; // 320
      tradeLines[size].startTime = time; // 321
      tradeLines[size].prefix = prefix; // 322

      isProcessed = true; // 323
      hitCount = 0; // 324
   } // 325

   if(isProcessed) { // 326
      int size = ArraySize(tradeLines) - 1; // 327
      int totalPositions = 0; // 328
      for(int i = 0; i < PositionsTotal(); i++) { // 329
         ulong ticket = PositionGetTicket(i); // 330
         if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == g_symb) { // 331
            totalPositions++; // 332
         } // 333
      } // 334

      if(bid >= tradeLines[size].BH1 && hitCount == 0 && totalPositions < 2) { // 335
         MqlTradeRequest request = {0}; // 336
         MqlTradeResult result = {0}; // 337
         request.action = TRADE_ACTION_DEAL; // 338
         request.symbol = g_symb; // 339
         request.volume = g_lot; // 340
         request.type = ORDER_TYPE_BUY; // 341
         request.price = bid; // 342
         OrderSend(request, result); // 343
         hitCount++; // 344
      } // 345
      else if(bid <= tradeLines[size].SH2 && hitCount == 0 && totalPositions < 2) { // 346
         MqlTradeRequest request = {0}; // 347
         MqlTradeResult result = {0}; // 348
         request.action = TRADE_ACTION_DEAL; // 349
         request.symbol = g_symb; // 350
         request.volume = g_lot; // 351
         request.type = ORDER_TYPE_SELL; // 352
         request.price = bid; // 353
         OrderSend(request, result); // 354
         hitCount++; // 355
      } // 356
      else if(bid >= tradeLines[size].SH3p && hitCount == 1 && totalPositions < 2) { // 357
         MqlTradeRequest request = {0}; // 358
         MqlTradeResult result = {0}; // 359
         request.action = TRADE_ACTION_DEAL; // 360
         request.symbol = g_symb; // 361
         request.volume = g_lot; // 362
         request.type = ORDER_TYPE_SELL; // 363
         request.price = bid; // 364
         OrderSend(request, result); // 365
         hitCount++; // 366
      } // 367
      else if(bid <= tradeLines[size].BH4p && hitCount == 1 && totalPositions < 2) { // 368
         MqlTradeRequest request = {0}; // 369
         MqlTradeResult result = {0}; // 370
         request.action = TRADE_ACTION_DEAL; // 371
         request.symbol = g_symb; // 372
         request.volume = g_lot; // 373
         request.type = ORDER_TYPE_BUY; // 374
         request.price = bid; // 375
         OrderSend(request, result); // 376
         hitCount++; // 377
      } // 378

      if(hitCount >= 2) { // 379
         tradeLines[size].endTime = TimeCurrent(); // 380
         CreateTrendLine(tradeLines[size].prefix + "_op_trend", tradeLines[size].opPriceB, tradeLines[size].startTime, tradeLines[size].endTime, clrYellow); // 381
         CreateTrendLine(tradeLines[size].prefix + "_BH1_trend", tradeLines[size].BH1, tradeLines[size].startTime, tradeLines[size].endTime, clrLime); // 382
         CreateTrendLine(tradeLines[size].prefix + "_SH2_trend", tradeLines[size].SH2, tradeLines[size].startTime, tradeLines[size].endTime, clrRed); // 383
         CreateTrendLine(tradeLines[size].prefix + "_SH3p_trend", tradeLines[size].SH3p, tradeLines[size].startTime, tradeLines[size].endTime, clrRed); // 384
         CreateTrendLine(tradeLines[size].prefix + "_BH4p_trend", tradeLines[size].BH4p, tradeLines[size].startTime, tradeLines[size].endTime, clrLime); // 385
         ObjectDelete(0, tradeLines[size].prefix + "_op"); // 386
         ObjectDelete(0, tradeLines[size].prefix + "_BH1"); // 387
         ObjectDelete(0, tradeLines[size].prefix + "_SH2"); // 388
         ObjectDelete(0, tradeLines[size].prefix + "_SH3p"); // 389
         ObjectDelete(0, tradeLines[size].prefix + "_BH4p"); // 390
         double profit = 0; // 391
         for(int i = 0; i < PositionsTotal(); i++) { // 392
            ulong ticket = PositionGetTicket(i); // 393
            if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == g_symb) { // 394
               profit += PositionGetDouble(POSITION_PROFIT); // 395
            } // 396
         } // 397
         UpdateProfitLabel(profit); // 398
         isProcessed = false; // 399
         hitCount = 0; // 400
               } // 401
   } // 402
} // 403

void LiveMod5L(double bid) { // 404
   static bool isProcessed = false; // 405
   static datetime lastTime; // 406
   datetime time = TimeCurrent(); // 407

   if(lastTime == time) return; // 408
   lastTime = time; // 409

   if(!isProcessed) { // 410
      double opPrice = bid; // 411
      double r1 = g_r1 * g_dev; // 412
      double r2 = g_r2 * g_dev; // 413
      double tpPrice = reverse ? opPrice - r1 : opPrice + r1; // 414
      double slPrice = reverse ? opPrice + r2 : opPrice - r2; // 415
      string prefix = "Live5L_" + IntegerToString(time); // 416

      CreateLine(prefix + "_op", opPrice, clrYellow, 0, 0); // 417
      CreateLine(prefix + "_tp", tpPrice, clrLime, 0, 0); // 418
      CreateLine(prefix + "_sl", slPrice, clrRed, 0, 0); // 419

      int size = ArraySize(tradeLines); // 420
      ArrayResize(tradeLines, size + 1); // 421
      tradeLines[size].opPriceB = opPrice; // 422
      tradeLines[size].tpPriceB = tpPrice; // 423
      tradeLines[size].slPriceB = slPrice; // 424
      tradeLines[size].startTime = time; // 425
      tradeLines[size].prefix = prefix; // 426

      if(PositionSelect(g_symb) == false) { // 427
         MqlTradeRequest request = {0}; // 428
         MqlTradeResult result = {0}; // 429
         request.action = TRADE_ACTION_DEAL; // 430
         request.symbol = g_symb; // 431
         request.volume = g_lot; // 432
         request.type = reverse ? ORDER_TYPE_SELL : ORDER_TYPE_BUY; // 433
         request.price = opPrice; // 434
         request.sl = slPrice; // 435
         request.tp = tpPrice; // 436
         OrderSend(request, result); // 437
      } // 438

      isProcessed = true; // 439
   } // 440

   if(isProcessed) { // 441
      int size = ArraySize(tradeLines) - 1; // 442
      if(bid >= tradeLines[size].tpPriceB || bid <= tradeLines[size].slPriceB) { // 443
         tradeLines[size].endTime = TimeCurrent(); // 444
         CreateTrendLine(tradeLines[size].prefix + "_op_trend", tradeLines[size].opPriceB, tradeLines[size].startTime, tradeLines[size].endTime, clrYellow); // 445
         CreateTrendLine(tradeLines[size].prefix + "_tp_trend", tradeLines[size].tpPriceB, tradeLines[size].startTime, tradeLines[size].endTime, clrLime); // 446
         CreateTrendLine(tradeLines[size].prefix + "_sl_trend", tradeLines[size].slPriceB, tradeLines[size].startTime, tradeLines[size].endTime, clrRed); // 447
         ObjectDelete(0, tradeLines[size].prefix + "_op"); // 448
         ObjectDelete(0, tradeLines[size].prefix + "_tp"); // 449
         ObjectDelete(0, tradeLines[size].prefix + "_sl"); // 450
         double profit = PositionGetDouble(POSITION_PROFIT); // 451
         UpdateProfitLabel(profit); // 452
         isProcessed = false; // 453
      } // 454
   } // 455
} // 456



void CreateButton(string name, int x, int y, int width, int height, string text, color clr) { // 47
   ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0); // 48
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x); // 49
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y); // 50
   ObjectSetInteger(0, name, OBJPROP_XSIZE, width); // 51
   ObjectSetInteger(0, name, OBJPROP_YSIZE, height); // 52
   ObjectSetString(0, name, OBJPROP_TEXT, text); // 53
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr); // 54
} // 55

void CreateLabel(string name, int x, int y, string text, color clr) { // 56
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0); // 57
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x); // 58
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y); // 59
   ObjectSetString(0, name, OBJPROP_TEXT, text); // 60
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr); // 61
} // 62

void CreateLine(string name, double price, color clr, datetime start, datetime end) { // 63
   ObjectCreate(0, name, OBJ_HLINE, 0, 0, price); // 64
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr); // 65
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID); // 66
} // 67

void CreateTrendLine(string name, double price, datetime start, datetime end, color clr) { // 68
   ObjectCreate(0, name, OBJ_TREND, 0, start, price, end, price); // 69
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr); // 70
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID); // 71
} // 72


void UpdateLines() { // 509
   int total = ArraySize(tradeLines); // 510
   if(total == 0) return; // 511

   int index = currentLineIndex; // 512
   if(index >= total) index = total - 1; // 513

   string prefix = tradeLines[index].prefix; // 514
   ObjectsDeleteAll(0, prefix + "_trend"); // 515

   CreateTrendLine(prefix + "_op_trend", tradeLines[index].opPriceB, tradeLines[index].startTime, tradeLines[index].endTime, clrYellow); // 516
   if(tradeLines[index].tpPriceB != 0) CreateTrendLine(prefix + "_tp_trend", tradeLines[index].tpPriceB, tradeLines[index].startTime, tradeLines[index].endTime, clrLime); // 517
   if(tradeLines[index].slPriceB != 0) CreateTrendLine(prefix + "_sl_trend", tradeLines[index].slPriceB, tradeLines[index].startTime, tradeLines[index].endTime, clrRed); // 518
   if(tradeLines[index].BH1 != 0) CreateTrendLine(prefix + "_BH1_trend", tradeLines[index].BH1, tradeLines[index].startTime, tradeLines[index].endTime, clrLime); // 519
   if(tradeLines[index].SH2 != 0) CreateTrendLine(prefix + "_SH2_trend", tradeLines[index].SH2, tradeLines[index].startTime, tradeLines[index].endTime, clrRed); // 520
   if(tradeLines[index].SH3p != 0) CreateTrendLine(prefix + "_SH3p_trend", tradeLines[index].SH3p, tradeLines[index].startTime, tradeLines[index].endTime, clrRed); // 521
   if(tradeLines[index].BH4p != 0) CreateTrendLine(prefix + "_BH4p_trend", tradeLines[index].BH4p, tradeLines[index].startTime, tradeLines[index].endTime, clrLime); // 522

   double profit = 0; // 523
   for(int i = 0; i < PositionsTotal(); i++) { // 524
      ulong ticket = PositionGetTicket(i); // 525
      if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == g_symb) { // 526
         profit += PositionGetDouble(POSITION_PROFIT); // 527
      } // 528
   } // 529
   UpdateProfitLabel(profit); // 530

   ObjectSetString(0, "lblDev", OBJPROP_TEXT, "DEV: " + DoubleToString(devValues[currentLineIndex % 5], 1)); // 531
} // 532


void OnTick() { // 99
   double bid = SymbolInfoDouble(g_symb, SYMBOL_BID); // 100

   if(btnVariant3) { // 101
      RunMod3L(bid); // 102
   } // 103
   else if(btnVariant4) { // 104
      RunMod4L(bid); // 105
   } // 106
   else if(btnVariant1) { // 107
      LiveMod3L(bid); // 108
   } // 109
   else if(btnVariant2) { // 110
      LiveMod4L(bid); // 111
   } // 112
   else if(btnVariant5) { // 113
      LiveMod5L(bid); // 114
   } // 115
} // 116

void RunMod3L(double bid) { // 117
   static bool isProcessed = false; // 118
   static datetime lastTime; // 119
   datetime time = TimeCurrent(); // 120

   if(lastTime == time) return; // 121
   lastTime = time; // 122

   if(!isProcessed) { // 123
      double opPrice = bid; // 124
      double tpPrice = reverse ? opPrice - g_dev : opPrice + g_dev; // 125
      double slPrice = reverse ? opPrice + g_dev : opPrice - g_dev; // 126
      string prefix = "Run3L_" + IntegerToString(time); // 127

      CreateLine(prefix + "_op", opPrice, clrYellow, 0, 0); // 128
      CreateLine(prefix + "_tp", tpPrice, clrLime, 0, 0); // 129
      CreateLine(prefix + "_sl", slPrice, clrRed, 0, 0); // 130

      int size = ArraySize(tradeLines); // 131
      ArrayResize(tradeLines, size + 1); // 132
      tradeLines[size].opPriceB = opPrice; // 133
      tradeLines[size].tpPriceB = tpPrice; // 134
      tradeLines[size].slPriceB = slPrice; // 135
      tradeLines[size].startTime = time; // 136
      tradeLines[size].prefix = prefix; // 137

      isProcessed = true; // 138

      MqlRates rates[]; // 139
      ArraySetAsSeries(rates, true); // 140
      int copied = CopyRates(g_symb, PERIOD_H1, 0, 100, rates); // 141
      if(copied <= 0) return; // 142

      for(int i = 0; i < copied; i++) { // 143
         double high = rates[i].high; // 144
         double low = rates[i].low; // 145

         if(high >= tpPrice) { // 146
            tradeLines[size].endTime = rates[i].time; // 147
            profitCount++; // 148
            totalSum += g_dev; // 149
            break; // 150
         } // 151
         else if(low <= slPrice) { // 152
            tradeLines[size].endTime = rates[i].time; // 153
            lossCount++; // 154
            totalSum -= g_dev; // 155
            break; // 156
         } // 157
      } // 158

      if(tradeLines[size].endTime != 0) { // 159
         CreateTrendLine(prefix + "_op_trend", opPrice, tradeLines[size].startTime, tradeLines[size].endTime, clrYellow); // 160
         CreateTrendLine(prefix + "_tp_trend", tpPrice, tradeLines[size].startTime, tradeLines[size].endTime, clrLime); // 161
         CreateTrendLine(prefix + "_sl_trend", slPrice, tradeLines[size].startTime, tradeLines[size].endTime, clrRed); // 162
         ObjectDelete(0, prefix + "_op"); // 163
         ObjectDelete(0, prefix + "_tp"); // 164
         ObjectDelete(0, prefix + "_sl"); // 165
         isProcessed = false; // 166
      } // 167
   } // 168
} // 169


///край