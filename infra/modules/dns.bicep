@sys.description('The name of the DNS zone to create the CNAME record in.')
param dnsZoneName string

@sys.description('The name of the CNAME record to create.')
param dnsCnameRecordName string

@sys.description('The value of the CNAME record to create.')
param dnsCnameRecordValue string

resource dnsZone 'Microsoft.Network/dnsZones@2018-05-01' existing = {
  name: dnsZoneName

  resource cnameRecord 'CNAME' = {
    name: dnsCnameRecordName
    properties: {
      TTL: 3600
      CNAMERecord: {
        cname: dnsCnameRecordValue
      }
    }
  }
}
