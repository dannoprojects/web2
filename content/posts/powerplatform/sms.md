---
title: "SMS Notification PowerApp with Twilio Integration"
date: 2020-06-01T06:49:22-08:00
draft: false
theme: Toha
menu:
    sidebar:
        name: SMS Notification 
        identifier: powerplatform-sms
        parent: powerplatform
        weight: 25
hero: images/site/custom-hero.jpg
---

### SMS Notification PowerApp with Twilio Integration
#### Problem
Obayashi has a subscription to an SMS Emergency Notification platform. Access to the platform costs Obyashi approximately $5000 per year even if no messages are ever sent.  That's five thousand to reserve the right to use the platform. 

I was asked to take a look at different platforms to reduce cost. 
#### Solution

I built a PowerApp that uses a Twilio connector.  We pay for the messages that we use at a rate of 0.0075 per message and $1.00 per month to reserve a local number.  This solution saved Obayashi about $4990 in cost. 

The PowerApp allows a member of HR or executive to send a SMS message selected groups.

#### App Configuration
##### Components
- Twilio Connector
- SharePoint Connector
- SharePoint Lists containing Emergency Contact Numbers

##### Screens
###### Landing Screen
- Landing Screen to select an SMS Group via a drop down.

![Landing Screen](/posts/powerplatform/smsscreen1.jpg)

###### Message Composing Screen
- Compose a message to send.
- Messages are preceeded with a standard greeting.
- Counter to display the number of recipients of the message.
- Counter to display chararacters remaining in message to ensure message is under character count for single line SMS.

![Composing Screen](/posts/powerplatform/smsscreen2.jpg)

###### Confirmation Screen
- Displays a confirmation of the message.

#### Code Snippets of Interest
Displaying the remaining character count from a text input.  My text input is named SMSMessage.  
```
"Characters remaining:  " & Text(149-Len(SmsMessage.Text))
```
#### Additional Features to Implement
- I had a requirement to get the PowerApp deployed quickly, so leveraged static SharePoint Online lists for mobile numbers. Not all of our employees have corporate issued devices and were not Azure Active Directory. I'd like to query AAD for corporate mobile devices and combine a short list of non published numbers. This would reduce the amount of effort to keep the lists current.
- Record responses from message recipients.  I believe that I'll implement this by giving the option of creating and sending a MS Form in the case of emergency contacts. 
- Record messages sent.  This could be implemented by writing to another SharePoint list as a log.  Additionally, I could display the list as a gallery in another screen.