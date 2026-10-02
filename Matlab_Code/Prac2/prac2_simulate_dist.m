%% prac2_simulate_dist.m
%
% EBB320 Practical 2 - System Simulation: Disturbance Rejection
%
% Simulates all 5 controllers in a feedback loop with G11 as the plant
% and G12 as the disturbance path (transistor 2 -> temperature 1).
%
% Block diagram (matches Figure 2 in the practical guide):
%
%   d(t) --> G12 ----+
%                    v
%   r -->(+)--> C --> G11 -->(+)--> y
%          ^                         |
%          |_________________________|  (negative feedback)
%
% The disturbance d(t) is a step in PWM2 duty cycle (same scale as u).
%
% Each figure has two stacked subplots:
%   Top    : Reference r(t) and controlled variable y(t)  [°C]
%   Bottom : Manipulated variable u(t) AND disturbance d(t)  [V]
%
% IMPORTANT: Run prac2_controllers.m FIRST to generate prac2_workspace.mat
%
clear; clc; close all;

%% Load controllers and plant
if ~isfile('prac2_workspace.mat')
    error('prac2_workspace.mat not found. Run prac2_controllers.m first.');
end
load('prac2_workspace.mat');

%% Simulation settings
t_end  = 3000;            % s  — long enough to see disturbance rejection
dt     = 0.5;             % s
t      = (0:dt:t_end)';

% Reference: step to 50 degC change at t=0
r_step = 50;
r      = r_step * ones(size(t));

% Disturbance: PWM2 step applied after system has settled (~800 s)
% Using 50% of full scale (1.65 V out of 3.3 V) — same as the demo state 3
d_amplitude  = 1.65;       % V  (50% duty cycle equivalent)
t_dist_start = 800;        % s  — disturbance applied here
d = zeros(size(t));
d(t >= t_dist_start) = d_amplitude;

%% Actuator limits
u_min = 0;
u_max = 3.3;

%% Controller list - only include controllers that exist in workspace
controllers = {};
names       = {};
colors      = {};

if exist('C1_p',  'var'), controllers{end+1} = C1_p;   names{end+1} = 'P';                          colors{end+1} = [0.18 0.44 0.72]; end
if exist('C1_pi', 'var'), controllers{end+1} = C1_pi;  names{end+1} = 'PI';                         colors{end+1} = [0.85 0.15 0.15]; end
if exist('C1_pd', 'var'), controllers{end+1} = C1_pd;  names{end+1} = 'PD';                         colors{end+1} = [0.13 0.63 0.13]; end
if exist('C1_pid','var'), controllers{end+1} = C1_pid; names{end+1} = 'PID (Reference Tracking)';   colors{end+1} = [0.75 0.10 0.75]; end
if exist('C2_pid','var'), controllers{end+1} = C2_pid; names{end+1} = 'PID (Disturbance Rejection)';colors{end+1} = [0.85 0.50 0.10]; end

fprintf('Simulating %d controller(s): %s\n\n', numel(names), strjoin(names, ', '));

