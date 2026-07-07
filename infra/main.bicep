targetScope = 'resourceGroup'

@description('Name of the environment (for example dev, test, prod).')
param environmentName string = 'dev'

@description('Azure region for all resources. East US 2 is used here because App Service plan capacity has been failing in westus3 for this subscription.')
param location string = 'eastus2'

@description('Short prefix used to name resources.')
param prefix string = 'zava'

@description('SKU for Azure Container Registry.')
@allowed([
  'Basic'
  'Standard'
])
param acrSku string = 'Basic'

@description('SKU for the Azure AI Services account.')
@allowed([
  'S0'
])
param aiServicesSku string = 'S0'

@description('Retention period for Log Analytics in days.')
param logAnalyticsRetentionInDays int = 30

var uniqueSuffix = toLower(take(uniqueString(resourceGroup().id), 6))
var resourceToken = '${prefix}${environmentName}${uniqueSuffix}'
var webAppName = 'app-${resourceToken}'
var acrName = take(replace('acr${resourceToken}', '-', ''), 50)
var logAnalyticsName = 'log-${resourceToken}'
var appInsightsName = 'appi-${resourceToken}'
var aiServicesName = 'ai-${resourceToken}'
var containerImageName = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

module logAnalytics 'modules/logAnalytics.bicep' = {
  name: 'logAnalytics'
  params: {
    name: logAnalyticsName
    location: location
    retentionInDays: logAnalyticsRetentionInDays
  }
}

module appInsights 'modules/applicationInsights.bicep' = {
  name: 'appInsights'
  params: {
    appInsightsName: appInsightsName
    location: location
    workspaceResourceId: logAnalytics.outputs.id
  }
}

module acr 'modules/acr.bicep' = {
  name: 'acr'
  params: {
    name: acrName
    location: location
    sku: acrSku
  }
}

module containerAppsEnvironment 'modules/containerAppsEnvironment.bicep' = {
  name: 'containerAppsEnvironment'
  params: {
    name: 'cae-${resourceToken}'
    location: location
    logAnalyticsWorkspaceId: logAnalytics.outputs.id
  }
}

module containerApp 'modules/containerApp.bicep' = {
  name: 'containerApp'
  params: {
    name: webAppName
    location: location
    containerAppsEnvironmentId: containerAppsEnvironment.outputs.id
    containerImageName: containerImageName
    acrLoginServer: acr.outputs.loginServer
    appInsightsConnectionString: appInsights.outputs.connectionString
  }
}

module aiServices 'modules/aiServices.bicep' = {
  name: 'aiServices'
  params: {
    accountName: aiServicesName
    location: location
    skuName: aiServicesSku
  }
}

module roleAssignment 'modules/roleAssignment.bicep' = {
  name: 'roleAssignment'
  params: {
    principalId: containerApp.outputs.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
    scopeResourceId: acr.outputs.id
  }
}

output appServiceUrl string = containerApp.outputs.fqdn
output acrLoginServer string = acr.outputs.loginServer
output appInsightsConnectionString string = appInsights.outputs.connectionString
output aiServicesEndpoint string = aiServices.outputs.endpoint
