---
layout: post
date: 2026-01-27 08:00:00
updated: 2026-01-27 08:00:00
title: "PowerShell 技能连载 - Azure Cosmos DB 操作"
description: PowerTip of the Day - Azure Cosmos DB Operations in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure
- cosmosdb
- nosql
- database
---

_适用于 PowerShell 7.0 及以上版本_

Azure Cosmos DB 是微软推出的全球分布式多模型数据库服务，原生支持 SQL API、MongoDB API、Cassandra API、Gremlin API 和 Table API 等多种数据模型。在全球化部署的微服务架构中，Cosmos DB 能够提供个位数毫秒级的读写延迟，并通过多区域写入实现 99.999% 的高可用性 SLA。无论是物联网场景的海量设备数据写入，还是电商平台的实时库存查询，Cosmos DB 都能胜任。

在混合云和多云管理场景下，运维团队通常需要同时管理多个 Cosmos DB 账户，涉及账户创建、一致性策略配置、多区域复制设置、吞吐量调整和备份恢复等操作。手动完成这些任务不仅耗时，而且容易因人为失误导致配置不一致。通过 PowerShell 脚本将这些操作标准化，可以实现一键部署、版本控制和审计追踪。

本文将介绍如何使用 PowerShell 和 `Az` 模块完成 Cosmos DB 的账户管理、容器操作以及数据备份恢复等常见任务，帮助你构建自动化的数据库运维流程。

<!-- more -->

## Cosmos DB 账户与数据库管理

首先安装并导入必要的模块，然后创建 Cosmos DB 账户并配置一致性策略和多区域复制。以下脚本演示了从零开始创建一个带有会话一致性和双区域复制的 Cosmos DB 账户。

```powershell
# 安装并导入 Az 模块
Install-Module -Name Az.CosmosDB -Force -Scope CurrentUser -Repository PSGallery
Import-Module Az.CosmosDB

# 连接到 Azure
Connect-AzAccount -SubscriptionId 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'

# 定义变量
$resourceGroupName = 'rg-cosmos-demo'
$location = 'eastasia'
$accountName = 'cosmos-psdemo-001'
$databaseName = 'BlogDatabase'

# 创建资源组
New-AzResourceGroup -Name $resourceGroupName -Location $location -Force

# 创建 Cosmos DB 账户（会话一致性 + 多区域写入）
$account = New-AzCosmosDBAccount `
    -ResourceGroupName $resourceGroupName `
    -Name $accountName `
    -Location $location `
    -DefaultConsistencyLevel 'Session' `
    -EnableMultipleWriteLocations:$true `
    -ApiKind 'Sql'

# 添加第二个复制区域（东南亚）
Update-AzCosmosDBAccount `
    -ResourceGroupName $resourceGroupName `
    -Name $accountName `
    -Location $location `
    -LocationObject @{ LocationName = 'southeastasia'; FailoverPriority = 1 }

# 创建数据库（手动吞吐量）
$database = New-AzCosmosDBSqlDatabase `
    -ResourceGroupName $resourceGroupName `
    -AccountName $accountName `
    -Name $databaseName `
    -Throughput 400

Write-Host "Cosmos DB 账户 '$accountName' 创建完成"
Write-Host "数据库 '$databaseName' 已就绪，吞吐量: 400 RU/s"
```

执行结果示例：

```
ResourceGroupName : rg-cosmos-demo
Location          : eastasia
Name              : cosmos-psdemo-001
Kind              : GlobalDocumentDB
Tags              : {}
DefaultConsistencyLevel : Session
EnableMultipleWriteLocations : True

Cosmos DB 账户 'cosmos-psdemo-001' 创建完成
数据库 'BlogDatabase' 已就绪，吞吐量: 400 RU/s
```

## 容器操作与吞吐量管理

创建容器时需要仔细设计分区键，它决定了数据的分布方式和查询性能。下面演示如何创建容器、配置自动扩缩吞吐量，以及查看容器指标。

```powershell
$containerName = 'Posts'
$partitionKeyPath = '/categoryId'

# 创建容器（指定分区键和索引策略）
$indexingPolicy = @{
    indexingMode = 'consistent'
    includedPaths = @(
        @{ path = '/title/?' },
        @{ path = '/createdAt/?' },
        @{ path = '/categoryId/?' }
    )
    excludedPaths = @(
        @{ path = '/*' }
    )
}

$container = New-AzCosmosDBSqlContainer `
    -ResourceGroupName $resourceGroupName `
    -AccountName $accountName `
    -DatabaseName $databaseName `
    -Name $containerName `
    -PartitionKeyKind 'Hash' `
    -PartitionKeyPath $partitionKeyPath `
    -IndexingPolicyObject $indexingPolicy

Write-Host "容器 '$containerName' 创建完成，分区键: $partitionKeyPath"

# 启用自动扩缩吞吐量（400 - 4000 RU/s）
$throughput = Invoke-AzCosmosDBSqlContainerThroughputMigration `
    -ResourceGroupName $resourceGroupName `
    -AccountName $accountName `
    -DatabaseName $databaseName `
    -Name $containerName `
    -ThroughputType Autoscale

$autoscaleSettings = Get-AzCosmosDBSqlContainerThroughput `
    -ResourceGroupName $resourceGroupName `
    -AccountName $accountName `
    -DatabaseName $databaseName `
    -Name $containerName

Write-Host "吞吐量模式: Autoscale"
Write-Host "最小 RU/s: $($autoscaleSettings.AutoscaleSettings.MinThroughput)"
Write-Host "最大 RU/s: $($autoscaleSettings.AutoscaleSettings.MaxThroughput)"

# 列出账户下所有容器
$containers = Get-AzCosmosDBSqlContainer `
    -ResourceGroupName $resourceGroupName `
    -AccountName $accountName `
    -DatabaseName $databaseName

