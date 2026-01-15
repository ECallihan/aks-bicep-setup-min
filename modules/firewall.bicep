param location string
param namePrefix string

@description('VNet name that contains the AKS subnet and AzureFirewallSubnet')
param vnetName string

@description('Subnet name for AKS nodes (e.g., snet-aks-nodes)')
param aksSubnetName string

@description('Azure Firewall subnet name. Must be AzureFirewallSubnet.')
param fwSubnetName string = 'AzureFirewallSubnet'

// -------- Public IP for Firewall --------
resource fwPip 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: '${namePrefix}-fw-pip'
  location: location
  sku: { name: 'Standard' }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// -------- Azure Firewall --------
resource firewall 'Microsoft.Network/azureFirewalls@2023-11-01' = {
  name: '${namePrefix}-afw'
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, fwSubnetName)
          }
          publicIPAddress: { id: fwPip.id }
        }
      }
    ]
  }
}

// -------- Route Table (UDR) forcing 0.0.0.0/0 to Firewall --------
resource rt 'Microsoft.Network/routeTables@2023-11-01' = {
  name: '${namePrefix}-aks-udr'
  location: location
  properties: {
    disableBgpRoutePropagation: true
    routes: [
      {
        name: 'default-to-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewall.properties.ipConfigurations[0].properties.privateIPAddress
        }
      }
    ]
  }
}

// -------- Subnet update: attach route table to AKS node subnet --------
// We reference the existing subnet via existing resource, then "update" it by setting routeTable.
resource aksSubnetExisting 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' existing = {
  name: '${vnetName}/${aksSubnetName}'
}

resource aksSubnetWithUdr 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  name: aksSubnetExisting.name
  properties: union(aksSubnetExisting.properties, {
    routeTable: { id: rt.id }
  })
  dependsOn: [
    rt
    firewall
  ]
}

output firewallName string = firewall.name
output firewallPrivateIp string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
output routeTableId string = rt.id
output aksSubnetIdWithUdr string = aksSubnetWithUdr.id
