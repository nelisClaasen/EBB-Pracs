filepath = fullfile('PID_root_V2.csv');
PWM1StepV1Data = readmatrix(filepath);
PWM1StepV1 = PWM1StepV1Data(7920:end,1:5);

figure;

% plot(PWM1StepV1())