% Antoniades et al. (2013) standard anti-saccade task: Antoniades et al.
% (2013). An internationally standardised antisaccade protocol. Vision
% Research 84, 1--5.
sca
clear variables

% add Titta folder to path
addpath(genpath(fullfile(fileparts(mfilename('fullpath')),'..','..')));

DEBUGlevel          = 0;

% provide info about your screen (set to defaults for screen of Spectrum)
sv.scr.num             = 0;
sv.scr.rect            = [1920 1080];                       % expected screen resolution   (px)
sv.scr.framerate       = 60;                                % expected screen refresh rate (hz)
sv.scr.viewdist        = 65;                                % viewing    distance      (cm)
sv.scr.sizey           = 29.69997;                          % vertical   screen   size (cm)
sv.scr.multiSample     = 8;

sv.bgclr               = 127;                               % screen background color (L, or RGB): here midgray

% setup eye tracker
qUseDummyMode           = false;
settings                = Titta.getDefaults('Tobii Pro Spectrum');
settings.cal.bgColor    = sv.bgclr;
% custom calibration drawer
calViz                  = AnimatedCalibrationDisplay();
calViz.bgColor          = sv.bgclr;
settings.cal.drawFunction = @(a,b,c,d,e) calViz.doDraw(a,b,c,d,e);

% task parameters, all defaults are per Antoniades et al. (2013)
% block and timing setup
sv.blockSetup      = {'P',60;'A',40;'A',40;'A',40;'P',60};  % blocks and number of trials per block to run: P for pro-saccade and A for anti-saccade
sv.nTrainTrial     = [10 4];                                % number of training trials for [pro-, anti-saccades]
sv.delayTMean      = 1500;                                  % the mean of the truncated exponential distribution for delay times
sv.delayTLimits    = [1000 3500];                           % the limits of the truncated exponential distribution for delay times
sv.targetDuration  = 1000;                                  % the duration for which the target is shown
sv.breakT          = 60000;                                 % the minimum resting time between blocks (ms)
sv.restT           = 1000;                                  % the blank time between trials
% fixation point
sv.fixBackSize     = 0.25;                                  % degrees
sv.fixFrontSize    = 0.1;                                   % degrees
sv.fixBackColor    = 0;                                     % L or RGB
sv.fixFrontColor   = 255;                                   % L or RGB
% target point
sv.targetDiameter  = 0.5;                                   % degrees
sv.targetColor     = 0;                                     % L or RGB
sv.targetEccentricity  = 8;                                 % degrees

% default text settings
text.font           = 'Consolas';
text.size           = 20;
text.style          = 0;                                    % can OR together, 0=normal,1=bold,2=italic,4=underline,8=outline,32=condense,64=extend.
text.wrapAt         = 62;
text.vSpacing       = 1;
text.lineCentOff    = 3;                                    % amount (pixels) to move single line text down so that it is visually centered on requested coordinate
text.color          = 0;                                    % L or RGB




%% prepare run
%%%%%%%%%%%%%%%%%% get display setup
rect                = Screen('Rect',sv.scr.num);
frate               = Screen('FrameRate',sv.scr.num);

%%%%%%%%%%%%%%%%%% fix Windows 7 brokenness
% see http://support.microsoft.com/kb/2006076, 59 Hz == 59.94Hz (and thus == 60 Hz)
if frate==59
    warning('Windows reported 59Hz again, ignoring it and pretending its 60 Hz...'); %#ok<WNTAG>
    frate=60;
end

%%%%%%%%%%%%%%%%%% check and compute display setup
assert(DEBUGlevel || isequal(rect(3:4),sv.scr.rect),'expected resolution of [%s], but got [%s]',num2str(sv.scr.rect),num2str(rect(3:4)));
assert(DEBUGlevel || frate==sv.scr.framerate,'expected framerate of %d, but got %d',sv.scr.framerate,frate);
sv.scr.FOVy        = 2*atand(.5 .* sv.scr.sizey./sv.scr.viewdist);       % Screen's Field of View (degrees)
sv.scr.aspectr     = sv.scr.rect(1) ./ sv.scr.rect(2);                   % aspect ratio
sv.scr.FOVx        = 2*atand(tand(sv.scr.FOVy/2)*sv.scr.aspectr);
sv.scr.center      = sv.scr.rect/2;
sv.scr.flipWaitT   = 1/sv.scr.framerate;

% check timing parameters
checkTime(sv.delayTMean    ,{'scalar'} ,'sv.delayTMean (the mean of the truncated exponential distribution for delay times)',sv.scr.framerate);
checkTime(sv.delayTLimits  ,{'numel',2},'sv.delayTLimits (the limits of the truncated exponential distribution for delay times)',sv.scr.framerate);
checkTime(sv.targetDuration,{'scalar'} ,'sv.targetDuration (the duration for which the target is shown)',sv.scr.framerate);
checkTime(sv.breakT        ,{'scalar'} ,'sv.breakT (the minimum resting time between blocks)',sv.scr.framerate);
checkTime(sv.restT         ,{'scalar'} ,'sv.restT (the blank time between trials)',sv.scr.framerate);

