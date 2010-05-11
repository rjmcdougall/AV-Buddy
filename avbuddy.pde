

/*
 * Reset Remote: tivo+power, thumbs-down 3 times, enter
 * Enter Denon Code: tivo+mute 1041
 */

// include the SoftwareSerial library so you can use its functions:
#include <RMCSoftSerial.h>
#include <IRremote.h>
#include <IRremoteInt.h>

#define RX1_PIN 6
#define TX1_PIN 7
#define TX2_PIN 8
#define RX2_PIN 5

// set up a new serial port
RMCSoftSerial SSerial1(RX1_PIN, TX1_PIN);
RMCSoftSerial SSerial2(RX2_PIN, TX2_PIN);
byte pinState = 0;

#define LED_PIN 9
int led = 0;

#define IR_PIN 4
IRrecv irrecv(IR_PIN);
IRsend irsend;
decode_results results;
// Storage for the recorded code
int codeType = -1; // The type of code
unsigned long codeValue; // The code value if not raw
unsigned int rawCodes[RAWBUF]; // The durations if raw
int codeLen; // The length of the code
int toggle = 0; // The RC5/6 toggle state



// Stores the code for later playback
// Most of this code is just logging
void storeCode(decode_results *results) {
  codeType = results->decode_type;
  int count = results->rawlen;
  if (codeType == UNKNOWN) {
    Serial.println("Received unknown code, saving as raw");
    codeLen = results->rawlen - 1;
    // To store raw codes:
    // Drop first value (gap)
    // Convert from ticks to microseconds
    // Tweak marks shorter, and spaces longer to cancel out IR receiver distortion
    for (int i = 1; i <= codeLen; i++) {
      if (i % 2) {
        // Mark
        rawCodes[i - 1] = results->rawbuf[i]*USECPERTICK - MARK_EXCESS;
        Serial.print(" m");
      } 
      else {
        // Space
        rawCodes[i - 1] = results->rawbuf[i]*USECPERTICK + MARK_EXCESS;
        Serial.print(" s");
      }
      Serial.print(rawCodes[i - 1], DEC);
    }
    Serial.println("");
  }
  else {
    if (codeType == NEC) {
      Serial.print("Received NEC: ");
      if (results->value == REPEAT) {
        // Don't record a NEC repeat value as that's useless.
        Serial.println("repeat; ignoring.");
        return;
      }
    } 
    else if (codeType == SONY) {
      Serial.print("Received SONY: ");
    } 
    else if (codeType == RC5) {
      Serial.print("Received RC5: ");
    } 
    else if (codeType == RC6) {
      Serial.print("Received RC6: ");
    } 
    else {
      Serial.print("Unexpected codeType ");
      Serial.print(codeType, DEC);
      Serial.println("");
    }
    Serial.println(results->value, HEX);
    codeValue = results->value;
    codeLen = results->bits;
  }
}

void my_delay(int usecs) {
  for (;usecs > 30; usecs -=30) {
    if (led == 0) {
      digitalWrite(LED_PIN, HIGH);   // set the LED on
      led = 1; 
    } else {
      digitalWrite(LED_PIN, LOW);   // set the LED off
      led = 0;
    }
    delay(30);
  }
  delay(usecs);
}

const uint8_t  tv_on_codes[7] =  { 0x08, 0x22,  0x00, 0x00, 0x00, 0x02, 0xd4 };
const uint8_t tv_off_codes[7] = { 0x08, 0x22, 0x00, 0x00, 0x00, 0x01, 0xd5 };
const uint8_t tv_hdmi_codes[7] = { 0x08, 0x22, 0x0a, 0x00, 0x05, 0x00, 0xc7 };

/*
 * Switch TV on and off
 * 0 = off
 * 1 = on
 * 2 = set default
 */
