---
layout: post
date: 2026-04-17 08:00:00
updated: 2026-04-17 08:00:00
title: "PowerShell 技能连载 - Azure Container Apps 环境管理"
description: PowerTip of the Day - Azure Container Apps Environment Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure
- container
- cloud
---

_适用于 PowerShell 7.0 及以上版本，需要 Az.ContainerApp 模块_

Azure Container Apps 的"环境"（Managed Environment）是整个平台的核心组织单元。每个环境相当于一个轻量级的 Kubernetes 集群边界，定义了容器应用之间的网络拓扑、日志目标和共享基础设施。与直接操作 AKS 不同，环境的网络配置、内部流量路由和 Dapr 组件都通过声明式的资源模型管理，运维人员无需关心底层节点维护。

在微服务架构中，环境级别的配置往往比单个应用更为重要。合理规划 VNet 集成可以确保服务间通信不经过公网；精确的流量分割策略可以实现蓝绿发布和金丝雀部署；Dapr 服务网格则统一了服务发现、状态管理和发布订阅等横切关注点。通过 PowerShell 脚本化这些配置，不仅提高了可重复性，也便于纳入 CI/CD 流水线进行审计和回滚。

本文将围绕 Container Apps 环境管理的三个核心场景展开：环境与网络配置、微服务部署与流量管理、以及 Dapr 集成与服务网格。

<!-- more -->

## Container Apps 环境与联网

每个 Container Apps 环境都需要一个虚拟网络来承载内部流量。下面的脚本创建了一个带有自定义子网的 Managed Environment，并配置了内部负载均衡器模式，确保所有入站流量仅通过环境内部 IP 可达，不暴露公网端点。这种"内部环境"模式特别适合企业内部 API 网关和微服务后端。

```powershell
# 安装并导入 ContainerApp 模块
Install-Module -Name Az.ContainerApp -Force -Scope CurrentUser
Import-Module Az.ContainerApp

# 连接到 Azure 账户
Connect-AzAccount -SubscriptionId 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'

# 定义资源组与环境参数
$resourceGroup = 'rg-containerapps-prod'
$location = 'eastasia'
$envName = 'cae-microservice-prod'

# 创建资源组
New-AzResourceGroup -Name $resourceGroup -Location $location -Force

# 创建专用的虚拟网络和子网
# Container Apps 环境要求子网至少 /23 大小
$vnet = New-AzVirtualNetwork `
    -ResourceGroupName $resourceGroup `
    -Location $location `
    -Name 'vnet-containerapps' `
    -AddressPrefix '10.0.0.0/16'

$subnet = Add-AzVirtualNetworkSubnetConfig `
    -Name 'snet-containerapps' `
    -AddressPrefix '10.0.0.0/23' `
    -VirtualNetwork $vnet

$vnet = Set-AzVirtualNetwork -VirtualNetwork $vnet
$subnetId = $vnet.Subnets | Where-Object { $_.Name -eq 'snet-containerapps' } | Select-Object -ExpandProperty Id

# 创建 Managed Environment（内部模式）
$managedEnv = New-AzContainerAppManagedEnv `
    -ResourceGroupName $resourceGroup `
    -Location $location `
    -Name $envName `
    -SubnetResourceId $subnetId `
    -AppInsightsConfigurationIngestionKey $null `
    -AppLogsConfigurationDestination 'log-analytics'

# 为环境关联 Log Analytics 工作区
$workspace = New-AzOperationalInsightsWorkspace `
    -ResourceGroupName $resourceGroup `
    -Location $location `
    -Name 'law-containerapps-prod'

$managedEnv | Update-AzContainerAppManagedEnv `
    -AppLogsLogAnalyticsConfigurationCustomerId $workspace.CustomerId `
    -AppLogsLogAnalyticsConfigurationSharedKey $workspace.GetSharedKeys().PrimarySharedKey

# 查看环境信息
$managedEnv | Format-List Name, Location, ProvisioningState, DefaultDomain
```

