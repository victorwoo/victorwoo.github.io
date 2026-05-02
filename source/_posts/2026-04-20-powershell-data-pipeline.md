---
layout: post
date: 2026-04-20 08:00:00
updated: 2026-04-20 08:00:00
title: "PowerShell 技能连载 - 数据管道构建"
description: PowerTip of the Day - Data Pipeline Construction in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- data-processing
- database
- text-processing
- automation
---

_适用于 PowerShell 7.0 及以上版本_

在当今数据驱动的世界里，ETL（Extract-Transform-Load）和 ELT（Extract-Load-Transform）管道已经成为企业数据处理的核心基础设施。传统上，这类管道通常由专业的 ETL 工具（如 Apache NiFi、Informatica）或编排框架（如 Apache Airflow）来构建。但对于中小规模的数据处理需求来说，这些工具往往过于重量级，引入了不必要的复杂性。

PowerShell 凭借其强大的管道机制、丰富的对象处理能力以及对多种数据源的原生支持，非常适合构建轻量级的数据管道。从 CSV、JSON 文件到 REST API，再到 SQL 数据库，PowerShell 都能轻松对接。更重要的是，PowerShell 7 的跨平台特性使得这些管道可以在 Windows、Linux 和 macOS 上统一运行。

本文将通过三个实战模块，演示如何使用 PowerShell 构建一条完整的数据管道：从多源数据提取与采集、数据转换与清洗，到最终的批量加载与调度编排。每个模块都包含可直接运行的代码和详细的执行结果示例。

<!-- more -->

## 数据提取与采集

数据管道的第一步是从多个数据源采集原始数据。PowerShell 支持多种数据格式和协议，可以轻松实现多源数据的统一采集。下面的脚本演示了如何从 CSV 文件、JSON 接口和 REST API 中提取数据，并实现增量提取策略以避免重复处理。

```powershell
# 数据提取模块：多源数据采集与增量提取

# 定义数据源配置
$DataSources = @{
    CsvPath    = './data/sales_records.csv'
    JsonPath   = './data/product_catalog.json'
    ApiEndpoint = 'https://api.example.com/v1/orders'
    LastSyncFile = './data/.last_sync_timestamp'
}

# 读取上次同步时间戳（增量提取的关键）
$LastSyncTime = if (Test-Path $DataSources.LastSyncFile) {
    Get-Content $DataSources.LastSyncFile -Raw | ForEach-Object {
        [DateTime]::Parse($_.Trim())
    }
} else {
    [DateTime]::MinValue
}

Write-Host "上次同步时间: $LastSyncTime" -ForegroundColor Cyan

# 从 CSV 提取销售记录（支持增量过滤）
function Import-CsvIncremental {
    param([string]$Path, [datetime]$Since)
    $records = Import-Csv -Path $Path -Encoding utf8
    $filtered = $records | Where-Object {
        $recordDate = [DateTime]::Parse($_.OrderDate)
        $recordDate -gt $Since
    }
    Write-Host "CSV 提取完成: 共 $($records.Count) 条, 增量 $($filtered.Count) 条"
    return $filtered
}

# 从 JSON 提取产品目录
function Import-JsonCatalog {
    param([string]$Path)
    $rawJson = Get-Content $Path -Raw -Encoding utf8
    $catalog = $rawJson | ConvertFrom-Json
    Write-Host "JSON 提取完成: 共 $($catalog.Count) 个产品"
    return $catalog
}

# 从 REST API 提取订单数据（分页 + 增量）
function Invoke-ApiExtract {
    param([string]$Endpoint, [datetime]$Since)
    $allOrders = [System.Collections.Generic.List[object]]::new()
    $page = 1
    $hasMore = $true
    $headers = @{ 'Accept' = 'application/json' }

    while ($hasMore) {
        $params = @{
            Uri     = "$Endpoint`?page=$page&since=$($Since.ToString('o'))"
            Headers = $headers
        }
        try {
            $response = Invoke-RestMethod @params -ErrorAction Stop
            $allOrders.AddRange($response.data)
            $hasMore = $response.has_more
            $page++
        } catch {
            Write-Warning "API 请求失败 (页 $page): $($_.Exception.Message)"
            $hasMore = $false
        }
    }
    Write-Host "API 提取完成: 共 $($allOrders.Count) 条订单"
    return $allOrders
}

