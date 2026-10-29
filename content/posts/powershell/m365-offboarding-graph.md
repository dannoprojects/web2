---
title: "A Repeatable Microsoft 365 Offboarding Script with Graph PowerShell"
date: 2026-07-09T09:00:00-07:00
description: "Turning a manual offboarding checklist into a single PowerShell script using Microsoft Graph and Exchange Online. It disables the account, revokes sessions, converts the mailbox, delegates access to the manager, removes licenses in the right order, and emails HR and the manager when it's done."
draft: false
theme: default
hero: images/site/custom-hero.jpg
menu:
  sidebar:
    name: M365 Offboarding Script
    identifier: m365-offboarding-graph
    parent: powershell
    weight: 10
tags: ["PowerShell", "Microsoft Graph", "Microsoft Entra ID", "PIM", "Exchange Online", "Automation", "Offboarding"]
categories: ["PowerShell"]
---

## Overview

Offboarding is one of those tasks that's simple on paper and easy to get subtly wrong in practice. Miss a step and you end up with a departed user who still has an active session token, a mailbox nobody can read, or a license you're paying for months later.

Between employees and a steady rotation of contractors, I was offboarding people often enough that a checklist in my head wasn't good enough. This post walks through the script I use now. It takes a UPN and runs the whole sequence the same way every time.

## The Checklist

Here's the sequence the script automates, **in this order**:

1. Disable sign-in.
2. Revoke all refresh tokens and sessions.
3. Convert the mailbox to a **shared mailbox** and hide it from the address list.
4. Give the user's **manager** Full Access to the mailbox.
5. Remove the user from cloud groups.
6. Remove directly assigned licenses.
7. Email an "offboarding complete" summary to **HR and the manager**.

The order matters. If you remove the Exchange license **before** converting the mailbox to shared, the mailbox starts down the path to being disabled. Convert first, then pull licenses.

## Prerequisites

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
Install-Module ExchangeOnlineManagement -Scope CurrentUser
```

If you use Privileged Identity Management (PIM), activate these roles before running the script:

| Role | Why the script needs it |
|---|---|
| **User Administrator** | Disable the account, remove licenses, and manage group membership |
| **Authentication Administrator** | Revoke sign-in sessions and refresh tokens |
| **Exchange Administrator** | Convert the mailbox, set permissions, and manage distribution lists |

The Graph connection also requests `Mail.Send` so the script can send the confirmation email from your account. The first run will prompt you to consent to that scope.

## The Script

```powershell
<#
.SYNOPSIS
  Offboards a Microsoft 365 user: disable, revoke, convert mailbox,
  delegate to manager, remove groups and licenses, then email HR
  and the manager a confirmation.
.EXAMPLE
  .\Invoke-M365Offboarding.ps1 -UserPrincipalName jdoe@example.com -WhatIf
.EXAMPLE
  .\Invoke-M365Offboarding.ps1 -UserPrincipalName jdoe@example.com -HrAddress hr@example.com
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$UserPrincipalName,

    # Optional override if the manager isn't set in Entra ID
    [string]$DelegateTo,

    # Where the confirmation email goes (in addition to the manager)
    [string]$HrAddress = 'hr@example.com'
)

$ErrorActionPreference = 'Stop'
$log = [System.Collections.Generic.List[string]]::new()

Connect-MgGraph -Scopes 'User.ReadWrite.All','Group.ReadWrite.All','Directory.ReadWrite.All','Mail.Send' -NoWelcome
Connect-ExchangeOnline -ShowBanner:$false

$user = Get-MgUser -UserId $UserPrincipalName -Property Id,DisplayName,UserPrincipalName,AssignedLicenses

# Resolve the manager (used for mailbox delegation and the confirmation email)
$managerUpn = $null
try {
    $mgr = Get-MgUserManager -UserId $user.Id
    $managerUpn = $mgr.AdditionalProperties['userPrincipalName']
} catch { Write-Warning 'No manager set in Entra ID.' }

if (-not $DelegateTo) { $DelegateTo = $managerUpn }
if (-not $DelegateTo) { Write-Warning 'No delegate found; mailbox will not be delegated.' }

# 1-2. Disable sign-in and revoke sessions
if ($PSCmdlet.ShouldProcess($UserPrincipalName, 'Disable account and revoke sessions')) {
    Update-MgUser -UserId $user.Id -AccountEnabled:$false
    Revoke-MgUserSignInSession -UserId $user.Id | Out-Null
    $log.Add('The account has been disabled and all sign-in sessions have been revoked.')
}

# 3. Convert the mailbox to shared and hide it from the GAL
if ($PSCmdlet.ShouldProcess($UserPrincipalName, 'Convert mailbox to shared')) {
    Set-Mailbox -Identity $UserPrincipalName -Type Shared
    Set-Mailbox -Identity $UserPrincipalName -HiddenFromAddressListsEnabled $true
    $log.Add('The mailbox has been converted to a shared mailbox and hidden from the address list.')
}

