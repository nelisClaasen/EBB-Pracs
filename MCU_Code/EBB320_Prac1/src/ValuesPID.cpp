#include <fmt/core.h>
#include <Arduino.h>
#include <iostream>
#include <sstream>
#include <vector>
#include <string>
#include <queue>

struct ValuesPID
{
    float P;
    float I;
    float D;
    float setpoint;

    float error;
    float prev_error;
    float integral;
    float derivative;
};

float calculatePID(ValuesPID& controller){

      float duty = 0;
      float next_integral = controller.integral + controller.error * dt;
      
      controller.derivative = (controller.error - controller.prev_error)/dt;
  
      float pid_out = controller.P * controller.error + controller.I*next_integral + controller.D*controller.derivative;
      //anti-windup logic
      if  (pid_out >= 3.3 )
      {
        duty = 1;
        if ( controller.error < 0){
        controller.integral = next_integral;
        }
  
      }
  
      else if (pid_out <= 0.0 ) {
      duty = 0.0; // You cannot have a negative duty cycle for a simple heater/cooler
      if ( controller.error > 0){
        controller.integral = next_integral;
        }
      
      }
  
      else{
        duty = pid_out/3.3;
        controller.integral = next_integral;
      }
      duty = (pow(2, PWM_res) - 1)*(duty);

    return duty;
}