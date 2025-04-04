﻿


//+------------------------------------------------------------------+ // 1
//|                                                  w2.mqh          | // 2
//|                        Copyright 2024, MetaQuotes Software Corp. | // 3
//|                                             https://www.mql5.com | // 4
//+------------------------------------------------------------------+ // 5
#property copyright "Copyright 2024, MetaQuotes Software Corp." // 6
#property link      "https://www.mql5.com" // 7
#property version   "1.00" // 8
#property strict // 9

#include <Controls\Dialog.mqh> // 10
#include <Controls\Button.mqh> // 11
#include <Controls\Label.mqh> // 12
#include <Controls\Edit.mqh> // 13
#include <Controls\CheckBox.mqh> // 14
#include <Trade\Trade.mqh> // 15

#include "deff2.mqh" //  15

//#include <ChartObjects\ChartObjects.mqh> // 16
//#include <Windows.mqh> // 17
/*
// Глобални променливи // 18
string g_entryHour = "09"; // 19
string g_entryMinute = "00"; // 20
double g_dev = 600.0; // Увеличена девиация за US30.c // 21
double g_r1 = 1.0; // 22
double g_r2 = 1.0; // 23
double g_lot = 0.10; // 24
long   g_period = 30; // 25
double g_multiplier = 0.0001; // 26
bool   g_liveMode = false; // 27
long magic =12345 ; 

input double input_g_dev = 600.0; // За да запазя входа // 28
input double input_g_lot = 0.1; // 29
input string input_g_symb = "US30.c"; // 30
input bool reverse = false; // 31
string g_symb = "" ;
int  AccountBalance =100000 ;
int AccountEquity = 100000 ;
int AdjustLeverage = 50;

bool btnVariant1, btnVariant2, btnVariant3, btnVariant4, btnVariant5; // 32
bool prevClicked, nextClicked; // 33
int currentLineIndex = 0; // 34

struct TradeLine { // 35
   double opPriceB, opPriceS; // 36
   double tpPriceB, tpPriceS; // 37
   double slPriceB, slPriceS; // 38
   double BH1, SH2, SH3p, BH4p; // 39
   datetime startTime, endTime; // 40
   string prefix; // 41
}; // 42

TradeLine tradeLines[]; // 43
int profitCount = 0, lossCount = 0; // 44
double totalSum = 0.0; // 45

double devValues[]; // 46   */

namespace w2 {

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

int OnInit() { // 73
   CreateButton("btnVariant1", 50, 50, 100, 30, "Variant 1", clrBlue); // 74
   CreateButton("btnVariant2", 160, 50, 100, 30, "Variant 2", clrBlue); // 75
   CreateButton("btnVariant3", 270, 50, 100, 30, "Variant 3", clrBlue); // 76
   CreateButton("btnVariant4", 380, 50, 100, 30, "Variant 4", clrBlue); // 77
   CreateButton("btnVariant5", 490, 50, 100, 30, "Variant 5", clrBlue); // 78
   CreateButton("btnPrev", 600, 50, 50, 30, "PREV", clrGray); // 79
   CreateButton("btnNext", 660, 50, 50, 30, "NEXT", clrGray); // 80

   CreateLabel("lblDev", 50, 90, "DEV: " + DoubleToString(g_dev, 1), clrWhite); // 81
   CreateLabel("lblProfit", 50, 110, "Profit: 0", clrYellow); // 82

   ArrayResize(devValues, 5); // 83
   devValues[0] = g_dev; // 84
   for(int i = 1; i < 5; i++) devValues[i] = g_dev; // 85

   return(INIT_SUCCEEDED); // 86
} // 87

void OnDeinit(const int reason) { // 88
   ObjectsDeleteAll(0, 0, -1); // 89
} // 90

void UpdateDevLabel() { // 91
   ObjectSetString(0, "lblDev", OBJPROP_TEXT, "DEV: " + DoubleToString(devValues[0], 1)); // 92
} // 93

void UpdateProfitLabel(double profit) { // 94
   color clr = profit > 0 ? clrAqua : (profit < 0 ? clrRed : clrYellow); // 95
   ObjectSetString(0, "lblProfit", OBJPROP_TEXT, "Profit: " + DoubleToString(profit, 1)); // 96
   ObjectSetInteger(0, "lblProfit", OBJPROP_COLOR, clr); // 97
} // 98

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
         MqlTradeRequest request = {}; // 266
         MqlTradeResult result = {}; // 267
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
         ObjectDelete(0, tradeLines[size].prefix + "_tp"); // 287
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
         MqlTradeRequest request = {}; // 336
         MqlTradeResult result = {}; // 337
         request.action = TRADE_ACTION_DEAL; // 338
         request.symbol = g_symb; // 339
         request.volume = g_lot; // 340
         request.type = ORDER_TYPE_BUY; // 341
         request.price = bid; // 342
         OrderSend(request, result); // 343
         hitCount++; // 344
      } // 345
      else if(bid <= tradeLines[size].SH2 && hitCount == 0 && totalPositions < 2) { // 346
         MqlTradeRequest request = {}; // 347
         MqlTradeResult result = {}; // 348
         request.action = TRADE_ACTION_DEAL; // 349
         request.symbol = g_symb; // 350
         request.volume = g_lot; // 351
         request.type = ORDER_TYPE_SELL; // 352
         request.price = bid; // 353
         OrderSend(request, result); // 354
         hitCount++; // 355
      } // 356
      else if(bid >= tradeLines[size].SH3p && hitCount == 1 && totalPositions < 2) { // 357
         MqlTradeRequest request = {}; // 358
         MqlTradeResult result = {}; // 359
         request.action = TRADE_ACTION_DEAL; // 360
         request.symbol = g_symb; // 361
         request.volume = g_lot; // 362
         request.type = ORDER_TYPE_SELL; // 363
         request.price = bid; // 364
         OrderSend(request, result); // 365
         hitCount++; // 366
      } // 367
      else if(bid <= tradeLines[size].BH4p && hitCount == 1 && totalPositions < 2) { // 368
         MqlTradeRequest request = {}; // 369
         MqlTradeResult result = {}; // 370
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
         MqlTradeRequest request = {}; // 428
         MqlTradeResult result = {}; // 429
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

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) { // 457
   if(id == CHARTEVENT_OBJECT_CLICK) { // 458
      if(sparam == "btnVariant1") { // 459
         btnVariant1 = true; // 460
         btnVariant2 = false; // 461
         btnVariant3 = false; // 462
         btnVariant4 = false; // 463
         btnVariant5 = false; // 464
         currentLineIndex = 0; // 465
      } // 466
      else if(sparam == "btnVariant2") { // 467
         btnVariant1 = false; // 468
         btnVariant2 = true; // 469
         btnVariant3 = false; // 470
         btnVariant4 = false; // 471
         btnVariant5 = false; // 472
         currentLineIndex = 0; // 473
      } // 474
      else if(sparam == "btnVariant3") { // 475
         btnVariant1 = false; // 476
         btnVariant2 = false; // 477
         btnVariant3 = true; // 478
         btnVariant4 = false; // 479
         btnVariant5 = false; // 480
         currentLineIndex = 0; // 481
      } // 482
      else if(sparam == "btnVariant4") { // 483
         btnVariant1 = false; // 484
         btnVariant2 = false; // 485
         btnVariant3 = false; // 486
         btnVariant4 = true; // 487
         btnVariant5 = false; // 488
         currentLineIndex = 0; // 489
      } // 490
      else if(sparam == "btnVariant5") { // 491
         btnVariant1 = false; // 492
         btnVariant2 = false; // 493
         btnVariant3 = false; // 494
         btnVariant4 = false; // 495
         btnVariant5 = true; // 496
         currentLineIndex = 0; // 497
      } // 498
      else if(sparam == "btnPrev") { // 499
         if(currentLineIndex > 0) currentLineIndex--; // 500
         UpdateLines(); // 501
      } // 502
      else if(sparam == "btnNext") { // 503
         if(currentLineIndex < ArraySize(tradeLines) - 1) currentLineIndex++; // 504
         UpdateLines(); // 505
      } // 506
   } // 507
} // 508

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



