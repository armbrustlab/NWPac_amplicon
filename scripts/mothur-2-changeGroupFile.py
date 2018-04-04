#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
mothur-2-changeGroupFile.py

Created on Tue Nov  1 16:15:50 2016 by @rachellelim
Revised on Tue Apr  3 14:12:33 2018 by @jamesco; subsequent version history on GitHub

@author: rachellelim
@author: jamesrco

Purpose: To make the groups file accord with the contigs file - some mismatches because 
of trimming the primer regions after merging reads and then discarding those 
reads that had any mismatches to the primer

Can also be used to change the taxonomy file after removing singletons 
(next time I'll do this earlier in the pipeline)

Dependencies: Python 2; Python package Biopython ('Bio') and dependencies (numpy, etc.)

If python2 is not in user's path, have to specify it above; further assumes 'python2'
will call your version of Python 2.x

"""

import sys
from Bio import SeqIO

def readFasta(fastaFile):
    seqSet = set()
    fastaSeqs = SeqIO.parse(open(fastaFile), "fasta")
    for seq in fastaSeqs:
        seqSet.add(seq.id)
    print "No. sequences in contigs file \"" + fastaFile + "\": " + str(len(seqSet))
    return seqSet

def writeGroupFile(seqSet, groupFile, outputFile):
    outfile_ctr = 0
    infile_ctr = 0
    with open(groupFile, "r") as inFile:
        with open(outputFile, "w") as outFile:
            for line in inFile:
                infile_ctr += 1
                if line.split()[0] in seqSet:
                    outFile.write(line)
                    outfile_ctr += 1
    print "No. sequences in original groups file \"" + groupFile + "\": " + str(infile_ctr)
    print "No. sequences written to new shortened groups file \"" + outputFile + "\": " + str(outfile_ctr)
    
def main():
    fastaFile = sys.argv[1]
    groupFile = sys.argv[2]
    outputFile = sys.argv[3]
    #readFasta(fastaFile)
    print writeGroupFile(readFasta(fastaFile), groupFile, outputFile)
#    with open(groupFile, "r") as inFile:
#        line = inFile.readline()
#        print line.split()[0]
    
if __name__ == "__main__":
    main()


