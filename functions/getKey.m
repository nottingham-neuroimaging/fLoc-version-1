function getKey(key,laptopKey)
% Waits until user presses the key specified in first argument.
% Written by KGS Lab
% Edited by AS 8/2014

while 1
    while 1
        % DW - allow device ID to be unspecified
        if nargin == 1
            [keyIsDown, secs, keyCode] = KbCheck(-1);
        else
            [keyIsDown,secs,keyCode] = KbCheck(laptopKey);
        end
        
        if keyIsDown
            break
        end
    end
    
    pressedKey = KbName(keyCode);
    if ismember(key,pressedKey)
        break
    end
    
end

end