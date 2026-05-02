---
layout: post
date: 2025-10-17 08:00:00
updated: 2025-10-17 08:00:00
title: "PowerShell 技能连载 - Prometheus 指标采集"
description: PowerTip of the Day - Prometheus Metrics Collection in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- prometheus
- metrics
- monitoring
- observability
---

_适用于 PowerShell 7.0 及以上版本_

在云原生可观测性体系中，Prometheus 已经成为指标采集与监控的事实标准。它的数据模型基于时间序列，每条指标由指标名称和一组键值对标签唯一标识。当我们需要在运维自动化脚本中采集系统指标、将业务应用的性能数据推送到 Prometheus Pushgateway、或者从 Prometheus Server 查询历史数据做容量规划时，直接通过 HTTP API 与 Prometheus 交互是最灵活的方式。

PowerShell 7 内置的 `Invoke-RestMethod` 对 JSON 的原生支持，使其非常适合与 Prometheus 的 RESTful API 和文本暴露格式（text-based exposition format）打交道。无需安装额外的 SDK，只需几行脚本就能完成指标采集、推送和查询。本文将从三个场景出发：采集本地系统指标并写入 Prometheus 格式文件、推送自定义指标到 Pushgateway、以及从 Prometheus Server 执行 PromQL 查询并分析结果。

## 场景一：采集本地系统指标并输出 Prometheus 格式

Prometheus 的文本暴露格式是一种人类可读的纯文本协议。每条指标以 `# TYPE` 声明类型，紧随其后的行是具体的指标值。下面的脚本通过 .NET 的 `System.Diagnostics.Process` 和 `PerformanceCounter` 类采集 CPU、内存和磁盘指标，然后输出符合 Prometheus 标准的文本格式。

```powershell
function Get-SystemPrometheusMetrics {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$InstanceHostname = $env:COMPUTERNAME
    )

    # 采集 CPU 使用率（通过 WMI/CIM，跨平台兼容）
    $cpuUsage = 0
    if ($IsWindows -or $PSEdition -eq 'Desktop') {
        $cpu = Get-CimInstance -ClassName Win32_Processor -ErrorAction SilentlyContinue
        if ($cpu) {
            $cpuUsage = [math]::Round(($cpu | Measure-Object -Property LoadPercentage -Average).Average, 2)
        }
    } else {
        # Linux/macOS：通过 top 命令获取
        $topOutput = top -bn1 | Select-String '^%?Cpu'
        if ($topOutput -match '(\d+\.?\d*)\s*id') {
            $cpuUsage = [math]::Round(100 - [double]$Matches[1], 2)
        }
    }

    # 采集内存使用情况
    $osInfo = if ($IsWindows -or $PSEdition -eq 'Desktop') {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        @{
            TotalBytes   = $os.TotalVisibleMemorySize * 1KB
            UsedBytes    = ($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) * 1KB
            FreeBytes    = $os.FreePhysicalMemory * 1KB
            UsedPercent  = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize * 100, 2)
        }
    } else {
        $memInfo = Get-Content /proc/meminfo
        $total = [int]($memInfo | Select-String 'MemTotal:\s+(\d+)' | ForEach-Object { $_.Matches[0].Groups[1].Value }) * 1KB
        $available = [int]($memInfo | Select-String 'MemAvailable:\s+(\d+)' | ForEach-Object { $_.Matches[0].Groups[1].Value }) * 1KB
        @{
            TotalBytes  = $total
            UsedBytes   = $total - $available
            FreeBytes   = $available
            UsedPercent = [math]::Round(($total - $available) / $total * 100, 2)
        }
    }

    # 采集磁盘使用情况（根分区 / 系统盘）
    $drive = if ($IsWindows -or $PSEdition -eq 'Desktop') {
        Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType=3' |
            Sort-Object -Property Size -Descending | Select-Object -First 1
    } else {
        $dfOutput = df / | Select-Object -Last 1
        $parts = $dfOutput -split '\s+'
        [PSCustomObject]@{
            Size         = [int64]$parts[1] * 1KB
            FreeSpace    = [int64]$parts[3] * 1KB
            VolumeName   = '/'
        }
    }
    $diskTotal = $drive.Size
    $diskFree = if ($drive.FreeSpace -is [long]) { $drive.FreeSpace } else { $drive.FreeSpace }
    $diskUsedPercent = [math]::Round(($diskTotal - $diskFree) / $diskTotal * 100, 2)

    # 获取当前时间戳（Unix 纪元秒）
    $timestamp = [int64][double]::Parse(
        (Get-Date -UFormat '%s'), [System.Globalization.CultureInfo]::InvariantCulture
    )

    # 组装 Prometheus 文本格式指标
    $labels = "instance=`"$InstanceHostname`""
    $lines = @(
        '# HELP system_cpu_usage_percent CPU usage percentage'
        '# TYPE system_cpu_usage_percent gauge'
        "system_cpu_usage_percent{$labels} $cpuUsage $timestamp"
        ''
        '# HELP system_memory_total_bytes Total physical memory in bytes'
        '# TYPE system_memory_total_bytes gauge'
        "system_memory_total_bytes{$labels} $($osInfo.TotalBytes) $timestamp"
        ''
        '# HELP system_memory_used_bytes Used physical memory in bytes'
        '# TYPE system_memory_used_bytes gauge'
        "system_memory_used_bytes{$labels} $($osInfo.UsedBytes) $timestamp"
        ''
        '# HELP system_memory_used_percent Memory usage percentage'
        '# TYPE system_memory_used_percent gauge'
        "system_memory_used_percent{$labels} $($osInfo.UsedPercent) $timestamp"
        ''
        '# HELP system_disk_total_bytes Total disk space in bytes'
        '# TYPE system_disk_total_bytes gauge'
        "system_disk_total_bytes{$labels} $diskTotal $timestamp"
        ''
        '# HELP system_disk_used_percent Disk usage percentage'
        '# TYPE system_disk_used_percent gauge'
        "system_disk_used_percent{$labels} $diskUsedPercent $timestamp"
    )

    return $lines -join "`n"
}

