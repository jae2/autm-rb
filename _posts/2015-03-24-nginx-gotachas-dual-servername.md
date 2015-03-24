---
title: "Nginx Gotchas - wildcard server names"
tags: 
     - nginx
     - webserver
     - http
---

This is a short post about a nginx gotcha that stumped me for a few minutes. tl;dr nginx servernames using wildcards can only occur if they are preceding a dot. 

Lets suppose we have an nginx vhost like this:

{% highlight nginx %}

upstream mydomain_upstream {
  server localhost:8080;
}

server {
  listen 0.0.0.0:80;
  server_name *.apps.my.domain.com;
  proxy_redirect http:// $scheme://;
  proxy_set_header Host $host;

  location / {
    proxy_pass mydomain_upstream;
  }

}
{% endhighlight %}


This proxies to localhost:8080, which could for instance be something like tomcat or jetty. Let's suppose we want our vhost to also proxy for requests coming in at *-apps.my.domain.com. You might try something like this:




{% highlight nginx %}
server {
  listen 0.0.0.0:80;
  server_name *.apps.my.domain.com *-apps.my.domain.com;
}

{% endhighlight %}


However, this will not work, to quote the [nginx docs:](http://nginx.org/en/docs/http/server_names.html)

*A wildcard name may contain an asterisk only on the name’s start or end, and only on a dot border. The names “www.\*.example.org” and “w\*.example.org” are invalid.*

Therefore, we need to use a regex instead, so in our example we can instead use:

{% highlight nginx %}
server {
  listen 0.0.0.0:80;
  server_name *.apps.my.domain.com ~.*-apps[.]my[.]domain[.]com;
}

{% endhighlight %}


Note that now we've converted the server_name to use a regex we need to escape the dots so they don't revert to match any character.





