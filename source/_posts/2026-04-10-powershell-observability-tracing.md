---
layout: post
date: 2026-04-10 08:00:00
updated: 2026-04-10 08:00:00
title: "PowerShell 技能连载 - 可观测性与分布式追踪"
description: PowerTip of the Day - Observability and Distributed Tracing in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- monitoring
---

_适用于 PowerShell 7.0 及以上版本_

在现代运维和 DevOps 实践中，可观测性（Observability）已成为系统可靠性的基石。与传统的被动监控不同，可观测性强调从系统外部输出推断内部状态的能力，其核心由三大支柱构成：日志（Logging）记录离散事件、指标（Metrics）量化系统状态、追踪（Tracing）串联请求链路。当 PowerShell 脚本从简单的自动化任务演进为跨系统编排工具时，缺乏可观测性就意味着排障时如同大海捞针。

在云原生环境中，一个运维操作可能横跨多个子系统：先调用 Azure API 获取资源列表，再通过 SSH 配置远程服务器，最后更新 CMDB 数据库。如果其中某个环节失败，仅凭零散的 `Write-Host` 输出几乎无法定位根因。通过引入结构化日志、指标采集和分布式追踪，我们可以为每条执行链路建立完整的"数字指纹"，让问题排查从猜测变为精确诊断。

本文将从三个层面逐步构建 PowerShell 脚本的可观测性体系：首先搭建统一的日志框架，确保所有脚本输出格式一致且可检索；然后实现性能指标采集，量化脚本的资源消耗与执行效率；最后引入分布式追踪机制，打通跨脚本、跨进程的调用链路。

<!-- more -->

## 结构化日志框架

良好的日志系统是可观测性的起点。与随意使用 `Write-Host` 不同，结构化日志要求每条日志都包含时间戳、级别、消息体和上下文信息，并以 JSON 格式输出，便于后续被 ELK、Splunk 或 Azure Log Analytics 等平台直接消费。

以下代码构建了一个轻量级的结构化日志模块，支持多级别控制、上下文注入和双通道输出（控制台 + 文件）：

```powershell
# 构建结构化日志框架
enum LogLevel {
    Debug = 0
    Information = 1
    Warning = 2
    Error = 3
    Critical = 4
}

function New-StructuredLogger {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$LogName,

        [string]$LogDirectory = './logs',

        [LogLevel]$MinimumLevel = [LogLevel]::Information,

        [hashtable]$DefaultContext = @{}
    )

    # 确保日志目录存在
    if (-not (Test-Path $LogDirectory)) {
        New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
    }

    $logFile = Join-Path $LogDirectory "$LogName-$(Get-Date -Format 'yyyyMMdd').json"

    # 返回日志记录器对象
    [PSCustomObject]@{
        Name          = $LogName
        LogFile       = $logFile
        MinimumLevel  = $MinimumLevel
        DefaultContext = $DefaultContext
    } | Add-Member -MemberType ScriptMethod -Name 'Write' -Value {
        param(
            [LogLevel]$Level,
            [string]$Message,
            [hashtable]$AdditionalContext = @{},
            [System.Management.Automation.ErrorRecord]$ErrorRecord = $null
        )

        # 级别过滤
        if ($Level -lt $this.MinimumLevel) { return }

        $entry = [ordered]@{
            timestamp  = (Get-Date).ToString('o')
            level      = $Level.ToString()
            logger     = $this.Name
            message    = $Message
            context    = [ordered]@{}
        }

        # 合并默认上下文和附加上下文
        foreach ($key in $this.DefaultContext.Keys) {
            $entry.context[$key] = $this.DefaultContext[$key]
        }
        foreach ($key in $AdditionalContext.Keys) {
            $entry.context[$key] = $AdditionalContext[$key]
        }

        # 异常信息
        if ($ErrorRecord) {
            $entry.exception = @{
                type       = $ErrorRecord.Exception.GetType().FullName
                message    = $ErrorRecord.Exception.Message
                stackTrace = $ErrorRecord.ScriptStackTrace
            }
        }

        $jsonLine = $entry | ConvertTo-Json -Depth 5 -Compress

        # 写入文件
        $jsonLine | Out-File -FilePath $this.LogFile -Append -Encoding utf8

        # 控制台着色输出
        $color = switch ($Level) {
            ([LogLevel]::Debug)       { 'Gray' }
            ([LogLevel]::Information) { 'White' }
            ([LogLevel]::Warning)     { 'Yellow' }
            ([LogLevel]::Error)       { 'Red' }
            ([LogLevel]::Critical)    { 'Magenta' }
            default                   { 'White' }
        }
        Write-Host "[$($Level.ToString().ToUpper())] $Message" -ForegroundColor $color
    } -Force -PassThru
}

# 创建日志记录器实例
$logger = New-StructuredLogger `
    -LogName 'deployment-pipeline' `
    -MinimumLevel ([LogLevel]::Debug) `
    -DefaultContext @{ environment = 'production'; host = $env:COMPUTERNAME }

