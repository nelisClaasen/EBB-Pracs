%% prac2_setup_and_run_simulink.m
%
% EBB320 Practical 2 - Run Simulink simulations and plot results
%
% This script:
%   1. Loads controller gains from prac2_workspace.mat
%   2. Configures prac2_nodist.slx with each controller and runs it
%   3. Configures prac2_dist.slx with each controller and runs it
%   4. Plots the required 2-subplot figures for each controller
%
% Run prac2_controllers.m first to generate prac2_workspace.mat
%
clear; clc; close all;

% Set to true to also save PDFs, false to just view figures on screen only
SAVE_PDF = false;

%% Load workspace
if ~isfile('prac2_workspace.mat')
    error('Run prac2_controllers.m first to generate prac2_workspace.mat');
end
load('prac2_workspace.mat');

%% Controller list (add teammates when available)
ctrl_names = {'P', 'PI'};
ctrl_Kp    = [C1_p.Kp,  C1_pi.Kp ];
ctrl_Ki    = [0,         C1_pi.Ki ];
ctrl_Kd    = [0,         0        ];

% --- Uncomment when teammates provide gains ---
% ctrl_names{end+1} = 'PD';          ctrl_Kp(end+1) = ???; ctrl_Ki(end+1) = 0;       ctrl_Kd(end+1) = ???;
% ctrl_names{end+1} = 'PID (Ref)';   ctrl_Kp(end+1) = ???; ctrl_Ki(end+1) = ???;     ctrl_Kd(end+1) = ???;
% ctrl_names{end+1} = 'PID (Dist)';  ctrl_Kp(end+1) = ???; ctrl_Ki(end+1) = ???;     ctrl_Kd(end+1) = ???;

colors = {[0.18 0.44 0.72], [0.85 0.15 0.15], [0.13 0.63 0.13], ...
          [0.75 0.10 0.75], [0.85 0.50 0.10]};

r_step       = 50;    % reference step (degC)
d_amplitude  = 1.65;  % disturbance voltage (V)
t_dist_start = 350;   % disturbance start time (s) — halfway through 700s run

%% Open models
mdl_nd = 'prac2_nodist';
mdl_d  = 'prac2_dist';
if ~bdIsLoaded(mdl_nd), open_system(mdl_nd); end
if ~bdIsLoaded(mdl_d),  open_system(mdl_d);  end

%% Enable signal logging on both models
% No-disturbance model: log output and control signal
set_param(mdl_nd, 'SignalLogging',        'on');
set_param(mdl_nd, 'SignalLoggingName',    'logsout_nd');
set_param(mdl_nd, 'LoggingToFile',        'off');

% Disturbance model: log output
set_param(mdl_d, 'SignalLogging',         'on');
set_param(mdl_d, 'SignalLoggingName',     'logsout_d');
set_param(mdl_d, 'LoggingToFile',         'off');

% Enable workspace output logging
set_param(mdl_nd, 'SaveOutput', 'on', 'OutputSaveName', 'yout_nd', ...
          'SaveTime',   'on', 'TimeSaveName',   'tout_nd');
set_param(mdl_d,  'SaveOutput', 'on', 'OutputSaveName', 'yout_d',  ...
          'SaveTime',   'on', 'TimeSaveName',   'tout_d');

% Set format to array
set_param(mdl_nd, 'SaveFormat', 'Array');
set_param(mdl_d,  'SaveFormat', 'Array');

