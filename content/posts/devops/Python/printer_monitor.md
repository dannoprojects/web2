---
title: "Printer Monitor: Because Printers Are Out to Get Us"
date: 2025-04-14T00:00:00-08:00
draft: false
theme: default

menu:
  sidebar:
    name: "Printer Monitor: Because Printers Are Out to Get Us"
    identifier: python-printer-monitor
    parent: python
    weight: 210

description: "Automate printer supply monitoring and notifications with Python"
tags:
  - Python
  - Printers
  - Automation
  - Monitoring
hero: images/site/custom-hero.jpg
---

# Printer Monitor: Because Printers Are Out to Get Us

No one wants to be the printer whisperer—especially for low-cost, unmanaged printers. After one too many toner emergencies (always at 4:59 PM on a Friday), I decided to automate the pain away. If you’re tired of being the “toner psychic,” this Python script is for you.

---

## Why?

Printers are needy, dramatic, and love to run out of toner at the worst possible moment. This project checks their status, logs the drama, and even emails you when it’s time to order more supplies. No more “surprise, you’re out of magenta!” moments.

---

## What Does It Do?

Monitors multiple printers for:

- Toner levels (Black, Cyan, Magenta, Yellow—yes, even that one you never have in stock)
- Waste toner status (because that’s a thing, apparently)
- Approximate pages remaining (for the truly paranoid)
- Sends email notifications when supplies are low, so you can ignore them at your leisure
- Logs everything, because if it’s not in the logs, it didn’t happen

---

## The Problem: Printers Are the Worst

Let's be honest—printers were invented by someone who truly hates IT professionals. They break constantly, lie about their status, and always run out of toner during the most critical print job of the year. We have three different HP models, each with its own special way of reporting toner levels, because why would there be any standardization.

---

## The Solution: Python to the Rescue

I cobbled together this using Python, Selenium, and some grit.  It did take some trial and error to get the web pages to parse though.

```python
# The imports alone should tell you how much pain went into this
import requests
from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
# ...plus about 20 more imports because PRINTERS
```

The script does several things:
1. Connects to each printer's embedded web server
2. Scrapes the toner levels using either direct HTTP requests or Selenium for the particularly stubborn ones
3. Logs everything (because documentation or it didn't happen)
4. Emails me when supplies are running low

The best part is how it handles different printer models:

```python
for printer in config["printers"]:
    if printer["type"] == "pages_remaining":
        # Deal with the M404dn's special snowflake reporting
    elif printer["type"] == "toner":
        # Extract percentage from the M402's bizarre format
    elif printer["type"] == "mfp":
        # Handle the MFP which reports FOUR different toners
        # Because one toner cartridge wasn't expensive enough
```

---

## How Does It Work?

You’ll need Python 3.8+, a few pip installs, and a willingness to admit that YAML is better than Excel for this sort of thing.

Configure your `.env` file with your Google API credentials and log file path. Then, set up your printers in `printers.yaml` like so:

```yaml
# printers.yaml
printers:
  - name: "OfficePrinter1"
    ip: "192.168.1.100"
    model: "HP LaserJet 400"
  - name: "ColorPrinter"
    ip: "192.168.1.101"
    model: "Brother HL-L8360CDW"
```

---

## Running the Script

You could run it manually:

```sh
python printer_status.py
```

But let’s be honest, you’ll forget. That’s why we automate.

---

## Scheduling with Windows Task Scheduler (Because Cron Jobs Are Too Mainstream)

Here’s how I made Windows do my dirty work:

1. Open **Task Scheduler** (search for it in the Start menu—yes, it still exists).
2. Create a **New Task**. Name it something like “Printer Monitor” so future-you knows what it is.
3. Set the **Trigger** to run daily at 7:00 AM, or whenever you want to be reminded of your printer’s existential crisis.
4. Set the **Action**:
    - **Program/script**: Path to your Python executable (e.g., `C:\Users\You\AppData\Local\Programs\Python\Python39\python.exe`)
    - **Add arguments**: `printer_status.py`
    - **Start in**: `PrinterMonitor`
5. Save. Enter your password. Curse at UAC. Done.

Make sure the service account running the task has network access to all the printers. I learned that one the hard way after two days of debugging silent failures.

---

## The Results

Now when toner runs low, I get an email like this:

```
Order Printer Supplies:

M402 Black toner percentage: 10%
Order 26X (CF226X)

MFP Black Cartridge (CE400X): 8%
```



---

## Lessons Learned

1. YAML is significantly better than hardcoding printer information
2. Selenium is your friend for awful printer web interfaces
3. Headless Chrome is CPU-intensive but worth it
4. Always, always check your `path_to_credentials.json` is correct in the Task Scheduler

---

## The Code

If you too want to avoid the "surprise toner emergency," check out the [complete code](https://github.com/dannoprojects/PrinterMonitor).

Because remember:
> The best sysadmin is the one who automates themselves out of the most tedious tasks.

