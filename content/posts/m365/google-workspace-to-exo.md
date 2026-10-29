---
title: "Moving 70 Mailboxes from Google Workspace to Exchange Online Without Losing a Message"
date: 2025-10-24T09:00:00-07:00
description: "A practical cutover checklist for a small-company Google Workspace to Exchange Online migration, covering coexistence, SPF/DKIM/DMARC, shared mailboxes, Power Automate, and cleaning up Google licensing afterward."
draft: false
theme: default
hero: images/site/custom-hero.jpg
menu:
  sidebar:
    name: Google Workspace to EXO
    identifier: google-workspace-to-exo
    parent: m365
    weight: 10
tags: ["Microsoft 365", "Exchange Online", "Google Workspace", "Migration", "DMARC", "DKIM", "SPF", "Power Automate"]
categories: ["Microsoft 365"]
---

## Overview

Email is the one system nobody notices until it stops working. When we moved a 70-person company from Google Workspace to Exchange Online, the goal wasn't just "move the mail." It was to move the mail **without anyone missing a message, a calendar invite, or an automated workflow** that quietly depended on a Gmail inbox.

This post is the checklist I wish I'd had at the start. It's written for small IT teams (often a team of one) doing a cutover without a migration partner.

## 1. Inventory Before You Touch DNS

The mailboxes are the easy part. The things that break are everything *around* the mailboxes:

- **Shared inboxes and groups.** Google Groups used as shared inboxes (support@, hr@, billing@) need a deliberate destination: an Exchange shared mailbox, a distribution list, or a Microsoft 365 group.
- **Things that send mail.** Copiers with scan-to-email, monitoring tools, line-of-business apps, and scripts that relay through Gmail SMTP.
- **Automations that read mail.** Any Power Automate flow, Zap, or script that triggers off a Gmail inbox.
- **Block lists and filters.** Senders you've blocked over the years live in Google's admin console, not in your head.
- **Who actually uses what.** Some "users" are former employees, service accounts, or aliases that should become shared mailboxes or simply be archived.

I put all of this in a SharePoint list with a column for "destination in M365" and "verified after cutover." That list became the cutover runbook.

## 2. Build the Destination First

Before migrating any data, I stood up the Exchange Online side completely:

- Licensed user mailboxes for real people.
- **Shared mailboxes** for team inboxes. They don't need a license under 50 GB, and access is managed by permission rather than password sharing.
- **Distribution lists** for simple fan-out addresses.
- Mail-enabled security groups only where something also needed SharePoint or app permissions.

Getting the destination right first means users land in a finished environment instead of one that's still being assembled around them.

## 3. Migrate in Batches

I ran the mailbox data migration in batches from the Exchange admin center. The pattern that worked:

1. **Pilot batch.** IT plus one or two friendly power users. Validate mail, calendar, contacts, and labels-to-folders mapping.
2. **Bulk batches.** Grouped by department so each team cut over together.
3. **Incremental syncs** right up to the MX change, so the final delta was small.

Expect at least one mailbox to get stuck. Mine was a sync issue on a large mailbox that needed a couple of re-runs. Leave yourself slack in the schedule for it.

## 4. Authentication: SPF, DKIM, and DMARC

This is where a lot of small migrations leave risk on the table. During coexistence, both Google and Microsoft may send as your domain, so your records need to reflect that, and then get tightened once Google is out of the path.

**SPF, during coexistence:**

```text
example.com.  TXT  "v=spf1 include:spf.protection.outlook.com include:_spf.google.com -all"
```

**SPF, after cutover:**

```text
example.com.  TXT  "v=spf1 include:spf.protection.outlook.com -all"
```

Don't forget anything else that sends as your domain (a marketing platform, a ticketing system). Every one of those needs to be in SPF or sending through an authenticated path.

**DKIM:** In the Microsoft Defender portal, go to *Email & collaboration → Policies & rules → Threat policies → Email authentication settings → DKIM*. Microsoft gives you two CNAME records (`selector1._domainkey` and `selector2._domainkey`). Publish both exactly as shown, wait for DNS to propagate, then enable signing.

**DMARC:** Start in monitor mode so you can see who is sending as you before you start enforcing:

```text
_dmarc.example.com.  TXT  "v=DMARC1; p=none; rua=mailto:dmarc-reports@example.com; fo=1"
```

Once the aggregate reports show only legitimate senders passing, step up to `p=quarantine`, and eventually `p=reject`.

## 5. Don't Forget the Block List

Years of "please block this sender" requests lived in Google's admin console. I exported them and re-created them in the **Tenant Allow/Block List** in Microsoft Defender. In Exchange Online PowerShell:

```powershell
Connect-ExchangeOnline

$blocked = Import-Csv .\google-blocked-senders.csv   # column: Sender
New-TenantAllowBlockListItems -ListType Sender -Block `
    -Entries $blocked.Sender -NoExpiration
```

This is a small step, but users notice immediately when spam they'd "already blocked" comes back.

## 6. Fix the Automations

Several Power Automate flows triggered off a Google shared inbox. After cutover, each one had to be repointed to the new Exchange shared mailbox using the Office 365 Outlook trigger **"When a new email arrives in a shared mailbox (V2)."** Test every flow end to end with a real message, not just a "Save."

The same goes for devices and apps that sent mail. I verified each relay path (scan-to-email, application notifications) by sending a real message and confirming delivery with **message trace** in the Exchange admin center.

## 7. Cutover Day

- Lower the MX record TTL a day or two ahead.
- Run the final incremental sync.
- Flip MX to Exchange Online Protection.
- Watch **message trace** and the **quarantine** for the first 24–48 hours. Legitimate mail caught by new filtering is the most common day-one complaint.
- Send users a short Outlook setup guide (desktop, mobile, and "where did my labels go?").

## 8. Clean Up Google Afterward

Once mail was flowing and users had settled in, I exported what needed to be retained and archived the majority of the Google accounts. That alone cut the next Google billing cycle by roughly **$400**, a nice way to close out the project with a visible win.

## Lessons Learned

- **The inventory is the project.** The mailbox move is mostly mechanical. The surprises come from shared inboxes, relays, and automations.
- **Treat DMARC as part of the migration**, not a follow-up ticket. You'll never have a better moment to get it right.
- **Verify with message trace, not assumptions.** "It should work" isn't the same as a delivered message.
- **Close the loop on cost.** Archiving the old platform promptly turns a migration into a savings story.

