//+------------------------------------------------------------------+
//|                                               Slime_Mold_RSI.mq4 |
//|                                                       Kei Sanada |
//|                          https://www.mql5.com/en/users/sdk7777   |
//|        2017/07/19 V1.1 Add take measures to changing ticket No   |          
//+------------------------------------------------------------------+
#property copyright "Kei Sanada"
#property link      "www.linkedin.com/in/kei-sanada"
#property version   "1.10"
#property strict

input double Lots = 0.1;
input int MagicNumber = 0;

input int    x1 = 0;//weight1
input int    x2 = 0;//weight2
input int    x3 = 0;//weight3
input int    x4 = 0;//weight4

input double atrMultiple = 2.5;

double UsePoint;

double PipPoint(string Currency)
{  double CalcPoint;
   int CalcDigits = MarketInfo(Currency, MODE_DIGITS);
   if(CalcDigits == 2 || CalcDigits == 3) CalcPoint = 0.01;
   else if(CalcDigits == 4 || CalcDigits == 5) CalcPoint = 0.0001;
   return(CalcPoint);
}

string Trade_Comment = "MagicNumber " + IntegerToString(MagicNumber,5,' '); 
int Ticket = 0; //Ticket number
int ticket = 0; 

void OnInit()
{
   UsePoint = PipPoint(Symbol());
}

void OnTick()
{
   double w1 = x1 - 100;
   double w2 = x2 - 100;
   double w3 = x3 - 100;
   double w4 = x4 - 100;   
   //Perceptron before one bar 2017/03/18
   double a11 = ((iRSI(Symbol(), PERIOD_M15, 14,PRICE_OPEN,0))/100-0.5)*2; 
   double a21 = ((iRSI(Symbol(), PERIOD_M30, 14,PRICE_OPEN,0))/100-0.5)*2; 
   double a31 = ((iRSI(Symbol(), PERIOD_H1, 14,PRICE_OPEN,0))/100-0.5)*2; 
   double a41 = ((iRSI(Symbol(), PERIOD_H1, 21,PRICE_OPEN,0))/100-0.5)*2; 
   double Current_Percptron = (w1 * a11 + w2 * a21 + w3 * a31 + w4 * a41);
   //Perceptron before two bar 2017/03/18
   double a12 = ((iRSI(Symbol(), PERIOD_M15, 14,PRICE_OPEN,1))/100-0.5)*2;
   double a22 = ((iRSI(Symbol(), PERIOD_M30, 14,PRICE_OPEN,1))/100-0.5)*2;
   double a32 = ((iRSI(Symbol(), PERIOD_H1, 14,PRICE_OPEN,1))/100-0.5)*2;
   double a42 = ((iRSI(Symbol(), PERIOD_H1, 21,PRICE_OPEN,1))/100-0.5)*2;
   double Pre_Percptron = (w1 * a12 + w2 * a22 + w3 * a32 + w4 * a42);
   
   double Atr = iATR(0,0,14,0);
   
   int pos = 0; //Position status
   //2017/07/19 V1.1 Add take measures to changing ticket No
   //Alpari changing ticekt No, when rollover.
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      //if(OrderSelect(i, SELECT_BY_POS,MODE_TRADES) && OrderMagicNumber() == MagicNumber)
      if(OrderSelect(i, SELECT_BY_POS) && OrderCloseTime() == 0 && OrderMagicNumber() == MagicNumber)
      {
         Ticket = OrderTicket();
      }
   }
   
   if(OrderSelect(Ticket, SELECT_BY_TICKET)) 
   {
      if(OrderType() == OP_BUY) pos = 1; //Long position
      if(OrderType() == OP_SELL) pos = -1; //Short positon
    }
   
   //2017/07/17 For Check Open price
   static int BarsBefore = 0;
   int BarsNow = Bars;
   int BarsCheck = BarsNow - BarsBefore;
   
   if (BarsCheck == 1)
   printf(Trade_Comment + ", " + "pos=" + IntegerToString(pos,0) + ", " + "Pre_Percptron=" + DoubleToString(Pre_Percptron,2) + ", " + "Current_Percptron=" + DoubleToString(Current_Percptron, 2) + ", ");
    
   BarsBefore = BarsNow;
      
   bool ret; //position status
   if(Pre_Percptron < 0 && Current_Percptron > 0) //long signal
   {
      //If there is a short position, send order close
      if(pos < 0)
      {
         ret = OrderClose(Ticket, OrderLots(), OrderClosePrice(), 0);
         //if(ret) pos = 0; //If order close succeeds, position status is Zero
         pos = 0;
      }
      //If there is no position, send long order
      if(pos == 0) 
      {
         ticket = OrderSend(
                                       _Symbol,              // symbol
                                       OP_BUY,                 // operation
                                       Lots,              // volume
                                       Ask,               // price
                                       0,            // slippage
                                       0,            // stop loss
                                       0,          // take profit
                                       Trade_Comment,        // comment
                                       MagicNumber,// magic number
                                       0,        // pending order expiration
                                       Green  // color
                                       );
                                       
       


         if(ticket > 0 && atrMultiple != 0)
         {
            if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
            {
               double BuyStopLoss = Bid - (Atr * atrMultiple);
               double BuyTakeProfit = Ask + (Atr * atrMultiple);
            
               OrderModify(ticket, OrderOpenPrice(), BuyStopLoss, BuyTakeProfit, 3, Green);
            }
         }
       }
   }
   if(Pre_Percptron > 0 && Current_Percptron < 0) //short signal
   {
      //If there is a long position, send order close
      if(pos > 0)
      {
         ret = OrderClose(Ticket, OrderLots(), OrderClosePrice(), 0);
         //if(ret) pos = 0; //If order close succeeds, position status is Zero
         pos = 0;
      }
      //If there is no position, send short order
      if(pos == 0) 
      {
         ticket = OrderSend(
                                       _Symbol,              // symbol
                                       OP_SELL,              // operation
                                       Lots,                 // volume
                                       Bid,          // price
                                       0,            // slippage
                                       0,            // stop loss
                                       0,            // take profit
                                       Trade_Comment,         // comment
                                       MagicNumber,  // magic number
                                       0,            // pending order expiration
                                       Red  // color
                                       );
                                       
         if(ticket > 0 && atrMultiple != 0)
         {
            if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
            {
               double SellStopLoss = Ask + (Atr * atrMultiple);
               double SellTakeProfit = Bid - (Atr * atrMultiple);
      
               OrderModify(ticket, OrderOpenPrice(), SellStopLoss, SellTakeProfit, 3, Green);
            }
         }
       } 
   }
}


//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
  //---
   return(TesterStatistics(STAT_PROFIT)/TesterStatistics(STAT_BALANCE_DD)-TesterStatistics(STAT_PROFIT_FACTOR));
  //---  
  }
//+------------------------------------------------------------------+