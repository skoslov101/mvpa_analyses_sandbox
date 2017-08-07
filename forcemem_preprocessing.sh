#!/bin/bash
# MODIFIED BY T.WANG twang.work@gmail.com 5.1.1y to include all preprocessing and ventral temporal lobe masks and then further edited by Seth Koslov to fit ForceMem
# Usage: >./forcemem_preprocessing '201704251' '/Users/srk482-admin/Documents/forcemem_mriDat/forcemem_201704251/Func/block4'
#

# subject number # SUBNO=2017061601
MIDRUN='block4'
#MIDRUNDIR='/Users/srk482-admin/Documents/forcemem_mriDat/forcemem_201704251/Func/block4'
#MIDRUN = name of the middle run (include localizer and study together)
#read in middle run (reference run) from the second argument in the script
SUBNO=$1
#MIDRUNDIR=$2
MIDRUN=$2


#set up directories
BASEDIR='/Users/srk482-admin/Documents'
#when calling basedir use ""
# name of the experiment
STUDYNAME='forcemem'
STUDY_DATA='forcemem_mriDat'
# code used for subjects when scanning
SUBCODE=${STUDYNAME}_${SUBNO}

# CHANGING STUDYNAME BECAUSE OF PERMISSION ERROR
STUDYNAME=${STUDYNAME}

#cd base separately then subdir
STUDYDIR=${BASEDIR}/${STUDY_DATA}
SUBDIR=${STUDYDIR}/${SUBCODE}

MIDRUNDIR=${SUBDIR}/Func/${MIDRUN}

cd ${SUBDIR}

ST_MASK_DIR=${STUDYDIR}/MVPA_anat_masks
MASK_DIR=${SUBDIR}/mask
mkdir -p "${MASK_DIR}"
FUNC_DIR=${SUBDIR}/Func
ANAT_DIR=${SUBDIR}/Anat


#functional_avg_ref

FUNC_AVG_DIR=${FUNC_DIR}/avg_func_ref
mkdir ${FUNC_AVG_DIR}


MEANRUNDIR=${FUNC_DIR}/${MIDRUN} 
cd ${MEANRUNDIR};
prefRI=${MEANRUNDIR}/meanbold.nii 

#meanscan=`ls | grep meanbold`
#prefRI=${MEANRUNDIR}/${meanscan}

##### VARIABLES THAT CAN CHANGE!!!!####
#ST_MASK_HIP=${ST_MASK_DIR}/hippocampus_thr50_MNI152.nii.gz 
#ST_MASK=${ST_MASK_DIR}/tempoccfusi_pHg_combined_MNI152.nii.gz
#ST_TEMPLATE='/Users/srk482-admin/Applications/fsl/data/standard/MNI152_T1_1mm_brain.nii.gz'
#ST_TEMPLATE_HEAD='/Users/srk482-admin/Applications/fsl/data/standard/MNI152_T1_1mm.nii.gz'
#ST_TEMPLATE_MASK='/Users/srk482-admin/Applications/fsl/data/standard/MNI152_T1_1mm_brain_mask_dil.nii.gz
ST_TEMPLATE='/Users/srk482-admin/Documents/forcemem_mriDat/standards/MNI152_T1_1mm_brain.nii.gz'
ST_TEMPLATE_HEAD='/Users/srk482-admin/Documents/forcemem_mriDat/standards/MNI152_T1_1mm.nii.gz'
ST_TEMPLATE_MASK='/Users/srk482-admin/Documents/forcemem_mriDat/standards/MNI152_T1_1mm_brain_mask_dil.nii.gz'
#MASK=${MASK_DIR}/tempoccfusi_pHg_combined_epi_space.nii
ST_MASK2=${ST_MASK_DIR}/${SUBNO}_15_mask.nii.gz
MASK2=${MASK_DIR}/${SUBNO}_mask_epi_space.nii
#MASK_HIP=${MASK_DIR}/hippocampus_thr50_epi_space.nii
###########################################

###########################################
#Create Middle Run Mean = this is your functional reference image fRI
MIDRUN_BOLD=${MIDRUNDIR}/bold_mid_mcf
pre_fRI=${MIDRUNDIR}/bold_avg_mcf
fRI_head=${FUNC_AVG_DIR}/bold_avg_mcf
fRI=${FUNC_AVG_DIR}/bold_avg_mcf_brain
aRI=${ANAT_DIR}/mprage_brain
aRI_head=${ANAT_DIR}/mprage

