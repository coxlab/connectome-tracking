from tifffile import imsave
import cPickle
import numpy as np
from PIL import Image

indices = range(70,100)
total = []

for i in indices:
	print i
	
	filename = 'isbi13_test_seg_%02d.png' %(i)
	im = Image.open(filename)
	print 'foo'
	frame = np.array(im)
	#frame *= 1.0/frame.max()
	print frame.shape
	frame = frame.reshape(1,1024,1024)
	print 'bar'

	if total == []:
		total = frame
	else:
		total = np.concatenate((total, frame))
	print total.shape

#frame = frame.squeeze()
total = total.squeeze()

#imsave('isbi13_trn100_tst50.tif', frame)
imsave('isbi13_test_seg_70-99.tif', total)

