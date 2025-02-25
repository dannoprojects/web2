---
title: "Barcode Canvas App"
date: 2022-01-08T06:49:22-08:00
draft: false
theme: Toha
menu:
    sidebar:
        name: PowerApps Barcode Reader
        identifier: powerplatform-barcode
        parent: powerplatform
        weight: 40
hero: images/site/custom-hero.jpg
---


#### Problem
Barcodes are everywhere, and I needed a barcode scanner.  So I made one.

#### Solution
This app started out as a single screen app where I could scan and email  myself a barcode. It worked for the couple of odd times I needed a barcode off a piece of hardware.  
After getting a pile of equipment, scanning each item and sending an email approach wasn’t cutting it. I added a screen to my app for collecting many barcodes and emailing the result in an html table.

I’ll illustrate how I handled multiple items.  


#### PowerApps Configuration
##### Components
- Office 365 Outlook Connector
- Office 365 Users Connector
- Collections
- Barcode media component

**Home Screen**

![HomeScreen](/posts/powerplatform/Barcode/Barcode_Home.jpeg)

**Single Barcode Screen**

![SingleItem](/posts/powerplatform/Barcode/Barcode_Single.jpeg)

##### Scanning multiple items
My screen contains 
- Note/asset input
- Label displaying barcode
- Scanner Control
- Gallery with delete item
- Reset Collection
- Send to Self

I enter the note field and tap Scan to read the barcode.  After the scanner control reads the barcode, the note field and barcode are added to a collection called ScannedItems.  The note/asset field can be cleared between barcode scans.  

I decided to not automatically clear it as I had a pile of the same model assets and I didn’t want to keep typing the same thing. 

As I scan items, the items are added to the collection.  One annoyance of scanning barcodes from manufacturer packages is that several barcodes can be clustered together. It’s easy to scan the wrong bar code, so I added a delete feature for individual items in my collection.

After collecting all the UPCs, I send them to myself in an email with the body as an HTML table. 

**Multipe Barcode Screen**

![MultipleItems](/posts/powerplatform/Barcode/Barcode_Multiple.PNG)

The Scan button has an OnSelect that adds items to a collection called ScannedItems.

The collection has two properties:  Asset and Barcode.  I assign the value from the note field and the input from the scanner. Each time I scan, a new item is added to the collection. 

{{< gist dannoprojects 540c7ef0d3dd1359fbbb9b759c572826 "Barcode_collection" >}}

The Send to email button has a little more going on.  I'm using the Office 365 Users Connector to look up my email for the Outlook Connector. 

Concat is used to summarize ScannedItems and build my html table.  
{{< gist dannoprojects 540c7ef0d3dd1359fbbb9b759c572826 "Barcode_SendEmail" >}}

**Email HTML table**

![EmailExample](/posts/powerplatform/Barcode/barcodescanneremail.jpg)

##### References
- [Concat](https://docs.microsoft.com/en-us/powerapps/maker/canvas-apps/functions/function-concatenate)
