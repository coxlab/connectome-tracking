#!/bin/sh

dir=/n/home08/vtan/klt

# enter directory
cd ${dir}

# make C files
make

for (( SR=1; SR<=15; SR+=2 )); do
	printf "${1}\t1\t${SR}\t" >> "klt-metrics.txt"  
	./klt-orig -n 100 -w ${1} -e 1 -s ${SR}
		
	# run extractFeatures
	echo 'python extractFeatures.py --feat klt'
	python extractFeatures.py --feat klt

	# run evalTrackedPoints 
	./matlab_script.sh evalTrackedPoints klt 

	for (( EIG=10; EIG<=150; EIG+=20 )); do
		printf "${1}\t${EIG}\t${SR}\t" >> "klt-metrics.txt"  
		./klt-orig -n 100 -w ${1} -e ${EIG} -s ${SR}
		
		# run extractFeatures
		echo 'python extractFeatures.py --feat klt'
		python extractFeatures.py --feat klt

		# run evalTrackedPoints 
		./matlab_script.sh evalTrackedPoints klt 
	done
done


