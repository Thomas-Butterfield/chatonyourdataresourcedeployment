param useManagedNetwork bool
param managedNetworkIsolationMode string
param createNetworkRules bool
param openAiServiceName string
param storageAccountName string
param searchServiceName string
param searchServiceSku string
param subnetId string
param aiHubName string
param aiHubSku string
param location string = resourceGroup().location
param tags object
param keyVaultName string
param appInsightsName string

// Define the Azure Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2024-04-01-preview' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    publicNetworkAccess: 'disabled'
    tenantId: subscription().tenantId
    accessPolicies: []
  }
}

// Define the Application Insights resource
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

// Define the Azure AI Hub Resource
resource aiHub 'Microsoft.MachineLearningServices/workspaces@2024-10-01-preview' = {
  name: aiHubName
  location: location
  sku: {
    name: aiHubSku
    tier: 'Basic'
  }
  kind: 'Hub'
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: aiHubName
    description: 'Azure AI Hub'
    managedNetwork: useManagedNetwork ? {
      isolationMode: managedNetworkIsolationMode
    } : null
    allowRoleAssignmentOnRG: true
    v1LegacyMode: false
    publicNetworkAccess: 'Disabled'
    enableDataIsolation: true
    systemDatastoresAuthMode: 'identity'
    enableServiceSideCMKEncryption: false
    storageAccount: storageAccount.id
    keyVault: keyVault.id
    applicationInsights: appInsights.id
    associatedWorkspaces: [
      openAiService.id
      searchService.id
    ]
    allowPublicAccessWhenBehindVnet: false
    containerRegistries: []
    containerRegistry: null
    discoveryUrl: null
    existingWorkspaces: []
    featureStoreSettings: {
      computeRuntime: {
        sparkRuntimeVersion: null
      }
      offlineStoreConnectionName: null
      onlineStoreConnectionName: null
    }
    hbiWorkspace: false
    hubResourceId: null
    imageBuildCompute: null
    ipAllowlist: []
    keyVaults: []
    networkAcls: {
      defaultAction: 'Deny'
      ipRules: []
    }
    primaryUserAssignedIdentity: null
    provisionNetworkNow: false
    serverlessComputeSettings: {
      serverlessComputeCustomSubnet: null
      serverlessComputeNoPublicIP: false
    }
    serviceManagedResourcesSettings: {
      cosmosDb: {
        collectionsThroughput: 0
      }
    }
    sharedPrivateLinkResources: []
    softDeleteRetentionInDays: 0
    storageAccounts: []
    workspaceHubConfig: {
      additionalWorkspaceStorageAccounts: []
      defaultWorkspaceResourceGroup: null
    }
  }
}

// Define the Azure OpenAI service with system-assigned managed identity
resource openAiService 'Microsoft.CognitiveServices/accounts@2021-04-30' = {
  name: openAiServiceName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    apiProperties: {}
    customSubDomainName: openAiServiceName
    networkAcls: createNetworkRules ? {
      defaultAction: 'Deny'
    } : null
    publicNetworkAccess: 'Disabled'
  }
}

// Define the storage account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    networkAcls: createNetworkRules ? {
      defaultAction: 'Deny'
    } : null
  }
}

resource storageAccountBlob 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      allowPermanentDelete: false
      enabled: true
      days: 7
    }
  }
}

// Define the Azure Cognitive Search service with system-assigned managed identity
resource searchService 'Microsoft.Search/searchServices@2024-03-01-preview' = {
  name: searchServiceName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: searchServiceSku
  }
  properties: {
    authOptions: {
      aadOrApiKey: {
        aadAuthFailureMode: 'http401WithBearerChallenge'
      }
    }
    networkRuleSet: createNetworkRules ? {
      bypass: 'AzureServices'
      ipRules: []
    } : null
    publicNetworkAccess: 'disabled'
  }
}

