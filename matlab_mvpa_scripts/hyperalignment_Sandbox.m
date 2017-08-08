%% Matlab Hyperalignment for ForceMem
%In this script, I'm going to load subject data one at a time.  Then I will
%do 2 things. The first, would be to concat them all and make the "blocks"
%represent each subject in order to do a K-fold between subject classifier
%analysis.  I can't do that until I have all EPI data in the same "space".
%Next I will do a between subject MVPA in hyperaligned space by recursively
%going from subject to subject to create the hyperaligned 

%First go from the scripts directory to wherever the master subject folders
%are
cd ../../
extension='.nii';
subjList=['2017061601','2017062101','2017062701','2017062801','2017070601'];

%Here, I'm going to load all subject data as 1 subject, and then perform
%MVPA by training on 4 subjects and testing on the left out subject.  I
%will also (to make it even more similar to hyperalignment) train on all
%subjects but leave out one block from one subject, and just test on that
%one left out subject block.  This is equivalent to between subject
%classification, without hyperalignment to get a baseline performance.
for subI=1:5
    subDir=['/forcemem_' subList(subI)];
    cd('mask');
    subj{subI} = load_spm_mask(subj,'vtMask','tempoccfusi_pHg_combined_epi_space.nii');

    for i=1:3
      index=num2str(i);
      raw_filenames{i+2} = ['Func/loc' index '/funcMNI' fextension]; %#ok<AGROW> 
    end
end


