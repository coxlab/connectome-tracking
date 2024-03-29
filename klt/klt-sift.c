/**********************************************************************
**********************************************************************/

#include <stdlib.h>
#include <stdio.h>
#include "pnmio.h"
#include "klt.h"
#include <unistd.h>


int main(int argc, char **argv)
{
  unsigned char *img1, *img2;
  char infile1[100], infile2[100], outfile1[100], outfile2[100], txt_name[100], ft_name[100], featfile[100];
  KLT_TrackingContext tc;
  KLT_FeatureList fl;
  KLT_FeatureTable ft, ft_ext;
	FILE *fh;
  int nFeatures = 20000;
  int ncols, nrows;
  int i;
	int param;
	int nFrames = 100, window = 3, searchRange = 1; 

  tc = KLTCreateTrackingContext();

	// Get params from the command line
	while ((param = getopt (argc, argv, "n:w:s:")) != -1) {
  	switch (param)  {
			case 'n':
				nFrames = atoi(optarg);
				break;
    	case 'w':
      	window = atoi(optarg);
        break;
    	case 's':
      	searchRange = atoi(optarg);
        break;
      case '?':
        if (isprint (optopt))
        	fprintf (stderr, "Unknown option `-%c'.\n", optopt);
        else
        	fprintf (stderr,"Unknown option character `\\x%x'.\n", optopt);
          return 1;
      default:
      	abort();
    }
	}
	printf("nFrames: %d, window: %d, searchRange: %d\n", nFrames, window, searchRange); 

	// Print params to file
	fh = fopen("sift-metrics.txt", "a");
	fprintf(fh, "%d\t%d\t%d\n", nFrames, window, searchRange);
	fclose(fh);

  tc = KLTCreateTrackingContext();

  // Parameters
  //tc->min_eigenvalue = 1;
  //tc->min_displacement = 1;
	tc->mindist = 7;
  tc->max_residue = 10.0f;
  tc->smoothBeforeSelecting = TRUE;
  tc->window_width = window;
  tc->window_height = window;
  tc->grad_sigma = 0.5f;
  tc->smooth_sigma_fact = 0.4f;
  KLTChangeTCPyramid(tc, searchRange);
  KLTUpdateTCBorder(tc);
  tc->sequentialMode = TRUE;
  tc->writeInternalImages = FALSE;
  tc->affineConsistencyCheck = 2;  /* set this to 2 to turn on affine consistency check */
 
  img1 = pgmReadFile("/n/home08/vtan/isbi_2013/pgms/train-input-norm-0.pgm", NULL, &ncols, &nrows);
  img2 = (unsigned char *) malloc(ncols*nrows*sizeof(unsigned char));


  fl = KLTCreateFeatureList(nFeatures);
  ft = KLTCreateFeatureTable(2, nFeatures);
  
  for (i = 0; i < nFrames - 1; i++)  {
    sprintf(infile1, "/n/home08/vtan/isbi_2013/pgms/train-input-norm-%d.pgm", i);
    sprintf(infile2, "/n/home08/vtan/isbi_2013/pgms/train-input-norm-%d.pgm", i+1);
    pgmReadFile(infile1, img1, &ncols, &nrows);
    pgmReadFile(infile2, img2, &ncols, &nrows);

    //KLTSelectGoodFeatures(tc, img1, ncols, nrows, fl);
    //KLTStoreFeatureList(fl, ft, 0);
    //KLTWriteFeatureListToPPM(fl, img1, ncols, nrows, outfile1);
    sprintf(featfile, "sift_features/init_feat%d.txt", i);
    ft_ext = KLTReadFeatureTable(NULL, featfile);
    fl = KLTCreateFeatureList(ft_ext->nFeatures);
    KLTExtractFeatureList(fl, ft_ext, 0);
    ft = KLTCreateFeatureTable(nFrames, ft_ext->nFeatures);
    KLTStoreFeatureList(fl, ft, 0);
    sprintf(outfile1, "sift_features/img/feat%d.ppm", i);
    KLTWriteFeatureListToPPM(fl, img1, ncols, nrows, outfile1);

    KLTTrackFeatures(tc, img1, img2, ncols, nrows, fl);
    KLTStoreFeatureList(fl, ft, 1);
    sprintf(outfile2, "sift_features/img/feat%d-tracked.ppm", i+1);
    KLTWriteFeatureListToPPM(fl, img2, ncols, nrows, outfile2);
    
    sprintf(txt_name, "sift_features/features%d-%d.txt", i, i+1);
    sprintf(ft_name, "sift_features/features%d-%d.ft", i, i+1);
    
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

