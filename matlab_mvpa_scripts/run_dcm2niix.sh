#!/bin/bash

SUBNO=$1

path="$PWD"
subDir=forcemem_${SUBNO}
mainDir=$path/$subDir

# DICOM to NII the MPRAGE by first renaming and then putting into the correct folder
mv ${mainDir}/DICOM/Anat/$subDir\ -\ MPRAGE ${mainDir}/DICOM/Anat/MPRAGE
dcm2niix -o $mainDir/Anat -f MPRAGE $mainDir/DICOM/Anat/MPRAGE

for blockI in 1 2 3 4 5
do
	mv $mainDir/DICOM/Func/block${blockI}/$subDir\ -\ test_forcemem_epi\ 32ch $mainDir/DICOM/Func/block${blockI}/pmTask_bold
	dcm2niix -o $mainDir/Func/block${blockI} -f bold $mainDir/DICOM/Func/block${blockI}/pmTask_bold
done


for locI in 1 2 3
do
	mv $mainDir/DICOM/Func/loc${locI}/$subDir\ -\ localizer_epi\ 32ch $mainDir/DICOM/Func/loc${locI}/loc_bold
	dcm2niix -o ${mainDir}/Func/loc${locI} -f bold $mainDir/DICOM/Func/loc${locI}/loc_bold	
done

for oglocI in 1 2
do
	mv $mainDir/DICOM/Func/ogloc${oglocI}/$subDir\ -\ localizer_OG_epi\ 32ch $mainDir/DICOM/Func/ogloc${oglocI}/ogloc_bold
	dcm2niix -o $mainDir/Func/ogloc${oglocI} -f bold $mainDir/DICOM/Func/ogloc${oglocI}/ogloc_bold
done

