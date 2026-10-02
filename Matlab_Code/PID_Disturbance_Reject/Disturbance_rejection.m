
numerator = [0.1175];
denominator = [1 0.0076]; 
G11 = tf(numerator, denominator);

opts = pidtuneOptions('DesignFocus', 'disturbance-rejection');
[C2_pid, info] = pidtune(G11, 'PID', opts);


C2_pid

Kp = C2_pid.Kp;
Ki = C2_pid.Ki;
Kd = C2_pid.Kd;
figure('Name', 'Controller Performance', 'Position', [100, 100, 800, 600]);
hold on; grid on;
% Plot the actual temperature
plot(out.temp_sig.Time, out.temp_sig.Data, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Temperature Closed Loop');

%Plot the closed loop temp.
plot(out.open_loop.Time, out.open_loop.Data, 'LineWidth', 1.5, 'DisplayName', 'Temperature Open Loop');
% Plot the reference
% plot(out.ref.Time, out.ref.Data, 'k--', 'LineWidth', 1.5, DisplayName='Setpoint');
yline(50, 'k--', 'DisplayName','Setpoint' , 'LineWidth', 1.5)

title('System Response: PID Disturbance Rejection No Disturbance');
ylabel('Temperature (°C)');
xlabel('Time (s)');
% ylim([20, 60])
legend('Location', 'best');
hold off;

reference_target = 50; 

% Calculate stepinfo using the timeseries data exported from Simulink
CL_info = stepinfo(out.No_disturb.Data, out.No_disturb.Time, reference_target);



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