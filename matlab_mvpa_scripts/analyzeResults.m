%% Analyze the MVPA output from the Princeton MVPA toolbox
% This will analyze the output for my ForceMemRI subjects that I ran MVPA
% through the Princeton Toolbox on.  Particularly, this is for the version
% where I trained on all Localizers (PM and OG) and Easy probes of the PM
% task (n-1 blocks) and tested on all real probes of the left out block.

%The way this was run, was that I ran a N-loop for each block where each
%iteration was specific to train on all but that block's easy
%probes/localizer and then test on that block's all probes.  The result is
%that I have 5 result files, each one specific to a block of results that I
%care about.  File "block1" = block 1 -> Iteration 6. File "block2" =
%block2 -> iteration 7, etc...

%The classifier is set up so that 1=face, 2=scene, 3=no target (nonPM + OG
%training), 4 = rest.  So in the results..acts array, those correspond to
%evidence in each row.

%First get the subject number and number of blocks
subNum=2017062801;
blockN=5;

%First we need to load the pmMaster file that will have the trialType and
%Difficulty information for each Probe/TR (probes are 2s so they match TRs)
%That file is then loaded in as a variable called 'pmMaster'
cd ..
masterFile=[pwd '/behav/mvpa_params/pmTaskMaster.mat'];
load(masterFile);

%make blank allArray to be filled as we go through each block
allArray=[];

for blockI=1:blockN
    iterN=blockI+5; %5 loc blocks first
    
    
    %load the pmResult file
    resultFile=[pwd '/mvpa_results/pmAllRegs_allProbesTrain_block' mat2str(blockI) '.mat'];
    load(resultFile)
    
    %extract only real TRs from the current block of interest
    pmX=find(pmMaster(1,:)==1);
    masterProbes=pmMaster(:,pmX);
    
    %Separate the rest probes to match the TR array
    nonRestX=find(pmAll.results.iterations(iterN).perfmet.desireds(1,:)<4);
    %now we want just those TRs from the results array
    nonRest=pmAll.results.iterations(iterN).acts(:,nonRestX);
    
    %Non rest and masterProbes should be the same length, so we can combine
    %them.
    resArray=[nonRest;masterProbes];
    
    allArray=[allArray,resArray];
    
    clear pmAll
    clear resArray
    
    %Now average the voxel heatmaps to use those
    
    
end

allArray=allArray.';

for arI=1:size(allArray,1)
    if allArray(arI,9)==1
        allArray(arI,11)=allArray(arI,1)-allArray(arI,2); %difference for face - scene
        allArray(arI,12)=allArray(arI,1); %raw face classifier evidence
    elseif allArray(arI,9)==2
        allArray(arI,11)=allArray(arI,2)-allArray(arI,1); %difference for scene - face
        allArray(arI,12)=allArray(arI,2); %raw scene classifier evidence
    elseif allArray(arI,9)==3
        allArray(arI,11)=NaN; %difference for scene - face
        allArray(arI,12)=allArray(arI,3); %raw scene classifier evidence
    end
end


%Header row=
%faceEV,sceneEV,noTargEV,restEV,block,trialN,probeN,trialType,pmType,probeDiff,diffEV,rawTargEV



    