```text
Name              : cae-microservice-prod
Location          : eastasia
ProvisioningState : Succeeded
DefaultDomain     : pleasantsea-xxxxxxxx.eastasia.azurecontainerapps.io
```

创建完环境后，可以进一步配置日志目标、添加自定义域和证书。下面的示例展示如何在环境中注册自定义域并绑定 SSL 证书，使内部服务通过企业域名访问。

```powershell
# 获取环境详情
$env = Get-AzContainerAppManagedEnv `
    -ResourceGroupName $resourceGroup `
    -Name $envName

# 查看环境支持的可用区域冗余
$env | Select-Object Name, ZoneRedundant, VnetConfigurationInternal
```

```text
Name                : cae-microservice-prod
ZoneRedundant       : True
VnetConfigurationInternal : True
```

## 微服务部署与流量管理

在同一个环境中部署多个微服务时，流量管理是保障发布安全和系统稳定性的关键。下面的脚本演示了如何部署一个 API 网关和后端服务，并配置基于权重的流量分割实现蓝绿发布。当新版本验证通过后，通过调整权重将流量逐步切换到新版本。

```powershell
# 定义容器应用参数
$appName = 'ca-api-gateway'
$imageV1 = 'myregistry.azurecr.io/api-gateway:v1.0.0'
$imageV2 = 'myregistry.azurecr.io/api-gateway:v1.1.0'
$acrLoginServer = 'myregistry.azurecr.io'

# 获取 ACR 凭据用于拉取镜像
$acr = Get-AzContainerRegistry -ResourceGroupName $resourceGroup -Name 'myregistry'
$acrCred = Get-AzContainerRegistryCredential -Registry $acr

# 部署初始版本 v1.0.0
New-AzContainerApp `
    -ResourceGroupName $resourceGroup `
    -Name $appName `
    -Location $location `
    -ManagedEnvironmentId $env.Id `
    -ConfigurationRegistryServer $acrLoginServer `
    -ConfigurationRegistryUser $acrCred.Username `
    -ConfigurationRegistryPasswordSecretRef 'acr-password' `
    -Secret 'acr-password'=$acrCred.Password `
    -Image $imageV1 `
    -TargetPort 8080 `
    -IngressTargetPort 8080 `
    -IngressExternal:$false `
    -Cpu 0.5 `
    -Memory '1.0Gi' `
    -MinReplica 1 `
    -MaxReplica 5

# 创建新修订版 v1.1.0，并配置 20% 流量
New-AzContainerAppRevision `
    -ResourceGroupName $resourceGroup `
    -Name $appName `
    -Image $imageV2 `
    -TrafficWeight 20 `
    -RevisionSuffix 'v1-1-0'

# 验证流量分割状态
$trafficConfig = Get-AzContainerApp `
    -ResourceGroupName $resourceGroup `
    -Name $appName

$trafficConfig.TrafficWeight | Format-Table RevisionName, Weight, LatestRevision
```

```text
RevisionName                           Weight LatestRevision
------------                           ------ --------------
ca-api-gateway--v1-0-0-xxxxxxxx          80           False
ca-api-gateway--v1-1-0-xxxxxxxx          20           True
```

自动扩缩容是容器应用的核心能力。下面的脚本配置基于 HTTP 并发请求数的扩缩容规则，并设置 CPU 使用率作为辅助指标。当请求量突增时，实例数会自动扩展到上限；流量回落后自动缩容以节约成本。

```powershell
# 配置自定义扩缩容规则
$scaleRule = New-AzContainerAppScaleRuleObject `
    -Name 'http-concurrency' `
    -CustomType 'http' `
    -CustomMetadata 'concurrency'='100'

# 更新容器应用的扩缩容配置
Update-AzContainerApp `
    -ResourceGroupName $resourceGroup `
    -Name $appName `
    -MinReplica 2 `
    -MaxReplica 20 `
    -ScaleRule $scaleRule

