%% plot_reaction_curve.m
%
% EBB320 Practical 1  -  Reaction Curve Method
%
% Produces ONE clean figure per CSV file:
%   - Left  y-axis : Temp1 (blue) and Temp2 (red)
%   - Right y-axis : PWM duty cycle % (black, 0->100 step)
%   - y0, y_inf reference lines for both channels
%   - t0 vertical line
%   - White background, ready to export as PDF/PNG for manual annotation
%
% HOW TO DRAW THE TANGENT MANUALLY:
%   1. Export: run the print command shown in the console, OR
%      use File > Save As > PDF in the figure window.
%   2. Open the PDF in any editor (PowerPoint, Inkscape, Adobe, etc.)
%   3. Draw a straight line tangent to the steepest part of each curve.
%   4. Read t1 (tangent crosses y0) and t2 (tangent crosses y_inf) from x-axis.
%   5. theta = t1 - t0,   tau = t2 - t1,   K printed in console.
%
% CSV columns (no header):
%   1=Temp1(degC)  2=Temp2(degC)  3=PWM1(V)  4=PWM2(V)  5=Time(ms)  6=unused
%
clear; clc; close all;

% =========================================================================
%  >>>  CHANGE THIS LINE to switch between data files  <<<
filename = "Data1/Step_PWM2_V0.csv";
%
%  "Data1/Step_PWM1_V0.csv"  ->  PWM1 stepped  ->  G11 (Temp1) and G21 (Temp2)
%  "Data1/Step_PWM2_V0.csv"  ->  PWM2 stepped  ->  G12 (Temp1) and G22 (Temp2)
% =========================================================================

% ---- View window --------------------------------------------------------
preStepView  = 50;    % seconds to show before t0
postStepView = 1300;  % seconds to show after t0% -------------------------------------------------------------------------

%% 1.  Load data ----------------------------------------------------------
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
timeS  = (timeMs - timeMs(1)) / 1000;

%% 2.  Detect stepped channel and t0 -------------------------------------
nEdge = max(100, round(0.02 * N));

med1_pre  = median(PWM1v(1:nEdge));
med1_post = median(PWM1v(end-nEdge+1:end));
med2_pre  = median(PWM2v(1:nEdge));
med2_post = median(PWM2v(end-nEdge+1:end));

if abs(med1_post - med1_pre) >= abs(med2_post - med2_pre)
    stepLabel = "PWM1";
    rawInput  = PWM1v;
    thresh    = (med1_pre + med1_post) / 2;
else
    stepLabel = "PWM2";
    rawInput  = PWM2v;
    thresh    = (med2_pre + med2_post) / 2;
end

stepIdx = NaN;
for k = 2 : N-1
    if rawInput(k-1) <= thresh && rawInput(k) > thresh && rawInput(k+1) > thresh
        stepIdx = k;
        break
    end
end
if isnan(stepIdx)
    tmp = find(rawInput > thresh, 1, "first");
    if ~isempty(tmp)
        stepIdx = tmp;
    else
        error("Could not detect step in '%s'.", filename);
    end
end

t0 = timeS(stepIdx);

%% 3.  Baseline and steady-state -----------------------------------------
y1_0  = mean(Temp1(1:stepIdx-1));
y2_0  = mean(Temp2(1:stepIdx-1));

tailIdx = max(stepIdx+1, round(0.99 * N));
y1Inf = mean(Temp1(tailIdx:end));
y2Inf = mean(Temp2(tailIdx:end));

% K uses delta_u = 100% (displayed PWM step is 0->100)
K1 = (y1Inf - y1_0) / 100;
K2 = (y2Inf - y2_0) / 100;

