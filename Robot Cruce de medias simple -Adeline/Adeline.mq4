//+------------------------------------------------------------------+
//| Este MQL es generado por el generador de asesores expertos       |
//|                                                                  |
//|                                                                  |
//| El autor no será responsable de los daños y perjuicios,          |
//|no es herramienta para inversión                                  |
//| Úselo bajo su propio riesgo.                                     |
//|                http://sufx.core.t3-ism.net/ExpertAdvisorBuilder/ |
//|    
//|                                                                  |
//|   Modificado por Mario Duran para mejorar rendimientos simulados                                       |                                                                 
//|                                                                  |
//+------------------- NO QUITAR ESTE HEADER !!! --------------------+
   
   /* 
      REGLAS DE ENTRADA ADELINE:
       operación larga cuando SMA (10) cruza SMA (40) desde abajo
       operación corta cuando SMA (10) cruza SMA (40) desde la parte superior
   
       REGLAS DE SALIDA ADELINE:
       Salir de la operación larga cuando SMA (10) cruza SMA (40) desde la parte superior
       Salir de la operación corta cuando SMA (10) cruza SMA (40) desde abajo
       Parada dura de 30 pips (30 pips del precio de entrada inicial)
       Trailing stop de 30 pips
   
       TAMAÑO DE LA POSICIÓn: 
       1 lote
   */

#define SIGNAL_NONE 0
#define SIGNAL_BUY   1
#define SIGNAL_SELL  2
#define SIGNAL_CLOSEBUY 3
#define SIGNAL_CLOSESELL 4

#copyright "Expert Advisor Builder"


// TDL 5: Tamaño de posición y stops (estructura) 

extern int MagicNumber = 12345;
extern bool SignalMail = False;
extern double Lots = 1.0;
extern int Slippage = 3;
extern bool UseStopLoss = True;
extern int StopLoss = 30;
extern bool UseTakeProfit = False;
extern int TakeProfit = 0;
extern bool UseTrailingStop = True;
extern int TrailingStop = 30;

int P = 1;
int Order = SIGNAL_NONE;
int Total, Ticket, Ticket2;
double StopLossLevel, TakeProfitLevel, StopLevel;

//Declaración de variables
double sma10_1, sma10_2, sma40_1, sma40_2;

