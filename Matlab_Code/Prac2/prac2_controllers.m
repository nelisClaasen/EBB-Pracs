%% prac2_controllers.m
%
% EBB320 Practical 2 - Controller Design
%
% JUNIOR tasks (this file):
%   - Design P controller  (simulate only)
%   - Design PI controller (simulate only)
%
% ALL tasks (this file):
%   - Define G11, G12 plant models
%   - Compute stepinfo metrics for all 5 controllers
%   - Print parameter and step-response tables
%   - Save workspace for simulation scripts
%
% TEAMMATE tasks (commented out - uncomment and fill in gains when received):
%   - PD controller          (Nelis)
%   - PID reference-tracking (Nelis)
%   - PID disturbance-rejection (Hanre)
%
% Run this script FIRST before the simulation scripts.
% Working directory must be the Prac2 folder.
%
clear; clc; close all;

%% =========================================================================
%  1. Plant transfer functions from Practical 1 (tfest results)  [ALL]
% ==========================================================================

% G11: PWM1 -> Temperature 1  (plant used to design all controllers)
G11 = tf([-0.1974, 0.0530], [1, 0.4582, 0.0034]);

% G12: PWM2 -> Temperature 1  (disturbance path, used in disturbed sim only)
G12 = tf([-0.0156, 0.0010], [1, 0.0300, 0.0002]);

fprintf('G11:\n'); disp(G11);
fprintf('G12 (disturbance path):\n'); disp(G12);

%% =========================================================================
%  2. Open-loop step response info (baseline)  [ALL]
% ==========================================================================
fprintf('=== Open-Loop Step Response (G11, no controller) ===\n');
info_OL = stepinfo(G11);
fprintf('  Rise Time    : %s s\n',  num2str(info_OL.RiseTime,   '%.1f'));
fprintf('  Peak Time    : %s s\n',  num2str(info_OL.PeakTime,   '%.1f'));
fprintf('  Settling Time: %s s\n',  num2str(info_OL.SettlingTime,'%.1f'));
fprintf('  Overshoot    : %s %%\n', num2str(info_OL.Overshoot,  '%.2f'));
fprintf('  DC Gain (K)  : %.4f\n\n', dcgain(G11));

%% =========================================================================
%  3. P controller  [JUNIOR - simulate only, NOT on MCU]
% ==========================================================================
[C1_p, info_p] = pidtune(G11, 'P');

fprintf('=== P Controller ===\n');
fprintf('  Kp = %.6f\n', C1_p.Kp);
fprintf('  Achieved Phase Margin: %.1f deg\n\n', info_p.PhaseMargin);

CL_p      = feedback(C1_p * G11, 1);
info_CL_p = stepinfo(CL_p, 'SettlingTimeThreshold', 0.02);

fprintf('  Closed-Loop Step Response:\n');
fprintf('    Rise Time    : %.1f s\n',  info_CL_p.RiseTime);
fprintf('    Peak Time    : %.1f s\n',  info_CL_p.PeakTime);
fprintf('    Settling Time: %.1f s\n',  info_CL_p.SettlingTime);
fprintf('    Overshoot    : %.2f %%\n', info_CL_p.Overshoot);
fprintf('    SS Gain      : %.4f\n\n',  dcgain(CL_p));

%% =========================================================================
%  4. PI controller  [JUNIOR - simulate only, NOT on MCU]
% ==========================================================================
[C1_pi, info_pi] = pidtune(G11, 'PI');

fprintf('=== PI Controller ===\n');
fprintf('  Kp = %.6f\n', C1_pi.Kp);
fprintf('  Ki = %.6f\n', C1_pi.Ki);
fprintf('  Achieved Phase Margin: %.1f deg\n\n', info_pi.PhaseMargin);

CL_pi      = feedback(C1_pi * G11, 1);
info_CL_pi = stepinfo(CL_pi, 'SettlingTimeThreshold', 0.02);

fprintf('  Closed-Loop Step Response:\n');
fprintf('    Rise Time    : %.1f s\n',  info_CL_pi.RiseTime);
fprintf('    Peak Time    : %.1f s\n',  info_CL_pi.PeakTime);
fprintf('    Settling Time: %.1f s\n',  info_CL_pi.SettlingTime);
fprintf('    Overshoot    : %.2f %%\n', info_CL_pi.Overshoot);
fprintf('    SS Gain      : %.4f\n\n',  dcgain(CL_pi));

%% =========================================================================
%  5. TEAMMATE controllers - commented out until gains are provided
% ==========================================================================

% --- PD controller (Nelis) ---
% Uncomment and replace Kp/Kd with Nelis's pidtune values when received.
% [C1_pd, info_pd] = pidtune(G11, 'PD');
% fprintf('=== PD Controller ===\n');
% fprintf('  Kp = %.6f\n', C1_pd.Kp);
% fprintf('  Kd = %.6f\n', C1_pd.Kd);
% fprintf('  Achieved Phase Margin: %.1f deg\n\n', info_pd.PhaseMargin);
% CL_pd      = feedback(C1_pd * G11, 1);
% info_CL_pd = stepinfo(CL_pd, 'SettlingTimeThreshold', 0.02);