// Define the Private Endpoints for Each Service
resource openAiPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = if (createNetworkRules) {
  name: '${openAiServiceName}-pe'
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${openAiServiceName}-plsc'
        properties: {
          privateLinkServiceId: openAiService.id
          groupIds: [
            'account'
          ]
        }
      }
    ]
  }
}
resource storageBlobPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = if (createNetworkRules) {
  name: '${storageAccountName}-blob-pe'
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${storageAccountName}-blob-plsc'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource storageFilePrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = if (createNetworkRules) {
  name: '${storageAccountName}-file-pe'
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${storageAccountName}-file-plsc'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'file'
          ]
        }
      }
    ]
  }
}

resource searchPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = if (createNetworkRules) {
  name: '${searchServiceName}-pe'
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${searchServiceName}-plsc'
        properties: {
          privateLinkServiceId: searchService.id
          groupIds: [
            'searchService'
          ]
        }
      }
    ]
  }
}

resource keyVaultPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = if (createNetworkRules) {
  name: '${keyVaultName}-pe'
  location: location
  properties: {
    subnet: {
      id: subnetId
    } 
    privateLinkServiceConnections: [
      {
        name: '${keyVaultName}-plsc'
        properties: {
          privateLinkServiceId: keyVault.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
  }
}

// Role assignment IDs
var searchIndexDataReaderRoleId = resourceId('Microsoft.Authorization/roleDefinitions', '1407120a-92aa-4202-b7e9-c0e197c71c8f')
var searchServiceContributorRoleId = resourceId('Microsoft.Authorization/roleDefinitions', '7ca78c08-252a-4471-8644-bb5ff32d4ba0')
var storageBlobDataContributorRoleId = resourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
var cognitiveServicesOpenAiContributorRoleId = resourceId('Microsoft.Authorization/roleDefinitions', 'a001fd3d-188f-4b5d-821b-7da978bf7442')
var storageBlobDataReaderRoleId = resourceId('Microsoft.Authorization/roleDefinitions', '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1')

// Assign Search Index Data Reader to Azure OpenAI (on the AI Search resource)
resource searchIndexDataReaderRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(openAiService.id, 'search index data reader')
  scope: searchService
  properties: {
    roleDefinitionId: searchIndexDataReaderRoleId
    principalId: openAiService.identity.principalId
  }
}

// Assign Search Service Contributor to Azure OpenAI (on AI Search resource)
resource openAiSearchServiceContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(openAiService.id, 'search service contributor')
  scope: searchService
  properties: {
    roleDefinitionId: searchServiceContributorRoleId
    principalId: openAiService.identity.principalId
  }
}

// Assign Storage Blob Data Contributor to Azure OpenAI (on Storage Account)
resource openAiStorageBlobDataContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(openAiService.id, 'storage blob data contributor')
  scope: storageAccount
  properties: {
    roleDefinitionId: storageBlobDataContributorRoleId
    principalId: openAiService.identity.principalId
  }
}

// Assign Cognitive Services OpenAI Contributor to AI Search (on Azure OpenAI)
resource searchCognitiveServicesOpenAiContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(searchService.id, 'cognitive services openai contributor')
  scope: openAiService
  properties: {
    roleDefinitionId: cognitiveServicesOpenAiContributorRoleId
    principalId: searchService.identity.principalId
  }
}

// Assign Storage Blob Data Reader to Azure AI Search on the storage account.
resource searchStorageBlobDataReaderRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(searchService.id, 'storage blob data reader')
  scope: storageAccount
  properties: {
    roleDefinitionId: storageBlobDataReaderRoleId
    principalId: searchService.identity.principalId
  }
}

// Outputs
output openAiServiceId string = openAiService.id
output storageAccountId string = storageAccount.id
output searchServiceId string = searchService.id
output searchIndexDataReaderRoleAssignmentId string = searchIndexDataReaderRoleAssignment.id
output openAiSearchServiceContributorRoleAssignmentId string = openAiSearchServiceContributorRoleAssignment.id
output openAiStorageBlobDataContributorRoleAssignmentId string = openAiStorageBlobDataContributorRoleAssignment.id
output searchCognitiveServicesOpenAiContributorRoleAssignmentId string = searchCognitiveServicesOpenAiContributorRoleAssignment.id
output searchStorageBlobDataReaderRoleAssignmentId string = searchStorageBlobDataReaderRoleAssignment.id
