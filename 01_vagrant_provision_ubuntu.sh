#!/bin/bash

# vagrant_provision_ubuntu.sh

# shell script for provisioning vagrant box running ubuntu 16.06.4
# also, could be the basis for provisioning an AWS image
# Jamie Collins, Armbrust Lab, University of Washington; james.r.collins@aya.yale.edu

# *** if using AWS: will assume we've allowed SSH traffic in the security group we used to set up our machine image

# ----------------------------------------------------
# secure copy necessary files to the remote
# ----------------------------------------------------

# use scp to copy the rclone config file called ".rclone.conf" to the remote 

scp -i /Users/jamesrco/Vagrant/.vagrant/machines/default/virtualbox/private_key -P 2222 ~/.rclone.conf vagrant@127.0.0.1:.

# ----------------------------------------------------
# provision ubuntu 16.06.4 environment
# ----------------------------------------------------

# install unzip
sudo apt-get install unzip

# install, configure rclone (allows command-line access to Dropbox, Google Drive, etc.)
curl https://rclone.org/install.sh | sudo bash 
echo "q" | rclone config --config=".rclone.conf"

# install brew (if needed)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)"
test -d ~/.linuxbrew && PATH="$HOME/.linuxbrew/bin:$HOME/.linuxbrew/sbin:$PATH"
test -d /home/linuxbrew/.linuxbrew && PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH"
test -r ~/.bash_profile && echo "export PATH='$(brew --prefix)/bin:$(brew --prefix)/sbin'":'"$PATH"' >>~/.bash_profile
echo "export PATH='$(brew --prefix)/bin:$(brew --prefix)/sbin'":'"$PATH"' >>~/.profile

