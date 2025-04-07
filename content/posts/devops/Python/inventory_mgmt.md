---
title: "Replacing Excel with a SharePoint List for Inventory Management"
date: 2025-04-07T00:00:00-08:00
draft: false
theme: default

# This is key for nesting under Python in your sidebar
menu:
  sidebar:
    name: "Replacing Excel with a SharePoint List for Inventory Management"
    identifier: python-sharepoint
    parent: python
    weight: 200

description: "Better than Excel"
tags:
  - SharePoint
  - Inventory
  - Dell API
  - Automation
hero: images/site/custom-hero.jpg
---

## Introduction
Managing a small inventory in Excel can be convenient at first—but as the inventory grows, **Excel** often becomes more of a bottleneck than a solution. I recently decided to shift from an Excel-based approach to a **SharePoint List** for better flexibility, multi-user access, and integration potential with APIs (like Dell’s warranty service).

In this post, I’ll walk you through:
1. **Why I moved from Excel to SharePoint**  
2. **How I set up the SharePoint List**  
3. **Automating warranty checks with the Dell API**  
4. **Lessons learned and future ideas**

---

## 1. Why Move Away from Excel?
Excel is great for quick data entry, but it shows its limitations when:
- Multiple users need to edit data **simultaneously** without version conflicts.  
- You want to leverage **real-time forms** or automated processes.  
- You need robust **searching**, **filtering**, and **indexing** across multiple columns.  

SharePoint Lists solve these problems by providing a **web-based** interface, access control via **Microsoft 365**, and the ability to integrate with tools like **Power Automate** or Python scripts via the **Microsoft Graph API**.  I might build a PowerApp ontop of the list in the future to appify it further.

---

## 2. Setting Up the SharePoint List
I created a list called **“Inventory”** within a SharePoint site dedicated to IT assets. Each item in the list has fields like:
- **Title**: The device name or label  
- **ServiceTagSerial**: The device’s Dell service tag  
- **WarrantyType** and **WarrantyExpiration**: For tracking coverage  
- **Status**: e.g., “Assigned” or “Available”  
- **DeviceType** (Laptop, Desktop, etc.)  
- **Location**, **Notes**, and others…

This structure immediately gave me:
- **Concurrent editing** by multiple team members  
- **Easy filtering** (e.g., all items with “Status == Assigned”)  
- **Built-in version history** and user permissions
- **Easy Filters and View**.  I love views in SPO.

---

## 3. Automating Warranty Checks with the Dell API
The inventory that I inherited was a mess.  I wanted to progrmatically update it. So I wrote a scrpt to check **warranty type and expiration date** using Dell’s API. Here’s the high-level flow:

1. **Script Authenticates to SharePoint**:  
   Using **Azure AD** (or an **OAuth** client) to connect to the list programmatically.  
2. **Query for “Assigned” Items**:  
   Grab items where `Status == 'Assigned'`.  
3. **Dell API Call**:  
   For each item, parse the `ServiceTagSerial` field, make a request to the **Dell Warranty API**, and get the latest coverage info.  
4. **Update SharePoint**:  
   Write back the `WarrantyType` and `WarrantyExpiration` fields using **Python** + **Microsoft Graph** (or the direct SharePoint REST API).

This automation ensures up-to-date warranty data is always visible in the same place where staff track device assignments—no more guesswork or rummaging through spreadsheets.

---

## 4. Lessons Learned & Future Plans
- **Index Key Fields**: Filtering by fields like `Status` or `ServiceTagSerial` is smoother when columns are indexed in SharePoint.  
- **Consider Power Automate**: If you’re not comfortable with custom scripts, **Power Automate** can help you schedule daily or weekly updates from Dell’s API.  
- **Dynamic Replacement Flags**: A small JSON column formatting snippet or a calculated field can highlight which devices are due for replacement each year (e.g., “Replace in 2026”).  
- **Secure Your Credentials**: Always store API keys or secrets in a secure fashion (e.g., Azure Key Vault, environment variables) rather than plain-text in scripts.

---

## Conclusion
Migrating from an Excel file to a **SharePoint List** drastically simplified my small inventory management process. Collaboration improved, updates became programmatic, and pulling warranty information from Dell’s API gives real-time insights that Excel just couldn’t offer.

If you’re juggling device assignments and service tags in Excel, consider giving SharePoint + some automation a try—it might be the flexible, scalable solution you’ve been missing.

**Thanks for reading!** If you have questions or need help integrating your own solution, feel free to reach out or comment below.
