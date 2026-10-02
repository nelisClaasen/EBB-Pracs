%Obtaining the transfer function

%Package the input arrays of both transistors into one matrix (Needs to be
%columns)
filepath = fullfile('..', 'Data1', 'Step_PWM1_V0.csv');
PWM1StepV1Data = readmatrix(filepath);
PWM1StepV1 = PWM1StepV1Data(7920:end,1:5);

filepath = fullfile('..', 'Data1', 'Step_PWM2_V0.csv');
PWM2StepV0Data = readmatrix(filepath);
PWM2StepV0 = PWM2StepV0Data(6400:end,1:5);

%pwm1 data prep
V_PWM1 = [PWM1StepV1(:,3)];
Temp_PWM1 = [PWM1StepV1(:,1)-22.28, PWM1StepV1(:,2)-21.24];
time_step = 0.005;

%pwm2 data prep
V_PWM2 = [PWM2StepV0(:,4)];
Temp_PWM2 = [PWM2StepV0(:,1)-20.26, PWM2StepV0(:,2)-19.05];

%use iddata to set up the data for tfest
tfest_data1 = iddata(Temp_PWM1, V_PWM1, time_step);
tfest_data2 = iddata(Temp_PWM2, V_PWM2, time_step);

%estimate nr of poles and zeros, 2 poles since there are two transistors
n_poles = 1;
n_zeros = 0;

%estimate the transfer functions
simo_transfer1 = tfest(tfest_data1(:, 1, 1), n_poles, n_zeros, NaN); % PWM1 to T1
simo_transfer2 = tfest(tfest_data2(:, 1, 1), n_poles, n_zeros, NaN); % PWM2 to T1

%create reference tracking PID.
opts = pidtuneOptions ('DesignFocus', 'reference-tracking');
[C1_pid, info] = pidtune(simo_transfer1, 'PID', opts)

%get closed loop step response.
PID_ref_tracking = feedback(C1_pid*simo_transfer1, 1);

G11 = simo_transfer1
G12 = simo_transfer2

% Create a new figure window
figure('Name', 'Controller Performance', 'Position', [100, 100, 800, 600]);

% --- TOP SUBPLOT: Reference vs. Controlled Variable ---
subplot(2, 1, 1);
hold on; grid on;
% Plot the actual temperature
plot(out.No_disturb.Time, out.No_disturb.Data, 'b-', 'LineWidth', 1.5);
% Plot the reference
plot(out.ref.Time, out.ref.Data, 'k--', 'LineWidth', 1.5);


% Formatting the top plot
title('System Response: PD Controller No Disturbance');
ylabel('Temperature (°C)');
% ylim([20, 60])
legend('Reference Trajectory', 'Controlled Variable (Temperature)', 'Location', 'best');
hold off;

% --- BOTTOM SUBPLOT: Manipulated vs. Disturbance Variables ---
subplot(2, 1, 2);
hold on; grid on;


valid_idx = out.control_input1.Time >= 0.15;


plot(out.control_input1.Time(valid_idx), out.control_input1.Data(valid_idx), 'r-', 'LineWidth', 1.5);

% Plot the disturbance step normallyvolt_sig
% plot(out.disturb_input.Time, out.disturb_input.Data, 'm-.', 'LineWidth', 1.5);

% Formatting the bottom plot
xlabel('Time (seconds)');
ylabel('Amplitude (Volts / Input)');
legend('Manipulated Variable (Voltage)', 'Disturbance Variable', 'Location', 'best');
hold off;

% Create a new figure window
figure('Name', 'Controller Performance', 'Position', [100, 100, 800, 600]);

% --- TOP SUBPLOT: Reference vs. Controlled Variable ---
subplot(2, 1, 1);
hold on; grid on;
% Plot the actual temperature
plot(out.Disturb.Time, out.Disturb.Data, 'b-', 'LineWidth', 1.5);
% Plot the reference
plot(out.ref.Time, out.ref.Data, 'k--', 'LineWidth', 1.5);


% Formatting the top plot
title('System Response: PD Controller with Disturbance');
ylabel('Temperature (°C)');
% ylim([20, 60])
legend('Reference Trajectory', 'Controlled Variable (Temperature)', 'Location', 'best');
hold off;

% --- BOTTOM SUBPLOT: Manipulated vs. Disturbance Variables ---
subplot(2, 1, 2);
hold on; grid on;


valid_idx = out.control_input2.Time >= 0.15;


plot(out.control_input2.Time(valid_idx), out.control_input2.Data(valid_idx), 'r-', 'LineWidth', 1.5);

% Plot the disturbance step normallyvolt_sig
plot(out.disturb_input.Time, out.disturb_input.Data, 'm-.', 'LineWidth', 1.5);

% Formatting the bottom plot
xlabel('Time (seconds)');
ylabel('Amplitude (Volts / Input)');
legend('Manipulated Variable (Voltage)', 'Disturbance Variable', 'Location', 'best');
hold off;

% 1. Closed-Loop Metrics (From Simulink Data)



reference_target = 50; 

% Calculate stepinfo using the timeseries data exported from Simulink
CL_info = stepinfo(out.No_disturb.Data, out.No_disturb.Time, reference_target);

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