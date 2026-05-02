---
layout: post
date: 2025-10-07 08:00:00
updated: 2025-10-07 08:00:00
title: "PowerShell 技能连载 - Azure 存储管理"
description: PowerTip of the Day - Azure Storage Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure
- storage
- blob
- cloud
---

_适用于 PowerShell 5.1 及以上版本_

<!-- more -->

## Azure 存储服务概述

在现代云原生架构中，对象存储已经成为应用数据持久化的首选方案。Azure Blob Storage 作为微软 Azure 平台的核心存储服务，支持海量非结构化数据的存放，包括文档、镜像、日志文件、备份归档等。无论是 DevOps 流水线中的制品管理，还是数据分析管道中的原始数据暂存，Blob Storage 都扮演着不可替代的角色。

对于运维工程师和自动化开发者来说，通过 PowerShell 管理 Azure 存储资源可以带来显著的效率提升。Azure 提供了两个主要的 PowerShell 模块：`Az.Storage`（基于 Az 资源管理器）和 `Azure.Storage`（经典管理模式）。本文将围绕推荐的 `Az.Storage` 模块，介绍存储账户创建、Blob 容器操作、文件上传下载以及存储访问策略配置等常见操作。

掌握这些操作后，你可以将存储管理无缝集成到现有的自动化脚本中，实现从基础设施配置到数据流转的全链路 PowerShell 自动化。

## 连接 Azure 并创建存储账户

在操作 Blob Storage 之前，需要先安装 Az 模块并通过 `Connect-AzAccount` 完成身份认证。认证通过后，即可创建资源组和存储账户。存储账户是所有 Blob、文件、队列和表服务的顶级命名空间，其名称在 Azure 全局范围内必须唯一。

```powershell
# 安装 Az 模块（仅首次需要）
Install-Module -Name Az -Repository PSGallery -Force -Scope CurrentUser

# 登录 Azure（会弹出浏览器窗口进行认证）
Connect-AzAccount

# 选择目标订阅
$subscriptionId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
Set-AzContext -SubscriptionId $subscriptionId

# 创建资源组
$resourceGroupName = "rg-storage-demo"
$location = "eastasia"
$null = New-AzResourceGroup -Name $resourceGroupName -Location $location -Force
Write-Host "资源组 [$resourceGroupName] 已创建于 [$location]"

# 创建存储账户（Standard LRS 冗余级别，适合开发测试）
$storageAccountName = "st$(Get-Random -Minimum 100000 -Maximum 999999)"
$storageSku = "Standard_LRS"
$storageKind = "StorageV2"

$storageAccount = New-AzStorageAccount `
    -ResourceGroupName $resourceGroupName `
    -Name $storageAccountName `
    -SkuName $storageSku `
    -Kind $storageKind `
    -Location $location `
    -EnableHttpsTrafficOnly $true `
    -MinimumTlsVersion "TLS1_2"

Write-Host "存储账户 [$storageAccountName] 已创建"
Write-Host "  SKU: $($storageAccount.Sku.Name)"
Write-Host "  类型: $($storageAccount.Kind)"
Write-Host "  位置: $($storageAccount.Location)"
Write-Host "  访问端点: $($storageAccount.PrimaryEndpoints.Blob)"
```

```text
资源组 [rg-storage-demo] 已创建于 [eastasia]
存储账户 [st729384] 已创建
  SKU: Standard_LRS
  类型: StorageV2
  位置: eastasia
  访问端点: https://st729384.blob.core.windows.net/
```

## Blob 容器操作与文件上传

存储账户创建完成后，下一步是创建 Blob 容器（Container），它类似于文件夹的概念，用于组织和隔离不同业务场景的 Blob 对象。Azure 提供三种访问级别：Private（默认，需认证）、Blob（允许匿名读取 Blob）和 Container（允许匿名列出和读取）。对于生产环境，建议始终保持 Private，通过 SAS 令牌或 Azure AD 认证控制访问。

```powershell
# 获取存储账户上下文（后续操作都需要）
$ctx = $storageAccount.Context

# 创建 Blob 容器
$containerName = "app-logs"
$container = New-AzStorageContainer -Name $containerName -Context $ctx -Permission Off
Write-Host "容器 [$containerName] 已创建，访问级别: $($container.PublicAccess)"

# 准备测试文件
$tempDir = Join-Path -Path $env:TEMP -ChildPath "storage-demo"
$null = New-Item -Path $tempDir -ItemType Directory -Force

