%% prac2_plot_for_report.m
%
% EBB320 Practical 2 - Generate report-quality figures for P and PI controllers.
%
% Produces 6 PNGs saved directly to the Prac-2-Report/Images/ folder:
%   P_nodist_response.png      -- 2-subplot: ref tracking, no disturbance
%   P_dist_response.png        -- 2-subplot: ref tracking, with disturbance
%   P_ol_vs_cl.png             -- single plot: open-loop vs closed-loop
%   PI_nodist_response.png
%   PI_dist_response.png
%   PI_ol_vs_cl.png
%
% Each figure has two subplots:
%   Top    -- reference r(t)  +  controlled variable y(t)  [degC]
%   Bottom -- manipulated variable u(t)  [V]  (+ disturbance d(t) for dist case)
%
% Run prac2_controllers.m first to generate prac2_workspace.mat.
% Working directory must be the Prac2 folder when running this script.
%
clear; clc; close all;

%% =========================================================================
%  0. Load workspace
% ==========================================================================
if ~isfile('prac2_workspace.mat')
    error('Run prac2_controllers.m first to generate prac2_workspace.mat');
end
load('prac2_workspace.mat');   % loads G11, G12, C1_p, C1_pi

% Output folder -- resolve absolute path
img_dir = fullfile(pwd, '..', '..', 'Prac-2-Report', 'Images');
img_dir = char(java.io.File(img_dir).getCanonicalPath());
fprintf('Saving figures to: %s\n', img_dir);
if ~exist(img_dir, 'dir')
    error('Images folder not found at: %s', img_dir);
end

%% =========================================================================
%  1. Simulation parameters
% ==========================================================================
r_step       = 50;    % reference step magnitude (degC)
d_amplitude  = 1.65;  % disturbance step magnitude (V) -- 50% duty cycle
t_dist_start = 350;   % disturbance start time (s)

t_nodist = 0:1:700;   % time vector for no-disturbance case
t_dist   = 0:1:700;   % time vector for disturbance case

%% =========================================================================
%  2. Controller loop
% ==========================================================================
ctrl_names  = {'P',  'PI'};
ctrl_objs   = {C1_p, C1_pi};
ctrl_colors = {[0.18 0.44 0.72], ...   % blue -- P
               [0.85 0.15 0.15]};      % red  -- PI

for k = 1:numel(ctrl_names)

    name = ctrl_names{k};
    C    = ctrl_objs{k};
    col  = ctrl_colors{k};

    % Closed-loop transfer functions
    L    = C * G11;
    T_yr = feedback(L, 1);        % y/r (reference to output)
    T_ur = feedback(C, G11);      % u/r (reference to control effort)

    % --- A. NO-DISTURBANCE CASE ---
    y_nd = r_step * step(T_yr, t_nodist);
    u_nd = r_step * step(T_ur, t_nodist);
    u_nd = min(max(u_nd, 0), 3.3);

    fig_nd = make_figure(t_nodist, y_nd, r_step, u_nd, [], [], ...
                         name, col, false);

    fname_nd = fullfile(img_dir, [name '_nodist_response.png']);
    exportgraphics(fig_nd, fname_nd, 'Resolution', 300, 'BackgroundColor', 'white');
    fprintf('Saved: %s\n', fname_nd);

    % --- C. OPEN-LOOP vs CLOSED-LOOP COMPARISON ---
    t_compare = (0:1:1500)';             % shared time axis for both curves

    % Open-loop: unit step on G11, scaled to r_step final value
    y_ol = lsim(G11, ones(size(t_compare)), t_compare);
    y_ol = y_ol * (r_step / dcgain(G11));  % scale so DC value = r_step

    % Closed-loop: step to r_step over same window
    y_cl = r_step * step(T_yr, t_compare);

    fig_ol = figure('Color', 'w', 'Units', 'centimeters', 'Position', [2 2 18 9]);
    hold on;
    plot(t_compare, y_ol, 'Color', [0.18 0.44 0.72], 'LineWidth', 1.5, ...
         'DisplayName', 'Open Loop');
    plot(t_compare, y_cl, 'Color', [0.93 0.69 0.13], 'LineWidth', 1.5, ...
         'DisplayName', 'Closed Loop');
    yline(r_step, 'k--', 'LineWidth', 1.0, 'HandleVisibility', 'off');
    hold off;
    grid on; box on;
    ax = gca;
    ax.Color = 'w'; ax.XColor = 'k'; ax.YColor = 'k';
    ax.GridColor = [0.75 0.75 0.75]; ax.FontSize = 10;
    ax.TickDir = 'in'; ax.LineWidth = 0.8;
    xlabel('Time (s)', 'FontSize', 11, 'Color', 'k');
    ylabel('Temperature (degC)', 'FontSize', 11, 'Color', 'k');
    title([name ' Controller - Closed Loop vs Open Loop Response'], ...
          'FontSize', 11, 'FontWeight', 'bold', 'Color', 'k');
    legend('Location', 'southeast', 'FontSize', 9, 'Box', 'on', ...
           'Color', 'w', 'TextColor', 'k');
    ylim([0 r_step * 1.30]);
    xlim([0 1500]);

    fname_ol = fullfile(img_dir, [name '_ol_vs_cl.png']);
    exportgraphics(fig_ol, fname_ol, 'Resolution', 300, 'BackgroundColor', 'white');
    fprintf('Saved: %s\n', fname_ol);



    % --- B. DISTURBANCE CASE ---
    S     = feedback(1, L);
    T_yd  = G12 * S;
    T_ud  = -C * G12 * S;

    d_vec = zeros(size(t_dist));
    d_vec(t_dist >= t_dist_start) = d_amplitude;

    y_r   = r_step * step(T_yr, t_dist);
    y_d   = lsim(T_yd, d_vec, t_dist);
    y_tot = y_r + y_d;

    u_r   = r_step * step(T_ur, t_dist);
    u_d   = lsim(T_ud, d_vec, t_dist);
    u_tot = min(max(u_r + u_d, 0), 3.3);

    fig_d = make_figure(t_dist, y_tot, r_step, u_tot, d_vec, d_amplitude, ...
                        name, col, true);

    fname_d = fullfile(img_dir, [name '_dist_response.png']);
    exportgraphics(fig_d, fname_d, 'Resolution', 300, 'BackgroundColor', 'white');
    fprintf('Saved: %s\n', fname_d);

