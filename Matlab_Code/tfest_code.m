%Obtaining the transfer function

%Package the input arrays of both transistors into one matrix (Needs to be
%columns)
V = [v1 , v2];
Temp = [temp1, temp2];
time_step = 0.1;

%use iddata to set up the data for tfest
tfest_data = iddata(Temp, V, time_step);

%estimate nr of poles and zeros, 2 poles since there are two transistors
n_poles = [2,2; 2,2] ;
n_zeors = [1,1;1,1];

%estimate the transfer functions
mimo_tranfer = tfest(tfest_data,n_poles,n_zeors, 'IODelay', NaN);


