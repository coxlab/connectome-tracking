#include "pnmio.h"
#include "klt.h"

int main() {
    KLT_FeatureList fl;
    KLT_FeatureHistory fh;
    KLT_FeatureTable ft;
    int i;

    ft = KLTReadFeatureTable(NULL, "features2.txt");
    fl = KLTCreateFeatureList(ft->nFeatures);
    KLTExtractFeatureList(fl, ft, 0);
    KLTWriteFeatureList(fl, "feat-test.txt", "%3.1f");

}