# 4. Delegate mailbox access
if ($DelegateTo -and $PSCmdlet.ShouldProcess($UserPrincipalName, "Grant Full Access to $DelegateTo")) {
    Add-MailboxPermission -Identity $UserPrincipalName -User $DelegateTo `
        -AccessRights FullAccess -InheritanceType All -AutoMapping $true | Out-Null
    $log.Add("$DelegateTo has been granted access to the mailbox.")
}

# 5. Remove cloud group memberships (skip dynamic and mail-enabled groups)
$groups = Get-MgUserMemberOf -UserId $user.Id -All |
    Where-Object { $_.AdditionalProperties['@odata.type'] -eq '#microsoft.graph.group' }

foreach ($g in $groups) {
    $types      = $g.AdditionalProperties['groupTypes']
    $mail       = $g.AdditionalProperties['mailEnabled']
    $isUnified  = $types -contains 'Unified'
    $isDynamic  = $types -contains 'DynamicMembership'
    $name       = $g.AdditionalProperties['displayName']

    if ($isDynamic) { continue }  # membership is rule-based

    if ($mail -and -not $isUnified) {
        # Distribution lists / mail-enabled security groups are managed in Exchange
        if ($PSCmdlet.ShouldProcess($name, 'Remove from distribution group')) {
            Remove-DistributionGroupMember -Identity $g.AdditionalProperties['mail'] -Member $UserPrincipalName `
                -BypassSecurityGroupManagerCheck -Confirm:$false
        }
    }
    elseif ($PSCmdlet.ShouldProcess($name, 'Remove from group')) {
        Remove-MgGroupMemberByRef -GroupId $g.Id -DirectoryObjectId $user.Id
    }
}
# 6. Remove directly assigned licenses (after mailbox conversion)
$skuIds = @($user.AssignedLicenses.SkuId)
if ($skuIds.Count -and $PSCmdlet.ShouldProcess($UserPrincipalName, 'Remove licenses')) {
    try {
        Set-MgUserLicense -UserId $user.Id -AddLicenses @() -RemoveLicenses $skuIds | Out-Null
    } catch {
        Write-Warning "Some licenses may be group-assigned and were removed with group membership: $_"
    }
}
if (-not $WhatIfPreference) { $log.Add('Group memberships and licenses have been removed.') }

# 7. Build the summary and email HR and the manager
$summary = @"
This is to confirm that $($user.DisplayName) ($UserPrincipalName) has been offboarded as of $(Get-Date -Format 'MM-dd-yyyy').

$(($log | ForEach-Object { "  * $_" }) -join "`n")
"@

$recipients = @($HrAddress, $managerUpn) | Where-Object { $_ } | Select-Object -Unique

if ($PSCmdlet.ShouldProcess(($recipients -join ', '), 'Send offboarding confirmation')) {
    $mail = @{
        Message = @{
            Subject      = "Offboarding complete: $($user.DisplayName)"
            Body         = @{ ContentType = 'Text'; Content = $summary }
            ToRecipients = @($recipients | ForEach-Object { @{ EmailAddress = @{ Address = $_ } } })
        }
        SaveToSentItems = $true
    }
    $sender = (Get-MgContext).Account
    Send-MgUserMail -UserId $sender -BodyParameter $mail
    Write-Host "Confirmation sent to: $($recipients -join ', ')"
}

$summary
```

## Things the Script Handles (and Why)

**Revoking sessions, not just disabling.** Disabling an account stops *new* sign-ins, but an existing refresh token can keep an app session alive for a while. `Revoke-MgUserSignInSession` invalidates those tokens so access ends now, not eventually.

**Distribution lists vs. Microsoft 365 groups.** Microsoft Graph can't change membership of distribution lists or mail-enabled security groups. Those still live in Exchange. The script checks `mailEnabled` and `groupTypes` and sends each group to the right cmdlet.

**Dynamic groups are skipped.** Their membership is rule-based, and disabling the account (or changing attributes) takes care of them.

**Group-based licensing.** If licenses are assigned through a group, `Set-MgUserLicense` can't remove them directly. They drop off when the user leaves the group. The `try/catch` keeps the script from stopping on that case.

**Emailing HR and the manager.** The script sends the summary from the signed-in admin's mailbox with `Send-MgUserMail`, to the HR address and the manager from Entra ID, and keeps a copy in Sent Items as a record. If no manager is set, HR still gets the email. With `-WhatIf`, it shows who *would* be emailed without sending anything.

**`-WhatIf` support.** `SupportsShouldProcess` means I can dry-run against a real user and see exactly what *would* happen before committing. I always run it with `-WhatIf` first.

## What's Still Manual (For Now)

A script shouldn't pretend it handles everything. These are still on my checklist outside the script:

- **Devices:** retire or wipe the user's laptop in Intune and arrange its return.
- **OneDrive:** confirm the manager has access before the retention window closes. Microsoft 365 can grant this automatically if *OneDrive retention and manager access* is configured in the SharePoint admin center.
- **Third-party apps** that don't use SSO, plus any shared credentials the user knew.
- **Timing:** for contractors, I schedule the run for the end of their final day rather than the morning of.

## Lessons Learned

- **Order of operations matters.** Converting the mailbox before removing licenses is the step people most often get backwards.
- **Make it boring.** The value of the script isn't speed. It's that the hundredth offboarding happens exactly like the first.
- **Close the loop automatically.** Sending the confirmation straight to HR and the manager means nobody has to ask whether it's done, and the Sent Items copy doubles as an audit trail.
- **Least privilege, just in time.** Running under PIM-activated roles means the script only has admin rights for the window you actually need them.

