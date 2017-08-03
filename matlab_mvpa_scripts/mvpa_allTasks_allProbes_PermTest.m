%% ForceMemRI PM Task - using all training
%In this script I use the TRs from the og loc, localizer and N-1 blocks to
%train the classifier, then test on leave 1 out.
clear
cd ..

subjID='2017062801';

% for blockI=1:5
    %Extension for neural data
fextension='.nii';
% start by creating an empty subj structure
subj = init_subj('ForceMemfMRI',subjID);

%% Create the mask for neural decoding
cd('mask');
subj = load_spm_mask(subj,'vtMask','tempoccfusi_pHg_combined_epi_space.nii');

%% Load in the function files for the OG loc task
cd ..
%For this version, we need to have the oglocalizer, the pmlocalizer, adn
%the main pm task loaded in.  I'm going to og then pmloc then pmtask
%ogLoc
for i=1:2
  index=num2str(i);
  raw_filenames{i} = ['Func/ogloc' index '/bold_dt_mcf_brain' fextension]; %#ok<AGROW> 
end
%pmLoc
for i=1:3
  index=num2str(i);
  raw_filenames{i+2} = ['Func/loc' index '/bold_dt_mcf_brain' fextension]; %#ok<AGROW> 
end
%pmTask
for i=1:5 %3 blocks of the pm localizer
    index=num2str(i);
    raw_filenames{i+5} = ['Func/block' index '/bold_dt_mcf_brain' fextension]; %#ok<AGROW>
end
%Load the bold using the mask provided earlier
subj = load_spm_pattern(subj,'epi','vtMask',raw_filenames);

%% Set up the regressors
%Now the regressors are going to work differently for this code.
%Essentially, I'm going to treat all of the localizer stuff as the same
%block 1.  Then, for each iteration of this code, the block of interest
%will have all probes included, while each other block will only have easy
%probes included (that's because we only want easy probes for training).

%first load and concat the ogLoc params with pmLoc
load('behav/mvpa_params/ogLocRegs.mat');
load('behav/mvpa_params/pmLocRegs.mat');
allLocsRegs=[ogRegs,locRegs];
allBlockRegs=ones(1,size(allLocsRegs,2));

%Next add in the easy probes of all blocks but blockI
load('behav/mvpa_params/pmTaskEasyProbes.mat');
load('behav/mvpa_params/pmTaskRegs.mat');

%     allRegs=[allLocsRegs,pmTaskReg];
allBlocks=[repmat(1,1,84), repmat(2,1,84), repmat(3,1,102), repmat(4,1,102), repmat(5,1,102), repmat(6,1,306), repmat(7,1,306), repmat(8,1,306), repmat(9,1,306),repmat(10,1,306)];


%     if blockI==1
%         pmRegsAll=[pmTaskReg(:,1:306),easyRegs(:,307:1530)];
%     elseif blockI==2
%         pmRegsAll=[easyRegs(:,1:306),pmTaskReg(:,307:612),easyRegs(:,613:1530)];
%     elseif blockI==3
%         pmRegsAll=[easyRegs(:,1:612),pmTaskReg(:,613:918),easyRegs(:,919:1530)];
%     elseif blockI==4
%         pmRegsAll=[easyRegs(:,1:918),pmTaskReg(:,919:1224),easyRegs(:,1225:1530)];
%     else
%         pmRegsAll=[easyRegs(:,1:1224),pmTaskReg(:,1225:1530)];
%     end
pmRegsAll=pmTaskReg;
allRegs=[allLocsRegs,pmRegsAll];
%     allBlocks=[allBlockRegs,pmBlocks];

%Set up the regressor rows/names to be filled in
subj = init_object(subj,'regressors','conds');
subj = set_mat(subj,'regressors','conds',allRegs);




condnames = {'face','scene','noTarget','rest'};
subj = set_objfield(subj,'regressors','conds','condnames',condnames);

subj = init_object(subj,'selector','runs');
subj = set_mat(subj,'selector','runs',allBlocks);

%Now I want to scramble all non-zero regressor numbers

%Shift regressors two TRs to account (roughly) for the hemodynamic lag
subj = shift_regressors(subj,'conds','runs',2); 
subj = create_norest_sel(subj,'conds_sh2');

%% PRE-PROCESSING - z-scoring in time and no-peeking anova
% we want to z-score the EPI data (called 'epi'),
% individually on each run (using the 'runs' selectors)
subj = zscore_runs(subj,'epi','runs','actives_selname', 'conds_sh2_norest');
subj = create_xvalid_indices(subj,'runs','actives_selname','conds_sh2_norest');

%% Run Classifier
% set some basic arguments for a backprop classifier
class_args.train_funct_name = 'train_L2_RLR';
class_args.test_funct_name = 'test_L2_RLR';
class_args.penalty=50;

overallAcc=[];
locTRs=474; %This is the amount of localizer TRs so that I can leave out the correct TRs for train/testing permutations
totalIter=250;
thisIter=0;

%Between this and feature select I want to randomize all blocks but 1 pm
%block and test on that
for blockRandI=1:5
    %I'm going to let each pm task block be the testing block 50 times
    for iterI=1:50
        thisIter=thisIter+1;
        disp(['Iteration ' mat2str(thisIter) ' of ' mat2str(totalIter)]);
        
        
        %Now we scramble the regressors for every block but the chosen one.
        % This takes about .02s
        
        %I only want to look at the  non-held out block for mixing
        %regressors
        
%         tic
        [~,regX]=find(subj.regressors{2}.mat(:,:)==1);
        
        if blockRandI==1
            regX=regX(regX<locTRs | regX>locTRs+306);
        elseif blockRandI==2
            regX=regX(regX<locTRs+306 | regX>locTRs+612);
        elseif blockRandI==3
            regX=regX(regX<locTRs+612 | regX>locTRs+918);
        elseif blockRandI==4
            regX=regX(regX<locTRs+918 | regX>locTRs+1224);
        else
            regX=regX(regX<locTRs+1224);
        end
        
        for regI=regX
            subj.regressors{2}.mat(:,regI)=Shuffle(subj.regressors{2}.mat(:,regI));
        end
%         toc
            
        % run the anova multiple times, separately for each iteration,
        % using the selector indices created above
        [subj] = feature_select(subj,'epi_z','conds_sh2','runs_xval');

        % now, run the classification multiple times, training and testing
        % on different subsets of the data on each iteration
        [subj, results] = cross_validation(subj,'epi_z','conds_sh2','runs_xval','epi_z_thresh0.05',class_args);

        %Record the classifier accuracy in an array
        overallAcc=[overallAcc;results.iterations(blockRandI+5).perfmet.perf];
    
        subj = remove_group(subj,'mask','epi_z_thresh0.05');
        subj = remove_group(subj,'pattern','epi_z_anova');
    end
end

h1=figure;
hist(overallAcc,30);

saveDir=['~/Documents/forcemem_mriDat/forcemem_' subjID '/mvpa_results'];
save([saveDir '/permTest_summary.m'],'overallAcc');
saveas(h1,[saveDir '/permTest_summary_hist.png']);

%


% subj = remove_group(subj,'selector','runs_xval');


