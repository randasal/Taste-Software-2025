classdef TasteSWVersionEdit
    methods (Static)
        function Status = TasteSWVersionEdit()
            SWVersion(1).Name = 'TasteAnalysisSW';
            SWVersion(1).Version = '1.40';
            SWVersion(2).Name = 'FileUtilities';
            SWVersion(2).Version = '1.40';
            SWVersion(3).Name = 'DataUtilities';
            SWVersion(3).Version = '1.00';
            SWVersion(4).Name = 'MiceListEditor';
            SWVersion(4).Version = '1.10';
            SWVersion(5).Name = 'ActivityRasters';
            SWVersion(5).Version = '1.31';
            SWVersion(6).Name = 'LickingDataObject';
            SWVersion(6).Version = '1.10';
            SWVersion(7).Name = 'BurstDataObject';
            SWVersion(7).Version = '1.10';
            SWVersion(8).Name = 'TasteExtractData';
            SWVersion(8).Version = '1.20';
            SWVersion(9).Name = 'ExtractBehavioralData';
            SWVersion(9).Version = '1.00';
            SWVersion(10).Name = 'ExportData';
            SWVersion(10).Version = '1.10';
            SWVersion(11).Name = 'DataCharReports';
            SWVersion(11).Version = '1.10';

            save('TasteSWVersions', 'SWVersion');
        end
    end
end
                 
