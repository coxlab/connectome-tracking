#!/bin/sh

dir=/n/home08/vtan/klt

# enter directory
cd ${dir}
make

for (( ET=5; ET<=7; ET+=2 )); do
	printf "${1}\t${ET}\t" >> "sift-metrics.txt"  

	# compute sift features
	./matlab_script.sh computeSiftFeatures ${1} ${ET} 

	# make C files and run klt-track3
	./klt-sift -n 100 -w 3 -s 1

	# run extractFeatures
	echo 'python extractFeatures.py --feat sift'
	python extractFeatures.py --feat sift

	# run evalTrackedPoints 
	./matlab_script.sh evalTrackedPoints sift  
done
