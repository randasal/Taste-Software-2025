%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% A Static class containing a collection of methods generating export files for various
% data elements. The expoert files are designed to be easily imported (or copied) into 
% statistical SW, such as SPSS used for further analysys
%
% Version History:
%   1.00 - First release
%   1.10 - Added Rouge licks column to the export burst analysis. Export behavioral data added.
%   1.11 - change export data type from cllstr to cell (heterogeneous data types)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef ExportData

    methods (Static, Access = public)

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Export burst analysys results of multiple mice. The bursts are grouped into Bins
        % and averaged. Each mouse gets one line in the exported file, which is 
        % stored in the upper most relevant directory based on the UI parameters 
        % (e.g. if mouse is 'all' or 'list' file is stored in the Experiment directory
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [] = ExportBursts(ProjectDirectory, ProjectData, Mouse, Day, binType, outputFileTag)
        
            % Verify SW version
            if ExportData.SWVersionError()
                return;
            end

            % Get input files
            [Status, FileList1, FileList2] = FileUtilities.GetFileLists(ProjectDirectory, ProjectData.MouseGroupName, ProjectData.SessionName, Mouse, Day);
            FileList = [FileList1; FileList2];
            if Status ~= 0 
                return
            end
        
            disp([num2str(length(FileList)) '  Behavioral files found']);
            if isempty(FileList)
                return
            end

            if binType == 0  
                outfilestr = ['Time_Bins' outputFileTag '.xlsx'];
            else
                outfilestr = ['Consumption_Bins' outputFileTag '.xlsx'];
            end
        
            % Build Title vectors for the output excel file.
            TitleVector1 = [{'Mouse Data'} {' '} {' '} {' '}];
            tempTitle = {'Start Time' 'Burst Licks' 'Burst Count', 'Burst Length', 'Primary Frequency', ...
                         'Effective Frequency', 'Burst Effiency', 'Average Pause', 'Rouge Licks'};
            for j = 1 : ProjectData.BinNum
                for i = 1 : length(tempTitle)
                    TitleVector1 = [TitleVector1 tempTitle(i)]; %#ok<AGROW>
                end
            end
        
            TitleVector2 = [{'Group'} {'Mouse'} {'Session'} {'day'}]; 
            for i = 1 : ProjectData.BinNum
                for j = 1 : length(tempTitle)
                    TitleVector2 = [TitleVector2 {['Bin-' num2str(i)]}];  %#ok<AGROW>
                end
            end
        
            DataToExport.Title = [TitleVector1 ; TitleVector2];
            allMiceData.Group = 'firstfile';
            allMiceData.Mouse = 'firstfile';
            allMiceData.Session = 'firstfile';
            allMiceData.Day = 'firstfile';
            allMiceDateCode = 'firstfile';
        
            % Process .mat files and Build output data array
            DataArray = cell(repmat({' '}, length(FileList), length(TitleVector1)));
            for i = 1 : length(FileList)
                Fname = [FileList(i).folder '\' FileList(i).name];
                disp(['Processing File:  ' Fname]); 
        
                % Load valid Licking data into global work space
                LickingData = LickingDataObject(ProjectData, [FileList(i).folder '\' FileList(i).name], 1); 
                mouseData = FileUtilities.ExtractMouseID(ProjectDirectory, FileList(i).folder, FileList(i).name);

                allMiceDateCode = FileUtilities.GeneralizeFileDateCode(allMiceDateCode, LickingData.DateCode);
                allMiceData = FileUtilities.GeneralizeMiceData(allMiceData, mouseData);
     
                BinsStartTime = LickingData.CalculateBins(ProjectData, binType);
                Bursts = BurstDataObject(LickingData, ProjectData);          % Identify Bursts
                BurstBins = Bursts.CalculateBinAverages(BinsStartTime);        
                
                DataArray(i, 1) = {mouseData.Group};
                DataArray(i, 2) = {mouseData.Mouse};
                DataArray(i, 3) = {mouseData.Session};
                DataArray(i, 4) = {mouseData.Day};
        
                for j = 1 : length(BinsStartTime) 
                    DataArray(i, 5 + (j - 1) * 9) = {BinsStartTime(j)};
                    DataArray(i, 6 + (j - 1) * 9 : 13 + (j - 1) * 9) = num2cell(BurstBins(j, :));
                end
            end
        
            DataToExport.DataArray = DataArray;
            fStruct = struct ('Prefix', allMiceDateCode, 'Name', outfilestr, 'Sheet', 'Stimulus');
            FileUtilities.WriteXlsFile(ProjectDirectory, ProjectData, allMiceData.Mouse, allMiceData.Day, DataToExport, fStruct); 
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Export behavioral data of multiple mice. Each mouse gets two lines in the exported file.
        % The first line is a vector of all licks. The second marks the burst with start and end indications.
        % The file is stored in the upper most relevant directory based on the UI parameters 
        % (e.g. if mouse is 'all' or 'list' file is stored in the Experiment directory
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [] = ExportBehavior(ProjectDirectory, ProjectData, Mouse, Day)
        
            % Verify SW version
            if ExportData.SWVersionError()
                return;
            end

            % Get input files
            [Status, FileList1, FileList2] = FileUtilities.GetFileLists(ProjectDirectory, ProjectData.MouseGroupName, ProjectData.SessionName, Mouse, Day);
            FileList = [FileList1; FileList2];
            if Status ~= 0 
                return
            end
        
            disp([num2str(length(FileList)) '  Behavioral files found']);
            if isempty(FileList)
                return
            end
        
            % Build Title vectors for the output excel file.
            TitleVector1 = [cellstr('Mouse Data') cellstr(' ') cellstr(' ') cellstr(' ') cellstr(' ')]; 
            TitleVector2 = [cellstr('Group') cellstr('Mouse') cellstr('Session') cellstr('day') cellstr('Licks/Bursts')];
        
            DataToExport.Title = [TitleVector1 ; TitleVector2];
            allMiceData.Group = 'firstfile';
            allMiceData.Mouse = 'firstfile';
            allMiceData.Session = 'firstfile';
            allMiceData.Day = 'firstfile';
            allMiceDateCode = 'firstfile';
        
            % Process .mat files and Build output data array
            maxLickVectorLength = 0;
            DataArray = cell(repmat({' '}, length(FileList) * 2, 4 + maxLickVectorLength));
            for i = 1 : length(FileList)
                Fname = [FileList(i).folder '\' FileList(i).name];
                disp(['Processing File:  ' Fname]); 
        
                % Load valid Licking data into global work space
                LickingData = LickingDataObject(ProjectData, [FileList(i).folder '\' FileList(i).name], 1); 
                mouseData = FileUtilities.ExtractMouseID(ProjectDirectory, FileList(i).folder, FileList(i).name);

                allMiceDateCode = FileUtilities.GeneralizeFileDateCode(allMiceDateCode, LickingData.DateCode);
                allMiceData = FileUtilities.GeneralizeMiceData(allMiceData, mouseData);
     
                Bursts = BurstDataObject(LickingData, ProjectData);          % Identify Bursts
                
                mouseRawIndex = i * 2 - 1;
                DataArray(mouseRawIndex, 1) = {mouseData.Group};
                DataArray(mouseRawIndex, 2) = {mouseData.Mouse};
                DataArray(mouseRawIndex, 3) = {mouseData.Session};
                DataArray(mouseRawIndex, 4) = {mouseData.Day};
        
                % resize output data array
                if length(LickingData.LickingStartTime) > maxLickVectorLength
                    DataArray = FileUtilities.ResizeOutData(DataArray, 4 + length(LickingData.LickingStartTime));
                    maxLickVectorLength = length(LickingData.LickingStartTime);
                end 

                DataArray(mouseRawIndex, 5 : 4 + length(LickingData.LickingStartTime)) = num2cell(LickingData.LickingStartTime);

                % mark bursts
                for j = 1 : length(Bursts.StartTime) 
                    StartBurstIndex = find(LickingData.LickingStartTime == Bursts.StartTime(j));
                    EndBurstIndex = find(LickingData.LickingStartTime == Bursts.EndTime(j));
                    DataArray(mouseRawIndex + 1, 4 + StartBurstIndex) = {'Start'};
                    DataArray(mouseRawIndex + 1, 4 + EndBurstIndex) = {'End'};
                end
            end

            DataToExport.Title = FileUtilities.ResizeOutData(DataToExport.Title, 4 + length(LickingData.LickingStartTime));
            DataToExport.DataArray = DataArray;
            fStruct = struct ('Prefix', allMiceDateCode, 'Name', 'Behavior.xlsx', 'Sheet', 'Data');
            FileUtilities.WriteXlsFile(ProjectDirectory, ProjectData, allMiceData.Mouse, allMiceData.Day, DataToExport, fStruct); 
        end

    end  % Static Public Methods

    methods (Static, Access = private)

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        % Verify SW version
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [status] = SWVersionError()
            status = (FileUtilities.VerifySWVersion('ExportData', '1.10') == 1);     % version error
        end
           
    end  % Static private  Methods

end




% Old code. I am keeping it, just in case.

% 
%     if bitand(ReportPar, 32) == 32
%         Normalize = 1;       % normalize exported data (function may vary from one report to another)
%     else
%         Normalize = 0;      
%     end
% 


% 
%     switch FileType
%         case 1       % all data
%             ExportAllData(FileList, TimeBins, AverageTrials, SyncToLick, Mouse, Day); 
% 
%         case 2       % accumulated bins (lick count only)
%             ExportAccumulatedBins(FileList, TimeBins, SyncToLick);
% 
%         case 3       % Stimulus Only
%             ExportFunctionalBin(FileList, TimeBins, AverageTrials, SyncToLick, 1);  % 1 is stymulus function
% 
%         case 4       % Consumption period
%             ExportFunctionalBin(FileList, TimeBins, AverageTrials, SyncToLick, 4);  % 4 is consumption functions
% 
%         case 5       % raw data
%             ExportRawData(FileList, TimeBins, SyncToLick, Mouse, Day); 
% 
%         case 6       % ILI Distribution
%             ILIDistribution(FileList, TimeBins, Normalize);
%     end
% end
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %
% % Export all behavioral data from all bins of multiple mice. Each mouse
% % gets a line in the file, each parameters is stroed on a separate
% % worksheet
% %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function [] = ExportAllData(FileList, TimeBins, AverageTrials, SyncToLick, Mouse, Day)
%     global OutputFileTag ProjectData;
% 
%     disp([num2str(length(FileList)) '  Behavioral files found']);
% 
%     allMiceData.Group = 'init';
%     allMiceData.Mouse = 'init';
%     allMiceData.Session = 'init';
%     allMiceData.Day = 'init';
%     allMiceDateCode = 'init';
% 
%     TitleVectorN = 1 : ProjectData.BinNum;
%     TitleVectorS = [];
%     for i = 1 : length(TitleVectorN)
%         TitleVectorS = [TitleVectorS cellstr(['bin-' num2str(TitleVectorN(i))])]; %#ok<AGROW>
%     end
%     DataToExport.Title = ['Group' 'Mouse' 'Session' 'Day' TitleVectorS]; 
% 
%     BDataArray = zeros(length(FileList), length(TitleVectorN), 7);
%     MDataArray = cellstr(num2str(zeros(length(FileList), 4)));
% 
%     % Process .mat files and Build output data array
%     for i = 1 : length(FileList)
% 
%         Fname = [FileList(i).folder '\' FileList(i).name];
%         disp(['Processing File:  ' Fname]); 
% 
%             % Load valid Licking data into global work space
%         [~, DateCode, ~] = TasteUtilities(1, 0, 0, Fname, 1);       
%         [~, MouseData, ~] = TasteUtilities(12, 0, 0, FileList(i).folder, FileList(i).name);
%         [~, allMiceData, ~] = TasteUtilities(15, 0, 0, allMiceData, MouseData);
%         [~, allMiceDateCode, ~] = TasteUtilities(16, 0, 0, allMiceDateCode, DateCode);
% 
%         LickCounts = BinsAndBursts(2, TimeBins, SyncToLick, []);           % calculate Lick bins
%         LickBarValues = BinsAndBursts(3, LickCounts, AverageTrials, []);   % Calculate Lick bars
%         Bursts = BinsAndBursts(1, [], [], []);                             % Identify Bursts
%         BurstBins = BinsAndBursts(5, Bursts, TimeBins, SyncToLick);        % Calculate Bursts bins
%         BurstBars = BinsAndBursts(6, BurstBins, [], []);                   % Calculate Burst bars
% 
%         MDataArray(i, 1) = cellstr(MouseData.Group);
%         MDataArray(i, 2) = cellstr(MouseData.Mouse);
%         MDataArray(i, 3) = cellstr(MouseData.Session);
%         MDataArray(i, 4) = cellstr(MouseData.Day);
% 
%         BDataArray(i, :, 1) = LickBarValues(1, :);
%         BDataArray(i, :, 2 : end) = BurstBars(1, :, :);
%     end
% 
%     % Write to file
%     SheetName = {'Lick Count', 'Burst Count', 'Burst Length', 'Primary Frequency', ...
%                  'Efficient Frequency', 'Burst Effiency', 'Burst Bause'};     
%     for i = 1 : length(SheetName)    
%         DataToExport.DataArray = MDataArray; 
%         for j = 1 : size(BDataArray, 1)
%             for k = 1 : size(BDataArray, 2)
%                 DataToExport.DataArray(j, k+4) = cellstr(num2str(BDataArray(j, k, i)));
%             end
%         end
%         fStruct = struct ('Prefix', allMiceDateCode, 'Name', ['Behavioral_Time_Bins' OutputFileTag], 'Sheet', SheetName(i));
%         TasteUtilities(11, allMiceData.Mouse, allMiceData.Day, DataToExport, fStruct); 
%     end
% end
% 

% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %
% % Export all behavioral data from all bins of multiple mice. Each mouse gets an independent file which
% % is stored under the relevant mouse directory. 
% %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function [] = ExportRawData(FileList, TimeBins, SyncToLick, Mouse, Day)
%     global OutputFileTag;
% 
%     if length(FileList) > 1
%         uiwait(msgbox('Multiple Behavioral .mat file were found. Only one allowed for behavioarl data (all) Export', 'Input Data', 'error', 'modal'));
%     else
%             % Load valid Licking data into global work space
%         [~, DateCode, ~] = TasteUtilities(1, Mouse, Day, [FileList(1).folder '\' FileList(1).name], 1);  
% 
%         LickCounts = BinsAndBursts(2, TimeBins, SyncToLick, []);           % calculate Lick bins
%         Bursts = BinsAndBursts(1, [], [], []);                             % Identify Bursts
%         BurstBins = BinsAndBursts(5, Bursts, TimeBins, SyncToLick);        % Calculate Bursts bins
% 
%         TitleVectorN = 1 : size(LickCounts, 2);
%         TitleVectorS = [];
%         for i = 1 : length(TitleVectorN)
%             TitleVectorS = [TitleVectorS cellstr(['bin-' num2str(TitleVectorN(i))])]; %#ok<AGROW>
%         end
%         DataToExport.Title = TitleVectorS; 
% 
%         % LickCounts
%         DataToExport.DataArray = LickCounts;
%         fStruct = struct ('Prefix', DateCode, 'Name', ['Behavioral_Raw_Data' OutputFileTag], 'Sheet', 'Lick Count');
%         TasteUtilities(11, Mouse, Day, DataToExport, fStruct); 
% 
%         % Burst Data
%         SheetName = {'Burst Count', 'Burst Frequency', 'Burst Length', 'Burst Effiency'};
%         for i = 1 : 4
%             DataToExport.DataArray(1 : size(BurstBins, 1), 1 : size(BurstBins, 2)) = BurstBins(:, :, i); 
%             fStruct = struct ('Prefix', DateCode, 'Name', ['Behavioral_Raw_Data' OutputFileTag], 'Sheet', SheetName(i));
%             TasteUtilities(11, Mouse, Day, DataToExport, fStruct); 
%         end
%     end
% end
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %
% % Export link count per bin - done for for multiple mice. Each mouse gets one line. 
% % The lick counts are accumulated and normelzied 
% % to provide consumption rate over time. File is placed in the upper most relevant
% % directory based on the UI parameters (e.g. if mouse is 'all' file is
% % stored under Experiment directory
% %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function [] = ExportAccumulatedBins(FileList, TimeBins, SyncToLick)
%     global ProjectData OutputFileTag;
% 
%     disp([num2str(length(FileList)) '  Behavioral files found']);
%     if TimeBins == 1
%         TitleVectorN = 1 : ProjectData.BinNum;
%     else
%         TitleVectorN = 1 : 3;
%     end
%     DataArray = cellstr(num2str(zeros(length(FileList), 4 + length(TitleVectorN))));
%     TitleVectorS = [cellstr('Group') cellstr('Mouse') cellstr('Session') cellstr('day')]; 
%     for i = 1 : length(TitleVectorN)
%         TitleVectorS = [TitleVectorS cellstr(['bin-' num2str(TitleVectorN(i))])]; %#ok<AGROW>
%     end
%     DataToExport.Title = TitleVectorS; 
%     allMiceData.Group = 'init';
%     allMiceData.Mouse = 'init';
%     allMiceData.Session = 'init';
%     allMiceData.Day = 'init';
%     allMiceDateCode = 'init';
% 
%     % Process .mat files and Build output data array
%     for i = 1 : length(FileList)
%         Fname = [FileList(i).folder '\' FileList(i).name];
%         disp(['Processing File:  ' Fname]); 
% 
%             % Load valid Licking data into global work space
%         [~, DateCode, ~] = TasteUtilities(1, 0, 0, Fname, 1);        
%         [~, MouseData, ~] = TasteUtilities(12, 0, 0, FileList(i).folder, FileList(i).name);
%         [~, allMiceData, ~] = TasteUtilities(15, 0, 0, allMiceData, MouseData);
%         [~, allMiceDateCode, ~] = TasteUtilities(16, 0, 0, allMiceDateCode, DateCode);
% 
%         LickCounts = BinsAndBursts(2, TimeBins, SyncToLick, []);           % calculate Lick bins
%         PerBinSums = sum(LickCounts, 1);
%         TotalLicks = sum(PerBinSums);
% 
%         DataArray(i, 1) = cellstr(MouseData.Group);
%         DataArray(i, 2) = cellstr(MouseData.Mouse);
%         DataArray(i, 3) = cellstr(MouseData.Session);
%         DataArray(i, 4) = cellstr(MouseData.Day);
% 
%         for j = 1 : length(PerBinSums)
%             DataArray(i, 4 + j) = cellstr(num2str(sum(PerBinSums(1 : j)) / TotalLicks));
%         end
%     end
% 
%     % Export LickCounts to Excel file
%     DataToExport.DataArray = DataArray;
%     fStruct = struct ('Prefix', allMiceDateCode, 'Name', ['Behavioral_Accumulated_Bins' OutputFileTag], 'Sheet', 'Lick Count');
%     TasteUtilities(11, allMiceData.Mouse, allMiceData.Day, DataToExport, fStruct); 
% end
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %
% % Export "binned" ILI distriubution data. every bin corresponed to a range of 
% % ILI values and includes number of lick and average ILI for the bin. 
% %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function [] = ILIDistribution(FileList, TimeBins, Normalize)
%     global ProjectData OutputFileTag ElectricLickingStartTime TasteDeliveryTime;
% 
%     if (ProjectData.MaxLickTime == 0) && (TimeBins == 1)      % Using mouse's maxLickILI for time bin report is not allowed
%         uiwait(msgbox('MaxLickILI cannot be zero if time bins are used', 'User Error', 'error', 'modal'))
%         return;            
%     end
% 
%     binWidth = (ProjectData.MaxLickTime - ProjectData.MinLickTime) / ProjectData.BinNum;
%     DataArray = cellstr(num2str(zeros(length(FileList) * 2, 7 + ProjectData.BinNum)));
%     TitleVectorS = [cellstr('Group') cellstr('Mouse') cellstr('Session') cellstr('day') ...
%                                     cellstr('Cnt/Avr') cellstr('Mod/Std') cellstr('Median')]; 
%     if TimeBins == 1
%         for i = 1 : ProjectData.BinNum
%             binLowBoundry = round((i-1) * binWidth + ProjectData.MinLickTime);
%             binHighBoundry = round(i * binWidth + ProjectData.MinLickTime);
%             TitleVectorS = [TitleVectorS cellstr([num2str(binLowBoundry) '-' num2str(binHighBoundry)])]; %#ok<AGROW>
%         end
%         fileSuffix = '_bins';
%     else
%         TitleVectorS = [TitleVectorS cellstr('min-Primary') cellstr('Primary-Burst') cellstr('burst-max')];
%         fileSuffix = '_functions';
%     end
% 
%     DataToExport.Title = TitleVectorS; 
%     allMiceData.Group = 'init';
%     allMiceData.Mouse = 'init';
%     allMiceData.Session = 'init';
%     allMiceData.Day = 'init';
%     allMiceDateCode = 'init';
% 
%     % Process .mat files and Build output data array
%     disp([num2str(length(FileList)) '  Behavioral files found']);
%     for i = 1 : length(FileList)
%         Fname = [FileList(i).folder '\' FileList(i).name];
%         disp(['Processing File:  ' Fname]); 
% 
%         % Load valid Licking data into global work space
%         [~, DateCode, ~] = TasteUtilities(1, 0, 0, Fname, 1);        
%         [~, MouseData, ~] = TasteUtilities(12, 0, 0, FileList(i).folder, FileList(i).name);
%         [~, allMiceData, ~] = TasteUtilities(15, 0, 0, allMiceData, MouseData);
%         [~, allMiceDateCode, ~] = TasteUtilities(16, 0, 0, allMiceDateCode, DateCode);
% 
%         % Generate ILI set - Select start times based on required session type and Start/End times          
%         ILI = [];
%         for TrialNumber = 1 : length(TasteDeliveryTime)
%             LickTimes = find(ElectricLickingStartTime > (TasteDeliveryTime(TrialNumber) + ProjectData.StartTime) & ...
%                              ElectricLickingStartTime < (TasteDeliveryTime(TrialNumber) + ProjectData.EndTime));                  
%             SelectedStarts = ElectricLickingStartTime(LickTimes); %#ok<FNDSB>
% 
%             % Build ILI vector of all values within allowed range
%             ILI = [ILI diff(SelectedStarts)]; %#ok<AGROW>
%         end
% 
%         % Filter ILI vector by max values. Sort to bins.
%         ILI = ILI * 1000;                   % convert time scale to milliSec
%         if ProjectData.MaxLickTime > 0      % use user defined maxLickILI
%             ILI = ILI(ILI < ProjectData.MaxLickTime);
%             maxILI = ProjectData.MaxLickTime;
%         else
%             maxILI = max(ILI) + 1;              % use maximum ILI from recorded file 
%         end
% 
%         ILICount = zeros(ProjectData.BinNum, 1);
%         ILISum = zeros(ProjectData.BinNum, 1);
%         if TimeBins == 1
%             for j = 1 : length(ILI)
%                 bin = floor((ILI(j) - ProjectData.MinLickTime) / binWidth);
%                 ILICount(1 + bin) = ILICount(1 + bin) + 1;
%                 ILISum(1 + bin) = ILISum(1 + bin) + ILI(j);
%             end
%         else
%             functionalBins = [ProjectData.MaxPrimaryILI ProjectData.MaxBurstILI maxILI];
%             for j = 1 : length(ILI)
%                 bin = find(functionalBins > ILI(j), 1);
%                 ILICount(bin) = ILICount(bin) + 1;
%                 ILISum(bin) = ILISum(bin) + ILI(j);
%             end
%         end
% 
%         TotalLicks = 1;
%         if Normalize == 1  % export lick count as percemtage per bin rather then absolute numbers
%             TotalLicks = sum(ILICount);        
%         end
% 
%         % populate file data structures
%         MiceOffset = length(FileList);
%         DataArray(i, 1) = cellstr(MouseData.Group);
%         DataArray(i, 2) = cellstr(MouseData.Mouse);
%         DataArray(i, 3) = cellstr(MouseData.Session);
%         DataArray(i, 4) = cellstr(MouseData.Day); 
%         DataArray(i, 5) = cellstr(num2str(length(ILI))); 
%         DataArray(i, 6) = cellstr(num2str(mode(ILI))); 
%         DataArray(i, 7) = cellstr(num2str(median(ILI))); 
%         DataArray(i + MiceOffset, 1) = cellstr(MouseData.Group);
%         DataArray(i + MiceOffset, 2) = cellstr(MouseData.Mouse);
%         DataArray(i + MiceOffset, 3) = cellstr(MouseData.Session);
%         DataArray(i + MiceOffset, 4) = cellstr(MouseData.Day); 
%         DataArray(i + MiceOffset, 5) = cellstr(num2str(mean(ILI))); 
%         DataArray(i + MiceOffset, 6) = cellstr(num2str(std(ILI))); 
%         for j = 1 : length(ILICount)
%             DataArray(i, 7 + j) = cellstr(num2str(ILICount(j) / TotalLicks));
%             if ILICount(j) == 0
%                 DataArray(i + MiceOffset, 7 + j) = cellstr(' ');
%             else
%                 DataArray(i + MiceOffset, 7 + j) = cellstr(num2str(ILISum(j) / ILICount(j)));
%             end
%         end
%     end
% 
%     % Export LickCounts to Excel file
%     DataToExport.DataArray = DataArray;
%     fStruct = struct ('Prefix', allMiceDateCode, 'Name', ['ILI_Distribution' fileSuffix OutputFileTag], 'Sheet', 'ILI Distribution');
%     TasteUtilities(11, allMiceData.Mouse, allMiceData.Day, DataToExport, fStruct); 
% end
