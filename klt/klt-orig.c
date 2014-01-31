/**********************************************************************
 * KLT tracking framework from http://www.ces.clemson.edu/~stb/klt/, 
 * modified to take some parameters from command line arguments
 * and track a new set of features for each pair of frames.
 * Reads in pgm images.
 *
 * Writes parameters used to external file klt-metrics.txt.
 * Writes feature files to klt_features/features{frame1}-{frame2}.txt.
 *********************************************************************/

#include <stdlib.h>
#include <stdio.h>
#include "pnmio.h"
#include "klt.h"
#include <unistd.h>


int main(int argc, char **argv)
{
  unsigned char *img1, *img2;
  char infile1[100], infile2[100], outfile1[100], outfile2[100], txt_name[100], ft_name[100];
	char *root_dir;
  KLT_TrackingContext tc;
  KLT_FeatureList fl;
  KLT_FeatureTable ft;
  int nFeatures = 20000;
  int ncols, nrows;
  int i;
	int param;
	int nFrames = 100, window = 3, eigenval = 10, searchRange = 3; 
	FILE *fh;

  tc = KLTCreateTrackingContext();

	// Get params from the command line
	while ((param = getopt (argc, argv, "n:w:e:s:")) != -1) {
  	switch (param)  {
			case 'n':
				nFrames = atoi(optarg);
				break;
    	case 'w':
      	window = atoi(optarg);
        break;
    	case 'e':
      	eigenval = atoi(optarg);
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
	printf("nFrames: %d, window: %d, eigenvalue: %d, searchRange: %d\n", nFrames, window, eigenval, searchRange); 

	// Print params to file
	fh = fopen("klt-metrics.txt", "a");
	fprintf(fh, "%d\t%d\t%d\t%d\n", nFrames, window, eigenval, searchRange);
	fclose(fh);


  // Parameters
  tc->mindist = 7;
  tc->min_eigenvalue = eigenval;
  tc->smoothBeforeSelecting = TRUE;
  tc->window_width = window;
  tc->window_height = window;
	tc->max_residue = 10.0f;
  tc->grad_sigma = 0.5f;
  tc->smooth_sigma_fact = 0.4f;
  KLTChangeTCPyramid(tc, searchRange);
  KLTUpdateTCBorder(tc);
  tc->sequentialMode = TRUE;
  tc->writeInternalImages = FALSE;
  tc->affineConsistencyCheck = 2; 
 
	// Read in first image and allocate memory for the second
	root_dir = "/n/home08/vtan/isbi_2013/pgms";
	sprintf(infile1, "%s/train-input-norm-0.pgm", root_dir);
  img1 = pgmReadFile(infile1, NULL, &ncols, &nrows);
  img2 = (unsigned char *) malloc(ncols*nrows*sizeof(unsigned char));

  fl = KLTCreateFeatureList(nFeatures);
  ft = KLTCreateFeatureTable(2, nFeatures);
  
	KLTSetVerbosity(0);

  for (i = 0; i < nFrames - 1; i++)  {
		// Read pair of images
    sprintf(infile1, "%s/train-input-norm-%d.pgm", root_dir, i);
    sprintf(infile2, "%s/train-input-norm-%d.pgm", root_dir, i+1);
    pgmReadFile(infile1, img1, &ncols, &nrows);
    pgmReadFile(infile2, img2, &ncols, &nrows);

		// Select and track features
    sprintf(outfile1, "klt_features/img/feat%d.ppm", i);
    KLTSelectGoodFeatures(tc, img1, ncols, nrows, fl);
    KLTStoreFeatureList(fl, ft, 0);
    KLTWriteFeatureListToPPM(fl, img1, ncols, nrows, outfile1);
    KLTTrackFeatures(tc, img1, img2, ncols, nrows, fl);

		// Store feature lists
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

