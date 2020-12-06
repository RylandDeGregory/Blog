---
title: "Rename Azure VM"
author: "Ryland DeGregory"
authorlink: "/about/"
date: 2020-05-22T18:28:52-04:00
draft: false
categories:
- Azure
- PowerShell
---

Azure doesn't let you rename Virtual Machine resources after provisioning. Here's how to fix it.

<!--more-->

## Azure vs AWS - A Tale of Two Names

Azure and AWS, though similar in most ways, are fundamentally different in others, such as the name of a virtual machine. In Azure, once you create a virtual machine, it will always have that name. You can't change it, not even the casing. In AWS, the name of an EC2 instance is simply a tag, with the key being **Name** and the value being the name of the instance. It can be changed at any time, or left blank.

## Docker EE trouble leads to discovery

While deploying Docker Enterprise, an issue arose where the automatically-provisioned Linux VMs that were set to be worker nodes in the swarm were launched with the Azure resource name in all caps (e.g. *USDKREEWKR01*). This is usually no issue, most of our Linux VMs in Azure are named this way. The hostname in-os is set to lower case during post-provisioning (e.g. *usdkreewkr01*). However, Docker EE is a little different. When the UCP started failing, we spent some time combing the [Docker Docs](https://docs.docker.com/ee/ucp/admin/install/cloudproviders/install-on-azure/#azure-prerequisites) one more time. I found a little, seemingly insignificant note buried in the requirements:

> The Azure Virtual Machine Object Name needs to match the Azure Virtual Machine Computer Name and the Node Operating System’s Hostname which is the FQDN of the host, including domain names. **Note that this requires all characters to be in lowercase**.

Wow. Ok, no problem. We'll just change the resource names!

Azure said no.

## The solution -- again -- PowerShell

We came up with the short PowerShell script below to "rename" an Azure virtual machine. This is done by copying the original Azure VM resource into a PowerShell object, creating a new VM with the same configuration, but the name in lower case (or whatever other transformation you want to make, just change `$newVMName`), and attaching all of the subordinate resources of the original VM (tags, disks, network interfaces) to the new VM.

The script accepts a PowerShell array for the `-Servers` parameter, so long as all Azure virtual machine resources within the array belong to the same OS platform (Windows or Linux).

{{% admonition type=tip title="Tip" open=true %}}
The script can be found on GitHub as the [Gist](https://gist.github.com/RylandDeGregory/49ba4e88311fcefd710a298eba0790c1) below.
{{% /admonition %}}

{{< gist RylandDeGregory 49ba4e88311fcefd710a298eba0790c1 >}}