% --- Reference-tracking PID (Nelis) ---
% Uncomment and replace with Nelis's pidtune values when received.
% opts_ref   = pidtuneOptions('DesignFocus', 'reference-tracking');
% [C1_pid, info_pid_ref] = pidtune(G11, 'PID', opts_ref);
% fprintf('=== Reference-Tracking PID ===\n');
% fprintf('  Kp = %.6f\n', C1_pid.Kp);
% fprintf('  Ki = %.6f\n', C1_pid.Ki);
% fprintf('  Kd = %.6f\n', C1_pid.Kd);
% fprintf('  Achieved Phase Margin: %.1f deg\n\n', info_pid_ref.PhaseMargin);
% CL_pid_ref      = feedback(C1_pid * G11, 1);
% info_CL_pid_ref = stepinfo(CL_pid_ref, 'SettlingTimeThreshold', 0.02);

% --- Disturbance-rejection PID (Hanre) ---
% Uncomment and replace with Hanre's pidtune values when received.
% opts_dist  = pidtuneOptions('DesignFocus', 'disturbance-rejection');
% [C2_pid, info_pid_dist] = pidtune(G11, 'PID', opts_dist);
% fprintf('=== Disturbance-Rejection PID ===\n');
% fprintf('  Kp = %.6f\n', C2_pid.Kp);
% fprintf('  Ki = %.6f\n', C2_pid.Ki);
% fprintf('  Kd = %.6f\n', C2_pid.Kd);
% fprintf('  Achieved Phase Margin: %.1f deg\n\n', info_pid_dist.PhaseMargin);
% CL_pid_dist      = feedback(C2_pid * G11, 1);
% info_CL_pid_dist = stepinfo(CL_pid_dist, 'SettlingTimeThreshold', 0.02);

%% =========================================================================
%  6. Parameter summary table (P and PI only for now)  [ALL]
% ==========================================================================
fprintf('\n+--------------------------------------------------+\n');
fprintf('| Controller Parameter Summary (Junior tasks)      |\n');
fprintf('+------------+-----------+-----------+------------+\n');
fprintf('| Controller |    Kp     |    Ki     |    Kd      |\n');
fprintf('+------------+-----------+-----------+------------+\n');
fprintf('| P          | %9.6f |     -     |     -      |\n', C1_p.Kp);
fprintf('| PI         | %9.6f | %9.6f |     -      |\n', C1_pi.Kp, C1_pi.Ki);
fprintf('+------------+-----------+-----------+------------+\n\n');

%% =========================================================================
%  7. Step-response metrics table (P and PI only for now)  [ALL]
% ==========================================================================
fprintf('+-----------------------------------------------------------+\n');
fprintf('| Step Response Metrics (2%% settling)                      |\n');
fprintf('+------------+----------+----------+----------+------------+\n');
fprintf('| Controller | Rise (s) | Peak (s) | Sett (s) |   OS (%%)  |\n');
fprintf('+------------+----------+----------+----------+------------+\n');
fprintf('| P          | %8.1f | %8.1f | %8.1f | %9.2f |\n', ...
    info_CL_p.RiseTime,  info_CL_p.PeakTime,  info_CL_p.SettlingTime,  info_CL_p.Overshoot);
fprintf('| PI         | %8.1f | %8.1f | %8.1f | %9.2f |\n', ...
    info_CL_pi.RiseTime, info_CL_pi.PeakTime, info_CL_pi.SettlingTime, info_CL_pi.Overshoot);
fprintf('+------------+----------+----------+----------+------------+\n\n');

%% =========================================================================
%  8. Step response comparison plot (P and PI)  [ALL]
% ==========================================================================
t_step = 0:1:2000;

% Simulate step responses manually so we can control line properties
[y_p,  t_out] = step(CL_p,  t_step);
[y_pi, ~    ] = step(CL_pi, t_step);

figure('Name', 'Closed-Loop Step Response: P vs PI', 'Color', 'w', ...
       'Units', 'normalized', 'Position', [0.05 0.1 0.88 0.70]);
hold on;
plot(t_out, y_p,  'Color', [0.18 0.44 0.72], 'LineWidth', 1.5, 'DisplayName', 'P controller');
plot(t_out, y_pi, 'Color', [0.85 0.15 0.15], 'LineWidth', 1.5, 'DisplayName', 'PI controller');
hold off;

grid on; box on;
ax = gca;
ax.Color            = [1 1 1];
ax.XColor           = [0 0 0];
ax.YColor           = [0 0 0];
ax.GridColor        = [0.75 0.75 0.75];
ax.MinorGridColor   = [0.88 0.88 0.88];
ax.FontSize         = 11;
ax.LineWidth        = 0.8;
xlabel('Time  (s)',                  'FontSize', 12, 'Color', 'k');
ylabel('Temperature Change  (degC)',   'FontSize', 12, 'Color', 'k');
title('Closed-Loop Step Response: P and PI Controllers (G_{11})', ...
      'FontSize', 13, 'FontWeight', 'bold', 'Color', 'k');
legend('Location', 'southeast', 'FontSize', 11, 'Box', 'on', ...
       'Color', 'w', 'TextColor', 'k');
set(gcf, 'Color', 'w');

%% =========================================================================
%  9. Save workspace  [ALL]
%     Simulation scripts will add teammate controllers once uncommented.
% ==========================================================================
save('prac2_workspace.mat', ...
     'G11', 'G12', ...
     'C1_p', 'C1_pi', ...
     'CL_p', 'CL_pi', ...
     'info_CL_p', 'info_CL_pi');

fprintf('Workspace saved to prac2_workspace.mat\n');
fprintf('Uncomment teammate sections (PD, PID_ref, PID_dist) when\n');
fprintf('Nelis and Hanre provide their gains, then re-run this script.\n\n');
