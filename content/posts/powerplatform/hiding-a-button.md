---
title: "Hiding a Button"
date: 2022-02-01T18:59:41-08:00
draft: false
theme: Toha
menu:
    sidebar:
        name: Button Permissions
        identifier: powerplatform-Hiding-button
        parent: powerplatform
        weight: 45
hero: images/site/custom-hero.jpg
---

#### Problem
You only want certain people to use a button on an app.  The button can be for navigation, or an action.  It doesn't matter.

#### Solution
Use an Azure Active Directory group to control who can use see the button.  This makes managing permissions for the button very easy. You don't need to change the app, change the group membership.

##### Components
- Azure AD Group with members
- Azure AD Group Object ID
- Some onStart code
- A button you only want certain people to see
- Office 365 Groups Connector
- Office 365 Users Connector

###### Azure AD
- Create an Azure AD Group
- Add members
- Make a note of the ObjectID

**Sample Group**

![AzureADGroup](/posts/powerplatform/HidingButtons/Powerapppermissions.jpg)

###### OnStart Code
I'm doing a few things in my onstart.

1. I create a collection of the Azure AD group and set it to ITProjectOwners.
2. I set the current user's UPN to CurrentUserUPN.  I also use this at another point in my app that isn't related to the button.  
3. I set a variable IsProjectOwner to either true or false by doing a lookup against ITProjectOwners using the current user's UPN. If the UPN is in the collection, the variable is true. If the current user is not in the collection, the variable is set to false.

When I want to hide a button, I set the Visable property to IsProjectOwner. This makes the button visable based on the value of IsProjectOwner.


{{< gist dannoprojects 6d5e3a98fa97ecdfc4fcabd958ebbe79 "ButtonPermissions" >}}