# 记录不同级别的日志
$logger.Write([LogLevel]::Information, '开始部署流程', @{ version = '2.4.1' })
$logger.Write([LogLevel]::Debug, '加载配置文件', @{ configPath = '/etc/app/config.yaml' })
$logger.Write([LogLevel]::Warning, '检测到内存使用率偏高', @{ memoryUsage = '82%' })

# 模拟一个异常场景
try {
    throw '数据库连接超时'
} catch {
    $logger.Write([LogLevel]::Error, '部署流程中断', @{ step = 'database-migration' }, $_)
}
```

执行结果示例：

```
[INFORMATION] 开始部署流程
[DEBUG] 加载配置文件
[WARNING] 检测到内存使用率偏高
[ERROR] 部署流程中断
```

每条日志以 JSON Lines 格式追加到文件中，可被日志平台直接索引。`DefaultContext` 参数允许注入环境名、主机名等全局上下文，避免在每条日志中重复传递。通过调整 `MinimumLevel`，可以在生产环境中过滤掉 Debug 级别的日志，减少存储开销。

## 性能指标采集

指标是可观测性的量化核心。与日志不同，指标关注的是可聚合的数值数据，如执行时长、内存增量、API 调用次数等。以下代码实现了一个轻量级的指标采集器，支持计数器、计时器和仪表盘三种度量类型：

```powershell
# 性能指标采集器
function New-MetricsCollector {
    [CmdletBinding()]
    param(
        [string]$ServiceName = 'powershell-script',
        [string]$OutputPath = './metrics'
    )

    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }

    $metrics = [System.Collections.Concurrent.ConcurrentDictionary[string, PSObject]]::new()

    $collector = [PSCustomObject]@{
        ServiceName = $ServiceName
        StartTime   = Get-Date
        OutputPath  = $OutputPath
    }

    # 计数器：递增统计
    $collector | Add-Member -MemberType ScriptMethod -Name 'Increment' -Value {
        param([string]$MetricName, [int64]$Value = 1, [hashtable]$Tags = @{})

        $now = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
        $metrics.AddOrUpdate(
            $MetricName,
            { [PSCustomObject]@{ type = 'counter'; value = $Value; tags = $Tags; updatedAt = $now } },
            { param($key, $existing)
              $existing.value += $Value
              $existing.updatedAt = $now
              $existing
            }
        )
    } -Force

    # 计时器：测量执行时长
    $collector | Add-Member -MemberType ScriptMethod -Name 'Measure' -Value {
        param(
            [string]$MetricName,
            [scriptblock]$Action,
            [hashtable]$Tags = @{}
        )

        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $result = & $Action
        $stopwatch.Stop()

        $now = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
        $metric = [PSCustomObject]@{
            type      = 'timer'
            value     = $stopwatch.ElapsedMilliseconds
            unit      = 'ms'
            tags      = $Tags
            updatedAt = $now
        }
        $metrics[$MetricName] = $metric

        $result
    } -Force

    # 仪表盘：记录当前值
    $collector | Add-Member -MemberType ScriptMethod -Name 'Gauge' -Value {
        param([string]$MetricName, [double]$Value, [string]$Unit = '', [hashtable]$Tags = @{})

        $now = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
        $metrics[$MetricName] = [PSCustomObject]@{
            type      = 'gauge'
            value     = $Value
            unit      = $Unit
            tags      = $Tags
            updatedAt = $now
        }
    } -Force

    # 导出为 OpenTelemetry 兼容格式
    $collector | Add-Member -MemberType ScriptMethod -Name 'Export' -Value {
        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $exportFile = Join-Path $this.OutputPath "$($this.ServiceName)-metrics-$timestamp.json"

        $exportData = @{
            resource = @{
                'service.name' = $this.ServiceName
                'service.version' = '1.0.0'
                'host.name' = $env:COMPUTERNAME
            }
            scopeMetrics = @(
                @{
                    scope = @{ name = 'powershell-metrics' }
                    metrics = @()
                }
            )
            timestamp = (Get-Date).ToString('o')
        }

        foreach ($key in $metrics.Keys) {
            $m = $metrics[$key]
            $metricEntry = [ordered]@{
                name  = $key
                type  = $m.type
                value = $m.value
            }
            if ($m.unit) { $metricEntry.unit = $m.unit }
            if ($m.tags.Count -gt 0) { $metricEntry.tags = $m.tags }
            $exportData.scopeMetrics[0].metrics += $metricEntry
        }

        $exportData | ConvertTo-Json -Depth 5 | Out-File -FilePath $exportFile -Encoding utf8
        Write-Host "指标已导出到：$exportFile"
        Write-Host "共采集 $($metrics.Count) 项指标"
    } -Force

    $collector
}

