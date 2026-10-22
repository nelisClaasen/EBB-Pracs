% 1. Corrected Plant and Dead Time
numerator11 = [0.1179];
denominator11 = [1 0.0076]; 

numerator12 = [0.03658];
denominator12 = [1 0.005254];

numerator21 = [0.06368];
denominator21 = [1 0.006012];

numerator22 = [0.05872];
denominator22 = [1 0.005984];


DeadNum = [-0.0725 1];
DeadDen = [0.0725 1]; % Corrected to +1

G11 = tf(numerator11, denominator11);
G22 = tf(numerator22, denominator22);
G12 = tf(numerator12,denominator12);
G21= tf(numerator21,denominator21);
DeadTime = tf(DeadNum, DeadDen);
G11_Final = G11 * DeadTime;
G22_Final = G22 * DeadTime;
G12_Final = G12 * DeadTime;
G21_Final = G21 * DeadTime;

% 2. Define the PID Controller
Kp1 = 0.09474;
Ki1 = 0.00257;
Kd1 = 0.6904;

Kp2= 0.1488;
Ki2 = 0.00314;
Kd2 = 1.174;

% MATLAB's built-in PID object handles the (Kd*s^2 + Kp*s + Ki)/s structure
C = pid(Kp1, Ki1, Kd1); 

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