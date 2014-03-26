#include <SPI.h>
#include <Ethernet.h>

// network config
byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
IPAddress ip(192,168,1, 30);

// DHT stuff
int MAXTIMINGS = 85;

EthernetServer server(80);

boolean read(int);
long readTemperature(void);
long readHumidity(void);

// array of pins where a dht22 is connected
int roomPins[] = {2,3,4,5};
const int roomPins_size = sizeof(roomPins)/sizeof(int); //this is the numer of elements

// tmp en hum are longs, not decimal, need to be divided by 10
struct sensors{
  short pin;
  float tmp;
  float hum;
	uint8_t sdata[6];
  long lastReadtime;
	boolean firstreading;
}sensor[roomPins_size];

// setup
void setup()
{
  Ethernet.begin(mac, ip);
  server.begin();
  Serial.begin(9600);

	// initialize sensorpin structs
	for ( int i=0; i < roomPins_size; i++) {
                
                Serial.print("i=");
                Serial.print(i);
                Serial.print(" pin:");
                Serial.println(roomPins[i]);
                
		sensor[i].pin=roomPins[i];
		sensor[i].firstreading = true;
	}
}

// loop
void loop()
{
  
  long lastReadingTime;
  String sensors_output;

  // listen for incoming clients
  EthernetClient client = server.available();
  if (client) {
    // an http request ends with a blank line
    boolean currentLineIsBlank = true;
    while (client.connected()) {
      if (client.available()) {
	        char c = client.read();
 	       // if you've gotten to the end of the line (received a newline
 	       // character) and the line is blank, the http request has ended,
 	       // so you can send a reply
	        if (c == '\n' && currentLineIsBlank) {
 	         // send a standard http response header
	         client.println("HTTP/1.1 200 OK");
 	  	 client.println("Content-Type: text/html");
 	         client.println();
          
					// time to get the sensors
					// loop and build sensors_putput string
					if (millis() - lastReadingTime > 5000){
					  for (int i=0; i < roomPins_size; i++) {
                                                        //Serial.print("going to read ");
                                                        //Serial.println(sensor[i].pin);
                                                        
                                                        boolean  rev=read(i);
							if ( !rev ) {
								Serial.print("Sensor read failed: sensor pin ");
								Serial.println(sensor[i].pin);
							}
							client.print("room");
							client.print(i);
							client.print(" temp:");
							client.print(sensor[i].tmp);
							client.print(" humi:");
							client.print(sensor[i].hum);
					    client.println("<br>");
          		sensor[i].lastReadtime = millis();
  				  }
					}
					break;
				}
        if (c == '\n') {
          // you're starting a new line
          currentLineIsBlank = true;
        } 
        else if (c != '\r') {
          // you've gotten a character on the current line
          currentLineIsBlank = false;
        }
      }
    }
    // give the web browser time to receive the data
    delay(1);
    // close the connection:
    client.stop();
  }
}

// read sensor function
boolean read(int pinid) {
//  Serial.print("pin in read: ");
//  Serial.println(sensor[pinid].pin);
  short _pin = sensor[pinid].pin;
  uint8_t laststate = HIGH;
  uint8_t counter = 0;
  uint8_t j = 0, i;
  unsigned long currenttime;

	// set all to 0
	sensor[pinid].tmp = 0;
	sensor[pinid].hum = 0;

  // pull the pin high and wait 250 milliseconds
  digitalWrite(_pin, HIGH);
  delay(250);

  currenttime = millis();
  if (currenttime < sensor[pinid].lastReadtime) {
    // ie there was a rollover
    sensor[pinid].lastReadtime = 0;
  }
  if (!sensor[pinid].firstreading && ((currenttime - sensor[pinid].lastReadtime) < 2000)) {
    return true; // return last correct measurement
    //delay(2000 - (currenttime - _lastreadtime));
  }
  sensor[pinid].firstreading = false;
  sensor[pinid].lastReadtime = millis();

  sensor[pinid].sdata[0] = sensor[pinid].sdata[1] = sensor[pinid].sdata[2] = sensor[pinid].sdata[3] = sensor[pinid].sdata[4] = 0;
  
  // now pull it low for ~20 milliseconds
  pinMode(_pin, OUTPUT);
  digitalWrite(_pin, LOW);
  delay(20);
  cli();
  digitalWrite(_pin, HIGH);
  delayMicroseconds(40);
  pinMode(_pin, INPUT);

  // read in timings
  for ( i=0; i< MAXTIMINGS; i++) {
    counter = 0;
    while (digitalRead(_pin) == laststate) {
      counter++;
      delayMicroseconds(1);
      if (counter == 255) {
        break;
      }
    }
    laststate = digitalRead(_pin);

    if (counter == 255) break;

    // ignore first 3 transitions
    if ((i >= 4) && (i%2 == 0)) {
      // shove each bit into the storage bytes
      sensor[pinid].sdata[j/8] <<= 1;
      if (counter > 6)
        sensor[pinid].sdata[j/8] |= 1;
      j++;
    }
  }

  sei();
  
  // check we read 40 bits and that the checksum matches
  if ((j >= 40) && 
    (sensor[pinid].sdata[4] == ((sensor[pinid].sdata[0] + sensor[pinid].sdata[1] + sensor[pinid].sdata[2] + sensor[pinid].sdata[3]) & 0xFF)) ) {

    float h = sensor[pinid].sdata[0];
    h *= 256;
    h += sensor[pinid].sdata[1];
		h /= 10;
		sensor[pinid].hum=h;

    float t = sensor[pinid].sdata[2] & 0x7F;
    t *= 256;
    t += sensor[pinid].sdata[3];
		t /= 10;
    if (sensor[pinid].sdata[2] & 0x80) {
      t *= -1;
    }
		sensor[pinid].tmp=t;

    return true;
  }
  
  return false;

}
