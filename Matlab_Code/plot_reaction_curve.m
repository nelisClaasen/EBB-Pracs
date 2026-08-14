%% plot_reaction_curve.m
%
% EBB320 Practical 1  -  Reaction Curve Method (FOPDT identification)
%
% For each CSV this script produces TWO figures (one per temperature sensor)
% and prints a full parameter summary to the console.
%
% Each figure shows:
%   - The temperature response curve (blue)
%   - y0 baseline and y_inf steady-state reference lines
%   - t0 vertical line (where the step was applied)
%   - The tangent line drawn at the point of maximum slope (red dashed)
%   - t1 : where the tangent crosses y0        (dot on x-axis level of y0)
%   - t2 : where the tangent crosses y_inf     (dot on x-axis level of y_inf)
%   - theta = t1 - t0   (dead time)
%   - tau   = t2 - t1   (time constant)
%   - K     = dy / du   (process gain,  degC per % duty cycle)
%
% Transfer function form:   G(s) = K * exp(-theta*s) / (tau*s + 1)
%
% CSV columns (no header row):
%   Col 1  ->  Temp1  (degC)
%   Col 2  ->  Temp2  (degC)
%   Col 3  ->  PWM1   (V - analogue readback, noisy when active)
%   Col 4  ->  PWM2   (V - analogue readback, clean 3.3 V when active)
%   Col 5  ->  Time   (ms, monotonically increasing)
%   Col 6  ->  (unused - always 100)
%
clear; clc; close all;

% =========================================================================
%  >>>  CHANGE THIS LINE to switch between data files  <<<
filename = "Data1/Step_PWM1_V0.csv";
%
%  "Data1/Step_PWM1_V0.csv"  ->  PWM1 stepped  ->  gives G11 and G21
%  "Data1/Step_PWM2_V0.csv"  ->  PWM2 stepped  ->  gives G12 and G22
% =========================================================================

% ---- View window --------------------------------------------------------
% Seconds of pre- and post-step data visible on screen.
% Does NOT affect parameter calculation (all loaded data is used for that).
preStepView  = 30;    % seconds of baseline to show before t0
postStepView = 1300;  % seconds of response to show after t0
% -------------------------------------------------------------------------

% ---- Smoothing ----------------------------------------------------------
% Moving-average window applied ONLY to find the max-slope point.
% The displayed curve is always the raw data.
% Increase smoothWin if the tangent lands on a noise spike instead of
% the main transient.
smoothWin = 200;      % samples  (~1 s at 200 Hz) - wider window gives cleaner slope estimate
% -------------------------------------------------------------------------

%% 1.  Load CSV -----------------------------------------------------------
opts                    = detectImportOptions(filename, ...
                            "FileType", "delimitedtext", "Delimiter", ",");
opts.VariableNamingRule = "preserve";
opts.VariableNames      = {'Temp1','Temp2','PWM1','PWM2','TimeMs','Field6'};
opts.DataLines          = [1 Inf];
data   = readtable(filename, opts);

Temp1  = data.Temp1;
Temp2  = data.Temp2;
PWM1v  = data.PWM1;
PWM2v  = data.PWM2;
timeMs = data.TimeMs;
N      = height(data);

% Time in seconds, zeroed at the very first sample in the file
timeS = (timeMs - timeMs(1)) / 1000;

%% 2.  Detect stepped channel and step time t0 ---------------------------
% Compare the median of the first 10% of rows vs the last 10% of rows
% for each PWM channel.  The stepped channel has the larger shift.
% Using medians rather than range makes this robust to the ~50 mV noise
% on the PWM1 analogue readback pin.

nEdge = round(0.10 * N);

med1_start = median(PWM1v(1:nEdge));
med1_end   = median(PWM1v(end-nEdge+1:end));
med2_start = median(PWM2v(1:nEdge));
med2_end   = median(PWM2v(end-nEdge+1:end));

shift1 = abs(med1_end - med1_start);
shift2 = abs(med2_end - med2_start);

if shift1 >= shift2
    stepLabel  = "PWM1";
    rawInput   = PWM1v;
    thresh     = (med1_start + med1_end) / 2;
else
    stepLabel  = "PWM2";
    rawInput   = PWM2v;
    thresh     = (med2_start + med2_end) / 2;
end

% Find the first sample that crosses the threshold (3-sample confirmation
% to avoid triggering on a single noise spike)
stepIdx = NaN;
for k = 2 : N-1
    if rawInput(k-1) <= thresh && rawInput(k) > thresh && rawInput(k+1) > thresh
        stepIdx = k;
        break
    end
