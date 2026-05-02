---
layout: post
date: 2026-01-20 08:00:00
updated: 2026-01-20 08:00:00
title: "PowerShell 技能连载 - Azure 存储服务管理"
description: PowerTip of the Day - Azure Storage Service Management in PowerShell
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
- cloud
---

_适用于 PowerShell 7.0 及以上版本_

Azure 存储服务是云基础设施中不可或缺的一环。无论是应用程序数据持久化、静态网站托管、大数据分析流水线，还是灾备归档，都离不开它。一个中型企业往往拥有数十个存储账户、数百个容器和海量的 Blob 对象，靠手工在 Azure 门户中逐一配置既容易出错，也难以保证一致性。

PowerShell 通过 `Az.Storage` 模块提供了对 Azure 存储的完整管理能力。从存储账户的创建与访问层选择，到 Blob 容器的生命周期策略，再到细粒度的访问控制和成本监控，都可以编写脚本实现自动化。对于需要跨区域部署或遵循合规要求的场景，脚本能确保每次操作都遵循相同的规范。

本文将通过三个实战场景，展示如何使用 PowerShell 高效管理 Azure 存储：首先是存储账户与 Blob 容器的批量管理，其次是文件共享与生命周期策略配置，最后是存储分析与成本监控。

<!-- more -->

## 存储账户与 Blob 容器管理

在 Azure 中，存储账户是所有存储服务的根容器。创建时需要选择合适的复制策略和访问层，以平衡性能和成本。下面的脚本展示了如何批量创建存储账户、配置访问层，以及管理 Blob 容器的完整流程。

```powershell
# 连接 Azure 账户（如已登录可跳过）
Connect-AzAccount

# 定义存储账户配置
$resourceGroup = "blog-storage-rg"
$location = "eastasia"
$accounts = @(
    @{ Name = "stbloghotprod"; AccessTier = "Hot"; Sku = "Standard_LRS" }
    @{ Name = "stblogcoolarch"; AccessTier = "Cool"; Sku = "Standard_GRS" }
    @{ Name = "stblogpremv2";   AccessTier = "Hot";  Sku = "Premium_LRS" }
)

# 确保资源组存在
if (-not (Get-AzResourceGroup -Name $resourceGroup -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $resourceGroup -Location $location
    Write-Host "已创建资源组: $resourceGroup"
}

# 批量创建存储账户
foreach ($acct in $accounts) {
    $existing = Get-AzStorageAccount -ResourceGroupName $resourceGroup `
        -Name $acct.Name -ErrorAction SilentlyContinue

    if ($existing) {
        Write-Host "存储账户 $($acct.Name) 已存在，跳过创建"
    } else {
        New-AzStorageAccount -ResourceGroupName $resourceGroup `
            -Name $acct.Name `
            -Location $location `
            -SkuName $acct.Sku `
            -Kind StorageV2 `
            -AccessTier $acct.AccessTier `
            -EnableHierarchicalNamespace $false
        Write-Host "已创建存储账户: $($acct.Name) ($($acct.AccessTier) / $($acct.Sku))"
    }
}