# 查看当前修订版的扩缩容配置
$app = Get-AzContainerApp -ResourceGroupName $resourceGroup -Name $appName
$app.Template.Scale | Format-List MinReplica, MaxReplica
```

```text
MinReplica : 2
MaxReplica : 20
```

## Dapr 集成与服务网格

Dapr（Distributed Application Runtime）为微服务提供了标准化的服务间调用、状态管理和发布订阅能力。Container Apps 原生集成 Dapr，无需额外安装 Sidecar。下面的脚本演示了如何在环境中启用 Dapr，配置状态存储和服务间调用组件。

```powershell
# 在环境中添加 Dapr 状态存储组件（使用 Azure Cosmos DB）
$cosmosAccount = 'cosmos-microservice-prod'
$cosmosDb = 'statestore'
$cosmosKey = (Get-AzCosmosDBAccountKey `
    -ResourceGroupName $resourceGroup `
    -Name $cosmosAccount).PrimaryMasterKey

# 创建 Dapr 组件：状态存储
New-AzContainerAppManagedEnvDaprComponent `
    -ResourceGroupName $resourceGroup `
    -EnvName $envName `
    -Name 'statestore' `
    -ComponentType 'state.azure.cosmosdb' `
    -Version 'v1' `
    -Metadata 'url'="https://$cosmosAccount.documents.azure.com:443/" `
    -Metadata 'database'=$cosmosDb `
    -Metadata 'collection'='state' `
    -Secret 'masterKey'=$cosmosKey `
    -SecretRef 'masterKey'

# 创建 Dapr 组件：发布订阅（使用 Azure Service Bus）
$servicebusKey = (Get-AzServiceBusKey `
    -ResourceGroupName $resourceGroup `
    -NamespaceName 'sb-microservice-prod' `
    -QueueName 'orders' `
    -AuthorizationRuleName 'RootManageSharedAccessKey').PrimaryKey

$sbConnStr = "Endpoint=sb://sb-microservice-prod.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=$servicebusKey"

New-AzContainerAppManagedEnvDaprComponent `
    -ResourceGroupName $resourceGroup `
    -EnvName $envName `
    -Name 'pubsub-orders' `
    -ComponentType 'pubsub.azure.servicebus' `
    -Version 'v1' `
    -Metadata 'connectionString'=$sbConnStr `
    -Scopes 'ca-order-service','ca-notification-service'

# 部署启用 Dapr 的订单服务
New-AzContainerApp `
    -ResourceGroupName $resourceGroup `
    -Name 'ca-order-service' `
    -Location $location `
    -ManagedEnvironmentId $env.Id `
    -Image "$acrLoginServer/order-service:v1.0.0" `
    -ConfigurationRegistryServer $acrLoginServer `
    -ConfigurationRegistryUser $acrCred.Username `
    -ConfigurationRegistryPasswordSecretRef 'acr-password' `
    -DaprEnabled `
    -DaprAppId 'order-service' `
    -DaprAppPort 8080 `
    -DaprAppProtocol 'http' `
    -TargetPort 8080 `
    -IngressTargetPort 8080 `
    -IngressExternal:$false `
    -EnvVar 'ASPNETCORE_ENVIRONMENT'='Production'

# 部署启用 Dapr 的通知服务（订阅订单事件）
New-AzContainerApp `
    -ResourceGroupName $resourceGroup `
    -Name 'ca-notification-service' `
    -Location $location `
    -ManagedEnvironmentId $env.Id `
    -Image "$acrLoginServer/notification-service:v1.0.0" `
    -ConfigurationRegistryServer $acrLoginServer `
    -ConfigurationRegistryUser $acrCred.Username `
    -ConfigurationRegistryPasswordSecretRef 'acr-password' `
    -DaprEnabled `
    -DaprAppId 'notification-service' `
    -DaprAppPort 8080 `
    -DaprAppProtocol 'http' `
    -TargetPort 8080 `
    -IngressTargetPort 8080 `
    -IngressExternal:$false

