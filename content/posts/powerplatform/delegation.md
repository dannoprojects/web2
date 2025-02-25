---
title: "Delegation"
date: 2022-03-13T18:59:41-08:00
draft: false
theme: Toha
menu:
    sidebar:
        name: Delegation
        identifier: powerplatform-delegation
        parent: powerplatform
        weight: 50
hero: images/site/custom-hero.jpg
---
I’ve been working on a canvas app to track and manage major IT projects. The app uses a SharePoint list as a datasource.  Our executives also use the app and the PowerBI dashboard to review projects that require executive approval in the form of what we call our Change Advisory Board (CAB).

I recieved feedback from a member of our CAB.  “It would be nice to separate out the completed projects from all the other projects.” 
 
I thought it would be easy to change my filter syntax to include  project status of “not completed”.  Wrong.  You cannot delegate “not” when using a SharePoint list.  

#### Problem
Using ‘Not’ in a gallery filter results in a delegation warning with a SharePoint List.

**The dreaded delegation warning**

![Delegation Warning](/posts/powerplatform/Delegation/delegationimage.jpg)


#### Solution
In this use case, I resolved my delegation and filter dilemma with a new choice column in my datasource named “Archived” with the values of ‘true’ or ‘false’.  Since equals to can be delegated, I make an equals to comparison to 'false' to show all active projects.

Now I have a filter expression that uses my various project filters and meets my user request. 

I decided to use a PowerAutomate flow to set my archive flag.  I have other helper flows for the solution, so I chose to to continue down the flow route to keep my patch functions simple. 


##### Components
- SharePoint List as a datasource
- Choice column named "ArchiveStatus" with values of 'true' and 'false' 
- PowerAutomate Flow that sets the archive flag when a project status is set to completed.

##### Code Snippet

{{< gist dannoprojects 736427de09e1fc1386b0d3a3a96919a0 "FilterDelegation" >}}
