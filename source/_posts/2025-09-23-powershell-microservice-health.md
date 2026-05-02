---
layout: post
date: 2025-09-23 08:00:00
updated: 2025-09-23 08:00:00
title: "PowerShell 技能连载 - 微服务健康检查"
description: PowerTip of the Day - Microservice Health Checks in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- microservice
- health-check
- api
- monitoring
---

_适用于 PowerShell 7.0 及以上版本_

在微服务架构中，服务之间的依赖关系错综复杂。一个服务异常可能引发连锁故障，导致整个系统崩溃。为了及时发现问题并触发自动恢复机制，我们需要对每个服务进行持续的健康检查。健康检查通常通过 HTTP 端点暴露服务的运行状态，包括数据库连接、缓存可用性、外部 API 响应等关键指标。

Kubernetes、Docker Swarm、Consul 等容器编排和服务发现工具都依赖健康检查端点来决定流量路由和容器重启策略。对于 PowerShell 运维人员来说，能够用脚本快速探测所有微服务的健康状态，是日常巡检和故障排查的基本功。

本文将从零开始，用 PowerShell 构建一套轻量级的微服务健康检查工具：先封装单服务探测函数，再扩展为批量并行检查，最后输出结构化的健康报告。

## 单服务健康检查函数

我们首先封装一个通用的健康检查函数，支持 HTTP 和 HTTPS 端点探测，返回结构化的检查结果。该函数会记录响应时间、状态码以及响应体中的关键信息。

```powershell
function Invoke-HealthCheck {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Url,

        [int]$TimeoutSeconds = 5,

        [string]$ExpectedStatus = '200'
    )

    $result = [ordered]@{
        Name       = $Name
        Url        = $Url
        Status     = 'Unknown'
        StatusCode = $null
        LatencyMs  = $null
        Timestamp  = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Error      = $null
    }

    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $response = Invoke-WebRequest -Uri $Url -TimeoutSec $TimeoutSeconds `
            -UseBasicParsing -ErrorAction Stop
        $stopwatch.Stop()

        $result.StatusCode = [int]$response.StatusCode
        $result.LatencyMs  = $stopwatch.ElapsedMilliseconds
        $result.Status     = if ($response.StatusCode -eq $ExpectedStatus) {
            'Healthy'
        } else {
            'Degraded'
        }
    }
    catch {
        $stopwatch.Stop()
        $result.Status    = 'Unhealthy'
        $result.LatencyMs = $stopwatch.ElapsedMilliseconds
        $result.Error     = $_.Exception.Message
    }

    [PSCustomObject]$result
}
```

```text
PS> Invoke-HealthCheck -Name '用户服务' -Url 'https://api.example.com/users/health'

Name       : 用户服务
Url        : https://api.example.com/users/health
Status     : Healthy
StatusCode : 200
LatencyMs  : 47
Timestamp  : 2025-09-23 08:15:32
Error      :
```

## 批量并行健康检查

在生产环境中，微服务数量通常有几十甚至上百个。逐个串行检查效率太低，我们利用 PowerShell 的 `ForEach-Object -Parallel`（PowerShell 7+）实现并行探测，并设置合理的并发度和超时时间。

```powershell
$services = @(
    @{ Name = 'API 网关';    Url = 'https://api.example.com/gateway/health' }
    @{ Name = '用户服务';    Url = 'https://api.example.com/users/health' }
    @{ Name = '订单服务';    Url = 'https://api.example.com/orders/health' }
    @{ Name = '支付服务';    Url = 'https://api.example.com/payment/health' }
    @{ Name = '库存服务';    Url = 'https://api.example.com/inventory/health' }
    @{ Name = '通知服务';    Url = 'https://api.example.com/notification/health' }
)

