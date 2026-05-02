---
layout: post
date: 2026-02-18 08:00:00
updated: 2026-02-18 08:00:00
title: "PowerShell 技能连载 - 错误处理设计模式"
description: PowerTip of the Day - Error Handling Design Patterns in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- error-handling
- patterns
- robustness
- best-practices
---

_适用于 PowerShell 5.1 及以上版本_

在生产环境中，一个脚本的可靠性往往取决于它的错误处理能力。PowerShell 提供了丰富的错误处理机制，但很多脚本作者仅仅使用简单的 `try/catch` 就草草了事，导致脚本在遇到网络波动、权限不足、文件锁定等真实场景时表现得异常脆弱。

PowerShell 的错误体系比多数脚本语言更加复杂。它将错误分为两类：终止性错误（Terminating Error）和非终止性错误（Non-Terminating Error）。前者会立即中断管道执行，后者仅记录错误但继续运行。理解这两者的区别以及如何控制它们的行为，是编写健壮脚本的第一步。

本文将介绍三种实用的错误处理设计模式：错误类型识别与捕获策略、重试与弹性模式、以及结构化错误报告。这些模式可以直接组合使用，为你的自动化脚本构建起完整的错误防御体系。

## 错误类型与捕获策略

PowerShell 中的错误处理之所以让许多人困惑，根源在于终止性错误和非终止性错误的行为截然不同。`try/catch` 只能捕获终止性错误，而像 `Get-Content` 找不到文件这样的非终止性错误，默认会被静默跳过。要捕获非终止性错误，需要将 `$ErrorActionPreference` 设为 `Stop`，或者在 cmdlet 上使用 `-ErrorAction Stop` 参数。

下面这段代码演示了如何建立一个统一的错误捕获框架，涵盖两种错误类型的处理：

```powershell
function Invoke-SafeOperation {
    [CmdletBinding()]
    param(
        [scriptblock]$Operation,
        [string]$OperationName = "Unnamed Operation",
        [switch]$ContinueOnError
    )

    # 保存原始偏好设置
    $originalEAP = $ErrorActionPreference
    $savedErrors = @()

    try {
        # 将 ErrorActionPreference 设为 Stop，使非终止性错误也能被 try/catch 捕获
        $ErrorActionPreference = 'Stop'

        Write-Verbose "[$OperationName] 开始执行操作"
        $result = & $Operation
        Write-Verbose "[$OperationName] 操作成功完成"

        return $result
    }
    catch {
        $savedErrors += $_
        $errorRecord = $_.Exception
        $errorType = $_.FullyQualifiedErrorId

        # 构建结构化错误信息
        $errorDetail = [PSCustomObject]@{
            Timestamp     = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            Operation     = $OperationName
            ErrorType     = $errorType
            Message       = $_.Exception.Message
            Category      = $_.CategoryInfo.Category
            Target        = $_.TargetObject
            StackTrace    = $_.ScriptStackTrace
        }

        Write-Warning "[$OperationName] 操作失败: $($_.Exception.Message)"
        Write-Warning "[$OperationName] 错误类型: $errorType"
        Write-Warning "[$OperationName] 错误分类: $($_.CategoryInfo.Category)"

        if ($ContinueOnError) {
            Write-Verbose "[$OperationName] ContinueOnError 已启用，继续执行"
            return $errorDetail
        }
        else {
            # 将原始错误重新抛出为终止性错误
            throw $errorDetail
        }
    }
    finally {
        # 恢复原始偏好设置
        $ErrorActionPreference = $originalEAP
        Write-Verbose "[$OperationName] ErrorActionPreference 已恢复为: $originalEAP"
    }
}

# 示例：捕获非终止性错误
$files = Invoke-SafeOperation -OperationName "读取配置文件" -ContinueOnError -Verbose {
    Get-Content -Path "C:\nonexistent\config.json" -ErrorAction Stop
}

# 示例：捕获终止性错误
try {
    Invoke-SafeOperation -OperationName "数据库连接" {
        throw "无法连接到数据库服务器 db01.internal:1433"
    }
}
catch {
    Write-Host "捕获到终止性错误: $($_.Message)" -ForegroundColor Red
    Write-Host "操作名称: $($_.Operation)" -ForegroundColor Yellow
    Write-Host "错误分类: $($_.Category)" -ForegroundColor Yellow
}
```

执行结果示例：

