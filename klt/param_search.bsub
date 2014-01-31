#!/bin/bash

#BSUB -J sift_params_[3]
#BSUB -o sift_params_%I.out
#BSUB -e sift_params_%I.err
#BSUB -W 10:00
#BSUB -q normal_serial 

# -- making sure that useful aliases are accessible to the command line
source ~/.bashrc
module load math/matlab-R2013a

# -- the working directory where my codes are
WORKING_DIR="/n/home08/vtan/klt"
cd $WORKING_DIR

PT=$((${LSB_JOBINDEX}*2))

# -- actual code to run !
./tracking-sift-batch.sh ${PT} > sift_job_output.txt