double CalculatePipValue(string symbol, double lotSize) { // 533
   double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE); // 534
   double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE); // 535
   return (tickValue / tickSize) * lotSize; // 536
} // 537 
/*
void AdjustTradeLevels(double &opPrice, double &tpPrice, double &slPrice) { // 538
   double point = SymbolInfoDouble(g_symb, SYMBOL_POINT); // 539
   double minLevel = SymbolInfoDouble(g_symb, MODE_STOPLEVEL) * point; // 540

   if(MathAbs(tpPrice - opPrice) < minLevel) { // 541
      tpPrice = opPrice + (reverse ? -minLevel : minLevel); // 542
   } // 543
   if(MathAbs(slPrice - opPrice) < minLevel) { // 544
      slPrice = opPrice + (reverse ? minLevel : -minLevel); // 545
   } // 546
} // 547*/

void SetTradeParameters() { // 548
   g_dev = devValues[currentLineIndex % 5]; // 549
   g_lot = input_g_lot; // 550
} // 551

void ResetTradeLines() { // 552
   ArrayResize(tradeLines, 0); // 553
   profitCount = 0; // 554
   lossCount = 0; // 555
   totalSum = 0.0; // 556
   UpdateProfitLabel(totalSum); // 557
} // 558

void SaveTradeData() { // 559
   int fileHandle = FileOpen("TradeData.csv", FILE_WRITE|FILE_CSV); // 560
   if(fileHandle != INVALID_HANDLE) { // 561
      FileWrite(fileHandle, "Time,OpPrice,TP,SL,Profit"); // 562
      for(int i = 0; i < ArraySize(tradeLines); i++) { // 563
         string timeStr = TimeToString(tradeLines[i].startTime); // 564
         double profit = 0; // 565
         for(int j = 0; j < PositionsTotal(); j++) { // 566
            ulong ticket = PositionGetTicket(j); // 567
            if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == g_symb) { // 568
               profit += PositionGetDouble(POSITION_PROFIT); // 569
            } // 570
         } // 571
         FileWrite(fileHandle, timeStr, DoubleToString(tradeLines[i].opPriceB, 5), DoubleToString(tradeLines[i].tpPriceB, 5), DoubleToString(tradeLines[i].slPriceB, 5), DoubleToString(profit, 2)); // 572
      } // 573
      FileClose(fileHandle); // 574
   } // 575
} // 576

void LoadTradeData() { // 577
   int fileHandle = FileOpen("TradeData.csv", FILE_READ|FILE_CSV); // 578
   if(fileHandle != INVALID_HANDLE) { // 579
      ResetTradeLines(); // 580
      while(!FileIsEnding(fileHandle)) { // 581
         string line[]; // 582
         string data = FileReadString(fileHandle); // 583
         StringSplit(data, ',', line); // 584
         if(ArraySize(line) >= 4) { // 585
            int size = ArraySize(tradeLines); // 586
            ArrayResize(tradeLines, size + 1); // 587
            tradeLines[size].startTime = StringToTime(line[0]); // 588
            tradeLines[size].opPriceB = StringToDouble(line[1]); // 589
            tradeLines[size].tpPriceB = StringToDouble(line[2]); // 590
            tradeLines[size].slPriceB = StringToDouble(line[3]); // 591
            tradeLines[size].endTime = 0; // 592
            tradeLines[size].prefix = "Loaded_" + IntegerToString(size); // 593
         } // 594
      } // 595
      FileClose(fileHandle); // 596
      UpdateLines(); // 597
   } // 598
} // 599

/*
void CheckTimeConditions() { // 600
   datetime currentTime = TimeCurrent(); // 601
   int currentHour = Hour(currentTime); // 602
   int currentMinute = Minute(currentTime); // 603
   string entryHourStr = g_entryHour; // 604
   string entryMinuteStr = g_entryMinute; // 605
   int entryHour = StringToInteger(entryHourStr); // 606
   int entryMinute = StringToInteger(entryMinuteStr); // 607

   if(currentHour == entryHour && currentMinute == entryMinute) { // 608
      g_liveMode = true; // 609
   } else { // 610
      g_liveMode = false; // 611
   } // 612
} // 613 */

void ManageRisk() { // 614
   double accountBalance = AccountBalance ; // 615
   double maxRisk = accountBalance * 0.01; // 1% риск // 616
   double pipValue = CalculatePipValue(g_symb, g_lot); // 617
   double riskPerTrade = g_dev * pipValue; // 618

   if(riskPerTrade > maxRisk) { // 619
      g_lot = NormalizeDouble(maxRisk / (g_dev * pipValue), 2); // 620
   } // 621
} // 622

void OptimizeParameters() { // 623
   double bestDev = g_dev; // 624
   double bestProfit = totalSum; // 625
   for(double dev = 100.0; dev <= 1000.0; dev += 100.0) { // 626
      g_dev = dev; // 627
      ResetTradeLines(); // 628
      for(int i = 0; i < 10; i++) { // 629
         OnTick(); // 630
      } // 631
      if(totalSum > bestProfit) { // 632
         bestProfit = totalSum; // 633
         bestDev = dev; // 634
      } // 635
   } // 636
   g_dev = bestDev; // 637
   devValues[0] = bestDev; // 638
   UpdateDevLabel(); // 639
} // 640

void DisplayStatistics() { // 641
   double winRate = (profitCount > 0) ? (profitCount * 100.0) / (profitCount + lossCount) : 0.0; // 642
   string stats = StringFormat("Win Rate: %.2f%%, Profit: %.2f, Trades: %d", winRate, totalSum, profitCount + lossCount); // 643
   CreateLabel("lblStats", 50, 130, stats, clrWhite); // 644
} // 645

void ClearChart() { // 646
   ObjectsDeleteAll(0); // 647
   ResetTradeLines(); // 648
} // 649

void ExportToImage() { // 650
   ChartScreenShot(0, "TradeChart.png", 800, 600, ALIGN_CENTER); // 651
} // 652

void BackupCode() { // 653
   int fileHandle = FileOpen("MainStrategy803_Backup.mq5", FILE_WRITE|FILE_TXT); // 654
   if(fileHandle != INVALID_HANDLE) { // 655
      string code = ""; // 656
      // Добавяне на целия код тук (за простота ще го имитирам) // 657
      FileWriteString(fileHandle, code); // 658
      FileClose(fileHandle); // 659
   } // 660
} // 661

