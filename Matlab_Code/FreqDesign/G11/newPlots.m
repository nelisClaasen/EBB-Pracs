% 1. Process Transfer Function Matrix and Dead Time
numerator11 = [0.1179];  denominator11 = [1 0.0076]; 
numerator12 = [0.03658]; denominator12 = [1 0.005254];
numerator21 = [0.06368]; denominator21 = [1 0.006012];
numerator22 = [0.05872]; denominator22 = [1 0.005984];

DeadNum = [-0.0725 1];
DeadDen = [0.0725 1]; 
DeadTime = tf(DeadNum, DeadDen);

G11_Final = tf(numerator11, denominator11) * DeadTime;
G12_Final = tf(numerator12, denominator12) * DeadTime;
G21_Final = tf(numerator21, denominator21) * DeadTime;
G22_Final = tf(numerator22, denominator22) * DeadTime;

disp('--- Process Transfer Function Matrix G(s) ---');
G_Matrix = [G11_Final, G12_Final; G21_Final, G22_Final]

% 2. Define the PID Controllers
Kp1 = 0.09474; Ki1 = 0.00257; Kd1 = 0.6904;
Kp2 = 0.1488;  Ki2 = 0.00314; Kd2 = 1.174;

C11 = pid(Kp1, Ki1, Kd1); 
C22 = pid(Kp2, Ki2, Kd2);

% 3. Create Open-Loop (L) and Closed-Loop (T) Systems
L11 = C11 * G11_Final;
T11 = feedback(L11, 1);

L22 = C22 * G22_Final;
T22 = feedback(L22, 1);

% Normalize the open-loop plants to a steady-state of 1 for visual comparison
G11_Normalized = G11_Final / dcgain(G11_Final);
G22_Normalized = G22_Final / dcgain(G22_Final);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% For G11 %%%%%%%%%%%%%%%%%%%%%%%%%%%
G_c11 = 1.17921 * ((s + 0.1)*(s + 0.0295055)/s);

plotStep(G11_Final, C11, G11_Final, "Normalized Open Loop vs PID Closed Loop Step Response for G11", "G11_Freq_Step.pdf");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% For G22 %%%%%%%%%%%%%%%%%%%%%%%%%%%
G_c22 = 1.90571 * ((s + 0.1)*(s + 0.0221733)/s);

plotStep(G22_Final, C22, G22_Final, "Normalized Open Loop vs PID Closed Loop Step Response for G22", "G22_Freq_Step.pdf");

function plotStep(plant, controller, Second_order_approx, figName, fileSaveName)

opts = timeoptions('cstprefs');
opts.Title.FontSize = 20;
opts.XLabel.FontSize = 20;
opts.YLabel.FontSize = 20;
opts.TickLabel.FontSize = 16;

%Get feedback tf
G_closed = feedback(controller * plant, 1);

%Plot ideal 2nd order response with controlled tf.
figure;
hold on;
stepplot(G_closed, opts, Name="Closed Loop", LineWidth=2);
stepplot(Second_order_approx/dcgain(Second_order_approx), opts, Name="Open Loop", LineWidth=2);
legend('Location','best', FontSize=20);
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
fontsize(gcf, 20, "points");
hold off;

filepath = fullfile('..','..', '..', 'Prac-3-Report', 'Images', fileSaveName);
exportgraphics(gcf, filepath, 'ContentType','vector');

end