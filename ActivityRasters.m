%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% A Static class containing a collection of methods generating Raster graphs of behavioral (licks)
% and Neuronal (Spikes) data plus several combinations, thereof. It is designed to be
% activated by the analysis SW launcher.
%
% Version History:
%   1.00 - First release
%   1.10 - Added support for two file lists, added Burst raster
%   1.20 - Bug fixes
%   1.30 - Added Rogue Licks to burst raster
%   1.31 - Bug Fix: ExperimentName replcaed with GroupName.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef ActivityRasters

    properties (Constant, Access = private)
        RasterLineOffset = -0.1;
        RasterLineHight = 0.2
    end

    methods (Static, Access = public)

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        % Draw the licking raster graph
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [] = LickingRasters(ProjectDirectory, ProjectData, Mouse, Day, outputFileTag) 
            if ActivityRasters.SWVersionError()
                return;
            end
        
            [Status, FileList1, FileList2] = FileUtilities.GetFileLists(ProjectDirectory, ProjectData.MouseGroupName, ProjectData.SessionName, Mouse, Day);
            FirstListLength = length(FileList1);
            FileList = [FileList1; FileList2];
            if Status ~= 0 
                return
            end

            outfiledatecode = 'firstfile';
            Ylables = cell(length(FileList)); 
            MouseTitle = ['Mouse: ', Mouse, ', Session: ', ProjectData.SessionName, ', Day: ', Day];
            figure();
            hold on;

            for i = 1 : length(FileList)
                LickingData = LickingDataObject(ProjectData, [FileList(i).folder '\' FileList(i).name], 1); 
                mouseData = FileUtilities.ExtractMouseID(ProjectDirectory, FileList(i).folder, FileList(i).name);
                Ylables(i) = {['M', mouseData.Mouse, ',D', mouseData.Day]};
                outfiledatecode = FileUtilities.GeneralizeFileDateCode(outfiledatecode, LickingData.DateCode);
                if i > FirstListLength
                    color = 'r';
                else
                    color = 'b';
                end
                ActivityRasters.PlotLickingRasterLine(ProjectData, LickingData.LickingStartTime, i, color);
            end

            hold off;
            ActivityRasters.SetReportAxes(ProjectData, Ylables);
            ActivityRasters.AddPlotTexts(ProjectData.MouseGroupName, MouseTitle);
            FileUtilities.WriteFigureFile(ProjectDirectory, ProjectData, Mouse, Day, 'LickingRaster', outfiledatecode, outputFileTag)
        end


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        % Draw the burst raster graph
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [] = BurstRasters(ProjectDirectory, ProjectData, Mouse, Day, outputFileTag) 
            if ActivityRasters.SWVersionError()
                return;
            end

            [Status, FileList1, FileList2] = FileUtilities.GetFileLists(ProjectDirectory, ProjectData.MouseGroupName, ProjectData.SessionName, Mouse, Day);
            FirstListLength = length(FileList1);
            FileList = [FileList1; FileList2];
            if Status ~= 0 
                return
            end

            outfiledatecode = 'firstfile';
            Ylables = cell(length(FileList)); 
            MouseTitle = ['Mouse: ', Mouse, ', Session: ', ProjectData.SessionName, ', Day: ', Day];
            figure();
            hold on;

            for i = 1 : length(FileList)
                LickingData = LickingDataObject(ProjectData, [FileList(i).folder '\' FileList(i).name], 1); 
                mouseData = FileUtilities.ExtractMouseID(ProjectDirectory, FileList(i).folder, FileList(i).name);
                Ylables(i) = {['M', mouseData.Mouse, ',D', mouseData.Day]};
                outfiledatecode = FileUtilities.GeneralizeFileDateCode(outfiledatecode, LickingData.DateCode);
                BurstData = BurstDataObject(LickingData, ProjectData);
                if i > FirstListLength
                    color1 = 'r';
                    color2 = 'b';
                else
                    color1 = 'b';
                    color2 = 'r';
               end
               ActivityRasters.PlotBurstRasterLine(ProjectData, BurstData, i, color1);
               ActivityRasters.PlotLickingRasterLine(ProjectData, BurstData.RogueLicks, i, color2)
            end

            hold off;
            ActivityRasters.SetReportAxes(ProjectData, Ylables);
            ActivityRasters.AddPlotTexts(ProjectData.MouseGroupName, MouseTitle);
            FileUtilities.WriteFigureFile(ProjectDirectory, ProjectData, Mouse, Day, 'LickingRaster', outfiledatecode, outputFileTag)
        end
    end
      
    methods (Static, Access = private)

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        % Verify SW version
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [status] = SWVersionError()
            status = (FileUtilities.VerifySWVersion('ActivityRasters', '1.31') == 1);     % version error
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        % draw a single line of the licking raster graph
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [] = PlotLickingRasterLine(ProjectData, LickingVector, HightOffset, color)
            TrialPoints = LickingVector(LickingVector > ProjectData.StartTime & LickingVector < ProjectData.EndTime);

            y1 = HightOffset + ActivityRasters.RasterLineOffset;
            y2 = HightOffset + ActivityRasters.RasterLineOffset + ActivityRasters.RasterLineHight;
            for i = 1 : length(TrialPoints)
                %text(TrialPoints(i), HightOffset, '|' , 'FontSize', 12, 'fontWeight', 'bold', 'color', color); 
                %rectangle('Position', [x, y, width, hight], 'FaceColor', 'w', 'EdgeColor', color, 'LineWidth', 1);
                
                line([TrialPoints(i) TrialPoints(i)], [y1 y2], 'color', color, 'LineWidth', 1);
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        % Set reports axes (limites and titles)
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [] = SetReportAxes(ProjectData, Ylables)
            ylim([0, length(Ylables) + 1]);
            xlim([ProjectData.StartTime, ProjectData.EndTime]);

            yticks(1 : length(Ylables));
            yticklabels(Ylables);

            ylabel('Mice');
            xlabel('Time [Seconds]');
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % This function adds text to the various activity plots.
        % The Axis tags and ticks are also adjusted. 
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [] = AddPlotTexts(Group, MouseTitle)
            title([cellstr([Group, ' - Licking behaviour']) ; cellstr(MouseTitle)]);          
        end


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Draws a single line of the burst raster 
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [] = PlotBurstRasterLine(ProjectData, BurstData, HightOffset, color)
            for BurstIndex = 1 : length(BurstData.StartTime)
                if BurstData.StartTime(BurstIndex) >= ProjectData.StartTime && BurstData.EndTime(BurstIndex) <= ProjectData.EndTime 
                   % draw primary section
                    x = BurstData.StartTime(BurstIndex);
                    y = HightOffset + ActivityRasters.RasterLineOffset;
                    hight = ActivityRasters.RasterLineHight * BurstData.Efficiency(BurstIndex) / 10;  %efficency is scaled to 10;
                    width = BurstData.EndTime(BurstIndex) - BurstData.StartTime(BurstIndex);
                    rectangle('Position', [x, y, width, hight], 'FaceColor', color, 'EdgeColor', color, 'LineWidth', 1);

                    % draw the non primary section
                    y = y + hight; 
                    hight = ActivityRasters.RasterLineHight - hight;
                    rectangle('Position', [x, y, width, hight], 'FaceColor', 'w', 'EdgeColor', color, 'LineWidth', 1);
                end
            end
        end

    end
end


%#####################################################################
% old code leftovers - I am keeping it, in case I will have to
% reincorporate them
%######################################################################

%                 case 3         % Licking Burst
%                     TitleText = [MouseTitle, ' - Licking behaviour, '];
%                     SubTitleText = 'Showing Burst Length (Red) and Frequency (Blue)';

        %         case {4, 5}         % Neuronal plot
        %             TitleText = [MouseTitle, ' - Neuronal Spikes'];
        %             SubTitleText = NeuronTitle;
        %     
        %         case 3         % Neuronal plot overlayed on Behavioral plot 
        %             TitleText = [MouseTitle, ' - Licking behaviour & Neuronal Spikes'];
        %             SubTitleText = ['Valid lick duration: ', ...
        %                         char(num2str(MinLickTime * 1000)), ' - ', ...
        %                         char(num2str(MaxLickTime * 1000)), ' [mSec]); ', ...
        %                         NeuronTitle];
        %                     
        %         case 6         % Spike/Lick corelation graph
        %             TitleText = [MouseTitle, ' - Corelation between Neuronal Firing and Licking Bihavior'];
        %             SubTitleText = ['Valid lick duration: ', ...
        %                         char(num2str(MinLickTime * 1000)), ' - ', ...
        %                         char(num2str(MaxLickTime * 1000)), ' [mSec]); ', ...
        %                         NeuronTitle];                    
        %         
        %     if ReportType ~= 6
        %         ylabel('Trials');
        %         if ReportType ~= 4    % PSTH are not ploted
        %             xlabel('Time [Seconds] - Taste solution provided between 0 and 10');
        %         end
        %         xlim([StartTime EndTime])
        %         ylim([0 length(TasteDeliveryTime) + 1])
        %     else
        %         ylabel('Spike / Sec');
        %         xlabel('Lick Count / Sec');
        %     end
