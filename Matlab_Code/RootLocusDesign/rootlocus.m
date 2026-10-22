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
% simo_transfer1 = tfest(tfest_data1(:, 1, 1), n_poles, n_zeros, NaN) % PWM1 to T1
% simo_transfer2 = tfest(tfest_data2(:, 2, 1), n_poles, n_zeros, NaN) % PWM2 to T2
% G12 = tfest(tfest_data2(:, 1, 1), n_poles, n_zeros, NaN)
% G21 = tfest(tfest_data1(:, 2, 1), n_poles, n_zeros, NaN)

s = tf('s');
G11 = exp(-0.145*s) * (0.1175/(s + 0.007592));
G22 = exp(-0.145*s) * (0.05872/(s + 0.005984));
G12 = exp(-0.145*s) * (0.03658/(s + 0.005254));
G21 = exp(-0.145*s) * (0.06368/(s + 0.006012));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% For G11 %%%%%%%%%%%%%%%%%%%%%%%%%%%
G_c11 = 1.17921 * ((s + 0.1)*(s + 0.0295055)/s);
plotRootLocus(G11, G_c11, 1.17921, "Root Locus with Padé Approximation for G11", "G11_root.pdf");

omega_n = 0.018967;
zeta = 0.5912;

G11_SecondOrder = (omega_n^2)/(s^2 + 2*zeta*omega_n*s + omega_n^2);

plotStep(G11, G_c11, G11, "Open Loop vs PID Closed Loop Step Response for G11", "G11_time.pdf");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% For G22 %%%%%%%%%%%%%%%%%%%%%%%%%%%
G_c22 = 1.90571 * ((s + 0.1)*(s + 0.0221733)/s);
plotRootLocus(G22, G_c22, 1.90571, "Root Locus with Padé Approximation for G22", "G22_root.pdf");

omega_n = 0.01495;
zeta = 0.5912;

G22_SecondOrder = (omega_n^2)/(s^2 + 2*zeta*omega_n*s + omega_n^2);

plotStep(G22, G_c22, G22, "Open Loop vs PID Closed Loop Step Response for G22", "G22_time.pdf");

function plotStep(plant, controller, Second_order_approx, figName, fileSaveName)

opts = timeoptions('cstprefs');
opts.Title.FontSize = 14;
opts.XLabel.FontSize = 14;
opts.YLabel.FontSize = 14;
opts.TickLabel.FontSize = 10;

%Get feedback tf
G_closed = feedback(controller * plant, 1);

%Plot ideal 2nd order response with controlled tf.
figure;
hold on;
stepplot(G_closed, opts, Name="Closed Loop", LineWidth=2);
stepplot(Second_order_approx/dcgain(Second_order_approx), opts, Name="Open Loop", LineWidth=2);
legend('Location','best', FontSize=14);
title(figName);

%Print out table comparing characteristics of the two.
G_closed_info = stepinfo(G_closed);
ideal_info = stepinfo(Second_order_approx);

fields = fieldnames(G_closed_info);

disp("For" + figName)
for i = 1:numel(fields)
    fieldName = fields{i};
    fieldValue_open = ideal_info.(fieldName);
    fieldValue_closed = G_closed_info.(fieldName);

    fprintf('%s & %.2f & %.2f \\\\ \n', fieldName, fieldValue_open, fieldValue_closed);
end

%Update font sizes.
fontsize(gcf, 14, "points");
hold off;

filepath = fullfile('..', '..', 'Prac-3-Report', 'Images', 'RootLocus', fileSaveName);
exportgraphics(gcf, filepath, 'ContentType','vector');

end

function plotRootLocus(plant, controller, K_c, figName, fileSaveName)
G_pade = pade(plant, 1);
G_c = 1/K_c * controller;

L_sys = G_pade * G_c;

figure("Name", 'Root Locus PID Verification')
rlocus(L_sys)
% set(findall(gca, 'Type', 'Line'), 'LineWidth', 2); % Change 2 to your desired thickness
hold on;

% 4. Target Design Specifications
Mp = 0.10; % 10% overshoot
zeta = -log(Mp) / sqrt(pi^2 + (log(Mp))^2); % ~0.5912

tr_uncomp = log(9) / plant.Denominator{1}(2);
tr_req = tr_uncomp / 3; % ~96.47 seconds
wn = (1.76*zeta^3 - 0.417 * zeta^2 + 1.039*zeta + 1)/tr_req; %(pi - acos(zeta)) / (tr_req * sqrt(1 - zeta^2)); % ~0.0283 rad/s

% Target closed-loop dominant pole
sd_real = -zeta * wn;
sd_imag = wn * sqrt(1 - zeta^2);
sd = sd_real + 1i*sd_imag;

% Overlay damping ratio and natural frequency grid
sgrid(zeta, wn);

% Mark the desired closed-loop pole s_d
% plot(real(sd), imag(sd), 'r*', 'MarkerSize', 12, 'LineWidth', 2, 'DisplayName', 'Target s_d');
% plot(real(sd), -imag(sd), 'r*', 'MarkerSize', 12, 'LineWidth', 2, 'HandleVisibility', 'off');

% Formatting
title(figName);
legend('show', 'Location', 'best');
axis([-0.12 0.02 -0.05 0.05]); % Zoom into relevant locus area
grid on;

% 2. Find the Root Locus Line Closest to target s_d
sd_target = sd; % Your target s_d
hLines = findobj(gca, 'Type', 'Line');
bestLine = [];
bestIdx = 1;
minDist = inf;

for k = 1:length(hLines)
    xData = hLines(k).XData;
    yData = hLines(k).YData;
    if ~isempty(xData)
        dist = (xData - real(sd_target)).^2 + (yData - imag(sd_target)).^2;
        [val, idx] = min(dist);
        if val < minDist
            minDist = val;
            bestLine = hLines(k);
            bestIdx = idx;
        end
    end
end

% 3. Create Native Data Tip (Modern R2019b+ syntax)
if ~isempty(bestLine)
    targetX = bestLine.XData(bestIdx);
    targetY = bestLine.YData(bestIdx);

    % Directly attach data tip to line object
    dt = datatip(bestLine, targetX, targetY);
end

%Update font sizes.
fontsize(gcf, 14, "points");
hold off;

filepath = fullfile('..', '..', 'Prac-3-Report', 'Images', 'RootLocus', fileSaveName);
exportgraphics(gcf, filepath, 'ContentType','vector');
end