void RestoreCode() { // 662
   int fileHandle = FileOpen("MainStrategy803_Backup.mq5", FILE_READ|FILE_TXT); // 663
   if(fileHandle != INVALID_HANDLE) { // 664
      string code = FileReadString(fileHandle); // 665
      FileClose(fileHandle); // 666
      // Логика за възстановяване на кода (за момента само имитация) // 667
   } // 668
} // 669

/*
void CheckUpdates() { // 670
   string url = "https://www.mql5.com/en/code/viewcode/" + IntegerToString(12345); // Имитация на URL // 671
   string content; // 672
   if(WebRequest("GET", url, "", NULL, 5000, NULL, 0, content, NULL) > 0) { // 673
      if(StringFind(content, "version 1.01") >= 0) { // 674
         CreateLabel("lblUpdate", 50, 150, "Update available!", clrYellow); // 675
      } // 676
   } // 677
} // 678  */

void SetDefaultParameters() { // 679
   g_dev = 600.0; // 680
   g_lot = 0.10; // 681
   g_entryHour = "09"; // 682
   g_entryMinute = "00"; // 683
   devValues[0] = g_dev; // 684
   UpdateDevLabel(); // 685
} // 686

void LogTrade(string message) { // 687
   int fileHandle = FileOpen("TradeLog.txt", FILE_WRITE|FILE_TXT|FILE_READ|FILE_SHARE_READ); // 688
   if(fileHandle != INVALID_HANDLE) { // 689
      FileSeek(fileHandle, 0, SEEK_END); // 690
      FileWriteString(fileHandle, TimeToString(TimeCurrent()) + ": " + message + "\n"); // 691
      FileClose(fileHandle); // 692
   } // 693
} // 694

void mySendNotification(string message) { // 695
   SendNotification(message); // 696
} // 697
/*
void AdjustTimeZone() { // 698
   long timezoneOffset = 0; // Трябва да се настройва според сървъра // 699
   datetime serverTime = TimeCurrent(); // 700
   datetime localTime = serverTime + timezoneOffset * 3600; // 701
   g_entryHour = TimeToString(localTime, TIME_HOURS); // 702
   g_entryMinute = TimeToString(localTime, TIME_MINUTES); // 703
} // 704  */

void ValidateInputs() { // 705
   if(g_dev <= 0) g_dev = 600.0; // 706
   if(g_lot <= 0) g_lot = 0.10; // 707
   if(StringLen(g_entryHour) != 2) g_entryHour = "09"; // 708
   if(StringLen(g_entryMinute) != 2) g_entryMinute = "00"; // 709
} // 710

void InitializeChart() { // 711
   ChartSetInteger(0, CHART_COLOR_BACKGROUND, clrBlack); // 712
   ChartSetInteger(0, CHART_COLOR_FOREGROUND, clrWhite); // 713
   ChartRedraw(0); // 714
} // 715
/*
void SetChartPeriod() { // 716
   ChartSetSymbolPeriod(0, g_symb, g_period); // 717
} // 718 */

void DrawGrid() { // 719
   for(int i = 0; i < 10; i++) { // 720
      double price = SymbolInfoDouble(g_symb, SYMBOL_BID) + i * g_dev; // 721
      CreateLine("Grid_" + IntegerToString(i), price, clrGray, 0, 0); // 722
   } // 723
} // 724

void RemoveGrid() { // 725
   for(int i = 0; i < 10; i++) { // 726
      ObjectDelete(0, "Grid_" + IntegerToString(i)); // 727
   } // 728
} // 729

void ToggleLiveMode() { // 730
   g_liveMode = !g_liveMode; // 731
   CreateLabel("lblLiveMode", 50, 170, "Live Mode: " + (g_liveMode ? "ON" : "OFF"), clrWhite); // 732
} // 733

void SetMultiplier() { // 734
   g_multiplier = 0.0001; // 735
   for(int i = 0; i < ArraySize(devValues); i++) { // 736
      devValues[i] *= g_multiplier; // 737
   } // 738
   UpdateDevLabel(); // 739
} // 740

void AdjustLotSize() { // 741
   double accountEquity = AccountEquity; // 742
   g_lot = NormalizeDouble(accountEquity * 0.01 / g_dev, 2); // 743
} // 744

void CheckMarketConditions() { // 745
   double spread = SymbolInfoDouble(g_symb, SYMBOL_ASK)-SymbolInfoDouble(g_symb, SYMBOL_BID); // 746
   if(spread > 50) { // 747
      CreateLabel("lblWarning", 50, 190, "High Spread Warning!", clrRed); // 748
   } else { // 749
      ObjectDelete(0, "lblWarning"); // 750
   } // 751
} // 752

void SetStopLossTakeProfit() { // 753
   for(int i = 0; i < PositionsTotal(); i++) { // 754
      ulong ticket = PositionGetTicket(i); // 755
      if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == g_symb) { // 756
         double opPrice = PositionGetDouble(POSITION_PRICE_OPEN); // 757
         double tp = reverse ? opPrice - g_dev : opPrice + g_dev; // 758
         double sl = reverse ? opPrice + g_dev : opPrice - g_dev; // 759
         PositionModify(ticket, sl, tp, magic); // 760
      } // 761
   } // 762
} // 763

void CloseAllPositions() { // 764
   for(int i = PositionsTotal() - 1; i >= 0; i--) { // 765
      ulong ticket = PositionGetTicket(i); // 766
      if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == g_symb) { // 767
         PositionClose(ticket); // 768
      } // 769
   } // 770
} // 771

void PauseTrading() { // 772
   g_liveMode = false; // 773
   CreateLabel("lblPause", 50, 210, "Trading Paused", clrOrange); // 774
} // 775

void ResumeTrading() { // 776
   g_liveMode = true; // 777
   ObjectDelete(0, "lblPause"); // 778
} // 779

void SetAlertLevel() { // 780
   double alertLevel = SymbolInfoDouble(g_symb, SYMBOL_BID) + g_dev * 2; // 781
   CreateLine("AlertLevel", alertLevel, clrOrange, 0, 0); // 782
} // 783

void RemoveAlertLevel() { // 784
   ObjectDelete(0, "AlertLevel"); // 785
} // 786

void CheckLatency() { // 787
   datetime serverTime = TimeCurrent(); // 788
   datetime localTime = TimeLocal(); // 789
   double latency = (localTime - serverTime) / 1000.0; // 790
   CreateLabel("lblLatency", 50, 230, "Latency: " + DoubleToString(latency, 2) + "s", clrWhite); // 791
} // 792

void AdjustChartZoom() { // 793
   ChartSetInteger(0, CHART_SCALE, 2); // 794
} // 795
/*
void SetCustomTimeframe() { // 796
   g_period = 60; // 797
   SetChartPeriod(); // 798
   ChartRedraw(0); // 799
} // 800*/
/*
void ResetCustomTimeframe() { // 801
   g_period = 30; // 802
   SetChartPeriod(); // 803
   ChartRedraw(0); // 804
} // 805 */

void DrawSupportResistance() { // 806
   MqlRates rates[]; // 807
   ArraySetAsSeries(rates, true); // 808
   int copied = CopyRates(g_symb, PERIOD_D1, 0, 50, rates); // 809
   if(copied <= 0) return; // 810

   double highest = 0, lowest = DBL_MAX; // 811
   for(int i = 0; i < copied; i++) { // 812
      if(rates[i].high > highest) highest = rates[i].high; // 813
      if(rates[i].low < lowest) lowest = rates[i].low; // 814
   } // 815

   CreateLine("Support", lowest, clrGreen, 0, 0); // 816
   CreateLine("Resistance", highest, clrRed, 0, 0); // 817
} // 818

