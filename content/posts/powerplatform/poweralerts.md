---
title: "PowerAutomate with Twilio Integration for Electricity Outages."
date: 2021-11-05T06:49:22-08:00
draft: false
theme: Toha
menu:
    sidebar:
        name: Power Outage Notifications
        identifier: powerplatform-poweroutagenotifications
        parent: powerplatform
        weight: 30
hero: images/site/custom-hero.jpg
---


#### Problem
We have a job site where power outages occur more often than we'd like.  The site engineer and other key staff members need to know when the power fluctuates while they work out a more robust back up power system for their construction requirements. Naturally, we have an APC UPS on site for our network equipment.  Why not use that as a monitoring device and get messages to our enginners. 
 
#### Solution
I used our Twilio connector and a Shared Mailbox trigger to send SMS messages to the site engineers. I could have sent emails, but who's inbox isn't swamped with noise?  Plus, the site is in a remote area, and SMS is more reliable than email.

The Alerts
- Critical alert when the UPS has less than 5 minutes of battery.
- Informational alert when the UPS first goes on battery.  Power sags happen often at this site, so this isn't a true indicator of an outage.
- Informational alert when the UPS goes off battery.  This is an all clear message that the event has ended. 

#### PowerAutomate Configuration
##### Components
- Twilio Connector
- Outlook Connector
- APC configured to send email alerts to a shared mailbox

##### The Flow
![The Flow](/posts/powerplatform/PowerAlerts_FlowOverview.jpg)
It looks complicated but isn't really. 
- Monitor a Shared Mailbox for messages from APC.
- A ContactList array of mobile numbers used later in the Flow. 
    * A note here, double quotes are used for the numbers. 
![Array Example](/posts/powerplatform/PowerAlerts_arraydetail.jpg)
- Conditions that match subject line to the type of alert that will be sent.  
    * My main condition checks for an email message with a subject containing "UPS Low Battery."  This indicates the power has been out for several minutes. 
    * In the If No of the main condition, I check the message for a subject containing "UPS on Battery."  This indicates the UPS just went on battery.
    * In the If No of my "UPS on Battery", I check the message for a subject containing "Power Restored".

- Apply to each to send messages based on the type of alert. I use a time stamp at the beginning of each message to give a better sense of when the alert happened.
![Apply To Each Example](/posts/powerplatform/PowerAlerts_applytoeachdetail.jpg)

##### Code Snippets of Interest
Expression to take current time and convert to Pacific Standard Time. 

{{< gist dannoprojects 4d197babf841e70470e70d17f7afc9bd "Date Conversion" >}}
