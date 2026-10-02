%% prac2_build_simulink_models.m
%
% EBB320 Practical 2 - Build Simulink block diagrams
%
% Creates two Simulink models:
%   1. prac2_nodist.slx  - Reference tracking, no disturbance  (Guide Fig 1)
%   2. prac2_dist.slx    - Disturbed system with G12            (Guide Fig 2)
%
% Screenshot each model window for your report.
%
% G11 = (-0.1974s + 0.0530) / (s^2 + 0.4582s + 0.0034)
% G12 = (-0.0156s + 0.0010) / (s^2 + 0.0300s + 0.0002)
%
clear; clc;

%% =========================================================================
%  Model 1: Reference tracking - NO disturbance
%
%  r --> [Sum(+-)] --> [PID] --> [G11] --> y
%              ^                          |
%              |__________________________|
% ==========================================================================

mdl1 = 'prac2_nodist';
if bdIsLoaded(mdl1), close_system(mdl1, 0); end
if isfile([mdl1 '.slx']), delete([mdl1 '.slx']); end
new_system(mdl1);
open_system(mdl1);

% Block positions [left top right bottom]
add_block('simulink/Sources/Step', [mdl1 '/Reference'], ...
    'Time', '0', 'InitialValue', '0', 'FinalValue', '50', ...
    'Position', [50 163 80 177]);

add_block('simulink/Math Operations/Sum', [mdl1 '/Sum'], ...
    'Inputs', '+-', 'IconShape', 'round', ...
    'Position', [150 158 180 192]);

add_block('simulink/Continuous/PID Controller', [mdl1 '/PID_Controller'], ...
    'P', '0.847505', 'I', '0', 'D', '0', ...
    'Controller', 'P', ...
    'Position', [240 150 340 200]);

add_block('simulink/Continuous/Transfer Fcn', [mdl1 '/G11'], ...
    'Numerator', '[-0.1974, 0.0530]', ...
    'Denominator', '[1, 0.4582, 0.0034]', ...
    'Position', [410 155 510 195]);

add_block('simulink/Sinks/Out1', [mdl1 '/y'], ...
    'Position', [590 163 620 177]);

% Scope: shows reference + output overlaid (2 inputs)
add_block('simulink/Sinks/Scope', [mdl1 '/Scope_Output'], ...
    'NumInputPorts', '2', ...
    'Position', [590 100 630 140]);
set_param([mdl1 '/Scope_Output'], 'Open', 'off');

% Scope: shows control signal u(t)
add_block('simulink/Sinks/Scope', [mdl1 '/Scope_Control'], ...
    'NumInputPorts', '1', ...
    'Position', [590 210 630 250]);
set_param([mdl1 '/Scope_Control'], 'Open', 'off');

% Connect forward path
add_line(mdl1, 'Reference/1',      'Sum/1',            'autorouting', 'on');
add_line(mdl1, 'Sum/1',            'PID_Controller/1', 'autorouting', 'on');
add_line(mdl1, 'PID_Controller/1', 'G11/1',            'autorouting', 'on');
add_line(mdl1, 'G11/1',            'y/1',              'autorouting', 'on');

% Connect scopes
ph_G11out  = get_param([mdl1 '/G11'],        'PortHandles');
ph_Sum_in2 = get_param([mdl1 '/Sum'],        'PortHandles');
ph_Ref_out = get_param([mdl1 '/Reference'],  'PortHandles');
ph_PID_out = get_param([mdl1 '/PID_Controller'], 'PortHandles');
ph_ScopeY  = get_param([mdl1 '/Scope_Output'],   'PortHandles');
ph_ScopeU  = get_param([mdl1 '/Scope_Control'],  'PortHandles');

% Feedback line
add_line(mdl1, ph_G11out.Outport(1), ph_Sum_in2.Inport(2), 'autorouting', 'on');
% Scope_Output: port 1 = reference, port 2 = plant output
add_line(mdl1, ph_Ref_out.Outport(1), ph_ScopeY.Inport(1), 'autorouting', 'on');
add_line(mdl1, ph_G11out.Outport(1),  ph_ScopeY.Inport(2), 'autorouting', 'on');
% Scope_Control: control signal u(t)
add_line(mdl1, ph_PID_out.Outport(1), ph_ScopeU.Inport(1), 'autorouting', 'on');

set_param(mdl1, 'StopTime', '700', 'Solver', 'ode45', 'MaxStep', '1');
set_param(mdl1, 'ZoomFactor', 'FitSystem');
save_system(mdl1);
fprintf('Saved: %s.slx\n', mdl1);

%% =========================================================================
%  Model 2: Disturbed system WITH G12
%
%  PWM2 --> [G12] -------------------------+
%                                          v
%  r --> [Sum(+-)] --> [PID] --> [G11] --> [Sum(++)] --> y
%              ^                                         |
%              |_________________________________________|
% ==========================================================================

mdl2 = 'prac2_dist';
if bdIsLoaded(mdl2), close_system(mdl2, 0); end
if isfile([mdl2 '.slx']), delete([mdl2 '.slx']); end
new_system(mdl2);
open_system(mdl2);

