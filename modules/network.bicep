param location string
param namePrefix string

param vnetCidr string
param aksSubnetCidr string
param peSubnetCidr string
param fwSubnetCidr string

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: '${namePrefix}-vnet'
  location: location
  properties: {
    addressSpace: { addressPrefixes: [vnetCidr] }
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: { addressPrefix: fwSubnetCidr }
      }
      {
        name: 'snet-aks-nodes'
        properties: { addressPrefix: aksSubnetCidr }
      }
      {
        name: 'snet-private-endpoints'
        properties: {
          addressPrefix: peSubnetCidr
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

resource fwSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  name: '${vnet.name}/AzureFirewallSubnet'
}
resource aksSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  name: '${vnet.name}/snet-aks-nodes'
}
resource peSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  name: '${vnet.name}/snet-private-endpoints'
}

output vnetId string = vnet.id
output fwSubnetId string = fwSubnet.id
output aksSubnetId string = aksSubnet.id
output peSubnetId string = peSubnet.id

output vnetName string = vnet.name
output aksSubnetName string = 'snet-aks-nodes'
output fwSubnetName string = 'AzureFirewallSubnet'
output peSubnetName string = 'snet-private-endpoints'