% setup colors
sv.bgclr        = color2RGBA(sv.bgclr);
sv.fixBackColor = color2RGBA(sv.fixBackColor);
sv.fixFrontColor= color2RGBA(sv.fixFrontColor);
sv.targetColor  = color2RGBA(sv.targetColor);
text.color      = color2RGBA(text.color);
% insert training blocks
bIdx = find(strcmp(sv.blockSetup(:,1),'P'));
if ~isempty(bIdx)
    sv.blockSetup = [sv.blockSetup(1:bIdx-1,:); {'TP',sv.nTrainTrial(1)}; sv.blockSetup(bIdx:end,:)];
end
bIdx = find(strcmp(sv.blockSetup(:,1),'A'));
if ~isempty(bIdx)
    sv.blockSetup = [sv.blockSetup(1:bIdx-1,:); {'TA',sv.nTrainTrial(2)}; sv.blockSetup(bIdx:end,:)];
end
% prepare display geometry
sv.targetEccentricityPix= AngleToScreenPos(sv.targetEccentricity,sv.scr.FOVx)/2*sv.scr.rect(1);   % /2 for scaling [-1 1] range of AngleToScreenPos to [0 1]
sv.targetDiameterPix    = AngleToScreenPos(sv.targetDiameter    ,sv.scr.FOVx)/2*sv.scr.rect(1);
sv.fixBackSizePix       = AngleToScreenPos(sv.fixBackSize       ,sv.scr.FOVx)/2*sv.scr.rect(1);
sv.fixFrontSizePix      = AngleToScreenPos(sv.fixFrontSize      ,sv.scr.FOVx)/2*sv.scr.rect(1);

% generate trials
nTrials = [0 sv.blockSetup{:,2}];
data.trials = struct('tNr',num2cell(1:sum(nTrials)));
[data.trials.qFirstOfBlock] = deal(false);
[data.trials.qLastOfBlock]  = deal(false);
[data.trials.instruct]      = deal(struct('text',''));
dealFun = @(x)x{:};                     % like deal, but no shit that we first have to create a cell variable that we then feed it with {:}
rafz    = @(x)ceil(abs(x)).*sign(x);    % round away from zero
delayTs = [sv.delayTLimits(1) : 1000/sv.scr.framerate : sv.delayTLimits(2)];    % possible delay times, discretized to frames in the interval
for p=1:size(sv.blockSetup,1)
    idxs = sum(nTrials(1:p))+[1:nTrials(p+1)];
    [data.trials(idxs).bNr]       = deal(p);
    [data.trials(idxs).bTNr]      = dealFun(num2cell(1:nTrials(p+1)));
    [data.trials(idxs).blockType] = deal(sv.blockSetup{p,1}(end));
    [data.trials(idxs).qTraining] = deal(sv.blockSetup{p,1}(1)=='T');
    [data.trials(idxs).dir]       = dealFun(num2cell(rafz(rand(1,nTrials(p+1))*2-1)));  % equal probability for each trial instead of balanced number
    data.trials(idxs(1)).qFirstOfBlock = true;
    data.trials(idxs(end)).qLastOfBlock= true;
    [data.trials(idxs).delayT]    = dealFun(num2cell(truncExpRandDiscrete([1,nTrials(p+1)],sv.delayTMean,delayTs)));
    % setup instructions
    if sv.blockSetup{p,1}(end)=='P'
        if sv.blockSetup{p,1}(1)=='T'
            data.trials(idxs(1)).instruct.text = 'In this task, a central black dot will be shown. Look at the central dot; and as soon as a new dot appears on the left or right, <u><i>look at it<i><u> as fast as you can.\n\nYou will now first do a brief practice.\n\n\nPress the spacebar to continue...';
        else
            data.trials(idxs(1)).instruct.text = 'Now, look at the central dot; and as soon as a new dot appears on the left or right, <u><i>look at it<i><u> as fast as you can.\n\n\nPress the spacebar to continue...';
        end
    else
        if sv.blockSetup{p,1}(1)=='T'
            data.trials(idxs(1)).instruct.text = 'Your task will now be different. As before, look at the central dot; but as soon as a new dot appears, <u><i>look away from it<i><u> in the opposite direction of where the dot appeared, as fast as you can. So if the new dot appears on the left, look to the right. You will probably sometimes make mistakes, and this is perfectly normal.\n\nYou will now first do a brief practice.\n\n\nPress the spacebar to continue...';
        else
            data.trials(idxs(1)).instruct.text = 'Now, look at the central dot; but as soon as a new dot appears, <u><i>look away from it<i><u> in the opposite direction of where the dot appeared, as fast as you can. So if the new dot appears on the left, look at the right. You will probably sometimes make mistakes, and this is perfectly normal.\n\n\nPress the spacebar to continue...';
        end
    end