end
if isnan(stepIdx)
    tmp = find(rawInput > thresh, 1, "first");  % simple fallback
    if ~isempty(tmp)
        stepIdx = tmp;
    else
        error("Could not detect a step in '%s'.\nTry adjusting smoothWin or check the file.", filename);
    end
end

t0 = timeS(stepIdx);

% Duty-cycle step size in % (0-100 scale)
dutyBefore = (median(rawInput(1:stepIdx-1))     / 3.3) * 100;
dutyAfter  = (median(rawInput(stepIdx:end))      / 3.3) * 100;
deltaU     = dutyAfter - dutyBefore;

%% 3.  Baseline and steady-state estimates --------------------------------
% Baseline y0  : mean of all pre-step samples (plenty of baseline in both files)
y1_0  = mean(Temp1(1:stepIdx-1));
y2_0  = mean(Temp2(1:stepIdx-1));

% Steady-state y_inf : mean of the last 1% of all loaded samples
% (uses the very end of the ~1250 s recording where the curve is flattest)
tailIdx = max(stepIdx+1, round(0.99 * N));
y1Inf  = mean(Temp1(tailIdx:end));
y2Inf  = mean(Temp2(tailIdx:end));

% Process gains
K1 = (y1Inf - y1_0) / deltaU;
K2 = (y2Inf - y2_0) / deltaU;

%% 4.  Tangent-line analysis (FOPDT parameters) ---------------------------
% Work only on post-step data
postIdx = stepIdx : N;
tPost   = timeS(postIdx);

% Smooth then differentiate (slope-finding only; raw curve still plotted)
sm1  = movmean(Temp1(postIdx), smoothWin);
sm2  = movmean(Temp2(postIdx), smoothWin);
dt   = mean(diff(tPost));           % ~5 ms uniform spacing
dT1  = gradient(sm1, dt);
dT2  = gradient(sm2, dt);

[~, iMax1] = max(abs(dT1));
[~, iMax2] = max(abs(dT2));

% Tangent anchor point (use RAW temperature value, not smoothed)
tTan1 = tPost(iMax1);    yTan1 = Temp1(postIdx(iMax1));
tTan2 = tPost(iMax2);    yTan2 = Temp2(postIdx(iMax2));
m1    = dT1(iMax1);
m2    = dT2(iMax2);

% Tangent intersections:   t = tTan + (y_target - yTan) / m
t1_1 = tTan1 + (y1_0  - yTan1) / m1;   % tangent crosses y0
t2_1 = tTan1 + (y1Inf - yTan1) / m1;   % tangent crosses y_inf
t1_2 = tTan2 + (y2_0  - yTan2) / m2;
t2_2 = tTan2 + (y2Inf - yTan2) / m2;

% FOPDT parameters
theta1 = t1_1 - t0;
tau1   = t2_1 - t1_1;
theta2 = t1_2 - t0;
tau2   = t2_2 - t1_2;

%% 5.  Build tangent line plot segments ----------------------------------
% Extend the line slightly past t1 and t2 so the intersections are visible
[tanX1, tanY1] = buildTangent(tTan1, yTan1, m1, y1_0, y1Inf);
[tanX2, tanY2] = buildTangent(tTan2, yTan2, m2, y2_0, y2Inf);

%% 6.  Shared x-axis view limits -----------------------------------------
xLo  = max(0,          t0 - preStepView);
xHi  = min(timeS(end), t0 + postStepView);
xLim = [xLo, xHi];

%% 7.  Figure 1 - Temp1 --------------------------------------------------
figure("Name", sprintf("Reaction Curve: %s to Temp1", stepLabel), ...
       "Color", "w", "Units", "normalized", "Position", [0.02 0.08 0.46 0.78]);
hold on;

% Response curve
hR1 = plot(timeS, Temp1, "Color", [0.18 0.44 0.72], "LineWidth", 1.6, ...
           "DisplayName", "Temp1 response");

% Reference lines
hY0a  = yline(y1_0,  "LineStyle", ":", "Color", [0.5 0.5 0.5], "LineWidth", 1.2, ...
              "DisplayName", sprintf("y_0 = %.2f degC", y1_0));
hYIa  = yline(y1Inf, "LineStyle", "--","Color", [0.10 0.60 0.10], "LineWidth", 1.2, ...
              "DisplayName", sprintf("y_inf = %.2f degC", y1Inf));
hT0a  = xline(t0, "LineStyle", "--", "Color", [0.15 0.15 0.15], "LineWidth", 1.3, ...
              "DisplayName", sprintf("t_0 = %.1f s", t0));