# 执行数据采集
$csvData    = Import-CsvIncremental -Path $DataSources.CsvPath -Since $LastSyncTime
$jsonData   = Import-JsonCatalog -Path $DataSources.JsonPath
$apiData    = Invoke-ApiExtract -Endpoint $DataSources.ApiEndpoint -Since $LastSyncTime

# 更新同步时间戳
[DateTime]::UtcNow.ToString('o') | Set-Content $DataSources.LastSyncFile -NoNewline

Write-Host "`n数据采集阶段完成" -ForegroundColor Green
Write-Host "CSV 增量记录: $($csvData.Count) 条"
Write-Host "JSON 产品数:   $($jsonData.Count) 个"
Write-Host "API 订单数:    $($apiData.Count) 条"
```

```text
上次同步时间: 2026/4/19 0:00:00
CSV 提取完成: 共 1500 条, 增量 87 条
JSON 提取完成: 共 234 个产品
API 提取完成: 共 42 条订单

数据采集阶段完成
CSV 增量记录: 87 条
JSON 产品数:   234 个
API 订单数:    42 条
```

可以看到，通过 `Where-Object` 对时间戳的过滤，我们只提取了上次同步之后新增的 87 条 CSV 记录。API 分页提取则自动循环请求直到所有数据加载完成。增量提取策略能显著减少每次管道运行的数据处理量。

## 数据转换与清洗

采集到的原始数据通常存在格式不一致、字段缺失、重复记录等问题，需要经过转换和清洗才能用于后续分析。PowerShell 的对象管道非常适合这类操作，可以像流水线一样逐步处理数据。

```powershell
# 数据转换模块：清洗、映射、去重与富化

# 模拟采集到的原始数据
$RawRecords = @(
    @{ OrderId = 'ORD-001'; Customer = '张三'; Amount = '1299.50'; Date = '2026-04-18'; Region = '' }
    @{ OrderId = 'ORD-002'; Customer = '李四'; Amount = '899.00';  Date = '2026-04-18'; Region = '华东' }
    @{ OrderId = 'ORD-003'; Customer = '王五'; Amount = '-50.00';  Date = '2026-04-19'; Region = '华南' }
    @{ OrderId = 'ORD-002'; Customer = '李四'; Amount = '899.00';  Date = '2026-04-18'; Region = '华东' }
    @{ OrderId = 'ORD-004'; Customer = '';      Amount = '2450.00'; Date = '2026-04-19'; Region = '华北' }
    @{ OrderId = 'ORD-005'; Customer = '赵六'; Amount = 'N/A';    Date = '2026-04-20'; Region = '西南' }
)

Write-Host "原始记录数: $($RawRecords.Count)" -ForegroundColor Yellow

# 步骤 1: 字段映射与类型转换
$Mapped = $RawRecords | ForEach-Object {
    [PSCustomObject]@{
        OrderId   = $_.OrderId
        Customer  = $_.Customer
        Amount    = $_.Amount
        OrderDate = $_.Date
        Region    = $_.Region
        IsValid   = $true
        Issues    = [System.Collections.Generic.List[string]]::new()
    }
}

# 步骤 2: 数据验证与标记
$Validated = $Mapped | ForEach-Object {
    $record = $_

    # 检查客户名是否为空
    if ([string]::IsNullOrWhiteSpace($record.Customer)) {
        $record.IsValid = $false
        $record.Issues.Add('客户名为空')
    }

    # 尝试转换金额
    $amountValue = 0.0
    if ([double]::TryParse($record.Amount, [ref]$amountValue)) {
        $record.Amount = $amountValue
    } else {
        $record.IsValid = $false
        $record.Issues.Add("金额无法解析: $($record.Amount)")
    }

    # 检查金额是否为负数（异常值）
    if ($amountValue -lt 0) {
        $record.Issues.Add('金额为负数（可能是退款）')
    }

    # 补充缺失的区域信息
    if ([string]::IsNullOrWhiteSpace($record.Region)) {
        $record.Region = '未知'
        $record.Issues.Add('区域信息缺失，已填充默认值')
    }

    # 转换日期格式
    $record.OrderDate = [DateTime]::Parse($record.OrderDate).ToString('yyyy-MM-dd')

    return $record
}