# 采集并输出指标
$metrics = Get-SystemPrometheusMetrics
Write-Output $metrics
```

执行结果示例：

```
# HELP system_cpu_usage_percent CPU usage percentage
# TYPE system_cpu_usage_percent gauge
system_cpu_usage_percent{instance="WEB-SVR01"} 23.45 1729137600

# HELP system_memory_total_bytes Total physical memory in bytes
# TYPE system_memory_total_bytes gauge
system_memory_total_bytes{instance="WEB-SVR01"} 34359738368 1729137600

# HELP system_memory_used_bytes Used physical memory in bytes
# TYPE system_memory_used_bytes gauge
system_memory_used_bytes{instance="WEB-SVR01"} 20132659200 1729137600

# HELP system_memory_used_percent Memory usage percentage
# TYPE system_memory_used_percent gauge
system_memory_used_percent{instance="WEB-SVR01"} 58.59 1729137600

# HELP system_disk_total_bytes Total disk space in bytes
# TYPE system_disk_total_bytes gauge
system_disk_total_bytes{instance="WEB-SVR01"} 536870912000 1729137600

# HELP system_disk_used_percent Disk usage percentage
# TYPE system_disk_used_percent gauge
system_disk_used_percent{instance="WEB-SVR01"} 72.31 1729137600
```

## 场景二：推送自定义指标到 Pushgateway

短生命周期的任务（如批处理脚本、CI/CD 构建流水线）运行时间很短，Prometheus 的默认拉取模式可能来不及采集。Pushgateway 提供了一种推送模式，允许脚本在任务完成时主动将指标推送到中间网关，等待 Prometheus 定期拉取。下面的脚本演示了如何将构建流水线的执行时长和成功率推送到 Pushgateway。

```powershell
function Push-PrometheusMetric {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [uri]$PushgatewayUrl,

        [Parameter(Mandatory)]
        [string]$JobName,

        [Parameter(Mandatory)]
        [string]$MetricName,

        [Parameter(Mandatory)]
        [double]$MetricValue,

        [Parameter()]
        [string]$MetricType = 'gauge',

        [Parameter()]
        [string]$HelpText = $MetricName,

        [Parameter()]
        [hashtable]$Labels
    )

    # 构建 Pushgateway 的推送 URL
    # 路径格式：/metrics/job/<job_name>/label_key/label_value
    $pushPath = "/metrics/job/$JobName"
    foreach ($key in $Labels.Keys) {
        $encodedKey = [uri]::EscapeDataString($key)
        $encodedValue = [uri]::EscapeDataString($Labels[$key])
        $pushPath += "/$encodedKey/$encodedValue"
    }

    $fullUrl = New-Object System.Uri -ArgumentList $PushgatewayUrl, $pushPath

    # 获取 Unix 时间戳
    $timestamp = [int64][double]::Parse(
        (Get-Date -UFormat '%s'), [System.Globalization.CultureInfo]::InvariantCulture
    )

    # 构建标签字符串（不包含 job，job 已在 URL 路径中）
    $labelPairs = foreach ($key in $Labels.Keys) {
        "$key=`"$($Labels[$key])`""
    }
    $labelStr = $labelPairs -join ','

    # 组装 Prometheus 文本格式
    $body = @(
        "# HELP $MetricName $HelpText"
        "# TYPE $MetricName $MetricType"
        "${MetricName}{$labelStr} $MetricValue $timestamp"
    ) -join "`n"

    # 发送推送请求
    try {
        $response = Invoke-RestMethod -Method Post -Uri $fullUrl -Body $body `
            -ContentType 'text/plain; version=1.0.4; charset=utf-8' `
            -ErrorAction Stop

        Write-Verbose "指标推送成功: $MetricName = $MetricValue -> $fullUrl"
        return $true
    }
    catch {
        Write-Error "指标推送失败: $($_.Exception.Message)"
        return $false
    }
}

