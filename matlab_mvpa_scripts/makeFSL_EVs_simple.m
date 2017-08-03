%% FSL EV Generator (PM > nonPM)
%In this script, I'm going to do a basic GLM model EV creator.  The events
%will be Target Introduction (3s Target Intro - not the 1s ISI), Probes
%(for PM it will be probe1:probeL-1 and for PM it will be probe1:probeL),
%and feedback on trial (2s at end of trial).  Rest (6s) after each trial
%will not be modeled but incorporated into noise.

%This script assumes you are starting in the forcemem_mriDat locally.
%However, it should work anywhere that this main file is placed as long as
%subfolders are named in the same way
curDir=pwd;

%% PM Task EV generator
%First load the original data file
subN=2017062701;
subInit='BV';


fileName=['forceMem_fMRI_v1_' mat2str(subN) '_' subInit '_5.mat'];
fileDir=['forcemem_' mat2str(subN)];

cd(fileDir)
cd behav/pmTask
load(fileName);

cd ../../fsl_analysis/EVs


%Experiment params
trLen=306;
blockN=5;
trialN=20;




for blockI=1:blockN
    
    %Separate EVs for PM and non PM trials
    nonPMRow=0;
    pmRow=0;
    pmProbeRow=0;
    npmProbeRow=0;

    blockDir=['block' mat2str(blockI)];
    cd(blockDir);
    
    for trialI=1:trialN
        probeL=Data.BlockTimings{blockI}.Trial{trialI}.trialLength; %Trial length
        pmType=Data.BlockTimings{blockI}.Trial{trialI}.pmType; %pm Type
        

        
        if pmType<=2
            pmRow=pmRow+1;
            pm_targetEVs(pmRow,1)=floor(Data.BlockTimings{blockI}.Trial{trialI}.pmTargOnset); %Onset of PM target
            pm_targetEVs(pmRow,2)=3; %3s for target presentation
            pm_targetEVs(pmRow,3)=1; %Weight of EV is 1
            
            for probeI=1:(probeL-1)
                pmProbeRow=pmProbeRow+1;
                pm_probeEVs(pmProbeRow,1)=floor(Data.BlockTimings{blockI}.Trial{trialI}.probeTiming{probeI,5}); %onset of first probe
                pm_probeEVs(pmProbeRow,2)=2; %2s per each probe, not including the last one
                pm_probeEVs(pmProbeRow,3)=1; %Weight of each EV is 1
            end
            
            %Now EVs for when that probe did come up
            pmProbeEvent(pmRow,1)=floor(Data.BlockTimings{blockI}.Trial{trialI}.probeTiming{probeL,5});
            pmProbeEvent(pmRow,2)=2;
            pmProbeEvent(pmRow,3)=1;
            
            feedbackEVs(pmRow,1)=floor(Data.BlockTimings{blockI}.Trial{trialI}.trialFeedbackTiming); %Start of trialFeedback
            feedbackEVs(pmRow,2)=2; %2s for PM feedback
            feedbackEVs(pmRow,3)=1; %weighting =1
        else
            nonPMRow=nonPMRow+1;
            
            Nonpm_targetEVs(nonPMRow,1)=floor(Data.BlockTimings{blockI}.Trial{trialI}.pmTargOnset); %Onset of PM target
            Nonpm_targetEVs(nonPMRow,2)=3; %3s for target presentation
            Nonpm_targetEVs(nonPMRow,3)=1; %Weight of EV is 1
            for probeI=1:probeL
                npmProbeRow=npmProbeRow+1;
                Nonpm_probeEVs(npmProbeRow,1)=floor(Data.BlockTimings{blockI}.Trial{trialI}.probeTiming{probeI,5}); %onset of first probe
                Nonpm_probeEVs(npmProbeRow,2)=2; %2s per each probe, this time including the last one
                Nonpm_probeEVs(npmProbeRow,3)=1; %Weight of each EV is 1
            end
            
            Nonpm_feedbackEVs(nonPMRow,1)=floor(Data.BlockTimings{blockI}.Trial{trialI}.trialFeedbackTiming); %Start of trialFeedback
            Nonpm_feedbackEVs(nonPMRow,2)=2; %2s for PM feedback
            Nonpm_feedbackEVs(nonPMRow,3)=1; %weighting =1
        end
        
        
        
    end
        
    pmtargFname='pm_targetEVs.txt';
    pmprobeFname='pm_probeEVs.txt';
    pmfeedbackFname='pm_feedbackEVs.txt';
    pmProbeFname='pm_targProbeEVs.txt';
    
    npmtargFname='npm_targetEVs.txt';
    npmprobeFname='npm_probeEVs.txt';
    npmfeedbackFname='npm_feedbackEVs.txt';
    
    % SAve the target EVs
    %PM Targ
    fileID=fopen(pmtargFname,'w');
    formatSpec='%d %d %d\n';
    [nrows,ncols]=size(pm_targetEVs);
    for rowI=1:nrows
        fprintf(fileID,formatSpec, pm_targetEVs(rowI,:));
    end
    fclose(fileID); 
    
    %NPM Targ
    fileID=fopen(npmtargFname,'w');
    formatSpec='%d %d %d\n';
    [nrows,ncols]=size(Nonpm_targetEVs);
    for rowI=1:nrows
        fprintf(fileID,formatSpec, Nonpm_targetEVs(rowI,:));
    end
    fclose(fileID);
    
    % SAve the probe EVs
    %PM Probe
    fileID=fopen(pmprobeFname,'w');
    formatSpec='%d %d %d\n';
    [nrows,ncols]=size(pm_probeEVs);
    for rowI=1:nrows
        fprintf(fileID,formatSpec, pm_probeEVs(rowI,:));
    end
    fclose(fileID);  

    %NPM Probe
    fileID=fopen(npmprobeFname,'w');
    formatSpec='%d %d %d\n';
    [nrows,ncols]=size(Nonpm_probeEVs);
    for rowI=1:nrows
        fprintf(fileID,formatSpec, Nonpm_probeEVs(rowI,:));
    end
    fclose(fileID);
    
    % SAve the feedback EVs
    fileID=fopen(pmfeedbackFname,'w');
    formatSpec='%d %d %d\n';
    [nrows,ncols]=size(feedbackEVs);
    for rowI=1:nrows
        fprintf(fileID,formatSpec, feedbackEVs(rowI,:));
    end
    fclose(fileID);  
    
    % SAve the feedback EVs
    fileID=fopen(npmfeedbackFname,'w');
    formatSpec='%d %d %d\n';
    [nrows,ncols]=size(Nonpm_feedbackEVs);
    for rowI=1:nrows
        fprintf(fileID,formatSpec, Nonpm_feedbackEVs(rowI,:));
    end
    fclose(fileID); 
    
    fileID=fopen(pmProbeFname,'w');
    formatSpec='%d %d %d\n';
    [nrows,ncols]=size(pmProbeEvent);
    for rowI=1:nrows
        fprintf(fileID,formatSpec, pmProbeEvent(rowI,:));
    end
    fclose(fileID); 

    %Done saving
    cd ..
    
    %Clear after each block so we can save each one at a time
    pm_targetEVs=[];
    pm_probeEVs=[];
    feedbackEVs=[];
    pmProbeEvet=[];
    
    Nonpm_targetEVs=[];
    Nonpm_probeEVs=[];
    Nonpm_feedbackEVs=[];
    
end