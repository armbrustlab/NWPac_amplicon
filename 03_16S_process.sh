#!/bin/bash

# 16S_process.sh

# a shell script for processing the NWPac 16S amplicon data
# Jamie Collins, Armbrust Lab, University of Washington; james.r.collins@aya.yale.edu
# some of this is based on the script "16Smothurpipeline_v2.sh" by Rachelle Lim (formerly in Armbrust Lab)

# inputs to this script: raw amplicon sequence files; some file paths in the variables section below
# outputs: OTU abundance information for input into phyloseq R analyses

# assumes:
# 1. we've already run scripts to provision a machine (if necessary) and install necessary dependencies, including mothur, 
# boost, boost-python, and rclone (perhaps with the scripts "01_vagrant_provision_ubuntu.sh" and "02_metagenomics_amplicon_provision.sh")
# 2. mothur is already be added to the path
# 3. scripts is also be added to the path

# some basic formatting directions, so that this all works correctly:
# 1. filename format (from sequencer) should be:
# PRIMER-SAMPLENAME_BARCODE_R1.fastq (e.g., V4_515F_New_V4_806R_New-64039_ATTAGCGAGT_R2.fastq)
# 2. all 16S files should begin with "V4_515F_New_V4," but can be stored in any directories or subdirectories so long as complementary 
# forward and reverse reads are stored together
# 3. the file paths between the primary fastq data directory (whatever you specify for "file_dir", below) and the locations of your
# fastq files should contain no spaces or special characters other than underscores

# ----------------------------------------------------
# specify some file locations and other variables
# ----------------------------------------------------

file_dir="/Users/jamesrco/Dropbox/Archived science projects & data/Projects & science data/2018/NWPac 16S & 18S/fastq/"
# OLIGOS="/mnt/nfs/home/rlalim/gradientscruise/16S/oligos.fa"
# V4REF="/mnt/nfs/home/rlalim/gradientscruise/db/silva.v4.fasta"
# DB_REF="/mnt/nfs/home/rlalim/gradientscruise/db/silvaNRv128PR2plusMMETSP.fna"
# DB_TAX="/mnt/nfs/home/rlalim/gradientscruise/db/silvaNRv128PR2plusMMETSP.taxonomy"
# TAXNAME="silvaNRv128PR2plusMMETSP"
# PREFIX="16S_stations"
# CLASS_CUTOFF=60 #bootstrap value for classification against the reference db at which the taxonomy is deemed valid
# OTU_CUTOFF=0.03 #percent similarity at which we want to cluster OTUs
# MAXLENGTH=275 #max sequence length when merged
# BAD_TAXA="Mitochondria-unknown-Archaea-Eukaryota-Chloroplast"

# ----------------------------------------------------
# pre-processing/"cleanup" steps
# ----------------------------------------------------

# get rid of any hyphens in fastq filenames
echo "Now working on files in or in suboordinate directories to:"
echo $file_dir

echo "Converting any hyphens in filenames to underscores..."
cd ''"$file_dir"''
find . -name "*.fastq" -exec bash -c 'mv "$1" "${1//-/_}"' - '{}' \;

# count the number of sequence-containing .fastq files in the directory structure (for comparison to e.g., a sample list)
# we want to exclude from this count .fastq files such as the "unmatchedIndex.fastq" files (hence the use of the regex)

echo "Total number of .fastq files in the current directory or in suboordinate directories:"
find . -name "*[1|2].fastq" | wc -l

echo "Total number of 16S-containing .fastq files in the current directory or in suboordinate directories:"
find . -name "V4_515F_New_V4*[1|2].fastq" | wc -l

# # make a list of the fastq filenames
# echo "Saving a list of 16S .fastq filenames..."
# find . -name "V4_515F_New_V4*[1|2].fastq" > 16S_fastq_filenames.txt

# ----------------------------------------------------
# pre-processing steps
# ----------------------------------------------------

# merge paired-end reads
# we will use mothur, but you could in theory use pear or some other software for this as well
echo "Now merging paired-end 16S reads using mothur. Check mothur logfiles for results..."

# get relative paths of all the subdirectories which contain 16S .fastq files
subdirs_16S=$(find . -type f -name 'V4_515F_New_V4_806R_New*.fastq' | grep -o "\(.*\)/" | sort -u | cut -c 3-)

# now, iterate through the list of subdirectories and generate stability files
for subdir in $subdirs_16S
do
	# sending to /dev/null suppresses output
	mothur "#make.file(inputdir='$subdir', type=fastq)" > /dev/null
	echo "mothur now making stability file for 16S files in directory:"
	echo $subdir
done

