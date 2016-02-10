#include <Bridge.h>
#include <YunServer.h>
#include <YunClient.h>
#include <Servo.h> 
#include <Process.h>
#include "EmonLib.h"                   // Include Emon Library

EnergyMonitor emon1;   
YunServer server;
bool isOnAlert = false;
bool isThereBreakIn = false;
unsigned long t_now, t_diff, t_last, t_culm, t_reset = 0;
double engCons;
double watts;
float temp = 0;
int speaker = 5;
int doorState = 0;
int relayPin = 4;
int doorPin = 3;

void setup() {
  // Bridge startup
  pinMode(relayPin, OUTPUT);      //pin attached to relay board
  pinMode(doorPin,INPUT);        //pin attached to reed switch
  emon1.current(1, 50);             // Current: input pin, calibration.
  t_reset = 0;
  
  Bridge.begin();

  // Listen for incoming connection only from localhost
  // (no one from the external network could connect)
  server.listenOnLocalhost();
  server.begin();
}

void loop() {
  // Get clients coming from server
  YunClient client = server.accept();

  if (client) {
    process(client);
    client.stop();
  }
  
  t_now = millis();
  if (t_now > t_last){
    t_diff = t_now - t_last;
  }else{
    t_diff = 4127;
  }
  
  t_culm += t_diff;
  t_last = t_now;
  
  if (t_culm > (3600000 * 24)){
    engCons = 0;
    t_culm = 0;
  }
 
  monitorElectric();
  checkDoor();
  
  delay(50); // Poll every 50ms
}

void monitorElectric(){
  double Irms = emon1.calcIrms(1480);  // Calculate Irms only
  watts = Irms * 120;
  engCons += (watts * t_diff) / 3600000;
}

void checkDoor() 
{
  int sensorValue = digitalRead(doorPin);  //reed switch;
  
  if ( sensorValue != doorState ){
    doorState = sensorValue;
    if (doorState == 0 && isOnAlert){
      if (!isThereBreakIn){   
        isThereBreakIn = true;   
        digitalWrite(relayPin, HIGH);
	alert();
      }
    }
    announcement(doorState);
    updateSys(doorState);
  }    
}

void alert(){
        Process alert;
        alert.begin("python");
        alert.addParameter("/mnt/sda1/BreakIn.py");
        alert.addParameter("Kitchen");
        alert.addParameter("BackDoor");
        alert.run();
}  

void announcement(int value){
    Process announcement;
    announcement.begin("python");
    announcement.addParameter("/mnt/sda1/Announcement.py");
    announcement.addParameter("Kitchen");      
    announcement.addParameter("OpenedDoors");
    if (value == 0){
      announcement.addParameter("BackDoor");
    }else{
      announcement.addParameter("/");
    }
    announcement.run();
}

void updateSys(int value){
    Process updateSys;
    updateSys.begin("python");
    updateSys.addParameter("/mnt/sda1/UpdateStatus.py");
    updateSys.addParameter("MainFloor");
    updateSys.addParameter("Kitchen");      
    updateSys.addParameter("OpenedDoors");
    if (value == 0){
      updateSys.addParameter("BackDoor");
    }else{
      updateSys.addParameter("/");
    }
    updateSys.run();
}

void process(YunClient client) {
  // read the command
  String command = client.readStringUntil('/');

  // is "digital" command?
  if (command == "digital") {
    digitalCommand(client);
  }

  // is "analog" command?
  if (command == "analog") {
    analogCommand(client);
  }

  // is "mode" command?
  if (command == "mode") {
    modeCommand(client);
  }
  
  //is "status" command?
  if (command == "status") {
    statusCommand(client);
  }
  
  if (command == "utility") {
    utilityCommand(client);
  }
  
  if (command == "night") {
    nightCommand(client);
  }
}