void RemoveSupportResistance() { // 819
   ObjectDelete(0, "Support"); // 820
   ObjectDelete(0, "Resistance"); // 821
} // 822
/*
void SetTrailingStop() { // 823
   for(int i = 0; i < PositionsTotal(); i++) { // 824
      ulong ticket = PositionGetTicket(i); // 825
      if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == g_symb) { // 826
         double opPrice = PositionGetDouble(POSITION_PRICE_OPEN); // 827
         double currentPrice = PositionGetDouble(POSITION_TYPE) == ORDER_TYPE_BUY ? SymbolInfoDouble(g_symb, SYMBOL_BID) : SymbolInfoDouble(g_symb, SYMBOL_ASK); // 828
         double profit = currentPrice - opPrice; // 829
         if(profit > g_dev) { // 830
            double newSL = opPrice + (reverse ? g_dev : -g_dev); // 831
            PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP)); // 832
         } // 833
      } // 834
   } // 835
} // 836

void DisableTrailingStop() { // 837
   for(int i = 0; i < PositionsTotal(); i++) { // 838
      ulong ticket = PositionGetTicket(i); // 839
      if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == g_symb) { // 840
         PositionModify(ticket, PositionGetDouble(POSITION_SL), PositionGetDouble(POSITION_TP)); // 841
      } // 842
   } // 843
} // 844

void SetBreakEven() { // 845
   for(int i = 0; i < PositionsTotal(); i++) { // 846
      ulong ticket = PositionGetTicket(i); // 847
      if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == g_symb) { // 848
         double opPrice = PositionGetDouble(POSITION_PRICE_OPEN); // 849
         double currentPrice = ( PositionGetDouble(POSITION_TYPE) == ORDER_TYPE_BUY) ? SymbolInfoDouble(g_symb, SYMBOL_BID) : SymbolInfoDouble(g_symb, SYMBOL_ASK); // 850
         double profit = currentPrice - opPrice; // 851
         if(profit > g_dev) { // 852
            PositionModify(ticket, opPrice, PositionGetDouble(POSITION_TP)); // 853
         } // 854
      } // 855
   } // 856
} // 857  */

void CheckVolatility() { // 858
   MqlRates rates[]; // 859
   ArraySetAsSeries(rates, true); // 860
   int copied = CopyRates(g_symb, PERIOD_H1, 0, 24, rates); // 861
   if(copied <= 0) return; // 862

   double avgRange = 0; // 863
   for(int i = 0; i < copied; i++) { // 864
      avgRange += (rates[i].high - rates[i].low); // 865
   } // 866
   avgRange /= copied; // 867

   if(avgRange > g_dev * 2) { // 868
      CreateLabel("lblVolatility", 50, 250, "High Volatility!", clrOrange); // 869
   } else { // 870
      ObjectDelete(0, "lblVolatility"); // 871
   } // 872
} // 873

void SetPendingOrders() { // 874
   if(PositionSelect(g_symb) == false) { // 875
      MqlTradeRequest request = {}; // 876
      MqlTradeResult result = {}; // 877
      request.action = TRADE_ACTION_PENDING; // 878
      request.symbol = g_symb; // 879
      request.volume = g_lot; // 880
      request.type = ORDER_TYPE_BUY_LIMIT; // 881
      request.price = SymbolInfoDouble(g_symb, SYMBOL_BID) - g_dev; // 882
      request.sl = request.price - g_dev; // 883
      request.tp = request.price + g_dev; // 884
      OrderSend(request, result); // 885
   } // 886
} // 887

void CancelPendingOrders() { // 888
   for(int i = OrdersTotal() - 1; i >= 0; i--) { // 889
      ulong ticket = OrderGetTicket(i); // 890
      if(OrderSelect(ticket) && OrderGetString(ORDER_SYMBOL) == g_symb) { // 891
         //OrderDelete(ticket); // 892
      } // 893
   } // 894
} // 895

void SetPartialClose() { // 896
   for(int i = 0; i < PositionsTotal(); i++) { // 897
      ulong ticket = PositionGetTicket(i); // 898
      if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == g_symb) { // 899
         double currentVolume = PositionGetDouble(POSITION_VOLUME); // 900
         if(currentVolume > g_lot) { // 901
            MqlTradeRequest request = {}; // 902
            MqlTradeResult result = {}; // 903
            request.action = TRADE_ACTION_DEAL; // 904
            request.symbol = g_symb; // 905
            request.volume = currentVolume - g_lot; // 906
            request.type = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? ORDER_TYPE_SELL : ORDER_TYPE_BUY; // 907
            request.price = SymbolInfoDouble(g_symb, PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? SYMBOL_BID : SYMBOL_ASK); // 908
            OrderSend(request, result); // 909
         } // 910
      } // 911
   } // 912
} // 913

void HedgePosition() { // 914
   if(PositionSelect(g_symb) == true) { // 915
      MqlTradeRequest request = {}; // 916
      MqlTradeResult result = {}; // 917
      request.action = TRADE_ACTION_DEAL; // 918
      request.symbol = g_symb; // 919
      request.volume = g_lot; // 920
      request.type = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? ORDER_TYPE_SELL : ORDER_TYPE_BUY; // 921
      request.price = SymbolInfoDouble(g_symb, PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? SYMBOL_BID : SYMBOL_ASK); // 922
      OrderSend(request, result); // 923
   } // 924
} // 925

void RemoveHedge() { // 926
   for(int i = PositionsTotal() - 1; i >= 0; i--) { // 927
      ulong ticket = PositionGetTicket(i); // 928
      if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == g_symb) { // 929
         PositionClose(ticket); // 930
      } // 931
   } // 932
} // 933

void SetNewsFilter() { // 934
   datetime newsTime = 0; // Трябва да се вземе от календар // 935
   if(TimeCurrent() >= newsTime - 300 && TimeCurrent() <= newsTime + 300) { // 936
      PauseTrading(); // 937
   } else if(!g_liveMode) { // 938
      ResumeTrading(); // 939
   } // 940
} // 941


/*
void CheckMarginLevel() { // 942
   double marginLevel = AccountMarginLevel; // 943
   if(marginLevel < 100) { // 944
      CreateLabel("lblMargin", 50, 270, "Low Margin Level!", clrRed); // 945
      PauseTrading(); // 946
   } else { // 947
      ObjectDelete(0, "lblMargin"); // 948
   } // 949
} // 950 */

void SetAutoLot() { // 951
   double riskPercent = 1.0; // 952
   double accountEquity = AccountEquity; // 953
   double tickValue = SymbolInfoDouble(g_symb, SYMBOL_TRADE_TICK_VALUE); // 954
   g_lot = NormalizeDouble((accountEquity * riskPercent / 100) / (g_dev * tickValue), 2); // 955
} // 956
/*
void AdjustSpread() { // 957
   double spread = SymbolInfoDouble(g_symb, MODE_SPREAD); // 958
   if(spread > 30) { // 959
      g_dev += spread * g_multiplier; // 960
      UpdateDevLabel(); // 961
   } // 962
} // 963*/

