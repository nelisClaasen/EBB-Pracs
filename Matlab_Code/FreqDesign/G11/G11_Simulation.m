% 1. Process Transfer Function Matrix and Dead Time
numerator11 = [0.1179];  denominator11 = [1 0.0076]; 
numerator12 = [0.03658]; denominator12 = [1 0.005254];
numerator21 = [0.06368]; denominator21 = [1 0.006012];
numerator22 = [0.05872]; denominator22 = [1 0.005984];

DeadNum = [-0.0725 1];
DeadDen = [0.0725 1]; 
DeadTime = tf(DeadNum, DeadDen);

G11_Final = tf(numerator11, denominator11) * DeadTime;
G12_Final = tf(numerator12, denominator12) * DeadTime;
G21_Final = tf(numerator21, denominator21) * DeadTime;
G22_Final = tf(numerator22, denominator22) * DeadTime;

disp('--- Process Transfer Function Matrix G(s) ---');
G_Matrix = [G11_Final, G12_Final; G21_Final, G22_Final]

% 2. Define the PID Controllers
Kp1 = 0.09474; Ki1 = 0.00257; Kd1 = 0.6904;
Kp2 = 0.1488;  Ki2 = 0.00314; Kd2 = 1.174;

C11 = pid(Kp1, Ki1, Kd1); 
C22 = pid(Kp2, Ki2, Kd2);

% 3. Create Open-Loop (L) and Closed-Loop (T) Systems
L11 = C11 * G11_Final;
T11 = feedback(L11, 1);

L22 = C22 * G22_Final;
T22 = feedback(L22, 1);

% Normalize the open-loop plants to a steady-state of 1 for visual comparison
G11_Normalized = G11_Final / dcgain(G11_Final);
G22_Normalized = G22_Final / dcgain(G22_Final);

% 4. Step Response Information
disp('--- G11 Open-Loop (Plant) Step Info ---');
stepinfo(G11_Final)
disp('--- G11 Closed-Loop Step Info ---');
stepinfo(T11)

disp('--- G22 Open-Loop (Plant) Step Info ---');
stepinfo(G22_Final)
disp('--- G22 Closed-Loop Step Info ---');
stepinfo(T22)

% 5. Verification Graphs (Forced to 12pt font)

% --- G11 Plots ---
figure(1);
step(G11_Normalized, 'b--', T11, 'r-', 800); 
title('G11: Normalized Open-Loop vs Closed-Loop Step Response');
xlabel('Time');
ylabel('Amplitude');
legend('Normalized Open-Loop (Plant)', 'Closed-Loop', 'Location', 'best');
grid on;
set(findall(gcf, '-property', 'FontSize'), 'FontSize', 12); % Applies 12pt to everything in Figure 1

figure(2);
margin(L11);
title('G11: Open-Loop Bode Plot with Phase Margin');
grid on;
set(findall(gcf, '-property', 'FontSize'), 'FontSize', 12); % Applies 12pt to everything in Figure 2

% --- G22 Plots ---
figure(3);
step(G22_Normalized, 'b--', T22, 'r-', 800); 
title('G22: Normalized Open-Loop vs Closed-Loop Step Response');
xlabel('Time');
ylabel('Amplitude');
legend('Normalized Open-Loop (Plant)', 'Closed-Loop', 'Location', 'best');
grid on;
set(findall(gcf, '-property', 'FontSize'), 'FontSize', 12); % Applies 12pt to everything in Figure 3

figure(4);
margin(L22);
title('G22: Open-Loop Bode Plot with Phase Margin');
grid on;
set(findall(gcf, '-property', 'FontSize'), 'FontSize', 12); % Applies 12pt to everything in Figure 4