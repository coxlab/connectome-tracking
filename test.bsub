#!/bin/bash

#BSUB -J siftflow_mult10_[1-100] 
#BSUB -o siftflow_mult10_%I.out
#BSUB -e siftflow_mult10_%I.err
#BSUB -W 1:00
#BSUB -q normal_serial 

# -- making sure that useful aliases are accessible to the command line
source ~/.bashrc
module load math/matlab-R2013a

# -- the working directory where my codes are
WORKING_DIR="/n/home08/vtan/SIFTflow"
cd $WORKING_DIR

IMG_IDX=$((${LSB_JOBINDEX}-1))

# -- actual code to run !
./matlab_script.sh siftflow_multframes ${IMG_IDX}
