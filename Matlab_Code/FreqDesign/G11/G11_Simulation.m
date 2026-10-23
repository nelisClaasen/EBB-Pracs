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


set(groot, 'defaultAxesFontSize', 14); 


% 5. Verification Graphs (Forced to 14pt font for export scaling)

% --- G11 Plots ---
figure(1);
step(G11_Normalized, 'b--', T11, 'r-', 800); 
legend('Normalized Open-Loop (Plant)', 'Closed-Loop', 'Location', 'best', 'FontSize', 14);
grid on;
h1 = gcr; 
opt1 = getoptions(h1);
opt1.Title.String = ''; 
opt1.TickLabel.FontSize = 14;
opt1.XLabel.FontSize = 14;
opt1.YLabel.FontSize = 14;
setoptions(h1, opt1);

figure(2);
[Gm1, Pm1, Wcg1, Wcp1] = margin(L11);
margin(L11);
grid on;
h2 = gcr;
opt2 = getoptions(h2);
opt2.Title.String = ''; 
opt2.TickLabel.FontSize = 20;
opt2.XLabel.FontSize = 20;
opt2.YLabel.FontSize = 20;
setoptions(h2, opt2);

% Create floating text box for the phase margin info
txt1 = sprintf('P_m = %.1f^\\circ at \\omega = %.4f rad/s', Pm1, Wcp1);
annotation('textbox', [0.55, 0.15, 0.35, 0.07], 'String', txt1, ...
    'BackgroundColor', 'white', 'EdgeColor', 'black', ...
    'FitBoxToText', 'on', 'FontSize', 20);

% --- G22 Plots ---
figure(3);
step(G22_Normalized, 'b--', T22, 'r-', 800); 
legend('Normalized Open-Loop (Plant)', 'Closed-Loop', 'Location', 'best', 'FontSize', 14);
grid on;
h3 = gcr; 
opt3 = getoptions(h3);
opt3.Title.String = ''; 
opt3.TickLabel.FontSize = 14;
opt3.XLabel.FontSize = 14;
opt3.YLabel.FontSize = 14;
setoptions(h3, opt3);

figure(4);
[Gm2, Pm2, Wcg2, Wcp2] = margin(L22);
margin(L22);
grid on;
h4 = gcr;
opt4 = getoptions(h4);
opt4.Title.String = ''; 
opt4.TickLabel.FontSize = 20;
opt4.XLabel.FontSize = 20;
opt4.YLabel.FontSize = 20;
setoptions(h4, opt4);

% Create floating text box for the phase margin info
txt2 = sprintf('P_m = %.1f^\\circ at \\omega = %.4f rad/s', Pm2, Wcp2);
annotation('textbox', [0.55, 0.15, 0.35, 0.07], 'String', txt2, ...
    'BackgroundColor', 'white', 'EdgeColor', 'black', ...
    'FitBoxToText', 'on', 'FontSize', 20);

t = out.temp.Time;

temp1 = out.temp.Data(:,1);
temp2 = out.temp.Data(:,2);

figure(5);
plot(t, temp1, 'b-', 'LineWidth', 2); hold on;
plot(t, temp2, 'r-', 'LineWidth', 2); 


xline(600, 'k--', 'LineWidth', 2);
xline(1200, 'k--', 'LineWidth', 2);

hold off;
5
title(''); 
xlabel('Time (seconds)');
ylabel('Temperature (^\circ C)')
legend('Temperature Measurement 1', 'Temperature Measurement 2', 'Location', 'best', 'FontSize', 20);
grid on;
set(gca, 'FontSize', 20);


control1 = out.control.Data(:,1);
control2 = out.control.Data(:,2);
figure(6);
plot(t, control1, 'b-', 'LineWidth', 2); hold on;
plot(t, control2, 'r--', 'LineWidth', 2);

xline(600, 'k--', 'LineWidth', 2);
xline(1200, 'k--', 'LineWidth', 2);

hold off;
xlabel('Time (seconds)');
ylabel('Controller Output');
legend('Controller 1', 'Controller  2', 'Location', 'best', 'FontSize', 20);
grid on;
set(gca, 'FontSize', 20);


%Calculate overshoot and rise time

% --- Temp 1: State 1 (0 to 600 seconds) ---
idx_t1_s1 = (t >= 0) & (t < 600);
t_t1_s1 = t(idx_t1_s1);
t_t1_s1 = t_t1_s1 - t_t1_s1(1); % Shift time to start at 0
y_t1_s1 = temp1(idx_t1_s1);
stats_t1_s1 = stepinfo(y_t1_s1, t_t1_s1, y_t1_s1(end), 'InitialValue', y_t1_s1(1));

fprintf('--- Temp 1 (G11) ---\n');
fprintf('State 1 (0-600s) Overshoot: %.2f%%\n', stats_t1_s1.Overshoot);
fprintf('State 1 (0-600s) Rise Time: %.2f seconds\n\n', stats_t1_s1.RiseTime);

% --- Temp 1: State 2 (600 to 1200 seconds) ---
idx_t1_s2 = (t >= 600) & (t < 1200);
t_t1_s2 = t(idx_t1_s2);
t_t1_s2 = t_t1_s2 - t_t1_s2(1); 
y_t1_s2 = temp1(idx_t1_s2);
stats_t1_s2 = stepinfo(y_t1_s2, t_t1_s2, y_t1_s2(end), 'InitialValue', y_t1_s2(1));

fprintf('State 2 (600-1200s) Overshoot: %.2f%%\n', stats_t1_s2.Overshoot);
fprintf('State 2 (600-1200s) Rise Time: %.2f seconds\n\n', stats_t1_s2.RiseTime);

% --- Temp 2: State 1 (0 to 600 seconds) ---
idx_t2_s1 = (t >= 0) & (t < 600);
t_t2_s1 = t(idx_t2_s1);
t_t2_s1 = t_t2_s1 - t_t2_s1(1); 
y_t2_s1 = temp2(idx_t2_s1);
stats_t2_s1 = stepinfo(y_t2_s1, t_t2_s1, y_t2_s1(end), 'InitialValue', y_t2_s1(1));

fprintf('--- Temp 2 (G22) ---\n');
fprintf('State 1 (0-600s) Overshoot: %.2f%%\n', stats_t2_s1.Overshoot);
fprintf('State 1 (0-600s) Rise Time: %.2f seconds\n\n', stats_t2_s1.RiseTime);

% --- Temp 2: State 3 (1200 to 1500 seconds) ---
idx_t2_s3 = (t >= 1200) & (t <= 1500);
t_t2_s3 = t(idx_t2_s3);
t_t2_s3 = t_t2_s3 - t_t2_s3(1); 
y_t2_s3 = temp2(idx_t2_s3);
stats_t2_s3 = stepinfo(y_t2_s3, t_t2_s3, y_t2_s3(end), 'InitialValue', y_t2_s3(1));

fprintf('State 3 (1200-1500s) Overshoot: %.2f%%\n', stats_t2_s3.Overshoot);
fprintf('State 3 (1200-1500s) Rise Time: %.2f seconds\n', stats_t2_s3.RiseTime);