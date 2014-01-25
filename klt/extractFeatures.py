import re
import argparse

def extract(features="klt"):
    directory = '%s_features' %(features)

    color = 0
    for i in xrange(99):
        infile = '%s/features%d-%d.txt' %(directory, i, i+1)
        outfile = '%s/features%d-%d.csv' %(directory, i, i+1)

        fin = open(infile, 'r')
        fout = open(outfile, 'w')

        loop = True
        while(loop):
            line = fin.readline()
            if (not line):
                loop = False
            if (re.match(r'\s+\d+\s\|', line)):
                coords = re.split('[^\d\.]+', line.strip())
                fout.write('%s,%s,%s,%s,%d\n' %(coords[1], coords[2], \
                        i, coords[3], color))
                fout.write('%s,%s,%s,%s,%d\n' %(coords[4], coords[5], \
                        i+1, coords[6], color))

                color += 1
        fin.close()
        fout.close()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--feat', dest='feat', default="klt")

    args = parser.parse_args()
    extract(args.feat)


main()

