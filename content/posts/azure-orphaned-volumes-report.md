---
title: "Identify Azure Orphaned Volumes"
date: 2021-06-06T16:12:08-04:00
draft: false
author: "Ryland DeGregory"
authorlink: "/about/"
categories:
- Azure
- PowerShell
- Azure Resource Graph
---

Detecting orphaned volumes (disks which are not attached to any virtual machine) can become a challenging endeavor, especially when faced with an environment containing thousands of virtual machines. Luckily, Azure Resource Graph allows users to easily identify orphaned volumes across their entire Azure estate.

<!--more-->

## What are orphaned volumes

In a large-scale, constantly changing Azure environment consisting of thousands of virtual machines, inevitably some resources will be left behind. Whether its due to incomplete manual cleanup, a forgotten PoC, or a platform migration, virtual machine data disks (and even operating system disks) are sometimes left behind after their parent virtual machine is removed or repurposed. If left unaccounted for, these disks will continue to generate cost every month whether they are used or not. Orphaned disks can be viewed in the Azure Portal by looking for disks whose **Owner** is listed as `-`.

![Orphaned Azure Disks in the Azure Portal](images/azure-orphaned-volumes/orphaned-vols-portal.png "Orphaned Azure Disks in the Azure Portal")

Getting a list of disks from the Azure Portal is useful, but doesn't work as well for scheduled operations such as weekly reports. I don't want to have to log in to the portal, pull up the list of Disks, filter to the ones that are orphaned, and click the **Export to CSV** button every Monday morning for the rest of time. Let's automate this.

## Azure Resource Manager and Azure Resource Graph

Azure's deployment and management service, [Azure Resource Manager (ARM)](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/overview), gives users a consistent, consolidated experience and interface by which they can manage their Azure resources in any Region or Subscription. This is different from other public cloud providers such as Amazon Web Services (AWS), where Accounts and Regions are completely independent of each other and cannot be queried simultaneously. The visibility of Azure Resource Manager enables tools such as the incredible [Azure Resource Graph](https://docs.microsoft.com/en-us/azure/governance/resource-graph/overview) to query resources and their properties across all 50+ Azure regions, and any Subscriptions where the user has access, within milliseconds.

To get a list of orphaned volumes using Azure Resource Graph, use the following [KQL query](https://docs.microsoft.com/en-us/azure/governance/resource-graph/concepts/query-language).

```kusto
resources
| where type =~ 'microsoft.compute/disks'
| where (coalesce(split(managedBy, '/')[(-1)], '-')) =~ '-'
```

### Add query results to your Azure Dashboard

If you want instant visibility into your environment's orphaned volumes, you can pin the results of an Azure Resource Graph query to your private or shared Azure Dashboard(s). The results will be updated based on the refresh frequency you set for the dashboard. To do this, perform the following steps:

![Save Azure Resource Graph query](images/azure-orphaned-volumes/orphaned-vols-query-save.png "Save Azure Resource Graph query to your library")

![Pin Azure Resource Graph query results to your Dashboard](images/azure-orphaned-volumes/orphaned-vols-query-pin.png "Pin Azure Resource Graph query results to your Dashboard")

![View the results in your Dashboard](images/azure-orphaned-volumes/orphaned-vols-dashboard.png "View the results in your Dashboard")

## Query Azure Resource Graph with PowerShell

To execute Azure Resource Graph queries, you can do so from the Azure Resource Graph Explorer within the Azure Portal, or you can use the [Az.ResourceGraph](https://www.powershellgallery.com/packages/Az.ResourceGraph/) PowerShell module to execute queries directly within a PowerShell script.

I've put together a simple PowerShell script, `Get-AzOrphanedVolumes.ps1`, which uses Azure Resource Graph to generate a list of orphaned volumes within your Azure environment. You can view the gist below to get a copy of the code:

{{% admonition type=note title="Note" open=false %}}
The Azure Resource Graph PowerShell module only supports returning a [maximum of 1000 records per query](https://docs.microsoft.com/en-us/powershell/module/az.resourcegraph/search-azgraph?view=azps-6.0.0#parameters), so if you find that your environment contains more than 1000 orphaned volumes, you may have to adjust the code to paginate your results.
{{% /admonition %}}

{{< gist RylandDeGregory f0cdd9c59f06a56dff8511fd57a8d801 >}}

### Export results to stdout

By default, the script will write the results of the Azure Resource Graph query to stdout, so you can capture the PowerShell object output in a variable, or let it write to the screen.

```powershell
./Get-AzOrphanedVolumes.ps1
```

![Orphaned Azure Disks in the PowerShell console](images/azure-orphaned-volumes/orphaned-vols-stdout.png "Orphaned Azure Disks in the PowerShell console")

By default, the script will search **all Azure Subscriptions within the current Azure AD Tenant** that the Azure AD Identity running the script has access to. Alternatively, you can specify the `-Subscriptions` parameter to limit the search to one or more Azure Subscriptions by name.

```powershell
./Get-AzOrphanedVolumes.ps1 -Subscriptions 'rylanddegregory', 'rylanddegregory dev'
```

### Export results to CSV

Just like the Azure Portal and Azure Resource Graph Explorer, you can use the script to export the results to a CSV file for easier consumption and more portable distribution. You can tell the script to export results to a file by invoking it with the `-GenerateReport` parameter.

```powershell
./Get-AzOrphanedVolumes.ps1 -GenerateReport
```

![Orphaned Azure Disks in a CSV report in Excel](images/azure-orphaned-volumes/orphaned-vols-excel.png "Orphaned Azure Disks report in Excel")

![Orphaned Azure Disks in a CSV report](images/azure-orphaned-volumes/orphaned-vols-report.png "Orphaned Azure Disks report in Finder")

By default, the report is exported to the root of your user profile (`C:\Users\<username>\` on Windows or `Users/<username/` on MacOS and Linux), but you can specify a custom filesystem path by including the `-OutFile` parameter.

```powershell
./Get-AzOrphanedVolumes.ps1 -GenerateReport -OutFile 'Users/ryland/Desktop/AzureOrphanedVolumes.csv'
```

## Automating report generation

The execution of this reporting script can be automated using one of the following Azure services:

- [Azure Automation PowerShell Runbook](https://docs.microsoft.com/en-us/system-center/sma/authoring-automation-runbooks?view=sc-sma-2019)
- [Azure PowerShell Function](https://docs.microsoft.com/en-us/azure/azure-functions/create-first-function-vs-code-powershell)