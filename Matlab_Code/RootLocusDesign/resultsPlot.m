filepath = fullfile('..', 'DataPrac3', 'PID_root_V4.csv');
PID_Root_Data = readmatrix(filepath);
PID_Root_Step = PID_Root_Data(7920:end,1:5);

filepath = fullfile('..', 'DataPrac3', 'PID_freq_V4.csv');
PID_Freq_Data = readmatrix(filepath);
PID_Freq_Step = PID_Freq_Data(6400:end,1:5);

y = PID_Root_Step(:, 1:2);
time = PID_Root_Step(:, 5);
pwms = PID_Root_Step(:, 3:4);
tempName = "Measured Temperature Curve for Root Locus designed PID Controllers";
inputName = "Measured Control Inputs for Root Locus designed PID Controllers";
saveName = "PID_Root"
trans_times = [567516, 1129700]

plotResults(pwms, y, time, tempName, inputName, saveName, trans_times);

y = PID_Freq_Step(:, 1:2);
time = PID_Freq_Step(:, 5);
pwms = PID_Freq_Step(:, 3:4);
tempName = "Measured Temperature Curve for Frequency Response designed PID Controllers";
inputName = "Measured Control Inputs for Frequency Response designed PID Controllers";
saveName = "PID_Freq"
trans_times = [629974, 1010150];
plotResults(pwms, y, time, tempName, inputName, saveName, trans_times);

function plotResults(PWM_Input, dataY, time, figNameTemp, figNamePWM, saveName, state_trans_times)
figure;
% subplot(2, 1, 1);
hold on; grid on;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Plot the actual temperature output.
%Plot both temeratures.
t1 = plot(time, dataY(:, 1), LineWidth=1.5);
t2 = plot(time, dataY(:, 2), LineWidth=1.5);
title(figNameTemp);
legend([t1, t2], {'Temperature Measurement 1', 'Temperature Measurement 2'}, 'Location','southeast', FontSize=14);
ylabel('Temperature (°C)');
xlabel('Time (s)');

if ~isempty(state_trans_times)
    for transitionTime = state_trans_times
        xline(transitionTime, '--k', 'LineWidth', 1.2, 'HandleVisibility', 'off');
    end
end

fontsize(gcf, 20, "points");
hold off;

filepath = fullfile('..', '..', 'Prac-3-Report', 'Images', 'Results', saveName + "_Temps.pdf");
exportgraphics(gcf, filepath, 'ContentType','vector');

figure;
% subplot(2, 1, 2);
hold on; grid on;

% Plot the PWM input signal.
ylim([-0.1, 3.5])
plot(time, movmean(PWM_Input(:, 1), 200), LineWidth=1.5);
plot(time, movmean(PWM_Input(:, 2), 200), LineWidth=1.5);
title(figNamePWM)
legend('PWM Input 1', 'PWM Input 2', 'Location','best', FontSize=14);
xlabel('Time (s)');
ylabel('Averaged PWM Input (V)');

if ~isempty(state_trans_times)
    for transitionTime = state_trans_times
        xline(transitionTime, '--k', 'LineWidth', 1.2, 'HandleVisibility', 'off');
    end
end

fontsize(gcf, 20, "points");
hold off;

filepath = fullfile('..', '..', 'Prac-3-Report', 'Images', 'Results', saveName + "_Inputs.pdf");
exportgraphics(gcf, filepath, 'ContentType','vector');

end