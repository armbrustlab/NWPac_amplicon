#!/bin/bash

# 01_vagrant_provision_ubuntu.sh

# shell script for provisioning vagrant box running ubuntu 16.04
# also, could be the basis for provisioning an AWS image, or simply for getting all the necessary software
# for this great adventure up and running on your own computer

# Jamie Collins, Armbrust Lab, University of Washington; james.r.collins@aya.yale.edu

# *** assumes this shell script is present on the remote computer (not your local machine)
# to do this, you can use the associated scripts 01_local_copy_to_vagrant.sh or 01_local_copy_to_AWS.sh

# *** if using AWS: will assume we've allowed SSH traffic in the security group we used to set up our machine image

# to run: source ./01_vagrant_provision_ubuntu.sh

# ----------------------------------------------------
# provision ubuntu 16.04 environment
# ----------------------------------------------------

# install unzip
sudo apt-get install unzip

# install, configure rclone (allows command-line access to Dropbox, Google Drive, etc.)
curl https://rclone.org/install.sh | sudo bash 
echo "q" | rclone config --config=".rclone.conf"

# install brew (for Ubuntu; avoids password prompt)
sudo apt-get install build-essential curl file git python-setuptools
sudo apt install linuxbrew-wrapper
test -d ~/.linuxbrew && PATH="$HOME/.linuxbrew/bin:$HOME/.linuxbrew/sbin:$PATH"
test -d /home/linuxbrew/.linuxbrew && PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH"
test -r ~/.bash_profile && echo "export PATH='$(brew --prefix)/bin:$(brew --prefix)/sbin'":'"$PATH"' >>~/.bash_profile
echo "export PATH='$(brew --prefix)/bin:$(brew --prefix)/sbin'":'"$PATH"' >>~/.profile
echo "export PATH='/home/linuxbrew/.linuxbrew/bin'":'"$PATH"'

# # install brew (for Linux, or Ubuntu if you know the root password)
# sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)"
# test -d ~/.linuxbrew && PATH="$HOME/.linuxbrew/bin:$HOME/.linuxbrew/sbin:$PATH"
# test -d /home/linuxbrew/.linuxbrew && PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH"
# test -r ~/.bash_profile && echo "export PATH='$(brew --prefix)/bin:$(brew --prefix)/sbin'":'"$PATH"' >>~/.bash_profile
# echo "export PATH='$(brew --prefix)/bin:$(brew --prefix)/sbin'":'"$PATH"' >>~/.profile
# echo "export PATH='/home/linuxbrew/.linuxbrew/bin'":'"$PATH"'
