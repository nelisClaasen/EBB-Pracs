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
simo_transfer2 = tfest(tfest_data2, n_poles, n_zeros);

%create reference tracking PID.
opts = pidtuneOptions ('DesignFocus', 'reference-tracking');
[C1_pid, info] = pidtune(simo_transfer1, 'PID', opts)

%get closed loop step response.
PID_ref_tracking = feedback(C1_pid*simo_transfer1, 1);

G11 = simo_transfer1(1)
G12 = simo_transfer2(2)

