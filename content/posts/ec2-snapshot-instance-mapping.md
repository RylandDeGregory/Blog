---
title: "Map EC2 Snapshots to EBS Volumes and EC2 Instances"
date: 2021-02-02T18:32:54-05:00
draft: false
author: "Ryland DeGregory"
authorlink: "/about/"
---

When working with AWS Backup, it can sometimes (often) become difficult to correlate which EBS Volume or EC2 Instance generated each Snapshot (and subsequently is responsible for its cost), especially since the AWS Cost and Usage Report can include millions of line items for large enterprises.
<!--more-->

## AWS Snapshots - Cost vs Console

I've spent a lot of time recently working on AWS Backup cost analysis, and it's become quite challenging to make sense of Snapshot costs when working at scale. Specifically, in an environment with hundreds of Instances, thousands of Volumes, and tens of thousands of Snapshots, trying to correlate a Snapshot's line item in a Cost and Usage Report (CUR) with the resource it was generated from becomes an exercise in futility.

This issue stems from the fact the CUR has no way of associating a Snapshot to the resource that generated it (not even using the Snapshot description, which includes the Volume ID or Instance ID of the resource that it was created from). To get this data, you have to use the EC2 APIs or AWS Backup APIs, and then make the correlation with the resource costs yourself.

## Correlating resources with PowerShell

I feel like almost every post I make has something to do with PowerShell, and with good reason! No matter the platform, no matter the task, PowerShell has a way to help (the same can be said for Python, for what it's worth). In this case, PowerShell will help to gather the data from EC2 and then correlate Snapshots with their parent resources.

The script I created (represented by the gist below) works by retrieving all of the EC2 Snapshots, EBS Volumes, and EC2 Instances from each AWS Region specified in the `Regions` parameter. For each Snapshot, it uses the Snapshot metadata to determine which EBS Volume it was generated from, checks the list of EBS Volumes for that VolumeId, and then determines if the Volume is attached to an EC2 Instance. The correlated data for each Snapshot is used to create a PowerShell object.

{{< gist RylandDeGregory 1947c5fbd8f43b6b84464970dedabc91 >}}

## Analyzing the correlated data

Once the script has built the matrix, it exports it to a [CSV file](https://en.wikipedia.org/wiki/Comma-separated_values) for analysis and association with the cost data from the CUR (using the Snapshot's ResourceARN as the key value). I use PowerBI for this, but you can also use Amazon QuickSight if you are more comfortable with it or just want to use all AWS tools.