# 批量并行检查，最大并发 8 个
$healthResults = $services | ForEach-Object -ThrottleLimit 8 -Parallel {
    # 在并行运行空间中重新定义函数
    function Invoke-HealthCheck {
        param($Name, $Url, $TimeoutSeconds = 5)
        $result = [ordered]@{
            Name       = $Name
            Url        = $Url
            Status     = 'Unknown'
            StatusCode = $null
            LatencyMs  = $null
            Timestamp  = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
            Error      = $null
        }
        try {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $r = Invoke-WebRequest -Uri $Url -TimeoutSec $TimeoutSeconds `
                -UseBasicParsing -ErrorAction Stop
            $sw.Stop()
            $result.StatusCode = [int]$r.StatusCode
            $result.LatencyMs  = $sw.ElapsedMilliseconds
            $result.Status     = if ($r.StatusCode -eq 200) { 'Healthy' } else { 'Degraded' }
        }
        catch {
            $sw.Stop()
            $result.Status    = 'Unhealthy'
            $result.LatencyMs = $sw.ElapsedMilliseconds
            $result.Error     = $_.Exception.Message
        }
        [PSCustomObject]$result
    }

    Invoke-HealthCheck -Name $_.Name -Url $_.Url
}

# 按状态排序输出：不健康 > 降级 > 健康
$statusOrder = @{ Healthy = 2; Degraded = 1; Unhealthy = 0 }
$healthResults | Sort-Object { $statusOrder[$_.Status] } | Format-Table -AutoSize
```

```text
Name       Url                                                    Status     StatusCode LatencyMs Timestamp           Error
----       ---                                                    ------     ---------- --------- ---------           -----
支付服务   https://api.example.com/payment/health                 Unhealthy            0        5012 2025-09-23 08:16:01 Unable to connect...
库存服务   https://api.example.com/inventory/health               Degraded           503          234 2025-09-23 08:16:01
API 网关   https://api.example.com/gateway/health                 Healthy            200           38 2025-09-23 08:16:01
用户服务   https://api.example.com/users/health                   Healthy            200           47 2025-09-23 08:16:01
订单服务   https://api.example.com/orders/health                  Healthy            200           62 2025-09-23 08:16:01
通知服务   https://api.example.com/notification/health            Healthy            200           85 2025-09-23 08:16:01
```

## 生成结构化健康报告

检查结果可以导出为 JSON 或 HTML 报告，方便集成到监控告警系统。下面的脚本将结果输出为 JSON 文件，并生成一份简洁的 HTML 报告。

```powershell
function Export-HealthReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject[]]$Results,

        [string]$OutputPath = './health-report'
    )

    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'

    # 导出 JSON 报告
    $jsonPath = Join-Path $OutputPath "health-$timestamp.json"
    $Results | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath -Encoding utf8

    # 统计摘要
    $healthyCount   = ($Results | Where-Object Status -eq 'Healthy').Count
    $degradedCount  = ($Results | Where-Object Status -eq 'Degraded').Count
    $unhealthyCount = ($Results | Where-Object Status -eq 'Unhealthy').Count
    $totalCount     = $Results.Count

    $summary = @{
        Total      = $totalCount
        Healthy    = $healthyCount
        Degraded   = $degradedCount
        Unhealthy  = $unhealthyCount
        CheckTime  = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        Overall    = if ($unhealthyCount -gt 0) { 'CRITICAL' }
                     elseif ($degradedCount -gt 0) { 'WARNING' }
                     else { 'OK' }
    }

    Write-Host "`n========== 健康检查报告 ==========" -ForegroundColor Cyan
    Write-Host "检查时间:  $($summary.CheckTime)"
    Write-Host "服务总数:  $totalCount"
    Write-Host "健康:      $healthyCount"  -ForegroundColor Green
    Write-Host "降级:      $degradedCount"  -ForegroundColor Yellow
    Write-Host "不健康:    $unhealthyCount"  -ForegroundColor Red
    Write-Host "总体状态:  $($summary.Overall)" -ForegroundColor $(
        if ($summary.Overall -eq 'OK') { 'Green' }
        elseif ($summary.Overall -eq 'WARNING') { 'Yellow' }
        else { 'Red' }
    )
    Write-Host "===================================`n"

    # 导出摘要 JSON
    $summaryPath = Join-Path $OutputPath "summary-$timestamp.json"
    $summary | ConvertTo-Json | Out-File -FilePath $summaryPath -Encoding utf8

    Write-Host "JSON 报告已保存: $jsonPath"
    Write-Host "摘要已保存:      $summaryPath"
}
```

```text
PS> Export-HealthReport -Results $healthResults -OutputPath './reports'

========== 健康检查报告 ==========
检查时间:  2025-09-23 08:17:15
服务总数:  6
健康:      4
降级:      1
不健康:    1
总体状态:  CRITICAL
===================================

JSON 报告已保存: /reports/health-20250923-081715.json
摘要已保存:      /reports/summary-20250923-081715.json
```

## 带告警阈值的服务配置文件

对于大规模服务集群，把服务列表和告警阈值维护在 JSON 配置文件中比硬编码更灵活。下面的示例展示了如何从配置文件加载服务定义并执行检查。

```powershell
# 配置文件 services.json 示例
$configContent = @{
    services = @(
        @{
            name            = 'API 网关'
            url             = 'https://api.example.com/gateway/health'
            timeoutSeconds  = 3
            latencyWarnMs   = 200
            latencyCritMs   = 1000
        }
        @{
            name            = '用户服务'
            url             = 'https://api.example.com/users/health'
            timeoutSeconds  = 5
            latencyWarnMs   = 500
            latencyCritMs   = 2000
        }
        @{
            name            = '订单服务'
            url             = 'https://api.example.com/orders/health'
            timeoutSeconds  = 10
            latencyWarnMs   = 1000
            latencyCritMs   = 5000
        }
    )
    notify = @{
        webhookUrl = 'https://hooks.slack.com/services/XXX/YYY/ZZZ'
        enabled    = $true
    }
}

$configPath = './services.json'
$configContent | ConvertTo-Json -Depth 5 | Out-File -FilePath $configPath -Encoding utf8
```

```text
PS> Get-Content ./services.json | ConvertFrom-Json | ConvertTo-Json -Depth 3

{
  "services": [
    {
      "name": "API 网关",
      "url": "https://api.example.com/gateway/health",
      "timeoutSeconds": 3,
      "latencyWarnMs": 200,
      "latencyCritMs": 1000
    },
    {
      "name": "用户服务",
      "url": "https://api.example.com/users/health",
      "timeoutSeconds": 5,
      "latencyWarnMs": 500,
      "latencyCritMs": 2000
    },
    {
      "name": "订单服务",
      "url": "https://api.example.com/orders/health",
      "timeoutSeconds": 10,
      "latencyWarnMs": 1000,
      "latencyCritMs": 5000
    }
  ],
  "notify": {
    "webhookUrl": "https://hooks.slack.com/services/XXX/YYY/ZZZ",
    "enabled": true
  }
}
```

接下来从配置文件加载并执行检查，根据延迟阈值自动判定告警级别。

```powershell
# 加载配置并执行检查
$config = Get-Content ./services.json -Raw | ConvertFrom-Json

$checkResults = foreach ($svc in $config.services) {
    $check = Invoke-HealthCheck -Name $svc.name -Url $svc.url `
        -TimeoutSeconds $svc.timeoutSeconds

    # 根据延迟阈值判定告警级别
    $alertLevel = 'OK'
    if ($check.Status -eq 'Unhealthy') {
        $alertLevel = 'CRITICAL'
    }
    elseif ($check.LatencyMs -gt $svc.latencyCritMs) {
        $alertLevel = 'CRITICAL'
    }
    elseif ($check.LatencyMs -gt $svc.latencyWarnMs) {
        $alertLevel = 'WARNING'
    }

    $check | Add-Member -NotePropertyName 'AlertLevel' `
        -NotePropertyValue $alertLevel -PassThru
}

$checkResults | Format-Table Name, Status, AlertLevel, LatencyMs -AutoSize
```

```text
Name       Status   AlertLevel LatencyMs
----       ------   ---------- ---------
API 网关   Healthy  OK                35
用户服务   Healthy  WARNING          612
订单服务   Healthy  OK                78
```

## 注意事项

1. **超时设置要合理**：健康检查的超时时间不宜过长，通常 3-5 秒即可。过长的超时会导致批量检查时总耗时增加，也会拖慢容器编排系统的故障检测速度。

2. **并行运行的函数作用域隔离**：`ForEach-Object -Parallel` 在独立的运行空间中执行，外部定义的函数和变量不会自动继承。需要在并行块内重新定义函数，或使用 `$using:` 传递变量。

3. **HTTPS 证书验证**：内部服务的健康检查端点可能使用自签名证书。在测试环境中可以通过 `-SkipCertificateCheck` 参数跳过验证，但生产环境应配置受信任的 CA 证书。

4. **配置文件管理**：服务列表和阈值应维护在 JSON 或 YAML 配置文件中，纳入版本控制。避免在脚本中硬编码服务地址，便于环境迁移和 CI/CD 集成。

5. **告警去重与静默**：当某个服务持续不健康时，应避免重复发送告警。建议在告警逻辑中加入静默窗口（如 5 分钟内同一服务不重复告警），减少告警疲劳。

6. **日志持久化**：每次健康检查的结果应持久化存储，用于趋势分析和容量规划。可以将 JSON 报告写入时序数据库（如 InfluxDB）或对象存储（如 S3），配合 Grafana 等可视化工具查看历史趋势。
