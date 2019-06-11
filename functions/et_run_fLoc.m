function [theSubject, theData] = et_run_fLoc(path, subject, varargin)
% Displays images for functional localizer experiment and collects
% behavioral data for 2-back image repetition detection task.
% AS 8/2014
% KJ@UMN 2/2016: Fix cumulative timing bug
%
% INPUTS (required)
%  path, subject - Structs created by runme.m
%
% INPUTs (optional) - specify as 'key1', value1, 'key2, value2, etc.
%   'countDown' : Time (secs) to wait after trigger before starting
%                 stimulus presentation
%   'stimSize' : Size to display images at (pixels)
%   'fixColor' : Fixation color specifed as [R,G,B] array of uint8 values
%   'textColor' : Text color specified as grayscale uint8 value
%   'blankColor' : Blank stimulus color specified as grayscale uint8 value
%   'waitDur' : For given task, time (secs) to wait after target image onset
%               before deciding response is a 'miss'. Must be < 2 and multiple
%               of 0.5.

%% DW edit - parse params from arguments instead of hard-coding
parser = inputParser();
parser.addRequired('path', @isstruct);
parser.addRequired('subject', @isstruct);
parser.addParameter('countDown', 12, @isnumeric);
parser.addParameter('stimSize', 512, @isnumeric);
parser.addParameter('fixColor', [255,0,0], @isnumeric);
parser.addParameter('textColor', 255, @isnumeric);
parser.addParameter('blankColor', 128, @isnumeric);
parser.addParameter('waitDur', 1.5, @(x) isnumeric(x) && x < 2 && mod(x, 0.5) == 0)

parser.parse(path, subject, varargin{:});
res = parser.Results;
path = res.path;
subject = res.subject;
countDown = res.countDown;
stimSize = res.stimSize;
fixColor = res.fixColor;
textColor = res.textColor;
blankColor = res.blankColor;
waitDur = res.waitDur;

%% FIND RESPONSE DEVICE
laptopKey = getKeyboardNumber;
buttonKey = getBoxNumber;
if subject.scanner == 1 && buttonKey ~= 0
    k = buttonKey;
else
    k = laptopKey;
end

% set k = -1 (looks through all connected USB devices)
k = -1; %macOS

%% SET UP SCREEN AND PRELOAD STIMULI
% read trial information stimulus sequence script
cd(path.scriptDir);
Trials = readScript_fLoc(subject.script);
subject.trials = Trials;
numTrials = length(Trials.block);
viewTime = Trials.onset(2);
cd(path.baseDir);
% initalize screen
[windowPtr,center,blankColor] = doScreen;
centerX = center(1);
centerY = center(2);
s = stimSize/2;
stimRect = [centerX-s centerY-s centerX+s centerY+s];
% store image textures in array of pointers
picPtrs = [];
catDirs = {'word' 'number' 'body' 'limb' 'adult' 'child' 'corridor' 'house' 'car' 'instrument'};
for t = 1:numTrials
    cd(path.stimDir);
    if strcmp(Trials.img{t},'blank')
        picPtrs(t) = 0;
    elseif subject.task == 3 && Trials.task(t) == 1
        cd('scrambled');
        pic = imread(Trials.img{t});
        picPtrs(t) = Screen('MakeTexture',windowPtr,pic);
    else
        cd(catDirs{Trials.cond(t)});
        pic = imread(Trials.img{t});
        picPtrs(t) = Screen('MakeTexture',windowPtr,pic);
    end
end
cd(path.baseDir);
% inititalize data structures
subject.timePerTrial = [];
subject.totalTime = [];
data = [];
data.keys = {};
data.rt = [];

%% DISPLAY INSTRUCTIONS AND START EXPERIMENT
% instructions for 1-back task
str{1} = 'Fixate. Press a button when an image repeats on sequential trials.\nPress g to continue.';
% instructions for 2-back task
str{2} = 'Fixate. Press a button when an image repeats within a block.\nPress g to continue.';
% instructions for oddball task
str{3} = 'Fixate. Press a button when a scrambled image appears.\nPress g to continue.';
% display instruction screen
WaitSecs(1);
Screen('FillRect',windowPtr,blankColor);
Screen('Flip',windowPtr);
DrawFormattedText(windowPtr,str{subject.task},'center','center',textColor);
Screen('Flip',windowPtr);

% DW - wait for go signal from laptop
fprintf(1, '\n!!! WAITING FOR ''g'' KEY PRESS FROM EXPERIMENTER !!!\n');
% getKey('g', laptopKey);
getKey('g'); %macOS
Screen('Flip', windowPtr);

% DW - possibly wait for trigger from scanner (key 5)
% TODO - not sure if scanner will register as laptop keyboard or not?
if subject.scanner == 1
    fprintf(1, '\n!!! WAITING FOR TRIGGER FROM SCANNER !!!\n');
    % getKey('5', laptopKey);
    getKey('5'); % macOS
end

%{
if subject.scanner == 0
    getKey('g',laptopKey);
elseif subject.scanner == 1
    while 1
        getKey('g',laptopKey);
        [status,time0] = newStartScan;
        if status == 0
            break
        else
            message = 'Trigger failed.';
            DrawFormattedText(windowPtr,message,'center','center',fixColor);
            Screen('Flip',windowPtr);
        end
    end
    end
%}

%% PRE-EXPERIMENT COUNTDOWN
% display countdown numbers
countDown = round(countDown);
countTime = countDown+GetSecs;
counter = countDown;
timeRemaining = countDown+GetSecs;
while timeRemaining > 0
    if floor(timeRemaining) <= counter
        number = num2str(counter);
        DrawFormattedText(windowPtr,number,'center','center',textColor);
        Screen('Flip',windowPtr);
        counter = counter-1;
    end
    timeRemaining = countTime-GetSecs;
end

%% MAIN DISPLAY LOOP
% get timestamp for start of experiment
startTime = GetSecs;
% display preloaded stimulus sequence
for t = 1:numTrials
    trialStart = GetSecs;
    % display blank screen if baseline trial and image if stimulus trial
    if Trials.cond(t) == 0
        Screen('FillRect',windowPtr,blankColor);
        drawFixation(windowPtr,center,fixColor);
    else
        Screen('DrawTexture',windowPtr,picPtrs(t),[],[stimRect]);
        drawFixation(windowPtr,center,fixColor);
    end
    Screen('Flip',windowPtr);
    % collect response and measure timing
    trialEnd = GetSecs-startTime;
    subject.timePerTrial(t) = trialEnd;
    %[keys RT] = recordKeys(trialStart,viewTime,k);
    [keys RT] = recordKeys(startTime+(t-1)*viewTime,viewTime,k);
    data.keys{t} = keys;
    data.rt(t) = min(RT);
end

%% ANANLYZE DATA AND CLEAR WINDOWS
% record total time of experiment
subject.totalTime = GetSecs-startTime;
theSubject = subject;
% analyze behavioral performance
theData = [];
theData = doAnalysis_fLoc(theSubject,data,waitDur,viewTime);
% display behavioral performance
hitStr = ['Hits: ' num2str(theData.hits) '/' num2str(theData.nreps) ' (' num2str(theData.propHit*100) '%)'];
faStr = ['False alarms: ' num2str(theData.falseAlarms)];
Screen('FillRect',windowPtr,blankColor);
Screen('Flip',windowPtr);
DrawFormattedText(windowPtr,[hitStr '\n' faStr '\n\nPress g to continue'],'center','center',textColor);
Screen('Flip',windowPtr);
% wait until g is pressed
getKey('g',laptopKey);
% show cursor and clear screen
ShowCursor;
Screen('CloseAll');

end
