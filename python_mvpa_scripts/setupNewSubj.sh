#!/bin/bash

SUBNO=$1

mainDir=forcemem_${SUBNO}
mkdir "${mainDir}"

cd ${mainDir}

mkdir DICOM
cd DICOM
mkdir Anat
mkdir fieldmap
mkdir Func
cd Func
mkdir block1
mkdir block2
mkdir block3
mkdir block4
mkdir block5
mkdir loc1
mkdir loc2
mkdir loc3
mkdir ogloc1
mkdir ogloc2
cd ..
cd ..

mkdir Func
cd Func
mkdir block1
mkdir block2
mkdir block3
mkdir block4
mkdir block5
mkdir loc1
mkdir loc2
mkdir loc3
mkdir ogloc1
mkdir ogloc2
cd ..

mkdir mask
mkdir behav
mkdir Anat
mkdir fsl_analysis
cd fsl_analysis
mkdir block1
mkdir block2
mkdir block3
mkdir block4
mkdir block5
cd ..

mkdir mvpa_results
mkdir mvpa_analysis
mkdir fieldmap

cd behav
mkdir loc
mkdir mvpa_params
mkdir ogLoc
mkdir pmTask
cd ..

echo folders created for $SUBNO