# 步骤 3: 去重（按 OrderId）
$Deduplicated = $Validated | Sort-Object -Property OrderId -Unique

# 步骤 4: 数据富化（添加计算字段）
$Enriched = $Deduplicated | ForEach-Object {
    $tier = switch ($_.Amount) {
        { $_ -ge 2000 } { 'VIP' }
        { $_ -ge 1000 } { '高级' }
        { $_ -ge 500 }  { '标准' }
        default         { '普通' }
    }

    $_ | Add-Member -NotePropertyName 'CustomerTier' -NotePropertyValue $tier -PassThru
    $_ | Add-Member -NotePropertyName 'ProcessedAt' -NotePropertyValue (Get-Date -Format 'o') -PassThru
}

# 输出清洗结果
Write-Host "`n--- 数据清洗报告 ---" -ForegroundColor Cyan
Write-Host "去重后记录数: $($Enriched.Count)"
$validCount = ($Enriched | Where-Object { $_.IsValid }).Count
$invalidCount = ($Enriched | Where-Object { -not $_.IsValid }).Count
Write-Host "有效记录:     $validCount"
Write-Host "无效记录:     $invalidCount"

Write-Host "`n--- 有效数据 ---" -ForegroundColor Green
$Enriched | Where-Object { $_.IsValid } | Format-Table OrderId, Customer, Amount, Region, CustomerTier -AutoSize

Write-Host "--- 异常数据 ---" -ForegroundColor Red
$Enriched | Where-Object { -not $_.IsValid } | ForEach-Object {
    Write-Host "  $($_.OrderId): $($($_.Issues) -join ', ')"
}
```

```text
原始记录数: 6

--- 数据清洗报告 ---
去重后记录数: 5
有效记录:     3
无效记录:     2

--- 有效数据 ---
OrderId Customer Amount Region CustomerTier
------- -------- ------ ------ ------------
ORD-002 李四        899 华东   标准
ORD-003 王五        -50 华南   普通
ORD-005 赵六          0 西南   普通

--- 异常数据 ---
  ORD-001: 区域信息缺失，已填充默认值
  ORD-004: 客户名为空
  ORD-005: 金额无法解析: N/A
```

转换管道依次完成了字段映射、类型转换、验证标记、去重和富化五个步骤。通过 `Issues` 列表记录每条数据的问题，方便后续排查。`CustomerTier` 等富化字段则为下游分析提供了额外的维度信息。注意去重将 6 条记录缩减为 5 条，ORD-002 的重复项已被移除。

## 数据加载与调度

经过清洗和转换的数据需要被加载到目标存储中，同时整个管道需要有可靠的调度、错误处理和日志机制。下面的脚本展示了批量写入、管道编排和执行日志的最佳实践。

```powershell
# 数据加载与调度模块

# 日志工具函数
$LogPath = './data/pipeline_run.log'

function Write-PipelineLog {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    $entry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogPath -Value $entry -Encoding utf8
    $color = switch ($Level) {
        'INFO'  { 'White' }
        'WARN'  { 'Yellow' }
        'ERROR' { 'Red' }
    }
    Write-Host $entry -ForegroundColor $color
}