%% 4.  Tangent lines anchored at user-specified points -------------------
% These coordinates were read from the data cursor on the steepest part
% of each curve. Change them here if you want to adjust the tangent.
%
%   Temp1 anchor:  (tAnchor1, yAnchor1)
%   Temp2 anchor:  (tAnchor2, yAnchor2)
%
tAnchor1 = 84.313;    yAnchor1 = 22.88;    % point on Temp1 at steepest slope
tAnchor2 = 93.683;    yAnchor2 = 28.6215;  % point on Temp2 at steepest slope

smoothWin = 200;   % samples for slope smoothing (~1 s at 200 Hz)

% Post-step indices
postIdx = stepIdx : N;
tPost   = timeS(postIdx);
dt      = mean(diff(tPost));

% Smooth and differentiate both channels
sm1 = movmean(Temp1(postIdx), smoothWin);
dT1 = gradient(sm1, dt);
sm2 = movmean(Temp2(postIdx), smoothWin);
dT2 = gradient(sm2, dt);

% Find anchor: use user-specified point if given, else auto max-slope
if isnan(tAnchor1)
    [~, iAnc1] = max(abs(dT1));
    tAnchor1 = tPost(iAnc1);
    yAnchor1 = Temp1(postIdx(iAnc1));
else
    [~, iAnc1] = min(abs(tPost - tAnchor1));
end
if isnan(tAnchor2)
    [~, iAnc2] = max(abs(dT2));
    tAnchor2 = tPost(iAnc2);
    yAnchor2 = Temp2(postIdx(iAnc2));
else
    [~, iAnc2] = min(abs(tPost - tAnchor2));
end
m1 = dT1(iAnc1);
m2 = dT2(iAnc2);

% Use user anchor as the tangent point
tTan1 = tAnchor1;   yTan1 = yAnchor1;
tTan2 = tAnchor2;   yTan2 = yAnchor2;

% Intersection times with y0 and y_inf
t1_1 = tTan1 + (y1_0  - yTan1) / m1;
t2_1 = tTan1 + (y1Inf - yTan1) / m1;
t1_2 = tTan2 + (y2_0  - yTan2) / m2;
t2_2 = tTan2 + (y2Inf - yTan2) / m2;

% FOPDT parameters
theta1 = t1_1 - t0;   tau1 = t2_1 - t1_1;
theta2 = t1_2 - t0;   tau2 = t2_2 - t1_2;

% Build tangent line vectors (never extend left of t0)
pad   = 0.05;
[tanX1, tanY1] = makeTangent(tTan1, yTan1, m1, y1_0, y1Inf, pad, t0);
[tanX2, tanY2] = makeTangent(tTan2, yTan2, m2, y2_0, y2Inf, pad, t0);

%% 5.  Build clean 0->100 PWM step vectors --------------------------------
tPWM  = [timeS(1);  timeS(stepIdx-1);  timeS(stepIdx);  timeS(end)];
duPWM = [0;         0;                 100;              100       ];

%% 5.  Plot ---------------------------------------------------------------
xLo = max(0,          t0 - preStepView);
xHi = min(timeS(end), t0 + postStepView);

fig = figure("Color", [1 1 1], ...
             "Units", "normalized", ...
             "Position", [0.03 0.06 0.92 0.82], ...
             "Name", sprintf("Reaction Curve: %s", stepLabel));

% -- Left axis: temperatures ---------------------------------------------
yyaxis left;
hold on;

hT1 = plot(timeS, Temp1, ...
           "Color", [0.18 0.44 0.72], ...
           "LineWidth", 1.0, ...
           "DisplayName", sprintf("Temp1  (y0=%.2f, yinf=%.2f degC)", y1_0, y1Inf));

hT2 = plot(timeS, Temp2, ...
           "Color", [0.85 0.15 0.15], ...
           "LineWidth", 1.0, ...
           "DisplayName", sprintf("Temp2  (y0=%.2f, yinf=%.2f degC)", y2_0, y2Inf));

% Temp1 reference lines
yline(y1_0,  "LineStyle", ":", "Color", [0.18 0.44 0.72], ...
      "LineWidth", 0.8, "HandleVisibility", "off");
