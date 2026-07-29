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
double duty = 128; //50% duty cycle by default.
int control_outputs = 0; //By default only pwm1 is on. 
bool start = 0; //Start off.   
int message = 100; //Flags for certain messages.
int start_time = 0;

hw_timer_t *timer = NULL;
const int PWM_Out_1 = GPIO_NUM_32;
const int PWM_Out_2 = GPIO_NUM_25;
const int PWM_Meas_1 = GPIO_NUM_33;
const int PWM_Meas_2 = GPIO_NUM_26;

const int Temp_Meas1 = GPIO_NUM_34;
const int Temp_Meas2 = GPIO_NUM_35;

const double A = 3.3/4095.0;
const int PWM_freq = 10;
const int PWM_res = 8;

const int BaudRate = 115200;
const int sampling_period = 10000; //In microseconds.

void setup() {
  //Start the USB-C serial/UART port.
  Serial.begin(BaudRate);

  //Setup I/O pins.
  pinMode(Temp_Meas1, INPUT);
  pinMode(Temp_Meas2, INPUT);
  pinMode(PWM_Meas_1, INPUT);
  pinMode(PWM_Meas_2, INPUT);

  ledcChangeFrequency(0, PWM_freq, PWM_res);
  ledcChangeFrequency(1, PWM_freq, PWM_res);
  ledcAttachPin (PWM_Out_1, 0);
  ledcAttachPin(PWM_Out_2, 1);

  timer = timerBegin(0, 80, true);
}

void loop() {

  //If receiving communication from computer, update values.
  if(Serial.available() > 0)
  {
    String received = Serial.readStringUntil('\n');
    received.trim();

    std::istringstream stream(received.c_str());
    std::string command;
    std::string value_str;
    double value;

    std::getline(stream, command, ',');
    std::getline(stream, value_str, ',');
    value = std::stod(value_str);

    if(command == "0")
    {
      P = value;
    }
    else if(command == "1")
    {
      I = value;
    }
    else if(command == "2")
    {
      D = value;
    }
    else if(command == "3")
    {
      setpoint = value;
    }
    else if(command == "4")
    {
      disturbance = value;
    }
    else if(command == "5")
    {
      duty = value;
      duty = (pow(2, PWM_res) - 1)*(duty/100.0); //Convert to percentage.
    }
    else if(command == "6")
    {
      control_outputs = value;
      //Serial.print("Igot");
      //Serial.println(control_outputs);
    }
    else if(command == "7")
    {
      start = value;

      //Check if start is true, then start timer.
      if(start)
      {
        start_time = millis();
      }
    }
  }

  //If start flag is true, start measuring inputs/start controlling aswell.
  if(start)
  {
    //Check when we started in order to see how long we were busy.
    timerRestart(timer);

    //Turn on the appropriate PWM signals.
    switch(control_outputs)
    {
      case 0:
        ledcWrite(0, duty);
        ledcWrite(1, 0);
        break;

      case 1:
        ledcWrite(1, duty);
        ledcWrite(0, 0);
        break;

      case 2:
        ledcWrite(0, duty);
        ledcWrite(1, duty);
        break;

        default:
        ledcWrite(0, 0);
        ledcWrite(1, 0);
    }

    //Send sensor input data as a comma seperated list.
    std::string sending = fmt::format("{0}, {1}, {2}, {3}, {4}, {5}",
    analogRead(Temp_Meas1)*A, analogRead(Temp_Meas2)*A, analogRead(PWM_Meas_1)*A, analogRead(PWM_Meas_2)*A, millis() - start_time, message);

    Serial.println(String(sending.c_str()));
    Serial.flush();

    //Check how long everything took in microseconds.
    int elapsed = timerReadMicros(timer);

    if(elapsed <= sampling_period)
    {
      delayMicroseconds(sampling_period - elapsed);
      message = 100; //Reset message flag to show nothing.
    }
    else
    {
      delayMicroseconds(sampling_period);
      message = 0; //Set message flag for sampling too fast.
    }
  }
  //Otherwise deactivate PWM outputs.
  else
  {
    ledcWrite(0, 0);
    ledcWrite(1, 0);
  }
}