% Tangent
hTn1  = plot(tanX1, tanY1, "r--", "LineWidth", 2.0, ...
             "DisplayName", "Tangent at max slope");

% t1 and t2 marker dots
hP1a  = plot(t1_1, y1_0,  "o", "MarkerSize", 9, "MarkerFaceColor", "r", ...
             "MarkerEdgeColor", "k", "LineWidth", 1, ...
             "DisplayName", sprintf("t_1 = %.1f s", t1_1));
hP2a  = plot(t2_1, y1Inf, "o", "MarkerSize", 9, "MarkerFaceColor", [0.8 0 0.8], ...
             "MarkerEdgeColor", "k", "LineWidth", 1, ...
             "DisplayName", sprintf("t_2 = %.1f s", t2_1));

% Max-slope triangle marker
hPka  = plot(tTan1, yTan1, "^", "MarkerSize", 9, "MarkerFaceColor", "k", ...
             "MarkerEdgeColor", "k", "DisplayName", "Max slope point");

% Vertical drop-lines at t1 and t2
yBase1 = min(y1_0, y1Inf);
plot([t1_1 t1_1], [yBase1, y1_0],   ":", "Color", "r",          "LineWidth", 1.0, "HandleVisibility", "off");
plot([t2_1 t2_1], [yBase1, y1Inf],  ":", "Color", [0.8 0 0.8],  "LineWidth", 1.0, "HandleVisibility", "off");

% Parameter annotation box (yellow background)
annStr1 = sprintf("theta = %.1f s\ntau   = %.1f s\nK     = %.4f degC/%%", theta1, tau1, K1);
text(xLo + 0.03*(xHi-xLo), y1_0 + 0.20*(y1Inf-y1_0), annStr1, ...
     "FontSize", 10, "FontWeight", "bold", "FontName", "Courier", ...
     "BackgroundColor", [1.0 1.0 0.80], "EdgeColor", [0.6 0.6 0.3], ...
     "Margin", 5, "VerticalAlignment", "bottom");

hold off;
grid on; grid minor; box on;
xlim(xLim);
xlabel("Time  (s)",          "FontSize", 11);
ylabel("Temperature  (degC)","FontSize", 11);
title(sprintf("Reaction Curve  -  Temp1 response to %s step", stepLabel), ...
      "FontSize", 12, "FontWeight", "bold");
legend([hR1 hTn1 hY0a hYIa hT0a hP1a hP2a hPka], ...
       "Location", "southeast", "NumColumns", 2, "FontSize", 9);

%% 8.  Figure 2 - Temp2 --------------------------------------------------
figure("Name", sprintf("Reaction Curve: %s to Temp2", stepLabel), ...
       "Color", "w", "Units", "normalized", "Position", [0.52 0.08 0.46 0.78]);
hold on;

hR2  = plot(timeS, Temp2, "Color", [0.18 0.44 0.72], "LineWidth", 1.6, ...
            "DisplayName", "Temp2 response");

hY0b = yline(y2_0,  "LineStyle", ":", "Color", [0.5 0.5 0.5], "LineWidth", 1.2, ...
             "DisplayName", sprintf("y_0 = %.2f degC", y2_0));
hYIb = yline(y2Inf, "LineStyle", "--","Color", [0.10 0.60 0.10], "LineWidth", 1.2, ...
             "DisplayName", sprintf("y_inf = %.2f degC", y2Inf));
hT0b = xline(t0, "LineStyle", "--", "Color", [0.15 0.15 0.15], "LineWidth", 1.3, ...
             "DisplayName", sprintf("t_0 = %.1f s", t0));

hTn2 = plot(tanX2, tanY2, "r--", "LineWidth", 2.0, ...
            "DisplayName", "Tangent at max slope");

hP1b = plot(t1_2, y2_0,  "o", "MarkerSize", 9, "MarkerFaceColor", "r", ...
            "MarkerEdgeColor", "k", "LineWidth", 1, ...
            "DisplayName", sprintf("t_1 = %.1f s", t1_2));
hP2b = plot(t2_2, y2Inf, "o", "MarkerSize", 9, "MarkerFaceColor", [0.8 0 0.8], ...
            "MarkerEdgeColor", "k", "LineWidth", 1, ...
            "DisplayName", sprintf("t_2 = %.1f s", t2_2));
hPkb = plot(tTan2, yTan2, "^", "MarkerSize", 9, "MarkerFaceColor", "k", ...
            "MarkerEdgeColor", "k", "DisplayName", "Max slope point");

