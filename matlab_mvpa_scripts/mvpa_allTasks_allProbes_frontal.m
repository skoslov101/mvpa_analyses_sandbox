%% ForceMemRI PM Task - using all training
%In this script I use the TRs from the og loc, localizer and N-1 blocks to
%train the classifier, then test on leave 1 out.
clear
cd ..


% for blockI=1:5
    %Extension for neural data
    fextension='.nii';
    % start by creating an empty subj structure
    subj = init_subj('ForceMemfMRI','2017062801');

    %% Create the mask for neural decoding
    cd('mask');
    subj = load_spm_mask(subj,'frontalMask','both_aPFC_mask.nii');

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
    subj = load_spm_pattern(subj,'epi','frontalMask',raw_filenames);

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

    %Shift regressors two TRs to account (roughly) for the hemodynamic lag
    subj = shift_regressors(subj,'conds','runs',2); 
    subj = create_norest_sel(subj,'conds_sh2');

    %% PRE-PROCESSING - z-scoring in time and no-peeking anova
    % we want to z-score the EPI data (called 'epi'),
    % individually on each run (using the 'runs' selectors)
    subj = zscore_runs(subj,'epi','runs','actives_selname', 'conds_sh2_norest');
    subj = create_xvalid_indices(subj,'runs','actives_selname','conds_sh2_norest');

    % run the anova multiple times, separately for each iteration,
    % using the selector indices created above
    [subj] = feature_select(subj,'epi_z','conds_sh2','runs_xval');
    summarize(subj)

    %% Run Classifier
    % set some basic arguments for a backprop classifier
    class_args.train_funct_name = 'train_L2_RLR';
    class_args.test_funct_name = 'test_L2_RLR';
    class_args.penalty=50;


    % now, run the classification multiple times, training and testing
    % on different subsets of the data on each iteration
    [subj, results] = cross_validation(subj,'epi_z','conds_sh2','runs_xval','epi_z_thresh0.05',class_args);

    cd mvpa_results

    pmAll.subj=subj;
    pmAll.results=results;
    
    fileName=['frontal_AllRegs_allProbesTrain.mat'];
    save(fileName,'pmAll');
    clear
    cd ..
% end


