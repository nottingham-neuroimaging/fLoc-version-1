function runme(sID, varargin)
% Prompts experimenter for session information and executes functional
% localizer experiment used to define regions in high-level visual cortex
% selective to written characters, body parts, faces, and places. 
% 
% INPUTS (required)
%   sID : string giving subject ID
%
% INPUTs (optional) - specify as 'key1', value1, 'key2, value2, etc.
%   'nruns' : total number of runs to execute sequentially (default is 1 run)
%   'startRun' : run number to start with if interrupted (default is run 1)
%   'task' : Which task to run; 1 = one-back, 2 = two-back, 3 = odd-ball
%            (detect occasional phase scram image). Default = 3 (odd-ball).
%   'scanner' : Boolean, if true then after experimenter presses 'g' to
%               start run, script will wait further for trigger (key '5')
%               from scanner before starting proper. Default = true.
%   'countDown' : Time (in secs) to wait after trigger to starting stimulus
%                 presentation. Default = 12.
%   'stimSize' : Size to display images at (in pixels). Default = 512.
% 
% STIMULUS CATEGORIES (2 subcategories for each stimulus condition)
% Written characters
%     1 = word:  English psueudowords (3-6 characters long; see Glezer et al., 2009)
%     2 = number: whole numbers (3-6 characters long)
% Body parts
%     3 = body: headless bodies in variable poses
%     4 = limb: hands, arms, feet, and legs in various poses and orientations
% Faces
%     5 = adult: adults faces
%     6 = child: child faces
% Places
%     7 = corridor: views of indoor corridors placed aperature
%     8 = house: houses and buildings isolated from background
% Objects
%     9 = car: motor vehicles with 4 wheels
%     10 = instrument: string instruments
% Baseline = 0
%
% EXPERIMENTAL DESIGN
% Run duration: 5 min + countdown (12 sec by default)
% Block duration: 4 sec (8 images shown sequentially for 500 ms each)
% Task: 1 or 2-back image repetition detection or odddball detection
% 6 conditions counterbalanced (5 stimulus conditions + baseline condition)
% 12 blocks per condition (alternating between subcategories)
%
% Version 2.0 8/2015
% Anthony Stigliani (astiglia@stanford.edu)
% Department of Psychology, Stanford University

%% DW - get all params from function args, instead of asking for text input
parser = inputParser;
parser.addRequired('sID', @ischar);
parser.addParameter('nruns', 1, @isnumeric);
parser.addParameter('startRun', 1, @isnumeric);
parser.addParameter('task', 3, @(x) ismember(x, [1,2,3]));
parser.addParameter('scanner', true, @islogical);
parser.addParameter('countDown', 12, @isnumeric);
parser.addParameter('stimSize', 512, @isnumeric);

parser.parse(sID, varargin{:});
res = parser.Results;
disp(res);

sID = res.sID;
nruns = res.nruns;
startRun = res.startRun;
task = res.task;
scanner = double(res.scanner);
countDown = res.countDown;
stimSize = res.stimSize;

if startRun > nruns
    error('startRun cannot be greater than nruns')
end

%% DW - init PsychToolbox
PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', 1); % macOS

%% SET PATHS
path.baseDir = pwd; addpath(path.baseDir);
path.fxnsDir = fullfile(path.baseDir,'functions'); addpath(path.fxnsDir);
path.scriptDir = fullfile(path.baseDir,'scripts'); addpath(path.scriptDir);
path.dataDir = fullfile(path.baseDir,'data'); addpath(path.dataDir);
path.stimDir = fullfile(path.baseDir,'stimuli'); addpath(path.stimDir);

%% COLLECT SESSION INFORMATION
% initialize subject data structure
subject.name = {};
subject.date = {};
subject.experiment = 'fLoc';
subject.task = -1;
subject.scanner = -1;
subject.script = {};
% collect subject info and experimental parameters
subject.name = deblank(sID);
subject.date = datestr(now, 'yyyy-mm-dd@HH-MM-SS');  % DW - include exact timestamp to prevent overwrite
subject.task = task;
subject.scanner = scanner;

%% GENERATE STIMULUS SEQUENCES
if startRun == 1
    % create subject script directory
    cd(path.scriptDir);
    makeorder_fLoc(nruns,subject.task);
    subScriptDir = sprintf('%s_%s_%s', subject.name,  subject.date, subject.experiment);
    mkdir(subScriptDir);
    % create subject data directory
    cd(path.dataDir);
    subDataDir = sprintf('%s_%s_%s', subject.name, subject.date, subject.experiment);
    mkdir(subDataDir);
    % prepare to exectue experiment
    cd(path.baseDir);
    fprintf(1, '\n%d runs will be exectued.\n', nruns);
end
tasks = {'1back' '2back' 'oddball'};

%% EXECUTE EXPERIMENTS AND SAVE DATA FOR EACH RUN
for r = startRun:nruns
    % execute this run of experiment
    subject.script = sprintf('script_%s_%s_run%d', subject.experiment, ...
        tasks{subject.task}, r);
    fprintf(1, '\nRun %d\n', r);
    WaitSecs(1);
    [theSubject, theData] = et_run_fLoc(path, subject, 'countDown', countDown, ...
        'stimSize', stimSize);
    % save data for this run
    cd(path.dataDir); cd(subDataDir);
    saveName = sprintf('%s_%s_%s_%s_run%d', theSubject.name, ...
        theSubject.date, theSubject.experiment, tasks{subject.task}, r);
    save(saveName,'theData','theSubject')
    cd(path.baseDir);
end

%% BACKUP SCRIPT AND PARAMTER FILES FOR THIS SESSION
for r = 1:nruns
    cd(path.scriptDir);
    source = sprintf('script_%s_%s_run%d', subject.experiment, tasks{subject.task}, r);
    movefile(source, subScriptDir);
    
    %cd(path.dataDir);  % <- DW : this seems to be wrong dir
    source = sprintf('script_%s_%s_run%d_%s.par', subject.experiment, ...
        tasks{subject.task}, r, date);  % Note - .par uses different date format
    try % even with fix above, still pretty flakey
        movefile(source, subScriptDir);
    catch ME
        disp(ME)
        warning('DW: no par file, think is bug in script?');
    end
        
end
cd(path.baseDir);

fprintf(1, '\nDone\n');

end