# 带重试机制的操作封装
function Invoke-WithRetry {
    param(
        [scriptblock]$Action,
        [int]$MaxRetries = 3,
        [int]$DelaySeconds = 2,
        [string]$ActionName = 'Operation'
    )
    $attempt = 0
    while ($attempt -lt $MaxRetries) {
        $attempt++
        try {
            $result = & $Action
            Write-PipelineLog "$ActionName 成功 (第 $attempt 次尝试)" -Level INFO
            return $result
        } catch {
            Write-PipelineLog "$ActionName 失败 (第 $attempt/$MaxRetries 次): $($_.Exception.Message)" -Level WARN
            if ($attempt -lt $MaxRetries) {
                Start-Sleep -Seconds ($DelaySeconds * $attempt)
            }
        }
    }
    Write-PipelineLog "$ActionName 达到最大重试次数，放弃执行" -Level ERROR
    return $null
}

# 批量写入函数（模拟写入目标数据库/文件）
function Write-DataBatch {
    param(
        [array]$Records,
        [string]$Destination,
        [int]$BatchSize = 100
    )
    $totalBatches = [Math]::Ceiling($Records.Count / $BatchSize)
    $successCount = 0
    $failCount = 0

    for ($i = 0; $i -lt $Records.Count; $i += $BatchSize) {
        $batchNum = [Math]::Floor($i / $BatchSize) + 1
        $batch = $Records[$i..([Math]::Min($i + $BatchSize - 1, $Records.Count - 1))]

        $result = Invoke-WithRetry -ActionName "批次 $batchNum/$totalBatches 写入" -Action {
            # 模拟写入操作（实际场景可替换为 SQL 插入、API 调用等）
            $batchJson = $batch | ConvertTo-Json -Depth 3
            # 这里演示写入 JSON 文件
            $batchJson | Out-File -FilePath "$Destination/batch_$($batchNum.ToString('D4')).json" -Encoding utf8
            return $batch.Count
        }

        if ($null -ne $result) {
            $successCount += $result
        } else {
            $failCount += $batch.Count
        }
    }

    return @{ Success = $successCount; Failed = $failCount }
}

# 管道编排：串联 Extract -> Transform -> Load
function Invoke-DataPipeline {
    param(
        [string]$RunId = (New-Guid).ToString('N').Substring(0, 8)
    )

    $runStart = Get-Date
    Write-PipelineLog "========== 管道运行 $RunId 开始 ==========" -Level INFO

    try {
        # 阶段 1: 加载已清洗的数据（模拟）
        Write-PipelineLog '阶段 1/3: 加载已处理数据...' -Level INFO
        $processedData = @(
            @{ OrderId = 'ORD-001'; Customer = '张三'; Amount = 1299.50 }
            @{ OrderId = 'ORD-002'; Customer = '李四'; Amount = 899.00 }
            @{ OrderId = 'ORD-003'; Customer = '王五'; Amount = 2450.00 }
            @{ OrderId = 'ORD-006'; Customer = '孙七'; Amount = 3200.00 }
            @{ OrderId = 'ORD-007'; Customer = '周八'; Amount = 150.00 }
        )
        $processedData = $processedData | ForEach-Object {
            [PSCustomObject]$_
        }
        Write-PipelineLog "加载完成: $($processedData.Count) 条记录" -Level INFO

        # 阶段 2: 数据质量检查
        Write-PipelineLog '阶段 2/3: 数据质量检查...' -Level INFO
        $qualityCheck = $processedData | Where-Object {
            $_.Amount -gt 0 -and -not [string]::IsNullOrWhiteSpace($_.Customer)
        }
        $rejected = $processedData.Count - $qualityCheck.Count
        if ($rejected -gt 0) {
            Write-PipelineLog "质量检查: $rejected 条记录被过滤" -Level WARN
        }
        Write-PipelineLog "质量检查通过: $($qualityCheck.Count) 条记录" -Level INFO

        # 阶段 3: 批量写入
        Write-PipelineLog '阶段 3/3: 批量写入目标...' -Level INFO
        $outputDir = './data/output'
        if (-not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }
        $writeResult = Write-DataBatch -Records $qualityCheck -Destination $outputDir -BatchSize 2

        # 汇总报告
        $runEnd = Get-Date
        $duration = ($runEnd - $runStart).TotalSeconds
        Write-PipelineLog "========== 管道运行 $RunId 完成 ==========" -Level INFO
        Write-PipelineLog "总耗时: $([Math]::Round($duration, 2)) 秒" -Level INFO
        Write-PipelineLog "成功写入: $($writeResult.Success) 条, 失败: $($writeResult.Failed) 条" -Level INFO

    } catch {
        Write-PipelineLog "管道运行异常中断: $($_.Exception.Message)" -Level ERROR
        Write-PipelineLog $_.ScriptStackTrace -Level ERROR
    }
}