void switch_tv(int mode) {
  
  if (mode == 1) {
    // Switch ON
    SSerial1.write(tv_on_codes, 7);
    my_delay(200);
    SSerial1.write(tv_on_codes, 7);
    my_delay(2000);
  } else if (mode == 2) {
    SSerial1.write(tv_hdmi_codes, 7);
    my_delay(200);
    SSerial1.write(tv_hdmi_codes, 7);
    my_delay(200);
  } else {
    // Switch OFF
    SSerial1.write(tv_off_codes, 7);
    my_delay(100);
    SSerial1.write(tv_off_codes, 7);
    my_delay(2000);
  }
}
  
#define AMP_ON   "ZMON"  //ZMON
#define AMP_OFF  "ZMOFF" //ZMOFF
#define AMP_VOL  "MV50"
#define AMP_TIVO  "SITV"
#define AMP_APPLE "SIVCR-1"
#define AMP_DVD  "SIDVD"
#define AMP_WII  "SIVCR-2"
#define Z2_ON    "Z2ON"
#define Z2_OFF   "Z2OFF"
#define Z2_TIVO  "Z2TV"
#define Z2_AIRPORT "Z2V.AUX"

/* 
 * Send to amp serial port
 */
void amp_serial(char *string) {
  SSerial2.print(string);
  SSerial2.print(13, BYTE);
}

int imp = 1;
#define INP_TIVO  1
#define INP_DVD   2
#define INP_APPLE 3
#define INP_WII   4


/*
 * Switch AMP on and off
 * 0 = off
 * 1 = on
 * 2 = set default
 */
void switch_amp(int mode) {
  
  if (mode == 1) {
    // Switch ON
    amp_serial(AMP_ON);
    my_delay(200);
    amp_serial(AMP_ON);
    my_delay(4000);
  } else if (mode == 2) {
    // Set AMP Defaults
    amp_serial(AMP_VOL);
    my_delay(200);
    amp_serial(AMP_VOL);
    my_delay(200);
    amp_serial(AMP_TIVO);
    my_delay(200);
    amp_serial(AMP_TIVO);
    imp = 1;
    my_delay(200);
  } else {
    // Switch OFF
    amp_serial(AMP_OFF);
    my_delay(200);
    amp_serial(AMP_OFF);
    my_delay(2000);
  }
}  


/*
 * Switch ZA on and off
 * 0 = off
 * 1 = on
 * 2 = airport
 * 3 = tivo
 */
void switch_z2(int mode) {
  
  if (mode == 1) {
    // Switch ON
    amp_serial(Z2_ON);
    my_delay(200);
    amp_serial(Z2_ON);
    my_delay(4000);
  } else if (mode == 2) {
    amp_serial(Z2_AIRPORT);
    my_delay(200);
    amp_serial(Z2_AIRPORT);
    my_delay(200);
  } else if (mode == 3) {
    amp_serial(Z2_TIVO);
    my_delay(200);
    amp_serial(Z2_TIVO);
    my_delay(200);
  } else {
    // Switch OFF
    amp_serial(Z2_OFF);
    my_delay(200);
    amp_serial(Z2_OFF);
    my_delay(4000);
  }
}



/*
 * Switch AMP input
 * 1 = TIVO
 * 2 = APPLE
 * 3 = DVD
 */
void switch_amp_input(int mode) {
  
  if (mode == 1) {
    // TIVO
    amp_serial(AMP_TIVO);
  } else if (mode == 2) {
    // APPLE
    amp_serial(AMP_APPLE);
  } else if (mode == 3) {
    // DVD
    amp_serial(AMP_DVD);
  }else {
    // WII
    amp_serial(AMP_WII);
  }
  my_delay(100);
}     
    

    
void setup()
{
  // set pins 0-8 for digital input

//  for (int i = 0; i <= 9; ++i)
//    pinMode(i, INPUT);

  pinMode(TX1_PIN, OUTPUT);
  pinMode(TX1_PIN, OUTPUT);
  pinMode(LED_PIN, OUTPUT);
  pinMode(IR_PIN, INPUT);
  
  irrecv.enableIRIn(); // Start the receiver  
  
//  irrecv.enableIRIn(); // Start the receiver
  Serial.begin(9600);
  SSerial1.begin(9600);
  SSerial2.begin(9600);
  
  Serial.println("fv: booted");

}

