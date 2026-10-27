---
title: "Hardening Legacy Linux Web Stacks Against PHP RCE"
date: 2026-10-27T12:00:00-07:00
draft: false
theme: default
hero: images/site/custom-hero.jpg
description: "Using AWS SSM, ModSecurity, PHP-FPM hardening, and Claude Code to lock down inherited Linux web servers—and catching a subtle WAF bypass along the way."
menu:
  sidebar:
    name: "Hardening Linux Web Stacks"
    identifier: hardening-linux-web-stacks
    parent: security
    weight: 10
tags: ["Security", "Linux", "AWS", "ModSecurity", "PHP", "Claude"]
categories: ["Security", "Linux"]
---

## Overview

When recent unauthenticated PHP RCE advisories dropped (targeting `PHP_SESSION_UPLOAD_PROGRESS` and oversized request bodies), I was in the middle of auditing several inherited Linux web servers I took over following a team retirement. 

While we work through a broader migration to move legacy workloads onto fresh, Terraform-managed infrastructure, I wanted to immediately reduce our PHP attack surface and add defense-in-depth controls across the existing hosts—without causing production downtime.

Because I was working across live systems that lacked a 1:1 staging twin, I leaned heavily on **Claude Code** and **AWS Systems Manager (SSM)** to orchestrate the discovery, build hash-checked apply/rollback scripts, and run an automated `curl` verification suite after every change. Here is how we locked the environment down.

---

## 1. Turning Off PHP Where It Isn't Needed

The best way to reduce PHP risk on an inherited server is to verify whether the host actually needs PHP running at all:

* **Reverse Proxy Nodes:** During read-only discovery, I found Nginx configurations still wired to pass `*.php` requests to an active `php-fpm` pool for a legacy management tool that was no longer used. We backed up and removed the PHP location blocks, reloaded Nginx gracefully, and masked the service (`systemctl mask php-fpm`) so it can't be started accidentally.
* **Non-PHP Application Servers:** Even when a core web application doesn't use PHP, default Apache `php.conf` packages often globally route any `*.php` request (including nonexistent URLs) to `php-fpm`. We disabled the global handler, denied `.php` execution across public document roots, and restricted internal database utilities strictly to VPN subnets.

---

## 2. Hardening Public PHP Workloads

Where PHP was legitimately required for public-facing web properties, we layered multiple controls at both the web server and the PHP-FPM pool:

* **Removed legacy surface area:** Used `<LocationMatch>` at the server config level (which cannot be overridden by `.htaccess` files in the web root) to block legacy diagnostic scripts and restrict non-production vhosts strictly to internal VPN traffic.
* **Enforced strict request body limits:** Configured `LimitRequestBody` in Apache alongside matching `SecRequestBodyLimit` caps in ModSecurity so oversized POST payloads are dropped at the edge before reaching PHP.
* **Locked down the PHP-FPM pool:** Set `expose_php = Off` to stop broadcasting version headers and enforced `php_admin_flag[session.upload_progress.enabled] = off` in the pool config. Using `php_admin_flag` ensures that neither `.htaccess` nor runtime `ini_set()` calls can re-enable session upload progress.

---

## 3. Catching the 1,001-Argument ModSecurity Bypass

To block exploit attempts before they reached PHP-FPM, we added a ModSecurity virtual patch to deny any request containing the `PHP_SESSION_UPLOAD_PROGRESS` parameter.

Standard exploit tests immediately returned `403 Forbidden`. Then we tested an edge case: what happens if an attacker stuffs a `POST` request with **1,000 junk parameters** and puts the malicious trigger as the **1,001st parameter**?

**In our initial test, it bypassed the WAF rule and returned `200 OK`.**

Digging into the legacy ModSecurity configuration revealed why:
1. `SecArgumentsLimit` was set to `1000`.
2. Years earlier, a previous admin had added `SecRuleRemoveById 200001`—disabling the stock ModSecurity rule that rejects requests when the body parser hits a limit (`REQBODY_ERROR`), likely to work around false positives on complex content uploads.

Because rule `200001` was disabled, ModSecurity simply stopped inspecting parameters after argument 1,000 and passed the rest of the request through to Apache.

**The Fix:** After running a log-only rule to verify normal traffic patterns, we deployed a strict enforcement rule returning `400 Bad Request` on any `REQBODY_ERROR` (any unparseable body or >1,000 arguments). Re-running the 1,001-argument test immediately flipped the response from `200 OK` to `400 Bad Request`.

---

## 4. Hardening `systemd` Against Scanner OOM Spikes

Vulnerability disclosures always bring waves of aggressive internet scanning, which can easily trigger Out-Of-Memory (OOM) events on smaller instances. During our audit, we noticed two dangerous default settings:

* Several services were running with the default `Restart=no` policy—meaning if `systemd-oomd` killed the web server during a traffic spike, it would stay down until manually restarted.
* `php-fpm` defaulted to `OOMPolicy=stop`, meaning a single OOM-killed worker process could take down the entire PHP pool.

We deployed `systemd` drop-in overrides (`10-restart.conf`) across the fleet setting `Restart=on-failure`, `RestartSec=5s`, and `OOMPolicy=continue`, and removed an unused legacy background agent to free up system memory. Testing with `kill -9` confirmed the web daemon recovered automatically in under 6 seconds.

---

## Orchestrating Changes Safely with Claude Code

Making dozens of web server, WAF, and `systemd` changes across live production servers requires tight guardrails. Rather than hand-editing config files over SSH, I used **Claude Code** to help build a structured deployment workflow over AWS SSM:

* **Read-Only Discovery First:** Every step started with non-destructive SSM scripts checking active listeners, file checksums, and weeks of access logs to confirm nothing legitimate would break.
* **Hash-Guarded Apply & Rollback Scripts:** Every change was packaged as a paired `apply.sh` and `rollback.sh`. Scripts verified the SHA-256 hash of existing config files before making changes, used drop-in files (`zz-*.conf`) instead of editing base configs wherever possible, and verified `apachectl configtest` / `nginx -t` before reloading.
* **Automated Regression Suite:** We built a 50+ check bash test harness that verified public pages, authentication flows, request size caps, and our ModSecurity bypass tests before and after every single step.

Forty-eight hours after wrapping up the deployment, automated scanners swept across our public IPs firing `PHP_SESSION_UPLOAD_PROGRESS` payloads. Every probe was dropped at the edge with a `403`, with zero worker crashes or false positives.