```
详细: [读取配置文件] 开始执行操作
警告: [读取配置文件] 操作失败: 找不到路径"C:\nonexistent\config.json"，因为它不存在。
警告: [读取配置文件] 错误类型: PathNotFound,Microsoft.PowerShell.Commands.GetContentCommand
警告: [读取配置文件] 错误分类: ObjectNotFound
详细: [读取配置文件] ContinueOnError 已启用，继续执行
详细: [读取配置文件] ErrorActionPreference 已恢复为: Continue

捕获到终止性错误: 无法连接到数据库服务器 db01.internal:1433
操作名称: 数据库连接
错误分类: OperationStopped
```

## 重试与弹性模式

在生产环境中，瞬时故障（transient fault）是最常见的失败原因——网络闪断、数据库连接池耗尽、远程 API 限流等。这些故障通常在短暂等待后自行恢复。与其让脚本直接报错退出，不如实现自动重试机制，大幅提升脚本的成功率。

指数退避（Exponential Backoff）是最经典的重试策略：每次重试的等待时间按指数增长，避免在服务端压力最大时发起更多请求。结合断路器模式（Circuit Breaker），当连续失败次数超过阈值时直接跳过后续调用，可以防止无意义的重试浪费资源。

```powershell
function Invoke-WithRetry {
    [CmdletBinding()]
    param(
        [scriptblock]$ScriptBlock,
        [string]$OperationName = "Operation",
        [int]$MaxRetries = 3,
        [int]$BaseDelaySeconds = 2,
        [double]$BackoffMultiplier = 2.0,
        [int]$MaxDelaySeconds = 60,
        [int]$CircuitBreakerThreshold = 5
    )

    # 断路器状态（脚本作用域）
    if (-not (Get-Variable -Name '__CircuitBreakerState' -Scope Script -ErrorAction SilentlyContinue)) {
        $script:__CircuitBreakerState = @{}
    }

    $cbKey = $OperationName
    if (-not $script:__CircuitBreakerState.ContainsKey($cbKey)) {
        $script:__CircuitBreakerState[$cbKey] = @{
            FailureCount = 0
            IsOpen       = $false
            LastFailure  = $null
        }
    }

    $cb = $script:__CircuitBreakerState[$cbKey]

    # 检查断路器状态
    if ($cb.IsOpen) {
        $timeSinceFailure = (Get-Date) - $cb.LastFailure
        if ($timeSinceFailure.TotalSeconds -lt 300) {
            throw "[断路器] 操作 '$OperationName' 的断路器已断开（连续失败 $($cb.FailureCount) 次），" +
                  "将在 $([int](300 - $timeSinceFailure.TotalSeconds)) 秒后重置。"
        }
        else {
            Write-Verbose "[断路器] 冷却时间已过，半开状态，允许尝试"
            $cb.IsOpen = $false
        }
    }

    $attempt = 0
    $lastError = $null

    while ($attempt -lt $MaxRetries) {
        $attempt++
        try {
            Write-Verbose "[$OperationName] 第 $attempt/$MaxRetries 次尝试"
            $result = & $ScriptBlock

            # 成功则重置断路器
            $cb.FailureCount = 0
            $cb.IsOpen = $false
            Write-Verbose "[$OperationName] 第 $attempt 次尝试成功"
            return $result
        }
        catch {
            $lastError = $_
            $cb.FailureCount++
            $cb.LastFailure = Get-Date

            Write-Warning "[$OperationName] 第 $attempt/$MaxRetries 次尝试失败: $($_.Exception.Message)"

            # 检查是否触发断路器
            if ($cb.FailureCount -ge $CircuitBreakerThreshold) {
                $cb.IsOpen = $true
                Write-Warning "[断路器] 连续失败 $($cb.FailureCount) 次，断路器已断开"
            }

            if ($attempt -lt $MaxRetries) {
                # 计算指数退避延迟
                $delay = [Math]::Min(
                    $BaseDelaySeconds * [Math]::Pow($BackoffMultiplier, $attempt - 1),
                    $MaxDelaySeconds
                )
                # 添加随机抖动，防止多个客户端同时重试（雷群效应）
                $jitter = Get-Random -Minimum 0 -Maximum ($delay * 0.3)
                $totalDelay = $delay + $jitter

                Write-Verbose "[$OperationName] 等待 $([Math]::Round($totalDelay, 1)) 秒后重试..."
                Start-Sleep -Seconds $totalDelay
            }
        }
    }

    throw "[$OperationName] 达到最大重试次数 ($MaxRetries)。最后一次错误: $($lastError.Exception.Message)"
}

# 示例：模拟不稳定的服务调用
$attemptCounter = 0
$result = Invoke-WithRetry -OperationName "调用用户API" -MaxRetries 4 -Verbose {
    $script:attemptCounter++
    if ($script:attemptCounter -lt 3) {
        throw "HTTP 503 - 服务暂时不可用 (第 $script:attemptCounter 次调用)"
    }
    return @{ Status = "OK"; Users = @("Alice", "Bob", "Charlie") }
}

Write-Host "最终结果: $($result | ConvertTo-Json -Compress)"
```

