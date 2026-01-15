
targetScope = 'resourceGroup'

@description('Deployment region. Gov: usgovvirginia')
param location string = 'usgovvirginia'

@description('Name prefix for resources')
param namePrefix string = 'govaksdev'

@description('VNet CIDRs')
param vnetCidr string = '10.10.0.0/16'
param aksSubnetCidr string = '10.10.1.0/24'
param peSubnetCidr  string = '10.10.2.0/24'
param fwSubnetCidr  string = '10.10.254.0/24'

@description('Private DNS zone names (cloud-dependent)')
param aksPrivateDnsZoneName string
param acrPrivateDnsZoneName string

@description('Tiny node pool settings')
param nodeVmSize string = 'Standard_D2s_v5'
param nodeCount int = 1

@allowed([
  'Basic'
  'Standard'
  'Premium'
])
@description('ACR SKU. NOTE: Private Link requires Premium.')
param acrSku string = 'Premium'

@description('Disable ACR public access (recommended for gov). If acrSku != Premium, you cannot use Private Endpoint and may need public access temporarily.')
param acrPublicNetworkDisabled bool = true

// --- Network ---
module network 'modules/network.bicep' = {
  name: '${namePrefix}-network'
  params: {
    location: location
    namePrefix: namePrefix
    vnetCidr: vnetCidr
    aksSubnetCidr: aksSubnetCidr
    peSubnetCidr: peSubnetCidr
    fwSubnetCidr: fwSubnetCidr
  }
}

// --- Private DNS zones + links ---
module dns 'modules/dns.bicep' = {
  name: '${namePrefix}-dns'
  params: {
    namePrefix: namePrefix
    vnetId: network.outputs.vnetId
    aksPrivateDnsZoneName: aksPrivateDnsZoneName
    acrPrivateDnsZoneName: acrPrivateDnsZoneName
  }
  dependsOn: [
    network
  ]
}

// --- Firewall + UDR ---
module firewall 'modules/firewall.bicep' = {
  name: '${namePrefix}-firewall'
  params: {
    location: location
    namePrefix: namePrefix
    vnetName: network.outputs.vnetName
    aksSubnetName: network.outputs.aksSubnetName
    fwSubnetName: network.outputs.fwSubnetName
  }
  dependsOn: [
    network
  ]
}


// --- ACR (+ optional Private Endpoint) ---
module acr 'modules/acr.bicep' = {
  name: '${namePrefix}-acr'
  params: {
    location: location
    namePrefix: namePrefix
    acrSku: acrSku
    publicNetworkDisabled: acrPublicNetworkDisabled
    peSubnetId: network.outputs.peSubnetId
    acrPrivateDnsZoneId: dns.outputs.acrPrivateDnsZoneId
  }
  dependsOn: [
    network
    dns
  ]
}

// --- AKS ---
module aks 'modules/aks.bicep' = {
  name: '${namePrefix}-aks'
  params: {
    location: location
    namePrefix: namePrefix
    nodeVmSize: nodeVmSize
    nodeCount: nodeCount
    aksSubnetIdWithUdr: firewall.outputs.aksSubnetIdWithUdr
    aksPrivateDnsZoneId: dns.outputs.aksPrivateDnsZoneId
    acrId: acr.outputs.acrId
  }
  dependsOn: [
    firewall
    dns
    acr
  ]
}

output vnetId string = network.outputs.vnetId
output firewallName string = firewall.outputs.firewallName
output acrName string = acr.outputs.acrName
output aksName string = aks.outputs.aksName
