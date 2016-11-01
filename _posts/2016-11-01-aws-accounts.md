---
title: "AWS Account structure - An Opinionated Post"
tags: 
     - aws
     - accounts
     - environments
---

I tend to work on a lot greenfield projects where we create AWS stuff from scratch. When I roll down somewhere the very first thing I need to think about is account structure. There are pros and cons to various account structures. There's no 'right' way to do this but I'm going to cover why I generally prefer multiple accounts.

  - **API limits:** AWS accounts have API limits this can be spread across multiple accounts such that too many dev api requests shouldn't interfere with production. It also makes finding the source of too many requests slightly easiar.
  - **Shared resource isolation by environment:** For example IAM roles/policies/users. We don't want to accidentally modify an IAM role policy and mess everything up in production. Of course there are other ways to solve this problem but I prefer this isolation.
  - **Consolidated visibly of billing per environment level:** How much are dev quality machines costing you? How about production? Again there are other ways to solve this problem like remembering to tag machines a certain way and using something like [janitor monkey](https://github.com/Netflix/SimianArmy/wiki/Janitor-Home). However, seperate accounts enforce the billing visibility. Also some resources cannot be tagged.
  - **Enforced resource limits per environment:** - You can limit the number of development instances that can be created and maybe have a something slightly higher in production. Of course I'm not advocating environment inconsistency - so it should be done within reason - but if you're running 3000 instances in development and production is 100 instances some questions probably need to be asked!
 
However, as with every technical decision, it's not perfect and there are trade offs:

- **Complexity**.
    -    You now need to think about assuming roles in other accounts if for example your CI machine wants to spin up stuff in production.
    -    Potentially you may need to peer VPCs. 
    -    Unless people are happy to keep logging out and logging back in over and over again (I can tell you I wouldn't be!) you'll need to peer accounts. 
- **Duplication of stuff** - The shared resources we talked about need to be duplicated in accounts. A lot of this problem can be solved through automation.


## Pitfalls

If going with multiple accounts I have a couple of reccommendations to make things a little smoother and have some things to avoid:

**Don't create one account per application evironment** 

Very often in places where testing has typically been hard you notice that there can sometimes be many different application environments. E.g DEV1, SIT7, UAT1, QA3 etc.. Creating an account per one of these is a really bad idea. It's going to become complicated and expensive to manage. Instead think of environment accounts as different classes of infrastructure. I.e. You're development area is where you put things that may occasionally break. Staging might just be there because we want something that is an exact clean replica of production where we can debug production issues with impacting live users and avoid getting swamped by any API limts in development.

**What about hybrid things?**

We may also want an account for core services which are common. For example, is your CI server development or production? You might think, *if it goes down no live users of my application are impacted so it's development I guess*. However, often CI servers are the only way something can get into production, so if it's broken you have no way of deploying to prod. What about monitoring? If it's down the users don't care. However, if something breaks in the middle of the night you have no way of knowing. There may be a need for a tooling classification of infrastructure which we should treat like production but doesn't necessarily impact users. Another reason for doing this is that putting this stuff in the development or production account means that environments could become inconsistent. For example put CI in the prod account and you may not need any assume role stuff in production, but it may be required in development. Environment inconsistencies are evil and have often been the source of much drama throughout my career. 

**Peer accounts**

Self explanatory, unless you like having to sign in on different browsers with some in incognito mode etc..

**Treat all your accounts like production**

Yes, I know this sounds contradictory but your accounts are just a way of diving up APIs. People who want to run bitcoining mining on your accounts don't care what name you give it. You should have MFA enabled for all your human user accounts not just production. Just because it's development it doesn't make it any less desirable to someone who wants to spin up 3000 EC2 instances and charge you for it. If you're hitting API limts on development you are wasting a lot of peoples time with people waiting to run things. All your accounts are important!