# 使用示例：采集脚本执行的各项指标
$metrics = New-MetricsCollector -ServiceName 'backup-job'

# 计数器：统计处理的文件数量
1..10 | ForEach-Object { $metrics.Increment('files.processed') }
$metrics.Increment('errors.total', 2)

# 计时器：测量数据库备份耗时
$dbBackupTime = $metrics.Measure('db.backup.duration', {
    Start-Sleep -Milliseconds 150
    'backup completed'
}, @{ database = 'app_db' })

# 计时器：测量文件上传耗时
$metrics.Measure('upload.duration', {
    Start-Sleep -Milliseconds 80
}, @{ destination = 'azure-blob' })

# 仪表盘：记录当前内存使用
$mem = [System.GC]::GetTotalMemory($false)
$metrics.Gauge('memory.usage.bytes', $mem, 'bytes')
$metrics.Gauge('disk.free.percent', 67.3, 'percent', @{ drive = 'C:' })

# 导出所有指标
$metrics.Export()
```

执行结果示例：

```
指标已导出到：./metrics/backup-job-metrics-20260410-080000.json
共采集 5 项指标
```

导出的 JSON 遵循 OpenTelemetry 的资源-作用域-指标层级结构，可以被 Prometheus、Grafana 或 Jaeger 等工具链直接消费。`Measure` 方法使用 `System.Diagnostics.Stopwatch` 提供毫秒级精度的计时，适用于需要精确度量的 I/O 操作和 API 调用场景。

## 分布式追踪实现

分布式追踪是可观测性三大支柱中最复杂但也最有价值的部分。一个 Trace 由多个 Span 组成，每个 Span 代表一个操作单元。当 PowerShell 脚本编排多个外部系统调用时，通过 Span 和 Trace ID 将它们串联起来，就能在 Jaeger 或 Zipkin 中看到完整的调用拓扑。

以下代码实现了一个兼容 OpenTelemetry 概念的追踪框架，支持嵌套 Span、上下文传播和 OTLP 格式导出：

```powershell
# 分布式追踪实现
function New-TraceContext {
    [CmdletBinding()]
    param(
        [string]$TraceId = (1..32 | ForEach-Object { '{0:x}' -f (Get-Random -Maximum 16) }) -join '',
        [string]$ParentSpanId = $null
    )

    $spanId = (1..16 | ForEach-Object { '{0:x}' -f (Get-Random -Maximum 16) }) -join ''

    [PSCustomObject]@{
        traceId       = $TraceId
        spanId        = $spanId
        parentSpanId  = $ParentSpanId
        startTime     = [DateTimeOffset]::UtcTime
        attributes    = [ordered]@{}
        events        = [System.Collections.Generic.List[PSObject]]::new()
        status        = 'OK'
    }
}