yline(y1Inf, "LineStyle", "--", "Color", [0.18 0.44 0.72], ...
      "LineWidth", 0.8, "HandleVisibility", "off");

% Temp2 reference lines
yline(y2_0,  "LineStyle", ":", "Color", [0.85 0.15 0.15], ...
      "LineWidth", 0.8, "HandleVisibility", "off");
yline(y2Inf, "LineStyle", "--", "Color", [0.85 0.15 0.15], ...
      "LineWidth", 0.8, "HandleVisibility", "off");

% Tangent lines (plotted as data - data cursor works on these)
hTn1 = plot(tanX1, tanY1, "--", "Color", [0.18 0.44 0.72], ...
            "LineWidth", 1.2, ...
            "DisplayName", sprintf("Tangent Temp1  t1=%.1fs  t2=%.1fs", t1_1, t2_1));
hTn2 = plot(tanX2, tanY2, "--", "Color", [0.85 0.15 0.15], ...
            "LineWidth", 1.2, ...
            "DisplayName", sprintf("Tangent Temp2  t1=%.1fs  t2=%.1fs", t1_2, t2_2));

% t1 and t2 marker dots on the tangent lines
plot(t1_1, y1_0,  "o", "MarkerSize", 7, "MarkerFaceColor", [0.18 0.44 0.72], ...
     "MarkerEdgeColor", "k", "HandleVisibility", "off");
plot(t2_1, y1Inf, "s", "MarkerSize", 7, "MarkerFaceColor", [0.18 0.44 0.72], ...
     "MarkerEdgeColor", "k", "HandleVisibility", "off");
plot(t1_2, y2_0,  "o", "MarkerSize", 7, "MarkerFaceColor", [0.85 0.15 0.15], ...
     "MarkerEdgeColor", "k", "HandleVisibility", "off");
plot(t2_2, y2Inf, "s", "MarkerSize", 7, "MarkerFaceColor", [0.85 0.15 0.15], ...
     "MarkerEdgeColor", "k", "HandleVisibility", "off");
axL = gca;
axL.Color    = [1 1 1];
axL.YColor   = [0 0 0];
ylabel("Temperature  (degC)", "FontSize", 12, "Color", [0 0 0]);

% -- Right axis: PWM 0->100 step -----------------------------------------
yyaxis right;

hPWM = plot(tPWM, duPWM * 3.3 / 100, ...
            "Color", [0.1 0.1 0.1], ...
            "LineWidth", 1.0, ...
            "DisplayName", sprintf("%s  (0 to 3.3 V)", stepLabel));

axR = gca;
axR.YColor = [0 0 0];
ylabel("PWM Voltage  (V)", "FontSize", 12, "Color", [0 0 0]);
ylim([-0.3 4.0]);
yticks(0:0.5:3.5);

% -- t0 vertical line ----------------------------------------------------
yyaxis left;
ht0 = xline(t0, ...
            "LineStyle", "--", ...
            "Color", [0.3 0.3 0.3], ...
            "LineWidth", 0.8, ...
            "DisplayName", sprintf("t_0 = %.1f s", t0));

hold off;

% -- Axes and figure formatting ------------------------------------------
axL.Color          = [1 1 1];
axL.GridColor      = [0.75 0.75 0.75];
axL.MinorGridColor = [0.88 0.88 0.88];
axL.GridAlpha      = 0.9;
axL.MinorGridAlpha = 0.7;
axL.XColor         = [0 0 0];
axL.FontSize       = 10;

grid on;
grid minor;
box on;
xlim([xLo xHi]);
xlabel("Time  (s)", "FontSize", 12, "Color", [0 0 0]);
title(sprintf("Reaction Curve  -  %s step  (Temp1 & Temp2)", stepLabel), ...
      "FontSize", 13, "FontWeight", "bold", "Color", [0 0 0]);

