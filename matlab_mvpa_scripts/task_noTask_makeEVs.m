function task_noTask_makeEVs(subID,subIni)

%% Create PM vs noPM only Reg Arrays for MATLAB MVPA- ForceMemRI v1
% Takes two inputs, the subject ID as a number and the subject initials as
% a string

%This code will take the behavioral data for ForceMemRI and create the
%EVs/Regs for doing MVPA within the Princeton toolbox.  The categories in
%this analysis are ONLY pm/npm - in order to see where we can decode task
%versus no task in the brain.  Most likely will be used in a whole brain
%searchlight and then compared with overlapping regions from the
%Face/Scene/noPM/(rest-maybe) analysis

cd ../../

subNum=subID;
subInit=subIni;

%Overall:
%Row 1 = pm Task
%Row 2 = npm Task


%First, I want to train within the OG and PM localizers as a sanity check.
%If those aren't working, then something is wrong.

%This script assumes you are starting in the forcemem_mriDat locally.
%However, it should work anywhere that this main file is placed as long as
%subfolders are named in the same way
curDir=pwd;

%This is where you would start a subject loop

%% OG Params
%So first, let's do the og localizer
% Params:
ogTrBlock=8; %8 trials per block
ogBlocks=2; %2 total blocks
ogTRs=84;
% cd behav/ogLoc/ %switch to the right data file

%Set up arrays to fill in with 
ogRegs=zeros(2,ogTRs*ogBlocks);
ogBlockR=zeros(1,ogTRs*ogBlocks);
ogMaster=zeros(4,ogTRs*ogBlocks);

%As a second analysis, I want to see if we can use MVPA within the areas of
%interest to decode OG task difficulty - that could be neat, right?
ogRegsbyDiff=zeros(3,ogTRs*ogBlocks);


ogDir=['forcemem_' mat2str(subNum) '/behav/ogLoc'];
cd(ogDir)

for ogBlockI=1:ogBlocks
    ogFile=['fm_fmri_ogLoc_' mat2str(subNum) '_' subInit '_1_' mat2str(ogBlockI) '.mat'];
    load(ogFile) %This loads the data file with the ogLoc data
    
     %You have to start with the first column even though start is at 0s
    startEV=0;
    ogBlockR(1,(ogBlockI-1)*84+1:(ogBlockI-1)*84+84)=ogBlockI;
    
    %For master list keep track of probeN
    startProbe=0;
    
    for ogTrialI=1:ogTrBlock
        trLength=size(Data.ogLocTiming{ogBlockI}.Trial{ogTrialI}.probeTiming,1);
        endEV=startEV+trLength;
        
        %Now indicate that nonPM is on those probes 
        ogRegs(2,(ogBlockI-1)*ogTRs+startEV+1:(ogBlockI-1)*ogTRs+endEV)=1;
        
        startEV=endEV;
        endEV=startEV+3;
        
        %Indicate the 6s (3ev) rest time between trials
%         ogRegs(4,(ogBlockI-1)*ogTRs+startEV+1:(ogBlockI-1)*ogTRs+endEV)=1;
        
        %Now set up the next trial
        startEV=endEV;
        
        %Now in this bit of code, I'm going to fill in the "master info for
        %that trial"
        for ogProbeI=1:trLength
            ogMaster(1,(ogBlockI-1)*ogTRs+startProbe+ogProbeI)=ogBlockI; %Block Num
            ogMaster(2,(ogBlockI-1)*ogTRs+startProbe+ogProbeI)=ogTrialI; %Trial Num
            ogMaster(3,(ogBlockI-1)*ogTRs+startProbe+ogProbeI)=Data.ogLocTiming{ogBlockI}.Trial{ogTrialI}.probeTiming{ogProbeI,13}; %ProbeNum in block
            ogMaster(4,(ogBlockI-1)*ogTRs+startProbe+ogProbeI)=Data.ogLocTiming{ogBlockI}.Trial{ogTrialI}.probeTiming{ogProbeI,2}; %Probe Difficulty
            
            
        end
        startProbe=startProbe+trLength+3;
        
        
    end
end