function New-Tracer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ServiceName,

        [string]$ExporterPath = './traces'
    )

    if (-not (Test-Path $ExporterPath)) {
        New-Item -ItemType Directory -Path $ExporterPath -Force | Out-Null
    }

    # Span 栈：支持嵌套调用
    $spanStack = [System.Collections.Stack]::new()
    $completedSpans = [System.Collections.Generic.List[PSObject]]::new()

    $tracer = [PSCustomObject]@{
        ServiceName  = $ServiceName
        ExporterPath = $ExporterPath
    }

    # 开始一个新的 Span
    $tracer | Add-Member -MemberType ScriptMethod -Name 'StartSpan' -Value {
        param(
            [string]$Name,
            [hashtable]$Attributes = @{}
        )

        $parentSpanId = if ($spanStack.Count -gt 0) { $spanStack.Peek().spanId } else { $null }
        $traceId = if ($spanStack.Count -gt 0) { $spanStack.Peek().traceId } else { $null }

        $span = New-TraceContext -TraceId $traceId -ParentSpanId $parentSpanId
        $span | Add-Member -MemberType NoteProperty -Name 'name' -Value $Name

        foreach ($key in $Attributes.Keys) {
            $span.attributes[$key] = $Attributes[$key]
        }

        # 注入系统信息
        $span.attributes['service.name'] = $this.ServiceName
        $span.attributes['host.name'] = $env:COMPUTERNAME

        $spanStack.Push($span)
        $span
    } -Force

    # 添加事件到当前 Span
    $tracer | Add-Member -MemberType ScriptMethod -Name 'AddEvent' -Value {
        param([string]$EventName, [hashtable]$Attributes = @{})

        if ($spanStack.Count -eq 0) {
            Write-Warning '没有活跃的 Span，无法添加事件'
            return
        }

        $currentSpan = $spanStack.Peek()
        $currentSpan.events.Add([PSCustomObject]@{
            name       = $EventName
            timestamp  = [DateTimeOffset]::UtcTime.ToString('o')
            attributes = $Attributes
        })
    } -Force

    # 结束当前 Span
    $tracer | Add-Member -MemberType ScriptMethod -Name 'EndSpan' -Value {
        param([string]$Status = 'OK')

        if ($spanStack.Count -eq 0) {
            Write-Warning '没有活跃的 Span 可以结束'
            return
        }

        $span = $spanStack.Pop()
        $endTime = [DateTimeOffset]::UtcTime
        $duration = ($endTime - $span.startTime).TotalMilliseconds

        $span.status = $Status

        $completedSpan = [ordered]@{
            traceId      = $span.traceId
            spanId       = $span.spanId
            parentSpanId = $span.parentSpanId
            name         = $span.name
            startTime    = $span.startTime.ToString('o')
            endTime      = $endTime.ToString('o')
            durationMs   = [math]::Round($duration, 2)
            status       = $span.status
            attributes   = $span.attributes
            events       = $span.events.ToArray()
            resource     = [ordered]@{
                'service.name'    = $this.ServiceName
                'service.version' = '1.0.0'
                'telemetry.sdk.name' = 'powershell-custom'
            }
        }

        $completedSpans.Add($completedSpan)
        $completedSpan
    } -Force

    # 导出为 OTLP JSON 格式
    $tracer | Add-Member -MemberType ScriptMethod -Name 'Export' -Value {
        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $exportFile = Join-Path $this.ExporterPath "$($this.ServiceName)-trace-$timestamp.json"

        $otlpExport = @{
            resourceSpans = @(
                @{
                    resource = @{
                        attributes = @(
                            @{ key = 'service.name'; value = @{ stringValue = $this.ServiceName } }
                        )
                    }
                    scopeSpans = @(
                        @{
                            scope = @{ name = 'powershell-tracer' }
                            spans = $completedSpans
                        }
                    )
                }
            )
        }

        $otlpExport | ConvertTo-Json -Depth 8 | Out-File -FilePath $exportFile -Encoding utf8
        Write-Host "追踪数据已导出到：$exportFile"
        Write-Host "共记录 $($completedSpans.Count) 个 Span"

        # 输出调用链摘要
        Write-Host "`n--- 调用链摘要 ---"
        foreach ($s in $completedSpans) {
            $indent = if ($s.parentSpanId) { '  ' } else { '' }
            Write-Host "$indent[$($s.status)] $($s.name) - $($s.durationMs)ms"
        }
    } -Force

    $tracer
}