# 获取第一个存储账户的上下文并创建容器
$storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroup `
    -Name $accounts[0].Name
$ctx = $storageAccount.Context

# 定义容器列表及公开访问级别
$containers = @(
    @{ Name = "images"; Access = "Blob" }
    @{ Name = "documents"; Access = "Off" }
    @{ Name = "logs"; Access = "Off" }
    @{ Name = "backups"; Access = "Off" }
)

foreach ($c in $containers) {
    $existing = Get-AzStorageContainer -Name $c.Name -Context $ctx `
        -ErrorAction SilentlyContinue

    if ($existing) {
        Write-Host "容器 $($c.Name) 已存在"
    } else {
        New-AzStorageContainer -Name $c.Name -Context $ctx `
            -Permission $c.Access
        Write-Host "已创建容器: $($c.Name) (公开访问: $($c.Access))"
    }
}

# 批量上传文件到 images 容器
$uploadPath = "/data/blog-assets"
if (Test-Path $uploadPath) {
    $files = Get-ChildItem -Path $uploadPath -File
    foreach ($file in $files) {
        Set-AzStorageBlobContent -File $file.FullName `
            -Container "images" `
            -Blob $file.Name `
            -Context $ctx `
            -StandardBlobTier Hot `
            -Force
        Write-Host "已上传: $($file.Name) ($('{0:N2}' -f ($file.Length / 1KB)) KB)"
    }
}
```

执行结果示例：

```
已创建资源组: blog-storage-rg
已创建存储账户: stbloghotprod (Hot / Standard_LRS)
已创建存储账户: stblogcoolarch (Cool / Standard_GRS)
已创建存储账户: stblogpremv2 (Hot / Premium_LRS)
已创建容器: images (公开访问: Blob)
已创建容器: documents (公开访问: Off)
已创建容器: logs (公开访问: Off)
已创建容器: backups (公开访问: Off)
已上传: hero-banner.png (245.67 KB)
已上传: logo-dark.svg (3.21 KB)
已上传: favicon.ico (4.12 KB)
```

## 文件共享与生命周期管理

当存储规模增长后，手动管理数据的分层和过期变得不现实。Azure 存储的生命周期管理（Lifecycle Management）可以根据规则自动将数据从热层迁移到冷层或归档层，甚至自动删除过期数据。结合 SAS 令牌，还可以为第三方应用授予临时访问权限，而无需暴露存储账户密钥。

```powershell
# 获取存储账户上下文
$storageAccount = Get-AzStorageAccount -ResourceGroupName "blog-storage-rg" `
    -Name "stbloghotprod"
$ctx = $storageAccount.Context

# 创建文件共享（Azure Files）
$shareName = "blog-shared-assets"
$share = Get-AzStorageShare -Name $shareName -Context $ctx `
    -ErrorAction SilentlyContinue

if (-not $share) {
    New-AzStorageShare -Name $shareName -Context $ctx
    Write-Host "已创建文件共享: $shareName"
}

# 上传目录到文件共享
$localDir = "/data/shared-docs"
if (Test-Path $localDir) {
    Get-ChildItem -Path $localDir -File | ForEach-Object {
        Set-AzStorageFileContent -ShareName $shareName `
            -Source $_.FullName `
            -Path $_.Name `
            -Context $ctx `
            -Force
        Write-Host "已上传到文件共享: $($_.Name)"
    }
}

# 生成 SAS 令牌（只读，7 天有效）
$sasToken = New-AzStorageAccountSASToken `
    -Service Blob,File `
    -ResourceType Service,Container,Object `
    -Permission "rl" `
    -ExpiryTime (Get-Date).AddDays(7) `
    -Context $ctx

Write-Host "SAS 令牌已生成（7 天只读）:"
Write-Host $sasToken.Substring(0, 30) "..."

# 配置生命周期管理策略
$lifecycleRules = @(
    @{
        Name         = "move-logs-to-cool"
        Enabled      = $true
        Definition   = @{
            Filters = @{
                PrefixMatch = @("logs/"]
                BlobTypes   = @("blockBlob")
            }
            Actions = @{
                BaseBlob = @{
                    TierToCool = @{ DaysAfterModificationGreaterThan = 30 }
                    TierToArchive = @{ DaysAfterModificationGreaterThan = 90 }
                    Delete = @{ DaysAfterModificationGreaterThan = 365 }
                }
            }
        }
    }
    @{
        Name         = "archive-old-backups"
        Enabled      = $true
        Definition   = @{
            Filters = @{
                PrefixMatch = @("backups/"]
                BlobTypes   = @("blockBlob")
            }
            Actions = @{
                BaseBlob = @{
                    TierToArchive = @{ DaysAfterModificationGreaterThan = 60 }
                    Delete = @{ DaysAfterModificationGreaterThan = 180 }
                }
            }
        }
    }
)

# 应用生命周期策略
$policy = Set-AzStorageAccountManagementPolicy `
    -ResourceGroupName "blog-storage-rg" `
    -StorageAccountName "stbloghotprod" `
    -Policy (@{ Rules = $lifecycleRules } | ConvertTo-Json -Depth 10 | ConvertFrom-Json)