%Now output that subject's EVs
%For now, I'm just going to save the 3 basic things: ogRegs, ogBlockR,
%ogMaster
cd ../mvpa_params
save('task_noTask_ogLocRegs.mat','ogRegs')
save('task_noTask_ogBlockRegs.mat','ogBlockR')
save('task_noTask_ogMasterArray.mat','ogMaster')

cd ..
clear Data


%% PM Task Reg generator
%First load the original data file
cd pmTask/
pmFileN=['forceMem_fMRI_v1_' mat2str(subNum) '_' subInit '_5.mat'];
load(pmFileN);

%Experiment params
trLen=306;
blockN=5;
trialN=20;

%There are separate for all probes, and just the easy probes for training
%purposes
pmTaskReg=zeros(2,trLen*blockN);
easyRegs=zeros(2,trLen*blockN);


pmBlockR=[repmat(1,1,trLen),repmat(2,1,trLen),repmat(3,1,trLen),repmat(4,1,trLen),repmat(5,1,trLen)];
pmMaster=zeros(5,trLen*blockN);

%So we are going to cycle through each block and grab all "real" trials and
%assign intro, probes, and rest values to the TRs.  Non-real trials will be
%given all zeros, which will be removed during MVPA.

for blockI=1:blockN
    %reset curProbe back to zero at the beginning of each block
    curProbe=0;
    for trialI=1:trialN
        
        %Get the probe length for this trial and trial type
        probeL=Data.BlockTimings{blockI}.Trial{trialI}.trialLength; %Trial length
        pmType=Data.BlockTimings{blockI}.Trial{trialI}.pmType; %pm Type
        trialType=Data.BlockTimings{blockI}.Trial{trialI}.trialType; %trial direction type
        
        %The first two probes are the trials that show the category
        %type, so I can either indicate that those are Face/Scene/or
        %neither or I can leave them out.  For now, I'm leaving them
        %out.  To include them, change the '=0' to '=1'
        pmTaskReg(1,(blockI-1)*trLen+curProbe+1:(blockI-1)*trLen+curProbe+2)=0;
        curProbe=curProbe+2;
        
        %So only real trials
        if probeL>7
            
            %We are going to do probe1:probeL for nonPM trials and
            %probe1:probeL-1 for pmtrials.  This is just so we get dual
            %task measure and not just the PM processing on that last
            %probe...
            if pmType==3
            
                %This is set up as a loop so that in the future, I can take out
                %incorrect probes easily
                for probeI=1:probeL
                    


                    %Add the Reg in the right row
                    pmTaskReg(2,(blockI-1)*trLen+curProbe+probeI)=1;

                    %also fill in the master for comparing to later (for things
                    %like classifier evidence by difficulty)
                    pmMaster(1,(blockI-1)*trLen+curProbe+probeI)=blockI;
                    pmMaster(2,(blockI-1)*trLen+curProbe+probeI)=trialI;
                    pmMaster(3,(blockI-1)*trLen+curProbe+probeI)=probeI;
                    pmMaster(4,(blockI-1)*trLen+curProbe+probeI)=trialType;
                    pmMaster(5,(blockI-1)*trLen+curProbe+probeI)=pmType;
                    pmMaster(6,(blockI-1)*trLen+curProbe+probeI)=Data.BlockTimings{blockI}.Trial{trialI}.probeTiming{probeI,2}; %Probe Difficulty
                    
                    if Data.BlockTimings{blockI}.Trial{trialI}.probeTiming{probeI,2}<=8
                       %Add the Reg in the right row
                        easyRegs(2,(blockI-1)*trLen+curProbe+probeI)=1;                         
                    end


                end
                curProbe=curProbe+probeL;
            
            %Now for pm trials (this will just leave a 0 at the probeL
            %probe).
            else
                %This is set up as a loop so that in the future, I can take out
                %incorrect probes easily
                for probeI=1:probeL-1


                    %Add the Reg in the right row
                    pmTaskReg(1,(blockI-1)*trLen+curProbe+probeI)=1;

                    %also fill in the master for comparing to later (for things
                    %like classifier evidence by difficulty)
                    pmMaster(1,(blockI-1)*trLen+curProbe+probeI)=blockI;
                    pmMaster(2,(blockI-1)*trLen+curProbe+probeI)=trialI;
                    pmMaster(3,(blockI-1)*trLen+curProbe+probeI)=probeI;
                    pmMaster(4,(blockI-1)*trLen+curProbe+probeI)=trialType;
                    pmMaster(5,(blockI-1)*trLen+curProbe+probeI)=pmType;
                    pmMaster(6,(blockI-1)*trLen+curProbe+probeI)=Data.BlockTimings{blockI}.Trial{trialI}.probeTiming{probeI,2}; %Probe Difficulty


                    if Data.BlockTimings{blockI}.Trial{trialI}.probeTiming{probeI,2}<=8
                       %Add the Reg in the right row
                       easyRegs(1,(blockI-1)*trLen+curProbe+probeI)=1;                         
                    end
                end
                curProbe=curProbe+probeL;
            end

        else
            %Add this number to the
            curProbe=curProbe+probeL;
                    
        end
        
        %Skip the task feedback for now
        curProbe=curProbe+1;
            
        %Now go to the ITI (row 4 = rest)
