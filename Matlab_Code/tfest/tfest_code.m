%Obtaining the transfer function

%Package the input arrays of both transistors into one matrix (Needs to be
%columns)
PWM1StepV1Data = readmatrix('../PWM1StepV1.csv');
PWM1StepV1 = PWM1StepV1Data(28600:130577,1:5);

PWM2StepV0Data = readmatrix('../PWM2StepV0.csv');
PWM2StepV0 = PWM2StepV0Data(13650:end,1:5);

%pwm1 data prep

%calculate average ambient temp 
average_ambientT1 = mean(PWM1StepV1(:, 1));


V_PWM1 = [PWM1StepV1(:,3)];
Temp_PWM1 = [PWM1StepV1(:,1)-10.66, PWM1StepV1(:,2)-9.36];
time_step = 0.01;

%pwm2 data prep
V_PWM2 = [PWM2StepV0(:,4)];
Temp_PWM2 = [PWM2StepV0(:,1)-9.57, PWM2StepV0(:,2)-8.16];



%input_v1 = timeseries(V(1),PWM1StepV1(:,5));
% Prepare the input timeseries for the second transistor
%input_v2 = timeseries(V(2), PWM1StepV1(:,5));

%use iddata to set up the data for tfest

tfest_data1 = iddata(Temp_PWM1, V_PWM1, time_step);
tfest_data2 = iddata(Temp_PWM2, V_PWM2, time_step);




%estimate nr of poles and zeros, 2 poles since there are two transistors
n_poles = [2; 2];
n_zeors = [1;1];

%estimate the transfer functions
mimo_transfer1 = tfest(tfest_data1,n_poles,n_zeors);
mimo_transfer2 = tfest(tfest_data2, n_poles, n_zeors);


v11output = mimo_transfer1(1,1);
v12output = mimo_transfer2(1,1);
v21output = mimo_transfer1(2,1);
v22output = mimo_transfer2(2,1);
%bode(v2output)



figure(1)
compare(tfest_data1, mimo_tranfer1);
figure(2)
compare(tfest_data2, mimo_tranfer2);