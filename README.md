# Chat on your data resource deployment

### Before you run the script:
- Install Azure CLI 
- Create a resource group in the region you would like to have your resources deployed to.

### Notes on the scripts:
- main.bicep is a script that can be run using the Azure CLI to deploy resources to enable 'chat on your data'
- There are 2 script (running them shown below)
    - **main.bicep** will deploy AzureOpenAI, AISearch, and a StorageAccount and set their permissions for managed identity connections
    - **permssions.bicep** will provide you with the permissions required to leverage the resource.

These will work with managed identity & key connections to resources.

### Azure CLI Commands to create resources
```
az deployment group create --resource-group <put-your-resource-group-here>  --template-file main.bicep  --parameters openAiServiceName=<openaiservicename> storageAccountName=<storageaccountname> searchServiceName=<searchservicename>
```

```
az deployment group create --resource-group <put-your-resource-group-here> --template-file permissions.bicep --parameters userPrincipalName=XXXX-XXXX-XXX-XXXX-XXXX openAiServiceName=<openaiservicename> storageAccountName=<storageaccountname> searchServiceName=<searchservicename>
```

After Deploying resources, then can attach AI Search & Azure OpenAI to AI Studio Hub creation at ai.azure.com
You will also be able to connect in Azure OpenAI Studio using keys or managed identity

For Users to leverage resources the permissions.bicep script provides the following permssions:
+ blob data reader (on storage)
+ Storage Blob Data Contributor ( on storage account)
+ Cognitive Services OpenAI Contributor ( on openai)
+ Cognitive Services User ( on openai)
+ Search Index Data Contributor ( on search )
+ Search Index Data Reader ( on search) 
+ Search Service Contributor ( on seaerch)


Some Notes:
+ Enabled soft deletes for blobs and containers. (Not required, but the oai.azure.com/portal requires it.)