# take the bold.nii from the middle run, mcflirt and mean
echo movement correction on middle run
mcflirt -in ${MIDRUNDIR}/bold.nii -out ${MIDRUN_BOLD} -mats -plots;
echo fslmaths ${MIDRUN_BOLD} -Tmean ${pre_fRI} 
fslmaths ${MIDRUN_BOLD} -Tmean ${pre_fRI} 
echo copy middle run average to functional acerag directory and brain extraction
cp ${pre_fRI}.nii.gz ${FUNC_AVG_DIR}
cd ${FUNC_AVG_DIR}
bet bold_avg_mcf bold_avg_mcf_brain -R -m
gunzip ${FUNC_AVG_DIR}/*.gz

# motion correct (coreg) all functionals the to average of the middle run; brain extract and bptf high pass all runs

scan_list=`ls ${FUNC_DIR} | grep loc`
for x in $scan_list; do cd ${FUNC_DIR}/$x; echo $x;
echo 'movement correction'; mcflirt -in bold.nii -out bold_mcf -reffile ${fRI_head} -mats -plots;
echo 'epi brain extraction'; bet bold_mcf.nii bold_mcf_brain.nii -F;
echo 'slice timing correction'; slicetimer -i bold_mcf_brain.nii -o bold_mcf_brain_st.nii -r 2.0000 --odd
echo 'creating temporary mean'; fslmaths bold_mcf_brain_st.nii -Tmean tempmean
echo 'high pass temporal filter';fslmaths bold_mcf_brain_st.nii -bptf 32 -1 -add tempmean bold_dt_mcf_brain.nii; rm tempmean; #128s high pass filter
echo 'unzipping all files'; gunzip *; done 


#BET your structural with -R (recursive) and -B (neck removal)

echo 'bet ${aRI_head} ${aRI} -R -B'
bet ${aRI_head} ${aRI} -R -B

#Register your fRI to the anatomical scan (MPRAGE)

echo epi_reg --epi=${fRI} --t1=${aRI_head} --t1brain=${aRI} --out=${FUNC_AVG_DIR}/bold_co_avg_mcf_brain.nii.gz 
epi_reg --epi=${fRI} --t1=${aRI_head} --t1brain=${aRI} --out=${FUNC_AVG_DIR}/bold_co_avg_mcf_brain.nii.gz 

##### Use the mask created from functional analysis #####
 CREATE VENTRAL TEMPORAL MASK #####
#you already have the fRI to MPRAGE from epi_reg prior. 
#Coregister the MPRAGE to the standard (T1 MNI152)

cd ${FUNC_AVG_DIR}
echo "creating AFFINE transform for non-linear registration"
flirt -ref ${ST_TEMPLATE} -in ${aRI} -omat affineT12MNI_4fnirt.mat
echo "FNIRT in progress, non-linear registration of MPRAGE to MNI152_1mm.nii"
fnirt --ref=${ST_TEMPLATE_HEAD} --in=${aRI_head} --refmask=${ST_TEMPLATE_MASK} --aff=affineT12MNI_4fnirt.mat --cout=T12MNI --iout=highres_T12MNI_image  

#compute inverse transform (standard to MPRAGE)
MNI2T1=${FUNC_AVG_DIR}/MNI2T1
#set the fRI to MPRAGE mat file 
fRI2T1=${FUNC_AVG_DIR}/bold_co_avg_mcf_brain.mat
fRI2STD=${FUNC_AVG_DIR}/fRI2STD
T12fRI=${FUNC_AVG_DIR}/T12fRI
T12MNI=${FUNC_AVG_DIR}/T12MNI
 
echo "compute inverse transform MNI to T1"
invwarp --ref=${aRI_head} --warp=${T12MNI} --out=MNI2T1
#compute inverse transform (T1 to fRI)
echo "compute inverse transform T1 to fRI"
convert_xfm -omat T12fRI -inverse ${fRI2T1}
#concatenate both mat and warp files to achieve fRI to standard
echo "apply concateonated warps"
# to ventral temporal mask
applywarp --ref=${fRI} --in=${ST_MASK2} --warp=${MNI2T1} --postmat=${T12fRI} --out=${MASK2}
# to hippocampus mask
#applywarp --ref=${fRI} --in=${ST_MASK_HIP} --warp=${MNI2T1} --postmat=${T12fRI} --out=${MASK_HIP}
#unzip mask
echo "unzipping subject-specific mask for MVPA decoding"
gunzip ${MASK2}
#gunzip ${MASK_HIP}
gunzip ${FUNC_DIR}/*/*.gz

#warp the white matter tract mask to subject space
glmDir=${SUBDIR}/GLM
GLM_MASK=${glmDir}/pm_greater_nonpm_bin_mask.nii.gz
#gunzip ${GLM_MASK}
GLM_MASK_fRI=${glmDir}/pm_greater_nonpm_bin_mask_fRI.nii.gz
applywarp --ref=${fRI} --in=${GLM_MASK} --warp=${MNI2T1} --postmat=${T12fRI} --out=${GLM_MASK_fRI}
gunzip ${GLM_MASK_fRI}
ST_WM_MASK=${FUNC_AVG_DIR}/bold_co_avg_mcf_brain_fast_wmseg.nii
WM_MASK=${MASK_DIR}/${SUBNO}_wm_epi_space.nii
applywarp --ref=${fRI} --in=${ST_WM_MASK} --premat=${T12fRI} --out=${WM_MASK}
gunzip ${WM_MASK}

#Now subtract the WM mask from the BOLD mask and then binarize the results
GLM_MASK_fRI=${glmDir}/pm_greater_nonpm_bin_mask_fRI.nii
BOLD_MASK_RAW=${glmDir}/pm_greater_nonpm_SUB_whmat.nii
BOLD_MASK_BIN=${MASK_DIR}/${SUBNO}_bold_mask_bin.nii
fslmaths ${GLM_MASK_fRI} -sub ${WM_MASK} ${BOLD_MASK_RAW}
fslmaths ${BOLD_MASK_RAW} -bin ${BOLD_MASK_BIN}
gunzip ${BOLD_MASK_BIN}

#return to launch
cd "${FUNC_DIR}"

