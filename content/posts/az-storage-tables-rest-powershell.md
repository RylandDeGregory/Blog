---
title: "Using Azure Storage Tables REST API with PowerShell"
date: 2023-09-11T20:34:50-04:00
draft: true
author: "Ryland DeGregory"
authorlink: "/about/"
categories:
- Azure
- PowerShell
---

If you've interacted with Azure Storage using PowerShell, you've probably come across the [AzTable](https://www.powershellgallery.com/packages/AzTable/2.1.0) community module. But, given this module's developer abandonment, to reduce reliance on third-party packages, and to enable modern authentication, you can interact directly with Azure Tables using its [REST API](https://learn.microsoft.com/en-us/rest/api/storageservices/table-service-rest-api).

<!--more-->

## Background

### What is Azure Tables?

[Azure Tables](https://learn.microsoft.com/en-us/azure/storage/tables/table-storage-overview) is one of the easiest, cheapest ways to store schemaless [key-value](https://en.wikipedia.org/wiki/Key%E2%80%93value_database) data in the cloud. It allows developers, platform engineers, and operations administrators to easily integrate durable, flexible data storage into their applications without needing to provision or manage a full database. Azure Tables is also popular for use with serverless, event-driven applications due to its high throughput and low latency.

### Accessing Azure Tables

Like many Azure resources, Azure Tables supports access management configuration at both the [Control Plane and Data Plane](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/control-plane-and-data-plane). Many developers will choose to use the [Azure SDK](https://devblogs.microsoft.com/azure-sdk/announcing-the-new-azure-data-tables-libraries/) to access the Data Plane, as it provides native abstractions for their language of choice and includes functionality such as authentication context management, retry logic, and rate limiting.

However, PowerShell is not a [supported language](https://azure.github.io/azure-sdk/) of the Azure SDK. Therefore, to perform Azure Tables Data Plane operations using PowerShell, developers and engineers must utilize alternative methods: community-provided PowerShell modules, manually manipulating the .NET SDK, or the REST API.

#### AzTable module

The AzTable PowerShell module, originally authored by a Microsoft employee named Paulo Marques, has for years been the defacto method of [performing
Azure Table Storage operations with PowerShell](https://learn.microsoft.com/en-us/azure/storage/tables/table-storage-how-to-use-powershell). However, development of this module has been abandoned by both Paulo and Microsoft, with the last release over 2.5 years ago (April 9, 2021). Additionally, the module lacks modern functionality such as Microsoft Entra ID (f/k/a Azure Active Directory) authentication.

## Setup

Using the Azure Tables REST API with PowerShell is incredibly simple and provides the most flexibility when interacting with the Data Plane.

### Install

To start using the Azure Tables REST API with PowerShell, install the [Azure PowerShell](https://learn.microsoft.com/en-us/powershell/azure/install-azure-powershell) module and download the sample code from my [Github](https://gist.github.com/RylandDeGregory/c65563d0b090fc32115be7025d1ce722). Sample code for common Entity operations is also provided in the [Perform Operations](#perform-operations) section of this post.

### Authentication

In your implementation, you can choose to support either [Shared Key Authorization](https://learn.microsoft.com/en-us/rest/api/storageservices/authorize-with-shared-key), [Entra ID Authorization](https://learn.microsoft.com/en-us/rest/api/storageservices/authorize-with-azure-active-directory), or both.

#### Shared (Master) Key

Shared Key Authorization is the standard way of authenticating Azure Tables REST API requests. The [Storage Account Key](https://learn.microsoft.com/en-us/azure/storage/common/storage-account-keys-manage?tabs=azure-portal) provides full, administrative access to all Storage Account Data Plane operations including creating, updating, and removing Azure Tables Entities (records).

Using Shared Key Authorization with the REST API does not require the assignment of any [Data Plane Azure RBAC Roles](https://learn.microsoft.com/en-us/azure/storage/tables/authorize-access-azure-active-directory), and only requires that the calling principal can list the Storage Account Keys. Built-in Azure RBAC Roles that include this permission are: [Contributor](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#contributor) and [Reader and Data Access](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#reader-and-data-access).

See the `AccessKey` #region of the [Gist](https://gist.github.com/RylandDeGregory/c65563d0b090fc32115be7025d1ce722) for code samples.

#### Entra ID (OAuth)

Microsoft Entra ID Authorization is the modern, preferred way of authenticating Azure Tables REST API requests. Using the built-in authentication and authorization capabilities of Microsoft Entra ID (such as Identity Protection, Identity Governance, PIM, and Conditional Access) enables greater security, control, and traceability for Azure Tables Data Plane operations when compared to Shared Key Authorization.

Access can be scoped to specific Data Plane operations by assigning either the [Storage Table Data Reader](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage-table-data-reader) or the [Storage Table Data Contributor](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage-table-data-contributor) built-in Azure RBAC Role.

See the `OAuth` #region of the [Gist](https://gist.github.com/RylandDeGregory/c65563d0b090fc32115be7025d1ce722) for code samples.

## Use

The Azure Tables REST API can be accessed either interactively as a user in a PowerShell session or unattended using a PowerShell automation service such as [Azure Automation](https://learn.microsoft.com/en-us/azure/automation/overview) or [Azure Functions](https://learn.microsoft.com/en-us/azure/azure-functions/functions-overview?pivots=programming-language-powershell).

Before continuing, please ensure that your user or [Workload Identity](https://learn.microsoft.com/en-us/entra/workload-id/workload-identities-overview) has been granted the required Azure RBAC Role(s) to access your Storage Account and Table(s).

{{% admonition type=note title="Note" open=false %}}
All following setup guidance and code samples demonstrate the use of [Entra ID](#entra-id-oauth), rather than [Shared Key](#shared-master-key) Authorization.
{{% /admonition %}}

### Interactive

To start using the Azure Tables REST API interactively, open a PowerShell session and run `Connect-AzAccount`. This will connect your Microsoft Entra ID identity to your PowerShell session.

My identity has been granted the *Storage Table Data Contributor* Role at the Storage Account scope. This assignment allows my identity to both read and write **all** Entities within **all** Tables in the Storage Account.

![Azure Table Storage user RBAC Role](images/az-storage-tables-rest-powershell/storage-rbac-data-user-role.png)

### Automated

The following example uses an Azure Automation Account.

To start using the Azure Tables REST API in an unattended configuration, [create an Automation Account](https://learn.microsoft.com/en-us/azure/automation/quickstarts/create-azure-automation-account-portal) and [enabled the Managed Identity](https://learn.microsoft.com/en-us/azure/automation/quickstarts/enable-managed-identity).

![Azure Automation Account Managed Identity](images/az-storage-tables-rest-powershell/aa-managed-identity.png)

Then, assign the Managed Identity the *Storage Table Data Contributor* Role at the Storage Account scope. This assignment allows the Automation Account to both read and write **all** Entities within **all** Tables in the Storage Account.

![Azure Table Storage MI RBAC Role](images/az-storage-tables-rest-powershell/storage-rbac-data-mi-role.png)

Finally, [create a PowerShell Runbook](https://learn.microsoft.com/en-us/azure/automation/manage-runbooks#create-a-runbook) within the Automation Account. Add the following code to the top of the Runbook:

```PowerShell
# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process

# Connect to Azure with system-assigned managed identity
Connect-AzAccount -Identity
```

Then, paste the required sample Azure Tables REST API code into the Runbook (see below for samples).

### Perform operations

Below is sample PowerShell code that can be used to perform [CRUD operations](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete) on Azure Tables Entities using the REST API.

- [Create](#create-entity)
- [Read](#get-entity) / [Search](#query-entities)
- [Update](#update-entity)
- [Delete](#remove-entity)

All samples assume you have already connected Azure PowerShell to your Azure environment using either the [Interactive](#interactive) or [Automated](#automated) Microsoft Entra ID authentication flow.

All samples will reference a Storage Account named `sttabledemouse2dev` and an Azure Table named `RestApi`.

#### Create Entity

All Azure Tables Entities **require** the following properties to be defined at creation time:

- [PartitionKey](https://learn.microsoft.com/en-us/rest/api/storageservices/understanding-the-table-service-data-model#partitionkey-property)
    - Used to group Entities.
- [RowKey](https://learn.microsoft.com/en-us/rest/api/storageservices/understanding-the-table-service-data-model#rowkey-property)
    - Used to uniquely identify an Entity within a Table.

All other properties are optional and are based on the schema of the Entity being created. Azure Tables is a schemaless data store, so each Entity within the Table can potentially have different properties defined. Below is a PowerShell code sample that creates an Azure Tables Entity with two user-defined properties: `Name` and `Status`.

```PowerShell
# Storage Account and Table details
$StorageAccount = 'sttabledemouse2dev'
$Table          = 'RestApi'

# Entity details
$PartitionKey   = 'partition1'
$RowKey         = (New-Guid).Guid

# Azure Table Storage request headers
$Date = [DateTime]::UtcNow.ToString('R')
$AzTableHeaders = @{
    'Accept'        = 'application/json;odata=nometadata'
    'x-ms-version'  = '2020-08-04'
    'x-ms-date'     = $Date
}

# Azure Table Storage Entra ID Authorization
$AzStorageToken = Get-AzAccessToken -ResourceTypeName Storage
$AzTableHeaders += @{'Authorization' = "$($AzStorageToken.Type) $($AzStorageToken.Token)"}

# Define Entity
$InsertBody = @{
    PartitionKey = $PartitionKey
    RowKey       = $RowKey.ToString()
    Name         = 'myEntity'
    Status       = 'Active'
} | ConvertTo-Json

# Create Entity using REST API
Invoke-RestMethod -Method Post -Uri "https://$StorageAccount.table.core.windows.net/$Table" -Body $InsertBody -Headers $AzTableHeaders -ContentType 'application/json'
```

The REST API will respond with a [PSCustomObject](https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-pscustomobject?view=powershell-7.3) representation of the new Entity.

![PowerShell Create Entity response](images/az-storage-tables-rest-powershell/ps-response-create.png)

You can view the Entity within the Azure Portal or the [Azure Storage Explorer](https://learn.microsoft.com/en-us/azure/vs-azure-tools-storage-manage-with-storage-explorer).

![Azure Table Create Entity result](images/az-storage-tables-rest-powershell/table-entity-create.png)

#### Get Entity

Retrieve an Azure Tables Entity by providing its `PartitionKey` and `RowKey`.

```PowerShell
# Storage Account and Table details
$StorageAccount = 'sttabledemouse2dev'
$Table          = 'RestApi'

# Entity details
$PartitionKey   = 'partition1'
$RowKey         = 'b748030d-f434-47d9-b6a2-2f0f05df59c1'

# Azure Table Storage request headers
$Date = [DateTime]::UtcNow.ToString('R')
$AzTableHeaders = @{
    'Accept'        = 'application/json;odata=nometadata'
    'x-ms-version'  = '2020-08-04'
    'x-ms-date'     = $Date
}

# Azure Table Storage Entra ID Authorization
$AzStorageToken = Get-AzAccessToken -ResourceTypeName Storage
$AzTableHeaders += @{'Authorization' = "$($AzStorageToken.Type) $($AzStorageToken.Token)"}

# Get Entity using REST API
Invoke-RestMethod -Method Get -Uri "https://$StorageAccount.table.core.windows.net/$Table(PartitionKey='$PartitionKey',RowKey='$RowKey')" -Headers $AzTableHeaders
```

The REST API will respond with a [PSCustomObject](https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-pscustomobject) representation of the Entity.

![PowerShell Get Entity response](images/az-storage-tables-rest-powershell/ps-response-get.png)

#### Query Entities

The Azure Tables REST API supports the [OData specification](https://learn.microsoft.com/en-us/rest/api/storageservices/querying-tables-and-entities) for querying Entities.

##### Get all Entities with a specific PartitionKey

Retrieve all Entities within an Azure Storage Table that share a `PartitionKey`.

```PowerShell
# Storage Account and Table details
$StorageAccount = 'sttabledemouse2dev'
$Table          = 'RestApi'

# Entity details
$PartitionKey   = 'partition1'

# Azure Table Storage request headers
$Date = [DateTime]::UtcNow.ToString('R')
$AzTableHeaders = @{
    'Accept'        = 'application/json;odata=nometadata'
    'x-ms-version'  = '2020-08-04'
    'x-ms-date'     = $Date
}

# Azure Table Storage Entra ID Authorization
$AzStorageToken = Get-AzAccessToken -ResourceTypeName Storage
$AzTableHeaders += @{'Authorization' = "$($AzStorageToken.Type) $($AzStorageToken.Token)"}

# Get all Entities by using a PartitionKey filter with the REST API
Invoke-RestMethod -Method Get -Uri "https://$StorageAccount.table.core.windows.net/$Table()?`$filter=PartitionKey eq '$PartitionKey'" -Headers $AzTableHeaders | Select-Object -ExpandProperty value

```

The REST API will respond with an array of [PSCustomObjects](https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-pscustomobject) representing the Entities.

![PowerShell Query Entities response](images/az-storage-tables-rest-powershell/ps-response-query.png)

##### Get all Entities in a Table

Pagination is required to retrieve all Entities within an Azure Storage Table. The following sample shows one potential pagination implementation.

```PowerShell
# Storage Account and Table details
$StorageAccount = 'sttabledemouse2dev'
$Table          = 'RestApi'

# Azure Table Storage request headers
$Date = [DateTime]::UtcNow.ToString('R')
$AzTableHeaders = @{
    'Accept'        = 'application/json;odata=nometadata'
    'x-ms-version'  = '2020-08-04'
    'x-ms-date'     = $Date
}

# Azure Table Storage Entra ID Authorization
$AzStorageToken = Get-AzAccessToken -ResourceTypeName Storage
$AzTableHeaders += @{'Authorization' = "$($AzStorageToken.Type) $($AzStorageToken.Token)"}

# Get all Entities in Table using REST API
# Invoke-WebRequest is used rather than Invoke-RestMethod to access response headers
$TableRecords = @()
$TableResponse = Invoke-WebRequest -Method Get -Uri "https://$StorageAccount.table.core.windows.net/$Table()" -Headers $AzTableHeaders
$TableRecords += $TableResponse | Select-Object -ExpandProperty Content | ConvertFrom-Json | Select-Object -ExpandProperty value
$TableRecords += while ($TableResponse.Headers.'x-ms-continuation-NextPartitionKey') {
    $TableResponse = Invoke-WebRequest -Method Get -Uri "https://$StorageAccount.table.core.windows.net/$Table()?NextPartitionKey=$($TableResponse.Headers.'x-ms-continuation-NextPartitionKey')&NextRowKey=$($TableResponse.Headers.'x-ms-continuation-NextRowKey')" -Headers $AzTableHeaders
    $TableResponse | Select-Object -ExpandProperty Content | ConvertFrom-Json | Select-Object -ExpandProperty value
}
```

The REST API will respond with an array of [PSCustomObjects](https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-pscustomobject) representing the Entities.

![PowerShell all Entities response](images/az-storage-tables-rest-powershell/ps-response-all.png)

#### Update Entity

Update an existing Entity by providing the `PartitionKey` and `RowKey` properties, along with an object representing the modified user-defined properties.

```PowerShell
# Storage Account and Table details
$StorageAccount = 'sttabledemouse2dev'
$Table          = 'RestApi'

# Entity details
$PartitionKey   = 'partition1'
$RowKey         = 'b748030d-f434-47d9-b6a2-2f0f05df59c1'

# Azure Table Storage request headers
$Date = [DateTime]::UtcNow.ToString('R')
$AzTableHeaders = @{
    'Accept'        = 'application/json;odata=nometadata'
    'x-ms-version'  = '2020-08-04'
    'x-ms-date'     = $Date
}

# Azure Table Storage Entra ID Authorization
$AzStorageToken = Get-AzAccessToken -ResourceTypeName Storage
$AzTableHeaders += @{'Authorization' = "$($AzStorageToken.Type) $($AzStorageToken.Token)"}

# Define updated object
$UpdateBody = @{
    Name = 'NewName'
} | ConvertTo-Json

# Update Entity using REST API
Invoke-RestMethod -Method Put -Uri "https://$StorageAccount.table.core.windows.net/$Table(PartitionKey='$PartitionKey',RowKey='$RowKey')" -Body $UpdateBody -Headers $AzTableHeaders -ContentType 'application/json'
```

The REST API will not provide a response message for Entity update operations.

You can view the updated Entity within the Azure Portal or the [Azure Storage Explorer](https://learn.microsoft.com/en-us/azure/vs-azure-tools-storage-manage-with-storage-explorer).

![Azure Table Update Entity result](images/az-storage-tables-rest-powershell/table-entity-update.png)

#### Remove Entity

Remove an existing Entity by providing the `PartitionKey` and `RowKey`.

```PowerShell
# Storage Account and Table details
$StorageAccount = 'sttabledemouse2dev'
$Table          = 'RestApi'

# Entity details
$PartitionKey   = 'partition1'
$RowKey         = 'b748030d-f434-47d9-b6a2-2f0f05df59c1'

# Azure Table Storage request headers
$Date = [DateTime]::UtcNow.ToString('R')
$AzTableHeaders = @{
    'Accept'        = 'application/json;odata=nometadata'
    'x-ms-version'  = '2020-08-04'
    'x-ms-date'     = $Date
}

# Azure Table Storage Entra ID Authorization
$AzStorageToken = Get-AzAccessToken -ResourceTypeName Storage
$AzTableHeaders += @{'Authorization' = "$($AzStorageToken.Type) $($AzStorageToken.Token)"}

# Remove Entity using REST API
$DeleteHeaders = $AzTableHeaders += @{'If-Match' = '*'}
Invoke-RestMethod -Method Delete -Uri "https://$StorageAccount.table.core.windows.net/$Table(PartitionKey='$PartitionKey',RowKey='$RowKey')" -Headers $DeleteHeaders
```

The REST API will not provide a response message for Entity delete operations.

You can view the results of the Entity removal within the Azure Portal or the [Azure Storage Explorer](https://learn.microsoft.com/en-us/azure/vs-azure-tools-storage-manage-with-storage-explorer).

![Azure Table Remove Entity result](images/az-storage-tables-rest-powershell/table-entity-remove.png)
