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
const int PWM1 = GPIO_NUM_32;
const int PWM2 = GPIO_NUM_33;
const int Meas1 = GPIO_NUM_34;
const int Meas2 = GPIO_NUM_35;

const double A = 3.3/4095.0;
const int PWM_freq = 10;
const int PWM_res = 8;

const int BaudRate = 115200;
const int sampling_period = 5;

void setup() {
  //Start the USB-C serial/UART port.
  Serial.begin(BaudRate);

  //Setup I/O pins.
  pinMode(Meas1, INPUT);
  pinMode(Meas2, INPUT);

  ledcChangeFrequency(0, PWM_freq, PWM_res);
  ledcAttachPin (PWM1, 0);
  ledcAttachPin(PWM2, 1);
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
    duty = pow(2, PWM_res)*(duty/100.0);
    
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
    double elapsed = sampling_period - (millis() - start_time);

    std::string sending = fmt::format("{0},{1},{2},{3}", analogRead(Meas1)*A, analogRead(Meas2)*A, millis() - timer, static_cast<int>(elapsed <= 0)); 
    Serial.println(String(sending.c_str()));

    ledcWrite(0, duty);

    elapsed >= 0 ? delay(elapsed) : delay(sampling_period);
  }
  //Otherwise deactivate PWM outputs.
  else
  {

  }
}
