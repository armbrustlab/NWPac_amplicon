# NWPac_amplicon

Scripts and other necessary files to build a cloud- or cluster-ready pipeline for workup of 16S/18S amplicon sequence data. The pipeline is designed to be fully reproducible. Currently configured to process data from three cruises in the NW Pacific Ocean.

## Software we'll need

These scripts and directions assume you are beginning with a blank machine image -- i.e., with nothing but the operating system and the standard preinstalled packages. Depending on your platform, you may already have some or all of the necessary software installed. If so, go ahead and skip right to the processing scripts. To execute the scripts in this pipeline, you'll need:

   * **Python 2.7**, with the **[Biopython package](http://biopython.org/wiki/Download)** and all its dependencies
   * a working version of **git**
   * **[mothur](https://www.mothur.org/wiki/Download_mothur)** (may require the package **boost**, depending on your platform)
   * the ability to execute both **python2** and **mothur** anywhere from the command line (ensure the binaries are in your PATH or you have the appropriate symbolic links)
   * a configured instance of **rclone**, if you will be accessing your .fastq files from a Dropbox or Google Drive location
   
If you don't have some or all of these installed, you don't know what any of this means, or you're starting from scratch: Never fear -- that's what these directions are for.

## First step: Machine prep and provisioning

First, we'll initialize, start up and provision a cloud computing instance or local Vagrant box.

### Option 1: Use an AWS machine image

[Log into your AWS console](https://console.aws.amazon.com/console/home), then your [EC2 Management Console](https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2). (The second link will only work for you if you use US West (Oregon) like I do -- otherwise, just use the EC2 link on your [console homepage](https://console.aws.amazon.com/console/home).) Once at EC2, launch a Ubuntu Server 16.04 machine image and configure it as desired. *Remember to give yourself enough storage to hold all your input (raw) .fastq files and all the files/products you'll be producing along the way. These intermediate products can be quite large.*

Launch the image, making sure you create an SSH key pair if you haven't already done so. (This is how you'll access your machine image once its running. Amazon has some [basic directions here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AccessingInstancesLinux.html) to connect to its machine images via SSH. An even better guide to creating and protecting ssh keys using **ssh-keygen** [can be found here](http://people.seas.harvard.edu/~nater/ec2-keyauth/).) As a general best practice, you should make sure your private key file *isn't* publicly accessible and *is* password protected; these can be accomplished using the **chmod** and **ssh-keygen -p -f** commands; see [this page](http://people.seas.harvard.edu/~nater/ec2-keyauth/) for directions.)

Wait for your AMI to get up and running (you can monitor its status via your EC2 console; wait until Instance State indicates "running," with a green dot). Once running, connect to the image via SSH. Assuming again that you launched a Ubuntu machine image, open a new shell (this is the "Terminal" on a Macintosh) and connect to your AMI via SSH by typing:
```
ssh -i /path/to/my-key-pair.pem ubuntu@ec2-198-51-100-1.compute-1.amazonaws.com
```
where `/path/to/my-key-pair.pem` is the path (on *your* computer) to your private key file. The private key file is (suprise!) the private half of the key pair you specified or created when you launched the machine image. The next bit (`ubuntu@ec2-198-51-100-1.compute-1.amazonaws.com` in this example) is the username and server address. On a Mac, your ssh keys should be in the .ssh folder in your user directory (`~/.ssh`). You can get get the server address from the information provided for the image in your EC2 console. (Copy the address listed in the column called "Public DNS.") Answer "yes" when SSH asks you if you want to continue connecting; you should then receive a response telling you the AMI has been added to your list of known hosts. Note that you use the username `ubuntu` when connecting to a Ubuntu instance; you would replace the `ubuntu` bit with `ec2-user` if connecting to an Amazon Linux or Red Hat EC2 instance. (A good rundown of these idiosyncracies [can be found here](https://99robots.com/how-to-ssh-to-ec2-instance-on-aws/).)

Once you are securely connected to your machine image, it's time to provision it. (Once you are connected to the remote client via SSH, your shell prompt should change from what you're used to seeing to something like `ubuntu@ip-172-31-23-22:~$`). First, let's make sure git is installed, since we'll be cloning the scripts and other files in this repository directly to a new repository on the machine image.
```
sudo apt install git
```
You should receive a message indicating git is already installed; if so, that's great -- but it's worth double-checking.

Next, let's clone a copy of this repository to the machine image. This is an easier way of obtaining all the necessary scripts and files than using secure copy (scp) -- and using git ensures you'll be downloading and using the very latest versions of the scripts/files maintained here on GitHub. We'll clone the repository into a new local repo of the same name. 
```
git clone https://github.com/jamesrco/NWPac_amplicon NWPac_amplicon
```

Now, we can change directories to the newly cloned repository and run the provisioning scripts. The [first script](scripts/01_provision_ubuntu.sh) will install unzip and rclone. rclone will be useful if we want to access our .fastq files from a Dropbox or Google Drive location. 
```
cd NWPac_amplicon/scripts
source ./01_provision_ubuntu.sh
```

The [second script](scripts/02_metagenomics_amplicon_provision.sh) will install Python 2.7 and the necessary bioinformatics    tools, including the Biopython package and mothur:
```
source ./02_metagenomics_amplicon_provision.sh
```
Answer yes ("Y") to any prompts.

### Option 2: Configure a Vagrant box

Doing all of this in a Vagrant box on your own computer is useful for testing new features, etc., without having to set up (and pay for) a cloud computing instance. You'll likely never need these directions unless you're developing and testing new shell scripts.

If on a Mac: Install and configure [Vagrant](https://www.vagrantup.com/) using these great directions here: http://sourabhbajaj.com/mac-setup/Vagrant/README.html. I'd also install the [vagrant-disksize plugin](https://github.com/sprotheroe/vagrant-disksize) because some of the stock box images have insufficient storage space for playing around with sequence data. To install:
```
vagrant plugin install vagrant-disksize
```

Once Vagrant (and vagrant-disksize) are installed, use Vagrant command `vagrant box add` to add whatever box(es) you want; the full listing of available boxes is [here](https://app.vagrantup.com/boxes/search). I'd recommend also creating a new directory to park your Vagrant init and logfiles. (On a Mac at least, the Vagrant boxes themselves live at `~/.vagrant.d/boxes`.) To add the latest Ubuntu 16.04 box:
```
vagrant box add xenial64 http://files.vagrantup.com/xenial64.box
```

Now, let's initialize and start up our box. The initialization step will be subsequently unnecessary so long as you wish to use the same box. (If changing boxes, you must initialize again with the name of the new box.)
```
vagrant init xenial64
vagrant up
```
This sometimes takes a bit. Once the box is ready, you will be returned to the shell prompt.

At this point, you can connect to the Vagrant box using ssh, install git, use git to clone the scripts and files to a new local repository, and then execute the two provisioning scripts as above:
```
sudo apt install git
git clone https://github.com/jamesrco/NWPac_amplicon NWPac_amplicon
cd NWPac_amplicon/scripts
source ./01_provision_ubuntu.sh
source ./02_metagenomics_amplicon_provision.sh
```
Answer yes ("Y") to any prompts.

## Next step: Copying files to the remote client

### Option 1: Secure copy (scp)

One way to get all your sequence files onto your AWS remote client or Vagrant box is **scp** (secure copy). For a variety of reasons, you might find this prohibitive, or just annoying. If you do choose to go this route, zip all your files into a single archive (or a few archives) and then try:
```
scp -i /path/to/my-key-pair.pem /local/path/to/file/SampleFile.txt ubuntu@c2-198-51-100-1.compute-1.amazonaws.com:/path/to/remote/destination
````
where `/path/to/my-key-pair.pem` is (as above) the path (on *your* computer) to your private key file, `/local/path/to/file/SampleFile.txt` is the location of the file you wish to copy, `ubuntu@c2-198-51-100-1.compute-1.amazonaws.com` is the username and address of your AWS client, and `/path/to/remote/destination` is the location where you want the file to end up on the remote end. Note that there's a colon separating the address and the remote path.

To copy the same file to a local Vagrant box, assuming the box can be reached at 127.0.0.1 on port 2222 (the defaults):
```
scp -i /path/to/Vagrant/.vagrant/machines/default/virtualbox/private_key -P 2222 /local/path/to/file/SampleFile.txt vagrant@127.0.0.1:/path/to/remote/destination 
```
With Vagrant, scp would not work unless I specified the path to the default Vagrant private key. It should be in the directory `.vagrant`, subordinate to the directory in which you added and initialized your Vagrant box. (Apparently, you can also specify a custom key pair by messing with some Vagrant box settings; I didn't waste my time with this step.)  If you're doing a lot of testing with Vagrant, you might find the instructions [here](https://superuser.com/questions/317036/ignore-known-hosts-security-in-ssh-for-some-addresses) and [here](http://www.kevssite.com/how-to-stop-ssh-from-adding-a-server-to-known_hosts-file/) useful to prevent ssh from adding every new Vagrant box to your known hosts lists. I would *not* disable any security features for ssh connections to AWS instances.

### Option 2: Use rclone to access files directly from the remote client

Another (perhaps easier) option is to use rclone to grab all the .fastq files you will want directly from a Dropbox or Google Drive location. This frees you from having to download all the files onto your computer, zip them into archives, and then manually copy them to the remote, as above. *Note: Once you've uploaded your rclone configuration file to the remote and/or you've configured things using the `config` command, anyone with access (authorized or unauthorized) to the remote client will have full access to whatever cloud storage locations you've configured. The ssh tunnel provides you with some security, but be wary.*

The [first provisioning script](scripts/01_provision_ubuntu.sh) downloads and installs rclone, so you're already halfway there. Once installed, you'll need to either (1) upload a configuration file or (2) configure things using the built-in `config` command.

**Case 1:** If you've already configured rclone on your own computer and you will be grabbing .fastq files from one of the locations in your existing rclone configuration, you can simply copy the config file `.rclone.conf` right on over to your remote using **scp**:
```
scp -i /path/to/my-key-pair.pem ~/.rclone.conf ubuntu@c2-198-51-100-1.compute-1.amazonaws.com:.
```
or, for a Vagrant box, assuming you installed rclone right into your home directory:
```
scp -i /path/to/Vagrant/.vagrant/machines/default/virtualbox/private_key -P 2222 ~/.rclone.conf vagrant@127.0.0.1:.
```
The rclone instance installed by the [provisioning script](scripts/01_provision_ubuntu.sh) is already looking for the `.rclone.conf` file in the home directory, so you should be ready to go.

**Case 2:** If you don't have a config file to upload and need to configure rclone, ssh into the remote (if you're not still connected) and run
```
rclone config
````
to perform setup. Further directions are here: https://rclone.org/docs/

**Copying files using rclone**: Once configured, copying files with rclone is fairly straightforward. See https://rclone.org/commands/rclone_copy/, in addition to some specific directions for [Dropbox](https://rclone.org/dropbox/) and [Google Drive](https://rclone.org/drive/) (rclone supports lots of other cloud data storage options, too). As an example, let's assume you had a Dropbox source configured under the name "Dropbox" in your `.rclone.conf` file. (You can use `rclone config show` to get a list of what's currently configured; the name of the source will be in brackets.) You want to copy to your AWS instance the contents of a folder deep within your Dropbox called "F566Euk_R1200Euk," which contains .fastq files. You want to copy the files to a new directory on your remote called "F566Euk_R1200Euk_for_analysis". At the shell prompt (on the remote, of course), you would type:
```
rclone copy -v Dropbox:"Path to the/folder/you want/to/copy/F566Euk_R1200Euk/" ~/F566Euk_R1200Euk_for_analysis
```
And voilà! The files should now be on your AWS instance in the directory "F566Euk_R1200Euk_for_analysis" to which you copied them. (If any of the directories in the path to your target folder contain spaces, you'll need to put the path in quotes when you call `rclone copy`.) Using the flag `-v` will allow you to track the progress of your file transfer. 

*A note:* Rclone includes an experimental command [`mount`](https://rclone.org/commands/rclone_mount/) that supposedly lets you mount your cloud storage location directly. I didn't have much luck with this, so I stuck with copying instead. If you can get `rclone mount` to work, I'd love to hear about it.

## Process some data

At this point, we should have a complete environment capable of processing whatever amplicon sequence data we want to throw at it. Assuming you are still connected to your remote, let's move to the `scripts` subdirectory in the repository we cloned from GitHub:
```
cd ~/NWPac_amplicon/scripts/
```

### Modify our "workhorse" script to specify necessary variables

We've already run the first two scripts in this directory to get our environment set up; now we'll make use of the others to process our data. Much of the pipeline written into the scripts is based on the [mothur team's example MiSeq SOP](https://mothur.org/wiki/MiSeq_SOP), with some additional guidance [from this blog post](http://blog.mothur.org/2018/01/10/SILVA-v132-reference-files/).

The main processing script ([03_16S_process.sh](scripts/03_16S_process.sh)) will allow you to process 16S amplicon sequence .fastq data residing in one or more directories subordinate to any file path you specify. If you do have data in a number of different directories, note that these will be combined about a quarter of the way into the process. (If you want to process segments of your data separately for some reason, remember to point the script at only the specific directory of interest.)

Before we run our script, we need to set some variables and file paths. We'll do this by editing the values of several variables within the following section of the processing script [03_16S_process.sh](scripts/03_16S_process.sh):  
```
# ----------------------------------------------------
# specify some file locations and other variables
# ----------------------------------------------------

file_dir="/Users/jamesrco/Dropbox/Archived science projects & data/Projects & science data/2018/NWPac 16S & 18S/fastq/"
# top-level directory under which all .fastq files reside; this is also where mothur output will be
# dumped
prefix="16S" # file prefix to be appended
numproc=4 # number of cores/processors for tasks that can be parallelized
oligos_16S="../primers/16S_oligos.fa" # path to file containing primer sequences
maxlength=275 # max sequence length when merged
supplied_v4ref="../databases/silva.v4.fasta" # path to mothur-compatible reference database for sequence
                                             # alignment; must be specified unless you want this script
                                             # to try and retrieve the latest one for you from
                                             # https://www.mothur.org/wiki/Silva_reference_files
# supplied_DB_ref="/mnt/nfs/home/rlalim/gradientscruise/db/silvaNRv128PR2plusMMETSP.fna"
# supplied_DB_tax="/mnt/nfs/home/rlalim/gradientscruise/db/silvaNRv128PR2plusMMETSP.taxonomy"
# TAXNAME="silvaNRv128PR2plusMMETSP"
# CLASS_CUTOFF=60 # bootstrap value for classification against the reference db at which the taxonomy 
                  # is deemed valid
# OTU_CUTOFF=0.03 #percent similarity at which we want to cluster OTUs
# MAXLENGTH=275 #max sequence length when merged
# BAD_TAXA="Mitochondria-unknown-Archaea-Eukaryota-Chloroplast"
```
You can edit the script on GitHub or on your own computer before you clone the repository to the remote. If you choose to set things up in advance using GitHub, you make your modifications only to files in a fork of the main repository; there's no need to commit changes to scripts in the master branch unless making functional changes to the code. The other benefit to this practice: Creating a fork each time you run the pipeline will allow you to save the parameters and scripts you used such that you (or anyone else) could reproduce your results for that particular dataset, exactly. (Alternatively, you can of course set the values of your variables by editing the script file directly once it's on the remote client.) When editing, the comments following each variable should be self-explanatory. Some of the "default" values for the numeric parameters are drawn from [this example pipeline](https://mothur.org/wiki/MiSeq_SOP).

### Running things: The simplest way

Once you've got everything set the way you want it (and, of course, you've transferred your data files to the location on the remote you've specified for `file_dir`), you should be ready to run the script. Double-check to make sure you've specifed all the necessary file paths correctly, or plan to check back on the progress of your run frequently to make sure the script hasn't thrown an error. (The latter is best practice anyway.) We *could* run the script right away simply by sourcing it at the command line from within the `scripts` directory:
```
source ./03_16S_process.sh
```
This will work fine, *except you'll have to remain connected to the remote instance to keep the processes running.* If you want to be able to disconnect from the remote while your script runs, you'll have to run things in a "screen." (We'll use **tmux** instead of **screen**, so techincally, we'll be in a "tmux session" than a screen.)

### Running things so you can actually disconnect from the remote computer: Setting up a screen

For this, we'll use **tmux**, which is included on most of the Amazon Ubuntu machine images. First, while still connected to the remote machine, we'll start **tmux**:
```
tmux
```
Assuming we are in the `~/NWPac_amplicon/scripts` directory, we can then run exactly the same code as above:
```
source ./03_16S_process.sh
```
... except this time, we're in a screen from which we can "detach" ourselves. Once you see that things are running properly (and have answered yes or no to the prompt described below), we can detach from the screen by typing

<kbd>Ctrl</kbd>+<kbd>b</kbd> and then <kbd>d</kbd>

We are now back out at our shell prompt... but the script is still doing its magic in the background! Upon detaching, you will receive some sort of message like this:
```
[detached (from session 0)]
```
Make a (mental) note of the session number (in this case, "0") because we'll need it a bit later. At this point, we can end our ssh session (i.e., close our connection to the remote) by typing
```
exit
```
... and voilà! You should be back at the command line on your own computer.

### Reconnecting to our tmux session

To reconnect to the remote (and check our progress/run some more scripts/collect our output), open a shell window on your computer and connect via ssh, using the same directions as above. Once reconnected to the remote, we can open up the screen from which detached earlier by calling **tmux** again, this time using `a -t` for `attach` by name:
```
tmux a -t myname
````
where `myname` is the name (session number) of session in which you are running your script. This should be the number of which you earlier made a mental note. If you forgot which session(s) are running, you can try:
```
tmux ls
```
and then pick out the right session number to use in the attach command.

Once reattached, you should see the commands in your script progressing along (or stopped on some sort of error, or, if you're *really* lucky, done processing). To detach again, simply use the same key combination as above.

There is a [good tmux cheatsheet here](https://gist.github.com/henrik/1967800).

### Some general notes, whether you run things in a screen or not

Before you disconnect from your remote/walk away, you will be asked for input at one interactive prompt:
```
Do you want me to try and retrieve the latest mothur-compatible Silva reference database for you? [Y/n] 
```
Based on your response, 03_16S_process.sh will either use the reference database and taxonomy files you've uploaded yourself (paths specified for `supplied_v4ref`, `supplied_DB_ref`, and `supplied_DB_tax`) **or** the helper script [get_mothurSilvafile.sh](scripts/get_mothurSilvafile.sh) will attempt to download the latest mothur-compatible Silva reference database automatically from the [mothur wiki site](https://www.mothur.org/wiki/Silva_reference_files) and then perform some necessary extractions and conversions.

### What the script actually does, and some important notes

As the script runs, it will perform a variety of tasks using shell functions, the mothur package, and Python. As different mothur functions are called, a series of data objects will be created in the top-level directory (i.e., your `file_dir`). In addition, mothur will create and write to the same directory a series of log files for each function call.

***Important note:** The function calls in [03_16S_process.sh](scripts/03_16S_process.sh) use files created in specific previous step(s) as input, assuming all the steps were performed in a certain order. A combination of filename pattern matching and the file modification time are used to determine which files will be used for which function calls. Because of this, it's important you don't modify or remove any of the files created by mothur until the script has finished running; otherwise, the script might use the wrong file(s) as input, producing incorrect or unexpected results.*

*With this in mind: It's worth remembering that, during a given session, mothur **will** automatically remember the most recent .fasta and .groups files it worked on, and will then attempt to feed these directly into the next function call if no specific file paths are given. (Check out the function `get.current()`.) So, it's theoretically possible to call each function without specifying the .fasta or .groups files to be used, so long as you remain within the same mothur session. However, the function calls in [03_16S_process.sh](scripts/03_16S_process.sh) are written with file search patterns unique enough that the user can easily end a session and "pick up" where here or she left off the next time.*
