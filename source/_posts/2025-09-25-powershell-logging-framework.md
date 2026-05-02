---
layout: post
date: 2025-09-25 08:00:00
updated: 2025-09-25 08:00:00
title: "PowerShell 技能连载 - 结构化日志框架"
description: PowerTip of the Day - Structured Logging Framework in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- logging
- structured-logging
- monitoring
---

_适用于 PowerShell 5.1 及以上版本_

在生产环境中管理 PowerShell 脚本时，`Write-Host` 和 `Write-Output` 这类简单输出方式很快就会暴露出不足：日志难以检索、无法按级别过滤、缺少上下文信息，更无法与 ELK、Splunk 等日志平台对接。当脚本数量增长到数十个、运行频率从手动变为定时任务时，缺乏结构化日志体系将成为运维效率的最大瓶颈。

结构化日志（Structured Logging）是解决这些问题的核心思路。它要求每条日志都携带固定格式的元数据——时间戳、级别、模块名、消息体以及自定义属性，并以 JSON 等机器可读格式输出。这样就能用 `ConvertFrom-Json` 在脚本内解析，也可以直接推送到日志平台进行全文检索和可视化分析。

本文将从零构建一个轻量但完整的结构化日志框架，涵盖日志级别控制、多目标输出（控制台 + 文件 + JSON 文件）、上下文自动注入、以及运行时的动态配置。

## 框架核心：日志条目数据结构

一切从定义日志条目的数据结构开始。我们用一个 PowerShell class 来承载每条日志的所有字段，确保输出格式始终一致。

```powershell
enum LogLevel {
    Debug
    Information
    Warning
    Error
    Critical
}

class LogEntry {
    [DateTime] $Timestamp
    [LogLevel] $Level
    [string] $Message
    [string] $Module
    [hashtable] $Properties
    [string] $CorrelationId

    LogEntry(
        [LogLevel] $Level,
        [string] $Message,
        [string] $Module,
        [hashtable] $Properties,
        [string] $CorrelationId
    ) {
        $this.Timestamp = Get-Date
        $this.Level = $Level
        $this.Message = $Message
        $this.Module = $Module
        $this.Properties = $Properties
        $this.CorrelationId = $CorrelationId
    }

    [hashtable] ToHashtable() {
        $ht = [ordered]@{
            timestamp      = $this.Timestamp.ToString('o')
            level          = $this.Level.ToString()
            module         = $this.Module
            message        = $this.Message
            correlationId  = $this.CorrelationId
        }
        foreach ($key in $this.Properties.Keys) {
            $ht[$key] = $this.Properties[$key]
        }
        return $ht
    }

    [string] ToJson() {
        return $this.ToHashtable() | ConvertTo-Json -Compress
    }
}
```

上面的代码定义了五个日志级别和一个 `LogEntry` 类。`ToHashtable()` 方法将日志转为有序哈希表，方便进一步处理；`ToJson()` 则输出紧凑的 JSON 字符串，可直接写入日志文件或发送到 HTTP 端点。注意这里使用 `foreach` 语句遍历属性字典，将自定义字段合并到输出中。

## 日志写入器：支持多目标输出

有了数据结构之后，需要实现写入器（Writer）来决定日志输出到哪里。下面定义三个写入器：控制台（带颜色）、纯文本文件、以及 JSON 文件。写入器通过注册机制挂载到框架中，运行时可动态增减。

