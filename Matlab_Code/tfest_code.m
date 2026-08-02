%Obtaining the transfer function

%Package the input arrays of both transistors into one matrix (Needs to be
%columns)
PWM1StepV1Data = readmatrix('PWM1StepV1.csv');
PWM1StepV1 = PWM1StepV1Data(28638:130577,1:5);

V = [PWM1StepV1(:,3),PWM1StepV1(:,4)];
Temp = [PWM1StepV1(:,1), PWM1StepV1(:,2)];
time_step = 0.01;
input_v1 = timeseries(V(1),PWM1StepV1(:,5));

%use iddata to set up the data for tfest
tfest_data = iddata(Temp, V, time_step);

%estimate nr of poles and zeros, 2 poles since there are two transistors
n_poles = [2,2; 2,2];
n_zeors = [1,1;1,1];

%estimate the transfer functions
mimo_tranfer = tfest(tfest_data,n_poles,n_zeors, 'IODelay', NaN);

v1output = mimo_tranfer(1,2);
