function [keys RT] = recordKeys(startTime,duration,deviceNumber)
% Collects all keypresses for a given duration (in secs).
% Written by KGS Lab
% Edited by AS 8/2014

% DW - allow device number to be unspecified
if nargin == 2
    deviceNumber = -1;
end

keys = [];
RT = [];
rcStart = GetSecs;

% wait until keys are released
while KbCheck(deviceNumber)
    if (GetSecs-startTime) > duration
        break
    end
end

% check for pressed keys
while 1
    [keyIsDown,secs,keyCode] = KbCheck(deviceNumber);
    % DW - add check for if key is '5' or '%' (SHIFT+5) and skip if it is
    % This stops scanner triggers getting confused with responses
    keyName = KbName(keyCode);
    if keyIsDown && ~any(strcmp(keyName, {'5%','%5','5','%'}))
        keys = [keys keyName];
        RT = [RT GetSecs-rcStart];
        while KbCheck(deviceNumber)
            if (GetSecs-startTime) > duration
                break
            end
        end
    end
    if (GetSecs-startTime) > duration
        break
    end
end

% label null responses noanswer and store multiple presses as an array
if isempty(keys)
    keys = 'noanswer';
    RT = 0;
elseif iscell(keys)
    keys = num2str(cell2mat(keys));
    RT = 0;
end

end