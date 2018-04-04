# NWPac_amplicon
Fully reproducible, cloud- or cluster-ready pipeline for workup of 16S/18S amplicon sequence data. Currently configured to process data from three cruises in the NW Pacific Ocean.

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
ssh -i /path/my-key-pair.pem ubuntu@ec2-198-51-100-1.compute-1.amazonaws.com
```
where `/path/my-key-pair.pem` is the path (on *your* computer) to your private key file. The private key file is (suprise!) the private half of the key pair you specified or created when you launched the machine image. The next bit (`ubuntu@ec2-198-51-100-1.compute-1.amazonaws.com` in this example) is the username and server address. On a Mac, your ssh keys should be in the .ssh folder in your user directory (`~/.ssh`). You can get get the server address from the information provided for the image in your EC2 console. (Copy the address listed in the column called "Public DNS.") Answer "yes" when SSH asks you if you want to continue connecting; you should then receive a response telling you the AMI has been added to your list of known hosts. Note that you use the username `ubuntu` when connecting to a Ubuntu instance; you would replace the `ubuntu` bit with `ec2-user` if connecting to an Amazon Linux or Red Hat EC2 instance. (A good rundown of these idiosyncracies [can be found here](https://99robots.com/how-to-ssh-to-ec2-instance-on-aws/).)

3. Once you are securely connected to your machine image, it's time to provision it. (Once you are connected to the remote client via SSH, your shell prompt should change from what you're used to seeing to something like `ubuntu@ip-172-31-23-22:~$`) 

First, let's make sure git is installed, since we'll be cloning the scripts in this repository directly to a new repository on the machine image.
```
sudo apt install git
```
You should receive a message indicating git is already installed; if so, that's great -- but it's worth double-checking.

Next, let's clone a copy of this repository to the machine image. Ths is an easier way of obtaining all the scripts than using secure copy (scp) -- and using git ensures you'll be downloading and using the very latest versions of the scripts maintained here on GitHub. We'll clone the repository into a new local repo of the same name. 
```
git clone https://github.com/jamesrco/NWPac_amplicon NWPac_amplicon
```

Now, we can change directories to the newly cloned repository and run the provisioning scripts.

The [first script](scripts/01_vagrant_provision_ubuntu.sh) will install unzip and rclone. rclone will be useful if we want to access our .fastq files from a Dropbox or Google Drive location. 
```
cd NWPac_amplicon/scripts
source ./01_vagrant_provision_ubuntu.sh
```

### Option 2: Configure a Vagrant box

Directions to come. Doing all of this in a Vagrant box on your own computer is useful for testing new features, etc., without having to set up (and pay for) a cloud computing instance. You'll likely never need these directions unless you're developing and testing new shell scripts.

## Next step: Copy files to the remote client, or allow the remote to access them

## Process some data
