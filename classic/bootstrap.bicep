targetScope = 'resourceGroup'

param location string = resourceGroup().location

resource clusterVnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: 'cluster-vnet'
  location: location
  properties: { addressSpace: { addressPrefixes: ['10.0.0.0/22'] } }
}

resource masterSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  name: 'master'
  parent: clusterVnet
  properties: { addressPrefixes: ['10.0.0.0/23'] }
}

resource workerSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  name: 'worker'
  parent: clusterVnet
  properties: { addressPrefixes: ['10.0.2.0/23'] }
}