```powershell
class LoggerConfig {
    [LogLevel] $MinimumLevel = [LogLevel]::Information
    [string] $LogDirectory = '.\logs'
    [string] $ApplicationName = 'PowerShellApp'
    [string] $CorrelationId = ''
    [System.Collections.Generic.List[scriptblock]] $Writers

    LoggerConfig() {
        $this.Writers = [System.Collections.Generic.List[scriptblock]]::new()
        if (-not $this.CorrelationId) {
            $this.CorrelationId = [guid]::NewGuid().ToString('N').Substring(0, 8)
        }
    }
}

function New-Logger {
    param(
        [LogLevel] $MinimumLevel = [LogLevel]::Information,
        [string] $LogDirectory = '.\logs',
        [string] $ApplicationName = 'PowerShellApp'
    )
    $config = [LoggerConfig]::new()
    $config.MinimumLevel = $MinimumLevel
    $config.LogDirectory = $LogDirectory
    $config.ApplicationName = $ApplicationName

    # 控制台写入器
    $config.Writers.Add({
        param($Entry)
        $colorMap = @{
            Debug       = 'DarkGray'
            Information = 'White'
            Warning     = 'Yellow'
            Error       = 'Red'
            Critical    = 'Magenta'
        }
        $color = $colorMap[$Entry.Level.ToString()]
        Write-Host -ForegroundColor $color (
            "[$($Entry.Timestamp.ToString('HH:mm:ss'))] " +
            "[$($Entry.Level)] [$($Entry.Module)] $($Entry.Message)"
        )
    }.GetNewClosure())

    # JSON 文件写入器
    $config.Writers.Add({
        param($Entry, $Config)
        $dir = $Config.LogDirectory
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        $dateStr = (Get-Date).ToString('yyyyMMdd')
        $filePath = Join-Path $dir "$($Config.ApplicationName)-$dateStr.jsonl"
        $Entry.ToJson() | Add-Content -Path $filePath -Encoding UTF8
    }.GetNewClosure())

    return $config
}
```

这段代码的核心是 `LoggerConfig` 类：它保存全局配置（最低级别、日志目录、应用名称、关联 ID）和一个写入器列表。`New-Logger` 函数创建配置实例并默认注册两个写入器——控制台和 JSONL 文件。JSONL（JSON Lines）格式每行一条 JSON 记录，非常适合日志场景，追加写入效率高，读取时逐行 `ConvertFrom-Json` 即可。

## 发送日志与上下文注入

有了配置和写入器，现在实现发送日志的核心函数。它会自动过滤低于最低级别的消息，并注入运行时上下文。

```powershell
function Send-Log {
    param(
        [Parameter(Mandatory)]
        [LoggerConfig] $Config,

        [Parameter(Mandatory)]
        [LogLevel] $Level,

        [Parameter(Mandatory)]
        [string] $Message,

        [string] $Module = 'General',

        [hashtable] $Properties = @{}
    )

    # 级别过滤
    if ($Level -lt $Config.MinimumLevel) {
        return
    }

    # 自动注入上下文属性
    $Properties['host'] = $env:COMPUTERNAME
    $Properties['user'] = $env:USERNAME
    $Properties['psVersion'] = $PSVersionTable.PSVersion.ToString()

    $entry = [LogEntry]::new(
        $Level,
        $Message,
        $Module,
        $Properties,
        $Config.CorrelationId
    )

    foreach ($writer in $Config.Writers) {
        try {
            & $writer $entry $Config
        } catch {
            Write-Warning "日志写入器执行失败: $($_.Exception.Message)"
        }
    }
}

# 便捷函数
function Write-LogDebug {
    param([LoggerConfig] $Config, [string] $Message, [string] $Module = 'General', [hashtable] $Properties = @{})
    Send-Log -Config $Config -Level Debug -Message $Message -Module $Module -Properties $Properties
}

function Write-LogInfo {
    param([LoggerConfig] $Config, [string] $Message, [string] $Module = 'General', [hashtable] $Properties = @{})
    Send-Log -Config $Config -Level Information -Message $Message -Module $Module -Properties $Properties
}

function Write-LogWarning {
    param([LoggerConfig] $Config, [string] $Message, [string] $Module = 'General', [hashtable] $Properties = @{})
    Send-Log -Config $Config -Level Warning -Message $Message -Module $Module -Properties $Properties
}

function Write-LogError {
    param([LoggerConfig] $Config, [string] $Message, [string] $Module = 'General', [hashtable] $Properties = @{})
    Send-Log -Config $Config -Level Error -Message $Message -Module $Module -Properties $Properties
}

function Write-LogCritical {
    param([LoggerConfig] $Config, [string] $Message, [string] $Module = 'General', [hashtable] $Properties = @{})
    Send-Log -Config $Config -Level Critical -Message $Message -Module $Module -Properties $Properties
}
```

`Send-Log` 在创建日志条目前自动注入主机名、用户名和 PowerShell 版本三个上下文字段。通过 `foreach` 语句遍历所有注册的写入器并逐一执行，单个写入器失败不会影响其他写入器。五个便捷函数封装了对应的日志级别，调用时无需手动指定 `-Level` 参数。

## 实战：在脚本中使用日志框架

下面模拟一个典型的文件处理脚本，展示日志框架的完整使用方式。