# 示例：推送 CI/CD 构建指标
$pushgateway = 'http://prometheus-pushgateway.monitoring.svc.cluster.local:9091'
$buildLabels = @{
    branch    = 'main'
    pipeline  = 'deploy-production'
    stage     = 'build'
    runner    = 'ps-runner-01'
}

# 推送构建时长（秒）
$buildDuration = Get-Random -Minimum 120 -Maximum 480
Push-PrometheusMetric -PushgatewayUrl $pushgateway `
    -JobName 'ci_build_pipeline' `
    -MetricName 'ci_build_duration_seconds' `
    -MetricValue $buildDuration `
    -MetricType 'gauge' `
    -HelpText 'Duration of CI build in seconds' `
    -Labels $buildLabels

# 推送构建结果（1=成功, 0=失败）
Push-PrometheusMetric -PushgatewayUrl $pushgateway `
    -JobName 'ci_build_pipeline' `
    -MetricName 'ci_build_success' `
    -MetricValue 1 `
    -MetricType 'gauge' `
    -HelpText 'Whether the CI build succeeded (1=yes, 0=no)' `
    -Labels $buildLabels

Write-Host "构建指标已推送到 Pushgateway"
```

执行结果示例：

```
构建指标已推送到 Pushgateway
```

可以通过以下命令验证 Pushgateway 中存储的指标：

```powershell
# 查询 Pushgateway 中所有指标组
$groups = Invoke-RestMethod -Uri "$pushgateway/api/v1/metrics"
$groups.data | ConvertTo-Json -Depth 5 | Select-Object -First 30
```

执行结果示例：

```
{
  "type": "gauge",
  "help": "Duration of CI build in seconds",
  "metrics": [
    {
      "labels": {
        "branch": "main",
        "instance": "",
        "job": "ci_build_pipeline",
        "pipeline": "deploy-production",
        "runner": "ps-runner-01",
        "stage": "build"
      },
      "value": "347"
    }
  ]
}
```

## 场景三：查询 Prometheus Server 并分析指标数据

Prometheus 提供了丰富的 HTTP Query API，支持即时查询（instant query）和范围查询（range query）。下面的脚本封装了两个查询函数，分别用于获取某一时刻的指标快照和一段时间内的时序数据，并将结果转换为 PowerShell 对象便于后续分析。

```powershell
function Invoke-PrometheusQuery {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [uri]$PrometheusUrl,

        [Parameter(Mandatory)]
        [string]$Query,

        [Parameter()]
        [datetime]$Time = (Get-Date)
    )

    # 即时查询：获取指定时刻的指标值
    $timestamp = [int64][double]::Parse(
        $Time.ToUniversalTime().Subtract([datetime]::new(1970, 1, 1)).TotalSeconds,
        [System.Globalization.CultureInfo]::InvariantCulture
    )

    $queryParams = @{
        query = $Query
        time  = $timestamp
    }

    $response = Invoke-RestMethod -Method Get `
        -Uri "$PrometheusUrl/api/v1/query" `
        -Body $queryParams

    if ($response.status -ne 'success') {
        throw "Prometheus 查询失败: $($response.errorType) - $($response.error)"
    }

    # 将查询结果转换为 PowerShell 对象
    $results = foreach ($result in $response.data.result) {
        $labels = $result.metric
        $value = $result.value

        [PSCustomObject]@{
            MetricName = $labels['__name__']
            Labels     = $labels
            Timestamp  = [datetimeoffset]::FromUnixTimeSeconds([int64]$value[0]).DateTime
            Value      = [double]$value[1]
        }
    }

    return $results
}

