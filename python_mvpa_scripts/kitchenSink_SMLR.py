#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Wed Jul 12 15:24:28 2017

@author: srk482-admin
"""

from mvpa2.tutorial_suite import *
import os as os
import numpy as np


subNum="2017062801"
dataPathName="/Users/srk482-admin/Documents/forcemem_mriDat/forcemem_%s" % subNum

run_datasets=[]

for runID in range(1,6):
    blockName="block%s" %runID
    bold_fname=os.path.join(dataPathName,'Func',blockName,'bold_dt_mcf_brain.nii')
    mask_fname=os.path.join(dataPathName,'mask','wholeBrain.nii')
    
    attr_block="block%s_attr.txt" %runID
    attr_fname=os.path.join(dataPathName,'behav','pyMVPA_params',attr_block)
    attr = SampleAttributes(attr_fname)
    
    run_ds=fmri_dataset(samples=bold_fname,targets=attr.targets,chunks=attr.chunks,mask=mask_fname)
    
    run_datasets.append(run_ds)
    
fds=vstack(run_datasets,a=0)

print fds.summary()
fds = fds[fds.sa.targets != '5']
poly_detrend(fds, polyord=1, chunks_attr='chunks')
zscore(fds)
#zscore(fds, param_est=('targets','5'))



fsel = SensitivityBasedFeatureSelection(
        OneWayAnova(),
        FractionTailSelector(0.05, mode='select', tail='upper'))


clf = SMLR()
fclf=FeatureSelectionClassifier(clf,fsel)
cvte2=CrossValidation(fclf,NFoldPartitioner(),errorfx=lambda p, t: np.mean(p ==t), enable_ca=['stats','training_stats','estimates'])
cv_results2=cvte2(fds)


cvte2.ca.stats.sets[0][0]  #This is how you look at targets
cvte2.ca.stats.sets[0][1]  #This is how you look at category of predictions
cvte2.ca.stats.sets[0][2]   #Probability estimates for the classifier for each category by TR

## Now break down the classifier a bit further by looking at the sensitivity analysis
sensana = fclf.get_sensitivity_analyzer(postproc=maxofabs_sample())
sens_cv=RepeatedMeasure(sensana,ChainNode((NFoldPartitioner(),
                                           Splitter('partitions', attr_values=(1,)))))
sens1=sens_cv(fds)
sens_comb = sens1.get_mapped(maxofabs_sample())

#Output that voxel map
map2nifti(fds,sens_comb).to_filename('sensMap.nii.gz')


## Also, we can do a searchlight across the whole brain, to see where voxels are significantly above chance at decoding...
searchlight1=sphere_searchlight(cvte2, radius=5, postproc=mean_sample())
searchRes1=searchlight1(fds)

sphere_Score=searchRes1.samples[0]
sRes_mean=np.mean(searchRes1)
sRes_std=np.std(searchRes1)
chance_level=1.0/len(fds.uniquetargets) #chance is .25 (empirically it is .251), so an error rate greater than
#than .75 would be greater than chance.  that is what we are computing here

#Get the proportion of voxels that predict above chance when taking into account the std. deviation
frac_lower=np.round(np.mean(sphere_Score < chance_level + 2*sRes_std),3)

#Now let's export that map to something we can project onto a brain
map2nifti(fds,sphere_errors).to_filename('searchlight_predAcc.nii.gz')


sphere_Score2=np.copy(sphere_Score)
for voxI in range(0,len(sphere_Score)):
    if sphere_Score[voxI]>chance_level+ 2*sRes_std:
        sphere_Score2[voxI]=sphere_Score[voxI]
    else:
        sphere_Score2[voxI]=0
map2nifti(fds,sphere_Score2).to_filename('maskedSigVox.nii.gz')


#We can look at the overlap of voxels from each of the 5 cross validated runs
ov = MapOverlap()
overFrac=ov(sens1.samples >0)
