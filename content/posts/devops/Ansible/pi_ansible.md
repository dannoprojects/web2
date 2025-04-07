---
title: "Setting Up Docker and Jenkins on Raspberry Pi"
date: 2025-03-03T00:00:00-08:00
draft: true
theme: default
menu:
  sidebar:
    name: "Ansible for Pi Config"
    identifier: ansible
    parent: ansible
    weight: 210
description: "Ansible for Pi Config."
tags: ["Ansible","DevOps"]
hero: images/site/custom-hero.jpg
---
### Install Ubuntu on the Pi

sudo apt update && sudo apt upgrade -y

sudo timedatectl set-timezone America/Los_Angeles


Create a key pair
ssh-keygen -t ed25519 -C "ansible-github-key" -f ~/.ssh/id_ed25519_ansible

Configure ssh
Host github-ansible
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_ansible
    IdentitiesOnly yes

clone using the new profile
git clone git@github-ansible:danr-pp/pi-ansible-config.git ~/ansible

install ansible
sudo apt install ansible-core