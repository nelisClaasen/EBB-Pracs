filepath = fullfile('..', 'DataPrac3', 'PID_root_V4.csv');
PID_Root_Data = readmatrix(filepath);
PID_Root_Step = PID_Root_Data(7920:end,1:5);

filepath = fullfile('..', 'DataPrac3', 'PID_freq_V4.csv');
PID_Freq_Data = readmatrix(filepath);
PID_Freq_Step = PID_Freq_Data(6400:end,1:5);

y = PID_Root_Step(:, 1:2)
time = PID_Root_Step(:, 5)
pwms = PID_Root_Step(:, 3:4)

plotResults(pwms, y, time, "")

function plotResults(PWM_Input, dataY, time, figNameTemp, figNamePWM)

opts = timeoptions('cstprefs');
opts.Title.FontSize = 14;
opts.XLabel.FontSize = 14;
opts.YLabel.FontSize = 14;
opts.TickLabel.FontSize = 10;
opts.LineWidth = 1.5;


figure("Name", figName);
subplot(2, 1, 1);
hold on; grid on;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Plot the actual temperature output.
%Plot both temeratures.
plot(time, dataY(:, 1), opts);
plot(time, dataY(:, 2), opts);
title(figNameTemp);
legend('Temperature Measurement 1', 'Temperature Measurement 2', 'Location','best', FontSize=14);
ylabel('Temperature (°C)');
xlabel('Time (s)');

hold off;

subplot(2, 1, 2);
hold on; grid on;

% Plot the PWM input signal.
plot(time, movmean(PWM_Input(:, 1), 20), opts);
plot(time, movmean(PWM_Input(:, 2), 20), opts);
title(figNamePWM)
legend('PWM Input 1', 'PWM Input 2', 'Location','best', FontSize=14);
xlabel('Time (s)');
ylabel('Averaged PWM Input (V)');
hold off;


end