#!/bin/bash

# 02_metagenomics_amplicon_provision.sh

# shell script for installing necessary tools for analysis of 16S/18S amplicon sequence data
# Jamie Collins, Armbrust Lab, University of Washington; james.r.collins@aya.yale.edu

# assumes we are setting up from scratch on a Ubuntu 16.04 machine image, perhaps using the script "01_vagrant_provision_ubuntu.sh"
# *** if using AWS: also assumes we've allowed SSH traffic in the security group we used to set up our machine image

# ----------------------------------------------------
# install, set up necessary packages (if not yet installed)
# ----------------------------------------------------

# ----------------------------------------------------
# python and necessary components 
# ----------------------------------------------------

# python 2

sudo apt install python-minimal

# pip

sudo apt-get update && sudo apt-get install python-pip

# biopython (pip will install numpy as well)

pip install biopython
# conda install -c anaconda biopython # achieves same thing if using conda

# ----------------------------------------------------
# mothur
# ----------------------------------------------------

# # install dependency: boost (doesn't appear to be necessary on ubuntu)

# brew install boost
# brew install boost-python

# install mothur itself and add installation directory to path

# option 1: direct download latest compiled release from the Github repo (no compilation necessary)
export VERSION=$(curl -s "https://github.com/mothur/mothur/releases/latest" | grep -o 'tag/[v.0-9]*' | awk -F/ '{print $2}')

# ubuntu
wget https://github.com//mothur/mothur/releases/download/$VERSION/Mothur.linux_64.zip
unzip Mothur.linux_64.zip

# # mac
# curl -L https://github.com//mothur/mothur/releases/download/$VERSION/Mothur.mac_64.OSX-10.12.zip | tar -xz

cd mothur
export PATH=$PATH:$(pwd)

# # option 2: download latest zipball, then compile
# curl -L https://api.github.com/repos/mothur/mothur/zipball > mothur-latest.tar.gz
# mkdir mothur-latest
# tar -xzf mothur-latest.tar.gz -C mothur-latest
# cd mothur-latest/*/
# make
# export PATH=$PATH:$(pwd)

# ----------------------------------------------------
# PEAR (if desired)
# ----------------------------------------------------

# # option 1: compile from old source on GitHub
# # N.B. this snippet will load a much older version of the code still hanging out on GitHub, which I (Jamie) have
# # forked to my GitHub account

# git clone https://github.com/jamesrco/PEAR.git ~/Code/PEAR
# cd ~/Code/PEAR
# ./configure
# make clean
# make

# # option 2: build from latest source
# # it seems that the *latest* version of PEAR is now available here via some convoluted download service:
# # http://www.exelixis-lab.org/web/software/pear
# # *** this makes it difficult to source and install using any sort of script, but if you want to do this (and are successful)
# # you will end up downloading the latest release source as a zipball (the file "pear-src-0.9.11.tar.gz" or similar)

# # you can then try the following, per guidance I received in response to a post on the PEAR user forum:
# # https://groups.google.com/forum/#!topic/pear-users/zvaVbn4BVGU

# # once in the directory where you unzipped your tarred zipball...

# # may have to execute the additional command on line below ("autoreconf -i") if you are building from source on a mac
# # autoreconf -i
# ./configure
# make clean
# make


