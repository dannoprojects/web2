---
title: "WiFi Monitor System"
date: 2025-04-20T00:00:00-08:00
draft: false
theme: default
menu:
  sidebar:
    name: "WiFi Monitor System"
    identifier: wifi-monitor
    parent: docker
    weight: 220
description: "Automated solution for monitoring and maintaining reliable WiFi connectivity."
tags: ["Docker", "DevOps", "Networking"]
hero: images/site/custom-hero.jpg
---

# WiFi Monitor System

## Overview

The WiFi Monitor System is an automated solution designed to monitor and maintain reliable WiFi connectivity in office environments, particularly for guest WiFi networks that may be unreliable. This system continuously checks WiFi connectivity and automatically power cycles the WiFi equipment when issues are detected, minimizing downtime and manual intervention.

## Problem Statement

Many offices experience issues with their guest WiFi networks:
- Intermittent connectivity problems
- Need for frequent manual router/access point reboots
- Disruption to guests and staff requiring WiFi access
- IT staff time wasted on repetitive troubleshooting tasks

## Solution

This automated monitoring system:
1. Continuously monitors WiFi connectivity status
2. Detects both connection and internet access issues
3. Automatically power cycles WiFi equipment when problems persist
4. Sends email notifications about connectivity issues and actions taken
5. Runs as a containerized service for easy deployment and maintenance

## Architecture

The system consists of:
- Python-based monitoring daemon
- Telnet control for power cycling WiFi hardware
- Docker containerization
- Jenkins CI/CD pipeline for automatic deployment

## Key Features

### 1. Comprehensive WiFi Monitoring

```python
def check_wifi_connection():
    """
    Checks if WiFi interface is up and connected.
    Returns True if connected, False otherwise.
    """
    wifi_up, wifi_ip = check_interface_status(WIFI_INTERFACE)
    
    if not wifi_up:
        log_message("WiFi interface is down or has no IP address.")
        return False
        
    # Check signal strength
    signal_strength = get_wifi_signal_strength()
    if signal_strength is None:
        log_message("Could not determine WiFi signal strength - possible disconnection")
    elif signal_strength < SIGNAL_THRESHOLD:
        log_message(f"Warning: WiFi signal is weak ({signal_strength} dBm)")
    
    # Check connection to local gateway
    gateway = get_default_gateway()
    if gateway:
        if ping_host(WIFI_INTERFACE, gateway):
            log_message(f"WiFi: Local gateway {gateway} is reachable.")
            return True
        else:
            log_message(f"WiFi: Local gateway {gateway} is unreachable despite active interface.")
    
    return wifi_up
```

### 2. Internet Connectivity Verification

```python
def check_wifi_internet():
    """
    Checks if public websites are reachable via WiFi.
    Returns True if any are reachable; False otherwise.
    """
    any_reachable = False
    for site in PUBLIC_WEBSITES:
        if ping_host(WIFI_INTERFACE, site):
            log_message(f"WiFi Internet: {site} is reachable.")
            any_reachable = True
        else:
            log_message(f"WiFi Internet: {site} is unreachable.")
    return any_reachable
```

### 3. Intelligent Failure Detection

The system uses consecutive failure counting to prevent unnecessary power cycling:

```python
# In the main monitoring loop:
if not wifi_internet:
    consecutive_failures += 1
    log_message(f"Consecutive failures: {consecutive_failures}")
    
    if consecutive_failures >= failure_threshold:
        log_message(f"Reached {failure_threshold} consecutive failures. Initiating toggle of Load 15...")
        # Power cycle the equipment
        asyncio.run(toggle_load(15))
        consecutive_failures = 0  # Reset failure count after toggling
```

### 4. Remote Power Control via Telnet

```python
async def toggle_load(load_number):
    # Connect to power control device via telnet
    reader, writer = await telnetlib3.open_connection(TELNET_HOST, TELNET_PORT)
    
    # Login and navigate to the appropriate menu
    # ...
    
    # Power cycle the equipment
    await send_command_sequence(reader, writer, ["2"], f"Turn OFF Load {load_number}")
    await asyncio.sleep(300)  # Wait 5 minutes
    await send_command_sequence(reader, writer, ["2"], f"Turn ON Load {load_number}")
```

### 5. Email Notifications

```python
def send_email_notification(subject, message_body):
    """
    Send an email notification about WiFi issues.
    """
    msg = EmailMessage()
    msg.set_content(message_body)
    msg['Subject'] = subject
    msg['From'] = EMAIL_FROM
    msg['To'] = EMAIL_TO
    
    with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
        server.send_message(msg)
```

## Deployment

The system is containerized with Docker and deployed via Jenkins:

```groovy
// Jenkins pipeline snippet
stage('Deploy as Service') {
    steps {
        script {
            echo "Deploying Docker container as a daemon service..."
            sh """
                # Stop and remove any existing container
                docker stop network_monitor_service || true
                docker rm network_monitor_service || true

                # Run the container as a daemon service
                docker run -d \\
                --restart always \\
                --name network_monitor_service \\
                --network=host \\
                -e TELNET_USER=$TELNET_USER \\
                -e TELNET_PASSWORD=$TELNET_PASSWORD \\
                -e MONITOR_INTERVAL=900 \\
                -e FAILURE_INTERVAL=60 \\
                -e SMTP_SERVER=10.0.1.4 \\
                -e EMAIL_TO=drowe@projectp.com \\
                network-monitor:latest daemon
            """
        }
    }
}
```

## Configuration

Key configuration parameters include:

| Parameter | Description | Default Value |
|-----------|-------------|---------------|
| NORMAL_INTERVAL | Time between checks when WiFi is working | 900 seconds (15 min) |
| FAILURE_INTERVAL | Time between checks after a failure | 60 seconds (1 min) |
| FAILURE_THRESHOLD | Number of failures before power cycling | 3 |
| PUBLIC_WEBSITES | Sites to check for internet connectivity | 8.8.8.8, 1.1.1.1 |

## Results

This system provides:
- Automated recovery from WiFi outages
- Reduced downtime for guest WiFi users
- Decreased manual intervention by IT staff
- Email alerts for persistent issues requiring attention
- Detailed logging for troubleshooting recurring problems

## Conclusion

The WiFi Monitor System provides a robust, automated solution for maintaining reliable guest WiFi connectivity in office environments with problematic internet providers or equipment, saving time and improving the experience for both office staff and visitors.