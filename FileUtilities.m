%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% A Static class containing a collection of file related static utility methods (e.g. create, save, 
% load, verify, search, etc.) 
% 
% Version History:
%   1.00 - First release
%   1.10 - GetFileList expanded to handle two lists (where either mouse or day is set to 'list' in GUI).
%          ExperimentName replaced with MouseGroupName. Some minor bug fixes. 
%          GetRecordedDataDirectory method added.
%   1.20 - Added system configuration info to the project data file
%   1.30 - Generilize mouse data and, write excel file functions added. Bug Fixes
%   1.40 - Added function to resize the width of the outout matrix
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 classdef FileUtilities

    methods (Static)

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Verify the SW version of calling module against the current version register.  
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [Status] = VerifySWVersion(Name, Version)   
            if exist('TasteSWVersions.mat', 'file') ~= 2
                uiwait(msgbox('TasteSWVersions file is missing. Please update', 'SW Version Error', 'error', 'modal'))
                Status = 1;
            else
                load('TasteSWVersions.mat', 'SWVersion');

                % Verify the FileUtilies version
                Status = 1;
                for i = 1 : length(SWVersion) 
                    if strcmp(SWVersion(i).Name, 'FileUtilities') && strcmp(SWVersion(i).Version, '1.40')
                        Status = 0;
                        break;
                    end
                end

                if Status ~= 0
                    uiwait(msgbox('FileUtilities is outdated, please update', 'SW Version Error', 'error', 'modal'));
                else
                    % Verify the calling module version
                    Status = 1;
                    for i = 1 : length(SWVersion) 
                        if strcmp(SWVersion(i).Name, Name) && strcmp(SWVersion(i).Version, Version)
                            Status = 0;
                            break;
                        end
                    end

                    if Status ~= 0
                        uiwait(msgbox(convertCharsToStrings(Name) + ' is outdated, please update', 'SW Version Error', 'error', 'modal'));
                    end
                end
            end
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Verify existence and load the project directory file. Verify existance of project directory.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [ProjectDirectory] = LoadProjectDirectory()
            if exist('TasteProjectDirectory.mat', 'file') == 2
                load('TasteProjectDirectory', 'ProjectDirectory');
                if ~(exist(ProjectDirectory, 'dir') == 7)
                    uiwait(msgbox('Project Directory does not exist', 'Project Directory Warning', 'warn', 'modal'));
                    ProjectDirectory = [];    
                end
            else
                uiwait(msgbox('TasteProjectDirectory.mat file is missing.', 'Project Directory Warning', 'warn', 'modal'));
                ProjectDirectory = [];    
            end
        end    

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Select a project directory and set the global ProjectDirectory vatuable
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [ProjectDirectory] = SelectProjectDirectory()

            ProjectDirectory = uigetdir();
        
            if ProjectDirectory == 0
                uiwait(msgbox('Taste Project Directory was not selected', 'Project Directory Warning', 'warn', 'modal'))
                ProjectDirectory = [];
            else
                save('TasteProjectDirectory', 'ProjectDirectory');
            end
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Check existence of Project Data file and, if exists, load the data to global variable.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [ProjectData] = LoadProjectData(ProjectDirectory)

            if exist([ProjectDirectory, '\ProjectSystemData.mat'], 'file') == 2
                load([ProjectDirectory, '\ProjectSystemData'], 'ProjectData');        

                if isfield(ProjectData, 'FileVersion') 
                    if ~strcmp(ProjectData.FileVersion, '7.10')
                        ProjectData = [];
                    end
                else
                    ProjectData = [];                    
                end

            else
                ProjectData = [];                    
            end
            
            if isempty(ProjectData)     % issues with the file create an empty one
                button = questdlg('Project data file missing or outdated. Create?', 'Project Data File');
                if strcmp(button, 'Yes')

                    % this is still using the old format (from the drops system) just for compatibility.
                    % So half of the fields are not used and the names might be somewhat archaic

                    ProjectData = struct('FileVersion', '7.10', 'MinLickTime', 0, 'MaxLickTime', 0, ...
                                 'MaxPrimaryILI', 0, 'MaxBurstILI', 0, 'MinILIPerBurst', 0, 'StartTime', 0, 'EndTime', 0, ...
                                 'SessionName', [], 'MouseGroupName', [], 'BinNum', 1, 'YLim', 0, 'RecordingSystem', 'TDT', ...
                                 'TDTPort', 'Port C', 'ExtractBehavioral', 1, 'Lickometer1', 1, 'Licokmeter2', 0, ...
                                 'ExtractNeuronal', 1);
                    FileUtilities.SaveProjectData(ProjectDirectory, ProjectData);
                end
            end 
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Save Project Data to Project data file 
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function SaveProjectData(ProjectDirectory, ProjectData)         
            save([ProjectDirectory, '\ProjectSystemData'], 'ProjectData');
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        % Uses a file selection dialog to select a file name, then extracts the
        % session name from the file name
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [SessionName] = SelectSessionName(ProjectDirectory, MosueGroupName)
            [fileName, filePath] = uigetfile(cellstr([ProjectDirectory '\' MosueGroupName '\*.*'])); 
              
            SessionName = [];

            if ischar(fileName)
                [MouseData] = FileUtilities.ExtractMouseID(ProjectDirectory, filePath, fileName);
                SessionName = MouseData.Session;
            end
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Verify existence and load the MouseGroup directory (as defined in the project directory file 
        % and project date file. 
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [MouseGroupDirectory] = LoadMouseGroupDirectory()
            projectDirectory = FileUtilities.LoadProjectDirectory();
            MouseGroupDirectory = [];    

            if ~isempty(projectDirectory)
                projectData = FileUtilities.LoadProjectData(projectDirectory);    
                if ~isempty(projectData)
                    MouseGroupDirectory = [projectDirectory '\' projectData.MouseGroupName]; 
                    if ~(exist(MouseGroupDirectory, 'dir') == 7)
                        uiwait(msgbox('MouseGroup Directory does not exist', 'Directory Warning', 'warn', 'modal')); 
                        MouseGroupDirectory = [];
                    end
                end 
            end
        end


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Verify existence and retrun the path to the requested recorded data directory 
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [RecordedDataDirectory] = GetRecordedDataDirectory(ProjectDirectory, MouseGroup, Mouse, Session, Day, FileExtention)
         
            FileMask = [ProjectDirectory, '\', MouseGroup, '\Mouse', Mouse, '\Recorded Data\*_', ...
                        Session, '_Day', Day];
            RecordedDataDirectory = [];
            FileList = dir (FileMask);
            
            if isempty(FileList) 
                uiwait(msgbox('Recorded data directory not found', 'Input Data', 'error', 'modal'));
                return;
            end
            
            if length(FileList) > 1 
                uiwait(msgbox('Multiple files or directories match the selected session', 'Input Data', 'error', 'modal'));
                return;
            end
            
            if FileList(1).isdir ~= 1 
                uiwait(msgbox('The selected file is not a directory', 'Input Data', 'error', 'modal'));
                return;
            else   
                FileMask = [FileList(1).folder '\' FileList(1).name '\*.' FileExtention];
                FileList = dir (FileMask);                
                if isempty(FileList)
                    ErrorText = ['Recorded data directory does not contain ' FileExtention ' files'];
                    uiwait(msgbox(ErrorText, 'Input Data', 'error', 'modal'));
                    return;
                end
            end

            RecordedDataDirectory = FileList(1).folder;
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Writes Current figure to a file in the 'Analysis Result" directory of
        % the Specified mouse. The inout arguments are used to locate the directory
        % and set file name.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [] = WriteFigureFile(ProjectDirectory, ProjectData, Mouse, Day, Directory, Prefix, outfiletag)
            [Fname] = FileUtilities.LocateOutfileDir(ProjectData, Mouse, 'Analysis Results'); 
        
            if FileUtilities.CheckDir(ProjectDirectory, Fname) == 1                % Analysis Results directory missing
                return;
            end
            
            Fname = [Fname '\' Directory];
            if FileUtilities.CheckDir(ProjectDirectory, Fname) == 1                % Specific Results directory missing
                return;
            end
            
            Fname = [ProjectDirectory, '\', Fname, '\', Prefix, '_', ProjectData.SessionName, '_Day', Day, outfiletag];
            
            set(gcf, 'PaperUnits', 'inches', 'PaperSize', [6,6], 'PaperPosition', [0 0 6 6]);
            print(gcf, '-dpng', '-r100', strcat(Fname,'.png'));
            savefig(strcat(Fname,'.fig'));
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % create a date code compatible with a list of files. namely, changes it to '000000' 
        % if not all of the files are from the same date.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [DateCode] = GeneralizeFileDateCode(allFilesDateCode, thisFileDateCode)
            if strcmp(allFilesDateCode, 'firstfile') == 1
                allFilesDateCode = thisFileDateCode;
            elseif strcmp(allFilesDateCode, thisFileDateCode) == 0
                allFilesDateCode = '000000';
            end
            DateCode = allFilesDateCode;
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Returns a structure with the mouse ID data (group, session, mouse and
        % day). The info is extracted from the behavioral data .mat file directory and name
        % provided as input parameter. If the file name is not coding the data properly a
        % status error and an empty struct is returned.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [MouseData] = ExtractMouseID(ProjectDirectory, folder, name)
            IdOk = true;
            
            tempstr = extractAfter(folder, [ProjectDirectory '\']);
            GroupName = extractBefore(tempstr, '\');
            if isempty(GroupName)
                IdOk = false;  
            end
            
            MouseNum = extractBetween(tempstr, '\Mouse', '\');
            if isempty(MouseNum)
                IdOk = false;
            end
            
            SessionName = extractBetween(name, '_', '_Day');
            if isempty(SessionName)
                IdOk = false;
            end
            
            DayNum = extractBetween(name, '_Day', '_');
            if isempty(DayNum)
                IdOk = false;
            end
        
            if IdOk
                MouseData = struct('Group', GroupName, 'Session', SessionName, 'Mouse', MouseNum, 'Day', DayNum);
            else
                MouseData = struct('Group', [], 'Session', [], 'Mouse', [], 'Day', []);
            end
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Returns a list of behavioral ".mat" files to be processed. The list depends on how the GUI
        % fields (specifieing project, MouseGroup, session, etc...) are set.
        % If either Muouse or Day fields in GUI are set to 'list' two lists are returned otherwise
        % only one list (the first) is returned.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [Status, FileList1, FileList2] = GetFileLists(ProjectDirectory, MouseGroupName, SessionName, Mouse, Day)
            FileList2 = [];

            if exist([ProjectDirectory '\' MouseGroupName '\MiceList.mat'], 'file') == 2
                load([ProjectDirectory '\' MouseGroupName '\MiceList.mat'], 'MiceList1', 'MiceList2', 'DaysList1', 'DaysList2');
            else
                MiceList1 = [];
                MiceList2 = [];
                DaysList1 = [];
                DaysList2 = [];
            end
            
            if strcmp(Mouse, 'list')
                FileList1 = FileUtilities.GetFilesFromList(ProjectDirectory, MouseGroupName, SessionName, MiceList1, cellstr(Day));
                FileList2 = FileUtilities.GetFilesFromList(ProjectDirectory, MouseGroupName, SessionName, MiceList2, cellstr(Day));
            elseif strcmp(Day, 'list')
                FileList1 = FileUtilities.GetFilesFromList(ProjectDirectory, MouseGroupName, SessionName, cellstr(Mouse), DaysList1);
                FileList2 = FileUtilities.GetFilesFromList(ProjectDirectory, MouseGroupName, SessionName, cellstr(Mouse), DaysList2);
            else
                FileList1 = FileUtilities.GetMaskedFileList(ProjectDirectory, MouseGroupName, SessionName, Mouse, Day);
            end
                
            Status = 0;
            if (isempty(FileList1) && isempty(FileList2)) 
                uiwait(msgbox('Behavioral .mat file was not found', 'Input Data', 'error', 'modal'));
                Status = 1;
            end
        end

        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        % Creates output file directory name to be used by file storing funcions.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [DirName] = LocateOutfileDir(ProjectData, Mouse, OutputDir) 
            DirName = '\';
            if strcmp(ProjectData.MouseGroupName, 'all') == 0
                DirName = [DirName, ProjectData.MouseGroupName, '\'];
                if strcmp(Mouse, 'all') == 0
                    DirName = [DirName, 'Mouse', Mouse, '\'];
                end
            end
            
            DirName = [DirName, OutputDir];
        end


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Check existence of given directory. Allow user to create if missing.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [Status] = CheckDir(ProjectDirectory, Dir)
            
            Status = 0;
            
            if ~(exist([ProjectDirectory '\' Dir], 'dir') == 7)
                button = questdlg([Dir ': Directory does not exist. Create?'], 'Directory not found');
                if strcmp(button, 'Yes')
                    mkdir([ProjectDirectory '\' Dir]);
                else
                    Status = 1;
                end
            end
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        % Builds a generelized mouse data structure, namely, changes specific data to
        % 'all' if multiple instances apear in a list of inpout files.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [OutData] = GeneralizeMiceData(allMiceData, MouseData)
            allMiceData.Group = FileUtilities.GeneralizeMouseDataField(allMiceData.Group, MouseData.Group);
            allMiceData.Mouse = FileUtilities.GeneralizeMouseDataField(allMiceData.Mouse, MouseData.Mouse);
            allMiceData.Session = FileUtilities.GeneralizeMouseDataField(allMiceData.Session, MouseData.Session);
            allMiceData.Day = FileUtilities.GeneralizeMouseDataField(allMiceData.Day, MouseData.Day);
            
            OutData = allMiceData;
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Writes exported data to a file in the 'Exported Data" directory of
        % the Specified mouse. The inout arguments are used to locate the directory
        % and set file name. Data of multiple mice are stored in an upper directory
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [] = WriteXlsFile(ProjectDirectory, ProjectData, Mouse, Day, DataToExport, FileData)
        
            Fname = '\Exported Data';
            if strcmp(ProjectData.MouseGroupName, 'all') == 0
                Fname = [ProjectData.MouseGroupName '\Exported Data'];
                if strcmp(Mouse, 'all') == 0
                    Fname = [ProjectData.MouseGroupName, '\Mouse', Mouse, '\Exported Data'];
                end
            end
        
            if FileUtilities.CheckDir(ProjectDirectory, Fname) == 1                % export directory missing
                return;
            end
            
            Fname = [ProjectDirectory, '\', Fname, '\', FileData.Prefix, '_', ProjectData.SessionName, '_Day', Day, '_', FileData.Name];
        
            writecell(DataToExport.Title, Fname, 'WriteMode', 'overwrite', 'Range', 'A1');
            writecell(DataToExport.DataArray, Fname, 'Range', 'A3');
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Resizes the width of a matrix and copies the data over 
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [resizedArray] = ResizeOutData(dataArray, newWidth)
            resizedArray = repmat({' '}, size(dataArray,1), newWidth);
            resizedArray = cellstr(string(resizedArray));
            resizedArray = dataArray(:, 1 : size(dataArray, 2));
        end

    end    % public methods


    methods (Static, Access = private)

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        % gets two behavioral data lists based on Mice Lists and merges them into
        % a single array
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [FileList] = GetFilesFromList(ProjectDirectory, MouseGroupName, SessionName, MiceList, DaysList)  
            FileList = [];

            for i = 1 : length(MiceList)
                mouse = MiceList{i};
                for j = 1 : length(DaysList)
                    day = DaysList{j};
                    SubList = FileUtilities.GetMaskedFileList(ProjectDirectory, MouseGroupName, SessionName, mouse, day);   % Get input file  
                    FileList = [FileList; SubList]; %#ok<AGROW>
                end
            end
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Builds a file name mask based on the GUI setting that (when used in a dir
        % command) will return a list of behavioral .mat files.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [FileList] = GetMaskedFileList(ProjectDirectory, MouseGroupName, SessionName, Mouse, Day)
            FileMask = ProjectDirectory;
            if strcmp(MouseGroupName, 'all')
                FileMask = [FileMask '\*'];
            else
                FileMask = [FileMask '\' MouseGroupName];
            end
            
            if strcmp(Mouse, 'all')
                FileMask = [FileMask '\*'];
            else
                FileMask = [FileMask '\Mouse' Mouse];
            end
            
            FileMask = [FileMask '\Licking Data\*'];
            if ~strcmp(SessionName, 'all')
                FileMask = [FileMask '_' SessionName];
                SpecificSession = true;
            else
                SpecificSession = false;        
            end
            
            if strcmp(Day, 'all')
                if SpecificSession
                    FileMask = [FileMask '_*.mat'];
                else
                    FileMask = [FileMask '.mat'];
                end
            else
                FileMask = [FileMask '_Day' Day '*.mat'];
            end
            
            FileList = dir(FileMask);            
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Genralizes a single data field in the mouse data structure
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        function [OutData] = GeneralizeMouseDataField(MiceData, MouseData)
            if strcmp(MiceData, 'firstfile') == 1
                MiceData = MouseData;
            elseif strcmp(MiceData, MouseData) == 0
                MiceData = 'all';
            end
            OutData = MiceData;
        end

    end  % Private methods
end     % class