void SetTimeFilter() { // 964
   datetime startTime = StringToTime("09:00"); // 965
   datetime endTime = StringToTime("17:00"); // 966
   datetime currentTime = TimeCurrent(); // 967
   if(currentTime < startTime || currentTime > endTime) { // 968
      PauseTrading(); // 969
   } else { // 970
      ResumeTrading(); // 971
   } // 972
} // 973

void DrawFibonacci() { // 974
   MqlRates rates[]; // 975
   ArraySetAsSeries(rates, true); // 976
   int copied = CopyRates(g_symb, PERIOD_D1, 0, 2, rates); // 977
   if(copied < 2) return; // 978

   double high = rates[0].high; // 979
   double low = rates[1].low; // 980
   double range = high - low; // 981

   CreateLine("Fib_0", high, clrWhite, 0, 0); // 982
   CreateLine("Fib_236", high - range * 0.236, clrWhite, 0, 0); // 983
   CreateLine("Fib_382", high - range * 0.382, clrWhite, 0, 0); // 984
   CreateLine("Fib_5", high - range * 0.5, clrWhite, 0, 0); // 985
   CreateLine("Fib_618", high - range * 0.618, clrWhite, 0, 0); // 986
   CreateLine("Fib_786", high - range * 0.786, clrWhite, 0, 0); // 987
   CreateLine("Fib_100", low, clrWhite, 0, 0); // 988
} // 989

void RemoveFibonacci() { // 990
   for(int i = 0; i <= 7; i++) { // 991
      ObjectDelete(0, "Fib_" + DoubleToString(i / 10.0, 3)); // 992
   } // 993
} // 994

void SetPriceAlerts() { // 995
   double alertPrice = SymbolInfoDouble(g_symb, SYMBOL_BID) + g_dev; // 996
   CreateLine("PriceAlert", alertPrice, clrOrange, 0, 0); // 997
   if(SymbolInfoDouble(g_symb, SYMBOL_BID) >= alertPrice) { // 998
      SendNotification("Price alert triggered at " + DoubleToString(alertPrice, 5)); // 999
   } // 1000
} // 1001

void RemovePriceAlerts() { // 1002
   ObjectDelete(0, "PriceAlert"); // 1003
} // 1004

void CheckCorrelation() { // 1005
   string correlatedSymbol = "US500.c"; // 1006
   double correlation = 0; // Трябва да се изчисли // 1007
   if(correlation > 0.7) { // 1008
      CreateLabel("lblCorrelation", 50, 290, "High Correlation!", clrYellow); // 1009
   } else { // 1010
      ObjectDelete(0, "lblCorrelation"); // 1011
   } // 1012
} // 1013

void SetSessionTimes() { // 1014
   g_entryHour = "09"; // 1015
   g_entryMinute = "00"; // 1016
   //CheckTimeConditions(); // 1017
} // 1018

void AdjustPositionSize() { // 1019
   double accountBalance = AccountBalance; // 1020
   if(accountBalance < 1000) { // 1021
      g_lot = 0.05; // 1022
   } else if(accountBalance < 5000) { // 1023
      g_lot = 0.10; // 1024
   } else { // 1025
      g_lot = 0.20; // 1026
   } // 1027
} // 1028

void SetDailyTarget() { // 1029
   double targetProfit = AccountBalance * 0.02; // 2% дневна цел // 1030
   if(totalSum >= targetProfit) { // 1031
      PauseTrading(); // 1032
      CreateLabel("lblTarget", 50, 310, "Daily Target Reached!", clrGreen); // 1033
   } // 1034
} // 1035

void ResetDailyTarget() { // 1036
   totalSum = 0.0; // 1037
   ObjectDelete(0, "lblTarget"); // 1038
   ResumeTrading(); // 1039
} // 1040

void SetMaxDrawdown() { // 1041
   double maxDrawdown = AccountBalance * 0.05; // 5% максимален спад // 1042
   double currentDrawdown = AccountEquity - AccountBalance; // 1043
   if(currentDrawdown < -maxDrawdown) { // 1044
      CloseAllPositions(); // 1045
      CreateLabel("lblDrawdown", 50, 330, "Max Drawdown Reached!", clrRed); // 1046
   } // 1047
} // 1048

void CheckTrend() { // 1049
   MqlRates rates[]; // 1050
   ArraySetAsSeries(rates, true); // 1051
   int copied = CopyRates(g_symb, PERIOD_H4, 0, 10, rates); // 1052
   if(copied < 2) return; // 1053

   double trend = rates[0].close - rates[1].close; // 1054
   if(trend > 0) { // 1055
      CreateLabel("lblTrend", 50, 350, "Uptrend", clrLime); // 1056
   } else if(trend < 0) { // 1057
      CreateLabel("lblTrend", 50, 350, "Downtrend", clrRed); // 1058
   } else { // 1059
      ObjectDelete(0, "lblTrend"); // 1060
   } // 1061
} // 1062

void SetSessionBreak() { // 1063
   datetime breakStart = StringToTime("12:00"); // 1064
   datetime breakEnd = StringToTime("13:00"); // 1065
   datetime currentTime = TimeCurrent(); // 1066
   if(currentTime >= breakStart && currentTime <= breakEnd) { // 1067
      PauseTrading(); // 1068
   } else if(!g_liveMode) { // 1069
      ResumeTrading(); // 1070
   } // 1071
} // 1072

void AdjustPipStep() { // 1073
   g_dev = NormalizeDouble(g_dev + 50, 1); // 1074
   UpdateDevLabel(); // 1075
} // 1076

void SetCustomIndicator() { // 1077
   // Логика за добавяне на персонализиран индикатор // 1078
   IndicatorCreate("Custom", 0, IND_CUSTOM); // 1079
} // 1080

void RemoveCustomIndicator() { // 1081
   IndicatorRelease(0); // 1082
} // 1083

void SetAutoTrade() { // 1084
   g_liveMode = true; // 1085
   //CheckTimeConditions(); // 1086
} // 1087

void StopAutoTrade() { // 1088
   g_liveMode = false; // 1089
} // 1090

void SetProfitLock() { // 1091
   double lockLevel = g_dev * 1.5; // 1092
   for(int i = 0; i < PositionsTotal(); i++) { // 1093
      ulong ticket = PositionGetTicket(i); // 1094
      if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == g_symb) { // 1095
         double profit = PositionGetDouble(POSITION_PROFIT); // 1096
         if(profit > lockLevel) { // 1097
            PositionClose(ticket); // 1098
         } // 1099
      } // 1100
   } // 1101
} // 1102

void CheckLiquidity() { // 1103
   double liquidity = 0; // Трябва да се изчисли // 1104
   if(liquidity < 1000) { // 1105
      CreateLabel("lblLiquidity", 50, 370, "Low Liquidity!", clrOrange); // 1106
   } else { // 1107
      ObjectDelete(0, "lblLiquidity"); // 1108
   } // 1109
} // 1110

void SetSessionEnd() { // 1111
   datetime endTime = StringToTime("17:00"); // 1112
   if(TimeCurrent() >= endTime) { // 1113
      CloseAllPositions(); // 1114
      PauseTrading(); // 1115
   } // 1116
} // 1117
/*
void AdjustLeverage() { // 1118
   double leverage = AccountLeverage; // 1119
   if(leverage < 50) { // 1120
      // Логика за настройка на ливъридж (зависи от брокера) // 1121
   } // 1122
} // 1123*/