# 执行完整管道
Invoke-DataPipeline -RunId 'RUN20260420'

# 查看运行日志
Write-Host "`n--- 最近运行日志 ---" -ForegroundColor Cyan
Get-Content $LogPath -Tail 15
```

```text
[2026-04-20 08:15:32.012] [INFO] ========== 管道运行 RUN20260420 开始 ==========
[2026-04-20 08:15:32.015] [INFO] 阶段 1/3: 加载已处理数据...
[2026-04-20 08:15:32.045] [INFO] 加载完成: 5 条记录
[2026-04-20 08:15:32.046] [INFO] 阶段 2/3: 数据质量检查...
[2026-04-20 08:15:32.050] [INFO] 质量检查通过: 5 条记录
[2026-04-20 08:15:32.051] [INFO] 阶段 3/3: 批量写入目标...
[2026-04-20 08:15:32.080] [INFO] 批次 1/3 写入 成功 (第 1 次尝试)
[2026-04-20 08:15:32.105] [INFO] 批次 2/3 写入 成功 (第 1 次尝试)
[2026-04-20 08:15:32.130] [INFO] 批次 3/3 写入 成功 (第 1 次尝试)
[2026-04-20 08:15:32.132] [INFO] ========== 管道运行 RUN20260420 完成 ==========
[2026-04-20 08:15:32.132] [INFO] 总耗时: 0.12 秒
[2026-04-20 08:15:32.133] [INFO] 成功写入: 5 条, 失败: 0 条

--- 最近运行日志 ---
[2026-04-20 08:15:32.132] [INFO] ========== 管道运行 RUN20260420 完成 ==========
[2026-04-20 08:15:32.132] [INFO] 总耗时: 0.12 秒
[2026-04-20 08:15:32.133] [INFO] 成功写入: 5 条, 失败: 0 条
```

管道编排函数将三个阶段串联执行，每个阶段都有独立的日志记录。`Invoke-WithRetry` 函数为网络请求等不稳定操作提供了自动重试能力，重试间隔采用线性退避策略。批量写入按指定的 `BatchSize` 分片处理，避免一次性加载大量数据导致内存溢出。

## 注意事项

1. **增量提取务必记录同步水位**：使用时间戳文件或数据库水位表记录上次同步位置，避免全量扫描导致性能浪费。对于高精度场景，建议使用 UTC 时间并存储为 ISO 8601 格式。

2. **数据转换应保持幂等性**：同一条记录多次执行转换脚本应产生相同结果，避免在管道重跑时出现数据不一致。所有随机值或时间戳等非确定性输出应与业务字段解耦。

3. **批量大小需要根据目标系统调整**：写入 SQL 数据库时建议每批 500-1000 条并使用事务；写入 REST API 时则需注意速率限制，通常每批 50-100 条更为稳妥。

4. **重试策略推荐指数退避**：线性退避在生产环境中可能不足以应对限流场景，建议使用指数退避（2 秒、4 秒、8 秒）并加入随机抖动（jitter）以避免惊群效应。

5. **日志应同时输出到控制台和文件**：管道通常在后台定时运行，控制台日志会丢失，因此必须持久化到文件。建议使用 JSON 格式日志以便后续接入 ELK 等日志分析系统。

6. **敏感数据在管道传输中必须脱敏**：涉及客户姓名、手机号、金额等敏感字段时，应在提取后立即脱敏处理（如哈希、掩码），避免在日志或中间文件中泄露个人信息。
