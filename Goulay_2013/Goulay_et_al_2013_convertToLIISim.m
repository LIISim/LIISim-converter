
%%
%   Convert supplementary material to LIISim compatible data format	
%
%   F. Goulay, P. E. Schrader, X. López-Yglesias, and H. A. Michelsen, 
%   "A data set for validation of models of laser-induced incandescence 
%   from soot: temporal profiles of LII signal and particle temperature," 
%   Appl. Phys. B 112, 287-306 (2013).
%
%   Script version: 0.1 (November 2017)
%   ---------------------------------------------------------------------
%   INSTRUCTIONS:
%   1) Go to https://doi.org/10.1007/s00340-013-5504-4
%   2) Download the Supplementary material (all .txt files)
%   3) Copy the text files to the same folder as this MATLAB script
%   4) Execute this script to convert files and create LIISettings
%   5) Copy 'Goulay_2013_3C_LIISettings.txt' to your LIISim database folder
%   6) The two folders created 'LIISim-523nm' and 'LIISim-1064nm' can then
%      be imported using the 'Custom Import' of LIISim
%   ---------------------------------------------------------------------
%   INFORMATION:
%
%   Downloaded: 340_2013_5504_MOESM<idx>_ESM.txt
%
%   Files: <idx>
%       1:    1 CH - Laser: 532 nm      BP: 682 nm - fluence in J/cm^2
%       2:    1 CH - Laser: 1064 nm     BP: 682 nm - fluence in J/cm^2
%
%       3:    3 CH - Laser: 532 nm      BP: 452 nm - fluence in mJ/cm^2 ?
%       4:    3 CH - Laser: 532 nm      BP: 682 nm
%       5:    3 CH - Laser: 532 nm      BP: 855 nm
%
%       6:    3 CH - Laser: 1064 nm     BP: 452 nm
%       7:    3 CH - Laser: 1064 nm     BP: 682 nm
%       8:    3 CH - Laser: 1064 nm     BP: 855 nm
%
%   Notice: Files with index 1 and 2 is not converted (these measurements
%           contain only a single detection channel and cannot be 
%           processed with LIISim).
%
%   This script converts text files into "Custom import" data format of
%   LIISim (only the signal traces and NOT additional information at the end of 
%   the files, i.e, laser temporal profiles etc.)
%   
%   Please make sure the created LIISettings file is located in the 
%   LIISim database directory.
%
%   The following settings need to be made in LIISim:
%       'Load Signal Data' -> CUSTOM
%       Only one channel per channel = disabled
%       Filename:   [] <EMPTY> [] <RUN> [] <EMPTY> [] <.txt>
%       delimiter   = \tab
%       decimal     = .
%       time unit   = s

clear

%% create LIISettings

filename_LIISettings = 'Goulay_2013_3C_LIISettings';

% set bandpass filter wavelengths for LIISettings
wavelength = [];
wavelength{1} = 452;
wavelength{2} = 682;
wavelength{3} = 855;

% set bandpass filter witdth for LIISettings
bp_width = [];
bp_width{1}   = 9;
bp_width{2}   = 10;
bp_width{3}   = 36;

% create dynamic settings content
lines = [];
lines{end+1} = strcat("Goulay2013;LIISettings;1.0;experimental setup used for validation data experiments;");

for j = 1:size(wavelength,2)
    lines{end+1} = "channel;" + wavelength{j} + ";" + bp_width{j} +";1;500;1;0;";
end

% write file
fid = fopen(strcat(filename_LIISettings, '.txt'),'w+');

if(fid < 0)
    disp("Could not create LIISettings file");
else
    for i = 1:size(lines,2)
    fprintf(fid, '%s\r\n', lines{i});
    end        
    fclose(fid);
end


%% Import measurement data
dataset = [];

for i = 1:8
    dataset{i} = importdata("340_2013_5504_MOESM" + i + "_ESM.txt");
end

% Set 1: 532 nm data

set{1}.export_folder = 'LIISim-532nm';

set{1}.data = [];
set{1}.time = [];

set{1}.coltext  = dataset{3}.colheaders;
set{1}.data{1} = dataset{3}.data;
set{1}.data{2} = dataset{4}.data;
set{1}.data{3} = dataset{5}.data;


% Set 2: 1064 nm data

set{2}.export_folder = 'LIISim-1064nm';

set{2}.data = [];
set{2}.time = [];

set{2}.coltext  = dataset{6}.colheaders;
set{2}.data{1} = dataset{6}.data;
set{2}.data{2} = dataset{7}.data;
set{2}.data{3} = dataset{8}.data;


% run this export routine for every set
for i = 1:size(set,2)
    
    export_folder   = set{i}.export_folder;
    coltext         = set{i}.coltext;
    time            = set{i}.time;
    data            = set{i}.data;
    
    if exist(export_folder,'dir') == 0
        mkdir(export_folder);
    end
    
    % create txt files for each colum (=measurement run)
    for col = 2:size(coltext,2)-1

        % take column text from first channel file        
        name = strjoin(regexp(coltext{col}, 'LII_[0-9]+_','split'),'');     
        
        % convert fluence text to double    
        stext = regexp(coltext{col}, '_','split');     
        fluence = str2num(strrep(stext{4}, 'p', '.'));

        %convert fluence from J/cm^2 to mJ/mm^2
        fluence = fluence * 10.0;

        signals = [];
        signals(:,1) = data{1}(:,1);    % time
        signals(:,2) = data{1}(:,col);  % ch1
        signals(:,3) = data{2}(:,col);  % ch2
        signals(:,4) = data{3}(:,col);  % ch3

        % save all channels in one file
        dlmwrite(strcat(export_folder, '\', name, '.txt'), signals, 'delimiter', '\t'); 

        % create settings data
        lines = [];
        lines{end+1} = "[MRunSettings]";
        lines{end+1} = "name=" + name;
        lines{end+1} = "description=Goulay et al. (2013) - A data set for validation of LII";
        lines{end+1} = strcat("liisettings=liisettings/", filename_LIISettings, ".txt");
        lines{end+1} = "filter=no Filter";
        lines{end+1} = "laser_fluence=" + num2str(fluence);

        % write measurement run settings file
        fid = fopen(strcat(export_folder, '\', name, '_settings.txt'),'w+');

        if(fid < 0)
            disp("Could not create MRun settings file");
        else
            for i = 1:size(lines,2)
            fprintf(fid, '%s\r\n', lines{i});
            end        
            fclose(fid);
        end
    end
end


