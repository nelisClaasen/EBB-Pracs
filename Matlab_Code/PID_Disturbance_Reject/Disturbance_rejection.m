% Example: A simple first-order system. Replace with your actual plant transfer function.
numerator = [0.1175];
denominator = [1 0.0076]; 
G11 = tf(numerator, denominator);

opts = pidtuneOptions('DesignFocus', 'disturbance-rejection');
[C2_pid, info] = pidtune(G11, 'PID', opts);

% View the results in the command window
C2_pid

Kp = C2_pid.Kp;
Ki = C2_pid.Ki;
Kd = C2_pid.Kd;
