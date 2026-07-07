param name string
param location string
param sku string = 'B1'

resource plan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: name
  location: location
  sku: {
    name: sku
    tier: sku == 'B1' ? 'Basic' : (sku == 'S1' ? 'Standard' : 'PremiumV3')
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

output id string = plan.id
