/**
 * Filter Mapping Visualisation
 * 
 * A close-to-realtime visualisation of the mapping between 
 * the device's mailboxes and the logging list.
 *
 * Also transmits the logging list to the device over RS232
 * as a form of remote configuration
 *
 */
 
/* Serial port definitions */ 
import processing.serial.*;
Serial myPort;                       
int[] serialInArray = new int[1000];    
int serialCount = 0;

File lastFile;

/* Global state flags */
boolean readyState = false;
int status = 0;
boolean allRefresh = false;
int hsCount = 0;

/* fonts */
PFont font, fontBold;

/* standard positioning values and indexing vars */
int d = 15;  
int s = 200;
int w = 900;
int i,j;

/* This array holds the variable end positions for the mapping lines (logging list end) */
int[] mapLineEnd = new int[64];

/* This array holds the variable ID's in the device mailboxes */
int[] IDs = new int[64];

/* logging list transmission progress */
int txPointer = 0;

/* Config */
int filterSizeTx = 2;
int duplicatesAllowed = 1;

//int[][] loggingList = {
//  {0x050,1,100},
////  {0x101,1,100},
//  {0x185,8,100},
//  {0x187,8,100},
//  {0x188,8,100},
//  {0x189,8,100},
//  {0x18A,8,100},
//  {0x18B,8,100},
//  {0x18C,8,100},
//  {0x18D,8,100},
//  {0x18E,8,100},
//  {0x190,8,100},
//  {0x192,8,100},
//  {0x205,8,100},
//  {0x207,8,100},
//  {0x209,8,100},
//  {0x20B,8,100},
//  {0x20D,8,100},
//  {0x287,8,100},
//  {0x289,8,100},
//  {0x28B,8,100},
//  {0x28D,8,100},
//  {0x307,8,100},
//  {0x309,8,100},
//  {0x30B,8,100},
//  {0x30D,8,100},
//  {0x385,8,100},
//  {0x387,8,100},
//  {0x389,8,100},
//  {0x38B,8,100},
//  {0x38D,8,100},
//  {0x407,8,100},
//  {0x409,8,100},
//  {0x40B,8,100},
//  {0x40D,8,100},
//  {0x487,8,100},
//  {0x489,8,100},
//  {0x48B,8,100},
//  {0x48D,8,100},
//  {0x507,8,100},
//  {0x509,8,100},
//  {0x50B,8,100},
//  {0x50D,8,100},
//  {0x705,1,100},
//  {0x707,1,100},
//  {0x709,1,100},
//  {0x70B,1,100},
//  {0x70D,1,100}
//};

/* The logging list. This is transmitted to the device for filter configuration */
//int[][] loggingList = {
//  {0x187,8,20},
//  {0x188,8,20},
//  {0x189,8,20},
//  {0x18A,8,20},
//  {0x18B,8,20},
//  {0x18C,8,20},
//  {0x18D,8,20},
//  {0x18E,8,20},
//  {0x207,8,20},
//  {0x209,8,20},
//  {0x20B,8,20},
//  {0x20D,8,20},
//  {0x287,8,20},
//  {0x289,8,20},
//  {0x28B,8,20},
//  {0x28D,8,20},
//  {0x307,8,20},
//  {0x309,8,20},
//  {0x30B,8,20},
//  {0x30D,8,20},
//  {0x385,8,20},
//  {0x387,8,20},
//  {0x389,8,20},
//  {0x38B,8,20},
//  {0x38D,8,20},
//  {0x407,8,20},
//  {0x409,8,20},
//  {0x40B,8,20},
//  {0x40D,8,20},
//  {0x707,1,100},
//  {0x709,1,100},
//  {0x70B,1,100},
//  {0x70D,1,100},  
//};  

/* The logging list. This is transmitted to the device for filter configuration */
int[][] loggingList = {
  {80,0,20},
  {389,8,20},
  {391,8,20},
  {392,8,20},
  {393,8,20},
  {394,8,20},
  {395,8,20},
  {396,8,20},
  {397,8,20},
  {398,8,20},
  {519,8,20},
  {521,8,20},
  {523,8,20},
  {525,8,20},
  {647,8,20},
  {649,8,20},
  {651,8,20},
  {653,8,20},
  {775,8,20},
  {777,8,20},
  {779,8,20},
  {781,8,20},
  {901,8,20},
  {903,8,20},
  {905,8,20},
  {907,8,20},
  {909,8,20},
  {1031,8,20},
  {1033,8,20},
  {1035,8,20},
  {1037,8,20},
  {1799,1,100},
  {1801,1,100},
  {1803,1,100},
  {1805,1,100},
};

