function drawFixation(windowPtr,center,color)
% Draws round fixation marker in the center of the window
% Written by KGS Lab
% Edited by AS 8/2014

% find center of window
centerX = center(1);
centerY = center(2);

Screen('FillOval', windowPtr, color, [centerX-6, centerY-6, centerX+6, centerY+6]);

end