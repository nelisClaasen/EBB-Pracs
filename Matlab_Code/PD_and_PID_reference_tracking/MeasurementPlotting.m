filepath = fullfile('..', 'Data2', 'PID_Disturb_Reject_S1_V0.csv');
all_data = readmatrix(filepath);
V_PWM1 = [all_data(:,3)];
Temp_PWM1 = [all_data(:,1)];
Time_PWM1 = [all_data(:,5)]./1000;

setpoint = 35;

figure('Name', 'Controller Performance', 'Position', [100, 100, 800, 600]);
hold on; grid on;

subplot(2, 1, 1);
hold on; grid on;
% Plot the actual temperature
plot(Time_PWM1, Temp_PWM1, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Temperature Closed Loop');

% Plot the reference
% plot(out.ref.Time, out.ref.Data, 'k--', 'LineWidth', 1.5, DisplayName='Setpoint');
yline(setpoint, 'k--', 'LineWidth', 1.5, DisplayName='Setpoint');

title('Measured Response: PID Disturbance Rejection State 1');
ylabel('Temperature (°C)');
xlabel('Time (s)');
% ylim([20, 60])
legend('Location', 'southeast');
hold off;

subplot(2, 1, 2);
hold on; grid on;

% Plot the simulated temperature
plot(out.No_disturb.Time, out.No_disturb.Data, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Temperature Closed Loop');

% Plot the reference
% plot(out.ref.Time, out.ref.Data, 'k--', 'LineWidth', 1.5, DisplayName='Setpoint');
yline(setpoint, 'k--', 'LineWidth', 1.5, DisplayName='Setpoint');

title('Simulated Response: PID Disturbance Rejection State 1');
ylabel('Temperature (°C)');
xlabel('Time (s)');
% ylim([20, 60])
legend('Location', 'southeast');
hold off;