#!/bin/bash

SUBNO=$1
dataDir=/Users/srk482-admin/Documents/forcemem_mriDat/forcemem_${SUBNO}/Anat
freeDir=/Users/srk482-admin/Documents/forcemem_mriDat/freesurfer
export anatFile=${dataDir}/MPRAGE.nii

echo "working on sub $SUBNO"
recon-all -all -i $anatFile -s ${SUBNO} -sd $freeDir -nuintensitycor-3T
echo "sub ${SUBNO} finished"