```powershell
# 初始化日志框架（Debug 级别，开发阶段能看到所有日志）
$logger = New-Logger -MinimumLevel Debug -LogDirectory '.\logs' -ApplicationName 'FileProcessor'

Write-LogInfo -Config $logger -Message '文件处理任务启动' -Module 'Main' -Properties @{
    taskType = 'BatchImport'
    sourcePath = 'D:\Data\Incoming'
}

# 模拟处理一批文件
$files = @('report-q3.csv', 'inventory.json', 'customers.xlsx', 'orders-corrupt.bad')

foreach ($file in $files) {
    Write-LogDebug -Config $logger -Message "开始处理文件: $file" -Module 'FileHandler' -Properties @{
        fileName = $file
        fileSize = (Get-Random -Minimum 1024 -Maximum 10485760)
    }

    if ($file -match 'corrupt') {
        Write-LogError -Config $logger -Message "文件损坏，跳过处理: $file" -Module 'FileHandler' -Properties @{
            fileName = $file
            errorCode = 'CORRUPT_HEADER'
            recoverable = $false
        }
        continue
    }

    Write-LogInfo -Config $logger -Message "文件处理完成: $file" -Module 'FileHandler' -Properties @{
        fileName = $file
        rowsProcessed = (Get-Random -Minimum 100 -Maximum 5000)
        durationMs = (Get-Random -Minimum 50 -Maximum 2000)
    }
}

Write-LogWarning -Config $logger -Message '批次处理结束，存在跳过的文件' -Module 'Main' -Properties @{
    totalFiles = $files.Count
    successCount = ($files | Where-Object { $_ -notmatch 'corrupt' }).Count
    skippedCount = 1
}

Write-LogInfo -Config $logger -Message '文件处理任务完成' -Module 'Main'
```

模拟执行结果如下：

```
[14:30:01] [Information] [Main] 文件处理任务启动
[14:30:01] [Debug] [FileHandler] 开始处理文件: report-q3.csv
[14:30:01] [Information] [FileHandler] 文件处理完成: report-q3.csv
[14:30:01] [Debug] [FileHandler] 开始处理文件: inventory.json
[14:30:02] [Information] [FileHandler] 文件处理完成: inventory.json
[14:30:02] [Debug] [FileHandler] 开始处理文件: customers.xlsx
[14:30:02] [Information] [FileHandler] 文件处理完成: customers.xlsx
[14:30:02] [Debug] [FileHandler] 开始处理文件: orders-corrupt.bad
[14:30:02] [Error] [FileHandler] 文件损坏，跳过处理: orders-corrupt.bad
[14:30:02] [Warning] [Main] 批次处理结束，存在跳过的文件
[14:30:02] [Information] [Main] 文件处理任务完成
```

同时，在 `.\logs` 目录下会生成类似 `FileProcessor-20250925.jsonl` 的文件，每行是一条完整的 JSON 日志。下面是其中一行记录的格式化展示：

```
{"timestamp":"2025-09-25T14:30:02.1234567+08:00","level":"Error","module":"FileHandler","message":"文件损坏，跳过处理: orders-corrupt.bad","correlationId":"a3f8c1d2","fileName":"orders-corrupt.bad","errorCode":"CORRUPT_HEADER","recoverable":false,"host":"WORKSTATION01","user":"admin","psVersion":"7.4.0"}
```

## 查询与分析结构化日志

结构化日志最大的优势在于可以用标准工具进行查询。下面的函数演示如何快速检索 JSONL 日志文件。

```powershell
function Search-LogArchive {
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [ValidateSet('Debug', 'Information', 'Warning', 'Error', 'Critical')]
        [string] $Level,

        [string] $Module,

        [string] $MessagePattern,

        [DateTime] $After,

        [int] $Latest = 50
    )

    $records = [System.Collections.Generic.List[psobject]]::new()

    $lines = Get-Content -Path $Path -Encoding UTF8

    foreach ($line in $lines) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }

        try {
            $obj = $line | ConvertFrom-Json
        } catch {
            continue
        }

        # 按条件过滤
        if ($Level -and $obj.level -ne $Level) { continue }
        if ($Module -and $obj.module -ne $Module) { continue }
        if ($MessagePattern -and $obj.message -notmatch $MessagePattern) { continue }
        if ($After -and [DateTime]$obj.timestamp -lt $After) { continue }

        $records.Add($obj)
    }

    # 按时间排序并取最近的记录
    $results = $records | Sort-Object { $_.timestamp } -Descending |
        Select-Object -First $Latest

    return $results
}

# 使用示例：查询今天所有 Error 级别的日志
$errors = Search-LogArchive -Path '.\logs\FileProcessor-20250925.jsonl' -Level Error

foreach ($err in $errors) {
    Write-Host "[$($err.timestamp)] $($err.message) (module=$($err.module), errorCode=$($err.errorCode))"
}
```

