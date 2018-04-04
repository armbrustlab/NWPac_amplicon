# NWPac_amplicon
Fully reproducible, cloud- or cluster-ready pipeline for workup of 16S/18S amplicon sequence data. Currently configured to process data from three cruises in the NW Pacific Ocean.

## First step: Machine prep and provisioning
First: Initialize, start up and provision your cloud computing instance. These scripts and directions assume you are beginning with a blank machine image -- i.e., with nothing but the operating system and the standard preinstalled packages. Depending on your platform, you may already have some or all of the necessary software installed. If so, go ahead and skip right to the one of the processing scripts.

### Option 1: Use an AWS machine image

1. [Log into your AWS console](https://console.aws.amazon.com/console/home), then your [EC2 Management Console](https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2). (The second link will only work for you if you use US West (Oregon) like I do -- otherwise, just use the EC2 link on your [console homepage](https://console.aws.amazon.com/console/home).) Once at EC2, launch a Ubuntu Server 16.04 machine image and configure it as desired. Launch the image, making sure you create an SSH key pair if you haven't already done so. (This is how you'll access your machine image once its running. Amazon has some [basic directions here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AccessingInstancesLinux.html) to connect to its machine images via SSH. An even better guide to creating and protecting ssh keys using **ssh-keygen** [can be found here](http://people.seas.harvard.edu/~nater/ec2-keyauth/).) As a general best practice, you should make sure your private key file *isn't* publicly accessible and *is* password protected; these can be accomplished using the **chmod** and **ssh-keygen -p -f** commands; see [this page](http://people.seas.harvard.edu/~nater/ec2-keyauth/) for directions.)

2. Wait for your AMI to get up and running (you can monitor its status via your EC2 console; wait until Instance State indicates "running," with a green dot). Once running, connect to the image via SSH. Assuming again that you launched a Ubuntu machine image, open a new shell (this is the "Terminal" on a Macintosh) and connect to your AMI via SSH by typing:
```
ssh -i /path/my-key-pair.pem ubuntu@ec2-198-51-100-1.compute-1.amazonaws.com
```
where `/path/my-key-pair.pem` is the path (on *your* computer) to your private key file. The private key file is (suprise!) the private half of the key pair you specified or created when you launched the machine image. The next bit (`ubuntu@ec2-198-51-100-1.compute-1.amazonaws.com` in this example) is the username and server address. On a Mac, your ssh keys should be in the .ssh folder in your user directory (`~/.ssh`). You can get get the server address from the information provided for the image in your EC2 console. (Copy the address listed in the column called "Public DNS.") Answer "yes" when SSH asks you if you want to continue connecting; you should then receive a response telling you the AMI has been added to your list of known hosts. Note that you use the username `ubuntu` when connecting to a Ubuntu instance; you would replace the `ubuntu` bit with `ec2-user` if connecting to an Amazon Linux or Red Hat EC2 instance. (A good rundown of these idiosyncracies [can be found here](https://99robots.com/how-to-ssh-to-ec2-instance-on-aws/).)

3. Once you are securely connected to your machine image, it's time to provision it. We'll do a couple of things:
  * Unordered sub-list. 
