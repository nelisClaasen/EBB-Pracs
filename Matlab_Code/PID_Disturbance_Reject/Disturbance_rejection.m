
numerator = [0.1175];
denominator = [1 0.0076]; 
G11 = tf(numerator, denominator);

opts = pidtuneOptions('DesignFocus', 'disturbance-rejection');
[C2_pid, info] = pidtune(G11, 'PID', opts);


C2_pid

Kp = C2_pid.Kp;
Ki = C2_pid.Ki;
Kd = C2_pid.Kd;

% Create a new figure window
figure('Name', 'Controller Performance', 'Position', [100, 100, 800, 600]);

% --- TOP SUBPLOT: Reference vs. Controlled Variable ---
subplot(2, 1, 1);
hold on; grid on;
% Plot the actual temperature
plot(out.temp_sig.Time, out.temp_sig.Data, 'b-', 'LineWidth', 1.5);
% Plot the reference
plot(out.ref_sig.Time, out.ref_sig.Data, 'k--', 'LineWidth', 1.5);


% Formatting the top plot
title('System Response: Disturbance Rejection');
ylabel('Temperature (°C)');
ylim([20, 60])
legend('Reference Trajectory', 'Controlled Variable (Temperature)', 'Location', 'best');
hold off;

% --- BOTTOM SUBPLOT: Manipulated vs. Disturbance Variables ---
subplot(2, 1, 2);
hold on; grid on;


valid_idx = out.volt_sig.Time >= 0.15;


plot(out.volt_sig.Time(valid_idx), out.volt_sig.Data(valid_idx), 'r-', 'LineWidth', 1.5);

% Plot the disturbance step normally
%plot(out.dist_sig.Time, out.dist_sig.Data, 'm-.', 'LineWidth', 1.5);

% Formatting the bottom plot
xlabel('Time (seconds)');
ylabel('Amplitude (Volts / Input)');
legend('Manipulated Variable (Voltage)', 'Disturbance Variable', 'Location', 'best');
hold off;

% 1. Closed-Loop Metrics (From Simulink Data)



reference_target = 50; 

% Calculate stepinfo using the timeseries data exported from Simulink
CL_info = stepinfo(out.temp_sig.Data, out.temp_sig.Time, reference_target);

fprintf('\n--- CLOSED-LOOP METRICS (Simulink) ---\n');
fprintf('Rise Time:      %.3f seconds\n', CL_info.RiseTime);
fprintf('Peak Time:      %.3f seconds\n', CL_info.PeakTime);
fprintf('Settling Time:  %.3f seconds\n', CL_info.SettlingTime);
fprintf('Overshoot:      %.2f %%\n', CL_info.Overshoot);


% 2. Open-Loop Metrics (From Transfer Function)

OL_info = stepinfo(G11);

fprintf('\n--- OPEN-LOOP METRICS (Mathematical) ---\n');
fprintf('Rise Time:      %.3f seconds\n', OL_info.RiseTime);
fprintf('Peak Time:      %.3f seconds\n', OL_info.PeakTime);
fprintf('Settling Time:  %.3f seconds\n', OL_info.SettlingTime);
fprintf('Overshoot:      %.2f %%\n', OL_info.Overshoot);