param location string = resourceGroup().location
param tags object = {}
param webServiceName string
param logAnalyticsName string
param applicationInsightsName string
param applicationInsightsDashboardName string
param appServicePlanName string
param appServiceName string
param keyVaultName string

// Provision a log analytics workspace, application insights instance and dashboard
module monitoring '../core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    location: location
    tags: tags
    logAnalyticsName: logAnalyticsName
    applicationInsightsName: applicationInsightsName
    applicationInsightsDashboardName: applicationInsightsDashboardName
  }
}

// Provision an app service plan
module appServicePlan '../core/host/appserviceplan.bicep' = {
  name: 'appServicePlan'
  params: {
    location: location
    tags: tags
    name: appServicePlanName
    sku: {
      name: 'B1'
    }
    kind: 'linux'
  }
}

// Provision an app service instance and add configuration for application insights and key vault
module web '../core/host/appservice.bicep' = {
  name: 'web'
  params: {
    name: appServiceName
    location: location
    tags: union(tags, { 'azd-service-name': webServiceName })
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    appServicePlanId: appServicePlan.outputs.id
    keyVaultName: keyVaultName
    runtimeName: 'dotnetcore'
    runtimeVersion: '8.0'
    appSettings: {
      ASPNETCORE_ENVIRONMENT: 'Development'
    }
  }
}

output APPLICATIONINSIGHTS_CONNECTION_STRING string = monitoring.outputs.applicationInsightsConnectionString
output SERVICE_WEB_IDENTITY_PRINCIPAL_ID string = web.outputs.identityPrincipalId
output SERVICE_WEB_NAME string = web.outputs.name
output SERVICE_WEB_URI string = web.outputs.uri
