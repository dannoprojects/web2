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

Step-by-step guide to set up a Raspberry Pi to run Docker and Jenkins.

## 1. Install and Configure Docker

{{< gist dannoprojects d9fa3c3d2bc91a7861c92eb3c85635eb "DockerPi_install">}}

## 2. Configure Jenkins to Run in a Docker image
Create a file named "Dockerfile.jenkins with the following content and change the group ID to the Docker group
{{< gist dannoprojects d9fa3c3d2bc91a7861c92eb3c85635eb "jenkins_setup">}}

Add the following to the Jenkins file
{{< gist dannoprojects d9fa3c3d2bc91a7861c92eb3c85635eb "JenkinsDockerFile">}}

## 3. Build and run the Docker image

{{< gist dannoprojects d9fa3c3d2bc91a7861c92eb3c85635eb "BuildRunCustomImage">}}
