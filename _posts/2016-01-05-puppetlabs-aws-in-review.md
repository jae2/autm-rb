---
title: "Get up and running with Puppetlabs AWS"
tags: 
     - puppet
     - aws
     - puppetlabs
     - puppetlabs-aws
---

There's an increasing number of ways to provision AWS infrastructure. I've already mentioned [terraform]({{ "/getting-started-with-terraform" | prepend:site.baseurl }}) which is my current frontrunner. There's also also a couple of other options like the [ansible cloud modules](http://docs.ansible.com/ansible/list_of_cloud_modules.html), [Cloud Formation](https://aws.amazon.com/cloudformation/aws-cloudformation-templates/) (ewwwww!) or writing your own custom stuff with an AWS sdk (also, ewwww!). In this post I'll be looking at something I came across fairly recently: [Puppetlabs-aws](https://github.com/puppetlabs/puppetlabs-aws).

## Getting started


So, firstly I'm going to assume that you have some basic understanding of [Puppet](https://puppetlabs.com). 

Creating AWS infrastructure with puppet isn't really different from using manifests to manage the resources of a Linux box.

If you're using puppet-librarian (if not why not!?) you'll want to add puppetlabs-aws to the Puppetfile:

{% highlight ruby %}
mod 'puppetlabs/puppetlabs-aws'
{% endhighlight %}

You'll also need a Gemfile with the aws-sdk included plus some other modules: 

{% highlight ruby %}

gem 'aws-sdk-core'
gem 'retries'
gem 'puppet', '3.8.1'
gem 'librarian-puppet'

{% endhighlight %}


Obviously, you're also going to need your AWS access keys. I'll leave it up to you to decide how you want to manage them, I prefer to use the``AWS_PROFILE``environment variable.

The quick and hacky solution is to export the following:

{% highlight bash %}

export AWS_ACCESS_KEY_ID=your_access_key_id
export AWS_SECRET_ACCESS_KEY=your_secret_access_key

{% endhighlight %}


You should then be able to run:

{% highlight bash %}

bundle install
bundle exec puppet resource ec2_instance --modulepath=modules

{% endhighlight %}

If you already have an EC2 instance running in your account you should see it's configuration is displayed to you. If not, the command shouldn't return anything.

**From here on the steps will cost you money**

Then you can create an EC2 instance like so in a manifest file:


{% highlight puppet %}

ec2_instance { 'test':
  ensure        => present,
  region        => 'us-west-2',
  image_id      => 'ami-f0091d91',
  instance_type => 't2.small',
}

{% endhighlight %}


One nice feature of puppetlabs-aws that is tragically missing from Cloud Formation is that you can do a dry run:

{% highlight bash %}

bundle exec puppet resource ec2_instance --modulepath modules --noop

{% endhighlight %}

You should see an output/diff of the expected outcome in AWS. In my opinion this is a lot better than the Cloud Formation model of "cross your fingers and apply the changes straight away". 

This is the basics of creating an EC2 instance. There are many more other attributes you can use in an EC2 instance such as a user data erb template file. Like other puppet resources you can destroy the ec2 instance as follows:

{% highlight puppet %}
ec2_instance { 'test':
  ensure            => absent,
  region            => 'us-west-2',
}
{% endhighlight %}

Then there's a [load of other resources](https://github.com/puppetlabs/puppetlabs-aws#reference) you can use. Another example could be creating an SQS queue:

{% highlight puppet %}

sqs_queue { 'my_queue':
  ensure => present,
  region => 'us-west-1',
  delay_seconds => 60,
  message_retention_period => 180,
  maximum_message_size => 2048,
}

{% endhighlight %}

Some other power comes from [creating your own defined types](https://github.com/puppetlabs/puppetlabs-aws/tree/master/examples/create-your-own-abstractions) which is also pretty neat.


## What's good about puppetlabs-aws?

**Dry-run** - You can see what will change before you apply a resource. This is a pretty basic idea but not all tools have this.

**Create your own abstractions** - As mentioned above, you can simply create an application type which consists of many AWS resources which should hopefully simplify environment creation.

**Hooks into hiera** - You can potentially manage your box configuration and box provisioning in one place. I've often seen cases where variables end up getting stored in more than one place. For example, An SQS queue might need to be created with the AWS provisioning tool and also may be called internally by a couple of machines. There could potentially be a single source of truth for this.

**Unit-testing**  - Using puppet gives you beaker and puppet-rspec so you can test all the things!

**Some Idempotency** - You can discover resources and pull them into your codebase and force aws resources to be in a certain state. Cloudformation and Terraform will ignore things which are created outside of their world  (or error if it finds something which overlaps with it's configuration). 

**No horrible state files** - Terraform uses a state file to determine what is in your infrastructure, this introduces all kinds of problems with developers working on the same codebase.

**Linkage into other puppet features** - e.g. PuppetDB, Puppet Reports..


## What's less good about puppetlabs-aws?

**Very early days** - There isn't much of a community around it yet.

**Small knowledge base** - You have to be prepared to dig into the code to figure out how things work. Needs to be done a lot more than you would with other open source projects.

**Idempotency problems:** - For example, if you create a resource manually in one region give it's name the tag 'a', then create the same resource in the same region give it a name tag of 'a' as well. Then in the manifest ensure the 'a' resource is absent. It's hard/impossible to determine which resource will get deleted. Therefore, the idempotency is not completely fool proof. This is mostly due to the fact most AWS resources don't have a suitable attribute that can become a namevar.

**Phoenix servers** - You may wish to implement the [phoenix server](http://martinfowler.com/bliki/PhoenixServer.html) pattern. One strategy for this involves attaching instances to a temporary load balancer, then moving them to a new load balancer, and destroying all instances with an old AMI in one change. Not sure how this would work in Puppetlabs-aws. If anyone has a good way of doing this with puppetlabs AWS, please let me know - I'd be interested! However, take this with a pinch of salt as I'm not convinced that tools like Terraform and puppetlabs-aws are really the right place to do those things (long story..).

**AWS resources** -  Not all AWS resources are supported yet.

**Various grievences people have with the Puppet DSL** - Although using the future parser can make life a lot easiar!

## Conclusions

You may have some success with Puppetlabs AWS if your infrastructure is already heavily puppet based, automation is a problem and/or you want to get away from Cloud Formation slowly bit by bit. However, it's still early days for the project and I would be a little nervous about building things in production from scratch on a greenfield site. The project still seems quite exciting and I'm be interested to see how it progresses.