end

%% run
try 
    % init
    EThndl          = Titta(settings);
    if qUseDummyMode
        EThndl          = EThndl.setDummyMode();
    end
    EThndl.init();
    
    
    if DEBUGlevel>1
        % make screen partially transparent on OSX and windows vista or
        % higher, so we can debug.
        PsychDebugWindowConfiguration;
    end
    Screen('Preference', 'SyncTestSettings', 0.002);    % the systems are a little noisy, give the test a little more leeway
    wpnt = PsychImaging('OpenWindow', sv.scr.num, sv.bgclr, [], [], [], [], sv.scr.multiSample);
    Priority(1);
    Screen('BlendFunction', wpnt, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    Screen('Preference', 'TextAlphaBlending', 1);
    Screen('Preference', 'TextAntiAliasing', 2);
    % This preference setting selects the high quality text renderer on
    % each operating system: It is not really needed, as the high quality
    % renderer is the default on all operating systems, so this is more of
    % a "better safe than sorry" setting.
    Screen('Preference', 'TextRenderer', 1);
    KbName('UnifyKeyNames');    % for correct operation of the setup/calibration interface, calling this is required
    
    % do calibration, start recording
    calValInfo = EThndl.calibrate(wpnt);
    EThndl.buffer.start('gaze');
    
    % clear flip
    clearTime = Screen('Flip',wpnt);
    % run all trials
    for p=1:length(data.trials)
        if data.trials(p).bTNr==1
            EThndl.sendMessage(sprintf('BLOCK START %d: %s',data.trials(p).bNr,sv.blockSetup{data.trials(p).bNr,1}));
        end
        if ~isempty(data.trials(p).instruct.text)
            insText                     = data.trials(p).instruct.text;
            data.trials(p).instruct     = drawInstruction(insText,addToStruct(text,'color',[0 0 0 255]),wpnt,{'space'},@EThndl.sendMessage);
            data.trials(p).instruct.text= insText;
            clearTime                   = data.trials(p).instruct.Toffset;
        end
        
        % draw fixation target after sv.restT
        drawfixpoints(wpnt,sv.scr.center,{'.','.'},{sv.fixBackSizePix sv.fixFrontSizePix},{sv.fixBackColor sv.fixFrontColor},1);
        data.trials(p).fixOnsetT  = Screen('Flip',wpnt,clearTime+sv.restT/1000-sv.scr.flipWaitT+1/1000);
        EThndl.sendMessage(sprintf('FIX ON %d (%d %d)',p,sv.scr.center),data.trials(p).fixOnsetT);
        
        % draw saccade (anti-)target after delayT
        pos = sv.scr.center;
        pos(1) = pos(1)+data.trials(p).dir*sv.targetEccentricityPix;
        drawfixpoints(wpnt,pos,{'.'},{sv.targetDiameterPix},{sv.targetColor},1);
        data.trials(p).targetOnsetT  = Screen('Flip',wpnt,data.trials(p).fixOnsetT+data.trials(p).delayT/1000-sv.scr.flipWaitT+1/1000);
        EThndl.sendMessage(sprintf('TARGET ON %d (%d %d)',p,round(pos)),data.trials(p).targetOnsetT);
        
        % clear after sv.targetDuration
        data.trials(p).targetOffsetT = Screen('Flip',wpnt,data.trials(p).targetOnsetT+sv.targetDuration/1000-sv.scr.flipWaitT+1/1000);
        clearTime = data.trials(p).targetOffsetT;
        EThndl.sendMessage(sprintf('TARGET OFF %d (%d %d)',p,round(pos)),clearTime);
        
        % break if after last of block and not training.
        if data.trials(p).qLastOfBlock && ~data.trials(p).qTraining && p~=length(data.trials)
            EThndl.sendMessage('BREAK START');
            displaybreak(sv.breakT/1000,wpnt,addToStruct(text,'color',[200 0 0 255]),'space',@EThndl.sendMessage);
            clearTime = Screen('Flip',wpnt);
            EThndl.sendMessage('BREAK OFF',clearTime);
        end
        if p==length(data.trials) || data.trials(p+1).bTNr==1
            EThndl.sendMessage(sprintf('BLOCK END %d: %s',data.trials(p).bNr,sv.blockSetup{data.trials(p).bNr,1}));
        end
    end
    
    % stopping
    EThndl.buffer.stop('gaze');
    
    % save data to mat file
    data.setup  = sv;
    data.ETdata = EThndl.collectSessionData();
    save('antiSac.mat','-struct','data')
    
    % shut down
    EThndl.deInit();
catch me
    sca
    rethrow(me)
end
% shut down
EThndl.deInit();
sca