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

poly_detrend(fds, polyord=1, chunks_attr='chunks')
zscore(fds, param_est=('targets','5'))

fds = fds[fds.sa.targets != '5']

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