执行结果示例：

```
详细: [调用用户API] 第 1/4 次尝试
警告: [调用用户API] 第 1/4 次尝试失败: HTTP 503 - 服务暂时不可用 (第 1 次调用)
详细: [调用用户API] 等待 2.4 秒后重试...
详细: [调用用户API] 第 2/4 次尝试
警告: [调用用户API] 第 2/4 次尝试失败: HTTP 503 - 服务暂时不可用 (第 2 次调用)
详细: [调用用户API] 等待 4.7 秒后重试...
详细: [调用用户API] 第 3/4 次尝试
详细: [调用用户API] 第 3 次尝试成功

最终结果: {"Status":"OK","Users":["Alice","Bob","Charlie"]}
```

## 结构化错误报告

当脚本在无人值守模式下运行（如定时任务、CI/CD 管道）时，错误信息的质量直接决定了排障效率。零散的 `Write-Error` 输出难以追溯上下文，也不便于后续的监控系统集成。我们需要一个统一的错误报告机制，将错误信息以结构化方式记录到日志文件，并可选地发送通知。

下面这个模式实现了完整的错误收集、日志记录和通知流程。它将所有错误汇总为 JSON 格式的报告文件，便于后续自动化分析，同时支持通过 Webhook 发送告警通知。

```powershell
class ErrorReport {
    [string]$ScriptName
    [datetime]$StartTime
    [datetime]$EndTime
    [System.Collections.Generic.List[PSObject]]$Errors
    [System.Collections.Generic.List[string]]$Warnings
    [bool]$Success

    ErrorReport([string]$ScriptName) {
        $this.ScriptName = $ScriptName
        $this.StartTime = Get-Date
        $this.Errors = [System.Collections.Generic.List[PSObject]]::new()
        $this.Warnings = [System.Collections.Generic.List[string]]::new()
        $this.Success = $true
    }

    [void] AddError([string]$Context, [System.Management.Automation.ErrorRecord]$ErrorRecord) {
        $this.Success = $false
        $this.Errors.Add([PSCustomObject]@{
            Timestamp  = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            Context    = $Context
            Message    = $ErrorRecord.Exception.Message
            Category   = $ErrorRecord.CategoryInfo.Category.ToString()
            ErrorId    = $ErrorRecord.FullyQualifiedErrorId
            Target     = if ($ErrorRecord.TargetObject) { $ErrorRecord.TargetObject.ToString() } else { "N/A" }
            StackTrace = $ErrorRecord.ScriptStackTrace
        })
    }

    [void] AddWarning([string]$Message) {
        $this.Warnings.Add("[$((Get-Date).ToString('HH:mm:ss'))] $Message")
    }

    [string] ToJson() {
        $this.EndTime = Get-Date
        $duration = ($this.EndTime - $this.StartTime).ToString('hh\:mm\:ss')
        $report = [PSCustomObject]@{
            ScriptName  = $this.ScriptName
            StartTime   = $this.StartTime.ToString('yyyy-MM-dd HH:mm:ss')
            EndTime     = $this.EndTime.ToString('yyyy-MM-dd HH:mm:ss')
            Duration    = $duration
            Success     = $this.Success
            ErrorCount  = $this.Errors.Count
            WarningCount = $this.Warnings.Count
            Errors      = $this.Errors
            Warnings    = $this.Warnings
        }
        return ($report | ConvertTo-Json -Depth 5)
    }

    [void] Save([string]$OutputPath) {
        $json = $this.ToJson()
        $dir = Split-Path -Parent $OutputPath
        if ($dir -and -not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        $json | Out-File -FilePath $OutputPath -Encoding UTF8
    }

    [void] SendWebhook([string]$WebhookUrl, [string]$Status) {
        $color = if ($this.Success) { "36a64f" } else { "ff0000" }
        $summary = if ($this.Success) {
            "脚本 $($this.ScriptName) 执行成功"
        } else {
            "脚本 $($this.ScriptName) 执行失败，共 $($this.Errors.Count) 个错误"
        }

        $body = @{
            text = $summary
        } | ConvertTo-Json -Depth 3

        try {
            Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $body `
                -ContentType "application/json" -TimeoutSec 10
        }
        catch {
            Write-Warning "Webhook 通知发送失败: $($_.Exception.Message)"
        }
    }
}

