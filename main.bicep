param openAiServiceName string // Define the Azure OpenAI service name  
param storageAccountName string // Define the storage account name  
param searchServiceName string // Define the Azure Cognitive Search service name  
 
  
// Define the Azure OpenAI service with system-assigned managed identity  
resource openAiService 'Microsoft.CognitiveServices/accounts@2021-04-30' = {  
  name: openAiServiceName  
  location: resourceGroup().location // Set location to the resource group's location  
  identity: {  
    type: 'SystemAssigned'  
  }  
  kind: 'OpenAI'  
  sku: {  
    name: 'S0' // Set SKU directly to S0  
  }  
  properties: {  
    apiProperties: {  
      // Additional properties can be added here if needed  
    }  
    customSubDomainName: openAiServiceName
  }  
}  
  
// Define the storage account  
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {  
  name: storageAccountName  
  location: resourceGroup().location // Same location as OpenAI service  
  sku: {  
    name: 'Standard_LRS' // Locally Redundant Storage (LRS)  
  }  
  kind: 'StorageV2' // Recommended kind for new storage accounts  
  properties: {  
    // Additional properties can be set here if needed
    
  
  
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
  location: resourceGroup().location // Same location as OpenAI service  
  identity: {  
    type: 'SystemAssigned' // Managed Identity  
  }  
  sku: {  
    name: 'standard' // Standard SKU  
  }  
  properties: {  
    authOptions: {
        aadOrApiKey: {
          aadAuthFailureMode: 'http401WithBearerChallenge'
        }
      }
    // Additional properties can be set here if needed  
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
  scope:storageAccount
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