//+------------------------------------------------------------------+
//| Función de inicialización de nuestro Experto                     |
//+------------------------------------------------------------------+
int init() {
   
   if(Digits == 5 || Digits == 3 || Digits == 1)P = 10;else P = 1; // To account for 5 digit brokers

   return(0);
}
//+------------------------------------------------------------------+
//| Función de inicialización de nuestro Experto   - FIN             |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Función de deinicialización de nuestro Experto                   |
//+------------------------------------------------------------------+
int deinit() {
   return(0);
}
//+------------------------------------------------------------------+
//|  Función de deinicialización de nuestro Experto - FIN            |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Empezamos fucniòn del experto                                    |
//+------------------------------------------------------------------+
int start() {

   Total = OrdersTotal();
   Order = SIGNAL_NONE;

   //+------------------------------------------------------------------+
   //| Setup de variables                                               |
   //+------------------------------------------------------------------+
 
   // Asignando valores a las variables
   
   sma10_1 = iMA(NULL, 0, 10, 0, MODE_SMA, PRICE_CLOSE, 1); // c
   sma10_2 = iMA(NULL, 0, 10, 0, MODE_SMA, PRICE_CLOSE, 2); // b
   sma40_1 = iMA(NULL, 0, 40, 0, MODE_SMA, PRICE_CLOSE, 1); // d
   sma40_2 = iMA(NULL, 0, 40, 0, MODE_SMA, PRICE_CLOSE, 2); // a
   
   
   StopLevel = (MarketInfo(Symbol(), MODE_STOPLEVEL) + MarketInfo(Symbol(), MODE_SPREAD)) / P; // Defining minimum StopLevel

   if (StopLoss < StopLevel) StopLoss = StopLevel;
   if (TakeProfit < StopLevel) TakeProfit = StopLevel;

   //+------------------------------------------------------------------+
   //| FIN                                                              |
   //+------------------------------------------------------------------+

   //Checamos la posición
   bool IsTrade = False;

   for (int i = 0; i < Total; i ++) {
      Ticket2 = OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      if(OrderType() <= OP_SELL &&  OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber) {
         IsTrade = True;
         if(OrderType() == OP_BUY) {
            //Cerramos

            //+------------------------------------------------------------------+
            //| Inicio de Señal (Salir de la compra)                             |
            //+------------------------------------------------------------------+
	    
	    /* REGLAS DE SALIDA ADELINE:
                Salir de la operación larga cuando SMA (10) cruza SMA (40) desde la parte superior
                Salir de la operación corta cuando SMA (10) cruza SMA (40) desde abajo
                Parada dura de 30 pips (30 pips del precio de entrada inicial)
                Trailing stop de 30 pips
             */
            
             // T4: reglas de salida de código
            
            if(sma10_2 > sma40_2 && sma40_1 >= sma10_1) Order = SIGNAL_CLOSEBUY; // Rule to EXIT a Long trade

            //+------------------------------------------------------------------+
            //| Signal End(Exit Buy)                                             |
            //+------------------------------------------------------------------+

            if (Order == SIGNAL_CLOSEBUY) {
               Ticket2 = OrderClose(OrderTicket(), OrderLots(), Bid, Slippage, MediumSeaGreen);
               if (SignalMail) SendMail("[Signal Alert]", "[" + Symbol() + "] " + DoubleToStr(Bid, Digits) + " Close Buy");
               IsTrade = False;
               continue;
            }
            //Trailing stop
            if(UseTrailingStop && TrailingStop > 0) {                 
               if(Bid - OrderOpenPrice() > P * Point * TrailingStop) {
                  if(OrderStopLoss() < Bid - P * Point * TrailingStop) {
                     Ticket2 = OrderModify(OrderTicket(), OrderOpenPrice(), Bid - P * Point * TrailingStop, OrderTakeProfit(), 0, MediumSeaGreen);
                     continue;
                  }
               }
            }
         } else {
            //Close

            //+------------------------------------------------------------------+
            //| Inicio de Señal (Salir de la venta)                              |
            //+------------------------------------------------------------------+

            if (sma40_2 > sma10_2 && sma10_1 >= sma40_1) Order = SIGNAL_CLOSESELL; // Rule to EXIT a Short trade

            //+------------------------------------------------------------------+
            //| Finde nuesta señal (Salida venta)                                |
            //+------------------------------------------------------------------+

            if (Order == SIGNAL_CLOSESELL) {
               Ticket2 = OrderClose(OrderTicket(), OrderLots(), Ask, Slippage, DarkOrange);
               if (SignalMail) SendMail("[Signal Alert]", "[" + Symbol() + "] " + DoubleToStr(Ask, Digits) + " Close Sell");
               IsTrade = False;
               continue;
            }
            //Trailing stop
            if(UseTrailingStop && TrailingStop > 0) {                 
               if((OrderOpenPrice() - Ask) > (P * Point * TrailingStop)) {
                  if((OrderStopLoss() > (Ask + P * Point * TrailingStop)) || (OrderStopLoss() == 0)) {
                     Ticket2 = OrderModify(OrderTicket(), OrderOpenPrice(), Ask + P * Point * TrailingStop, OrderTakeProfit(), 0, DarkOrange);
                     continue;
                  }
               }
            }
         }
      }
   }

   //+------------------------------------------------------------------+
   //| Inicio de Señal (Entradas)                                       |
   //+------------------------------------------------------------------+
   
   /* REGLAS DE ENTRADA ADELINE:
       operación larga cuando SMA (10) cruza SMA (40) desde abajo
      operación corta cuando SMA (10) cruza SMA (40) desde la parte superior
    */

    // reglas de entrada de código
   
   if (sma40_2 > sma10_2 && sma10_1 >= sma40_1) Order = SIGNAL_BUY; // Rule to ENTER a Long trade

   if (sma10_2 > sma40_2 && sma40_1 >= sma10_1) Order = SIGNAL_SELL; // Rule to ENTER a Short trade


   //+------------------------------------------------------------------+
   //| Señal de salida                                                  |
   //+------------------------------------------------------------------+

   //Comprar
   if (Order == SIGNAL_BUY) {
      if(!IsTrade) {
         //Check free margin
         if (AccountFreeMargin() < (1000 * Lots)) {
            Print("We have no money. Free Margin = ", AccountFreeMargin());
            return(0);
         }

         if (UseStopLoss) StopLossLevel = Ask - StopLoss * Point * P; else StopLossLevel = 0.0;
         if (UseTakeProfit) TakeProfitLevel = Ask + TakeProfit * Point * P; else TakeProfitLevel = 0.0;

         Ticket = OrderSend(Symbol(), OP_BUY, Lots, Ask, Slippage, StopLossLevel, TakeProfitLevel, "Buy(#" + MagicNumber + ")", MagicNumber, 0, DodgerBlue);
         if(Ticket > 0) {
            if (OrderSelect(Ticket, SELECT_BY_TICKET, MODE_TRADES)) {
				Print("BUY order opened : ", OrderOpenPrice());
                if (SignalMail) SendMail("[Signal Alert]", "[" + Symbol() + "] " + DoubleToStr(Ask, Digits) + " Open Buy");
			} else {
				Print("Error opening BUY order : ", GetLastError());
			}
         }
         return(0);
      }
   }

   //Vender
   if (Order == SIGNAL_SELL) {
      if(!IsTrade) {
         //Check free margin
         if (AccountFreeMargin() < (1000 * Lots)) {
            Print("We have no money. Free Margin = ", AccountFreeMargin());
            return(0);
         }

         if (UseStopLoss) StopLossLevel = Bid + StopLoss * Point * P; else StopLossLevel = 0.0;
         if (UseTakeProfit) TakeProfitLevel = Bid - TakeProfit * Point * P; else TakeProfitLevel = 0.0;

         Ticket = OrderSend(Symbol(), OP_SELL, Lots, Bid, Slippage, StopLossLevel, TakeProfitLevel, "Sell(#" + MagicNumber + ")", MagicNumber, 0, DeepPink);
         if(Ticket > 0) {
            if (OrderSelect(Ticket, SELECT_BY_TICKET, MODE_TRADES)) {
				Print("Orden de Venta abierta : ", OrderOpenPrice());
                if (SignalMail) SendMail("[Signal Alert]", "[" + Symbol() + "] " + DoubleToStr(Bid, Digits) + " Open Sell");
			} else {
				Print("Error en apertura de venta : ", GetLastError());
			}
         }
         return(0);
      }
   }

   return(0);
}
//+------------------------------------------------------------------+
