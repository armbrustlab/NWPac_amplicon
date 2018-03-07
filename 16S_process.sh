# 16S_process.sh
# shell script for processing the NWPac 16S amplicon data

# get rid of any hyphens in fastq filenames

cd "/Users/jamesrco/Dropbox/Archived science projects & data/Projects & science data/2018/NWPac 16S & 18S/fastq/"
find . -name "*.fastq" -exec bash -c 'mv "$1" "${1//-/_}"' - '{}' \;

# count the number of sequence-containing .fastq files in the directory structure (for comparison to e.g., a sample list)
# we want to exclude from this count .fastq files such as the "unmatchedIndex.fastq" files (hence the use of the regex)

find . -name "*[1|2].fastq" | wc -l

# make folders for pear