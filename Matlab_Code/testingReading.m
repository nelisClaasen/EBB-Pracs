comPort = '/dev/ttyUSB0';
baudRate = 115200;
maxPoints = 200;
dataWindow = zeros(1, maxPoints);
xAxes = 1:maxPoints;

serialportlist

% try 
    esp32 = serialport(comPort, baudRate);
    configureTerminator(esp32, "LF");
    flush(esp32);
    %print('Successfully connected to ESP32 on %s\n', comPort);
% catch ME
%     error('Could not connect to port.');
% end

figureHandle = figure('Name', 'Data Stream', 'NumberTitle','off');
plotHandle = plot(xAxes, dataWindow, 'LineWidth', 1.5, 'Color', [0 0.4470 0.7410]);
grid on;
%axis([1 maxPoints - 10 4100]);

while ishandle(figureHandle)
    if esp32.NumBytesAvailable > 0
        rawData = readline(esp32);
        numericVal = str2double(split(rawData, ','));

        if ~isnan(numericVal(1))
            dataWindow = [dataWindow(2:end), numericVal(1)];

            set(plotHandle, 'YData', dataWindow);

            drawnow;
        end
    end
end

clear esp32;