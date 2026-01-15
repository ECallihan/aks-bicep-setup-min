param location string
param namePrefix string

@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param acrSku string

@description('If true, sets publicNetworkAccess Disabled. If acrSku != Premium, you may need to set this false temporarily.')
param publicNetworkDisabled bool

@description('Subnet for Private Endpoints (only used when acrSku == Premium)')
param peSubnetId string

@description('Private DNS zone id for ACR (only used when acrSku == Premium)')
param acrPrivateDnsZoneId string

var acrName = toLower('${namePrefix}acr${uniqueString(resourceGroup().id)}')
var usePrivateLink = (acrSku == 'Premium')

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  sku: { name: acrSku }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: publicNetworkDisabled ? 'Disabled' : 'Enabled'
  }
}

resource acrPe 'Microsoft.Network/privateEndpoints@2023-11-01' = if (usePrivateLink) {
  name: '${namePrefix}-acr-pe'
  location: location
  properties: {
    subnet: { id: peSubnetId }
    privateLinkServiceConnections: [
      {
        name: 'acr-connection'
        properties: {
          privateLinkServiceId: acr.id
          groupIds: ['registry']
        }
      }
    ]
  }
}

resource acrZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = if (usePrivateLink) {
  name: '${acrPe.name}/acr-zonegroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'acrDns'
        properties: { privateDnsZoneId: acrPrivateDnsZoneId }
      }
    ]
  }
  dependsOn: [
    acrPe
  ]
}

output acrId string = acr.id
output acrName string = acr.name
output usePrivateLink bool = usePrivateLink
