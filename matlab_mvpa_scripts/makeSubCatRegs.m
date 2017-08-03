%% Create Subcategory RegArrays
%This code will take the behavioral data for ForceMemRI and create the
%EVs/Regs for doing MVPA within the Princeton toolbox.  The categories in
%this analysis go one step past the previous analysis, in that I want to
%see if we can get any sub-category specificity.  So we are going to have 6
%categories, male, female, indoor, outdoor, noPM, and rest
clear
%Overall:
%Row 1 = Male Face
%Row 2 = Female Face
%Row 3 = Indoor Scene
%Row 4 = Outdoor Scene
%Row 5 = NoPM
%Row 6 = Rest

%First, I want to train within the PM localizer as a sanity check.
%If those aren't working, then I probably won't be able to do this with the
%PM task either.

%This script assumes you are starting in the forcemem_mriDat locally.
%However, it should work anywhere that this main file is placed as long as
%subfolders are named in the same way
curDir=pwd;

subNum=2017070601;
subInit='AL';

locDir=['forcemem_' mat2str(subNum) '/behav/loc'];
cd(locDir)

%% PM Localizer EV Creator

%load the file - if you need to cycle through blocks add a block script,
%else just use the number 3

locBlocks=3;
locTRs=102;
locBlockLen=66;
miniBlockL=11;
miniBlockN=6;

locRegs=zeros(6,locTRs*locBlocks);
locBlockR=zeros(1,locTRs*locBlocks);
locMaster=zeros(6,locTRs*locBlocks);


locFile=['fm_fmri_loc_' mat2str(subNum) '_' subInit '_1_3.mat'];
load(locFile)

%I can do some complicated thing to get the TRs, but because everything
%lines up so nicely for this experiment, it is really easy to just grab the
%category for that mini block and put the next 11 TRs in that row, and then
%the next 6 TRs (12s) in the Rest column.

locRegStart=0;
locProbeN=1;
for locBlockI=1:locBlocks
    
    
    locBlockR(1,(locBlockI-1)*locTRs+1:(locBlockI-1)*locTRs+locTRs)=locBlockI;
    
    for miniBlockI=1:miniBlockN
        
        for probeI=1:miniBlockL
            % The coding was faces=1, scenes=2;
            % indoor/Male=2; Outdoor/Female=1
            if Data.locDat{(locBlockI-1)*locBlockLen+(miniBlockI-1)*miniBlockL+probeI,2}==1 && ...
                Data.locDat{(locBlockI-1)*locBlockLen+(miniBlockI-1)*miniBlockL+probeI,3}==1
                locRow=2;
            elseif Data.locDat{(locBlockI-1)*locBlockLen+(miniBlockI-1)*miniBlockL+probeI,2}==1 && ...
                Data.locDat{(locBlockI-1)*locBlockLen+(miniBlockI-1)*miniBlockL+probeI,3}==2
                locRow=1;
            elseif Data.locDat{(locBlockI-1)*locBlockLen+(miniBlockI-1)*miniBlockL+probeI,2}==2 && ...
                Data.locDat{(locBlockI-1)*locBlockLen+(miniBlockI-1)*miniBlockL+probeI,3}==1
                locRow=4;
            elseif Data.locDat{(locBlockI-1)*locBlockLen+(miniBlockI-1)*miniBlockL+probeI,2}==2 && ...
                Data.locDat{(locBlockI-1)*locBlockLen+(miniBlockI-1)*miniBlockL+probeI,3}==2
                locRow=3;
            end
            locRegs(locRow,locProbeN)=1;
            locProbeN=locProbeN+1;
        end
%         locRegEnd=locRegStart+11;
        
        
        %Now set the next 6 EVs (12s) as rest
        for restI=1:6
            locRegs(6,locProbeN)=1;
            locProbeN=locProbeN+1;
        end
%         locRegStart=locRegEnd;
%         locRegEnd=locRegStart+6;
%         locRegs(6,locRegStart+1:locRegEnd)=1;
        
        %Now reset for next miniBlock
%         locRegStart=locRegEnd;
        
        
    end
end


%And save the TRs
cd ../mvpa_params
save('subCat_pmLocRegs.mat','locRegs')
save('subCat_pmBlockRegs.mat','locBlockR')