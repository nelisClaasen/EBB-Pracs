classdef EBBPrac < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                   matlab.ui.Figure
        GridLayout                 matlab.ui.container.GridLayout
        LeftPanel                  matlab.ui.container.Panel
        TabGroup                   matlab.ui.container.TabGroup
        Tab                        matlab.ui.container.Tab
        DataSaveEditField          matlab.ui.control.EditField
        DataSaveEditFieldLabel     matlab.ui.control.Label
        SamplingtoofastLabel       matlab.ui.control.Label
        UpdateChannelsButton       matlab.ui.control.Button
        StartButton                matlab.ui.control.StateButton
        StopButton                 matlab.ui.control.StateButton
        OutputDropDown             matlab.ui.control.DropDown
        OutputDropDownLabel        matlab.ui.control.Label
        DutyCycleEditField         matlab.ui.control.NumericEditField
        DutyCycleEditFieldLabel    matlab.ui.control.Label
        DisturbanceEditField       matlab.ui.control.NumericEditField
        DisturbanceEditFieldLabel  matlab.ui.control.Label
        SetpointEditField          matlab.ui.control.NumericEditField
        SetpointEditFieldLabel     matlab.ui.control.Label
        DEditField                 matlab.ui.control.NumericEditField
        DEditFieldLabel            matlab.ui.control.Label
        IEditField                 matlab.ui.control.NumericEditField
        IEditFieldLabel            matlab.ui.control.Label
        PEditField                 matlab.ui.control.NumericEditField
        PEditFieldLabel            matlab.ui.control.Label
        Tab2                       matlab.ui.container.Tab
        BaudRateEditField          matlab.ui.control.NumericEditField
        BaudRateEditFieldLabel     matlab.ui.control.Label
        COMPortEditField           matlab.ui.control.EditField
        COMPortEditFieldLabel      matlab.ui.control.Label
        RightPanel                 matlab.ui.container.Panel
        UIAxes_2                   matlab.ui.control.UIAxes
        UIAxes                     matlab.ui.control.UIAxes
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
        P
        I
        D
        setpoint
        disturbance
        duty_cycle
        output
        capturing
        COM_port
        baud_rate
        window_size
        esp32
        data_save_name % Description
    end


    % Callbacks that handle component events
    methods (Access = private)

        % Value changed function: PEditField
        function PEditFieldValueChanged(app, event)
            app.P = app.PEditField.Value;
        end

        % Value changed function: IEditField
        function IEditFieldValueChanged(app, event)
            app.I = app.IEditField.Value;
        end

        % Value changed function: DEditField
        function DEditFieldValueChanged(app, event)
            app.D = app.DEditField.Value;
        end

        % Value changed function: SetpointEditField
        function SetpointEditFieldValueChanged(app, event)
            app.setpoint = app.SetpointEditField.Value;
        end

        % Value changed function: DisturbanceEditField
        function DisturbanceEditFieldValueChanged(app, event)
            app.disturbance = app.DisturbanceEditField.Value;
        end

        % Value changed function: DutyCycleEditField
        function DutyCycleEditFieldValueChanged(app, event)
            app.duty_cycle = app.DutyCycleEditField.Value;
        end

        % Value changed function: OutputDropDown
        function OutputDropDownValueChanged(app, event)
            app.output = str2double(app.OutputDropDown.Value);
        end

        % Value changed function: StartButton
        function StartButtonValueChanged(app, event)
            app.StartButton.Visible = "off";
            app.StopButton.Visible = "on";
            app.UpdateChannelsButton.Visible = "on";
            app.capturing = true;

            %Call all of the other functions to make sure their values are
            %captured.
            app.PEditFieldValueChanged();
            app.IEditFieldValueChanged();
            app.DEditFieldValueChanged();
            app.SetpointEditFieldValueChanged();
            app.DisturbanceEditFieldValueChanged();
            app.DutyCycleEditFieldValueChanged();
            app.OutputDropDownValueChanged();
            app.BaudRateEditFieldValueChanged();
            app.COMPortEditFieldValueChanged();
            app.DataSaveEditFieldValueChanged();

            if isempty(app.esp32)
                app.esp32 = serialport(app.COM_port, app.baud_rate);
                configureTerminator(app.esp32, "LF");
            end
            flush(app.esp32);

            pause(1);

            %Make sure all info is read into esp.
            writeline(app.esp32, sprintf("%d, %.2f", 0, app.P)); %
            writeline(app.esp32, sprintf("%d, %.2f", 1, app.I)); %
            writeline(app.esp32, sprintf("%d, %.2f", 2, app.D)); %
            writeline(app.esp32, sprintf("%d, %.2f", 3, app.setpoint)); %
            writeline(app.esp32, sprintf("%d, %.2f", 4, app.disturbance)); %
            writeline(app.esp32, sprintf("%d, %d", 5, app.duty_cycle)); %
            writeline(app.esp32, sprintf("%d, %.2f", 6, app.output)); %
            writeline(app.esp32, sprintf("%d, %.2f", 7, app.capturing)); %

            %Clear axes.
            cla(app.UIAxes);
            cla(app.UIAxes_2);

            %Plotting axes for the temperature measurements.
            app.liveLine1 = animatedline(app.UIAxes, 'Color', 'r');
            app.liveLine2 = animatedline(app.UIAxes, 'Color', 'b');

            %Plotting axes for the PWM signals.
            app.liveLine3 = animatedline(app.UIAxes_2, 'Color', 'r');
            app.liveLine4 = animatedline(app.UIAxes_2, 'Color', 'b');

            app.window_size = 30; %seconds

            %Define data csv that we will safe to.
            fid = fopen(app.data_save_name + ".csv", 'wt');

            while(app.capturing)
                if app.esp32.NumBytesAvailable > 0
                    rawData = readline(app.esp32);
                    data = str2double(split(rawData, ','));
                    data(5) = data(5)/1000;

                    if ~isnan(data(1)) && (length(data) == 6)
                        %Plot temperature data.
                        addpoints(app.liveLine1, data(5), data(1));
                        addpoints(app.liveLine2, data(5), data(2));
                        xlim(app.UIAxes, [data(5) - app.window_size, data(5)]);

                        %Plot PWM signals.
                        addpoints(app.liveLine3, data(5), data(3));
                        addpoints(app.liveLine4, data(5), data(4));
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
            app.StopButton.Visible = "off";
            app.UpdateChannelsButton.Visible = "off";
            app.StartButton.Visible = "on";

        end

        % Button pushed function: UpdateChannelsButton
        function UpdateChannelsButtonPushed(app, event)
            app.DutyCycleEditFieldValueChanged();
            app.OutputDropDownValueChanged();
            writeline(app.esp32, sprintf("%d, %.2f", 5, app.duty_cycle));
            writeline(app.esp32, sprintf("%d, %.2f", 6, app.output));
        end

        % Value changed function: DataSaveEditField
        function DataSaveEditFieldValueChanged(app, event)
            app.data_save_name = app.DataSaveEditField.Value;
            
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

            % Create Tab
            app.Tab = uitab(app.TabGroup);
            app.Tab.Title = 'Tab';

            % Create PEditFieldLabel
            app.PEditFieldLabel = uilabel(app.Tab);
            app.PEditFieldLabel.HorizontalAlignment = 'right';
            app.PEditFieldLabel.Position = [46 385 25 22];
            app.PEditFieldLabel.Text = 'P';

            % Create PEditField
            app.PEditField = uieditfield(app.Tab, 'numeric');
            app.PEditField.ValueChangedFcn = createCallbackFcn(app, @PEditFieldValueChanged, true);
            app.PEditField.Position = [85 385 100 22];

            % Create IEditFieldLabel
            app.IEditFieldLabel = uilabel(app.Tab);
            app.IEditFieldLabel.HorizontalAlignment = 'right';
            app.IEditFieldLabel.Position = [46 355 25 22];
            app.IEditFieldLabel.Text = 'I';

            % Create IEditField
            app.IEditField = uieditfield(app.Tab, 'numeric');
            app.IEditField.ValueChangedFcn = createCallbackFcn(app, @IEditFieldValueChanged, true);
            app.IEditField.Position = [85 355 100 22];

            % Create DEditFieldLabel
            app.DEditFieldLabel = uilabel(app.Tab);
            app.DEditFieldLabel.HorizontalAlignment = 'right';
            app.DEditFieldLabel.Position = [46 326 25 22];
            app.DEditFieldLabel.Text = 'D';

            % Create DEditField
            app.DEditField = uieditfield(app.Tab, 'numeric');
            app.DEditField.ValueChangedFcn = createCallbackFcn(app, @DEditFieldValueChanged, true);
            app.DEditField.Position = [85 326 100 22];

            % Create SetpointEditFieldLabel
            app.SetpointEditFieldLabel = uilabel(app.Tab);
            app.SetpointEditFieldLabel.HorizontalAlignment = 'right';
            app.SetpointEditFieldLabel.Position = [21 296 49 22];
            app.SetpointEditFieldLabel.Text = 'Setpoint';

            % Create SetpointEditField
            app.SetpointEditField = uieditfield(app.Tab, 'numeric');
            app.SetpointEditField.ValueChangedFcn = createCallbackFcn(app, @SetpointEditFieldValueChanged, true);
            app.SetpointEditField.Position = [85 296 100 22];

            % Create DisturbanceEditFieldLabel
            app.DisturbanceEditFieldLabel = uilabel(app.Tab);
            app.DisturbanceEditFieldLabel.HorizontalAlignment = 'right';
            app.DisturbanceEditFieldLabel.Position = [1 265 69 22];
            app.DisturbanceEditFieldLabel.Text = 'Disturbance';

            % Create DisturbanceEditField
            app.DisturbanceEditField = uieditfield(app.Tab, 'numeric');
            app.DisturbanceEditField.ValueChangedFcn = createCallbackFcn(app, @DisturbanceEditFieldValueChanged, true);
            app.DisturbanceEditField.Position = [85 265 100 22];

            % Create DutyCycleEditFieldLabel
            app.DutyCycleEditFieldLabel = uilabel(app.Tab);
            app.DutyCycleEditFieldLabel.HorizontalAlignment = 'right';
            app.DutyCycleEditFieldLabel.Position = [9 235 63 22];
            app.DutyCycleEditFieldLabel.Text = 'Duty Cycle';

            % Create DutyCycleEditField
            app.DutyCycleEditField = uieditfield(app.Tab, 'numeric');
            app.DutyCycleEditField.ValueChangedFcn = createCallbackFcn(app, @DutyCycleEditFieldValueChanged, true);
            app.DutyCycleEditField.Position = [86 235 100 22];
            app.DutyCycleEditField.Value = 100;

            % Create OutputDropDownLabel
            app.OutputDropDownLabel = uilabel(app.Tab);
            app.OutputDropDownLabel.HorizontalAlignment = 'right';
            app.OutputDropDownLabel.Position = [30 199 41 22];
            app.OutputDropDownLabel.Text = 'Output';

            % Create OutputDropDown
            app.OutputDropDown = uidropdown(app.Tab);
            app.OutputDropDown.Items = {'None', 'Channel1', 'Channel2', 'Both'};
            app.OutputDropDown.ItemsData = {'3', '0', '1', '2'};
            app.OutputDropDown.ValueChangedFcn = createCallbackFcn(app, @OutputDropDownValueChanged, true);
            app.OutputDropDown.Position = [85 199 100 22];
            app.OutputDropDown.Value = '3';

            % Create StopButton
            app.StopButton = uibutton(app.Tab, 'state');
            app.StopButton.ValueChangedFcn = createCallbackFcn(app, @StopButtonValueChanged, true);
            app.StopButton.Visible = 'off';
            app.StopButton.Text = 'Stop';
            app.StopButton.Position = [85 168 100 23];

            % Create StartButton
            app.StartButton = uibutton(app.Tab, 'state');
            app.StartButton.ValueChangedFcn = createCallbackFcn(app, @StartButtonValueChanged, true);
            app.StartButton.Text = 'Start';
            app.StartButton.Position = [86 168 100 23];

            % Create UpdateChannelsButton
            app.UpdateChannelsButton = uibutton(app.Tab, 'push');
            app.UpdateChannelsButton.ButtonPushedFcn = createCallbackFcn(app, @UpdateChannelsButtonPushed, true);
            app.UpdateChannelsButton.Visible = 'off';
            app.UpdateChannelsButton.Position = [81 136 108 23];
            app.UpdateChannelsButton.Text = 'Update Channels';

            % Create SamplingtoofastLabel
            app.SamplingtoofastLabel = uilabel(app.Tab);
            app.SamplingtoofastLabel.Visible = 'off';
            app.SamplingtoofastLabel.Position = [90 12 101 22];
            app.SamplingtoofastLabel.Text = 'Sampling too fast!';

            % Create DataSaveEditFieldLabel
            app.DataSaveEditFieldLabel = uilabel(app.Tab);
            app.DataSaveEditFieldLabel.HorizontalAlignment = 'right';
            app.DataSaveEditFieldLabel.Position = [10 96 61 22];
            app.DataSaveEditFieldLabel.Text = 'Data Save';

            % Create DataSaveEditField
            app.DataSaveEditField = uieditfield(app.Tab, 'text');
            app.DataSaveEditField.ValueChangedFcn = createCallbackFcn(app, @DataSaveEditFieldValueChanged, true);
            app.DataSaveEditField.Position = [86 96 100 22];
            app.DataSaveEditField.Value = 'PWM1StepV0';

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
            app.BaudRateEditField.Value = 115200;

            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;

            % Create UIAxes
            app.UIAxes = uiaxes(app.RightPanel);
            title(app.UIAxes, 'Title')
            xlabel(app.UIAxes, 'X')
            ylabel(app.UIAxes, 'Y')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.Position = [7 213 489 235];

            % Create UIAxes_2
            app.UIAxes_2 = uiaxes(app.RightPanel);
            title(app.UIAxes_2, 'Title')
            xlabel(app.UIAxes_2, 'X')
            ylabel(app.UIAxes_2, 'Y')
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