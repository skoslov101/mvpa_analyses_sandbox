#!/bin/bash

# Script created by Seth Koslov to take ForceMem functional files and convert tostandard space.  Initially this was scripted as practice going between file types and also to set up a hyperalignment test.  Importantly, I've already run the preprocessing script at this point (to save time) so I already have a number of the conversion arrays and already have motion corrected (preprocessed) epi files.

# Input for this script needs to be the subject number to be run.

#Collect subject number from input
SUBNO=$1

baseDir='/Users/srk482-admin/Documents/forcemem_mriDat'
subDir=$baseDir/forcemem_$SUBNO
funcDir=$subDir/Func
anatDir=$subDir/Anat

stndRef=$baseDir/standards/MNI152_T1_1mm_brain.nii.gz
stndMask=$baseDir/standards/MNI152_t1_1mm_brain_mask.nii.gz

#Here I'm going to align the preprocessed functional to the highres anatomical
anatRef=$anatDir/mprage_brain.nii.gz
affRef=$subDir/avg_func_ref/affineT12MNI_4fnirt

warpRef=$funcDir/avg_func_ref/T12MNI.nii.gz

for blockI in 1 2 3
do
	cd $funcDir/loc${blockI}
	echo loc${blockI} flirt starting
	flirt -ref ${anatRef} -in bold_dt_mcf_brain.nii -out func2highres -omat func2highres.mat
	#So normally here youd need to run a fnirt, but it takes forever, and I already have the output from preprocessing, so Im going to just steal that file (t12MNI) instead of redoing it here. Below is the command you would use.
	#fnirt --ref=${stndRef} --in=${anatRef} --refmask=${stndMask} --aff=${affRef} --cout=T12MNI --iout=highres_T12MNI_image
	echo loc${blockI} convertwarp starting
	convertwarp --ref=${stndRef} --warp1=${warpRef} --premat=func2highres.mat --out=t2_to_std --relout
	echo loc${blockI} applywarp starting
	applywarp --ref=${stndRef} --in=bold_dt_mcf_brain.nii --warp=t2_to_std --rel --out=funcMNI
	echo gunzippidedooda
	gunzip funcMNI.nii.gz
done
