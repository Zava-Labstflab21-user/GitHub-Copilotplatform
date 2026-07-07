param appInsightsName string
param location string
param workspaceResourceId string

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspaceResourceId
    Flow_Type: 'Bluefield'
    Request_Source: 'rest'
  }
}

output connectionString string = appInsights.properties.ConnectionString