%% Simulate each controller
for k = 1:numel(controllers)

    C    = controllers{k};
    name = names{k};
    col  = colors{k};

    % ------------------------------------------------------------------ %
    % Transfer functions for the disturbed system:
    %
    %   Y = [C*G11/(1+C*G11)] * R  +  [G12/(1+C*G11)] * D
    %   U = [C/(1+C*G11)]     * R  -  [C*G11/(... wait, see below]
    %
    % More carefully:
    %   Let L = C*G11  (loop TF)
    %   Y/R = L/(1+L)          = feedback(C*G11, 1)
    %   Y/D = G12/(1+L)        = G12 * feedback(1, C*G11)  [= G12/(1+L)]
    %   U/R = C/(1+L)          = feedback(C, G11)
    %   U/D = -C*G12/(1+L)     = -C * G12/(1+L)
    %         (disturbance enters AFTER controller, so u is unaffected
    %          by d in this topology — see note below)
    %
    % NOTE on topology:
    %   In the guide's Figure 2, the disturbance d passes through G12 and
    %   sums with the G11 output AFTER the controller.  The controller
    %   sees the disturbance only through the feedback signal y.
    %   Therefore:
    %       U/D = -C*G12 / (1+C*G11)      (controller reacts to d via y)
    %       Y/D =    G12 / (1+C*G11)
    % ------------------------------------------------------------------ %

    L    = C * G11;
    S    = feedback(1, L);           % sensitivity  1/(1+L)

    T_yr = feedback(L, 1);           % Y/R  = L/(1+L)
    T_yd = G12 * S;                  % Y/D  = G12/(1+L)
    T_ur = feedback(C, G11);         % U/R  = C/(1+L)
    T_ud = -C * G12 * S;             % U/D  = -C*G12/(1+L)

    % Simulate using lsim for arbitrary disturbance signal
    % y = y_from_r + y_from_d
    % u = u_from_r + u_from_d
    y_r = lsim(T_yr, r,  t);
    y_d = lsim(T_yd, d,  t);
    u_r = lsim(T_ur, r,  t);
    u_d = lsim(T_ud, d,  t);

    y_total = y_r + y_d;
    u_total = u_r + u_d;

    % Clamp control signal to actuator limits
    u_clamped = min(max(u_total, u_min), u_max);

    % ----- Figure -----
    fig = figure('Name', sprintf('Disturbance Simulation: %s Controller', name), ...
                 'Color', 'w', 'Units', 'normalized', ...
                 'Position', [0.05 0.08 0.88 0.78]);

    % -- Top subplot: reference vs output --
    ax1 = subplot(2, 1, 1);
    hold on;
    plot(t, r,       'k--', 'LineWidth', 1.2, 'DisplayName', 'Reference  r(t)');
    plot(t, y_total, 'Color', col, 'LineWidth', 1.5, ...
         'DisplayName', sprintf('Output  y(t)  [%s]', name));
    % Mark disturbance onset
    xline(t_dist_start, 'r:', 'LineWidth', 1.0, ...
          'Label', sprintf('Disturbance ON  (t = %d s)', t_dist_start), ...
          'LabelVerticalAlignment', 'bottom', 'HandleVisibility', 'off');
    hold off;
    grid on; grid minor; box on;
    ax1.Color          = 'w';
    ax1.XColor         = 'k';
    ax1.YColor         = 'k';
    ax1.GridColor      = [0.75 0.75 0.75];
    ax1.MinorGridColor = [0.88 0.88 0.88];
    ax1.FontSize       = 10;
    xlabel('Time  (s)',          'FontSize', 11, 'Color', 'k');
    ylabel('Temperature  (°C)',  'FontSize', 11, 'Color', 'k');
    title(sprintf('Disturbance Rejection — %s Controller', name), ...
          'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');
    legend('Location', 'southeast', 'FontSize', 10, 'Color', 'w', 'TextColor', 'k');

    % -- Bottom subplot: manipulated variable + disturbance --
    ax2 = subplot(2, 1, 2);
    hold on;
    plot(t, u_clamped, 'Color', col, 'LineWidth', 1.5, ...
         'DisplayName', 'Manipulated variable  u(t)  [PWM1 V]');
    plot(t, d, 'Color', [0.4 0.4 0.4], 'LineWidth', 1.2, 'LineStyle', '--', ...
         'DisplayName', sprintf('Disturbance  d(t)  [PWM2 V,  %.2f V step]', d_amplitude));
    yline(u_max, 'r:', 'LineWidth', 0.8, 'DisplayName', 'Saturation limit (3.3 V)');
    hold off;
    grid on; grid minor; box on;
    ax2.Color          = 'w';
    ax2.XColor         = 'k';
    ax2.YColor         = 'k';
    ax2.GridColor      = [0.75 0.75 0.75];
    ax2.MinorGridColor = [0.88 0.88 0.88];
    ax2.FontSize       = 10;
    xlabel('Time  (s)',                                      'FontSize', 11, 'Color', 'k');
    ylabel('Signal  (V)',                                    'FontSize', 11, 'Color', 'k');
    title('Manipulated Variable  u(t)  &  Disturbance  d(t)', 'FontSize', 11, 'FontWeight', 'bold', 'Color', 'k');
    legend('Location', 'northeast', 'FontSize', 10, 'Color', 'w', 'TextColor', 'k');
    ylim([-0.3,  u_max + 0.5]);

    linkaxes([ax1, ax2], 'x');

    % Save PDF
    fname = sprintf('dist_%s', strrep(name, ' ', '_'));
    fname = strrep(fname, '(', '');
    fname = strrep(fname, ')', '');
    figure(fig);
    print(gcf, fname, '-dpdf', '-bestfit');
    fprintf('Saved: %s.pdf\n', fname);
end

fprintf('\nAll disturbance simulation figures complete.\n');
fprintf('\nCompare the PID(ref) and PID(dist) responses:\n');
fprintf('  - PID(ref) is tuned for fast setpoint tracking but may recover\n');
fprintf('    more slowly from the disturbance.\n');
fprintf('  - PID(dist) is tuned to reject disturbances quickly at the cost\n');
fprintf('    of potentially slower or more aggressive reference tracking.\n');
