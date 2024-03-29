import numpy as np
import numexpr as ne
from skimage.util.shape import view_as_windows
import skimage.io as io
import time
import argparse
import scipy.io

# simpler data structure
(FILT, ACTV, POOL, NORM) = range(4)
(FSIZ, FNUM, FWGH) = range(3)
(AMIN, AMAX) = range(2)
(PSIZ, PORD) = range(2)
(NSIZ, NCNT, NGAN, NTHR) = range(4)

def slminit():

  network = []

  layer = [[], [], [], []]
  layer[FILT][FSIZ:] = [9]
  layer[FILT][FNUM:] = [64]
  layer[ACTV][AMIN:] = [0]
  layer[ACTV][AMAX:] = [None]
  layer[POOL][PSIZ:] = [3]
  layer[POOL][PORD:] = [1]
  layer[NORM][NSIZ:] = [0]
  layer[NORM][NCNT:] = [0]
  layer[NORM][NGAN:] = [0]
  layer[NORM][NTHR:] = [0]
  network.append(layer)

  layer = [[], [], [], []]
  layer[FILT][FSIZ:] = [5]
  layer[FILT][FNUM:] = [128]
  layer[ACTV][AMIN:] = [0]
  layer[ACTV][AMAX:] = [None]
  layer[POOL][PSIZ:] = [3]
  layer[POOL][PORD:] = [1]
  layer[NORM][NSIZ:] = [0]
  layer[NORM][NCNT:] = [0]
  layer[NORM][NGAN:] = [0]
  layer[NORM][NTHR:] = [0]
  network.append(layer)

  np.random.seed(0)

  for i in xrange(len(network)):


    if (network[i][FILT][FSIZ] != 0):
      if (i == 0):
        network[i][FILT][FWGH:] = [np.random.rand(network[i][FILT][FSIZ], network[i][FILT][FSIZ], 1, network[i][FILT][FNUM]).astype(np.float32)]
      else:
        network[i][FILT][FWGH:] = [np.random.rand(network[i][FILT][FSIZ], network[i][FILT][FSIZ], network[i-1][FILT][FNUM], network[i][FILT][FNUM]).astype(np.float32)]
      for j in xrange(network[i][FILT][FNUM]):
        network[i][FILT][FWGH][:,:,:,j] -= np.mean(network[i][FILT][FWGH][:,:,:,j])
        network[i][FILT][FWGH][:,:,:,j] /= np.linalg.norm(network[i][FILT][FWGH][:,:,:,j])
      network[i][FILT][FWGH] = np.squeeze(network[i][FILT][FWGH])

  np.random.seed()

  return network

def nepow(X, O):

  if (O != 1): return ne.evaluate('X ** O')
  else:      return X

def nediv(X, Y):

  if (np.ndim(X) == 2):
    return ne.evaluate('X / Y')
  else:
    Y = Y[:,:,None]
    return ne.evaluate('X / Y')

def nemin(X, MIN): return ne.evaluate('where(X < MIN, MIN, X)')
def nemax(X, MAX): return ne.evaluate('where(X > MAX, MAX, X)')

def mcconv3(X, W):

  X_VAW = view_as_windows(X, W.shape[0:-1])
  Y_FPS = X_VAW.shape[0:2]
  X_VAW = X_VAW.reshape(Y_FPS[0] * Y_FPS[1], -1)
  W = W.reshape(-1, W.shape[-1])
  Y = np.dot(X_VAW, W)
  Y = Y.reshape(Y_FPS[0], Y_FPS[1], -1)

  return Y

def bxfilt2(X, F_SIZ, F_STRD):

  for i in reversed(xrange(2)):

    W_SIZ = np.ones(np.ndim(X))
    S_SIZ = np.ones(2)
    W_SIZ[i], S_SIZ[i] = F_SIZ, F_STRD
    X = np.squeeze(view_as_windows(X, tuple(W_SIZ)))[::S_SIZ[0], ::S_SIZ[1]] # subsampling before summation
    X = np.sum(X, -1)

  return X

def slmprop(X, network):

  for i in xrange(len(network)):
    if (network[i][FILT][FSIZ] != 0): X = mcconv3(X, network[i][FILT][FWGH])

    if (network[i][ACTV][AMIN] != None): X = nemin(X, network[i][ACTV][AMIN])
    if (network[i][ACTV][AMAX] != None): X = nemax(X, network[i][ACTV][AMAX])

    if (network[i][POOL][PSIZ] != 0):
      X = nepow(X, network[i][POOL][PORD])
      X = bxfilt2(X, network[i][POOL][PSIZ], 2)
      X = nepow(X, (1.0 / network[i][POOL][PORD]))

    if (network[i][NORM][NSIZ] != 0):
      B = (network[i][NORM][NSIZ] - 1) / 2
      X_SQS = bxfilt2(nepow(X, 2) if (np.ndim(X) == 2) else np.sum(nepow(X, 2), -1), network[i][NORM][NSIZ], 1)

      if (network[i][NORM][NCNT] == 1):
        X_SUM  = bxfilt2(X if (np.ndim(X) == 2) else np.sum(X, -1), network[i][NORM][NSIZ], 1)
        X_MEAN = X_SUM / ((network[i][NORM][NSIZ] ** 2) * network[i][FILT][FNUM])

        X = X[B:X.shape[0]-B, B:X.shape[1]-B] - X_MEAN[:,:,None]
        X_NORM = X_SQS - ((X_SUM ** 2) / ((network[i][NORM][NSIZ] ** 2) * network[i][FILT][FNUM]))
        X_NORM = X_NORM ** (1.0/2)
      else:
        X = X[B:X.shape[0]-B, B:X.shape[1]-B]
        X_NORM = X_SQS ** (1.0/2)

      np.putmask(X_NORM, X_NORM < (network[i][NORM][NTHR] / network[i][NORM][NGAN]), (1/network[i][NORM][NGAN]))
      X = nediv(X, X_NORM) # numexpr for large matrix division

  return X

# MAIN
parser = argparse.ArgumentParser(description='')
parser.add_argument('fname', default="")
parser.add_argument('size')
args = parser.parse_args()
size = int(args.size)

if not args.fname:
  img = np.random.randn(size, size).astype(np.float32)
  print 'Using random image'
else:
  im = io.imread(args.fname, as_grey=True).astype('f')
  # pad if necessary and crop down to desired size
  if im.shape[0] < size:
    img = np.zeros((size, size))
    img[:size, :size] = im
  else: 
    img = im[0:size, 0:size]
  print 'Using image ' + args.fname

print 'Image size ' + args.size
print img.shape
network = slminit()

t1 = time.time()
for i in xrange(100): ftmap = slmprop(img, network)
t2 = time.time()

network = np.array(network)
print '%0.5f s' % (t2-t1)

scipy.io.savemat('fmap.mat', {'fmap': ftmap}, appendmat=False)
t3 = time.time()
print '%0.5f s' % (t3-t2)

