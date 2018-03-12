# 16S_process.sh

# shell script for processing the NWPac 16S amplicon data
# Jamie Collins, Armbrust Lab, University of Washington; james.r.collins@aya.yale.edu
# some of this is based on the script "16Smothurpipeline_v2.sh" by Rachelle Lim (formerly in Armbrust Lab)

# inputs this script: raw amplicon sequence files
# outputs: OTU abundance information for input into phyloseq R analyses

# assumes:
# 1. we've already run scripts to install necessary dependencies, including mothur, boost, boost-python, and rclone
# 2. mothur is already be added to the path
# 3. scripts folder must also be added to the path

# sample filename format (from sequencer) should be:
# PRIMER-SAMPLENAME_BARCODE_R1.fastq (e.g., V4_515F_New_V4_806R_New-64039_ATTAGCGAGT_R2.fastq)

# ----------------------------------------------------
# pre-processing steps
# ----------------------------------------------------

# get rid of any hyphens in fastq filenames
cd "/Users/jamesrco/Dropbox/Archived science projects & data/Projects & science data/2018/NWPac 16S & 18S/fastq/"
find . -name "*.fastq" -exec bash -c 'mv "$1" "${1//-/_}"' - '{}' \;

# count the number of sequence-containing .fastq files in the directory structure (for comparison to e.g., a sample list)

# we want to exclude from this count .fastq files such as the "unmatchedIndex.fastq" files (hence the use of the regex)
find . -name "*[1|2].fastq" | wc -l

# just the number of 16S files
find . -name "V4_515F_New_V4*[1|2].fastq" | wc -l

# just the number of 18S files
find . -name "F566Euk_R1200Euk*[1|2].fastq" | wc -l

# merge paired-end reads
# we will use mothur, but you could in theory use pear or some other software for this as well

