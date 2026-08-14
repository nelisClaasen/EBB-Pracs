%Obtaining the transfer function

%Package the input arrays of both transistors into one matrix (Needs to be
%columns)
PWM1StepV1Data = readmatrix('..\Data1\Step_PWM1_V0.csv');
PWM1StepV1 = PWM1StepV1Data(7920:end,1:5);

PWM2StepV0Data = readmatrix('..\Data1\Step_PWM2_V0.csv');
PWM2StepV0 = PWM2StepV0Data(6400:end,1:5);

PWM1TestDataFile = readmatrix('..\Data1\Step_PWM1_VtestData50.csv');
PWM1TestData = PWM1TestDataFile(6230:end,1:5);

PWM2TestDataFile = readmatrix('..\Data1\Step_PWM2_VtestData50.csv');
PWM2TestData = PWM2TestDataFile(6160:end,1:5);

%pwm1 data prep


V_PWM1 = [PWM1StepV1(:,3)];
Temp_PWM1 = [PWM1StepV1(:,1)-22.28, PWM1StepV1(:,2)-21.24];
time_step = 0.005;

%pwm2 data prep
V_PWM2 = [PWM2StepV0(:,4)];
Temp_PWM2 = [PWM2StepV0(:,1)-20.26, PWM2StepV0(:,2)-19.05];

%pwm1 test data prep
V_PWM1_Test = [PWM1TestData(:,3)];
Temp_PWM1_test = [PWM1TestData(:,1)-21.2, PWM1TestData(:,2)-20.2];

%pwm2 test data prep
V_PWM2_Test = [PWM2TestData(:,4)];
Temp_PWM2_test = [PWM2TestData(:,1)-21.1, PWM2TestData(:,2)-20.2] ;





%use iddata to set up the data for tfest

tfest_data1 = iddata(Temp_PWM1, V_PWM1, time_step);
tfest_data2 = iddata(Temp_PWM2, V_PWM2, time_step);
testData1 = iddata(Temp_PWM1_test,V_PWM1_Test,time_step);
testData2 = iddata(Temp_PWM2_test,V_PWM2_Test,time_step);






%estimate nr of poles and zeros, 2 poles since there are two transistors
% n_poles = [2; 2];
% n_zeors = [1;1];
% 
% %estimate the transfer functions
% simo_transfer1 = tfest(tfest_data1,n_poles,n_zeors);
% simo_transfer2 = tfest(tfest_data2, n_poles, n_zeors);
% 
% 
% 
% %set up graph details
% tfest_data1.Name = 'Measured Data';
% tfest_data2.Name = 'Measured Data';
% testData1.Name = 'Measured Data';
% testData2.Name = 'Measured Data';
% 
% simo_transfer2.Name = 'Simulated Model';
% simo_transfer1.Name = 'Simulated Model';
% 
% 
% 
% figure(1)
% compare(tfest_data1, simo_transfer1);
% legend('Location', 'best');
% ylabel('Change in Temperature (℃)')
% figure(2)
% compare(tfest_data2, simo_transfer2);
% legend('Location', 'best');
% ylabel('Change in Temperature (℃)')
% figure(3)
% compare(testData1, simo_transfer1);
% legend('Location', 'best');
% ylabel('Change in Temperature (℃)')
% figure(4)
% compare(testData2, simo_transfer2);
% legend('Location', 'best');
% ylabel('Change in Temperature (℃)')
% 
% lines = findobj(gcf, 'Type', 'Line');
% set(lines, 'LineWidth', 1.5);
% 
% %display the transfer functions of PWM1
% [num1, den1] = tfdata(simo_transfer1(1, 1), 'v');
% 
% 
% [num2, den2] = tfdata(simo_transfer1(2, 1), 'v');
% 
% 
% disp('--- Transfer Function 1 (PWM1 to T1) ---');
% disp('Numerator:'); disp(num1);
% disp('Denominator:'); disp(den1);
% 
% disp('--- Transfer Function 2 (PWM1 to T2) ---');
% disp('Numerator:'); disp(num2);
% disp('Denominator:'); disp(den2);
% 
% 
% 
% %display transfer functions of PWM2
% [num12, den12] = tfdata(simo_transfer2(1, 1), 'v');
% 
% 
% [num22, den22] = tfdata(simo_transfer2(2, 1), 'v');
% 
% 
% disp('--- Transfer Function 1 (PWM2 to T1) ---');
% disp('Numerator:'); disp(num12);
% disp('Denominator:'); disp(den12);
% 
% disp('--- Transfer Function 2 (PWM2 to T2) ---');
% disp('Numerator:'); disp(num22);
% disp('Denominator:'); disp(den22);

% 1. Define the G11 pathway
prc_G11 = tf(15.376, [158.9, 1]);
prc_G11.InputDelay = 4.0;

% 2. Define the G21 pathway
prc_G21 = tf(10.430, [328.5, 1]);
prc_G21.InputDelay = 18.7;

% 3. Combine them into a SIMO system (1 input, 2 outputs)
% The semicolon vertically stacks them: Output 1 (top), Output 2 (bottom)
prc_simo = [prc_G11; prc_G21];

% 4. Name the model and its outputs for a clean legend
prc_simo.Name = 'Process Reaction Curve';
prc_simo.OutputName = {'Temperature 1', 'Temperature 2'};

% 5. Ensure your physical data has matching output names
tfest_data1.OutputName = {'Temperature 1', 'Temperature 2'};

% 6. Generate the comparison plot
figure(1);
compare(testData1, prc_simo);
legend('Location', 'best');
ylabel('Change in Temperature (℃)')
% 7. Thicken the lines for your report
lines = findobj(gcf, 'Type', 'Line');
set(lines, 'LineWidth', 1.5);



% 1. Define the G12 pathway (PWM 2 to T1)
prc_G12 = tf(6.724, [198.0, 1]);
prc_G12.InputDelay = 29.0;

% 2. Define the G22 pathway (PWM 2 to T2)
prc_G22 = tf(9.712, [198.0, 1]);
prc_G22.InputDelay = 1.5;

% 3. Combine them into a SIMO system for PWM 2
% Semicolon stacks them: Output 1 (top), Output 2 (bottom)
prc_simo2 = [prc_G12; prc_G22];

% 4. Name the model and its outputs for a clean legend
prc_simo2.Name = 'Process Reaction Curve';
prc_simo2.OutputName = {'Temperature 1', 'Temperature 2'};

% 5. Ensure your second physical dataset has matching output names
% (Assuming your PWM 2 dataset is named tfest_data2)
tfest_data2.OutputName = {'Temperature 1', 'Temperature 2'};

% 6. Generate the comparison plot for PWM 2



figure(2);
% This plots the physical data, the tfest model, and the PRC model all together
compare(testData2, prc_simo2);
legend('Location', 'best');
ylabel('Change in Temperature (℃)')
% 7. Thicken the lines for your report
lines = findobj(gcf, 'Type', 'Line');
set(lines, 'LineWidth', 1.5);