Write-Host "已配置 $($lifecycleRules.Count) 条生命周期管理规则"

# 查看各容器中的 Blob 层级分布
$containers = @("images", "documents", "logs", "backups")
foreach ($containerName in $containers) {
    $blobs = Get-AzStorageBlob -Container $containerName -Context $ctx `
        -ErrorAction SilentlyContinue
    $total = ($blobs | Measure-Object).Count
    $totalSize = ($blobs | ForEach-Object { $_.Length } | Measure-Object -Sum).Sum
    $sizeMB = if ($totalSize) { '{0:N2}' -f ($totalSize / 1MB) } else { '0.00' }
    Write-Host "容器 $containerName : $total 个 Blob, 总计 $sizeMB MB"
}
```

执行结果示例：

```
已创建文件共享: blog-shared-assets
已上传到文件共享: architecture-diagram.pdf
已上传到文件共享: deployment-guide.docx
已上传到文件共享: runbook.xlsx
SAS 令牌已生成（7 天只读）:
?sv=2024-08-03&ss=bf&srt=sco&sp=r ...
已配置 2 条生命周期管理规则
容器 images : 3 个 Blob, 总计 0.25 MB
容器 documents : 12 个 Blob, 总计 8.45 MB
容器 logs : 156 个 Blob, 总计 234.67 MB
容器 backups : 28 个 Blob, 总计 1024.33 MB
```

## 存储分析与监控

持续监控存储使用情况和访问模式是控制云成本的关键。通过 `Az.Storage` 和 `Az.Monitor` 模块，可以自动化查询存储指标、分析访问日志，并生成成本报告。下面的脚本演示了如何收集这些信息并输出结构化的分析结果。

```powershell
# 获取存储账户信息
$resourceGroup = "blog-storage-rg"
$storageAccountName = "stbloghotprod"
$storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroup `
    -Name $storageAccountName
$ctx = $storageAccount.Context

# 查询存储账户的容量和使用情况
$usage = Get-AzStorageUsage -Location $storageAccount.Location
Write-Host "`n=== 存储账户配额使用情况 ==="
foreach ($u in $usage) {
    $pct = if ($u.Limit -gt 0) { '{0:P1}' -f ($u.CurrentValue / $u.Limit) } else { 'N/A' }
    Write-Host ("{0,-40} {1,6}/{2,6} ({3})" -f $u.Name.Value, `
        $u.CurrentValue, $u.Limit, $pct)
}

# 启用 Blob 服务的访问日志（如尚未启用）
$logging = $ctx.Logging
if (-not $logging.LoggingOperations -contains "Read") {
    Set-AzStorageServiceLoggingProperty -ServiceType Blob `
        -LoggingOperations Read,Write,Delete `
        -RetentionDays 30 `
        -Context $ctx
    Write-Host "`n已启用 Blob 访问日志（保留 30 天）"
}

# 查询最近的存储指标
$endTime = Get-Date
$startTime = $endTime.AddDays(-7)
$metricNames = @("UsedCapacity", "TransactionCount", "Ingress", "Egress")

Write-Host "`n=== 最近 7 天存储指标 ==="
foreach ($metric in $metricNames) {
    $metrics = Get-AzMetric -ResourceId $storageAccount.Id `
        -MetricName $metric `
        -StartTime $startTime `
        -EndTime $endTime `
        -AggregationType Total `
        -ErrorAction SilentlyContinue

    if ($metrics) {
        $data = $metrics.Data | Where-Object { $_.Total -gt 0 } | Select-Object -Last 1
        if ($data) {
            $value = switch ($metric) {
                "UsedCapacity"     { '{0:N2} GB' -f ($data.Total / 1GB) }
                "TransactionCount" { '{0:N0}' -f $data.Total }
                "Ingress"          { '{0:N2} MB' -f ($data.Total / 1MB) }
                "Egress"           { '{0:N2} MB' -f ($data.Total / 1MB) }
            }
            Write-Host ("{0,-25} {1}" -f $metric, $value)
        }
    }
}

# 分析各容器的 Blob 层级和大小分布
Write-Host "`n=== Blob 层级分布 ==="
$containers = Get-AzStorageContainer -Context $ctx
$summary = foreach ($container in $containers) {
    $blobs = Get-AzStorageBlob -Container $container.Name -Context $ctx `
        -ErrorAction SilentlyContinue
    if (-not $blobs) { continue }

    $blobs | Group-Object AccessTier | ForEach-Object {
        $sizeBytes = ($_.Group | ForEach-Object { $_.Length } | Measure-Object -Sum).Sum
        [PSCustomObject]@{
            Container = $container.Name
            Tier      = $_.Name
            Count     = $_.Count
            SizeMB    = [math]::Round($sizeBytes / 1MB, 2)
        }
    }
}

$summary | Format-Table -AutoSize

# 生成成本估算摘要
Write-Host "`n=== 月度成本估算 ==="
$hotBlobs = $summary | Where-Object { $_.Tier -eq "Hot" }
$coolBlobs = $summary | Where-Object { $_.Tier -eq "Cool" }
$archiveBlobs = $summary | Where-Object { $_.Tier -eq "Archive" }

$hotCost = ($hotBlobs | Measure-Object SizeMB -Sum).Sum * 0.018 / 1000
$coolCost = ($coolBlobs | Measure-Object SizeMB -Sum).Sum * 0.01 / 1000
$archiveCost = ($archiveBlobs | Measure-Object SizeMB -Sum).Sum * 0.0004 / 1000

Write-Host ("Hot 层存储:    {0,10:N4} USD/月" -f $hotCost)
Write-Host ("Cool 层存储:   {0,10:N4} USD/月" -f $coolCost)
Write-Host ("Archive 层存储:{0,10:N4} USD/月" -f $archiveCost)
Write-Host ("--------------------------")
Write-Host ("合计估算:      {0,10:N4} USD/月" -f ($hotCost + $coolCost + $archiveCost))
```

执行结果示例：

```
=== 存储账户配额使用情况 ===
StorageAccounts                          3/ 250 (1.2%)
已启用 Blob 访问日志（保留 30 天）

=== 最近 7 天存储指标 ===
UsedCapacity                  1.24 GB
TransactionCount              12,456
Ingress                       456.78 MB
Egress                        2345.67 MB

=== Blob 层级分布 ===
Container  Tier Count SizeMB
---------  ---- ----- ------
backups    Hot       28 1024.33
documents  Hot       12    8.45
images     Hot        3    0.25
logs       Hot      156  234.67

=== 月度成本估算 ===
Hot 层存储:      0.0229 USD/月
Cool 层存储:     0.0000 USD/月
Archive 层存储:  0.0000 USD/月
--------------------------
合计估算:        0.0229 USD/月
```

## 注意事项

1. **SkuName 选择**：`Standard_LRS` 适合开发测试，生产环境建议使用 `Standard_ZRS` 或 `Standard_GRS` 以获得更高的数据持久性。`Premium_LRS` 仅支持页 Blob 和文件共享，不支持块 Blob 的访问层分层。

2. **生命周期策略延迟**：生命周期管理规则的应用并非实时生效，Azure 通常每天执行一次策略评估。规则变更后可能需要 24-48 小时才能看到效果，不要误以为配置未生效。

3. **SAS 令牌安全**：生成的 SAS 令牌等同于访问凭证，务必通过安全渠道分发。建议优先使用存储在 Azure Key Vault 中的 SAS 定义，而非在脚本中硬编码令牌。设置最短的有效期以满足业务需求即可。

4. **容器公开访问级别**：`Blob` 级别允许匿名读取单个 Blob，`Container` 级别则允许列出容器内容。默认值 `Off` 最安全，仅在需要公开访问的场景（如静态网站资源）下才开启。

5. **上传大文件分块**：`Set-AzStorageBlobContent` 对大于 256 MB 的文件会自动分块上传，但网络不稳定时建议手动设置 `-ConcurrentTaskCount` 参数来控制并发数，避免上传超时。

6. **成本监控盲区**：`Get-AzMetric` 返回的指标有数分钟到数小时的延迟，不适合做实时成本告警。如需精确的实时成本控制，应配置 Azure Cost Management 的预算告警规则，并通过 `Az.Billing` 模块查询。