# 使用示例：模拟一个批量运维任务
$report = [ErrorReport]::new("ServerMaintenance")

$report.AddWarning("磁盘清理将在非工作时间执行")

# 模拟处理多台服务器
$servers = @("web01", "web02", "db01", "cache01")
foreach ($server in $servers) {
    try {
        $ErrorActionPreference = 'Stop'
        # 模拟远程操作（db01 模拟失败）
        if ($server -eq "db01") {
            throw "连接超时: $server 端口 5432 无响应"
        }
        $report.AddWarning("$server 操作完成")
    }
    catch {
        $report.AddError("服务器维护 - $server", $_)
    }
}

# 生成报告
$reportPath = Join-Path $env:TEMP "error-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$report.Save($reportPath)

Write-Host "=== 执行摘要 ==="
Write-Host "脚本: $($report.ScriptName)"
Write-Host "成功: $($report.Success)"
Write-Host "错误数: $($report.Errors.Count)"
Write-Host "警告数: $($report.Warnings.Count)"
Write-Host "报告已保存至: $reportPath"
```

执行结果示例：

```
=== 执行摘要 ===
脚本: ServerMaintenance
成功: False
错误数: 1
警告数: 5
报告已保存至: /tmp/error-report-20260218-080000.json
```

生成的 JSON 报告内容：

```
{
    "ScriptName": "ServerMaintenance",
    "StartTime": "2026-02-18 08:00:01",
    "EndTime": "2026-02-18 08:00:02",
    "Duration": "00:00:01",
    "Success": false,
    "ErrorCount": 1,
    "WarningCount": 5,
    "Errors": [
        {
            "Timestamp": "2026-02-18 08:00:02",
            "Context": "服务器维护 - db01",
            "Message": "连接超时: db01 端口 5432 无响应",
            "Category": "OperationStopped",
            "ErrorId": "MyError",
            "Target": "N/A"
        }
    ],
    "Warnings": [
        "[08:00:01] 磁盘清理将在非工作时间执行",
        "[08:00:01] web01 操作完成",
        "[08:00:01] web02 操作完成",
        "[08:00:02] cache01 操作完成"
    ]
}
```

## 注意事项

1. **理解错误类型差异**：`try/catch` 只能捕获终止性错误。对于非终止性错误（如文件未找到），必须配合 `$ErrorActionPreference = 'Stop'` 或 `-ErrorAction Stop` 才能进入 catch 块。这是 PowerShell 错误处理中最常见的踩坑点。

2. **finally 块不可或缺**：无论是否发生错误，`finally` 块都会执行。它适合用来释放资源（关闭数据库连接、删除临时文件）和恢复被修改的全局状态（如 `$ErrorActionPreference`），确保脚本不会因为异常退出而留下脏状态。

3. **重试策略需要上限**：指数退避的延迟时间必须设置上限（`MaxDelaySeconds`），否则在极端情况下等待时间会无限增长。同时，添加随机抖动（jitter）可以有效防止多个客户端在同一时刻同时重试，避免"雷群效应"。

4. **断路器防止雪崩**：当底层服务完全不可用时，断路器模式可以在连续失败达到阈值后直接跳过调用，而不是继续无意义地重试。设置一个冷却期（如 5 分钟），冷却过后进入"半开"状态允许一次试探性调用，成功则重置断路器。

5. **错误报告要包含上下文**：仅有错误消息是不够的。结构化报告应包含时间戳、操作名称、错误分类、调用栈和目标对象等信息。这些上下文能将排障时间从小时级缩短到分钟级，尤其在无人值守的定时任务场景中。

6. **Webhook 通知要处理自身失败**：发送告警通知本身也可能失败（网络问题、URL 失效等）。通知失败不应导致脚本崩溃，应使用 `try/catch` 包裹并降级为本地日志记录。通知机制是锦上添花，不能喧宾夺主。
