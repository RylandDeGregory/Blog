@sys.description('The name of the DNS CNAME record to create.')
param dnsZoneRecordName string

@sys.description('The Azure Resource ID of the DNS zone to create the CNAME record in.')
param dnsZoneResourceId string

@sys.description('The branch of the GitHub repository to use. Default: main')
param githubRepositoryBranch string = 'main'

@sys.description('The URL of the GitHub repository to use.')
param gitHubRepositoryUrl string

@sys.description('Azure location for the static web app. Default: resourceGroup().location')
param location string = resourceGroup().location

@sys.description('The name of the static web app to create.')
param staticWebAppName string

@sys.description('Dictionary of Azure tags to apply to the resources.')
param tags object = {}

var customDomainName = dnsZoneRecordName == '@' ? dnsZoneName : '${dnsZoneRecordName}.${dnsZoneName}'

var dnsZoneSubscriptionId = split(dnsZoneResourceId, '/')[2]
var dnsZoneResourceGroupName = split(dnsZoneResourceId, '/')[4]
var dnsZoneName = split(dnsZoneResourceId, '/')[8]

module dns 'modules/dns.bicep' = {
  name: 'DNS'
  params: {
    dnsZoneName: dnsZoneName
    dnsCnameRecordName: dnsZoneRecordName
    dnsCnameRecordValue: staticWebApp.properties.defaultHostname
  }
  scope: resourceGroup(dnsZoneSubscriptionId, dnsZoneResourceGroupName)
}

resource staticWebApp 'Microsoft.Web/staticSites@2025-03-01' = {
  name: staticWebAppName
  location: location
  sku: {
    name: 'Free'
    tier: 'Free'
  }
  properties: {
    branch: githubRepositoryBranch
    buildProperties: {
      appLocation: '/'
      apiLocation: ''
      outputLocation: 'public'
    }
    enterpriseGradeCdnStatus: 'Disabled'
    repositoryUrl: gitHubRepositoryUrl
    stagingEnvironmentPolicy: 'Enabled'
  }
  tags: tags

  resource customDomain 'customDomains' = {
    name: customDomainName
    properties: {
      validationMethod: 'cname-delegation'
    }
    dependsOn: [
      dns
    ]
  }
}
