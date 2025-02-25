---
title: "New-TimeSpan"
date: 2022-03-24T18:59:41-08:00
draft: false
theme: Toha
menu:
    sidebar:
        name: New-TimeSpan
        identifier: powershell-new-timepan
        parent: powershell
        weight: 10
hero: images/site/custom-hero.jpg
---

I was investigating an issue with our identity provider and out of date passwords the other day.  I needed to do a date comparison to find accounts with expired passwords. In the past I’d used (Get-Date).AddDays() and done an evaluation.   It works, but to me the code is hard to read. 

I stumbled on the New-Timespan cmdlet which creates a timespan object.  Creating a timespan object and referencing the days property is so much easier to read when you look at the code.  

Here’s an example of it in use to find accounts with expired passwords.

{{< gist dannoprojects 575d959199fd39b718c5a19b942c126b "NewTimeSpan" >}}

The $DateCheck variable is an integer of the number of days between the PasswordLastSet and Today.  

The result is easy to check, and it makes the If condition simple too .  It’s a number.  

I was happy to find something new in PowerShell.

#### Links

- [NewTime-Span](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/new-timespan?view=powershell-7.2)