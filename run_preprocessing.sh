#!/bin/bash
#This code is adapted from Tracy Wangs preprocessing pipeline.
#Usage: ./run_preprocessing.sh $subjectNumber

MIDRUN='block3'
SUBNO=$1 #subject number is the input variable from the very start of the script

#Now set up directories
studyDir="$PWD"
subDir=$studyDir/forcemem_${SUBNO}
funcDir=${subDir}/Func
anatDir=${subDir}/Anat

#Mask directories
stand_maskDir=$studyDir/MVPA_anat_masks #standard mask
subMaskDir=${subDir}/mask #individual subject masks directory
stMask=$stand_maskDir/tempoccfusi_pHg_combined_MNI152.nii.gz
stTemplate=${studyDir}/standards/MNI152_T1_1mm_brain.nii.gz
stTemplate_head=${studyDir}/standards/MNI152_T1_1mm.nii.gz
stTemplate_mask=${studyDir}/standards/MNI152_T1_1mm_brain_mask_dil.nii.gz
mask=${subMaskDir}/tempoccfusi_pHg_combined_epi_space.nii
brain_mask=${studyDir}/standards/MNI152_T1_1mm_brain_mask.nii.gz
subMask_wholeBrain=${subMaskDir}/wholeBrain.nii


#Average run directories
midRunDir=${funcDir}/${MIDRUN}
avgFuncDir=${funcDir}/avg_func_ref

#average run filenames
midRun_bold=${midRunDir}/bold_mid_mcf
pre_fRI=${midRunDir}/bold_avg_mcf
fRI_head=${avgFuncDir}/bold_avg_mcf
fRI=${avgFuncDir}/bold_avg_mcf_brain
aRI=${anatDir}/mprage_brain
aRI_head=${anatDir}/mprage

#Now make a few folders that did not exist
mkdir ${avgFuncDir}

##Now we can get started on some preprocessing
#The first thing to do is preprocess the middle run
echo movement correction on the middle run:
mcflirt -in ${midRunDir}/bold.nii -out ${midRun_bold} -mats -plots
echo running fslmaths ${midRun_bold} -Tmean output: ${pre_fRI}
fslmaths ${midRun_bold} -Tmean ${pre_fRI}
echo copying middle run average to func average directory
cp ${pre_fRI}.nii.gz ${avgFuncDir}
cd ${avgFuncDir}
echo brain extract average func image
bet bold_avg_mcf bold_avg_mcf_brain -R -m
gunzip ${avgFuncDir}/*.gz

#This is where I should add some code that can output movement stats on the middle scan

scan_list=`ls ${funcDir} | grep loc`
for subX in $scan_list
do
	cd ${funcDir}/$subX
	echo starting preprocessing $subX
	
	echo 'movement correcetion'
	mcflirt -in bold.nii -out bold_mcf -reffile ${fRI_head} -mats -plots
	
	echo 'epi brain extraction'
	bet bold_mcf.nii bold_mcf_brain.nii -F -g 0

	echo 'slice timing correction'
	slicetimer -i bold_mcf_brain.nii -o bold_mcf_brain_st.nii -r 2.0000 -d 2 --odd

	echo 'creating temp mean'
	fslmaths bold_mcf_brain_st.nii -Tmean tempmean
	
	echo 'highpass temporal filter'
	fslmaths bold_mcf_brain_st.nii -bptf 32 -1 -add tempmean bold_dt_mcf_brain.nii
	rm tempmean.nii.gz
	gunzip *
	echo 'preprocessed file for $subX bold_dt_mcf_brain is complete'
	echo  
done

#The next step is to brain extract the structural
echo 'bet structural ${aRI_head} with -R and -B to output {aRI}'
bet ${aRI_head} ${aRI} -R -B

#Register fRI to the aRI (anatomical mprage)
epi_reg --epi=${fRI} --t1=${aRI_head} --t1brain=${aRI} --out=${avgFuncDir}/bold_co_avg_mcf_brain.nii.gz

#### Mask section
cd ${avgFuncDir}
echo creating AFFINE transform for non-linear reg
flirt -ref ${stTemplate} -in ${aRI} -omat affineT12MNI_4fnirt.mat

echo FNIRT non-linear transform of MPRAGE to MNI152_1mm
fnirt --ref=${stTemplate_head} --in=${aRI_head} --refmask=${stTemplate_mask} --aff=affineT12MNI_4fnirt.mat --cout=T12MNI --iout=highres_T12MNI_image

#Compute inverse transform (standard to MPRAGE)
MNI2T1=${avgFuncDir}/MNI2T1
fRI2T1=${avgFuncDir}/bold_co_avg_mcf_brain.mat
fRI2STD=${avgFuncDir}/fRI2STD
T12fRI=${avgFuncDir}/T12fRI
T12MNI=${avgFuncDir}/T12MNI

echo compute inverse transform MNI to TI
invwarp --ref=${aRI_head} --warp=${T12MNI} --out=MNI2T1

echo compute inverse transform T1 to functional reference
convert_xfm -omat T12fRI -inverse ${fRI2T1}

echo warp mask from standard space to high res to reference func
applywarp --ref=${fRI} --in=${stMask} --warp=${MNI2T1} --postmat=${T12fRI} --out=${mask}

echo warp whole brain mask from highRes to reference func
applywarp --ref=${fRI} --in=${brain_mask} --warp=${MNI2T1} --postmat=${T12fRI} --out=${subMask_wholeBrain}

echo warping done now unzip file
gunzip ${mask}.gz
gunzip ${subMask_wholeBrain}
