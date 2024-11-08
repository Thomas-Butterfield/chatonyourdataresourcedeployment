param userPrincipalName string // The user principal name (UPN) of the user to assign roles to  
param storageAccountName string // The name of the existing storage account  
param openAiServiceName string // The name of the existing OpenAI service  
param searchServiceName string // The name of the existing Azure Cognitive Search service
  
// Role definition IDs  
var blobDataReaderRoleDefinitionId = '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1' // Blob Data Reader role ID  
var cognitiveServicesOpenAiContributorRoleId = 'a001fd3d-188f-4b5d-821b-7da978bf7442' // Cognitive Services OpenAI Contributor role ID  
var cognitiveServicesUserRoleId = 'a97b65f3-24c7-4388-baec-2e87135dc908' // Cognitive Services User role for OpenAI ID  
var blobDataContributorRoleId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
var searchIndexDataContributorRoleId = '8ebe5a00-799e-43f5-93ac-243d3dce84a7'
var searchIndexDataReaderRoleId =  '1407120a-92aa-4202-b7e9-c0e197c71c8f'
var searchServiceContributorRoleId =  '7ca78c08-252a-4471-8644-bb5ff32d4ba0'


  
// Reference to the existing storage account  
resource existingStorageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {  
  name: storageAccountName  
  scope: resourceGroup() // Specify the resource group if needed  
}  

// Reference to the existing search service
resource existingSearchAccount 'Microsoft.Search/searchServices@2024-03-01-preview' existing = {  
  name: searchServiceName  
  scope: resourceGroup() // Specify the resource group if needed  
}  
  
// Reference to the existing OpenAI service  
resource existingOpenAI 'Microsoft.CognitiveServices/accounts@2021-04-30' existing = {  
  name: openAiServiceName  
  scope: resourceGroup() // Specify the resource group if needed  
}  

// Role assignment for search service contributor
var SearchServiceContributorAssignmentName = guid(userPrincipalName, searchServiceContributorRoleId, resourceGroup().id)  
resource SearchServiceContributorAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {  
  name: SearchServiceContributorAssignmentName  
  scope: existingSearchAccount  
  properties: {  
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', searchServiceContributorRoleId)  
    principalId: userPrincipalName // This may need to be changed to the user's object ID  
  }  
} 

// Role assignment for search index data contributor
var SearchIndexDataContributorAssignmentName = guid(userPrincipalName, searchIndexDataContributorRoleId, resourceGroup().id)  
resource SearchIndexDataContributorAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {  
  name: SearchIndexDataContributorAssignmentName  
  scope: existingSearchAccount  
  properties: {  
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', searchIndexDataContributorRoleId)  
    principalId: userPrincipalName // This may need to be changed to the user's object ID  
  }  
} 

// Role assignment for search index data reader
var SearchIndexDataReaderAssignmentName = guid(userPrincipalName, searchIndexDataReaderRoleId, resourceGroup().id)  
resource SearchIndexDataReaderAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {  
  name: SearchIndexDataReaderAssignmentName  
  scope: existingSearchAccount  
  properties: {  
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', searchIndexDataReaderRoleId)  
    principalId: userPrincipalName // This may need to be changed to the user's object ID  
  }  
} 


// Role assignment for Blob Data Reader  
var blobDataContributorAssignmentName = guid(userPrincipalName, blobDataContributorRoleId, resourceGroup().id)  
resource roleBlobDataContributorAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {  
  name: blobDataContributorAssignmentName  
  scope: existingStorageAccount  
  properties: {  
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', blobDataContributorRoleId)  
    principalId: userPrincipalName // This may need to be changed to the user's object ID  
  }  
} 

// Role assignment for Blob Data Reader  
var blobDataReaderAssignmentName = guid(userPrincipalName, blobDataReaderRoleDefinitionId, resourceGroup().id)  
resource roleBlobDataReaderAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {  
  name: blobDataReaderAssignmentName  
  scope: existingStorageAccount  
  properties: {  
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', blobDataReaderRoleDefinitionId)  
    principalId: userPrincipalName // This may need to be changed to the user's object ID  
  }  
}  
  
// Role assignment for Cognitive Services OpenAI Contributor  
var cognitiveServicesContributorName = guid(userPrincipalName, cognitiveServicesOpenAiContributorRoleId, resourceGroup().id)  
resource roleCognitiveServicesContributorAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {  
  name: cognitiveServicesContributorName  
  scope: existingOpenAI  
  properties: {  
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', cognitiveServicesOpenAiContributorRoleId)  
    principalId: userPrincipalName // This may need to be changed to the user's object ID  
  }  
}  
  
// Role assignment for Cognitive Services User  
var cognitiveServicesUserName = guid(userPrincipalName, cognitiveServicesUserRoleId, resourceGroup().id)  
resource roleCognitiveServicesUserAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {  
  name: cognitiveServicesUserName  
  scope: existingOpenAI  
  properties: {  
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', cognitiveServicesUserRoleId)  
    principalId: userPrincipalName // This may need to be changed to the user's object ID  
  }  
}  
  
// Outputs  
output blobDataReaderAssignmentName string = roleBlobDataReaderAssignment.name  
output resourceGroupName string = resourceGroup().name  
output blobDataReaderAssignmentId string = roleBlobDataReaderAssignment.id  
output cognitiveServicesContributorAssignmentId string = roleCognitiveServicesContributorAssignment.id  
output cognitiveServicesUserAssignmentId string = roleCognitiveServicesUserAssignment.id  