void SetCustomColor() { // 1124
   ChartSetInteger(0, CHART_COLOR_CHART_UP, clrLime); // 1125
   ChartSetInteger(0, CHART_COLOR_CHART_DOWN, clrRed); // 1126
   ChartRedraw(0); // 1127
} // 1128
/*void ResetCustomColor() { // 1129
   ChartSetInteger(0, CHART_COLOR_CHART_UP, clrDefault); // 1130
   ChartSetInteger(0, CHART_COLOR_CHART_DOWN, clrDefault); // 1131
   ChartRedraw(0); // 1132
} // 1133*/

void SetAutoOptimize() { // 1134
   OptimizeParameters(); // 1135
   SetTradeParameters(); // 1136
} // 1137

void CheckAccountStatus() { // 1138
   if(AccountBalance <= 0) { // 1139
      CreateLabel("lblAccount", 50, 390, "Account Depleted!", clrRed); // 1140
      CloseAllPositions(); // 1141
   } // 1142
} // 1143

void SetCustomAlert() { // 1144
   double alertPrice = SymbolInfoDouble(g_symb, SYMBOL_BID) - g_dev; // 1145
   if(SymbolInfoDouble(g_symb, SYMBOL_BID) <= alertPrice) { // 1146
      SendNotification("Custom alert at " + DoubleToString(alertPrice, 5)); // 1147
   } // 1148
} // 1149

void RemoveCustomAlert() { // 1150
   // Логика за премахване на персонализирани алерти // 1151
} // 1152

void SetSessionStart() { // 1153
   datetime startTime = StringToTime("09:00"); // 1154
   if(TimeCurrent() >= startTime) { // 1155
      ResumeTrading(); // 1156
   } // 1157
} // 1158
/*
void AdjustTradeFrequency() { // 1159
   g_period = g_period * 2; // 1160
   SetChartPeriod(); // 1161
} // 1162*/
/*
void ResetTradeFrequency() { // 1163
   g_period = 30; // 1164
   SetChartPeriod(); // 1165
} // 1166 */

void SetCustomGrid() { // 1167
   for(int i = -5; i <= 5; i++) { // 1168
      double price = SymbolInfoDouble(g_symb, SYMBOL_BID) + i * g_dev; // 1169
      CreateLine("CustomGrid_" + IntegerToString(i), price, clrGray, 0, 0); // 1170
   } // 1171
} // 1172

void RemoveCustomGrid() { // 1173
   for(int i = -5; i <= 5; i++) { // 1174
      ObjectDelete(0, "CustomGrid_" + IntegerToString(i)); // 1175
   } // 1176
} // 1177

void SetTradeLimit() { // 1178
   int maxTrades = 5; // 1179
   if(PositionsTotal() >= maxTrades) { // 1180
      PauseTrading(); // 1181
      CreateLabel("lblTradeLimit", 50, 410, "Trade Limit Reached!", clrRed); // 1182
   } // 1183
} // 1184

void ResetTradeLimit() { // 1185
   ObjectDelete(0, "lblTradeLimit"); // 1186
   ResumeTrading(); // 1187
} // 1188

void SetCustomTimeAlert() { // 1189
   datetime alertTime = StringToTime("15:00"); // 1190
   if(TimeCurrent() >= alertTime) { // 1191
      SendNotification("Time alert at 15:00"); // 1192
   } // 1193
} // 1194

void RemoveTimeAlert() { // 1195
   // Логика за премахване на времеви алерти // 1196
} // 1197

void SetEquityProtection() { // 1198
   double equity = AccountEquity; // 1199
   if(equity < AccountBalance * 0.95) { // 1200
      PauseTrading(); // 1201
      CreateLabel("lblEquity", 50, 430, "Equity Protection Triggered!", clrRed); // 1202
   } // 1203
} // 1204

void ResetEquityProtection() { // 1205
   ObjectDelete(0, "lblEquity"); // 1206
   ResumeTrading(); // 1207
} // 1208

void SetCustomRange() { // 1209
   double rangeStart = SymbolInfoDouble(g_symb, SYMBOL_BID) - g_dev * 2; // 1210
   double rangeEnd = SymbolInfoDouble(g_symb, SYMBOL_BID) + g_dev * 2; // 1211
   CreateLine("RangeStart", rangeStart, clrBlue, 0, 0); // 1212
   CreateLine("RangeEnd", rangeEnd, clrBlue, 0, 0); // 1213
} // 1214

void RemoveCustomRange() { // 1215
   ObjectDelete(0, "RangeStart"); // 1216
   ObjectDelete(0, "RangeEnd"); // 1217
} // 1218

void SetAutoAdjust() { // 1219
   g_dev = SymbolInfoDouble(g_symb, SYMBOL_POINT) * 10000; // 1220
   UpdateDevLabel(); // 1221
} // 1222
/*
void CheckServerStatus() { // 1223
   if(!IsConnected()) { // 1224
      CreateLabel("lblServer", 50, 450, "Server Disconnected!", clrRed); // 1225
      PauseTrading(); // 1226
   } else { // 1227
      ObjectDelete(0, "lblServer"); // 1228
   } // 1229
} // 1230*/

void SetCustomPip() { // 1231
   g_dev = 50.0; // 1232
   UpdateDevLabel(); // 1233
} // 1234
/*
void AdjustTradeDirection() { // 1235
   reverse = !reverse; // 1236
   CreateLabel("lblDirection", 50, 470, "Direction: " + (reverse ? "Reverse" : "Normal"), clrWhite); // 1237
} // 1238

void ResetTradeDirection() { // 1239
   reverse = false; // 1240
   ObjectDelete(0, "lblDirection"); // 1241
} // 1242  */

void SetCustomEntry() { // 1243
   g_entryHour = "10"; // 1244
   g_entryMinute = "00"; // 1245
   //CheckTimeConditions(); // 1246
} // 1247

void ResetCustomEntry() { // 1248
   g_entryHour = "09"; // 1249
   g_entryMinute = "00"; // 1250
  // CheckTimeConditions(); // 1251
} // 1252

void SetTradeConfirmation() { // 1253
   if(MessageBox("Confirm Trade?", "Confirmation", MB_YESNO) == IDYES) { // 1254
      g_liveMode = true; // 1255
   } else { // 1256
      g_liveMode = false; // 1257
   } // 1258
} // 1259

void CheckTradeHistory() { // 1260
   for(int i = 0; i < HistoryOrdersTotal(); i++) { // 1261
      ulong ticket = HistoryOrderGetTicket(i); // 1262
      if(HistoryOrderSelect(ticket)) { // 1263
         if(HistoryOrderGetString(ticket, ORDER_SYMBOL) == g_symb) { // 1264
            CreateLabel("lblHistory", 50, 490, "Trade History Found!", clrYellow); // 1265
            break; // 1266
         } // 1267
      } // 1268
   } // 1269
} // 1270

void RemoveTradeHistoryLabel() { // 1271
   ObjectDelete(0, "lblHistory"); // 1272
} // 1273
/*
void SetCustomSpread() { // 1274
   double customSpread = 20; // 1275
   if(SymbolInfoDouble(g_symb, MODE_SPREAD) > customSpread) { // 1276
      PauseTrading(); // 1277
      CreateLabel("lblSpread", 50, 510, "Spread Too High!", clrRed); // 1278
   } else { // 1279
      ObjectDelete(0, "lblSpread"); // 1280
   } // 1281
} // 1282*/

