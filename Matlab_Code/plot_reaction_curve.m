%% plot_reaction_curve.m
%
% Reusable reaction-curve plotter for EBB320 Practical 1.
%
% Plots Temp1 and Temp2 against time (in seconds) for a chosen window of
% a step-test CSV, so you can use MATLAB's built-in annotation tools
% (Insert > Line, or Data Cursor) to draw the tangent line at the
% steepest point of the curve, exactly like Figure 10 in the practical
% guide. The PWM input is NOT plotted -- it's only used internally to
% detect t0 (marked as a dashed vertical line).
%
% CSV columns (no header row):
%   1 = Temp1  (deg C)
%   2 = Temp2  (deg C)
%   3 = PWM1   (analog readback of the PWM1 pin, volts)
%   4 = PWM2   (analog readback of the PWM2 pin, volts)
%   5 = Time   (ms)
%   6 = (unused / constant field from the app)
%
clear; clc; close all;

% ---- Change these to reuse this for either CSV -----------------------
filename           = "Step_PWM2_V0.csv"; % "Step_PWM1_V0.csv" -> gives G11 & G21
                                          % "Step_PWM2_V0.csv" -> gives G12 & G22
startRow           = 8500;   % first row to include (1-indexed, as in the raw CSV)
                              % PWM1 file: step happens at row 10063 -> 9500 gives ~2.9 s baseline
                              % PWM2 file: step happens at row 10261 -> 9700 gives ~2.9 s baseline
endRow              = [];    % [] = read to the end of the file (recommended, gives an accurate
                              % steady-state value); set a number to cap it if MATLAB feels slow
logicVoltage        = 3.3;   % ESP32 logic level, used only to detect the step time t0
focusWindowSeconds  = 1200;   % how much post-step time to SHOW on screen (zoomed view, for easy
                              % reading/drawing); set to [] to show the full loaded range instead
% ------------------------------------------------------------------------

%% --- Load only the rows we need ---
opts = detectImportOptions(filename, "FileType", "delimitedtext", "Delimiter", ",");
opts.VariableNamingRule = "preserve";
opts.VariableNames = {'Temp1','Temp2','PWM1','PWM2','TimeMs','Field6'};
if isempty(endRow)
    opts.DataLines = [startRow Inf];
else
    opts.DataLines = [startRow endRow];
end
data = readtable(filename, opts);

Temp1  = data.Temp1;
Temp2  = data.Temp2;
PWM1   = data.PWM1;
PWM2   = data.PWM2;
timeMs = data.TimeMs;

% Time in seconds, referenced to t = 0 at the first sample of THIS window.
% Because it's re-zeroed here, changing startRow above never breaks the
% axis -- t0, t1, t2 etc. always read directly off the x-axis in seconds.
timeS = (timeMs - timeMs(1)) / 1000;

%% --- Auto-detect which channel is actually being stepped ---
if range(PWM1) >= range(PWM2)
    stepLabel = "PWM1";
    rawInput  = PWM1;
else
    stepLabel = "PWM2";
    rawInput  = PWM2;
end

dutyPct = (rawInput / logicVoltage) * 100;

threshold = (max(dutyPct) + min(dutyPct)) / 2;
stepIdx   = find(dutyPct > threshold, 1, "first");
if isempty(stepIdx)
    t0 = NaN;
else
    t0 = timeS(stepIdx);
end

%% --- Steady-state estimate (mean of the last 5% of loaded samples) ---
tailStart = round(0.95 * height(data));
y1Inf = mean(Temp1(tailStart:end));
y2Inf = mean(Temp2(tailStart:end));
y1_0  = mean(Temp1(1:stepIdx-1));   % baseline before the step
y2_0  = mean(Temp2(1:stepIdx-1));

%% --- Shared x-axis view window (zoomed for easy reading) ---
if isempty(focusWindowSeconds)
    xViewLim = [0, timeS(end)];
else
    xViewLim = [0, min(timeS(end), t0 + focusWindowSeconds)];
end
xTicks = linspace(xViewLim(1), xViewLim(2), 21);   % ~20 evenly spaced gridlines, any window length

%% --- Figure 1: Temp1 reaction curve ---
figure("Name", "Reaction Curve: " + stepLabel + " to Temp1", "Color", "w");
plot(timeS, Temp1, "b", "LineWidth", 1.5);
ylabel("Temperature (^{\circ}C)");
xlabel("Time (s)");
title("Reaction Curve: Temp1 Response to " + stepLabel + " Step");
legend("Output (Temp1)", "Location", "southeast");
grid on; grid minor; box on;
xlim(xViewLim);
ax = gca;
ax.XTick = xTicks;
if ~isnan(t0)
    xline(t0, "--", "t_0", "LabelVerticalAlignment", "bottom");
end
yline(y1_0, ":", "y_0");
yline(y1Inf, ":", "y_\infty");

%% --- Figure 2: Temp2 reaction curve ---
figure("Name", "Reaction Curve: " + stepLabel + " to Temp2", "Color", "w");
plot(timeS, Temp2, "b", "LineWidth", 1.5);
ylabel("Temperature (^{\circ}C)");
xlabel("Time (s)");
title("Reaction Curve: Temp2 Response to " + stepLabel + " Step (Coupling)");
legend("Output (Temp2)", "Location", "southeast");
grid on; grid minor; box on;
xlim(xViewLim);
ax = gca;
ax.XTick = xTicks;
if ~isnan(t0)
    xline(t0, "--", "t_0", "LabelVerticalAlignment", "bottom");
end
yline(y2_0, ":", "y_0");
yline(y2Inf, ":", "y_\infty");

%% --- Console summary ---
fprintf("Detected stepped channel: %s\n", stepLabel);
fprintf("t0 = %.3f s (window-relative)\n", t0);
fprintf("Estimated duty cycle plateau: %.1f %%\n", mean(dutyPct(stepIdx:end)));
fprintf("Temp1: y0 = %.2f C, y_inf = %.2f C, delta_y = %.2f C\n", y1_0, y1Inf, y1Inf - y1_0);
fprintf("Temp2: y0 = %.2f C, y_inf = %.2f C, delta_y = %.2f C\n", y2_0, y2Inf, y2Inf - y2_0);
fprintf("(Full loaded window: %.1f s -- shown view zoomed to %.1f s via focusWindowSeconds)\n", ...
    timeS(end), xViewLim(2));

%% --- Notes ---
% Both figures are now open, zoomed to the transient region with fine
% gridlines and dashed y0 / y_infinity reference lines already drawn for
% you. Use the figure toolbar / Insert menu (Insert > Line, or the Data
% Cursor tool) to:
%   1. Click the point of maximum slope on the blue Output curve.
%   2. Draw the tangent line through that point (Insert > Line).
%   3. Read off t1 (where your tangent crosses the y_0 line) and t2
%      (where it crosses the y_infinity line).
%   4. theta = t1 - t0, tau = t2 - t1, K = delta_y / delta_u
%      (delta_u = the duty-cycle plateau printed in the console above).