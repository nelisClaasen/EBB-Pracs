#include <fmt/core.h>
#include <Arduino.h>
#include <iostream>
#include <sstream>
#include <vector>
#include <string>
#include <queue>
#include "ValuesPID.cpp"

double P = 0;
double I = 0;
double D = 0;
double setpoint = 0;
double duty1 = 128; //50% duty cycle by default.
double duty2 = 128;
int control_outputs = 0; //By default only pwm1 is on. 
bool start = 0; //Start off.   
int message = 100; //Flags for certain messages.
int start_time = 0;
bool startControlling = 0; //See if we should start controlling, or continue just measuring.

//PID variables 
float error = 0;
float integral = 0;
float previous_error = 0;
float derivative = 0;
bool do_integration = true;

//New PID structs for eventual use in the controllers.
ValuesPID controllerG11 = {0, 0, 0, 0, 0, 0, 0, 0};
ValuesPID controllerG22 = {0, 0, 0, 0, 0, 0, 0, 0};


double temp1 = 0; //Final temperature measurement that is sent to PC and used by controller/s.
double temp2 = 0; //Final temperature measurement that is sent to PC and used by controller/s.
int N_samples = 200; //Amount of samples being averaged.
std::queue<double> samples1; //Storage of samples for temp measurements for T1
std::queue<double> samples2; //Storage of samples for temp measurements for T2

hw_timer_t *timer = NULL; //Timer to ensure constant sample rate.
const int PWM_Out_1 = GPIO_NUM_32;
const int PWM_Out_2 = GPIO_NUM_25;
const int PWM_Meas_1 = GPIO_NUM_33;
const int PWM_Meas_2 = GPIO_NUM_26;

const int Temp_Meas1 = GPIO_NUM_27;
const int Temp_Meas2 = GPIO_NUM_35;

const double A = (3.3/4095.0); //Constant multiplier used to scale PWM outputs to voltages.
const int PWM_freq = 10;
const int PWM_res = 8;

const int BaudRate = 1152000;
const int sampling_period = 5000; //In microseconds.
const float dt = sampling_period/1000000.0; //t delta used in PWM calculations.
bool first_run = true; //Check if this is the very first run, used the prevent initial derivative kick. (Can be used for both controllers at once since they are controlling at the same time?)

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

  samples1.push(0);
  samples2.push(0);
}

void loop() {

  //If receiving communication from computer, update values.
  if(Serial.available() > 0)
  {
    //Read the entire line, trim whitespace, and separate the comma separated line into the command value pair.
    String received = Serial.readStringUntil('\n');
    received.trim();

    std::istringstream stream(received.c_str());
    std::string command;
    std::string value_str;
    double value;

    std::getline(stream, command, ',');
    std::getline(stream, value_str, ',');
    value = std::stod(value_str);

    //Essentially a "switch case" to update the appropriate values for each command.
    if(command == "0") // P value for PWM1
    {
      controllerG11.P = value;
    }
    else if(command == "1") // I value for PWM1
    {
      controllerG11.I = value;
    }
    else if(command == "2") // D value for PWM1
    {
      controllerG11.D = value;
    }
    else if(command == "3") // Setpoint value for PWM1
    {
      controllerG11.setpoint = value;
    }
    
    else if(command == "5") //Change from duty cycle set to the startControlling flag.
    {
      startControlling = value;
    }
    else if(command == "7") //Flag to start process of taking measurements and sending them over UART.
    {
      start = value;

      //Check if start is true, then start timer.
      if(start)
      {
        start_time = millis();
      }
    }

    else if(command == "8") // P value for PWM2
    {
      controllerG22.P = value;
    }
    else if(command == "9") // I value for PWM2
    {
      controllerG22.I = value;
    }
    else if(command == "10") // D value for PWM2
    {
      controllerG22.D = value;
    }
    else if(command == "11") // Setpoint value for PWM2
    {
      controllerG22.setpoint = value;
    }
  }

  //If start flag is true, start measuring inputs/start controlling aswell.
  if(start)
  {
    //Check when we started in order to see how long we were busy.
    timerRestart(timer);

    if(startControlling)
    {
      //Turn on the appropriate PWM signals.
        ledcWrite(0, duty1);
        ledcWrite(1, duty2);
    }

    //Interpret sensor data.
    double temp1_raw = (analogReadMilliVolts(Temp_Meas1)/1000.0 - 0.5)/0.01;
    double temp2_raw = (analogReadMilliVolts(Temp_Meas2)/1000.0 - 0.5)/0.01;

    if(samples1.size() > N_samples)
    {
      temp1 -= samples1.front();
      temp2 -= samples2.front();

      samples1.pop();
      samples2.pop();
    }

    temp1 += temp1_raw/N_samples;
    temp2 += temp2_raw/N_samples;

    samples1.push(temp1_raw/N_samples);
    samples2.push(temp2_raw/N_samples);

    //Send sensor input data as a comma seperated list.
    std::string sending = fmt::format("{0}, {1}, {2}, {3}, {4}, {5}",
    temp1, temp2, analogRead(PWM_Meas_1)*A, analogRead(PWM_Meas_2)*A, millis() - start_time, message);

    Serial.println(String(sending.c_str()));
    Serial.flush();


    if (startControlling)
    {
      //PID controller start
      controllerG11.prev_error = controllerG11.error;
      controllerG11.error = controllerG11.setpoint - temp1;

      controllerG22.prev_error =  controllerG22.error;
      controllerG22.error =  controllerG22.setpoint - temp2;
  
      // Prevent derivative kick on first run
  
      if (first_run) {
        controllerG11.prev_error = controllerG11.error;
        controllerG22.prev_error = controllerG22.error;

        first_run = false;
      }

      duty1 = calculatePID(controllerG11);
      duty2 =calculatePID(controllerG22);
      
      

      // std::string sending = fmt::format("{0}, {1}, {2}, {3}, {4}", P, I, D, error, duty);
      // Serial.println(String(sending.c_str()));
      // Serial.flush();
    }
    //Otherwise turn off control signals.
    else
    {
      ledcWrite(0, 0);
      ledcWrite(1, 0);
    }

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


  //Otherwise deactivate PWM outputs.
  }
  else
  {
    ledcWrite(0, 0);
    ledcWrite(1, 0);
  }
}
