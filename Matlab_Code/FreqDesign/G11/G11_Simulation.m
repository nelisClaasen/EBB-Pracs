% 1. Corrected Plant and Dead Time
numerator = [0.1179];
denominator = [1 0.0076]; 
DeadNum = [-0.0725 1];
DeadDen = [0.0725 1]; % Corrected to +1

G11 = tf(numerator, denominator);
DeadTime = tf(DeadNum, DeadDen);
G11_Final = G11 * DeadTime;

% 2. Define the PID Controller
Kp = 0.09474;
Ki = 0.00257;
Kd = 0.6904;

% MATLAB's built-in PID object handles the (Kd*s^2 + Kp*s + Ki)/s structure
C = pid(Kp, Ki, Kd); 

% 3. Create the Open-Loop and Closed-Loop Systems
L = C * G11_Final;       % Open-loop (for checking Phase Margin)
T = feedback(L, 1);      % Closed-loop (for checking Rise Time and Overshoot)

% 4. Verify Transient Response (Time Domain)
figure(1);
step(T);
title('Closed-Loop Step Response');
grid on;

% Extract exact performance metrics directly to the command window
disp('--- Step Response Specifications ---');
metrics = stepinfo(T)

% 5. Verify Frequency Response Margins (Bode Plot)
figure(2);
margin(L); % This draws the Bode plot and displays the Phase Margin