---
title: "Provisioning with Terraform Part 1"
tags: [terraform,provisioning,aws,hashicorp,devops]
---
I've heard a lot of talk about [terraform](http://terraform.io/ "terraform")  recently. I decided it was time for me to see what all the fuss was about. After attending a talk about it, I decided it was time to give it a try! So the next few posts are about my experience of provisioning with terraform, along with some of the pitfalls I encountered along the way. 

## What Terraform is

[Terraform](http://terraform.io/ "Terraform") is basically a tool for building and changing your cloud infrastructure. It's a similar product to CloudFormation and Heat, except the cool thing is that it's provider agnostic. That is, you can build and provision infrastructure from different cloud providers all within one project. Lets say you want an AWS Elastic load balancer, some Digital Ocean Droplets and a Heroku app. Terraform can handle that within a single configuration file.

## What Terraform is not

With the word 'devops' being thrown around by the marketing departments of so many organizations there's lots of tools out there. It's important to distinguish what Terraform does and doesn't do.

**Terraform is not a configuration management tool**

It's not an alternative to Puppet, Chef or Ansible. It's purely about building,updating and provisioning infrastructure. If you're including a machine (like an EC2 instance) then it is possible to run a set of commands after it's built which could include running Puppet/Ansible/Chef. I'll be explaining all this in a later post.

**Terraform is not a library for interacting with your cloud provider**

Terraform is a much higher level abstraction. Libraries like fog will call the api functions of your cloud provider. Terraform, simply requires you to define what your infrastructure looks like across multiple cloud providers using a template/configuration file pattern. There is very little logic and flow control involved.

**Terraform is not a means to orchestrate application deployment**

Terraform is only concerned with your infrastructure. If you're looking for a replacement for Beanstalk, Terraform is not going to solve your problems. As far as I'm aware there are no plans to extend Terraform to include application deployment. So use it for what it does best, building, updating and provisioning your infrastructure.


## Getting up and running.

The first step is to get a copy of the [terraform binaries](https://www.terraform.io/downloads.html) . Installing them was a fairly simply process on OSX. Just unzip them somewhere and add them to the path in your .profile. I prefer to go with this convention: 

{% highlight bash %}
TERRAFORM_HOME=/my/path/
PATH=$PATH:$TERRAFORM_HOME
{% endhighlight %}


Just my preference as I can easily override TERRAFORM_HOME on the command line for experimenting with new versions.

Now lets test the path is set of correctly:

{%highlight shell-session %}
myhost:~ user$ terraform --version
Terraform v0.3.5
{% endhighlight %}

Cool, we're ready to go!


##  Creating the first Terraform configuration

Terraform uses a configuration file which can either have the .tf or .tf.json extension.  As the extension names would imply, terraform understands both json and it's own DSL. However, they are both very similar except the .tf extension is more human readable. So far I haven't seen a good reason to use the .json format, so I will be writing the rest of this post only mentioning the .tf format.

**Warning! From here on running terraform commands may incur a cost with AWS. Check your free tier eligibility if you don't want to be charged!**

I'm going to assume here that you access your AWS instances using ssh keys which can be accessed on the machine you're using to run terraform.


Create a file named provision.tf and add the following:

{% highlight console %}

provider "aws" {
    access_key = "Your aws access key"
    secret_key = "your aws secret key"
    region = "us-east-1"
}

resource "aws_instance" "example" {
    ami = "ami-408c7f28"
    instance_type = "t1.micro"
    key_name      = "your-aws-key-name"
}

{% endhighlight %}


Once this is in place we can use one of the coolest features of terraform - plan mode. This is basically a noop feature which shows the final state of your infrastructure after applying your configuration. It prints out a before and after diff:

{% highlight console %}

terraform plan 
+ aws_instance.example
    ami:               "" => "ami-408c7f28"
    availability_zone: "" => "<computed>"
    instance_type:     "" => "t1.micro"
    key_name:          "" => "key-name"
    private_dns:       "" => "<computed>"
    private_ip:        "" => "<computed>"
    public_dns:        "" => "<computed>"
    public_ip:         "" => "<computed>"
    security_groups.#: "" => "<computed>"
    subnet_id:         "" => "<computed>"
    tenancy:           "" => "<computed>"

{% endhighlight %}

There were a lot of things we didn't specify in our configuration like security_groups or private_dns, these can be provided but in our case they will get computed by the AWS backend.

Hold on, how does Terraform know this? 

It won't be there at present but terraform maintains a state file called <config_filename>.tfstate this contains the current state of your infrastructure. As no file is currently present we can assume that we're adding brand new things. This file should only ever come from running terraform commands, so don't try and be smart and edit it yourself - you'll leave yourself in a world of hurt.


The final state looks about right. We're adding a new EC2 instance, so lets provision it! This can be done as follows:

{% highlight console %}

terrform apply

{% endhighlight %}


If you browse to the AWS management console, and click EC2 you should now see that either a new instance has been built or one is being built. You should be able to ssh onto it with the ssh key you referenced with key_name. 

Remember that in ubuntu AWS machines the default username is ubuntu e.g:

{%highlight shell-session %}
ssh -i ~/.ssh/my_aws_key ubuntu@ec2-machine
{% endhighlight %}

As mentioned before there should now be a .tfstate file present. You can take a look at this if you want to have a look at the information terraform knows about your infrastructure.

Once you're done with this instance you can destroy it with:

{%highlight shell-session %}
terraform destroy 
{% endhighlight %}

You should see that the machine gets terminated from the AWS console.


In Part 2 we'll be building the machine and provisioning it with Ansible.



### External Links

[http://terraform.io/ ](http://terraform.io/ "terraform") 