end

fprintf('\nDone. All 4 figures saved to Images/\n');

%% =========================================================================
%  Helper function -- builds a 2-subplot report figure
%  Args:
%    t         -- time vector
%    y         -- output temperature (degC)
%    r         -- reference step value (degC)
%    u         -- control signal (V)
%    d_vec     -- disturbance vector ([] for no-dist case)
%    d_amp     -- disturbance amplitude for legend ([] for no-dist)
%    ctrl_name -- label string e.g. 'P' or 'PI'
%    col       -- [r g b] line colour
%    is_dist   -- logical, true = disturbance case
% ==========================================================================
function fig = make_figure(t, y, r, u, d_vec, d_amp, ctrl_name, col, is_dist)

    fig = figure('Color', 'w', 'Units', 'centimeters', 'Position', [2 2 18 12]);

    % ---- Top subplot: reference + output ----
    ax1 = subplot(2, 1, 1);
    hold on;
    plot(t, r * ones(size(t)), 'k--', 'LineWidth', 1.2, ...
         'DisplayName', 'Reference r(t)');
    plot(t, y, 'Color', col, 'LineWidth', 1.5, ...
         'DisplayName', ['Output y(t) - ' ctrl_name]);
    hold off;

    if is_dist && ~isempty(d_vec)
        idx = find(d_vec > 0, 1);
        if ~isempty(idx)
            xline(t(idx), ':', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.0, ...
                  'HandleVisibility', 'off');
        end
    end

    grid on; box on;
    ax1.Color     = 'w'; ax1.XColor = 'k'; ax1.YColor = 'k';
    ax1.GridColor = [0.75 0.75 0.75];
    ax1.FontSize  = 10; ax1.TickDir = 'in'; ax1.LineWidth = 0.8;
    ylabel('Temperature (degC)', 'FontSize', 11, 'Color', 'k');

    if is_dist
        title([ctrl_name ' Controller - Reference Tracking with Disturbance (G12)'], ...
              'FontSize', 11, 'FontWeight', 'bold', 'Color', 'k');
    else
        title([ctrl_name ' Controller - Reference Tracking, No Disturbance'], ...
              'FontSize', 11, 'FontWeight', 'bold', 'Color', 'k');
    end

    legend('Location', 'southeast', 'FontSize', 9, 'Box', 'on', ...
           'Color', 'w', 'TextColor', 'k');

    % ---- Bottom subplot: u(t) [+ d(t)] ----
    ax2 = subplot(2, 1, 2);
    hold on;
    plot(t, u, 'Color', col, 'LineWidth', 1.5, ...
         'DisplayName', 'Manip. var. u(t) - PWM1 (V)');
    if is_dist && ~isempty(d_vec)
        plot(t, d_vec, '--', 'Color', [0.40 0.40 0.40], 'LineWidth', 1.2, ...
             'DisplayName', sprintf('Disturbance d(t) - PWM2 (%.2f V)', d_amp));
    end
    yline(3.3, ':', 'Color', [0.85 0.15 0.15], 'LineWidth', 0.8, ...
          'DisplayName', 'Saturation (3.3 V)');
    hold off;

    grid on; box on;
    ax2.Color     = 'w'; ax2.XColor = 'k'; ax2.YColor = 'k';
    ax2.GridColor = [0.75 0.75 0.75];
    ax2.FontSize  = 10; ax2.TickDir = 'in'; ax2.LineWidth = 0.8;
    ylim([-0.2 3.8]);
    xlabel('Time (s)', 'FontSize', 11, 'Color', 'k');
    ylabel('Voltage (V)', 'FontSize', 11, 'Color', 'k');
    title('Manipulated Variable u(t)', 'FontSize', 11, ...
          'FontWeight', 'bold', 'Color', 'k');
    legend('Location', 'southeast', 'FontSize', 9, 'Box', 'on', ...
           'Color', 'w', 'TextColor', 'k', 'NumColumns', 1);

    linkaxes([ax1 ax2], 'x');
    xlim([t(1) t(end)]);

end
