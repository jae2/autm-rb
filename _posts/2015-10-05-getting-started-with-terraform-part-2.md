---
title: "Provisioning with Terraform Part 2"
description: "part two of getting started with terraform."
tags: 
     - terraform
     - provisioning
     - aws
     - hashicorp
     - devops
---

In my last [post](https://www.jaetech.org/getting-started-with-terraform/) I covered the basics of provisioning a single EC2 instance with terraform. This time we're going to go further and explore the provisioners and some other features. I'm doing some pretty funky things just to show the power of terraform. As you'll see later there are other (better) ways.

## From base image to something useful

So last time we provisioned an AWS box with a ubuntu base image. This is not really very useful on it's own. I'm going to assume you'd like to at least install some applications on there. Of course we could hop onto the box and run some commands, but one of the main points of terraform is reproducibility and by manually setting up the box we end up with a box that becomes like a 'snowflake'. Snowflakes are not always beautiful, they fall apart when you touch them which is what the box would become without configuration management. 
So now we introduce the concept of provisioners.

## Provisioners

Provisioners are a pretty common concept in most hashicorp products. As we saw in the last example a builder built an AWS instance, but now it's time for the provisioner to install all the required software on our box. A provisioner is basically something that runs something to build the box. This could be anything from a couple of shell commands to running something like puppet. In contrast to other hashicorp applications terraform only includes a fairly small set of provisioners. [Packer](https://www.packer.io/) and [Vagrant](https://www.vagrantup.com/) contain rather a lot. For the time being terraform is limited to:

- chef - self explanatory - runs Chef on the instance.
- connection - 
- file - Copies a file over the the machine
- local-exec - Runs commands locally on the machine you are executing terraform *from*.
- remote-exec - Runs commands remotely on the machine you are executing terraform *on*.

## Provisioning

So we we take our original terraform file:


{%highlight shell-session %}

provider "aws" {
    access_key = "mykey"
    secret_key = "imobviouslynotgoingtoputmyrealkeyhere:)"
    region = "us-east-1"
}

resource "aws_instance" "example" {
    ami = "ami-408c7f28"
    instance_type = "t1.micro"
    key_name      = "mykey"
}

{% endhighlight %}

We'll add some steps, lets copy a shell script to the box, run the shell script and then provision via ansible-pull. Normally ansible runs in push mode i.e. changes are pushed out to a set of boxes. So we could add the following shell script assuming we had some things in a github repo:


{%highlight bash %}
 
sudo apt-get -yy update
sudo apt-get -yy install ansible git

cd /tmp

# Assuming here we don't rely on any ssh keys
git clone https://github.com/someone/somerepo.git

cd somerepo

sudo ansible-pull -U /tmp/somerepo -i hosts

{% endhighlight %}

Then we could have a simple playbook like this:

{%highlight yaml %}

- hosts: 127.0.0.1
  connection: local
  tasks:
  - apt: name=python-httplib2 update_cache=yes
  - name: Add core users.
    user: name={{ item }} shell=/bin/bash groups=admin state=present
    with_items:
      - bob

{% endhighlight %}


So this is the basis of some really simple automation


Then we just plugin in the provisioners so our complete file now looks like this:


{%highlight shell-session %}

provider "aws" {
    access_key = "myaccesskey"
    secret_key = "notgivingmyrealkeyaway:)"
    region = "us-east-1"
}

resource "aws_instance" "example" {
    ami = "ami-408c7f28"
    instance_type = "t1.micro"
    key_name      = "mykey"

    provisioner "file" {
        connection {
          user = "ubuntu"
          host = "${aws_instance.example.public_ip}"
          timeout = "1m"
          key_file = "/path/to/ssh_key"
        }
        source = "go.sh"
        destination = "/home/ubuntu/go.sh"
    }

    provisioner "remote-exec" {
        connection {
          user = "ubuntu"
          host = "${aws_instance.example.public_ip}"
          timeout = "1m"
          key_file = "/path/to/ssh_key"
        }
        script = "go.sh"
    }
}

{% endhighlight %}


So there's some really cheap dirty automation.


## In reality..

With anything beyond a basic single machine I wouldn't use terraform provisoners to do the actual machine build as illustrated here. A much nicer way would be to build an AMI with [packer](https://www.packer.io/) giving us the following work flow:

1. Create AMI's with packer and provision it with ansible/puppet/chef.
2. Create a terraform file with all of the things! I.e. VPC's, route tables, subnets, ELBs, autoscaling groups, iam roles etc..
3. Once the AMI is built the terraform.tf file is updated with the correct ami names (probably best to have a seperate file for variables). They will still get spun up int he correct subnet
4. perform a dry run with ``` terraform plan ```
5. Apply the terraform file.
6. When terraform spins up the boxes from your pre-baked AMIs there will almost certainly be some things left over from the box packer used to provision with. This is where I think the correct terraform provisioner use case comes in. For example lets say our machine is referencing the provisioner box's IP address in several places. The terraform provisioner can take the appropiate action (e.g. delete some files or re-run puppet/ansible/chef etc..).


## Likes/Dislikes

Terraform seems good for:

- Building all the things! - Lets say you want to create a vpc, then some subnets inside it, then some machines on that subnet with some route tables. With terraform you don't necessarily need to store VPC IDs or subnets anywhere you can just pass variables that will eventually represent these things between resources.
- Mixing up your cloud providers.
- Cleaning up the mess packer has left behind.
- Dry-running your provision/update to ensure you don't do something you regret.

But there are still some issues:

- Terraform's state management is a bit off. There's a single tfstate text file which determines the current state of your world. If you have multiple developers trying to work on this you are probably going to hit some chaos unless you have a process which works around this!
- Early days and still quite buggy. For some evidence of this check the number of issues in their [github repo](https://github.com/hashicorp/terraform/issues] 

Many people like to completely trash their servers with every deployment (phoenix server pattern). It seems like doing this in a [blue/green deployment](https://www.thoughtworks.com/insights/blog/implementing-blue-green-deployments-aws) way could be fiddily with terraform. This is something I'd like to investigate further


