param namePrefix string
param vnetId string

param aksPrivateDnsZoneName string
param acrPrivateDnsZoneName string

resource aksPrivateDns 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: aksPrivateDnsZoneName
  location: 'global'
}

resource aksDnsLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${aksPrivateDns.name}/${namePrefix}-aksdnslink'
  location: 'global'
  properties: {
    virtualNetwork: { id: vnetId }
    registrationEnabled: false
  }
}

resource acrPrivateDns 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: acrPrivateDnsZoneName
  location: 'global'
}

resource acrDnsLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${acrPrivateDns.name}/${namePrefix}-acrdnslink'
  location: 'global'
  properties: {
    virtualNetwork: { id: vnetId }
    registrationEnabled: false
  }
}

output aksPrivateDnsZoneId string = aksPrivateDns.id
output acrPrivateDnsZoneId string = acrPrivateDns.id
