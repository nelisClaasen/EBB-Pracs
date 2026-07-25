#include <fmt/core.h>
#include <Arduino.h>
#include <iostream>
#include <sstream>
#include <vector>
#include <string>

double P = 0;
double I = 0;
double D = 0;
double setpoint = 0;
double disturbance = 0;
double duty = 50; //50% duty cycle by default.
int PWM_Flag = 0; //By default only pwm1 is on. 
bool start = 0; //Start off.   

int timer = 0;
const int PWM1 = 0;
const int PWM2 = 0;
const int Meas1 = 0;
const int Meas2 = 0;

const int BaudRate = 115200;

void setup() {
  // Start the USB-C serial/UART port
  Serial.begin(BaudRate);
}

void loop() {

  //If receiving communication from computer, update values.
  if(Serial.available() > 0)
  {
    String received = Serial.readStringUntil('\n');
    received.trim();

    std::istringstream stream(received.c_str());
    std::string temp;

    std::getline(stream, temp, ',');
    P = std::stod(temp);

    std::getline(stream, temp, ',');
    I = std::stod(temp);
    
    std::getline(stream, temp, ',');
    D = std::stod(temp);

    std::getline(stream, temp, ',');
    setpoint = std::stod(temp);
    
    std::getline(stream, temp, ',');
    disturbance = std::stod(temp);
    
    std::getline(stream, temp, ',');
    duty = std::stod(temp);
    
    std::getline(stream, temp, ',');
    PWM_Flag = std::stod(temp);
    
    std::getline(stream, temp, ',');
    start = std::stod(temp);

    timer = millis();
  }

  //If start flag is true, start measuring inputs/start controlling aswell.
  if(start)
  {
    int start_time = millis();
    std::string sending = fmt::format("{0},{1},{2}", 100*sin(millis()/500.0), 100*cos(millis()/500.0), millis() - timer); 
    Serial.println(String(sending.c_str()));

    double elapsed = 10 - (millis() - start_time);
    elapsed >= 0 ? delay(elapsed) : delay(10);
  }
  //Otherwise deactivate PWM outputs.
  else
  {

  }
}