#define AMP_PWR_PIN 1
#define TV_PWR_PIN  0

#define PINK_PIN 3
#define GREEN_PIN 4
#define BLUE_PIN 5



#define IS_ON(X) (((X) > 1000))
#define IS_OFF(X) (((X) < 900))
#define IS_PRESSED(X) (((X) == 0))

int amp_on_last = -1;
int tv_on_last = -1;
int pink_last = 0;
int green_last = 0;
int blue_last = 0;



int state = -1;

/*
 * State machine
 */
#define TOFF_AOFF 1
#define TON_AOFF  2
#define TON_AON   3
#define TOFF_AON  4


int z2 = 1;

void loop()
{

  char webbuffer[256];
  int bufflen = 256;
  int tv;
  int amp;
  int blue;
  int pink;
  int green;
  int ir_inpbutton = 0;
  int ir_powbutton = 0;
  int pink_pressed;
  int green_pressed;
    
  irrecv.blink13(1);
  
  if (irrecv.decode(&results)) {
    storeCode(&results);
    Serial.println("Received IR");
    if ((results.decode_type == NEC) && (results.value == 0x20DF906F)) {
//    if ((results.decode_type == NEC) && (results.value == 0xA10C2C83)) {
    Serial.println("Received IR tivo inp button");
    ir_inpbutton = 1;
    }
    if ((results.decode_type == NEC) && (results.value == 0x20DF10EF)) {
//    if ((results.decode_type == NEC) && (results.value == 0xA10C0887)) {
    Serial.println("Received IR tivo power button");
    ir_powbutton = 1;
    }    
  irrecv.resume();
  }
  
  delay(50);
  
//  Serial.println("");
  
  amp = analogRead(AMP_PWR_PIN);    
  tv = analogRead(TV_PWR_PIN);     

  pink = analogRead(PINK_PIN);
  blue = analogRead(BLUE_PIN);
  green = analogRead(GREEN_PIN);

  if (tv_on_last == -1) {
    tv_on_last = IS_ON(tv);
    if (tv_on_last) {
      Serial.println("TV is on");
    } else {
      Serial.println("TV is off");
    }
  }
  
  if (amp_on_last == -1) {
    amp_on_last = IS_ON(amp);
    if (amp_on_last) {
      Serial.println("AMP is on");
    } else {
      Serial.println("AMP is off");
    }
  }

  // Set initial state
  if (state == -1) {
    if (IS_OFF(amp) && IS_OFF(tv)) {
      state = 1;
    } else if (IS_ON(tv) && IS_OFF(amp)) {
      state = 2;
    } else if (IS_ON(tv) && IS_ON(amp)) {
      state = 3;
    } else if (IS_OFF(tv) && IS_ON(amp)) {
      state = 4;
    }
  }

  pink_pressed = IS_PRESSED(pink);
  if (((pink_last == 0) && pink_pressed) || ir_powbutton) {
    if (pink_pressed) {
      pink_last = 1;
    }
    Serial.println("Pink pressed");
    if ((state == 1) || (state == 2) || (state == 4)) {
      Serial.println("Turning ALL on");
      switch_tv(1); // Turn on tv
      switch_amp(1); // Turn on amp
      switch_amp(2); // Set amp defaults
      switch_tv(2); // Set tv defaults
      state = 3;
    } else if (state == 3) { 
      // Turn all off
      Serial.println("Turning ALL off");
      switch_tv(0); // Turn TV off
      switch_amp(0); // Turn AMP off
      my_delay(4000);
      state = 1;
    }
  }
  if ((pink_last == 1) && !IS_PRESSED(pink)) {
    pink_last = 0;
    Serial.println("Pink released");
  }
  
  green_pressed = IS_PRESSED(green);
  if ((green_last == 0) && green_pressed || ir_inpbutton) {
    if (green_pressed) {
      green_last = 1;
    }
    Serial.println("green pressed");
    if (imp == 1) {
      Serial.println("Selecting Apple");
      switch_amp_input(2);
      imp = 2;
    } else if (imp == 2) { 
      Serial.println("Selecting DVD");
      switch_amp_input(3);
      imp = 3;
    } else if (imp == 3) {
      Serial.println("Selecting WII");
      switch_amp_input(4);
      imp = 4;
    } else if (imp == 4) {
      Serial.println("Selecting TIVO");
      switch_amp_input(1);
      imp = 1;
    }
  }
  if ((green_last == 1) && !IS_PRESSED(green)) {
    green_last = 0;
    Serial.println("green released");
  }
  
  if ((blue_last == 0) && IS_PRESSED(blue)) {
    blue_last = 1;
    Serial.println("blue pressed");
    if (z2 == 1) {
      Serial.println("Turning on Z2");
      switch_z2(1);
      switch_z2(2);
      z2 = 2;
    } else if (z2 == 2) { 
      Serial.println("Z2 TIVO");
      switch_z2(3);
      z2 = 3;
    } else if (z2 == 3) {
      Serial.println("Z2 OFF");
      switch_z2(0);
      z2 = 1;
    }
  }
  if ((blue_last == 1) && !IS_PRESSED(blue)) {
    blue_last = 0;
    Serial.println("blue released");
  }
  
  // AMP State sense off -> on
  if ((amp_on_last == 0) && IS_ON(amp)) {
    Serial.println("Amp on detected");
    amp_on_last = 1;
    if (state == 1) {
      Serial.println("Turning TV on");
      switch_amp(2); // Set defaults
      switch_tv(1); // Turn on tv
      my_delay(8000);
      switch_tv(2); // Set tv defaults
      state = 3;
    }
    if (state == 2) { 
      // TV already on
      state = 3;
    }
  }
  
  // Amp State sense on -> off
  if ((amp_on_last == 1) && IS_OFF(amp)) {
    Serial.println("Amp off detected");
    amp_on_last = 0;
    if (state == 3) {
      Serial.println("Turning TV off");
      switch_tv(0); // Turn TV off
      state = 1;
    }
    if (state == 4) {
      // TV already off
      state = 1; 
    }
  } 

  // TV State sense off -> on  
  if ((tv_on_last == 0) && IS_ON(tv)) {
    tv_on_last = 1;
    Serial.println("TV on detected");
    if (state == 1) {
      Serial.println("Turning AMP on");
      switch_amp(1); // Turn on amp
      switch_amp(2); // Set amp defaults
      switch_tv(2); // Set tv defaults
      state = 3;
    } 
    if (state == 4) {
      // Amp already on
      state = 3;
    }
  }

  // TV State sense on -> off  
  if ((tv_on_last == 1) && IS_OFF(tv)) {
    Serial.println("TV off detected");
    tv_on_last = 0;
    if (state == 3) {
      Serial.println("Turning AMP off");
      switch_amp(0); // Turn AMP off
      state = 1;
    }
    if (state == 2) { 
      // Amp already off
      state = 1;
    }
  }
  
  digitalWrite(LED_PIN, LOW);   // set the LED off



/*
  Serial.println("");
  Serial.print("Values amp: ");
  Serial.print(amp, DEC);
  Serial.print(" tv:");
  Serial.print(tv, DEC);
  Serial.print(" pink:");
  Serial.print(pink, DEC);
  Serial.print(" green:");
  Serial.print(green, DEC);
  Serial.print(" blue:");
  Serial.print(blue, DEC);
  */
}

