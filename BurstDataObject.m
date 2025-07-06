%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% A Burst data object holds all bursts recorded in one session. 
% The constructor creates an array of bursts from a licking data object. 
%
% Version History:
%   1.00 - First release
%   1.10 - Changed the burst analysys algorithm. Burst length is now (ILI + 1)
%          Added a list of rogue lickes with start times.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef BurstDataObject

    properties (Access = public)
        StartTime, 
        EndTime,
        Length,
        PrimaryFrequency,
        EffectiveFrequency,
        Efficiency,
        Pause,
        RogueLicks
    end

    methods (Access = public)

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Class constructor. Creates an array of the session bursts
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = BurstDataObject(LickingDataObject, ProjectData)
            if FileUtilities.VerifySWVersion('BurstDataObject', '1.10') == 1     % version error
               return;
            end
            ILI = diff(LickingDataObject.LickingStartTime);
        
            obj.StartTime = []; 
            obj.EndTime = [];
            obj.Length = [];
            obj.PrimaryFrequency = [];
            obj.EffectiveFrequency = [];
            obj.Efficiency = [];
            obj.Pause = [];
            obj.RogueLicks = [];

            BurstPrimaryILIs = [];
            BurstOtherILIs = [];
        
            for i = 1 : length(ILI)
                if ILI(i) > ProjectData.MaxBurstILI / 1000                          % Start New Burst
                    if length(BurstPrimaryILIs) + length(BurstOtherILIs) >= ProjectData.MinILIPerBurst % A previous Valid burst found. Store it.
                        obj = obj.PackBurst(BurstStart, BurstEnd, BurstPrimaryILIs, BurstOtherILIs, ILI(i));  
                    else
                        obj = obj.PackRogueLicks(length(BurstPrimaryILIs) + length(BurstOtherILIs), LickingDataObject.LickingStartTime, i);
                    end
                    BurstPrimaryILIs = [];
                    BurstOtherILIs = [];
                else                                       % add ILI to current burst
                    if ILI(i) > ProjectData.MaxPrimaryILI / 1000    % This is not a primary ILI, add to OtherILI list.
                        BurstOtherILIs = [BurstOtherILIs ILI(i)]; %#ok<AGROW>
                    else
                        BurstPrimaryILIs = [BurstPrimaryILIs ILI(i)];   %#ok<AGROW> % within Frequency range, Add to primary ILI list.
                    end
                    if length(BurstPrimaryILIs) + length(BurstOtherILIs) == 1  % this is first ILI. Set Burst Start Time;
                        BurstStart = LickingDataObject.LickingStartTime(i);
                    else
                        BurstEnd = LickingDataObject.LickingStartTime(i + 1);
                    end        
                end                
            end
    
            % The case when the .mat file end cuts an ongoing burst
            if length(BurstPrimaryILIs) + length(BurstOtherILIs) >= ProjectData.MinILIPerBurst        % A previous Valid burst found. Store it.
                obj = obj.PackBurst(BurstStart, BurstEnd, BurstPrimaryILIs, BurstOtherILIs, 0);         
            else
                obj = obj.PackRogueLicks(length(BurstPrimaryILIs) + length(BurstOtherILIs), LickingDataObject.LickingStartTime, length(LickingDataObject.LickingStartTime));
            end    
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Devides the session bursts into groups and returns a wighted group avarege
        % The sorting is inclusive. A burst will be included in a bin if it starts 
        % before the bin ends and (even if it) ends after the bin started. 
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function BurstBins = CalculateBinAverages(obj, BinsStartTime)
            binNum = length(BinsStartTime);
            BinAverages = zeros(binNum, 8);
            WeightedAverage = 1;  % compile flag: set to 1 for weighted average, 0 for algebric 
            
            for j = 1 : binNum
                PrimaryFrequencyArray = [];
                EffectiveFrequencyArray = [];
                LengthArray = [];
                EfficiencyArray = [];
	            PausesArray = [];

                WeightsArray = [];
                if j < binNum
                    BinEndTime = BinsStartTime(j + 1);
                elseif obj.EndTime(end) > obj.RogueLicks(end)
                    BinEndTime = obj.EndTime(end);          % the end of the Bin lick is greater of 
                else                                        % the end of the last burst or the last Rogue Lick
                    BinEndTime = obj.RogueLicks(end) + 1;   % to make sure that if the last lick is a rogue one it
                end                                         % will be inlcuded (bins include the start time and exclude the ned)

                for i = 1 : length(obj.StartTime)
                    if obj.StartTime(i) >= BinsStartTime(j) && obj.StartTime(i) < BinEndTime 
                        
                        if WeightedAverage == 0
                            AverageWeightFactor = 1;
                        else
                            AverageWeightFactor = obj.Length(i);
                        end
                            
                        PrimaryFrequencyArray = [PrimaryFrequencyArray obj.PrimaryFrequency(i) * AverageWeightFactor]; %#ok<AGROW>
                        EffectiveFrequencyArray = [EffectiveFrequencyArray obj.EffectiveFrequency(i) * AverageWeightFactor]; %#ok<AGROW>
		                LengthArray = [LengthArray obj.Length(i)]; %#ok<AGROW>
                        EfficiencyArray = [EfficiencyArray obj.Efficiency(i) * AverageWeightFactor]; %#ok<AGROW>
                        PausesArray = [PausesArray obj.Pause(i)];  %#ok<AGROW>
                        WeightsArray = [WeightsArray AverageWeightFactor];  %#ok<AGROW>
                    end
                end
     
                BurstCount = length(PrimaryFrequencyArray); % No bursts in this bin (could have checked any other array, they all have same length)
                LickCount = sum(LengthArray);
                RougeLicks = obj.RogueLicks((obj.RogueLicks >= BinsStartTime(j)) & (obj.RogueLicks < BinEndTime)); 
                RougeLicksCount = length(RougeLicks);

                if BurstCount == 0    
                    Burstlength = 0;
                    primaryFrequency = 0;
                    effectiveFrequency = 0;
                    efficiency = 0; 
                    pause = 0;
                else
                    Burstlength = mean(LengthArray);
            
                    if isempty(PrimaryFrequencyArray(PrimaryFrequencyArray ~= 0))
                        primaryFrequency = 0;
                    else
                        primaryFrequency = sum(PrimaryFrequencyArray(PrimaryFrequencyArray ~= 0)) / sum(WeightsArray(PrimaryFrequencyArray ~= 0));
                    end
                
                    if isempty(EffectiveFrequencyArray(EffectiveFrequencyArray ~= 0))
                        effectiveFrequency = 0;
                    else
                        effectiveFrequency = sum(EffectiveFrequencyArray(EffectiveFrequencyArray ~= 0)) / sum(WeightsArray(EffectiveFrequencyArray ~= 0));
                    end
                    
                    efficiency = sum(EfficiencyArray) / sum(WeightsArray); 
                    pause = mean(PausesArray(PausesArray ~= 0));
                end

                BinAverages(j, :) = [LickCount, BurstCount, Burstlength, primaryFrequency, effectiveFrequency, efficiency, pause, RougeLicksCount];    
            end
            BurstBins = BinAverages;
        end
    end   % public Methods

    methods (Access = private)

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Calculates burests parameters and packs data in struct)
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [obj] = PackBurst(obj, BurstStart, BurstEnd, BurstPrimaryILIs, BurstOtherILIs, BurstPause) 
            if isempty(BurstPrimaryILIs)
                PFrequency = 0;
            else
                PFrequency = 1 / mean(BurstPrimaryILIs);
            end
                
            if isempty(BurstOtherILIs)
                EFrequency = PFrequency;
            else
                EFrequency = 1 / mean([BurstPrimaryILIs BurstOtherILIs]);
            end
            
            obj.StartTime = [obj.StartTime, BurstStart];
            obj.EndTime = [obj.EndTime, BurstEnd];
            obj.Length = [obj.Length, length(BurstPrimaryILIs) + length(BurstOtherILIs) + 1];
            obj.PrimaryFrequency = [obj.PrimaryFrequency, PFrequency];
            obj.EffectiveFrequency = [obj.EffectiveFrequency, EFrequency];               
            obj.Efficiency = [obj.Efficiency, length(BurstPrimaryILIs) / (length(BurstPrimaryILIs) + length(BurstOtherILIs)) * 10];  % efficiency is scaled to 0:10
            obj.Pause = [obj.Pause, BurstPause]; 
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % packs rouge Licks data in struct)
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [obj] = PackRogueLicks(obj, NumOfILI, LickStartTime, LastILIIndex)
            for i = LastILIIndex - NumOfILI : LastILIIndex
                obj.RogueLicks = [obj.RogueLicks LickStartTime(i)];
            end
        end
    end
end
