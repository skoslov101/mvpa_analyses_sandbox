#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Wed Aug  9 14:45:47 2017

@author: srk482-admin
"""

#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Wed Jul 12 15:24:28 2017

@author: srk482-admin
"""
def sensitivity_analysis_script(subjNum):
    from mvpa2.tutorial_suite import SampleAttributes, fmri_dataset, vstack, poly_detrend, zscore
    from mvpa2.tutorial_suite import SensitivityBasedFeatureSelection, OneWayAnova, FractionTailSelector
    from mvpa2.tutorial_suite import SMLR, FeatureSelectionClassifier, CrossValidation,NFoldPartitioner, maxofabs_sample
    from mvpa2.tutorial_suite import RepeatedMeasure, ChainNode, Splitter
    from mvpa2.tutorial_suite import map2nifti, MapOverlap
    import os as os
    import numpy as np
    
    
    subNum=subjNum
    dataPathName="/Users/srk482-admin/Documents/forcemem_mriDat/forcemem_%s" % subNum
    
    run_datasets=[]
    
    for runID in range(1,6):
        print"Starting analysis for subject " + subNum + " block " + str(runID)
        blockName="block%s" %runID
        bold_fname=os.path.join(dataPathName,'Func',blockName,'bold_dt_mcf_brain.nii')
        mask_fname=os.path.join(dataPathName,'mask','wholeBrain_binary.nii')
        
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
    
    ## Now break down the classifier a bit further by looking at the sensitivity analysis
    sensana = fclf.get_sensitivity_analyzer(postproc=maxofabs_sample())
    sens_cv=RepeatedMeasure(sensana,ChainNode((NFoldPartitioner(),
                                               Splitter('partitions', attr_values=(1,)))))
    sens1=sens_cv(fds)
    sens_comb = sens1.get_mapped(maxofabs_sample())
    
    #Output that voxel map
    savePath=os.path.join(dataPathName,'mvpa_results','pyMVPA_results')
    if not os.path.exists(savePath):
        os.makedirs(savePath)
    
    saveFname=os.path.join(savePath,'sensitivityMap.nii.gz')    
    map2nifti(fds,sens_comb).to_filename(saveFname)
    
    
    #We can look at the overlap of voxels from each of the 5 cross validated runs
    ov = MapOverlap()
    overFrac=ov(sens1.samples >0)
    
    return fds


subList=['2017061601','2017062701','2017062101','2017070601']
for subI in subList:
    sensitivity_analysis_script(subI)