/* counters for counting */
long[] counters = new long[loggingList.length];
long[] countersTemp = new long[loggingList.length];
long countersTotal = 0;
  
/* the number of mailboxes used for the filter (this should be half the number of IDs in the logging list */
int filterSizeRx = 0;

void setup(){
  if(loggingList.length > 64){
    println("Logging list too long: Max 64 IDs. Cannot continue.");
    exit();
  }
  else{
    /* Serial port will be Serial.list()[0] when nothing else connected */
    try{
      println(Serial.list());
      String portName = Serial.list()[0];
      myPort = new Serial(this, portName, 9600);
    }
    catch(Exception e){
      /* App will close if no serial ports are found */
      println("No serial ports found. Use your dongle!");
      exit();
    }
    
    size(1200, 1000);
    background(0);
    font = loadFont("Consolas-16.vlw");
    fontBold = loadFont("Consolas-Bold-16.vlw");
    textFont(font, 12);    
    stroke(153);
    /* draw handled manually by RS232 reception */    
    noLoop();
  }
}

void delay_ms(int ms){
  long lastTime = millis();
  while (millis()-lastTime < ms);
}

int standardSpacingY(int mult, int offset){
  return ((d*mult)+(2*d)+offset);
}

String intToStr_02(int num){
  String returnStrg;
  
  if(i<10){
    returnStrg = (" 0"+num);
  }
  else{
    returnStrg = (" "+str(num));
  }
  
  return returnStrg;
}

void draw(){
  int barLength = 0;
  String strg = "";

  
  try{
    /* Mailbox and logging list blocks */
    background(10);    
    stroke(255);
    fill(20);
    rect((s-((4*d)+110)), 2, s-d-(s-((4*d)+110)), 25+(filterSizeRx*d),10);
    rect(w+d, 2, 250, 2*d+(loggingList.length*d),10);
    
    stroke(255);
    fill(255);
    textFont(fontBold, 14);
    text("Device Mailboxes", (s-((4*d)+100)), (d+4));
    text(" Logging List      Hits", (w+d+3), (d+4));

    if(allRefresh == true){
      countersTotal = 0;
    }
    
    /* Draws logging list details */
    for(i=0;i<loggingList.length;i++){
      
      if(allRefresh == true){
        counters[i] = countersTemp[i];
        countersTotal += counters[i];
      }
      
      stroke(45);
      line(0, standardSpacingY(i,d/2), 1200, standardSpacingY(i,d/2));   
      stroke(255);
      strg = intToStr_02(i);
      text(strg+": "+hex(loggingList[i][0],3)+"           "+counters[i], (w+d+5), standardSpacingY(i,6));
      line(w, standardSpacingY(i,0), (w+d), standardSpacingY(i,0));
    }
    
    /* Draws device filter information and mapping lines */
    textFont(fontBold, 12);    
    for(i=0;i<filterSizeRx;i++){
      /* Text and leader lines */
      strg = intToStr_02(i);
      text(strg+": "+hex(IDs[i],3), (s-((4*d)+20)), standardSpacingY(i,6));
      stroke(255);
      line(s, standardSpacingY(i,0), (s-d), standardSpacingY(i,0));
      
      /* Mapping lines */    
      line(s, standardSpacingY(i,0), w, mapLineEnd[i]);   
    } 

    /* Title and status block */
    fill(0);
    rect((s-((4*d)+110)), standardSpacingY(53,15), 760, 150, 10);
    fill(255);  
    
    switch(status){
    case 0:
      strg = "Offline - Can't see device";
      break;      
    case 1:
      strg = "Offline - Device waiting\nPress 'R' to begin.";
      break;
    case 2:
      strg = "Transmitting logging list: ";   
      if(txPointer>6){
       strg += txPointer-6; 
       rect((s-((4*d)+100)), standardSpacingY(61,15), (740/(loggingList.length/(txPointer-6))), 6);
      }
      break;
    case 3:
      strg = "Online\nPress 'R' to reset, 'S' to save hit counts, 'C' to save and close, 'X' to exit without saving.\nTotal hits: ";
      strg += countersTotal;
      break;
    case 4:
      strg = "Connection lost - press 'R' to reset";
    default:
      break; 
    }
    
    textFont(fontBold, 16);
    text("Dynamic CAN Filter Mapping Visualisation", (s-((4*d)+100)), standardSpacingY(55,6));
    textFont(fontBold, 14);
    text("Chris Barlow, MSc Reliable Embedded Systems 2013, University of Leicester", (s-((4*d)+100)), standardSpacingY(56,8));
    textFont(font, 14);
    text("This application displays the CAN mailbox to logging list mapping.", (s-((4*d)+100)), standardSpacingY(58,6));
    text("Logging list is sent to the device on connection", (s-((4*d)+100)), standardSpacingY(59,6));
    textFont(fontBold, 14);
    text("Status: "+strg, (s-((4*d)+100)), standardSpacingY(61,6));
    
    allRefresh = false;  
    
  }
  catch(Exception e){
    exit();
  }
}