%         pmTaskReg(4,(blockI-1)*trLen+curProbe+1:(blockI-1)*trLen+curProbe+3)=1;
%         easyRegs(4,(blockI-1)*trLen+curProbe+1:(blockI-1)*trLen+curProbe+3)=1;
        curProbe=curProbe+3;
        
        
    end
end


cd ../mvpa_params
save('task_noTask_pmTaskRegs.mat','pmTaskReg');
save('task_noTask_pmTaskBlockR.mat','pmBlockR');
save('task_noTask_pmTaskMaster.mat','pmMaster');
save('task_noTask_pmTaskEasyProbes','easyRegs');

%% PM Localizer EV Creator
%% Not included in this analysis

% 
% %first switch into the correct directory
% cd loc
% 
% %load the file - if you need to cycle through blocks add a block script,
% %else just use the number 3
% 
% locBlocks=3;
% locTRs=102;
% locBlockLen=66;
% miniBlockL=11;
% miniBlockN=6;
% 
% locRegs=zeros(4,locTRs*locBlocks);
% locBlockR=zeros(1,locTRs*locBlocks);
% locMaster=zeros(4,locTRs*locBlocks);
% 
% 
% locFile=['fm_fmri_loc_' mat2str(subNum) '_' subInit '_1_3.mat'];
% load(locFile)
% 
% %I can do some complicated thing to get the TRs, but because everything
% %lines up so nicely for this experiment, it is really easy to just grab the
% %category for that mini block and put the next 11 TRs in that row, and then
% %the next 6 TRs (12s) in the Rest column.
% 
% % locTimingArray=cell2mat(Data.locTiming.locBlock{1}.trialTiming(:,3));
% % locTimingArray(:,2)=floor(locTimingArray)/2+1;
% % locTRarray=zeros(1,102);
% % locTRarray(1,locTimingArray(:,2))=1;
% 
% locRegStart=0;
% for locBlockI=1:locBlocks
%     
%     locBlockR(1,(locBlockI-1)*locTRs+1:(locBlockI-1)*locTRs+locTRs)=locBlockI;
%     
%     for miniBlockI=1:miniBlockN
%         
%         %Find the Reg row based on stimulus type and then make the next 11
%         %EVs that type
%         locRow=Data.locDat{(locBlockI-1)*locBlockLen+(miniBlockI-1)*miniBlockL+1,2}; % 1 = Face, 2 = Scene 
%         locRegEnd=locRegStart+11;
%         locRegs(locRow,locRegStart+1:locRegEnd)=1;
%         
%         %Now set the next 6 EVs (12s) as rest
%         locRegStart=locRegEnd;
%         locRegEnd=locRegStart+6;
%         locRegs(4,locRegStart+1:locRegEnd)=1;
%         
%         %Now reset for next miniBlock
%         locRegStart=locRegEnd;
%         
%         
%     end
% end
% 
% 
% %And save the TRs
% cd ../mvpa_params
% save('pmLocRegs.mat','locRegs')
% save('pmBlockRegs.mat','locBlockR')
cd ../