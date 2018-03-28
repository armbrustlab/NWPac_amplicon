#!/bin/bash

# 01_local_copy_to_vagrant.sh

# shell script for copying necessary files from user's local machine to a vagrant box running ubuntu
# also, could be used to copy the same items to an AWS image, with some modifications
# Jamie Collins, Armbrust Lab, University of Washington; james.r.collins@aya.yale.edu

# *** run this script before trying to execute any shell scripts on the remote machine
# *** if using AWS: will assume we've allowed SSH traffic in the security group we used to set up our machine image

# ----------------------------------------------------
# secure copy necessary files to the remote
# ----------------------------------------------------

# *** these commands should be run on your local machine, not the host

# copy shell provisioning and bioinformatics scripts

cd ~/Code/NWPac_amplicon/remote_shell_scripts/
scp -i /Users/jamesrco/Vagrant/.vagrant/machines/default/virtualbox/private_key -P 2222 * vagrant@127.0.0.1:. # have to specify the private key, otherwise won't work

# copy the rclone config file called ".rclone.conf" to the remote 

scp -i /Users/jamesrco/Vagrant/.vagrant/machines/default/virtualbox/private_key -P 2222 ~/.rclone.conf vagrant@127.0.0.1:.