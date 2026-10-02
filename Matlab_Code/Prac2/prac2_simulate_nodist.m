%% prac2_simulate_nodist.m
%
% EBB320 Practical 2 - System Simulation: Reference Tracking (No Disturbances)
%
% Simulates all 5 controllers in a standard unity-feedback loop with G11.
% No disturbance input is applied.
%
% Block diagram (matches Figure 1 in the practical guide):
%
%   r -->(+)--> Controller --> G11 --> y
%          ^                         |
%          |_________________________|  (negative feedback)
%
% Each figure has two stacked subplots:
%   Top    : Reference trajectory r(t) and controlled variable y(t)  [°C]
%   Bottom : Manipulated variable u(t)  [V  duty cycle 0-3.3V equiv]
%
% IMPORTANT: Run prac2_controllers.m FIRST to generate prac2_workspace.mat
%
% Reference step: 50 degC change from ambient (feasible operating point)
%
clear; clc; close all;

%% Load controllers and plant from workspace
if ~isfile('prac2_workspace.mat')
    error('prac2_workspace.mat not found. Run prac2_controllers.m first.');
end
load('prac2_workspace.mat');

%% Simulation settings
t_end    = 2000;          % simulation end time (s) - thermal system is slow
dt       = 0.5;           % time step (s)
t        = (0:dt:t_end)'; % time vector
r_step   = 50;            % reference step size (degC change from ambient)

% Reference signal
r = r_step * ones(size(t));

%% Controller list - only include controllers that exist in workspace
controllers = {};
names       = {};
colors      = {};

if exist('C1_p',  'var'), controllers{end+1} = C1_p;   names{end+1} = 'P';                      colors{end+1} = [0.18 0.44 0.72]; end
if exist('C1_pi', 'var'), controllers{end+1} = C1_pi;  names{end+1} = 'PI';                     colors{end+1} = [0.85 0.15 0.15]; end
if exist('C1_pd', 'var'), controllers{end+1} = C1_pd;  names{end+1} = 'PD';                     colors{end+1} = [0.13 0.63 0.13]; end
if exist('C1_pid','var'), controllers{end+1} = C1_pid; names{end+1} = 'PID (Reference Tracking)'; colors{end+1} = [0.75 0.10 0.75]; end
if exist('C2_pid','var'), controllers{end+1} = C2_pid; names{end+1} = 'PID (Disturbance Rejection)'; colors{end+1} = [0.85 0.50 0.10]; end

fprintf('Simulating %d controller(s): %s\n\n', numel(names), strjoin(names, ', '));

%% Saturation limits (PWM duty cycle in volts equivalent: 0 to 3.3 V)
u_min = 0;
u_max = 3.3;

%% Simulate each controller
for k = 1:numel(controllers)

    C   = controllers{k};
    name = names{k};
    col  = colors{k};

    % Build closed-loop transfer functions:
    %   Y/R = C*G11 / (1 + C*G11)   (output / reference)
    %   U/R = C     / (1 + C*G11)   (control signal / reference)
    CG      = C * G11;
    T_yr    = feedback(CG, 1);          % closed-loop output TF
    T_ur    = feedback(C, G11);         % control signal TF  (C / (1 + C*G11))

    % Simulate step responses
    [y_raw, ~] = step(r_step * T_yr, t);
    [u_raw, ~] = step(r_step * T_ur, t);

    % Clamp control signal to actuator limits
    u = min(max(u_raw, u_min), u_max);

    % ----- Figure -----
    fig = figure('Name', sprintf('No-Disturbance Simulation: %s Controller', name), ...
                 'Color', 'w', 'Units', 'normalized', ...
                 'Position', [0.05 0.08 0.88 0.78]);

    % -- Top subplot: reference vs output --
    ax1 = subplot(2, 1, 1);
    hold on;
    plot(t, r,     'k--', 'LineWidth', 1.2, 'DisplayName', 'Reference  r(t)');
    plot(t, y_raw, 'Color', col, 'LineWidth', 1.5, ...
         'DisplayName', sprintf('Output  y(t)  [%s]', name));
    hold off;
    grid on; grid minor; box on;
    ax1.Color          = 'w';
    ax1.XColor         = 'k';
    ax1.YColor         = 'k';
    ax1.GridColor      = [0.75 0.75 0.75];
    ax1.MinorGridColor = [0.88 0.88 0.88];
    ax1.FontSize       = 10;
    xlabel('Time  (s)',           'FontSize', 11, 'Color', 'k');
    ylabel('Temperature  (°C)',   'FontSize', 11, 'Color', 'k');
    title(sprintf('Reference Tracking — %s Controller  (No Disturbance)', name), ...
          'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');
    legend('Location', 'southeast', 'FontSize', 10, 'Color', 'w', 'TextColor', 'k');

    % Annotate steady-state error
    ss_y   = dcgain(T_yr) * r_step;
    ss_err = r_step - ss_y;
    text(t_end * 0.55, r_step * 0.15, ...
         sprintf('SS error = %.2f °C', ss_err), ...
         'FontSize', 9, 'Color', col, 'FontWeight', 'bold');

    % -- Bottom subplot: manipulated variable --
    ax2 = subplot(2, 1, 2);
    hold on;
    plot(t, u, 'Color', col, 'LineWidth', 1.5, ...
         'DisplayName', 'Manipulated variable  u(t)');
    yline(u_max, 'r--', 'LineWidth', 0.8, 'DisplayName', 'Saturation limit (3.3 V)');
    hold off;
    grid on; grid minor; box on;
    ax2.Color          = 'w';
    ax2.XColor         = 'k';
    ax2.YColor         = 'k';
    ax2.GridColor      = [0.75 0.75 0.75];
    ax2.MinorGridColor = [0.88 0.88 0.88];
    ax2.FontSize       = 10;
    xlabel('Time  (s)',                    'FontSize', 11, 'Color', 'k');
    ylabel('Control Signal  (V)',          'FontSize', 11, 'Color', 'k');
    title('Manipulated Variable  u(t)',    'FontSize', 11, 'FontWeight', 'bold', 'Color', 'k');
    legend('Location', 'northeast', 'FontSize', 10, 'Color', 'w', 'TextColor', 'k');
    ylim([u_min - 0.2,  u_max + 0.3]);

    % Link x-axes so zoom syncs
    linkaxes([ax1, ax2], 'x');

    % Save figure as PDF
    fname = sprintf('nodist_%s', strrep(name, ' ', '_'));
    fname = strrep(fname, '(', '');
    fname = strrep(fname, ')', '');
    figure(fig);
    print(gcf, fname, '-dpdf', '-bestfit');
    fprintf('Saved: %s.pdf\n', fname);
end

fprintf('\nAll no-disturbance simulation figures complete.\n');
fprintf('Run prac2_simulate_dist.m for the disturbance rejection simulations.\n');