% Disturbance path (top row)
add_block('simulink/Sources/Step', [mdl2 '/PWM2'], ...
    'Time', '350', 'InitialValue', '0', 'FinalValue', '1.65', ...
    'Position', [250 60 280 80]);

add_block('simulink/Continuous/Transfer Fcn', [mdl2 '/G12'], ...
    'Numerator', '[-0.0156, 0.0010]', ...
    'Denominator', '[1, 0.0300, 0.0002]', ...
    'Position', [370 55 470 95]);

% Main feedback path (bottom row)
add_block('simulink/Sources/Step', [mdl2 '/Reference'], ...
    'Time', '0', 'InitialValue', '0', 'FinalValue', '50', ...
    'Position', [50 228 80 242]);

add_block('simulink/Math Operations/Sum', [mdl2 '/Sum_ctrl'], ...
    'Inputs', '+-', 'IconShape', 'round', ...
    'Position', [150 223 180 257]);

add_block('simulink/Continuous/PID Controller', [mdl2 '/PID_Controller'], ...
    'P', '0.847505', 'I', '0', 'D', '0', ...
    'Controller', 'P', ...
    'Position', [240 215 340 265]);

add_block('simulink/Continuous/Transfer Fcn', [mdl2 '/G11'], ...
    'Numerator', '[-0.1974, 0.0530]', ...
    'Denominator', '[1, 0.4582, 0.0034]', ...
    'Position', [410 220 510 260]);

add_block('simulink/Math Operations/Sum', [mdl2 '/Sum_dist'], ...
    'Inputs', '++', 'IconShape', 'round', ...
    'Position', [560 223 590 257]);

add_block('simulink/Sinks/Out1', [mdl2 '/y'], ...
    'Position', [660 228 690 242]);

% Scope: reference + output
add_block('simulink/Sinks/Scope', [mdl2 '/Scope_Output'], ...
    'NumInputPorts', '2', ...
    'Position', [660 155 700 195]);
set_param([mdl2 '/Scope_Output'], 'Open', 'off');

% Scope: control signal + disturbance signal
add_block('simulink/Sinks/Scope', [mdl2 '/Scope_Control'], ...
    'NumInputPorts', '2', ...
    'Position', [660 290 700 330]);
set_param([mdl2 '/Scope_Control'], 'Open', 'off');

% Forward path connections
add_line(mdl2, 'Reference/1',      'Sum_ctrl/1',       'autorouting', 'on');
add_line(mdl2, 'Sum_ctrl/1',       'PID_Controller/1', 'autorouting', 'on');
add_line(mdl2, 'PID_Controller/1', 'G11/1',            'autorouting', 'on');
add_line(mdl2, 'G11/1',            'Sum_dist/1',       'autorouting', 'on');
add_line(mdl2, 'Sum_dist/1',       'y/1',              'autorouting', 'on');

% Disturbance path
add_line(mdl2, 'PWM2/1', 'G12/1',       'autorouting', 'on');
add_line(mdl2, 'G12/1',  'Sum_dist/2',  'autorouting', 'on');

% Feedback from output back to Sum_ctrl input 2
ph_Sdist_out = get_param([mdl2 '/Sum_dist'],      'PortHandles');
ph_Sctrl_in2 = get_param([mdl2 '/Sum_ctrl'],      'PortHandles');
ph_Ref2_out  = get_param([mdl2 '/Reference'],     'PortHandles');
ph_PID2_out  = get_param([mdl2 '/PID_Controller'],'PortHandles');
ph_PWM2_out  = get_param([mdl2 '/PWM2'],          'PortHandles');
ph_ScopeY2   = get_param([mdl2 '/Scope_Output'],  'PortHandles');
ph_ScopeU2   = get_param([mdl2 '/Scope_Control'], 'PortHandles');

add_line(mdl2, ph_Sdist_out.Outport(1), ph_Sctrl_in2.Inport(2), 'autorouting', 'on');
% Scope_Output: port 1 = reference, port 2 = y
add_line(mdl2, ph_Ref2_out.Outport(1),  ph_ScopeY2.Inport(1),   'autorouting', 'on');
add_line(mdl2, ph_Sdist_out.Outport(1), ph_ScopeY2.Inport(2),   'autorouting', 'on');
% Scope_Control: port 1 = u(t), port 2 = d(t) from PWM2
add_line(mdl2, ph_PID2_out.Outport(1),  ph_ScopeU2.Inport(1),   'autorouting', 'on');
add_line(mdl2, ph_PWM2_out.Outport(1),  ph_ScopeU2.Inport(2),   'autorouting', 'on');

set_param(mdl2, 'StopTime', '700', 'Solver', 'ode45', 'MaxStep', '1');
set_param(mdl2, 'ZoomFactor', 'FitSystem');
save_system(mdl2);
fprintf('Saved: %s.slx\n', mdl2);

fprintf('\nBoth models are open. Screenshot each for your report.\n');
fprintf('Press Ctrl+Shift+F in each Simulink window to fit to screen first.\n');
