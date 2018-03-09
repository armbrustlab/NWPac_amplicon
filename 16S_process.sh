# 16S_process.sh
# shell script for processing the NWPac 16S amplicon data
# Jamie Collins, Armbrust Lab, University of Washington; james.r.collins@aya.yale.edu

# assumes we are setting up from scratch on a Ubuntu machine image
# *** also assumes we've allowed SSH traffic in the security group we used to set up our machine image

# ----------------------------------------------------
# secure copy some necessary files to the remote
# ----------------------------------------------------

# use scp to copy the rclone config file called ".rclone.conf" to the remote 
# *** ?

# ----------------------------------------------------
# install, set up necessary packages
# ----------------------------------------------------

# 1. rclone (allows command-line access to Dropbox, Google Drive, etc.)

# install
curl https://rclone.org/install.sh | sudo bash 

# configure rclone so it knows where the config file is
rclone config --config="/.rclone.conf"

# 2. mothur

# install dependencies, if required

# mac requires that boost first be installed; haven't verified this is necessary yet on Ubuntu
brew install boost
brew install boost-python

# install mothur itself and add installation directory to path

# option 1: direct download latest compiled release from the Github repo (no compilation necessary)
export VERSION=$(curl -s "https://github.com/mothur/mothur/releases/latest" | grep -o 'tag/[v.0-9]*' | awk -F/ '{print $2}')
# linux
curl -L https://github.com//mothur/mothur/releases/download/$VERSION/Mothur.linux_64.zip | tar -xz
# mac
curl -L https://github.com//mothur/mothur/releases/download/$VERSION/Mothur.mac_64.OSX-10.12.zip | tar -xz
cd mothur
export PATH=$PATH:$(pwd)

# option 2: download latest zipball, then compile
curl -L https://api.github.com/repos/mothur/mothur/zipball > mothur-latest.tar.gz
mkdir mothur-latest
tar -xzf mothur-latest.tar.gz -C mothur-latest
cd mothur-latest/*/
make
export PATH=$PATH:$(pwd)

# ----------------------------------------------------
# pre-processing steps
# ----------------------------------------------------

# get rid of any hyphens in fastq filenames

cd "/Users/jamesrco/Dropbox/Archived science projects & data/Projects & science data/2018/NWPac 16S & 18S/fastq/"
find . -name "*.fastq" -exec bash -c 'mv "$1" "${1//-/_}"' - '{}' \;

# count the number of sequence-containing .fastq files in the directory structure (for comparison to e.g., a sample list)
# we want to exclude from this count .fastq files such as the "unmatchedIndex.fastq" files (hence the use of the regex)

find . -name "*[1|2].fastq" | wc -l

# merge paired-end reads
# we will use mothur, but you could use pear for this as well