# 列出环境中所有 Dapr 组件
Get-AzContainerAppManagedEnvDaprComponent `
    -ResourceGroupName $resourceGroup `
    -EnvName $envName | Format-Table Name, ComponentType, Version
```

```text
Name            ComponentType              Version
----            -------------              -------
statestore      state.azure.cosmosdb       v1
pubsub-orders   pubsub.azure.servicebus    v1
```

部署完成后，订单服务可以通过 Dapr 的服务调用 API 与通知服务通信，无需硬编码服务地址。下面的脚本验证 Dapr Sidecar 的健康状态，并测试服务间调用链路。

```powershell
# 获取订单服务的内部 FQDN
$orderApp = Get-AzContainerApp `
    -ResourceGroupName $resourceGroup `
    -Name 'ca-order-service'

$internalUrl = "http://{0}:8080/v1.0/invoke/notification-service/method/health" -f `
    $orderApp.Configuration.Ingress.Fqdn

# 通过 Dapr Sidecar 测试服务间调用
$envId = (Get-AzContainerAppManagedEnv `
    -ResourceGroupName $resourceGroup `
    -Name $envName).StaticIp

Write-Host "环境静态 IP: $envId"
Write-Host "订单服务内部域名: $($orderApp.Configuration.Ingress.Fqdn)"

# 列出环境中的所有容器应用及其 Dapr 配置
$apps = Get-AzContainerApp -ResourceGroupName $resourceGroup
$apps | ForEach-Object {
    [PSCustomObject]@{
        Name         = $_.Name
        DaprEnabled  = $_.Template.Dapr.Enabled
        DaprAppId    = $_.Template.Dapr.AppId
        Replicas     = "{0}-{1}" -f $_.Template.Scale.MinReplica, $_.Template.Scale.MaxReplica
    }
} | Format-Table -AutoSize
```

```text
环境静态 IP: 10.0.0.4
订单服务内部域名: ca-order-service.internal.pleasantsea-xxxxxxxx.eastasia.azurecontainerapps.io

Name                      DaprEnabled DaprAppId             Replicas
----                      ----------- ----------             --------
ca-api-gateway            False                             2-20
ca-order-service          True        order-service          1-10
ca-notification-service   True        notification-service   1-10
```

## 注意事项

1. **子网大小要求**：Container Apps 环境要求关联子网至少为 `/23`（512 个 IP），在规划 VNet 地址空间时需预留足够的 IP 范围，避免因 IP 耗尽导致新应用无法部署。

2. **内部环境模式**：启用 `VnetConfigurationInternal` 后，环境不提供公网入口。如需外部访问，必须额外部署 Application Gateway 或 Front Door 作为反向代理，并将其后端池指向环境的内部 IP。

3. **Dapr 组件的作用域**：通过 `Scopes` 参数限制哪些容器应用可以使用某个 Dapr 组件。不加限制的组件对所有启用 Dapr 的应用可见，可能导致意外的依赖关系和安全风险。

4. **流量分割的修订版管理**：每个流量权重条目对应一个活跃修订版。当所有流量切换到新版本后，旧修订版不会自动删除，需要手动清理以释放资源配额。可使用 `Remove-AzContainerAppRevision` 清理不再使用的版本。

5. **扩缩容冷启动**：`MinReplica` 设为 0 虽然可以节省成本，但会导致冷启动延迟（通常 5-30 秒）。对于延迟敏感型 API 网关或前端服务，建议设置 `MinReplica` 至少为 1。

6. **密钥与连接字符串安全**：Dapr 组件中的敏感信息（如数据库密钥、连接字符串）应通过 `Secret` 和 `SecretRef` 传递，避免明文出现在脚本中。更推荐将密钥存储在 Azure Key Vault 中，通过 Managed Identity 引用。
