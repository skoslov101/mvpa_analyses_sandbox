#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Wed Jul 19 16:32:12 2017

@author: srk482-admin
"""

## Full pipeline for Preprocessing and Level 1 Analysis
#Will attempt to roll into PYMVPA


#### Step 1 Import all necessary modules
from os import chdir,getcwd,listdir
from os.path import join as opj
import numpy as np
from nipype.interfaces.afni import Despike
from nipype.interfaces.freesurfer import (BBRegister, ApplyVolTransform,
                                          Binarize, MRIConvert, FSCommand)
from nipype.interfaces.spm import (SliceTiming, Realign, Smooth, Level1Design,
                                   EstimateModel, EstimateContrast)
from nipype.interfaces.utility import Function, IdentityInterface
from nipype.interfaces.io import FreeSurferSource, SelectFiles, DataSink
from nipype.algorithms.rapidart import ArtifactDetect
from nipype.algorithms.misc import TSNR, Gunzip
from nipype.algorithms.modelgen import SpecifySPMModel
from nipype.pipeline.engine import Workflow, Node, MapNode




# MATLAB - Specify path to current SPM and the MATLAB's default mode
from nipype.interfaces.matlab import MatlabCommand
MatlabCommand.set_default_paths('/Users/srk482-admin/spm12')
MatlabCommand.set_default_matlab_cmd("matlab -nodesktop -nosplash")

# FreeSurfer - Specify the location of the freesurfer folder
fs_dir = '/Users/srk482-admin/Documents/forcemem_mriDat/nipype_tutorial/freesurfer'
FSCommand.set_default_subjects_dir(fs_dir)


##Define Experiment Parameters
experiment_dir = '/Users/srk482-admin/Documents/forcemem_mriDat/nipype_tutorial'          # location of experiment folder
data_dir='/Users/srk482-admin/Documents/forcemem_mriDat/'
subject_list = ['2017062801', '2017070601', '2017062701','2017062101']    
block_list=['block1','block2','block3','block4','block5']
                 # list of subject identifiers
output_dir = 'output_fMRI_example_1st'        # name of 1st-level output folder
working_dir = 'workingdir_fMRI_example_1st'   # name of 1st-level working directory

number_of_slices = 48                         # number of slices in volume
TR = 2.0                                      # time repetition of volume
fwhm_size = 6                                 # size of FWHM in mm


# Despike - Removes 'spikes' from the 3D+time input dataset
despike = MapNode(Despike(outputtype='NIFTI'),
                  name="despike", iterfield=['in_file'])

# Slicetiming - correct for slice wise acquisition
interleaved_order = range(1,number_of_slices+1,2) + range(2,number_of_slices+1,2)
sliceTiming = Node(SliceTiming(num_slices=number_of_slices,
                               time_repetition=TR,
                               time_acquisition=TR-TR/number_of_slices,
                               slice_order=interleaved_order,
                               ref_slice=2),
                   name="sliceTiming")

# Realign - correct for motion
realign = Node(Realign(register_to_mean=True),
               name="realign")

# TSNR - remove polynomials 2nd order
tsnr = MapNode(TSNR(regress_poly=2),
               name='tsnr', iterfield=['in_file'])

# Artifact Detection - determine which of the images in the functional series
#   are outliers. This is based on deviation in intensity or movement.
art = Node(ArtifactDetect(norm_threshold=1,
                          zintensity_threshold=3,
                          mask_type='file',
                          parameter_source='SPM',
                          use_differences=[True, False]),
           name="art")

# Gunzip - unzip functional
gunzip = MapNode(Gunzip(), name="gunzip", iterfield=['in_file'])

# Smooth - to smooth the images with a given kernel
#I will not be using this if I'm doing MVPA analysis, but may use it for GLM analysis
smooth = Node(Smooth(fwhm=fwhm_size),
              name="smooth")

# FreeSurferSource - Data grabber specific for FreeSurfer data
fssource = Node(FreeSurferSource(subjects_dir=fs_dir),
                run_without_submitting=True,
                name='fssource')

# BBRegister - coregister a volume to the Freesurfer anatomical
bbregister = Node(BBRegister(init='header',
                             contrast_type='t2',
                             out_fsl_file=True),
                  name='bbregister')

# Volume Transformation - transform the brainmask into functional space
applyVolTrans = Node(ApplyVolTransform(inverse=True),
                     name='applyVolTrans')

# Binarize -  binarize and dilate an image to create a brainmask
binarize = Node(Binarize(min=0.5,
                         dilate=1,
                         out_type='nii'),
                name='binarize')

### Connect the workflow
# Create a preprocessing workflow
preproc = Workflow(name='preproc')

# Connect all components of the preprocessing workflow
preproc.connect([(despike, sliceTiming, [('out_file', 'in_files')]),
                 (sliceTiming, realign, [('timecorrected_files', 'in_files')]),
                 (realign, tsnr, [('realigned_files', 'in_file')]),
                 (tsnr, art, [('detrended_file', 'realigned_files')]),
                 (realign, art, [('mean_image', 'mask_file'),
                                 ('realignment_parameters',
                                  'realignment_parameters')]),
                 (tsnr, smooth, [('detrended_file', 'in_files')]),
                 (realign, bbregister, [('mean_image', 'source_file')]),
                 (fssource, applyVolTrans, [('brainmask', 'target_file')]),
                 (bbregister, applyVolTrans, [('out_reg_file', 'reg_file')]),
                 (realign, applyVolTrans, [('mean_image', 'source_file')]),
                 (applyVolTrans, binarize, [('transformed_file', 'in_file')]),
                 ])


### First Level Pipeline
# SpecifyModel - Generates SPM-specific Model
modelspec = Node(SpecifySPMModel(concatenate_runs=False,
                                 input_units='secs',
                                 output_units='secs',
                                 time_repetition=TR,
                                 high_pass_filter_cutoff=128),
                 name="modelspec")

# Level1Design - Generates an SPM design matrix
level1design = Node(Level1Design(bases={'hrf': {'derivs': [0, 0]}},
                                 timing_units='secs',
                                 interscan_interval=TR,
                                 model_serial_correlations='AR(1)'),
                    name="level1design")

# EstimateModel - estimate the parameters of the model
level1estimate = Node(EstimateModel(estimation_method={'Classical': 1}),
                      name="level1estimate")

# EstimateContrast - estimates contrasts
conestimate = Node(EstimateContrast(), name="conestimate")

# Volume Transformation - transform contrasts into anatomical space
applyVolReg = MapNode(ApplyVolTransform(fs_target=True),
                      name='applyVolReg',
                      iterfield=['source_file'])

# MRIConvert - to gzip output files
mriconvert = MapNode(MRIConvert(out_type='niigz'),
                     name='mriconvert',
                     iterfield=['in_file'])

# Initiation of the 1st-level analysis workflow
l1analysis = Workflow(name='l1analysis')

# Connect up the 1st-level analysis components
l1analysis.connect([(modelspec, level1design, [('session_info',
                                                'session_info')]),
                    (level1design, level1estimate, [('spm_mat_file',
                                                     'spm_mat_file')]),
                    (level1estimate, conestimate, [('spm_mat_file',
                                                    'spm_mat_file'),
                                                   ('beta_images',
                                                    'beta_images'),
                                                   ('residual_image',
                                                    'residual_image')]),
                    (conestimate, applyVolReg, [('con_images',
                                                 'source_file')]),
                    (applyVolReg, mriconvert, [('transformed_file',
                                                'in_file')]),
                    ])

metaflow = Workflow(name='metaflow')
metaflow.base_dir = opj(experiment_dir, working_dir)

metaflow.connect([(preproc, l1analysis, [('realign.realignment_parameters',
                                          'modelspec.realignment_parameters'),
                                         ('smooth.smoothed_files',
                                          'modelspec.functional_runs'),
                                         ('art.outlier_files',
                                          'modelspec.outlier_files'),
                                         ('binarize.binary_file',
                                          'level1design.mask_image'),
                                         ('bbregister.out_reg_file',
                                          'applyVolReg.reg_file'),
                                         ]),
                  ])
                                         
# Condition names
condition_names = ['pmTarget','pmProbe','pmFeedback','pmTargProbe','nonPMtarget',
                   'nonPMprobes', 'nonPMfeedback']

# Contrasts
cont01 = ['pm',   'T', condition_names, [1, 1, 1, 1, 0, 0, 0]]
cont02 = ['npm',   'T', condition_names, [0, 0, 0, 0, 1, 1, 1]]
cont03 = ['pm > npm', 'T', condition_names, [1, 1, 1, 1, -1, -1, -1]]
cont04 = ['pmProbe > npmProbe','T', condition_names, [0,1,0,0,0,-1,0]]
cont05 = ['pmTarget > npmTarget','T', condition_names, [1,0,0,0,-1,0,0]]
cont06 = ['pmFeed > npmFeed','T', condition_names, [0,0,1,0,0,0,-1]]
cont07 = ['Cond vs zero', 'F', [cont01, cont02]]


contrast_list = [cont01, cont02, cont03, cont04, cont05, cont06, cont07]

from nipype.interfaces.base import Bunch

def get_subject_info(subject_id):
    import numpy as np
    from nipype.interfaces.base import Bunch
    
    # Condition names
    condition_names = ['pmTarget','pmProbe','pmFeedback','pmTargProbe','nonPMtarget',
                   'nonPMprobes', 'nonPMfeedback']
    
    subjectinfo=[]
    for r in range(5):
        blockNum = r+1
        evDir='/Users/srk482-admin/Documents/forcemem_mriDat/forcemem_{0}/fsl_analysis/EVs/block{1}/'.format(subject_id,blockNum)
        #Rest the onset duration and amp lists
        onset=[]
        duration=[]
        amp=[]
        #if r>1:
            #del(onset)
            #del(duration)
            #del(amp)
        
        #Set values to empty
        tmpOnset=[]
        tmpDuration=[]
        tmpAmp=[]
        
        
        #I am going to open each file by name for the time being.
        fileOpen=evDir+'pm_targetEVs.txt'
        tmpFile=open(fileOpen)
        for tmpLine in tmpFile:
            tmpOnset.append(float(tmpLine.split()[0]))
            tmpDuration.append(float(tmpLine.split()[1]))
            tmpAmp.append(float(tmpLine.split()[2]))
            
        onset.append(tmpOnset)
        duration.append(tmpDuration)
        amp.append(tmpAmp)
        
        #Set values to empty
        tmpOnset=[]
        tmpDuration=[]
        tmpAmp=[]
        
            
        fileOpen=evDir+'pm_probeEVs.txt'
        tmpFile=open(fileOpen)
        for tmpLine in tmpFile:
            tmpOnset.append(float(tmpLine.split()[0]))
            tmpDuration.append(float(tmpLine.split()[1]))
            tmpAmp.append(float(tmpLine.split()[2]))
            
            
        onset.append(tmpOnset)
        duration.append(tmpDuration)
        amp.append(tmpAmp)
        
        #Set values to empty
        tmpOnset=[]
        tmpDuration=[]
        tmpAmp=[]
        

        fileOpen=evDir+'pm_feedbackEVs.txt'
        tmpFile=open(fileOpen)
        for tmpLine in tmpFile:
            tmpOnset.append(float(tmpLine.split()[0]))
            tmpDuration.append(float(tmpLine.split()[1]))
            tmpAmp.append(float(tmpLine.split()[2]))
            
        onset.append(tmpOnset)
        duration.append(tmpDuration)
        amp.append(tmpAmp)
        
        #Set values to empty
        tmpOnset=[]
        tmpDuration=[]
        tmpAmp=[]
            
        fileOpen=evDir+'pm_targProbeEVs.txt'
        tmpFile=open(fileOpen)
        for tmpLine in tmpFile:
            tmpOnset.append(float(tmpLine.split()[0]))
            tmpDuration.append(float(tmpLine.split()[1]))
            tmpAmp.append(float(tmpLine.split()[2]))
            
        onset.append(tmpOnset)
        duration.append(tmpDuration)
        amp.append(tmpAmp)
        
        #Set values to empty
        tmpOnset=[]
        tmpDuration=[]
        tmpAmp=[]
            
        fileOpen=evDir+'npm_targetEVs.txt'
        tmpFile=open(fileOpen)
        for tmpLine in tmpFile:
            tmpOnset.append(float(tmpLine.split()[0]))
            tmpDuration.append(float(tmpLine.split()[1]))
            tmpAmp.append(float(tmpLine.split()[2]))
            
        onset.append(tmpOnset)
        duration.append(tmpDuration)
        amp.append(tmpAmp)
        
        #Set values to empty
        tmpOnset=[]
        tmpDuration=[]
        tmpAmp=[]
            
        fileOpen=evDir+'npm_probeEVs.txt'
        tmpFile=open(fileOpen)
        for tmpLine in tmpFile:
            tmpOnset.append(float(tmpLine.split()[0]))
            tmpDuration.append(float(tmpLine.split()[1]))
            tmpAmp.append(float(tmpLine.split()[2]))
            
        onset.append(tmpOnset)
        duration.append(tmpDuration)
        amp.append(tmpAmp)
        
        #Set values to empty
        tmpOnset=[]
        tmpDuration=[]
        tmpAmp=[]
            
        fileOpen=evDir+'pm_feedbackEVs.txt'
        tmpFile=open(fileOpen)
        for tmpLine in tmpFile:
            tmpOnset.append(float(tmpLine.split()[0]))
            tmpDuration.append(float(tmpLine.split()[1]))
            tmpAmp.append(float(tmpLine.split()[2]))
            
        onset.append(tmpOnset)
        duration.append(tmpDuration)
        amp.append(tmpAmp)
        
        #Set values to empty
        tmpOnset=[]
        tmpDuration=[]
        tmpAmp=[]
        
        #Now turn these lists into np arrays and export from file.
        onset=np.asarray(onset)
        duration=np.asarray(duration)
        amp=np.asarray(amp)        
        
        #return onset, duration, amp
        
        subjectinfo.insert(r,
                           Bunch(conditions=condition_names,
                                 onsets=onset,
                                 durations=duration,
                                 amplitudes=amp,
                                 tmod=None,
                                 pmod=None,
                                 regressor_names=None,
                                 regressors=None))
    return subjectinfo

# Get Subject Info - get subject specific condition information
getsubjectinfo = Node(Function(input_names=['subject_id'],
                               output_names=['subject_info'],
                               function=get_subject_info),
                      name='getsubjectinfo')




#### Now we establish the imput and output of this pipeline
# Infosource - a function free node to iterate over the list of subject names
infosource = Node(IdentityInterface(fields=['subject_id',
                                            'block_id',
                                            'contrasts'],
                                    contrasts=contrast_list),
                  name="infosource")
infosource.iterables = [('subject_id', subject_list),
                        ('block_id', block_list)]

# SelectFiles - to grab the data (alternativ to DataGrabber)
templates = {'func': 'forcemem_{subject_id}/Func/{block_id}/bold.nii'}
selectfiles = Node(SelectFiles(templates,
                               base_directory=data_dir),
                   name="selectfiles")

# Datasink - creates output folder for important outputs
datasink = Node(DataSink(base_directory=experiment_dir,
                         container=output_dir),
                name="datasink")

# Use the following DataSink output substitutions
substitutions = [('_subject_id_', ''),
                 ('_block_id_',''),
                 ('_despike', ''),
                 ('_detrended', ''),
                 ('_warped', '')]
datasink.inputs.substitutions = substitutions

# Connect Infosource, SelectFiles and DataSink to the main workflow
metaflow.connect([(infosource, selectfiles, [('subject_id', 'subject_id'),
                                             ('block_id','block_id')]),
                  (infosource, preproc, [('subject_id',
                                          'bbregister.subject_id'),
                                         ('subject_id',
                                          'fssource.subject_id')]),
                  (selectfiles, preproc, [('func', 'despike.in_file')]),
                  (infosource, getsubjectinfo, [('subject_id', 'subject_id'),
                                                ('block_id','block_id')]),
                  (getsubjectinfo, l1analysis, [('subject_info',
                                                 'modelspec.subject_info')]),
                  (infosource, l1analysis, [('contrasts',
                                             'conestimate.contrasts')]),
                  (preproc, datasink, [('realign.mean_image',
                                        'preprocout.@mean'),
                                       ('realign.realignment_parameters',
                                        'preprocout.@parameters'),
                                       ('art.outlier_files',
                                        'preprocout.@outliers'),
                                       ('art.plot_files',
                                        'preprocout.@plot'),
                                       ('binarize.binary_file',
                                        'preprocout.@brainmask'),
                                       ('bbregister.out_reg_file',
                                        'bbregister.@out_reg_file'),
                                       ('bbregister.out_fsl_file',
                                        'bbregister.@out_fsl_file'),
                                       ('bbregister.registered_file',
                                        'bbregister.@registered_file'),
                                       ]),
                  (l1analysis, datasink, [('mriconvert.out_file',
                                           'contrasts.@contrasts'),
                                          ('conestimate.spm_mat_file',
                                           'contrasts.@spm_mat'),
                                          ('conestimate.spmT_images',
                                           'contrasts.@T'),
                                          ('conestimate.con_images',
                                           'contrasts.@con'),
                                          ]),
                  ])

metaflow.write_graph(graph2use='colored')
metaflow.run('MultiProc', plugin_args={'n_procs': 4})
