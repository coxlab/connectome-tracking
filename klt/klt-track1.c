/**********************************************************************
Finds the 150 best features in an image and tracks them through the 
next two images.  The sequential mode is set in order to speed
processing.  The features are stored in a feature table, which is then
saved to a text file; each feature list is also written to a PPM file.
**********************************************************************/

#include <stdlib.h>
#include <stdio.h>
#include "pnmio.h"
#include "klt.h"

/* #define REPLACE*/

int main()
{
  unsigned char *img1, *img2;
  char fnamein[100], fnameout[100];
  KLT_TrackingContext tc;
  KLT_FeatureList fl;
  KLT_FeatureTable ft;
  int nFeatures = 1000, nFrames = 7;
  int ncols, nrows;
  int i;

  tc = KLTCreateTrackingContext();
  tc->mindist = 10;
  tc->min_eigenvalue = 100;
  tc->min_determinant = 10;
  //tc->min_displacement = 1;
  //tc->max_iterations = 20;
  tc->max_residue = 10;
  tc->smoothBeforeSelecting = TRUE;
  tc->window_width = 5;
  tc->window_height = 5;
  tc->grad_sigma = 1.0;
  tc->smooth_sigma_fact = 0.5;
  KLTChangeTCPyramid(tc, 5);
  KLTUpdateTCBorder(tc);
  fl = KLTCreateFeatureList(nFeatures);
  ft = KLTCreateFeatureTable(nFrames, nFeatures);
  tc->sequentialMode = TRUE;
  tc->writeInternalImages = FALSE;
  tc->affineConsistencyCheck = -1;  /* set this to 2 to turn on affine consistency check */
 
  img1 = pgmReadFile("isbi_dataset/pgms/train-volume.tif-00.pgm", NULL, &ncols, &nrows);
  img2 = (unsigned char *) malloc(ncols*nrows*sizeof(unsigned char));

  KLTSelectGoodFeatures(tc, img1, ncols, nrows, fl);
  KLTStoreFeatureList(fl, ft, 0);
  KLTWriteFeatureListToPPM(fl, img1, ncols, nrows, "feat0.ppm");

  for (i = 1 ; i < nFrames ; i++)  {
    sprintf(fnamein, "isbi_dataset/pgms/train-volume.tif-%02d.pgm", i);
    pgmReadFile(fnamein, img2, &ncols, &nrows);
    KLTTrackFeatures(tc, img1, img2, ncols, nrows, fl);
#ifdef REPLACE
    KLTReplaceLostFeatures(tc, img2, ncols, nrows, fl);
#endif
    KLTStoreFeatureList(fl, ft, i);
    sprintf(fnameout, "feat%d.ppm", i);
    KLTWriteFeatureListToPPM(fl, img2, ncols, nrows, fnameout);
  }
  KLTWriteFeatureTable(ft, "features.txt", "%5.1f");
  KLTWriteFeatureTable(ft, "features.ft", NULL);

  KLTFreeFeatureTable(ft);
  KLTFreeFeatureList(fl);
  KLTFreeTrackingContext(tc);
  free(img1);
  free(img2);

  return 0;
}

