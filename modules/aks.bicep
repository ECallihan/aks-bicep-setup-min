param location string
param namePrefix string

param nodeVmSize string
param nodeCount int

@description('AKS subnet ID that already has the UDR applied')
param aksSubnetIdWithUdr string

@description('Private DNS Zone ID for AKS private API')
param aksPrivateDnsZoneId string

@description('ACR resource ID for AcrPull role assignment')
param acrId string

resource aks 'Microsoft.ContainerService/managedClusters@2024-05-01' = {
  name: '${namePrefix}-aks'
  location: location
  identity: { type: 'SystemAssigned' }
  properties: {
    dnsPrefix: '${namePrefix}-aks'

    apiServerAccessProfile: {
      enablePrivateCluster: true
      privateDNSZone: aksPrivateDnsZoneId
    }

    agentPoolProfiles: [
      {
        name: 'systemnp'
        mode: 'System'
        count: nodeCount
        vmSize: nodeVmSize
        osType: 'Linux'
        type: 'VirtualMachineScaleSets'
        vnetSubnetID: aksSubnetIdWithUdr
        enableNodePublicIP: false
      }
    ]

    networkProfile: {
      networkPlugin: 'azure'
      loadBalancerSku: 'standard'
      outboundType: 'userDefinedRouting'
    }
  }
}

var kubeletObjectId = aks.properties.identityProfile.kubeletidentity.objectId

resource acrPullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acrId, kubeletObjectId, 'acrpull')
  scope: acrId
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // AcrPull
    principalId: kubeletObjectId
    principalType: 'ServicePrincipal'
  }
}

output aksName string = aks.name
output aksId string = aks.id
