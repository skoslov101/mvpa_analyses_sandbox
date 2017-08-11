#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Wed Aug  9 15:48:46 2017

@author: srk482-admin

In this script, I want to move the t1 space brain mask images created during preprocessing
and make epi-space masks for loading in data.  From preprocessing we already have all of the parts,
(even the inverse warp) we just have to run it
"""

 
def brainMask2epi(subjI):
    print('running brain mask creation')
    import os
    subNum=str(subjI)
    dataPathName="/Users/srk482-admin/Documents/forcemem_mriDat/forcemem_%s" % subNum
    
    std2t1_warp=os.path.join(dataPathName,'Func/avg_func_ref/MNI2T1')
    invWarp=os.path.join(dataPathName,'Func/avg_func_ref/T12fRI')
    refFunc=os.path.join(dataPathName,'Func/avg_func_ref/bold_avg_mcf_brain.nii')
    brainMask=os.path.join('/Users/srk482-admin/Documents/forcemem_mriDat/standards','MNI152_T1_1mm_brain.nii.gz')
    outFile=os.path.join(dataPathName,'mask/wholeBrain.nii.gz')
    
    warping = ('applywarp --ref=' + refFunc
           + ' --in=' + brainMask
           + ' --warp=' + std2t1_warp
           + ' --postmat=' + invWarp
           + ' --out=' + outFile)
    
    run_bash(warping)
    
def run_bash(cmd):
    import os
    os.system(cmd)

subjN=2017070601
brainMask2epi(subjN)
    

    

    
    