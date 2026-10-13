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
    float do_integraion;
};