void ResetCustomSpread() { // 1283
   ObjectDelete(0, "lblSpread"); // 1284
   ResumeTrading(); // 1285
} // 1286

void SetCustomRisk() { // 1287
   double risk = 2.0; // 2% риск // 1288
   g_lot = NormalizeDouble((AccountEquity * risk / 100) / g_dev, 2); // 1289
} // 1290

void CheckPositionRisk() { // 1291
   for(int i = 0; i < PositionsTotal(); i++) { // 1292
      ulong ticket = PositionGetTicket(i); // 1293
      if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == g_symb) { // 1294
         double risk = PositionGetDouble(POSITION_VOLUME) * g_dev; // 1295
         if(risk > AccountEquity * 0.02) { // 1296
            PositionClose(ticket); // 1297
            CreateLabel("lblRisk", 50, 530, "High Risk Position Closed!", clrRed); // 1298
         } // 1299
      } // 1300
   } // 1301
} // 1302

void SetCustomProfit() { // 1303
   double profitTarget = g_dev * 3; // 1304
   for(int i = 0; i < PositionsTotal(); i++) { // 1305
      ulong ticket = PositionGetTicket(i); // 1306
      if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == g_symb) { // 1307
         double profit = PositionGetDouble(POSITION_PROFIT); // 1308
         if(profit >= profitTarget) { // 1309
            PositionClose(ticket); // 1310
            CreateLabel("lblProfitTarget", 50, 550, "Profit Target Reached!", clrGreen); // 1311
         } // 1312
      } // 1313
   } // 1314
} // 1315

void ResetCustomProfit() { // 1316
   ObjectDelete(0, "lblProfitTarget"); // 1317
} // 1318

void SetCustomLoss() { // 1319
   double lossLimit = g_dev * 2; // 1320
   for(int i = 0; i < PositionsTotal(); i++) { // 1321
      ulong ticket = PositionGetTicket(i); // 1322
      if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == g_symb) { // 1323
         double loss = -PositionGetDouble(POSITION_PROFIT); // 1324
         if(loss >= lossLimit) { // 1325
            PositionClose(ticket); // 1326
            CreateLabel("lblLossLimit", 50, 570, "Loss Limit Reached!", clrRed); // 1327
         } // 1328
      } // 1329
   } // 1330
} // 1331

void ResetCustomLoss() { // 1332
   ObjectDelete(0, "lblLossLimit"); // 1333
} // 1334

void SetCustomTimeRange() { // 1335
   datetime start = StringToTime("09:00"); // 1336
   datetime end = StringToTime("16:00"); // 1337
   if(TimeCurrent() < start || TimeCurrent() > end) { // 1338
      PauseTrading(); // 1339
   } else { // 1340
      ResumeTrading(); // 1341
   } // 1342
} // 1343

void CheckMarketHours() { // 1344
   datetime openTime = StringToTime("00:00"); // 1345
   datetime closeTime = StringToTime("23:59"); // 1346
   if(TimeCurrent() < openTime || TimeCurrent() > closeTime) { // 1347
      PauseTrading(); // 1348
      CreateLabel("lblMarket", 50, 590, "Market Closed!", clrRed); // 1349
   } else { // 1350
      ObjectDelete(0, "lblMarket"); // 1351
   } // 1352
} // 1353

void SetCustomVolume() { // 1354
   g_lot = 0.20; // 1355
} // 1356

void ResetCustomVolume() { // 1357
   g_lot = 0.10; // 1358
} // 1359

void SetCustomDeviation() { // 1360
   g_dev = 800.0; // 1361
   UpdateDevLabel(); // 1362
} // 1363

void ResetCustomDeviation() { // 1364
   g_dev = 600.0; // 1365
   UpdateDevLabel(); // 1366
} // 1367
/*
void SetCustomSlippage() { // 1368
   int slippage = 10; // 1369
   for(int i = 0; i < PositionsTotal(); i++) { // 1370
      ulong ticket = PositionGetTicket(i); // 1371
      if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == g_symb) { // 1372
         MqlTradeRequest request = {}; // 1373
         MqlTradeResult result = {}; // 1374
         request.action = TRADE_ACTION_SLTP; // 1375
         request.slippage = slippage; // 1376
         OrderSend(request, result); // 1377
      } // 1378
   } // 1379
} // 1380 */
/*
void ResetCustomSlippage() { // 1381
   int slippage = 3; // 1382
   for(int i = 0; i < PositionsTotal(); i++) { // 1383
      ulong ticket = PositionGetTicket(i); // 1384
      if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == g_symb) { // 1385
         MqlTradeRequest request = {}; // 1386
         MqlTradeResult result = {}; // 1387
         request.action = TRADE_ACTION_SLTP; // 1388
         request.slippage = slippage; // 1389
         OrderSend(request, result); // 1390
      } // 1391
   } // 1392
} // 1393 */
/*
void SetCustomExpiration() { // 1394
   datetime expiration = TimeCurrent() + 24 * 3600; // 1395
   for(int i = 0; i < OrdersTotal(); i++) { // 1396
      ulong ticket = OrderGetTicket(i); // 1397
      if(OrderSelect(ticket) && OrderGetString(ORDER_SYMBOL) == g_symb) { // 1398
         OrderModify(ticket, OrderGetDouble(ORDER_PRICE_OPEN), OrderGetDouble(ORDER_SL), OrderGetDouble(ORDER_TP), expiration); // 1399
      } // 1400
   } // 1401
} // 1402

void ResetCustomExpiration() { // 1403
   for(int i = 0; i < OrdersTotal(); i++) { // 1404
      ulong ticket = OrderGetTicket(i); // 1405
      if(OrderSelect(ticket) && OrderGetString(ORDER_SYMBOL) == g_symb) { // 1406
         OrderModify(ticket, OrderGetDouble(ORDER_PRICE_OPEN), OrderGetDouble(ORDER_SL), OrderGetDouble(ORDER_TP), 0); // 1407
      } // 1408
   } // 1409
} // 1410   */

void SetCustomMagic() { // 1411
   long magic = 123456; // 1412
   for(int i = 0; i < PositionsTotal(); i++) { // 1413
      ulong ticket = PositionGetTicket(i); // 1414
      if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == g_symb) { // 1415
         PositionModify(ticket, PositionGetDouble(POSITION_SL), PositionGetDouble(POSITION_TP), magic); // 1416
      } // 1417
   } // 1418
} // 1419

void ResetCustomMagic() { // 1420
   for(int i = 0; i < PositionsTotal(); i++) { // 1421
      ulong ticket = PositionGetTicket(i); // 1422
      if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == g_symb) { // 1423
         PositionModify(ticket, PositionGetDouble(POSITION_SL), PositionGetDouble(POSITION_TP), 0); // 1424
      } // 1425
   } // 1426
} // 1427

void SetCustomComment() { // 1428
   string comment = "Custom Trade"; // 1429
   for(int i = 0; i < PositionsTotal(); i++) { // 1430
      ulong ticket = PositionGetTicket(i); // 1431
      if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == g_symb) { // 1432
         PositionModify(ticket, PositionGetDouble(POSITION_SL), PositionGetDouble(POSITION_TP), 0); // 1433
      } // 1434
   } // 1435
} // 1436

