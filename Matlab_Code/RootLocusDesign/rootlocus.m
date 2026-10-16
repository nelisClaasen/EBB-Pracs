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
simo_transfer1 = tfest(tfest_data1(:, 1, 1), n_poles, n_zeros, NaN) % PWM1 to T1
simo_transfer2 = tfest(tfest_data2(:, 2, 1), n_poles, n_zeros, NaN) % PWM2 to T2

% s = tf('s');
% C =  1.17921 * (s + 0.1) * (s + 0.0295055) / s;
% GC_G11 = C * pade(simo_transfer1, 1);
% 
% rlocus(GC_G11);
% grid on;

% s = tf('s');
% G = (0.1175 / (s + 0.007592)) * exp(-0.145*s);
% 
% % Closed-loop step response
% T = feedback(C*G, 1);
% step(T);
% grid on;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% For G11 %%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1. Define Plant and Padé Approximation
s = tf('s');
K_plant = 0.1175;
a = 0.007592;
L = 0.145;

G_exact = (K_plant / (s + a)) * exp(-L*s);
G_pade = pade(G_exact, 1); % 1st-order Padé approximation

% 2. Define Controller Zeros and Unscaled PID
z1 = 0.1;
z2 = 0.0295055;
C_unscaled = (s + z1) * (s + z2) / s; % C(s) without Kc gain

% 3. Open-Loop Transfer Function for Root Locus
L_sys = C_unscaled * G_pade;

% 4. Target Design Specifications
Mp = 0.10; % 10% overshoot
zeta = -log(Mp) / sqrt(pi^2 + (log(Mp))^2); % ~0.5912

tr_uncomp = log(9) / a;
tr_req = tr_uncomp / 3; % ~96.47 seconds
wn = (1.76*zeta^3 - 0.417 * zeta^2 + 1.039*zeta + 1)/tr_req; %(pi - acos(zeta)) / (tr_req * sqrt(1 - zeta^2)); % ~0.0283 rad/s

% Target closed-loop dominant pole
sd_real = -zeta * wn;
sd_imag = wn * sqrt(1 - zeta^2);
sd = sd_real + 1i*sd_imag;

% 5. Plot Root Locus
figure('Name', 'Root Locus PID Verification');
rlocus(L_sys);
hold on;

% Overlay damping ratio and natural frequency grid
sgrid(zeta, wn);

% Mark the desired closed-loop pole s_d
plot(real(sd), imag(sd), 'r*', 'MarkerSize', 12, 'LineWidth', 2, 'DisplayName', 'Target s_d');
plot(real(sd), -imag(sd), 'r*', 'MarkerSize', 12, 'LineWidth', 2, 'HandleVisibility', 'off');

% Formatting
title('Root Locus with Padé Approximation G11');
legend('show', 'Location', 'best');
axis([-0.1 0.02 -0.05 0.05]); % Zoom into relevant locus area
grid on;
hold off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% For G22 %%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1. Define Plant and Padé Approximation
s = tf('s');
K_plant = 0.05872;
a = 0.005984;
L = 0.145;

G_exact = (K_plant / (s + a)) * exp(-L*s);
G_pade = pade(G_exact, 1); % 1st-order Padé approximation

% 2. Define Controller Zeros and Unscaled PID
z1 = 0.1;
z2 = 0.0221733;
C_unscaled = (s + z1) * (s + z2) / s; % C(s) without Kc gain

% 3. Open-Loop Transfer Function for Root Locus
L_sys = C_unscaled * G_pade;

% 4. Target Design Specifications
Mp = 0.10; % 10% overshoot
zeta = -log(Mp) / sqrt(pi^2 + (log(Mp))^2); % ~0.5912

tr_uncomp = log(9) / a;
tr_req = tr_uncomp / 3; % ~96.47 seconds
wn = (1.76*zeta^3 - 0.417 * zeta^2 + 1.039*zeta + 1)/tr_req; %(pi - acos(zeta)) / (tr_req * sqrt(1 - zeta^2)); % ~0.0283 rad/s

% Target closed-loop dominant pole
sd_real = -zeta * wn;
sd_imag = wn * sqrt(1 - zeta^2);
sd = sd_real + 1i*sd_imag;

% 5. Plot Root Locus
figure('Name', 'Root Locus PID Verification');
rlocus(L_sys);
hold on;

% Overlay damping ratio and natural frequency grid
sgrid(zeta, wn);

% Mark the desired closed-loop pole s_d
plot(real(sd), imag(sd), 'r*', 'MarkerSize', 12, 'LineWidth', 2, 'DisplayName', 'Target s_d');
plot(real(sd), -imag(sd), 'r*', 'MarkerSize', 12, 'LineWidth', 2, 'HandleVisibility', 'off');

% Formatting
title('Root Locus with Padé Approximation G22');
legend('show', 'Location', 'best');
axis([-0.1 0.02 -0.05 0.05]); % Zoom into relevant locus area
grid on;
hold off;

% G11_info = stepinfo(out.G11.Data, out.G11.Time)
G22_info = stepinfo(out.G22.Data, out.G22.Time)