void transmitLoggingList(){
  int txListPointer;


  /* *
  * Data packet looks like this:
  *      0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
  *     "{ f d a a A X b b B  Y  c  c  C  Z  ~  }" where:
  *     f is the filter size control constant
  *     d is the duplication control constant
  *    aa is two byte CAN ID
  *     A is the CAN data length
  *    X is the CAN message cycle time
  *    etc
  * */
  print(txPointer+" ");
  if(txPointer == 0){
    myPort.write('{');
    println("{");
  }
  else if(txPointer == 1){
    myPort.write(filterSizeTx);
    println(filterSizeTx);
  }
  else if(txPointer == 2){
    myPort.write(duplicatesAllowed);
    println(duplicatesAllowed);
  } 
  else if(txPointer < loggingList.length+3){
    txListPointer =  txPointer-3;
    /* CAN ID high byte */
    myPort.write((loggingList[txListPointer][0]>>8)&0x87);
    /* CAN ID low byte */
    myPort.write (loggingList[txListPointer][0]&0xFF);
    /* Message length in bytes */
    myPort.write (loggingList[txListPointer][1]&0xFF);
    /* Message cycle time */
    myPort.write (loggingList[txListPointer][2]&0xFF);
    
    println(hex((loggingList[txListPointer][0]>>8)&0xFF,1)+" "+hex(loggingList[txListPointer][0]&0xFF,2)+" "+hex(loggingList[txListPointer][1]&0xFF,2)+" "+hex(loggingList[txListPointer][2]&0xFF,2));
  }
  else if(txPointer == (loggingList.length+3)){
    myPort.write('~');
    println("~");
  }
  else if(txPointer == (loggingList.length+4)){
    myPort.write('}');
    println("}");

  }
  else{
   println("got here");
  } 
}

void receiveLoggingDetails(){
  int loggingListPointer = 0;
  int IDhPointer,IDlPointer,lineEndPointer, txListPointer;
  long messageCounter = 0; 
          
          /* First character of packet after { indicates packet type */
          switch(serialInArray[1]){ 
               
          case 'M': 
          /* Data packet contains mailbox information */
          
            if(serialCount-3 == 1){
              filterSizeRx = 1;
            }
            else{
              filterSizeRx = (serialCount-3)/3;
            }
            
            for(loggingListPointer=0;loggingListPointer<filterSizeRx;loggingListPointer++){
              IDhPointer = (3*loggingListPointer)+2;
              IDlPointer = (3*loggingListPointer)+3;
              lineEndPointer = (3*loggingListPointer)+4;
              
              IDs[loggingListPointer] = ((serialInArray[IDhPointer]<<8) | serialInArray[IDlPointer]);
              mapLineEnd[loggingListPointer] = standardSpacingY(serialInArray[lineEndPointer],0);
            }
            break;
                   
          case 'S':
          /* Data packet contains loggingList information */ 
           
            loggingListPointer = serialInArray[2];
//            println(loggingListPointer);
            
            if(loggingListPointer < loggingList.length){
              /* Unpack 32 bit counter */
              messageCounter  = ((serialInArray[3]&0xFF)<<24);
              messageCounter |= ((serialInArray[4]&0xFF)<<16);
              messageCounter |= ((serialInArray[5]&0xFF)<<8);
              messageCounter |=  (serialInArray[6]&0xFF);
               
              /* counters stored in temp array until refresh required */
              countersTemp[loggingListPointer] = messageCounter;
              
              /* Only refresh loggingList counters on screen when all counters have been received (takes several packets) */
              if(loggingListPointer >= (loggingList.length-1)){
                allRefresh = true;
              }
            }
      
            break;
            
          case '~':
            /* Empty serial packet instructs screen refresh */
            redraw();
            break;
            
          default:        
            break;
          }
                  

}

