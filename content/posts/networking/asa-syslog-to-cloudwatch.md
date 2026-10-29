---
title: "Sending Cisco Firewall Logs to CloudWatch Without Drowning in Noise"
date: 2026-04-14T09:00:00-07:00
description: "How I routed Cisco ASA syslog through a small Linux relay into Amazon CloudWatch Logs, trimmed it down to what matters, and turned the important events into metrics, alarms, and a dashboard."
draft: false
theme: default
hero: images/site/custom-hero.jpg
menu:
  sidebar:
    name: ASA Logs to CloudWatch
    identifier: asa-syslog-to-cloudwatch
    parent: networking
    weight: 20
tags: ["Cisco", "Firepower", "ASA", "Syslog", "AWS", "CloudWatch", "Monitoring", "rsyslog"]
categories: ["Networking"]
---

## Overview

In an [earlier post](/posts/networking/cisco-firepower-saml-mfa/) I set up SAML and MFA for VPN on a Cisco Firepower 1120 running ASA. Once that was in place, the next question was obvious: **how do I know when something is wrong with the firewall without logging into ASDM every morning?**

We already ran most of our infrastructure in AWS, so Amazon CloudWatch was the natural place to land firewall logs. The first attempt worked, and it also sent *everything*. The log volume was noisy, expensive to keep, and useless for alerting. This post covers the version I ended up with: a small Linux syslog relay, a trimmed log stream, and a handful of metric filters that drive alarms and a dashboard.

## Architecture

```text
Cisco ASA (Firepower 1120)
   │  syslog (UDP 514)
   ▼
Linux relay (rsyslog)  ──►  /var/log/cisco/asa.log
   │  amazon-cloudwatch-agent
   ▼
CloudWatch Logs  ──►  Metric filters  ──►  Alarms (SNS)  +  Dashboard
```

The relay can be any small Linux host the firewall can reach. I reused an existing utility server that already had the CloudWatch agent installed.

## Step 1: Point the ASA at the Relay

From the ASA CLI (or the equivalent in ASDM under *Device Management → Logging*):

```text
logging enable
logging timestamp
logging device-id hostname
logging host inside 10.0.0.25
logging trap warnings
```

A few notes:

- `logging trap` sets the **severity sent to the syslog server**. My first pass used `informational`, which includes every connection build and teardown. That was the main source of noise. Moving to `warnings` cut volume dramatically while keeping denies, threat detection, and failures.
- If you need a specific informational message (for example, AAA rejects for VPN logins, which are severity 6), you can raise just that message instead of lowering the whole trap level:

```text
logging message 113005 level warnings
```

## Step 2: Receive and Separate the Logs with rsyslog

On the relay, enable UDP input and write ASA traffic to its own file so it doesn't mix with system logs. ASA sends on facility `local4` by default.

`/etc/rsyslog.d/30-cisco-asa.conf`:

```text
module(load="imudp")
input(type="imudp" port="514")

if $syslogfacility-text == 'local4' then {
    action(type="omfile" file="/var/log/cisco/asa.log")
    stop
}
```

```bash
sudo mkdir -p /var/log/cisco
sudo systemctl restart rsyslog
```

Make sure the relay's host firewall and any AWS security group only allow UDP 514 **from the firewall's address**. You don't want an open syslog listener.

Add a logrotate entry for `/var/log/cisco/asa.log` too. The CloudWatch agent handles rotation fine, but your disk won't appreciate an unrotated firewall log.

## Step 3: Ship the File with the CloudWatch Agent

Add the log file to the agent's `collect_list` in `/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json`:

```json
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/cisco/asa.log",
            "log_group_name": "/network/cisco-asa",
            "log_stream_name": "{instance_id}",
            "retention_in_days": 90
          }
        ]
      }
    }
  }
}
```

Reload the agent:

```bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
```

Setting `retention_in_days` matters. CloudWatch Logs defaults to never expiring, and that's where a noisy log group quietly becomes a line item.

## Step 4: Turn Important Events into Metrics

Logs are for investigating. **Metrics are for alerting.** I created a metric filter for each type of event I actually wanted to be woken up for. For example, VPN authentication rejects:

```bash
aws logs put-metric-filter \
  --log-group-name /network/cisco-asa \
  --filter-name asa-aaa-reject \
  --filter-pattern '"%ASA-4-113005"' \
  --metric-transformations \
      metricName=AaaAuthReject,metricNamespace=Network/ASA,metricValue=1,defaultValue=0
```

> Because I raised message 113005 to `warnings` in Step 1, it arrives as `%ASA-4-113005` rather than the default `%ASA-6-113005`. Match the pattern to the level you configured.

Other filters worth considering (verify the message IDs against your ASA version's syslog reference):

| What | Pattern idea |
|---|---|
| Threat detection rate exceeded | `"%ASA-4-733100"` |
| Denied inbound traffic | `"%ASA-2-106001"` or `"%ASA-4-106023"` |
| Any critical/alert/emergency | `"%ASA-1-"`, `"%ASA-2-"` |

## Step 5: Alarms and a Dashboard

An alarm on the auth-reject metric, sending to an SNS topic that emails the IT mailbox:

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name asa-vpn-auth-rejects-high \
  --namespace Network/ASA \
  --metric-name AaaAuthReject \
  --statistic Sum --period 300 --evaluation-periods 1 \
  --threshold 10 --comparison-operator GreaterThanThreshold \
  --treat-missing-data notBreaching \
  --alarm-actions arn:aws:sns:us-west-2:111122223333:it-alerts
```

The thresholds are a judgment call. Start loose, watch a couple of weeks of data, then tighten. An alarm that fires every day gets ignored, which is worse than no alarm.

For the dashboard, I put the metric-filter graphs next to a **Logs Insights** widget that shows the most recent high-severity lines:

```text
fields @timestamp, @message
| filter @message like /%ASA-[1-3]-/
| sort @timestamp desc
| limit 20
```

Now the firewall's morning check is a single CloudWatch dashboard tab.

## A Side Fix: SIP Inspection

While reviewing the running config, I also removed SIP inspection from the default policy. ASA's SIP inspection is a well-known cause of odd VoIP and Wi-Fi calling behavior when you aren't running an on-prem phone system through the firewall:

```text
policy-map global_policy
 class inspection_default
  no inspect sip
```

Test this in your environment first. If you *do* rely on the ASA to handle SIP, leave it on.

## Lessons Learned

- **Trim at the source.** Lowering `logging trap` on the ASA did more for cost and clarity than any filtering downstream.
- **Separate logs early.** A dedicated file and log group per device type keeps metric filters simple.
- **Set retention on day one.** Never-expiring log groups are a slow-moving bill.
- **Alert on metrics, investigate in logs.** Metric filters turn a wall of text into a few numbers you can actually watch.