yBase2 = min(y2_0, y2Inf);
plot([t1_2 t1_2], [yBase2, y2_0],  ":", "Color", "r",         "LineWidth", 1.0, "HandleVisibility", "off");
plot([t2_2 t2_2], [yBase2, y2Inf], ":", "Color", [0.8 0 0.8], "LineWidth", 1.0, "HandleVisibility", "off");

annStr2 = sprintf("theta = %.1f s\ntau   = %.1f s\nK     = %.4f degC/%%", theta2, tau2, K2);
text(xLo + 0.03*(xHi-xLo), y2_0 + 0.20*(y2Inf-y2_0), annStr2, ...
     "FontSize", 10, "FontWeight", "bold", "FontName", "Courier", ...
     "BackgroundColor", [1.0 1.0 0.80], "EdgeColor", [0.6 0.6 0.3], ...
     "Margin", 5, "VerticalAlignment", "bottom");

hold off;
grid on; grid minor; box on;
xlim(xLim);
xlabel("Time  (s)",          "FontSize", 11);
ylabel("Temperature  (degC)","FontSize", 11);
title(sprintf("Reaction Curve  -  Temp2 response to %s step (coupling)", stepLabel), ...
      "FontSize", 12, "FontWeight", "bold");
legend([hR2 hTn2 hY0b hYIb hT0b hP1b hP2b hPkb], ...
       "Location", "southeast", "NumColumns", 2, "FontSize", 9);

%% 9.  Console summary ----------------------------------------------------
numStr = regexp(stepLabel, '\d+', 'match');
num    = numStr{1};

fprintf("\n");
fprintf("+------------------------------------------------------+\n");
fprintf("  Reaction Curve Results  -  %s\n", filename);
fprintf("+------------------------------------------------------+\n");
fprintf("  Stepped channel  : %s\n",      stepLabel);
fprintf("  Duty cycle step  : %.1f %%  (%.1f -> %.1f %%)\n", deltaU, dutyBefore, dutyAfter);
fprintf("  t0 (step time)   : %.2f s\n\n", t0);

fprintf("  [ Temp1  (G%s1) ]\n", num);
fprintf("    y0      = %.3f degC\n",   y1_0);
fprintf("    y_inf   = %.3f degC\n",   y1Inf);
fprintf("    delta_y = %.3f degC\n",   y1Inf - y1_0);
fprintf("    t1      = %.2f s\n",      t1_1);
fprintf("    t2      = %.2f s\n",      t2_1);
fprintf("    theta   = %.2f s   (dead time)\n",      theta1);
fprintf("    tau     = %.2f s   (time constant)\n",  tau1);
fprintf("    K       = %.4f degC/%%  (process gain)\n", K1);
fprintf("    G(s)    = %.4f * exp(-%.2f*s) / (%.2f*s + 1)\n\n", K1, theta1, tau1);

fprintf("  [ Temp2  (G%s2) ]\n", num);
fprintf("    y0      = %.3f degC\n",   y2_0);
fprintf("    y_inf   = %.3f degC\n",   y2Inf);
fprintf("    delta_y = %.3f degC\n",   y2Inf - y2_0);
fprintf("    t1      = %.2f s\n",      t1_2);
fprintf("    t2      = %.2f s\n",      t2_2);
fprintf("    theta   = %.2f s   (dead time)\n",      theta2);
fprintf("    tau     = %.2f s   (time constant)\n",  tau2);
fprintf("    K       = %.4f degC/%%  (process gain)\n", K2);
fprintf("    G(s)    = %.4f * exp(-%.2f*s) / (%.2f*s + 1)\n\n", K2, theta2, tau2);

fprintf("  FOPDT form:  G(s) = K * exp(-theta*s) / (tau*s + 1)\n\n");

%% -----------------------------------------------------------------------
%  LOCAL FUNCTION  (must be at the end of the script file)
% -----------------------------------------------------------------------
function [tx, ty] = buildTangent(tTan, yTan, m, y0, yInf)
% Returns x/y coordinates for the tangent line segment, clipped to the
% y-range [y0, y_inf] with a small 5% padding on each side.
    pad = 0.05 * abs(yInf - y0);
    yLo = min(y0, yInf) - pad;
    yHi = max(y0, yInf) + pad;
    % t values at the clipping boundaries
    tLo = tTan + (yLo - yTan) / m;
    tHi = tTan + (yHi - yTan) / m;
    tx  = linspace(min(tLo, tHi), max(tLo, tHi), 400);
    ty  = m * (tx - tTan) + yTan;
    % Clip
    keep = ty >= yLo & ty <= yHi;
    tx   = tx(keep);
    ty   = ty(keep);
end