void ResetCustomComment() { // 1437
   for(int i = 0; i < PositionsTotal(); i++) { // 1438
      ulong ticket = PositionGetTicket(i); // 1439
      if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == g_symb) { // 1440
         PositionModify(ticket, PositionGetDouble(POSITION_SL), PositionGetDouble(POSITION_TP), 0); // 1441
      } // 1442
   } // 1443
} // 1444

void SetCustomOffset() { // 1445
   double offset = 100.0; // 1446
   g_dev += offset; // 1447
   UpdateDevLabel(); // 1448
} // 1449

void ResetCustomOffset() { // 1450
   g_dev = 600.0; // 1451
   UpdateDevLabel(); // 1452
} // 1453

void SetCustomRangeAlert() { // 1454
   double rangeStart = SymbolInfoDouble(g_symb, SYMBOL_BID) - g_dev; // 1455
   double rangeEnd = SymbolInfoDouble(g_symb, SYMBOL_BID) + g_dev; // 1456
   if(SymbolInfoDouble(g_symb, SYMBOL_BID) <= rangeStart || SymbolInfoDouble(g_symb, SYMBOL_BID) >= rangeEnd) { // 1457
      SendNotification("Price outside custom range!"); // 1458
   } // 1459
} // 1460

void RemoveCustomRangeAlert() { // 1461
   // Логика за премахване на алерт за обхват // 1462
} // 1463

void SetCustomSession() { // 1464
   g_entryHour = "14"; // 1465
   g_entryMinute = "00"; // 1466
   //CheckTimeConditions(); // 1467
} // 1468

void ResetCustomSession() { // 1469
   g_entryHour = "09"; // 1470
   g_entryMinute = "00"; // 1471
   //CheckTimeConditions(); // 1472
} // 1473

void SetCustomPipValue() { // 1474
   double pipValue = 10.0; // 1475
   g_dev = pipValue; // 1476
   UpdateDevLabel(); // 1477
} // 1478

void ResetCustomPipValue() { // 1479
   g_dev = 600.0; // 1480
   UpdateDevLabel(); // 1481
} // 1482

void SetCustomTradeType() { // 1483
   // Логика за настройка на персонализиран тип търговия // 1484
} // 1485

void ResetCustomTradeType() { // 1486
   // Логика за връщане на стандартния тип търговия // 1487
} // 1488
/*
void SetCustomIndicatorPeriod() { // 1489
   g_period = 15; // 1490
   SetChartPeriod(); // 1491
} // 1492*/
/*
void ResetCustomIndicatorPeriod() { // 1493
   g_period = 30; // 1494
   SetChartPeriod(); // 1495
} // 1496*/

void SetCustomAlertSound() { // 1497
   PlaySound("alert.wav"); // 1498
} // 1499

void ResetCustomAlertSound() { // 1500
   // Логика за изключване на звука // 1501
} // 1502
/*
void SetCustomChartStyle() { // 1503
   ChartSetInteger(0, CHART_STYLE, CHART_CANDLES); // 1504
   ChartRedraw(0); // 1505
} // 1506*/
/*
void ResetCustomChartStyle() { // 1507
   ChartSetInteger(0, CHART_STYLE, CHART_BARS); // 1508
   ChartRedraw(0); // 1509
} // 1510*/

void SetCustomTimeOffset() { // 1511
   long offset = 2; // Часов отстъп // 1512
   g_entryHour = IntegerToString((StringToInteger(g_entryHour) + offset) % 24); // 1513
  // CheckTimeConditions(); // 1514
} // 1515

void ResetCustomTimeOffset() { // 1516
   g_entryHour = "09"; // 1517
   //CheckTimeConditions(); // 1518
} // 1519

void SetCustomProfitFactor() { // 1520
   double factor = 1.5; // 1521
   for(int i = 0; i < PositionsTotal(); i++) { // 1522
      ulong ticket = PositionGetTicket(i); // 1523
      if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == g_symb) { // 1524
         double tp = PositionGetDouble(POSITION_TP) * factor; // 1525
         PositionModify(ticket, PositionGetDouble(POSITION_SL), tp, magic); // 1526
      } // 1527
   } // 1528
} // 1529

void ResetCustomProfitFactor() { // 1530
   for(int i = 0; i < PositionsTotal(); i++) { // 1531
      ulong ticket = PositionGetTicket(i); // 1532
      if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == g_symb) { // 1533
         PositionModify(ticket, PositionGetDouble(POSITION_SL), PositionGetDouble(POSITION_TP), magic); // 1534
      } // 1535
   } // 1536
} // 1537

void SetCustomLossFactor() { // 1538
   double factor = 0.5; // 1539
   for(int i = 0; i < PositionsTotal(); i++) { // 1540
      ulong ticket = PositionGetTicket(i); // 1541
      if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == g_symb) { // 1542
         double sl = PositionGetDouble(POSITION_SL) * factor; // 1543
         PositionModify(ticket, sl, PositionGetDouble(POSITION_TP), magic); // 1544
      } // 1545
   } // 1546
} // 1547

void ResetCustomLossFactor() { // 1548
   for(int i = 0; i < PositionsTotal(); i++) { // 1549
      ulong ticket = PositionGetTicket(i); // 1550
      if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == g_symb) { // 1551
         PositionModify(ticket, PositionGetDouble(POSITION_SL), PositionGetDouble(POSITION_TP), magic); // 1552
      } // 1553
   } // 1554
} // 1555

void SetCustomTradeDelay() { // 1556
   Sleep(1000); // 1557
} // 1558

void ResetCustomTradeDelay() { // 1559
   // Няма забавяне // 1560
} // 1561

void SetCustomChartShift() { // 1562
   ChartSetInteger(0, CHART_SHIFT, true); // 1563
   ChartRedraw(0); // 1564
} // 1565

void ResetCustomChartShift() { // 1566
   ChartSetInteger(0, CHART_SHIFT, false); // 1567
   ChartRedraw(0); // 1568
} // 1569

void SetCustomScroll() { // 1570
   ChartNavigate(0, CHART_END, 0); // 1571
} // 1572

void ResetCustomScroll() { // 1573
   ChartNavigate(0, CHART_BEGIN, 0); // 1574
} // 1575

void SetCustomZoomLevel() { // 1576
   ChartSetInteger(0, CHART_SCALE, 3); // 1577
   ChartRedraw(0); // 1578
} // 1579

void ResetCustomZoomLevel() { // 1580
   ChartSetInteger(0, CHART_SCALE, 2); // 1581
   ChartRedraw(0); // 1582
} // 1583

void SetCustomGridSpacing() { // 1584
   for(int i = -10; i <= 10; i++) { // 1585
      double price = SymbolInfoDouble(g_symb, SYMBOL_BID) + i * g_dev / 2; // 1586
      CreateLine("CustomGridSpacing_" + IntegerToString(i), price, clrGray, 0, 0); // 1587
   } // 1588
} // 1589

void RemoveCustomGridSpacing() { // 1590
   for(int i = -10; i <= 10; i++) { // 1591
      ObjectDelete(0, "CustomGridSpacing_" + IntegerToString(i)); // 1592
   } // 1593
} // 1594

void Finalize() { // 1595
   SaveTradeData(); // 1596
   ExportToImage(); // 1597
   BackupCode(); // 1598
   CloseAllPositions(); // 1599
} // 1600   

void PositionModify(ulong ticket, double sl,  double tp, long magic)
{} // 760

void PositionClose(ulong ticket) {}


} // namespace
