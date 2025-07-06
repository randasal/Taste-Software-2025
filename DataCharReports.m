%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% A Static class containing a collection of methods generating data characterization reports.
%
% Version History:
%   1.00 - First release
%   1.10 - added function MaxBurstILI()
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef DataCharReports

    methods (Static, Access = public)

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % plots a histogram of ILI 
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [] = ILIDistribution(ProjectDirectory, ProjectData, Mouse, Day, Normalize)
            if DataCharReports.SWVersionError()
                return;
            end
        
            ILI = DataCharReports.GetAllILI(ProjectDirectory, ProjectData, Mouse, Day);
            
            % Filter ILI vector by max values.
            ILI = ILI * 1000;            % convert time scale to milliSec
            if ProjectData.MaxLickTime > 0
                ILI = ILI(ILI <= ProjectData.MaxLickTime);
            end   

            % plot
            PrimaryILI = ILI(ILI <= ProjectData.MaxPrimaryILI);

            Title1 = {['ILI Distribution Histogram; Primary ILI = ' num2str(ProjectData.MaxPrimaryILI) 'ms']};
            Title2 = {['Group: ' ProjectData.MouseGroupName ', Session: ' ProjectData.SessionName ...
                       ', Mouse: ' Mouse ', Day: ' Day]}; 
            DataCharReports.HPlot(ProjectData, ILI, PrimaryILI, Normalize, Title1, Title2); 
            if ProjectData.YLim ~= 0
                ylim([0 ProjectData.YLim]);
            end
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Finds optimized max ILI by curve fitting and shmuiing 
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [] = MaxBurstILI(ProjectDirectory, ProjectData, Mouse, Day, Normalize)
            if DataCharReports.SWVersionError()
                return;
            end

            ILI = DataCharReports.GetAllILI(ProjectDirectory, ProjectData, Mouse, Day);
            ILI = ILI * 1000;            % convert time scale to milliSec
            PrimaryILI = ILI(ILI <= ProjectData.MaxPrimaryILI);

            Title1 = {['ILI Distribution Histogram; Primary ILI = ' num2str(ProjectData.MaxPrimaryILI) 'ms']};
            Title2 = {['Group: ' ProjectData.MouseGroupName ', Session: ' ProjectData.SessionName ...
                       ', Mouse: ' Mouse ', Day: ' Day]}; 
            xTicks = DataCharReports.HPlot(ProjectData, ILI, PrimaryILI, 1, Title1, Title2); 
            if ProjectData.YLim ~= 0
                ylim([0 ProjectData.YLim]);
            end

            numComponents = 3; % assume 2 Gaussians (adjust based on visualization)
            gmmModel = fitgmdist(ILI, numComponents); % Fit GMM
            x = xTicks.';
            pdf_vals = pdf(gmmModel, x); % Compute PDF values from GMM
            hold on;
            plot(xTicks, pdf_vals, 'r', 'LineWidth', 2); % Plot fitted GMM
            hold off;
       
        %---
        
        %Check where the GMM’s probability density drops significantly.
        %Alternatively, cluster the data using the fitted GMM:
        %idx = cluster(gmmModel, data); % Assign each data point to a Gaussian component
        %scatter(data, zeros(size(data)), 30, idx, 'filled'); % Visualize clusters        
       
        %---
        
        %  Alternative: Model Selection for Optimal Components
        % If you're unsure about the number of Gaussian components, you can use the 
        % Bayesian Information Criterion (BIC) to select the best model:

        % BIC = zeros(1, 5);
        % for k = 1:5  % Test 1 to 5 Gaussian components
        %     gmm = fitgmdist(data, k);
        %     BIC(k) = gmm.BIC;
        % end
        % plot(1:5, BIC, '-o');
        % xlabel('Number of Gaussian Components');
        % ylabel('BIC Value');
        % title('Selecting the Best Number of Gaussians');

        % The lowest BIC value suggests the best number of Gaussian distributions.
        % Once you’ve identified the Gaussian components, you can analyze their mean 
        % and variance. The boundary is likely at the rightmost tail of the last Gaussian before randomness begins.

        end
    end % public methods

    methods (Static, Access = private)

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        % Verify SW version
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [status] = SWVersionError()
            status = (FileUtilities.VerifySWVersion('DataCharReports', '1.10') == 1);     % version error
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Plot Histogram for a given vector. Add Average and STD markers.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [BarLocations] = HPlot(ProjectData, Vector, PrimaryVector, Normalize, Text1, Text2)
        
            % Calculate properties for the histogram
            Average = mean(PrimaryVector);
            STD = std(PrimaryVector, 1);
            %SortedVector = sort(Vector);
            %LowAlpha = SortedVector(round(length(Vector) * 0.05));
            %HighAlpha = SortedVector(round(length(Vector) * 0.95));
        
            % Plot
            figure();    
            if ProjectData.MaxLickTime == 0
                maxLick = max(Vector);
            else
                maxLick = ProjectData.MaxLickTime;
            end
            BinWidth = (maxLick - ProjectData.MinLickTime) / ProjectData.BinNum;
            EdgesVector = ProjectData.MinLickTime : BinWidth : maxLick;
            [ILICounts, ~] = histcounts(Vector, EdgesVector);
            if Normalize == 1
                ILICounts = ILICounts / sum(ILICounts);  % normalize counts to percentage of total
            end
            BarLocations = ProjectData.MinLickTime + BinWidth / 2 : BinWidth : maxLick - BinWidth / 2;
            bar(BarLocations, ILICounts);
            xticks(BarLocations);
            xtickangle(45);
        
            Text3 = {['Total Number of ILIs ploted: ' num2str(length(Vector))]}; 
            title([ Text1 ; Text2 ; Text3]);
        
            ylabel('ILI counts / Duration ');
            xlabel('ILI values Range [MilliSeconds]');
        
            % get current y axis limit
            yLimits = ylim();
        
            % Plot Marker lines
            line([Average Average], [0 yLimits(2) * 0.9], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '--');
            line([Average - STD Average - STD], [0 yLimits(2) * 0.8], 'Color', 'r', 'lineWidth', 1, 'LineStyle', '--');
            line([Average + STD Average + STD], [0 yLimits(2) * 0.8], 'Color', 'r', 'lineWidth', 1, 'LineStyle', '--');
            %line([LowAlpha LowAlpha], [0 yLimits(2) * 0.7], 'Color', 'r', 'lineWidth', 1, 'LineStyle', '--');
            %line([HighAlpha HighAlpha], [0 yLimits(2) * 0.7], 'Color', 'r', 'lineWidth', 1, 'LineStyle', '--');
        
            % print properties text
            text(Average, yLimits(2) * 0.95, ['Av. = ', num2str(round(Average))], 'FontSize', 12);  
            text(Average + STD, yLimits(2) * 0.85, ['+Std. = ', num2str(round(Average + STD))], 'FontSize', 12); 
            text(Average - STD, yLimits(2) * 0.85, ['-Std. = ', num2str(round(Average - STD))], 'FontSize', 12, 'HorizontalAlignment', 'right'); 
            %text(HighAlpha, yLimits(2) * 0.75, ['H. Alph. = ', num2str(round(HighAlpha))], 'FontSize', 12); 
            %text(LowAlpha, yLimits(2) * 0.75, ['L. Alph. = ', num2str(round(LowAlpha))], 'FontSize', 12, 'HorizontalAlignment', 'right'); 
        
            % save charted data to a temp xls file. fname = 'latestrun'
            writematrix([BarLocations; ILICounts], 'Latest Run.csv');
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % plots a histogram of ILI 
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [ILI] = GetAllILI(ProjectDirectory, ProjectData, Mouse, Day)
            ILI = [];

            [Status, FileList1, FileList2] = FileUtilities.GetFileLists(ProjectDirectory, ProjectData.MouseGroupName, ProjectData.SessionName, Mouse, Day);
            if Status ~= 0 
                return 
            end
            
            %%%% Load behavioral Data from a '*.mat' file
            FileList = [FileList1; FileList2];

            disp([num2str(length(FileList)) '  Behavioral files found']);

            for i = 1 : length(FileList)
                fName = [FileList(i).folder '\' FileList(i).name];
                lickingData = LickingDataObject(ProjectData, fName, 1); 
                disp(['Processing File:  ' fName]); 
                ILI = [ILI; diff(lickingData.LickingStartTime)]; %#ok<AGROW> 
            end
        end

    end  % Static private  Methods
end % class





% Old code. It will go away eventually.


% 
%         case 2       % Water Consumption
%                 WaterConsumption(FileList, list1Length, Mouse, Day)
% 
%         case 3       % Burst Length histogram
%                 BurstLengthDistribution(FileList, Mouse, Day);
% 
%         case 4       % Burst efficiency matrix
%                 BurstEfficiencyMatrix(FileList, Mouse, Day);
%     end
% end
% 

% 
% function [] = BurstEfficiencyMatrix(FileList, Mouse, Day)
%     global ProjectData 
% 
%     % Init
%     Bursts  = [];
%     [~, ~, SetBoundries] = TasteUtilities(9, [], [], true, []);  % Defines the boundries for the session sets
% 
%     %%%% Load behavioral Data from a '*.mat' file
%     disp([num2str(length(FileList)) '  Behavioral files found']);
% 
%     for i = 1 : length(FileList)
%         Fname = [FileList(i).folder '\' FileList(i).name];
%         [~, DateCode, ~] = TasteUtilities(1, Mouse, Day, Fname, 1);  
%         disp(['Processing File:  ' Fname]); 
% 
%         Bursts = [Bursts BinsAndBursts(1, [], [], [])]; %#ok<AGROW>
%     end
% 
%     CorrelationPlot([Bursts.Length], [Bursts.Efficiency], Mouse, Day, 'Efficiency');
%     CorrelationPlot([Bursts.Length], [Bursts.EffectiveFrequency], Mouse, Day, 'EffectiveFrequency');
%     CorrelationPlot([Bursts.Length], [Bursts.PrimaryFrequency], Mouse, Day, 'PrimaryFrequency');
% 
%     % save charted data to a temp xls file. fname = 'latestrun'
%     writematrix([[Bursts.Length]; [Bursts.Efficiency]; [Bursts.EffectiveFrequency]; [Bursts.PrimaryFrequency]], 'Latest Run.csv');
% 
% end
% 
% function [] = CorrelationPlot(Length, Attribute, Mouse, Day, plotTitle)
%     global ProjectData 
% 
%     figure();
%     scatter(Length, Attribute);
% 
%     Title1 = {['Burst length/' plotTitle 'Correlation plot']};
%     Title2 = {['Experiment: ' ProjectData.ExperimentName ', Session: ' ProjectData.SessionName ...
%                ', Mouse: ' Mouse ', Day: ' Day]}; 
%     Title3 = {['Total Number of Bursts ploted: ' num2str(length(Length))]}; 
%     title([ Title1; Title2; Title3]);
% 
%     ylabel(plotTitle);
%     xlabel('Burst Length [ILI]');
% 
%     [R, P] = corrcoef(Length, Attribute);
%     xLimits = xlim();
%     yLimits = ylim();
%     xCoord = xLimits(1) + (xLimits(2) - xLimits(1)) * 0.5;
%     yCoord1 = yLimits(1) + (yLimits(2) - yLimits(1)) * 0.2;
%     yCoord2 = yLimits(1) + (yLimits(2) - yLimits(1)) * 0.1;
% 
%     text(xCoord, yCoord1, ['Corr. Coef.: ', num2str(R(1,2))], 'FontSize', 12);  
%     text(xCoord, yCoord2, ['    P Value: ', num2str(P(1,2))], 'FontSize', 12);  
% end
% 



% function [] = WaterConsumption(FileList, List1Length, Mouse, Day)
%     global ProjectData 
% 
%     %constants
%     TimeBins = 1;
%     SyncToLick = 1;
% 
%     figure();
%     hold on;
%     percentAverageVector1 = zeros(ProjectData.BinNum, 1);
%     percentAverageVector2 = zeros(ProjectData.BinNum, 1);
%     timeVector = zeros(ProjectData.BinNum, 1);
%     for i = 1 : ProjectData.BinNum
%         timeVector(i) = i * (ProjectData.EndTime - ProjectData.StartTime) / ProjectData.BinNum;
%     end
%     dataarray = timeVector;
% 
%     % Process and plot .mat files 
%     for i = 1 : length(FileList)
%         Fname = [FileList(i).folder '\' FileList(i).name];
%         [~, DateCode, ~] = TasteUtilities(1, Mouse, Day, Fname, 1);  % Load behavioral data
%         disp(['Processing File:  ' Fname]); 
%         percentileVector = zeros(ProjectData.BinNum, 1);
% 
%         LickCounts = BinsAndBursts(2, TimeBins, SyncToLick, []);           % calculate Lick bins
%         PerBinSums = sum(LickCounts, 1);
%         TotalLicks = sum(PerBinSums);
%         for j = 1 : length(PerBinSums)
%             percentileVector(j) = sum(PerBinSums(1 : j)) / TotalLicks * 100; % percentage
%         end
% 
%         plot(timeVector, percentileVector, 'color', 'b');
%         dataarray = [dataarray, percentileVector]; %#ok<AGROW>
%         if i > List1Length
%             percentAverageVector2 = percentAverageVector2 + percentileVector;
%         else
%             percentAverageVector1 = percentAverageVector1 + percentileVector;
%         end
%     end
% 
% 
% 
%     if length(FileList) > List1Length
%         percentAverageVector1 = percentAverageVector1 / List1Length;
%         plot(timeVector, percentAverageVector1, 'color', 'r', 'linewidth', 2);
%         dataarray = [dataarray, percentAverageVector1];
%         percentAverageVector2 = percentAverageVector2 / (length(FileList) - List1Length);
%         plot(timeVector, percentAverageVector2, 'color', 'g', 'linewidth', 2);
%         dataarray = [dataarray, percentAverageVector2];
%     else
%         percentAverageVector1 = percentAverageVector1 / length(FileList);
%         plot(timeVector, percentAverageVector1, 'color', 'r', 'linewidth', 2);
%         dataarray = [dataarray, percentAverageVector1];
%     end
% 
%     ylabel('Percentage of consumption ');
%     xlabel('Session Time [Seconds]');
% 
%     text1 = {'Accumulated Liquide Consumption'}; 
%     text2 = {['Experiment: ' ProjectData.ExperimentName ',     Session: ' ProjectData.SessionName ...
%                ',     Mouse: ' Mouse ',     Day: ' Day]}; 
%     text3 = {['Total Number of sessions ploted: ' num2str(length(FileList))]}; 
%     title([ text1 ; text2 ; text3]);
% 
%     hold off;    
% 
%     % save charted data to a temp xls file. fname = 'latestrun'
%     xlswrite('latestrun', dataarray, 'Water Consumption');
% end
% 
