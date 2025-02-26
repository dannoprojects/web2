---
title: "Setting Up Docker and Jenkins on Raspberry Pi"
date: 2025-02-20T00:00:00-08:00
draft: false
theme: default
menu:
  sidebar:
    name: "Setting up Docker and Jenkins on a Raspberry Pi"
    identifier: docker-pi
    parent: docker
    weight: 210
description: "Setting up Docker and Jenkins on a Raspberry Pi."
tags: ["Docker", "Containers", "DevOps"]
hero: images/site/custom-hero.jpg
---

# Raspberry Pi Docker and Jenkins Setup

This guide provides step-by-step directions to set up your Raspberry Pi to run Docker and Jenkins with the following configuration:

1. **Install and Configure Docker on the Raspberry Pi**
2. **Configure Jenkins to Run in a Docker Container** 
3. **Schedule a daily build** to run a Python script from the repository every day at 8:00 AM
4. **Enable Docker-in-Docker** (allow Jenkins to run Docker commands)
5. **Set the local timezone** to Pacific Standard Time (Los Angeles)
6. **Adjust host permissions** on the Raspberry Pi as needed
7. **Set up the Jenkins pipeline** to prune previous Docker images



---

## 1. Install and Configure Docker on the Raspberry Pi

{{< gist dannoprojects d9fa3c3d2bc91a7861c92eb3c85635eb "DockerPi_install">}}

## 2. Configure Jenkins to Run in a Docker Container
Create a file named "Dockerfile.jenkins with the following content and change the group ID to the Docker group
{{< gist dannoprojects d9fa3c3d2bc91a7861c92eb3c85635eb "JenkinsDockerFile">}}

Build a Docker image that:
* Set to Pacific time Zone
* Allows Jenkins to communicate with Docker

{{< gist dannoprojects d9fa3c3d2bc91a7861c92eb3c85635eb "BuildRunCustomImage">}}