$containers | Format-Table Name, PartitionKey -AutoSize
```

执行结果示例：

```
容器 'Posts' 创建完成，分区键: /categoryId
吞吐量模式: Autoscale
最小 RU/s: 400
最大 RU/s: 4000

Name   PartitionKey
----   ------------
Posts  {/categoryId}
```

## 数据操作与备份恢复

通过 Cosmos DB 的 SQL API 可以直接在 PowerShell 中执行 CRUD 操作。结合定期备份和时间点恢复（PITR）功能，可以构建完整的数据保护方案。以下示例展示文档的增删改查以及备份策略的管理。

```powershell
# 获取账户密钥用于数据平面操作
$keys = Get-AzCosmosDBAccountKey `
    -ResourceGroupName $resourceGroupName `
    -Name $accountName

$primaryKey = $keys[0].Value

# 构造 REST API 请求头
$databaseAccountUrl = "https://${accountName}.documents.azure.com"
$headers = @{
    'x-ms-version' = '2020-07-15'
    'Authorization' = $primaryKey
}

# 插入文档
$document = @{
    id = 'post-001'
    title = 'PowerShell Cosmos DB 指南'
    categoryId = 'cat-powershell'
    author = 'admin'
    createdAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')
    tags = @('powershell', 'azure', 'cosmosdb')
    content = '这是一篇关于使用 PowerShell 管理 Cosmos DB 的文章。'
} | ConvertTo-Json -Depth 5

$body = @{
    documents = @(
        @{
            id = 'post-001'
            title = 'PowerShell Cosmos DB 指南'
            categoryId = 'cat-powershell'
            author = 'admin'
            createdAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')
            tags = @('powershell', 'azure', 'cosmosdb')
        }
    )
} | ConvertTo-Json -Depth 5

Write-Host "文档已准备: $($document.Length) 字节"

# 查看备份策略
$backupInfo = Get-AzCosmosDBAccount `
    -ResourceGroupName $resourceGroupName `
    -Name $accountName

Write-Host "备份类型: $($backupInfo.BackupPolicy.Type)"
Write-Host "备份间隔: $($backupInfo.BackupPolicy.PeriodicModeProperties.BackupIntervalInMinutes) 分钟"
Write-Host "备份保留: $($backupInfo.BackupPolicy.PeriodicModeProperties.BackupRetentionIntervalInHours) 小时"

# 启用连续备份（支持时间点恢复）
Enable-AzCosmosDBAccountContinuousBackup `
    -ResourceGroupName $resourceGroupName `
    -Name $accountName

Write-Host "已启用连续备份模式，支持 30 天内任意时间点恢复"

# 列出可恢复的数据库和容器
$restorableAccounts = Get-AzCosmosDBRestorableDatabaseAccount `
    -Location $location `
    -Name $accountName

Write-Host "可恢复账户数量: $($restorableAccounts.Count)"
Write-Host "最早可恢复时间: $($restorableAccounts[0].OldestRestorableTime)"

# 成本优化：检查低利用率容器
$allContainers = Get-AzCosmosDBSqlContainer `
    -ResourceGroupName $resourceGroupName `
    -AccountName $accountName `
    -DatabaseName $databaseName

foreach ($c in $allContainers) {
    $tp = Get-AzCosmosDBSqlContainerThroughput `
        -ResourceGroupName $resourceGroupName `
        -AccountName $accountName `
        -DatabaseName $databaseName `
        -Name $c.Name -ErrorAction SilentlyContinue

    if ($tp) {
        $ruInfo = "容器: $($c.Name) | 吞吐量: $($tp.Throughput) RU/s"
        if ($tp.AutoscaleSettings) {
            $ruInfo += " (自动扩缩: $($tp.AutoscaleSettings.MaxThroughput) RU/s 上限)"
        }
        Write-Host $ruInfo
    }
}
```

执行结果示例：

```
文档已准备: 287 字节
备份类型: Periodic
备份间隔: 240 分钟
备份保留: 8 小时
已启用连续备份模式，支持 30 天内任意时间点恢复
可恢复账户数量: 1
最早可恢复时间: 2026-01-26T08:00:00Z
容器: Posts | 吞吐量:  RU/s (自动扩缩: 4000 RU/s 上限)
```

## 注意事项

1. **分区键设计至关重要**：分区键一旦创建无法修改。选择基数高且分布均匀的属性作为分区键，避免"热分区"导致性能瓶颈。建议使用 `categoryId`、`tenantId` 等天然分散的字段。

2. **吞吐量成本控制**：Cosmos DB 按配置的 RU/s 计费，而非实际消耗。开发环境可使用无服务器（Serverless）模式按请求计费，生产环境建议启用自动扩缩以平衡性能与成本。

3. **一致性级别权衡**：从强到弱依次为 Strong、Bounded Staleness、Session、Consistent Prefix、Eventual。Session 是大多数场景的最佳选择，在保证读己之写的同时提供良好的性能。

4. **备份策略选择**：定期备份（Periodic）默认保留 8 小时，连续备份（Continuous）支持 30 天内任意时间点恢复（PITR），但连续备份会产生额外费用，建议仅对关键业务数据库启用。

5. **多区域写入注意事项**：启用多区域写入时，只支持 Session、Consistent Prefix 和 Eventual 三种一致性级别。同时需注意冲突解决策略的配置，避免数据不一致。

6. **密钥安全与轮换**：Cosmos DB 提供主密钥和资源令牌两种认证方式。生产环境建议使用 Azure Key Vault 存储连接字符串，并定期轮换主密钥（支持零停机轮换，新旧密钥可同时生效）。
