#!/bin/bash

# get_mothurSilvafile.sh

# shell script to retrieve the latest mothur-compatible Silva reference database from
# https://www.mothur.org/wiki/Silva_reference_files

# Jamie Collins, Armbrust Lab, University of Washington; james.r.collins@aya.yale.edu

# *** if this doesn't work (which is possible, since I'm quite sure there's no API for the mothur wiki page),
# user should manually download the latest "Full length sequences and taxonomy references" file from
# https://www.mothur.org/wiki/Silva_reference_files ... and then, let @jamesrco know so he can fix the script

# ----------------------------------------------------
# meat and potatoes
# ----------------------------------------------------

echo "Attempting to retrieve the latest mothur-compatible Silva reference database from the mothur wiki page..."
echo "If this fails, you should download the latest 'Full length sequences and taxonomy references' file from the wiki yourself and supply it as the 'v4ref' V4 references file..."; echo

# attempt to find the link to the latest full reference file from https://www.mothur.org/wiki/Silva_reference_files, then download it
latestDBlink=$(curl https://www.mothur.org/wiki/Silva_reference_files | grep -Eoi '<a [^>]+>' |  grep -Eo 'href="[^\"]+"' |  grep -Eo '(((http|https)://)|/).*Silva\.nr_v.*\.tgz' | head -1)

# test to make sure we got something

if [ ! -n "${latestDBlink}" ]; then
	# we didn't get anything; let user know 
	echo "Unable to find any new database files on the mothur wiki site."
	echo "You might want to check that the script is matching patterns correctly, and that the wiki page hasn't moved. If you didn't supply your own database file, the sequence alignment step later in the pipeline will fail."
fi

if echo "${latestDBlink}" | grep -q '^/.*Silva\.nr_v.*\.tgz'; then
	# the URL is a relative link and we have to append the domain to it
	latestDBlink="https://www.mothur.org${latestDBlink}"
fi

if [ ! -d ~/databases ]; then
  mkdir ~/databases
fi

echo; echo "Downloading latest mothur-compatible Silva database from ${latestDBlink} ..."
wget $latestDBlink -P ~/databases/ # if on a mac, try curl -L instead of wget
tar -xvzf ~/databases/$(basename "$latestDBlink") -C ~/databases/ # this may require a lot of disk space