$logFiles = @(
    @{ Name = "app-2025-10-01.log"; Content = "2025-10-01 INFO Application started" }
    @{ Name = "app-2025-10-02.log"; Content = "2025-10-02 INFO Database connected" }
    @{ Name = "app-2025-10-03.log"; Content = "2025-10-03 WARN Memory usage high" }
)

foreach ($log in $logFiles) {
    $filePath = Join-Path -Path $tempDir -ChildPath $log.Name
    Set-Content -Path $filePath -Value $log.Content -Encoding UTF8
    Write-Host "已生成本地文件: $($log.Name)"
}

# 批量上传文件到 Blob 容器
Write-Host "`n开始上传文件到 Blob 容器..."
$localFiles = Get-ChildItem -Path $tempDir -Filter "*.log"
foreach ($file in $localFiles) {
    $blob = Set-AzStorageBlobContent `
        -File $file.FullName `
        -Container $containerName `
        -Blob $file.Name `
        -Context $ctx `
        -StandardBlobTier Hot

    Write-Host "  已上传: $($blob.Name) | 大小: $($blob.Length) 字节 | 层级: $($blob.StandardBlobTier)"
}

# 列出容器中的所有 Blob
Write-Host "`n容器 [$containerName] 中的文件列表："
$blobs = Get-AzStorageBlob -Container $containerName -Context $ctx
foreach ($blob in $blobs) {
    Write-Host "  - $($blob.Name) ($($blob.Length) 字节) 最后修改: $($blob.LastModified.ToString('yyyy-MM-dd HH:mm:ss'))"
}
```

```text
容器 [app-logs] 已创建，访问级别: Off
已生成本地文件: app-2025-10-01.log
已生成本地文件: app-2025-10-02.log
已生成本地文件: app-2025-10-03.log

开始上传文件到 Blob 容器...
  已上传: app-2025-10-01.log | 大小: 38 字节 | 层级: Hot
  已上传: app-2025-10-02.log | 大小: 40 字节 | 层级: Hot
  已上传: app-2025-10-03.log | 大小: 38 字节 | 层级: Hot

容器 [app-logs] 中的文件列表：
  - app-2025-10-01.log (38 字节) 最后修改: 2025-10-07 10:30:15
  - app-2025-10-02.log (40 字节) 最后修改: 2025-10-07 10:30:16
  - app-2025-10-03.log (38 字节) 最后修改: 2025-10-07 10:30:17
```

## 生成 SAS 令牌与访问策略管理

在实际应用中，经常需要将 Blob 的访问权限临时授予外部系统或客户端应用，而不希望暴露存储账户的密钥。共享访问签名（Shared Access Signature，SAS）正是为此设计的。SAS 令牌可以精确控制访问权限（读、写、删除）、有效时间范围和允许的 IP 地址，是 Azure 存储安全模型的核心组成部分。

```powershell
# 为整个容器生成 SAS 令牌（只读，有效期 1 小时）
$sasToken = New-AzStorageContainerSASToken `
    -Name $containerName `
    -Context $ctx `
    -Permission "r" `
    -StartTime (Get-Date) `
    -ExpiryTime (Get-Date).AddHours(1)

Write-Host "容器 SAS 令牌（只读，1小时有效）："
Write-Host $sasToken

# 为单个 Blob 生成 SAS 令牌（读写，有效期 30 分钟）
$targetBlob = "app-2025-10-01.log"
$blobSasToken = New-AzStorageBlobSASToken `
    -Container $containerName `
    -Blob $targetBlob `
    -Context $ctx `
    -Permission "rw" `
    -StartTime (Get-Date) `
    -ExpiryTime (Get-Date).AddMinutes(30)

Write-Host "`nBlob [$targetBlob] SAS 令牌（读写，30分钟有效）："
Write-Host $blobSasToken

# 使用 SAS 令牌通过 HTTP 下载 Blob
$fullUrl = "$($ctx.BlobEndPoint)$containerName/$targetBlob$blobSasToken"
$downloadPath = Join-Path -Path $tempDir -ChildPath "downloaded-$targetBlob"
Invoke-WebRequest -Uri $fullUrl -OutFile $downloadPath
Write-Host "`n通过 SAS URL 下载成功: $downloadPath"
Write-Host "文件内容: $((Get-Content -Path $downloadPath -Raw).Trim())"

# 配置存储访问策略（用于长期管理的最佳实践）
$accessPolicy = @{
    StartTime  = Get-Date
    ExpiryTime = (Get-Date).AddDays(30)
    Permission = "rwl"
}

$policyName = "app-log-write-policy"
$null = Set-AzStorageContainerAcl `
    -Name $containerName `
    -Context $ctx `
    -Policy $accessPolicy `
    -PolicyName $policyName

Write-Host "`n已创建存储访问策略: [$policyName]"
Write-Host "  权限: $($accessPolicy.Permission)（读写+列表）"
Write-Host "  有效期: $($accessPolicy.StartTime.ToString('yyyy-MM-dd')) - $($accessPolicy.ExpiryTime.ToString('yyyy-MM-dd'))"

# 查看容器上的所有访问策略
$acl = Get-AzStorageContainerAcl -Name $containerName -Context $ctx
foreach ($policy in $acl) {
    Write-Host "`n策略: $($policy.Id)"
    Write-Host "  权限: $($policy.AccessPolicy.Permission)"
    Write-Host "  起始: $($policy.AccessPolicy.StartTime.ToString('yyyy-MM-dd HH:mm:ss'))"
    Write-Host "  过期: $($policy.AccessPolicy.ExpiryTime.ToString('yyyy-MM-dd HH:mm:ss'))"
}

# 清理临时文件
Remove-Item -Path $tempDir -Recurse -Force
Write-Host "`n临时文件已清理"
```

```text
容器 SAS 令牌（只读，1小时有效）：
?sv=2023-01-03&ss=b&srt=co&sp=r&se=2025-10-07T11:30:00Z&st=2025-10-07T10:30:00Z&spr=https&sig=abc123XYZ...

Blob [app-2025-10-01.log] SAS 令牌（读写，30分钟有效）：
?sv=2023-01-03&ss=b&srt=sco&sp=rw&se=2025-10-07T11:00:00Z&st=2025-10-07T10:30:00Z&spr=https&sig=def456UVW...

通过 SAS URL 下载成功: /tmp/storage-demo/downloaded-app-2025-10-01.log
文件内容: 2025-10-01 INFO Application started

已创建存储访问策略: [app-log-write-policy]
  权限: rwl（读写+列表）
  有效期: 2025-10-07 - 2025-11-06

策略: app-log-write-policy
  权限: rwl
  起始: 2025-10-07 10:30:00
  过期: 2025-11-06 10:30:00

临时文件已清理
```

## 注意事项

1. **存储账户命名规则**：存储账户名称只能包含小写字母和数字，长度为 3-24 个字符，且在 Azure 全局范围内必须唯一。建议在脚本中使用 `Get-Random` 或业务前缀加哈希的方式生成名称，避免因名称冲突导致创建失败。

2. **SAS 令牌安全保管**：SAS 令牌本质上是一个携带权限信息的 URL 参数，任何获得该令牌的人都可以在有效期内访问对应资源。在日志记录、API 响应和脚本输出中应避免打印完整的 SAS URL。建议使用存储访问策略（Stored Access Policy）来管理 SAS，这样可以在令牌泄露时通过撤销策略立即失效。

3. **Blob 层级选择**：Azure Blob Storage 提供热（Hot）、冷（Cool）和归档（Archive）三种访问层级。热层级访问性能最优但存储成本最高，归档层级存储成本最低但读取需要数小时的解冻时间。在脚本中可以通过 `StandardBlobTier` 参数在上传时指定层级，也可以对已有 Blob 调用 `Set-AzStorageBlobTier` 进行层级转换。

4. **Az 模块版本兼容性**：`Az.Storage` 模块更新频繁，不同版本之间的 cmdlet 参数可能有差异。建议在脚本开头通过 `#Requires -Modules @{ ModuleName="Az.Storage"; ModuleVersion="5.0.0" }` 声明最低版本要求，确保脚本在目标环境中能正常运行。

5. **大文件上传策略**：对于超过 256 MB 的文件，应使用分块上传（Block Blob）方式，将文件拆分为多个 Block 分别上传后提交组合。`Set-AzStorageBlobContent` 会自动处理分块逻辑，但在网络不稳定的环境下，建议手动控制分块大小并实现重试机制，避免因单次网络中断导致整个上传任务失败。

6. **资源清理与成本控制**：测试和演示完毕后，务必通过 `Remove-AzStorageAccount` 和 `Remove-AzResourceGroup` 清理不再使用的资源。存储账户即使不活跃也会产生最低存储费用和计费周期费用。建议在非生产环境中为资源组添加自动过期标签，并通过 Azure Policy 或定时脚本定期清理过期资源。
