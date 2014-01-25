/**********************************************************************
**********************************************************************/

#include <stdlib.h>
#include <stdio.h>
#include "pnmio.h"
#include "klt.h"


int main()
{
  unsigned char *img1, *img2;
  char infile1[100], infile2[100], outfile1[100], outfile2[100], txt_name[100], ft_name[100];
  KLT_TrackingContext tc;
  KLT_FeatureList fl;
  KLT_FeatureTable ft;
  int nFeatures = 20000, nFrames = 100;
  int ncols, nrows;
  int i;

  tc = KLTCreateTrackingContext();

  // Parameters
  tc->mindist = 7;
  tc->min_eigenvalue = 10;
  //tc->max_residue = 10.0f;
  tc->smoothBeforeSelecting = TRUE;
  tc->window_width = 3;
  tc->window_height = 3;
  tc->grad_sigma = 0.5f;
  tc->smooth_sigma_fact = 0.4f;
  KLTChangeTCPyramid(tc, 3);
  KLTUpdateTCBorder(tc);
  tc->sequentialMode = TRUE;
  tc->writeInternalImages = FALSE;
  tc->affineConsistencyCheck = 2;  /* set this to 2 to turn on affine consistency check */
 
  img1 = pgmReadFile("/home/vyt/Documents/Research/isbi_2013/pgms/train-input-norm-0.pgm", NULL, &ncols, &nrows);
  img2 = (unsigned char *) malloc(ncols*nrows*sizeof(unsigned char));


  fl = KLTCreateFeatureList(nFeatures);
  ft = KLTCreateFeatureTable(2, nFeatures);
  
  for (i = 0; i < nFrames - 1; i++)  {
    sprintf(infile1, "/home/vyt/Documents/Research/isbi_2013/pgms/train-input-norm-%d.pgm", i);
    sprintf(infile2, "/home/vyt/Documents/Research/isbi_2013/pgms/train-input-norm-%d.pgm", i+1);
    pgmReadFile(infile1, img1, &ncols, &nrows);
    pgmReadFile(infile2, img2, &ncols, &nrows);

    sprintf(outfile1, "klt_features/img/feat%d.ppm", i);
    KLTSelectGoodFeatures(tc, img1, ncols, nrows, fl);
    KLTStoreFeatureList(fl, ft, 0);
    KLTWriteFeatureListToPPM(fl, img1, ncols, nrows, outfile1);

    KLTTrackFeatures(tc, img1, img2, ncols, nrows, fl);
    KLTStoreFeatureList(fl, ft, 1);
    sprintf(outfile2, "klt_features/img/feat%d-tracked.ppm", i+1);
    KLTWriteFeatureListToPPM(fl, img2, ncols, nrows, outfile2);
    
    sprintf(txt_name, "klt_features/features%d-%d.txt", i, i+1);
    sprintf(ft_name, "klt_features/features%d-%d.ft", i, i+1);
    
    KLTWriteFeatureTable(ft, txt_name, "%5.1f");
    KLTWriteFeatureTable(ft, ft_name, NULL);
  }


  KLTFreeFeatureTable(ft);
  KLTFreeFeatureList(fl);
  KLTFreeTrackingContext(tc);
  free(img1);
  free(img2);

  return 0;
}