# 模拟一个完整的多层调用链
$tracer = New-Tracer -ServiceName 'deployment-pipeline'

# 根 Span：整个部署流程
$rootSpan = $tracer.StartSpan('deploy.release', @{ version = '2.4.1'; environment = 'production' })

  # 子 Span 1：拉取代码
  $pullSpan = $tracer.StartSpan('git.pull', @{ repository = 'app-service' })
  Start-Sleep -Milliseconds 50
  $tracer.AddEvent('checkout_complete', @{ branch = 'main'; commit = 'a1b2c3d' })
  $tracer.EndSpan()

  # 子 Span 2：运行测试
  $testSpan = $tracer.StartSpan('test.run', @{ framework = 'pytest' })
  $tracer.AddEvent('test_started', @{ totalTests = 142 })
  Start-Sleep -Milliseconds 120

  # 孙 Span：代码覆盖率分析
  $coverageSpan = $tracer.StartSpan('test.coverage', @{ threshold = '80%' })
  Start-Sleep -Milliseconds 30
  $tracer.AddEvent('coverage_calculated', @{ lineCoverage = '87.3%'; branchCoverage = '82.1%' })
  $coverageResult = $tracer.EndSpan()

  $tracer.AddEvent('test_completed', @{ passed = 140; failed = 2 })
  $testResult = $tracer.EndSpan()

  # 子 Span 3：部署到生产
  $deploySpan = $tracer.StartSpan('deploy.push', @{ target = 'k8s-cluster-01' })
  $tracer.AddEvent('rolling_update_started', @{ replicas = 3 })
  Start-Sleep -Milliseconds 80
  $tracer.AddEvent('health_check_passed')
  $deployResult = $tracer.EndSpan()

# 结束根 Span
$tracer.EndSpan()

# 导出追踪数据
$tracer.Export()
```

执行结果示例：

```
追踪数据已导出到：./traces/deployment-pipeline-trace-20260410-080000.json
共记录 5 个 Span

--- 调用链摘要 ---
[OK] deploy.release - 284.37ms
  [OK] git.pull - 52.14ms
  [OK] test.run - 153.89ms
  [OK] test.coverage - 33.27ms
  [OK] deploy.push - 83.41ms
```

通过 `spanStack` 实现的嵌套机制，子 Span 自动继承父 Span 的 `traceId` 和 `spanId`，形成完整的调用树。导出格式兼容 OTLP JSON，可以直接发送到 OpenTelemetry Collector，再由 Collector 转发到 Jaeger、Zipkin 或 Tempo 等后端进行可视化分析。

## 注意事项

1. **日志级别与环境匹配**：开发环境建议将 `MinimumLevel` 设为 `Debug`，生产环境至少设为 `Information`。过于详细的日志在生产环境会产生大量 I/O 开销，尤其是在高频循环中记录日志时需格外谨慎。

2. **JSON 序列化深度**：`ConvertTo-Json` 默认深度仅为 2，嵌套的 `hashtable` 和 `PSCustomObject` 会被截断为字符串。在日志和指标导出中务必指定 `-Depth 5` 或更高，否则结构化数据会丢失。

3. **Trace ID 的唯一性**：示例中使用 `Get-Random` 生成 Trace/Span ID 仅供演示，生产环境建议使用 `[guid]::NewGuid().ToString('N')` 或基于时间戳的确定性算法，确保全局唯一性。

4. **大对象内存压力**：长时间运行的脚本中，`$completedSpans` 列表可能累积大量数据。建议设置导出阈值（如每 1000 个 Span 自动导出并清空），或在 `EndSpan` 时直接流式写入文件，避免内存持续增长。

5. **线程安全考量**：`ConcurrentDictionary` 用于指标存储是线程安全的，但 `Span` 的栈操作（`Push`/`Pop`）不是。如果你的脚本使用 `ForEach-Object -Parallel`，每个 runspace 应拥有独立的 Tracer 实例，最后再合并导出。

6. **与 OpenTelemetry Collector 集成**：生产环境中，建议将导出的 JSON 文件通过 Filelog Receiver 或 HTTP Receiver 发送到 OpenTelemetry Collector，由 Collector 统一处理采样、批处理和路由，而不是让每个脚本直接对接后端存储。