查询结果示例：

```
[2025-09-25T14:30:02.1234567+08:00] 文件损坏，跳过处理: orders-corrupt.bad (module=FileHandler, errorCode=CORRUPT_HEADER)
```

`Search-LogArchive` 函数逐行读取 JSONL 文件，使用 `ConvertFrom-Json` 解析每条记录后按条件过滤。支持按级别、模块、消息模式和时间范围过滤，返回最近的 N 条匹配记录。由于使用 `foreach` 语句逐行处理，即使是几十 MB 的日志文件也能保持较低的内存占用。

## 动态调整日志级别

在生产环境中，经常需要在不重启服务的情况下调整日志级别来排查问题。下面实现一个简单的运行时级别切换机制。

```powershell
function Set-LoggerLevel {
    param(
        [Parameter(Mandatory)]
        [LoggerConfig] $Config,

        [Parameter(Mandatory)]
        [LogLevel] $Level
    )

    $oldLevel = $Config.MinimumLevel
    $Config.MinimumLevel = $Level

    # 级别变更本身也记录到日志中
    Send-Log -Config $Config -Level Information -Message "日志级别已变更" `
        -Module 'Logger' -Properties @{
        oldLevel = $oldLevel.ToString()
        newLevel = $Level.ToString()
        changedBy = $env:USERNAME
    }
}

# 正常运行时使用 Information 级别
$logger = New-Logger -MinimumLevel Information -ApplicationName 'WebMonitor'

Write-LogInfo -Config $logger -Message '站点健康检查通过' -Module 'HealthCheck'
Write-LogDebug -Config $logger -Message '这条不会输出' -Module 'HealthCheck'

# 发现异常，临时切换到 Debug 级别排查
Set-LoggerLevel -Config $logger -Level Debug

Write-LogDebug -Config $logger -Message '现在 Debug 日志可见了' -Module 'HealthCheck'

# 排查完毕，恢复到 Information
Set-LoggerLevel -Config $logger -Level Information
```

执行结果：

```
[14:35:10] [Information] [HealthCheck] 站点健康检查通过
[14:35:10] [Information] [Logger] 日志级别已变更
[14:35:10] [Debug] [HealthCheck] 现在 Debug 日志可见了
[14:35:10] [Information] [Logger] 日志级别已变更
```

级别切换操作本身会被记录为一条 Information 日志，包含了变更前后的级别和操作人信息，方便审计追踪。这在多人共享的运维环境中尤为重要。

## 注意事项

- **关联 ID 的使用**：每个 `LoggerConfig` 实例会自动生成一个关联 ID（Correlation ID），在分布式系统中用于串联一次完整请求的所有日志。建议在脚本入口处将此 ID 传递给所有子模块和远程调用。
- **JSONL 与普通 JSON 的选择**：日志文件推荐使用 JSONL 格式（每行一条 JSON），而非 JSON 数组。JSONL 天然支持追加写入，不会因为进程中断导致文件格式损坏，也方便 `Get-Content` 逐行处理。
- **写入器的异常隔离**：`Send-Log` 中对每个写入器都使用了 `try/catch`，确保某个输出目标（如网络端点不可达）不会导致整个日志功能失效。生产环境中务必保留这一保护机制。
- **大日志文件的查询性能**：当日志文件超过 100MB 时，`Get-Content` 会消耗较多内存。建议按日期滚动日志文件，或使用 `System.IO.StreamReader` 进行流式读取。
- **线程安全注意事项**：PowerShell 的 `foreach` 语句和 `Add-Content` 在单一线程（单一 runspace）中是安全的。但如果使用 `ForEach-Object -Parallel` 或 Start-Job 等并发机制，需要额外加锁保护文件写入，否则会出现内容交错。
- **敏感信息过滤**：自动注入的上下文属性（主机名、用户名）可能包含敏感信息。在将日志推送到外部系统之前，建议实现一个脱敏写入器，对指定字段进行掩码处理。
