%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% A licking data object holds all the behavioral information recorded in one session. 
% The constructor loads the data from the relevant "behavioraldata.mat"
% into public properties.
%
% Version History:
%   1.00 - First release
%   1.10 - Added function to calculate time slots for the analysis bins.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef LickingDataObject

    properties (Access = public)
        LickingStartTime
        LickingEndTime
        DateCode
    end

    methods (Access = public)
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        % Class constractor. Loads the data from the licking .mat file, filters Licking 
        % noise and generats lick vectors. 
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = LickingDataObject(ProjectData, FileName, FilterNoise)
            if FileUtilities.VerifySWVersion('LickingDataObject', '1.10') == 1     % version error
               return;
            end

            load(FileName, 'LickingStartTime', 'LickingEndTime');
            
            nameElements = split(FileName, '\');
            obj.DateCode = cell2mat(extractBefore(nameElements(end), '_')); 
            
            if FilterNoise  % filter invalid licks                 
                % Filer Lickometer data for Min ILI (start to Start)
                ILI = diff (LickingStartTime);
                ValidLicks = find(ILI >= ProjectData.MinLickTime / 1000);
                obj.LickingStartTime = LickingStartTime(ValidLicks);
                obj.LickingEndTime = LickingEndTime(ValidLicks);
            end
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        % Returns a vector of start times (first lick) for the behavioral bins. 
        % Bins can be either equal time or equal consumption percentage.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function BinsStartTime = CalculateBins(obj, ProjectData, consumptionBins)
            BinsStartTime = zeros(ProjectData.BinNum, 1);         
            if ~consumptionBins
                BinWidth = (ProjectData.EndTime - ProjectData.StartTime) / ProjectData.BinNum;
                for i = 1 : ProjectData.BinNum
                    BinsStartTime(i) = ProjectData.StartTime + BinWidth * (i -1);
                end
            else
                firstLickIndex = int32(length(obj.LickingStartTime) * ProjectData.StartTime / 100);
                if firstLickIndex == 0
                    firstLickIndex = 1; % int32 trancates. Which is the right thing to do unless it becomes 0
                end
                lastLickIndex = int32(length(obj.LickingStartTime) * ProjectData.EndTime / 100);
                startTime = obj.LickingStartTime(firstLickIndex);
                endTime = obj.LickingStartTime(lastLickIndex);
                BinWidth = (endTime - startTime) / ProjectData.BinNum;
                for i = 1 : ProjectData.BinNum
                    BinsStartTime(i) = startTime + BinWidth * (i - 1);
                end
            end
        end

    end   % public methods
end       % class