void serialEvent(Serial myPort) {

  try{

    if(serialCount == 0){
      for(j=0;j<serialInArray.length;j++){
        serialInArray[j] = 0;
      }
    }

    /* read a byte from the serial port: */
    serialInArray[serialCount] = myPort.read();
//    println(serialInArray[serialCount]);
    
    /* Device sends '?' character as a handshake / logging list request */
    if(serialInArray[serialCount] == '?'){
    
      /* Prevents '63' values in data stream from being misinterpreted as a handshake request */ 
      if(hsCount < 10){
        hsCount++;
      }
      else{
        hsCount = 0; 
        if(status == 0){ 
          status = 1;
        }
        /* if we are in online state, we know that the device has been reset */
        else if(status == 3){
          status = 4;
        }
        print("HS ");
      }    
    }
    else{
      hsCount = 0;
    }
    
    
    switch(status){
    /* Offline */
    case 0:
    case 4:
      /* App offline */
      serialCount = 0;
      txPointer = 0;
      delay_ms(5);
      /* Handshake signals device to wait for new filter information */
      myPort.write('?');
      if(readyState==false){
        status = 0;
      }
      redraw();
     break;
          
    /* Offline but Device found */
    case 1:
      myPort.write('?');
      if(readyState==true){
          txPointer = 0;        
          status = 2;   
      }
      redraw();
      break;
    /* Transmitting logging list */
    case 2:
      if(readyState==true){
        /* this delay is necesssary for the TI chip to keep up when it receives erroneous null characters */ 
        if((serialInArray[0] == '?')&&(txPointer <= (loggingList.length+4))){
          delay_ms(5);
          transmitLoggingList();
          txPointer++;
          redraw();
        }
        else if(serialInArray[0] == '{'){
          println("got here");
          status = 3;
        }
        else{
          println("staying here");
        }
      }
      else{
        serialCount = 0;
        status = 0;
        redraw();
      }
      break;
    /* Online */
    case 3:
      
      if(readyState==true){
      /* End of data packet - update data arrays */
        if((serialCount>0)&&(serialInArray[serialCount-1] == '~')&&(serialInArray[serialCount] == '}')){
          receiveLoggingDetails();
          serialCount = 0;
        }      
        /* Receiving data packet from TI chip */
        else if((serialInArray[0] == '{') && (serialCount < 999)){
            serialCount++;
        }  
      }
      else{
        serialCount = 0;
        status = 0;
        redraw();
      }
      break;
      
    default:
      break;
    }
    
   
//     println("A"+serialInArray[0]);
//     println("S"+status);
  
  }
  catch(Exception e){
    exit();
  }
}

/* keyboard controls */
void keyPressed() {  
  int k;
  
  /* Reset */
  if((key == 'r')||(key == 'R')){
     readyState = !readyState;
     println(readyState);
     for(k=0;k<filterSizeRx;k++){
        IDs[k] = 0x000;
        mapLineEnd[k] = standardSpacingY(k,0);
     }
     
     for (k = 0; k < loggingList.length; k++) {
      counters[k] = 0;
    }
    filterSizeRx = 0;
//    status = 0;
    redraw();
  }
  
  /* Save */
  if((key == 's')||(key == 'S')){
//    saveCounters();
    selectOutput("Select file","saveCounters",lastFile);
  } 
  
  /* Close and save */
  if((key == 'c')||(key == 'C')){
//    saveCounters();
    exit(); // Stop the program
  } 
  
  /* Exit without saving */
  if((key == 'x')||(key == 'X')){
    exit(); // Stop the program
  } 

  /* save frame image */
  if((key == 'f')||(key == 'F')){
    saveFrame("output/frames####.png");
  }
}


/* Save counters to text file */
void saveCounters(File selection){
  int k;
  String[] lines = new String[loggingList.length+1];
  
  for (k = 0; k < loggingList.length; k++) {
      lines[k] = (hex(loggingList[k][0],3)+","+counters[k]);
  }
  
  lines[k] = ("Total,"+countersTotal);
  
  if(selection != null){
    saveStrings(selection, lines);
    lastFile = selection;
  }
}
  
