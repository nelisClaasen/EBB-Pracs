classdef EBBPrac < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                 matlab.ui.Figure
        GridLayout               matlab.ui.container.GridLayout
        LeftPanel                matlab.ui.container.Panel
        TabGroup                 matlab.ui.container.TabGroup
        Tab2                     matlab.ui.container.Tab
        SamplingtoofastLabel     matlab.ui.control.Label
        UpdateChannelsButton     matlab.ui.control.Button
        DataSaveEditField        matlab.ui.control.EditField
        DataSaveEditFieldLabel   matlab.ui.control.Label
        SaveDirEditField         matlab.ui.control.EditField
        SaveDirEditFieldLabel    matlab.ui.control.Label
        StopControllingButton    matlab.ui.control.Button
        StartControllingButton   matlab.ui.control.Button
        StartMeasuringButton     matlab.ui.control.StateButton
        StopButton               matlab.ui.control.StateButton
        BaudRateEditField        matlab.ui.control.NumericEditField
        BaudRateEditFieldLabel   matlab.ui.control.Label
        COMPortEditField         matlab.ui.control.EditField
        COMPortEditFieldLabel    matlab.ui.control.Label
        Tab                      matlab.ui.container.Tab
        Setpoint2EditField       matlab.ui.control.NumericEditField
        Setpoint2EditFieldLabel  matlab.ui.control.Label
        D2EditField              matlab.ui.control.NumericEditField
        D2EditFieldLabel         matlab.ui.control.Label
        I2EditField              matlab.ui.control.NumericEditField
        I2EditFieldLabel         matlab.ui.control.Label
        P2EditField              matlab.ui.control.NumericEditField
        P2EditFieldLabel         matlab.ui.control.Label
        Setpoint1EditField       matlab.ui.control.NumericEditField
        Setpoint1EditFieldLabel  matlab.ui.control.Label
        D1EditField              matlab.ui.control.NumericEditField
        D1EditFieldLabel         matlab.ui.control.Label
        I1EditField              matlab.ui.control.NumericEditField
        I1EditFieldLabel         matlab.ui.control.Label
        P1EditField              matlab.ui.control.NumericEditField
        P1EditFieldLabel         matlab.ui.control.Label
        RightPanel               matlab.ui.container.Panel
        UIAxes_2                 matlab.ui.control.UIAxes
        UIAxes                   matlab.ui.control.UIAxes
    end

    % Properties that correspond to apps with auto-reflow
    properties (Access = private)
        onePanelWidth = 576;
    end


    properties (Access = private)
        %Live lines 1 and 2 are for the temperature measurements.
        liveLine1
        liveLine2

        %Live lines 3 and 4 are for the PWM signals.
        liveLine3
        liveLine4

        %Live line for setpoint tracking.
        liveLine5

        %PID values and setpoint for the first controller.
        P1
        I1
        D1
        setpoint1
        
        %PID values and setpoint for the second controller.
        P2
        I2
        D2
        setpoint2

        disturbance
        start_controlling
        output
        capturing
        COM_port
        baud_rate
        window_size
        esp32
        data_save_name % Description
        data_save_dir

        %
        set1_yline
        set2_yline
    end
    
    methods (Access = private)
        
        function updateAllFields(app)
            %Update all fields related to the first controller.
            app.P1EditFieldValueChanged();
            app.I1EditFieldValueChanged();
            app.D1EditFieldValueChanged();
            app.Setpoint1EditFieldValueChanged();

            %Update all fields related to the second controller.
            app.P2EditFieldValueChanged();
            app.I2EditFieldValueChanged();
            app.D2EditFieldValueChanged();
            app.Setpoint2EditFieldValueChanged();

            %Update the data save information.
            app.SaveDirEditFieldValueChanged();
            app.DataSaveEditFieldValueChanged();

            %Update the current state information. (Baudrate, COMPort, etc.)
            app.BaudRateEditFieldValueChanged();
            app.COMPortEditFieldValueChanged();
        end

        function sendUpdatedFields(app)
            %check if serial connection has already been made.
            if isempty(app.esp32)
                app.esp32 = serialport(app.COM_port, app.baud_rate);
                configureTerminator(app.esp32, "LF");
            end
            flush(app.esp32);

            pause(1);

            %Make sure all info is read into esp.
            %First send values for the first controller.
            writeline(app.esp32, sprintf("%d, %.10f", 0, app.P1));
            writeline(app.esp32, sprintf("%d, %.10f", 1, app.I1));
            writeline(app.esp32, sprintf("%d, %.10f", 2, app.D1));
            writeline(app.esp32, sprintf("%d, %.10f", 3, app.setpoint1)); 

            %Then send the values for the second controller.
            writeline(app.esp32, sprintf("%d, %.10f", 8, app.P2));
            writeline(app.esp32, sprintf("%d, %.10f", 9, app.I2));
            writeline(app.esp32, sprintf("%d, %.10f", 10, app.D2));
            writeline(app.esp32, sprintf("%d, %.10f", 11, app.setpoint2)); 

            writeline(app.esp32, sprintf("%d, %d", 5, app.start_controlling)); %
            writeline(app.esp32, sprintf("%d, %.5f", 7, app.capturing)); %
        end
    end


    % Callbacks that handle component events
    methods (Access = private)

        % Value changed function: P1EditField
        function P1EditFieldValueChanged(app, event)
            app.P1 = app.P1EditField.Value;
        end

        % Value changed function: I1EditField
        function I1EditFieldValueChanged(app, event)
            app.I1 = app.I1EditField.Value;
        end

        % Value changed function: D1EditField
        function D1EditFieldValueChanged(app, event)
            app.D1 = app.D1EditField.Value;
        end

        % Value changed function: Setpoint1EditField
        function Setpoint1EditFieldValueChanged(app, event)
            app.setpoint1 = app.Setpoint1EditField.Value;
        end

        % Callback function
        function DisturbanceEditFieldValueChanged(app, event)
            app.disturbance = app.DisturbanceEditField.Value;
        end

        % Callback function
        function DutyCycleEditFieldValueChanged(app, event)
            app.start_controlling = app.DutyCycleEditField.Value;
        end

        % Callback function
        function OutputDropDownValueChanged(app, event)
            app.output = str2double(app.OutputDropDown.Value);
        end

        % Value changed function: StartMeasuringButton
        function StartMeasuringButtonValueChanged(app, event)
            app.StartMeasuringButton.Visible = "off";
            app.StopButton.Visible = "on";
            app.UpdateChannelsButton.Visible = "on";
            app.capturing = 1;
            app.start_controlling = 0; %Always start off with controllers turned off.

            %Call all of the other functions to make sure their values are
            %captured.
            updateAllFields(app);
            sendUpdatedFields(app);

            %Clear axes.
            cla(app.UIAxes);
            cla(app.UIAxes_2);

            %Plotting axes for the temperature measurements.
            app.liveLine1 = animatedline(app.UIAxes, 'Color', 'r', 'DisplayName', 'Temperature 1 Output');
            app.liveLine2 = animatedline(app.UIAxes, 'Color', 'b', 'DisplayName', 'Temperature 2 Output');

            %Plotting axes for the PWM signals.
            app.liveLine3 = animatedline(app.UIAxes_2, 'Color', 'r', 'DisplayName', 'Control Input 1');
            app.liveLine4 = animatedline(app.UIAxes_2, 'Color', 'b', 'DisplayName', 'Control Input 2');
            legend(app.UIAxes_2, 'Location', 'best');

            %Plotting axis for setpoint tracking. On the same axis as the
            %temperatures.
            app.set1_yline = yline(app.UIAxes, app.setpoint1, 'LineStyle', ':', 'Color', 'g', LineWidth=2, DisplayName='Setpoint 1');
            app.set2_yline = yline(app.UIAxes, app.setpoint2, 'LineStyle', ':', 'Color', 'g', LineWidth=2, DisplayName='Setpoint 2');
            legend(app.UIAxes, 'Location', 'best');

            app.window_size = 30; %seconds

            %Define data csv that we will safe to.
            app.SaveDirEditFieldValueChanged();
            mkdir(app.data_save_dir);
            filepath = fullfile(app.data_save_dir, app.data_save_name + ".csv");
            fid = fopen(filepath, 'wt');

            %Running average arrays for the PWM signals.
            N_average = 30;
            pwm1_points = zeros(N_average);
            pwm2_points = zeros(N_average);

            while(app.capturing)
                if app.esp32.NumBytesAvailable > 0
                    rawData = readline(app.esp32);
                    if isstring(rawData)
                        data = str2double(split(rawData, ','));
                        if length(data) > 4
                            data(5) = data(5)/1000;
                        else
                            continue;
                        end
                    end

                    if ~isnan(data(1)) && (length(data) == 6)
                        %Plot temperature data.
                        addpoints(app.liveLine1, data(5), data(1));
                        addpoints(app.liveLine2, data(5), data(2));

                        %Plot setpoint.
                        % addpoints(app.liveLine5, data(5), app.setpoint);
                        %Resize axis.
                        xlim(app.UIAxes, [data(5) - app.window_size, data(5)]);

                        %Update running averages for PWM signals.
                        pwm1_points = [pwm1_points(2:end), data(3)];
                        pwm2_points = [pwm2_points(2:end), data(4)];

                        %Plot PWM signals.
                        addpoints(app.liveLine3, data(5), mean(pwm1_points));
                        addpoints(app.liveLine4, data(5), mean(pwm2_points));
                        %Resize axis.
                        xlim(app.UIAxes_2, [data(5) - app.window_size, data(5)]);

                        %Write data to file.
                        fprintf(fid, rawData);

                        if data(end) == 0
                            app.SamplingtoofastLabel.Visible = "on";
                        else
                            app.SamplingtoofastLabel.Visible = "off";
                        end
                    end

                    drawnow limitrate
                end
            end

            %Close file we are saving to.
            fclose(fid);

            %Send stop signal.
            writeline(app.esp32, sprintf("%d, %.2f", 7, app.capturing));

            clear app.esp32;
        end

        % Value changed function: COMPortEditField
        function COMPortEditFieldValueChanged(app, event)
            app.COM_port = app.COMPortEditField.Value;
        end

        % Value changed function: BaudRateEditField
        function BaudRateEditFieldValueChanged(app, event)
            app.baud_rate = app.BaudRateEditField.Value;
        end

        % Value changed function: StopButton
        function StopButtonValueChanged(app, event)
            app.capturing = false;
            app.start_controlling = false;

            app.StopButton.Visible = "off";
            app.UpdateChannelsButton.Visible = "off";
            app.StartMeasuringButton.Visible = "on";
            app.StartControllingButton.Visible = "on";
            app.StopControllingButton.Visible = "off";
        end

        % Button pushed function: UpdateChannelsButton
        function UpdateChannelsButtonPushed(app, event)
            %Make sure all info is read into esp.
            %First send values for the first controller.
            writeline(app.esp32, sprintf("%d, %.10f", 0, app.P1));
            writeline(app.esp32, sprintf("%d, %.10f", 1, app.I1));
            writeline(app.esp32, sprintf("%d, %.10f", 2, app.D1));
            writeline(app.esp32, sprintf("%d, %.10f", 3, app.setpoint1)); 

            %Then send the values for the second controller.
            writeline(app.esp32, sprintf("%d, %.10f", 8, app.P2));
            writeline(app.esp32, sprintf("%d, %.10f", 9, app.I2));
            writeline(app.esp32, sprintf("%d, %.10f", 10, app.D2));
            writeline(app.esp32, sprintf("%d, %.10f", 11, app.setpoint2));

            writeline(app.esp32, sprintf("%d, %d", 5, app.start_controlling));

            delete(app.set1_yline)
            delete(app.set2_yline)

            app.set1_yline = yline(app.UIAxes, app.setpoint1, 'LineStyle', ':', 'Color', 'g', LineWidth=2, DisplayName='Setpoint 1');
            app.set2_yline = yline(app.UIAxes, app.setpoint2, 'LineStyle', ':', 'Color', 'g', LineWidth=2, DisplayName='Setpoint 2');
        end

        % Value changed function: DataSaveEditField
        function DataSaveEditFieldValueChanged(app, event)
            app.data_save_name = app.DataSaveEditField.Value;
            
        end

        % Button pushed function: StartControllingButton
        function StartControllingButtonPushed(app, event)
            app.start_controlling = 1;
            app.UpdateChannelsButtonPushed();

            app.StartControllingButton.Visible = "off";
            app.StopControllingButton.Visible = "on";
        end

        % Button pushed function: StopControllingButton
        function StopControllingButtonPushed(app, event)
            app.start_controlling = 0;
            app.UpdateChannelsButtonPushed();

            app.StartControllingButton.Visible = "on";
            app.StartControllingButton.Visible = "off";
        end

        % Value changed function: SaveDirEditField
        function SaveDirEditFieldValueChanged(app, event)
            app.data_save_dir = app.SaveDirEditField.Value;
            
        end

        % Value changed function: P2EditField
        function P2EditFieldValueChanged(app, event)
            app.P2 = app.P2EditField.Value;
            
        end

        % Value changed function: I2EditField
        function I2EditFieldValueChanged(app, event)
            app.I2 = app.I2EditField.Value;
            
        end

        % Value changed function: D2EditField
        function D2EditFieldValueChanged(app, event)
            app.D2 = app.D2EditField.Value;
            
        end

        % Value changed function: Setpoint2EditField
        function Setpoint2EditFieldValueChanged(app, event)
            app.setpoint2 = app.Setpoint2EditField.Value;
            
        end

        % Changes arrangement of the app based on UIFigure width
        function updateAppLayout(app, event)
            currentFigureWidth = app.UIFigure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 2x1 grid
                app.GridLayout.RowHeight = {449, 449};
                app.GridLayout.ColumnWidth = {'1x'};
                app.RightPanel.Layout.Row = 2;
                app.RightPanel.Layout.Column = 1;
            else
                % Change to a 1x2 grid
                app.GridLayout.RowHeight = {'1x'};
                app.GridLayout.ColumnWidth = {204, '1x'};
                app.RightPanel.Layout.Row = 1;
                app.RightPanel.Layout.Column = 2;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [100 100 702 449];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {204, '1x'};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.Scrollable = 'on';

            % Create LeftPanel
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;

            % Create TabGroup
            app.TabGroup = uitabgroup(app.LeftPanel);
            app.TabGroup.Position = [3 3 197 442];

            % Create Tab2
            app.Tab2 = uitab(app.TabGroup);
            app.Tab2.Title = 'Tab2';

            % Create COMPortEditFieldLabel
            app.COMPortEditFieldLabel = uilabel(app.Tab2);
            app.COMPortEditFieldLabel.HorizontalAlignment = 'right';
            app.COMPortEditFieldLabel.Position = [13 385 58 22];
            app.COMPortEditFieldLabel.Text = 'COM Port';

            % Create COMPortEditField
            app.COMPortEditField = uieditfield(app.Tab2, 'text');
            app.COMPortEditField.ValueChangedFcn = createCallbackFcn(app, @COMPortEditFieldValueChanged, true);
            app.COMPortEditField.Position = [85 385 100 22];
            app.COMPortEditField.Value = '/dev/ttyUSB0';

            % Create BaudRateEditFieldLabel
            app.BaudRateEditFieldLabel = uilabel(app.Tab2);
            app.BaudRateEditFieldLabel.HorizontalAlignment = 'right';
            app.BaudRateEditFieldLabel.Position = [9 355 62 22];
            app.BaudRateEditFieldLabel.Text = 'Baud Rate';

            % Create BaudRateEditField
            app.BaudRateEditField = uieditfield(app.Tab2, 'numeric');
            app.BaudRateEditField.ValueChangedFcn = createCallbackFcn(app, @BaudRateEditFieldValueChanged, true);
            app.BaudRateEditField.Position = [85 355 100 22];
            app.BaudRateEditField.Value = 1152000;

            % Create StopButton
            app.StopButton = uibutton(app.Tab2, 'state');
            app.StopButton.ValueChangedFcn = createCallbackFcn(app, @StopButtonValueChanged, true);
            app.StopButton.Visible = 'off';
            app.StopButton.Text = 'Stop';
            app.StopButton.Position = [84 316 100 23];

            % Create StartMeasuringButton
            app.StartMeasuringButton = uibutton(app.Tab2, 'state');
            app.StartMeasuringButton.ValueChangedFcn = createCallbackFcn(app, @StartMeasuringButtonValueChanged, true);
            app.StartMeasuringButton.Text = 'Start Measuring';
            app.StartMeasuringButton.Position = [85 316 100 23];

            % Create StartControllingButton
            app.StartControllingButton = uibutton(app.Tab2, 'push');
            app.StartControllingButton.ButtonPushedFcn = createCallbackFcn(app, @StartControllingButtonPushed, true);
            app.StartControllingButton.Position = [83 273 101 23];
            app.StartControllingButton.Text = 'Start Controlling';

            % Create StopControllingButton
            app.StopControllingButton = uibutton(app.Tab2, 'push');
            app.StopControllingButton.ButtonPushedFcn = createCallbackFcn(app, @StopControllingButtonPushed, true);
            app.StopControllingButton.Visible = 'off';
            app.StopControllingButton.Position = [83 273 100 23];
            app.StopControllingButton.Text = 'Stop Controlling';

            % Create SaveDirEditFieldLabel
            app.SaveDirEditFieldLabel = uilabel(app.Tab2);
            app.SaveDirEditFieldLabel.HorizontalAlignment = 'right';
            app.SaveDirEditFieldLabel.Position = [18 220 51 22];
            app.SaveDirEditFieldLabel.Text = 'Save Dir';

            % Create SaveDirEditField
            app.SaveDirEditField = uieditfield(app.Tab2, 'text');
            app.SaveDirEditField.ValueChangedFcn = createCallbackFcn(app, @SaveDirEditFieldValueChanged, true);
            app.SaveDirEditField.Position = [84 220 100 22];
            app.SaveDirEditField.Value = 'DataDemo';

            % Create DataSaveEditFieldLabel
            app.DataSaveEditFieldLabel = uilabel(app.Tab2);
            app.DataSaveEditFieldLabel.HorizontalAlignment = 'right';
            app.DataSaveEditFieldLabel.Position = [7 180 61 22];
            app.DataSaveEditFieldLabel.Text = 'Data Save';

            % Create DataSaveEditField
            app.DataSaveEditField = uieditfield(app.Tab2, 'text');
            app.DataSaveEditField.ValueChangedFcn = createCallbackFcn(app, @DataSaveEditFieldValueChanged, true);
            app.DataSaveEditField.Position = [83 180 100 22];
            app.DataSaveEditField.Value = 'PID_root_V4';

            % Create UpdateChannelsButton
            app.UpdateChannelsButton = uibutton(app.Tab2, 'push');
            app.UpdateChannelsButton.ButtonPushedFcn = createCallbackFcn(app, @UpdateChannelsButtonPushed, true);
            app.UpdateChannelsButton.Visible = 'off';
            app.UpdateChannelsButton.Position = [80 123 108 23];
            app.UpdateChannelsButton.Text = 'Update Channels';

            % Create SamplingtoofastLabel
            app.SamplingtoofastLabel = uilabel(app.Tab2);
            app.SamplingtoofastLabel.Visible = 'off';
            app.SamplingtoofastLabel.Position = [85 17 101 22];
            app.SamplingtoofastLabel.Text = 'Sampling too fast!';

            % Create Tab
            app.Tab = uitab(app.TabGroup);
            app.Tab.Title = 'Tab';

            % Create P1EditFieldLabel
            app.P1EditFieldLabel = uilabel(app.Tab);
            app.P1EditFieldLabel.HorizontalAlignment = 'right';
            app.P1EditFieldLabel.Position = [46 385 25 22];
            app.P1EditFieldLabel.Text = 'P1';

            % Create P1EditField
            app.P1EditField = uieditfield(app.Tab, 'numeric');
            app.P1EditField.ValueChangedFcn = createCallbackFcn(app, @P1EditFieldValueChanged, true);
            app.P1EditField.Position = [85 385 100 22];
            app.P1EditField.Value = 0.09474;

            % Create I1EditFieldLabel
            app.I1EditFieldLabel = uilabel(app.Tab);
            app.I1EditFieldLabel.HorizontalAlignment = 'right';
            app.I1EditFieldLabel.Position = [46 355 25 22];
            app.I1EditFieldLabel.Text = 'I1';

            % Create I1EditField
            app.I1EditField = uieditfield(app.Tab, 'numeric');
            app.I1EditField.ValueChangedFcn = createCallbackFcn(app, @I1EditFieldValueChanged, true);
            app.I1EditField.Position = [85 355 100 22];
            app.I1EditField.Value = 0.00257;

            % Create D1EditFieldLabel
            app.D1EditFieldLabel = uilabel(app.Tab);
            app.D1EditFieldLabel.HorizontalAlignment = 'right';
            app.D1EditFieldLabel.Position = [46 326 25 22];
            app.D1EditFieldLabel.Text = 'D1';

            % Create D1EditField
            app.D1EditField = uieditfield(app.Tab, 'numeric');
            app.D1EditField.ValueChangedFcn = createCallbackFcn(app, @D1EditFieldValueChanged, true);
            app.D1EditField.Position = [85 326 100 22];
            app.D1EditField.Value = 0.6904;

            % Create Setpoint1EditFieldLabel
            app.Setpoint1EditFieldLabel = uilabel(app.Tab);
            app.Setpoint1EditFieldLabel.HorizontalAlignment = 'right';
            app.Setpoint1EditFieldLabel.Position = [14 296 56 22];
            app.Setpoint1EditFieldLabel.Text = 'Setpoint1';

            % Create Setpoint1EditField
            app.Setpoint1EditField = uieditfield(app.Tab, 'numeric');
            app.Setpoint1EditField.ValueChangedFcn = createCallbackFcn(app, @Setpoint1EditFieldValueChanged, true);
            app.Setpoint1EditField.Position = [85 296 100 22];
            app.Setpoint1EditField.Value = 35;

            % Create P2EditFieldLabel
            app.P2EditFieldLabel = uilabel(app.Tab);
            app.P2EditFieldLabel.HorizontalAlignment = 'right';
            app.P2EditFieldLabel.Position = [44 261 25 22];
            app.P2EditFieldLabel.Text = 'P2';

            % Create P2EditField
            app.P2EditField = uieditfield(app.Tab, 'numeric');
            app.P2EditField.ValueChangedFcn = createCallbackFcn(app, @P2EditFieldValueChanged, true);
            app.P2EditField.Position = [83 261 100 22];
            app.P2EditField.Value = 0.1488;

            % Create I2EditFieldLabel
            app.I2EditFieldLabel = uilabel(app.Tab);
            app.I2EditFieldLabel.HorizontalAlignment = 'right';
            app.I2EditFieldLabel.Position = [44 231 25 22];
            app.I2EditFieldLabel.Text = 'I2';

            % Create I2EditField
            app.I2EditField = uieditfield(app.Tab, 'numeric');
            app.I2EditField.ValueChangedFcn = createCallbackFcn(app, @I2EditFieldValueChanged, true);
            app.I2EditField.Position = [83 231 100 22];
            app.I2EditField.Value = 0.00314;

            % Create D2EditFieldLabel
            app.D2EditFieldLabel = uilabel(app.Tab);
            app.D2EditFieldLabel.HorizontalAlignment = 'right';
            app.D2EditFieldLabel.Position = [44 202 25 22];
            app.D2EditFieldLabel.Text = 'D2';

            % Create D2EditField
            app.D2EditField = uieditfield(app.Tab, 'numeric');
            app.D2EditField.ValueChangedFcn = createCallbackFcn(app, @D2EditFieldValueChanged, true);
            app.D2EditField.Position = [83 202 100 22];
            app.D2EditField.Value = 1.174;

            % Create Setpoint2EditFieldLabel
            app.Setpoint2EditFieldLabel = uilabel(app.Tab);
            app.Setpoint2EditFieldLabel.HorizontalAlignment = 'right';
            app.Setpoint2EditFieldLabel.Position = [12 172 56 22];
            app.Setpoint2EditFieldLabel.Text = 'Setpoint2';

            % Create Setpoint2EditField
            app.Setpoint2EditField = uieditfield(app.Tab, 'numeric');
            app.Setpoint2EditField.ValueChangedFcn = createCallbackFcn(app, @Setpoint2EditFieldValueChanged, true);
            app.Setpoint2EditField.Position = [83 172 100 22];
            app.Setpoint2EditField.Value = 35;

            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;

            % Create UIAxes
            app.UIAxes = uiaxes(app.RightPanel);
            title(app.UIAxes, 'Temperature output')
            xlabel(app.UIAxes, 'Time (seconds)')
            ylabel(app.UIAxes, 'Temperature (Celcius)')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.Position = [7 213 489 235];

            % Create UIAxes_2
            app.UIAxes_2 = uiaxes(app.RightPanel);
            title(app.UIAxes_2, 'Control and Disturbance inputs')
            xlabel(app.UIAxes_2, 'Time (seconds)')
            ylabel(app.UIAxes_2, 'Average control input (V)')
            zlabel(app.UIAxes_2, 'Z')
            app.UIAxes_2.Position = [8 7 488 207];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = EBBPrac

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end