legend([hT1, hT2, hTn1, hTn2, hPWM, ht0], ...
       "Location", "east", "FontSize", 10, "Box", "on", ...
       "Color", [1 1 1], "TextColor", [0 0 0]);

% -- Reference line labels -----------------------------------------------
yyaxis left;
yRng = ylim;
span = yRng(2) - yRng(1);
xTxt = xLo + 0.012*(xHi - xLo);

text(xTxt, y1_0  + 0.014*span, sprintf("y0,1=%.2f",   y1_0),  ...
     "Color", [0.18 0.44 0.72], "FontSize", 8, "FontWeight", "bold");
text(xTxt, y1Inf + 0.014*span, sprintf("yinf,1=%.2f", y1Inf), ...
     "Color", [0.18 0.44 0.72], "FontSize", 8, "FontWeight", "bold");
text(xTxt, y2_0  - 0.022*span, sprintf("y0,2=%.2f",   y2_0),  ...
     "Color", [0.85 0.15 0.15], "FontSize", 8, "FontWeight", "bold");
text(xTxt, y2Inf - 0.022*span, sprintf("yinf,2=%.2f", y2Inf), ...
     "Color", [0.85 0.15 0.15], "FontSize", 8, "FontWeight", "bold");

%% 6.  Console summary ---------------------------------------------------
fprintf("\n+----------------------------------------------------------+\n");
fprintf("  File            : %s\n",     filename);
fprintf("  Stepped channel : %s\n",     stepLabel);
fprintf("  t0              : %.2f s\n", t0);
fprintf("  delta_u         : 100%%  (0 -> 100%% as displayed)\n");
fprintf("\n");
fprintf("  Temp1:  y0=%.3f  yinf=%.3f  dy=%.3f degC\n", y1_0, y1Inf, y1Inf-y1_0);
fprintf("  Temp2:  y0=%.3f  yinf=%.3f  dy=%.3f degC\n", y2_0, y2Inf, y2Inf-y2_0);
  fprintf("  K1 = dy/du = %.4f degC/%%\n", K1);
fprintf("  K2 = dy/du = %.4f degC/%%\n", K2);
fprintf("\n");
fprintf("  Temp1:  t1=%.2fs  t2=%.2fs  theta=%.2fs  tau=%.2fs\n", t1_1, t2_1, theta1, tau1);
fprintf("  Temp2:  t1=%.2fs  t2=%.2fs  theta=%.2fs  tau=%.2fs\n", t1_2, t2_2, theta2, tau2);
fprintf("\n");
fprintf("  G11(s) = %.4f * exp(-%.2f*s) / (%.2f*s + 1)\n", K1, theta1, tau1);
fprintf("  G21(s) = %.4f * exp(-%.2f*s) / (%.2f*s + 1)\n", K2, theta2, tau2);
fprintf("\n");
fprintf("  Circle  marker = t1 (tangent x y0)\n");
fprintf("  Square  marker = t2 (tangent x y_inf)\n");
fprintf("  Run:  datacursormode on  to click and verify points.\n");
fprintf("+----------------------------------------------------------+\n\n");
fprintf("  Export command (run in Command Window):\n");
fprintf("  >> print(fig, 'reaction_curve_%s', '-dpdf', '-bestfit')\n\n", stepLabel);

%% Local function ---------------------------------------------------------
function [tx, ty] = makeTangent(tTan, yTan, m, y0, yInf, pad, tMin)
    if nargin < 7, tMin = -Inf; end
    span = abs(yInf - y0);
    yLo  = min(y0, yInf) - pad * span;
    yHi  = max(y0, yInf) + pad * span;
    tLo  = tTan + (yLo - yTan) / m;
    tHi  = tTan + (yHi - yTan) / m;
    tx   = linspace(min(tLo, tHi), max(tLo, tHi), 400);
    ty   = m * (tx - tTan) + yTan;
    keep = ty >= yLo & ty <= yHi & tx >= tMin;
    tx   = tx(keep);
    ty   = ty(keep);
end