function Invoke-PrometheusRangeQuery {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [uri]$PrometheusUrl,

        [Parameter(Mandatory)]
        [string]$Query,

        [Parameter(Mandatory)]
        [datetime]$StartTime,

        [Parameter(Mandatory)]
        [datetime]$EndTime,

        [Parameter()]
        [string]$Step = '5m'
    )

    # 范围查询：获取时间区间内的指标时序
    $startTs = [int64][double]::Parse(
        $StartTime.ToUniversalTime().Subtract([datetime]::new(1970, 1, 1)).TotalSeconds,
        [System.Globalization.CultureInfo]::InvariantCulture
    )
    $endTs = [int64][double]::Parse(
        $EndTime.ToUniversalTime().Subtract([datetime]::new(1970, 1, 1)).TotalSeconds,
        [System.Globalization.CultureInfo]::InvariantCulture
    )

    $queryParams = @{
        query = $Query
        start = $startTs
        end   = $endTs
        step  = $Step
    }

    $response = Invoke-RestMethod -Method Get `
        -Uri "$PrometheusUrl/api/v1/query_range" `
        -Body $queryParams

    if ($response.status -ne 'success') {
        throw "Prometheus 范围查询失败: $($response.errorType) - $($response.error)"
    }

    # 将时序数据转换为扁平化的 PowerShell 对象列表
    $results = foreach ($series in $response.data.result) {
        $labels = $series.metric
        $values = $series.values

        foreach ($pair in $values) {
            [PSCustomObject]@{
                MetricName = $labels['__name__']
                Instance   = $labels['instance']
                Job        = $labels['job']
                Timestamp  = [datetimeoffset]::FromUnixTimeSeconds([int64]$pair[0]).DateTime
                Value      = [double]$pair[1]
            }
        }
    }

    return $results
}

