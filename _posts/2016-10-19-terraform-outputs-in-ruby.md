---
title: "Getting Terraform outputs into Ruby Code with ruby-tfoutputs"
tags: 
     - ruby
     - terraform
     - outputs
     - aws
---

This post details a way to get your terraform outputs into your Ruby code. I wrote a little ruby gem to handle it.  Why might you do this? Well good question, sometimes people like to write some scripting that uses things from terraform outputs. Of course you can just make a command line call to ```terraform output``` which is pretty simple. After writing this gem I was wondering whether or not I should have bothered:

![I probably shouldn't have bothered!]({{ site.base.url }}/images/medium/could-vs-should.jpg)


## wtf is this shit..

So basically you've got your terraform outputs. You can grab them with:

{% highlight bash %}
terraform output outputname
{% endhighlight %}

However sometimes people want to do other things with them like generate ERB templates. Instead of wrapping the terraform command line it's possible to use a rubygem I created which should pull everything together for you. Better still, you can use many different terraform states so you might have 3 stored as file and 2 in Amazon s3. You can access them all through one source.

For help setting it up please see the github [repo](https://github.com/jae2/ruby-tfoutputs) README.md

It's still at an early stage so there may still be one or two bugs. If I'm honest it was a bit of a hack job and I'm not very proud of the quality of the code, but it seems to work!

## Backends

Currently there are only two sources where you can retrieve states from: S3 or file.  An example using both of these is below:

{% highlight ruby %}
config = [{:backend => 's3',:options => {:bucket_name => 'my-bucket-name-goes-here',
           :bucket_region => 'eu-west-1', :bucket_key => 'terraform.tfstate' }
         },
          {:backend => 'file', :options => { :file_path => '/path/to/state/file/terraform.tfstate' } }
        ]
state_reader = TfOutputs.configure(config)
puts(state_reader.my_output_name)
{% endhighlight %}


However, it is designed to be extensible in terms of backends. So if it'd be useful to have other things like etcd, consul and others feel free to contribute.

## Is it going to be useful?

I reckon most people will just wrap the terraform commandline, but if you don't want to or doing so becomes to big this might help you.