void digitalCommand(YunClient client) {
  int pin, value;

  // Read pin number
  pin = client.parseInt();

  // If the next character is a '/' it means we have an URL
  // with a value like: "/digital/13/1"
  if (client.read() == '/') {
    value = client.parseInt();
    digitalWrite(pin, value);
    // Send feedback to client
    client.print(F("Pin D"));
    client.print(pin);
    client.print(F(" set to "));
    client.println(value);
  }
  else {
    value = digitalRead(pin);
    // Send feedback to client
    client.println(value);
  }

  // Update datastore key with the current pin value
  String key = "D";
  key += pin;
  Bridge.put(key, String(value));
}

void analogCommand(YunClient client) {
  int pin, value;

  // Read pin number
  pin = client.parseInt();

  // If the next character is a '/' it means we have an URL
  // with a value like: "/analog/5/120"
  if (client.read() == '/') {
    // Read value and execute command
    value = client.parseInt();
    analogWrite(pin, value);

    // Send feedback to client
    client.print(F("Pin D"));
    client.print(pin);
    client.print(F(" set to analog "));
    client.println(value);

    // Update datastore key with the current pin value
    String key = "D";
    key += pin;
    Bridge.put(key, String(value));
  }
  else {
    // Read analog pin
    value = analogRead(pin);
    
    //conversion for temperature
    if (pin == 2){
      // converting that reading to voltage, for 3.3v arduino use 3.3
      client.print(temp);
      client.println(F(" F"));
    }else {
      // Send feedback to client
      client.println(value);
    }
    
    // Update datastore key with the current pin value
    String key = "A";
    key += pin;
    Bridge.put(key, String(value));
  }
}

void modeCommand(YunClient client) {
  int pin;

  // Read pin number
  pin = client.parseInt();

  // If the next character is not a '/' we have a malformed URL
  if (client.read() != '/') {
    client.println(F("error"));
    return;
  }

  String mode = client.readStringUntil('\r');

  if (mode == "input") {
    pinMode(pin, INPUT);
    // Send feedback to client
    client.print(F("Pin D"));
    client.print(pin);
    client.print(F(" configured as INPUT!"));
    return;
  }

  if (mode == "output") {
    pinMode(pin, OUTPUT);
    // Send feedback to client
    client.print(F("Pin D"));
    client.print(pin);
    client.print(F(" configured as OUTPUT!"));
    return;
  }

  client.print(F("error: invalid mode "));
  client.print(mode);
}

void statusCommand(YunClient client) 
{ 
  client.print(F("Kitchen,Temp,"));
  int value3 = analogRead(2);      //temp probe
  float voltage = value3 * 5.0;
  voltage /= 1024.0; 
  float temperatureC = (voltage - 0.5) * 100 ;  //converting from 10 mv per degree wit 500 mV offset
  temp = (temperatureC * 9.0 / 5.0) + 32.0;
  client.println(temp);
  
  int value = digitalRead(doorPin);
  client.print(F("Kitchen,OpenedDoors,"));
  if  (value == 0){
    client.println("BackDoor");
  }else{
    client.println("");
  }
  
  //int value2 = digitalRead(relayPin);
  client.print(F("Kitchen,EnabledLights,"));
  //if  (value2 == 1){
  //  client.println("MainLights");
  //}else{
  client.println("");
  //}
  
  client.println(F("Kitchen,LockedDoors,"));
  client.println(F("Kitchen,OpenedWindows,"));
  client.println(F("Kitchen,hasExtraLights,False"));
  client.println(F("Kitchen,hasControls,True"));
 
  client.print(F("Home,Occupied,"));
  if (isOnAlert){
    client.println(F("False"));
  }else{
    client.println(F("True"));
  }

}

void utilityCommand(YunClient client) 
{
  
  if  (watts >= 1000){
    client.print(watts/1000.0);
    client.println(F(" KW currently in use"));
  }else{
    client.print(watts);
    client.println(F(" Watts currently in use"));	
  }    
  
  if  (engCons >= 1000){
    client.print(engCons/1000.0);
    client.println(F(" KWH Total Used"));
  }else{
    client.print(engCons);
    client.println(F(" Watts Total Used"));	
  }  
}

void nightCommand(YunClient client)
{
  int value;

  // Read pin number
  value = client.parseInt();
  isThereBreakIn = false;
  
  if (value == 1) {
   isOnAlert = true; 
  }else {
   isOnAlert = false;
  }
}

