param principalId string
param roleDefinitionId string
param scopeResourceId string

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: last(split(scopeResourceId, '/'))
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(scopeResourceId, principalId, roleDefinitionId)
  scope: acr
  properties: {
    principalId: principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: roleDefinitionId
  }
}