%% Loop over each controller
for k = 1:numel(ctrl_names)

    name = ctrl_names{k};
    Kp   = ctrl_Kp(k);
    Ki   = ctrl_Ki(k);
    Kd   = ctrl_Kd(k);
    col  = colors{k};

    fprintf('Simulating %s controller...\n', name);

    % ---- Set PID gains in both models ----
    set_param([mdl_nd '/PID_Controller'], 'P', num2str(Kp), ...
              'I', num2str(Ki), 'D', num2str(Kd));
    set_param([mdl_d  '/PID_Controller'], 'P', num2str(Kp), ...
              'I', num2str(Ki), 'D', num2str(Kd));

    % ---- Run no-disturbance simulation ----
    simOut_nd = sim(mdl_nd);
    t_nd  = simOut_nd.tout_nd;
    y_nd  = simOut_nd.yout_nd;

    % Control signal: resample to uniform grid first (Simulink uses variable step)
    t_uniform = linspace(t_nd(1), t_nd(end), length(t_nd))';
    if Ki == 0 && Kd == 0
        C = pid(Kp);
    elseif Kd == 0
        C = pid(Kp, Ki);
    else
        C = pid(Kp, Ki, Kd);
    end
    T_ur = feedback(C, G11);
    u_nd = lsim(T_ur, r_step * ones(size(t_uniform)), t_uniform);
    u_nd = min(max(u_nd, 0), 3.3);
    % Also resample y for consistent plotting
    y_nd_plot = interp1(t_nd, y_nd, t_uniform, 'linear');
    t_nd = t_uniform;

    % ---- Plot no-disturbance ----
    fig1 = figure('Color','w','Units','normalized','Position',[0.05 0.08 0.88 0.78], ...
                  'Name', sprintf('Simulink No-Dist: %s', name));

    ax1 = subplot(2,1,1);
    hold on;
    plot(t_nd, r_step*ones(size(t_nd)), 'k--', 'LineWidth',1.2, 'DisplayName','Reference r(t)');
    plot(t_nd, y_nd_plot, 'Color',col, 'LineWidth',1.5, 'DisplayName',sprintf('Output y(t) [%s]',name));
    hold off;
    grid on; grid minor; box on;
    ax1.Color='w'; ax1.XColor='k'; ax1.YColor='k';
    ax1.GridColor=[0.75 0.75 0.75]; ax1.FontSize=10;
    xlabel('Time  (s)','FontSize',11,'Color','k');
    ylabel('Temperature  (°C)','FontSize',11,'Color','k');
    title(sprintf('Reference Tracking — %s Controller  (No Disturbance)', name),...
          'FontSize',12,'FontWeight','bold','Color','k');
    legend('Location','southeast','FontSize',10,'Color','w','TextColor','k');

    ax2 = subplot(2,1,2);
    hold on;
    plot(t_nd, u_nd, 'Color',col, 'LineWidth',1.5, 'DisplayName','Manipulated variable u(t)');
    yline(3.3,'r--','LineWidth',0.8,'DisplayName','Saturation limit (3.3 V)');
    hold off;
    grid on; grid minor; box on;
    ax2.Color='w'; ax2.XColor='k'; ax2.YColor='k';
    ax2.GridColor=[0.75 0.75 0.75]; ax2.FontSize=10;
    xlabel('Time  (s)','FontSize',11,'Color','k');
    ylabel('Control Signal  (V)','FontSize',11,'Color','k');
    title('Manipulated Variable  u(t)','FontSize',11,'FontWeight','bold','Color','k');
    legend('Location','northeast','FontSize',10,'Color','w','TextColor','k');
    ylim([-0.2 3.6]);
    linkaxes([ax1 ax2],'x');

    if SAVE_PDF
        fname1 = ['slx_nodist_' strrep(strrep(name,' ','_'),'(','')];
        fname1 = strrep(fname1,')','');
        figure(fig1); print(gcf, fname1, '-dpdf', '-bestfit');
        fprintf('  Saved: %s.pdf\n', fname1);
    end

    % ---- Run disturbance simulation ----
    simOut_d = sim(mdl_d);
    t_d  = simOut_d.tout_d;
    y_d  = simOut_d.yout_d;

    % Disturbance signal vector
    t_d_uniform = linspace(t_d(1), t_d(end), length(t_d))';
    y_d_plot    = interp1(t_d, y_d, t_d_uniform, 'linear');
    d_vec = zeros(size(t_d_uniform));
    d_vec(t_d_uniform >= t_dist_start) = d_amplitude;

    % Control signal for disturbance case
    L       = C * G11;
    S       = feedback(1, L);
    T_ur_d  = feedback(C, G11);
    T_ud    = -C * G12 * S;
    u_r     = lsim(T_ur_d, r_step*ones(size(t_d_uniform)), t_d_uniform);
    u_dist  = lsim(T_ud,   d_vec,                          t_d_uniform);
    u_total = min(max(u_r + u_dist, 0), 3.3);
    t_d     = t_d_uniform;

    % ---- Plot disturbance ----
    fig2 = figure('Color','w','Units','normalized','Position',[0.05 0.08 0.88 0.78], ...
                  'Name', sprintf('Simulink Dist: %s', name));

    ax3 = subplot(2,1,1);
    hold on;
    plot(t_d, r_step*ones(size(t_d)), 'k--', 'LineWidth',1.2, 'DisplayName','Reference r(t)');
    plot(t_d, y_d_plot, 'Color',col, 'LineWidth',1.5, 'DisplayName',sprintf('Output y(t) [%s]',name));
    xline(t_dist_start,'r:','LineWidth',1.0,'Label',sprintf('Disturbance ON (t=%ds)',t_dist_start),...
          'LabelVerticalAlignment','bottom','HandleVisibility','off');
    hold off;
    grid on; grid minor; box on;
    ax3.Color='w'; ax3.XColor='k'; ax3.YColor='k';
    ax3.GridColor=[0.75 0.75 0.75]; ax3.FontSize=10;
    xlabel('Time  (s)','FontSize',11,'Color','k');
    ylabel('Temperature  (°C)','FontSize',11,'Color','k');
    title(sprintf('Disturbance Rejection — %s Controller', name),...
          'FontSize',12,'FontWeight','bold','Color','k');
    legend('Location','southeast','FontSize',10,'Color','w','TextColor','k');

    ax4 = subplot(2,1,2);
    hold on;
    plot(t_d, u_total, 'Color',col, 'LineWidth',1.5, 'DisplayName','Manipulated variable u(t) [PWM1 V]');
    plot(t_d, d_vec, 'Color',[0.4 0.4 0.4], 'LineWidth',1.2, 'LineStyle','--',...
         'DisplayName',sprintf('Disturbance d(t) [PWM2, %.2fV]',d_amplitude));
    yline(3.3,'r:','LineWidth',0.8,'DisplayName','Saturation limit (3.3 V)');
    hold off;
    grid on; grid minor; box on;
    ax4.Color='w'; ax4.XColor='k'; ax4.YColor='k';
    ax4.GridColor=[0.75 0.75 0.75]; ax4.FontSize=10;
    xlabel('Time  (s)','FontSize',11,'Color','k');
    ylabel('Signal  (V)','FontSize',11,'Color','k');
    title('Manipulated Variable u(t)  &  Disturbance d(t)','FontSize',11,'FontWeight','bold','Color','k');
    legend('Location','northeast','FontSize',10,'Color','w','TextColor','k');
    ylim([-0.3 3.8]);
    linkaxes([ax3 ax4],'x');

    if SAVE_PDF
        fname2 = ['slx_dist_' strrep(strrep(name,' ','_'),'(','')];
        fname2 = strrep(fname2,')','');
        figure(fig2); print(gcf, fname2, '-dpdf', '-bestfit');
        fprintf('  Saved: %s.pdf\n', fname2);
    end

end

fprintf('\nDone. All figures displayed.\n');
if SAVE_PDF, fprintf('PDFs saved to Prac2 folder.\n'); end