# 即时查询：获取所有实例的 CPU 使用率
$prometheus = 'http://prometheus.monitoring.svc.cluster.local:9090'
$cpuData = Invoke-PrometheusQuery -PrometheusUrl $prometheus `
    -Query '100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)'

$cpuData | Select-Object MetricName, Instance, Value, Timestamp |
    Sort-Object Value -Descending |
    Format-Table -AutoSize

# 范围查询：获取过去 1 小时内存使用率的时序数据
$rangeData = Invoke-PrometheusRangeQuery -PrometheusUrl $prometheus `
    -Query '(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100' `
    -StartTime (Get-Date).AddHours(-1) `
    -EndTime (Get-Date) `
    -Step '5m'

# 计算统计摘要
$rangeData | Group-Object Instance | ForEach-Object {
    $values = $_.Group.Value
    [PSCustomObject]@{
        Instance = $_.Name
        Min      = [math]::Round(($values | Measure-Object -Minimum).Minimum, 2)
        Max      = [math]::Round(($values | Measure-Object -Maximum).Maximum, 2)
        Avg      = [math]::Round(($values | Measure-Object -Average).Average, 2)
        Samples  = $values.Count
    }
} | Sort-Object Avg -Descending | Format-Table -AutoSize
```

执行结果示例：

```
MetricName                        Instance            Value Timestamp
----------                        --------            ----- ---------
node_cpu_seconds_total            web-svr01:9100      78.34 10/17/2025 8:00:00 AM
node_cpu_seconds_total            db-svr01:9100       45.21 10/17/2025 8:00:00 AM
node_cpu_seconds_total            api-svr01:9100      32.67 10/17/2025 8:00:00 AM
node_cpu_seconds_total            monitor-svr01:9100  12.45 10/17/2025 8:00:00 AM

Instance            Min   Max   Avg Samples
---------            ---   ---   --- -------
web-svr01:9100      55.32 82.17 68.45      12
db-svr01:9100       40.11 62.89 51.33      12
api-svr01:9100      28.45 48.22 37.61      12
monitor-svr01:9100   8.12 22.34 15.88      12
```

## 注意事项

1. **指标命名规范**：Prometheus 指标名称应遵循 `namespace_subsystem_name_unit` 的命名约定。例如 `node_memory_MemAvailable_bytes` 分别代表命名空间（node）、子系统（memory）、度量项（MemAvailable）和单位（bytes）。使用一致的命名规范能让 PromQL 查询更简洁，也便于 Grafana 面板复用。

2. **时间戳精度与同步**：推送指标时附带的时间戳必须是 Unix 纪元秒数（float64）。确保运行 PowerShell 的主机时间已通过 NTP 同步，否则 Prometheus 可能因时间偏移而拒绝数据。在推送模式下可以省略时间戳，让 Pushgateway 自动使用接收时间。

3. **Pushgateway 数据清理**：Pushgateway 不会自动清除已推送的指标，即使对应的任务已经停止运行。这会导致 Prometheus 持续采集到过期的静态数据。建议在任务结束后调用 Pushgateway 的 DELETE API 清理指标组，或在推送时设置合理的标签（如 `instance`）以便批量清理。

4. **PromQL 注入风险**：如果 PromQL 查询字符串包含用户输入（如主机名、应用名称），必须进行转义和校验，防止注入攻击。PromQL 本身不支持 SQL 式的注入，但恶意的标签值可能导致查询结果被篡改或返回大量数据耗尽 Prometheus Server 内存。

5. **大范围查询的性能**：范围查询（`query_range`）的 `step` 参数直接影响返回的数据点数量。公式为 `(end - start) / step`。查询 7 天的数据、step 设为 15 秒将返回约 4 万个数据点，可能使 PowerShell 的对象处理变慢。建议根据查询时长合理设置 step：1 小时用 `1m`，1 天用 `5m`，7 天用 `15m`。

6. **认证与网络安全**：生产环境的 Prometheus 通常部署在内部网络，可能需要 mTLS 或 Bearer Token 认证。使用 `Invoke-RestMethod` 时通过 `-Headers @{Authorization = 'Bearer <token>'}` 传递令牌，通过 `-SkipCertificateCheck` 处理自签证书（仅限内部测试环境）。建议将凭据存储在 PowerShell SecretManagement 模块中，不要硬编码在脚本里。
