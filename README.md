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

1. [Log into your AWS console](https://console.aws.amazon.com/console/home), then your [EC2 Management Console](https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2). (The second link will only work for you if you use US West (Oregon) like I do -- otherwise, just use the EC2 link on your [console homepage](https://console.aws.amazon.com/console/home).) Once at EC2, launch a Ubuntu Server 16.04 machine image and configure it as desired. Launch the image, making sure you create an SSH key pair if you haven't already done so. (This is how you'll access your machine image once its running. Amazon has some [basic directions here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AccessingInstancesLinux.html) to connect to its machine images via SSH. An even better guide to creating and protecting ssh keys using **ssh-keygen** [can be found here](http://people.seas.harvard.edu/~nater/ec2-keyauth/).) As a general best practice, you should make sure your private key file *isn't* publicly accessible and *is* password protected; these can be accomplished using the **chmod** and **ssh-keygen -p -f** commands; see [this page](http://people.seas.harvard.edu/~nater/ec2-keyauth/) for directions.)

2. Wait for your AMI to get up and running (you can monitor its status via your EC2 console; wait until Instance State indicates "running," with a green dot). Once running, connect to the image via SSH. Assuming again that you launched a Ubuntu machine image, open a new shell (this is the "Terminal" on a Macintosh) and connect to your AMI via SSH by typing:
```
ssh -i /path/to/my-key-pair.pem ubuntu@ec2-198-51-100-1.compute-1.amazonaws.com
```
where `/path/to/my-key-pair.pem` is the path (on *your* computer) to your private key file. The private key file is (suprise!) the private half of the key pair you specified or created when you launched the machine image. The next bit (`ubuntu@ec2-198-51-100-1.compute-1.amazonaws.com` in this example) is the username and server address. On a Mac, your ssh keys should be in the .ssh folder in your user directory (`~/.ssh`). You can get get the server address from the information provided for the image in your EC2 console. (Copy the address listed in the column called "Public DNS.") Answer "yes" when SSH asks you if you want to continue connecting; you should then receive a response telling you the AMI has been added to your list of known hosts. Note that you use the username `ubuntu` when connecting to a Ubuntu instance; you would replace the `ubuntu` bit with `ec2-user` if connecting to an Amazon Linux or Red Hat EC2 instance. (A good rundown of these idiosyncracies [can be found here](https://99robots.com/how-to-ssh-to-ec2-instance-on-aws/).)

3. Once you are securely connected to your machine image, it's time to provision it. (Once you are connected to the remote client via SSH, your shell prompt should change from what you're used to seeing to something like `ubuntu@ip-172-31-23-22:~$`) 

First, let's make sure git is installed, since we'll be cloning the scripts and other files in this repository directly to a new repository on the machine image.
```
sudo apt install git
```
You should receive a message indicating git is already installed; if so, that's great -- but it's worth double-checking.

Next, let's clone a copy of this repository to the machine image. This is an easier way of obtaining all the necessary scripts and files than using secure copy (scp) -- and using git ensures you'll be downloading and using the very latest versions of the scripts/files maintained here on GitHub. We'll clone the repository into a new local repo of the same name. 
```
git clone https://github.com/jamesrco/NWPac_amplicon NWPac_amplicon
```

Now, we can change directories to the newly cloned repository and run the provisioning scripts.

The [first script](scripts/01_provision_ubuntu.sh) will install unzip and rclone. rclone will be useful if we want to access our .fastq files from a Dropbox or Google Drive location. 
```
cd NWPac_amplicon/scripts
source ./01_provision_ubuntu.sh
```

The [second script](scripts/02_metagenomics_amplicon_provision.sh) will install Python 2.7 and the necessary bioinformatics tools, including the Biopython package and mothur.
```
source ./02_metagenomics_amplicon_provision.sh
```
Answer yes ("Y") to any prompts.

### Option 2: Configure a Vagrant box

Doing all of this in a Vagrant box on your own computer is useful for testing new features, etc., without having to set up (and pay for) a cloud computing instance. You'll likely never need these directions unless you're developing and testing new shell scripts.

If on a Mac: Install and configure [Vagrant](https://www.vagrantup.com/) using these great directions here: http://sourabhbajaj.com/mac-setup/Vagrant/README.html 

Once Vagrant is installed, create a new directory to store your Vagrant "boxes" (essentially machine images). In this directory, get whatever box(es) you want. (The full listing of available boxes is [here](https://app.vagrantup.com/boxes/search).) For Ubuntu 16.04:
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

## Next step: Copying files to the remote client, or allowing the remote to access them

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
With Vagrant, scp would not work unless I specified the path to the default Vagrant private key. It should be in the directory `.vagrant`, subordinate to the directory in which you added and initialized your Vagrant box. (Apparently, you can also specify a custom key pair by messing with some Vagrant box settings; I didn't waste my time with this step.)  If you're doing a lot of testing with Vagrant, you might find the instructions (here)[https://superuser.com/questions/317036/ignore-known-hosts-security-in-ssh-for-some-addresses] and (here)[http://www.kevssite.com/how-to-stop-ssh-from-adding-a-server-to-known_hosts-file/] useful to prevent ssh from adding every new Vagrant box to your known hosts lists. I would *not* disable any security features for ssh connections to AWS instances.

### Option 2: Use rclone to access files directly from the remote client

Another (perhaps easier) option is to use rclone to grab all the .fastq files you will want directly from a Dropbox or Google Drive location. This frees you from having to download all the files onto your computer, zip them into archives, and then manually copy them to the remote, as above.

The [first provisioning script](scripts/01_provision_ubuntu.sh) downloads and installs rclone, so you're already halfway there. Once installed, you'll need to configure things. If you've already configured rclone on your own computer and you will be grabbing .fastq files from one of the locations in your existing rclone configuration, you can simply copy the config file `.rclone.conf` right on over to your remote using **scp**:
```
scp -i /path/to/my-key-pair.pem ~/.rclone.conf ubuntu@c2-198-51-100-1.compute-1.amazonaws.com:.
```
or, for a Vagrant box, assuming you installed rclone right into your home directory:
```
scp -i /path/to/Vagrant/.vagrant/machines/default/virtualbox/private_key -P 2222 ~/.rclone.conf vagrant@127.0.0.1:.
```

## Process some data
