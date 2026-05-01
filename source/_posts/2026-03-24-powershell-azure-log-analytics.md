---
layout: post
date: 2026-03-24 08:00:00
title: "PowerShell 技能连载 - Azure Log Analytics 查询"
description: PowerTip of the Day - Azure Log Analytics Query in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure
- log-analytics
- kql
- monitoring
---

_适用于 PowerShell 7.0 及以上版本_

Azure Log Analytics 是 Azure Monitor 的核心数据收集和分析引擎，它从虚拟机、容器、应用服务、网络安全组等各种数据源汇聚海量日志和指标数据。面对每天数以 GB 计的日志流，仅在门户中手动查询远远不够——你需要将查询能力嵌入到自动化脚本中，才能实现真正的持续监控和快速响应。

Kusto Query Language（KQL）是 Log Analytics 的查询语言，语法简洁但功能强大，支持跨表关联、时间序列分析、正则匹配和统计聚合。通过 PowerShell 调用 Azure Monitor REST API 执行 KQL 查询，可以把日志分析无缝集成到运维工作流中——无论是性能趋势分析、安全事件调查还是容量规划，都能用脚本自动完成并生成报告。

本文将从三个方面展开实战：先搭建 Log Analytics 查询的基础函数，处理认证和结果解析；然后深入运维分析场景，包括性能趋势、错误统计和安全事件检索；最后构建定时查询与告警机制，实现日志监控的全自动化闭环。

## Log Analytics 查询基础

执行 KQL 查询的第一步是获取工作区信息并调用 Azure Monitor Query API。下面的脚本封装了一个通用查询函数，支持连接指定工作区、执行 KQL 查询，并将返回的 JSON 结果转换为结构化的 PowerShell 对象，方便后续处理。

```powershell
function Invoke-LogAnalyticsQuery {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$WorkspaceId,

        [Parameter(Mandatory = $true)]
        [string]$Query,

        [Parameter(Mandatory = $false)]
        [datetime]$TimeRangeStart = (Get-Date).AddHours(-24),

        [Parameter(Mandatory = $false)]
        [datetime]$TimeRangeEnd = (Get-Date),

        [Parameter(Mandatory = $false)]
        [int]$MaxResults = 10000
    )

    $apiVersion = "2024-02-01"
    $uri = "/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.OperationalInsights/workspaces/{2}/query?api-version={3}" -f `
        $script:SubscriptionId, $script:ResourceGroupName, $script:WorkspaceName, $apiVersion

    # 使用 Invoke-AzRestMethod 直接调用 REST API
    $body = @{
        query  = $Query
        timespan = "$($TimeRangeStart.ToString('yyyy-MM-ddTHH:mm:ssZ'))/$($TimeRangeEnd.ToString('yyyy-MM-ddTHH:mm:ssZ'))"
    } | ConvertTo-Json

    $response = Invoke-AzRestMethod -Path $uri -Method POST -Payload $body

    if ($response.StatusCode -ne 200) {
        Write-Error "查询失败 (HTTP $($response.StatusCode)): $($response.Content)"
        return
    }

    $result = $response.Content | ConvertFrom-Json

    # 解析表格结果为 PowerShell 对象数组
    $table = $result.tables[0]
    $columns = $table.columns.name
    $rows = $table.rows

    $output = foreach ($row in $rows) {
        $obj = [ordered]@{}
        for ($i = 0; $i -lt $columns.Count; $i++) {
            $obj[$columns[$i]] = $row[$i]
        }
        [PSCustomObject]$obj
    }

    # 输出摘要信息
    Write-Host ("查询完成，返回 {0} 行数据（耗时 {1}ms）" -f $output.Count, $result.stats.queryTimeInMs) -ForegroundColor Green
    Write-Host "查询语句: $Query" -ForegroundColor DarkGray

    return $output
}

# 设置工作区上下文
$script:SubscriptionId = "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
$script:ResourceGroupName = "rg-monitoring"
$script:WorkspaceName = "law-production"

# 确保已连接到正确的订阅
$null = Set-AzContext -SubscriptionId $script:SubscriptionId

# 查询最近 24 小时的 Heartbeat 数据，确认各服务器在线状态
$query = @"
Heartbeat
| summarize LastSeen=max(TimeGenerated) by Computer, OSType
| order by LastSeen desc
"@

$heartbeat = Invoke-LogAnalyticsQuery -WorkspaceId $script:WorkspaceId -Query $query
$heartbeat | Format-Table -AutoSize
```

执行结果示例：

```
查询完成，返回 12 行数据（耗时 342ms）
查询语句: Heartbeat | summarize LastSeen=max(TimeGenerated) by Computer, OSType

Computer           OSType  LastSeen
--------           ------  --------
prod-web-01        Linux   2026-03-24T07:58:32Z
prod-web-02        Linux   2026-03-24T07:58:28Z
prod-db-01         Linux   2026-03-24T07:57:45Z
prod-app-01        Windows 2026-03-24T07:58:10Z
prod-app-02        Windows 2026-03-24T07:58:05Z
staging-web-01     Linux   2026-03-24T07:55:12Z
dev-box-01         Linux   2026-03-24T07:30:00Z
```

Heartbeat 查询是 Log Analytics 的入门必备——它告诉你哪些服务器正在正常上报日志。如果某台机器的 LastSeen 时间明显落后，说明 Log Analytics Agent 可能已停止工作或网络中断。这个函数封装了 API 调用和结果解析的细节，后续所有查询都可以直接复用。

## 运维分析查询

掌握基础查询后，可以构建面向运维场景的分析脚本。下面的函数集成了三个常见的运维分析维度：性能趋势分析（CPU/内存）、错误日志统计、以及安全事件检索，每个维度都通过精心编写的 KQL 语句实现高效聚合。

```powershell
function Get-LogAnalyticsOpsReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$WorkspaceId,

        [Parameter(Mandatory = $false)]
        [int]$HoursBack = 24
    )

    $startTime = (Get-Date).AddHours(-$HoursBack)
    $endTime = Get-Date

    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host "Log Analytics 运维分析报告" -ForegroundColor Cyan
    Write-Host "时间范围: $($startTime.ToString('yyyy-MM-dd HH:mm')) ~ $($endTime.ToString('yyyy-MM-dd HH:mm'))"
    Write-Host ("=" * 70) -ForegroundColor Cyan

    # 1. 性能趋势分析 - CPU 使用率超过 80% 的虚拟机
    Write-Host "`n[1] CPU 高负载分析 (使用率 > 80%)" -ForegroundColor Yellow
    $cpuQuery = @"
Perf
| where TimeGenerated > ago($($HoursBack)h)
| where ObjectName == 'Processor' and CounterName == '% Processor Time'
| where InstanceName == '_Total'
| summarize AvgCPU=avg(CounterValue), MaxCPU=max(CounterValue), P95CPU=percentile(CounterValue, 95) by Computer
| where AvgCPU > 80 or MaxCPU > 95
| order by AvgCPU desc
| project Computer, AvgCPU=round(AvgCPU, 1), MaxCPU=round(MaxCPU, 1), P95CPU=round(P95CPU, 1)
"@
    $cpuResult = Invoke-LogAnalyticsQuery -WorkspaceId $WorkspaceId -Query $cpuQuery `
        -TimeRangeStart $startTime -TimeRangeEnd $endTime
    $cpuResult | Format-Table -AutoSize

    # 2. 错误日志统计 - 按来源和计算机分组
    Write-Host "`n[2] 错误事件统计 (EventLevelName == 'error')" -ForegroundColor Yellow
    $errorQuery = @"
Event
| where TimeGenerated > ago($($HoursBack)h)
| where EventLevelName == 'error'
| summarize ErrorCount=count() by Computer, Source, EventID
| order by ErrorCount desc
| project Computer, Source, EventID, ErrorCount
"@
    $errorResult = Invoke-LogAnalyticsQuery -WorkspaceId $WorkspaceId -Query $errorQuery `
        -TimeRangeStart $startTime -TimeRangeEnd $endTime
    $errorResult | Format-Table -AutoSize

    # 3. 安全事件检索 - 登录失败和权限变更
    Write-Host "`n[3] 安全事件分析 (登录失败 + 权限变更)" -ForegroundColor Yellow
    $securityQuery = @"
SecurityEvent
| where TimeGenerated > ago($($HoursBack)h)
| where EventID in (4625, 4732, 4733, 4672)
| extend EventType = case(
    EventID == 4625, "LoginFailed",
    EventID == 4732, "MemberAddedToGroup",
    EventID == 4733, "MemberRemovedFromGroup",
    EventID == 4672, "PrivilegeLogon",
    "Unknown"
)
| summarize EventCount=count() by EventType, Computer, TargetUserName
| order by EventCount desc
| project EventType, Computer, TargetUserName, EventCount
"@
    $securityResult = Invoke-LogAnalyticsQuery -WorkspaceId $WorkspaceId -Query $securityQuery `
        -TimeRangeStart $startTime -TimeRangeEnd $endTime
    $securityResult | Format-Table -AutoSize

    # 汇总信息
    Write-Host "`n--- 汇总 ---" -ForegroundColor Cyan
    Write-Host "CPU 高负载主机: $($cpuResult.Count) 台"
    Write-Host "错误事件类型: $(($errorResult | Measure-Object).Count) 种"
    Write-Host "安全事件总数: $(($securityResult | Measure-Object -Property EventCount -Sum).Sum) 条"

    return @{
        CPU    = $cpuResult
        Errors = $errorResult
        Security = $securityResult
    }
}

# 生成最近 24 小时的运维分析报告
$report = Get-LogAnalyticsOpsReport -WorkspaceId "law-production-01" -HoursBack 24
```

执行结果示例：

```
======================================================================
Log Analytics 运维分析报告
时间范围: 2026-03-23 08:00 ~ 2026-03-24 08:00
======================================================================

[1] CPU 高负载分析 (使用率 > 80%)

查询完成，返回 3 行数据（耗时 1205ms）
Computer      AvgCPU MaxCPU P95CPU
--------      ------ ------ ------
prod-app-01   87.3   99.2   94.6
prod-web-02   82.1   96.8   91.3
prod-db-01    80.5   93.4   88.7

[2] 错误事件统计 (EventLevelName == 'error')

查询完成，返回 5 行数据（耗时 876ms）
Computer      Source              EventID ErrorCount
--------      ------              ------- ----------
prod-app-01   Application Error   1000    234
prod-web-01   WAS                 5009    156
prod-db-01    MSSQL               18456   89
prod-web-02   IIS AspNet Core     1001    67
staging-web-01 Docker             1001    42

[3] 安全事件分析 (登录失败 + 权限变更)

查询完成，返回 4 行数据（耗时 1534ms）
EventType              Computer      TargetUserName EventCount
---------              --------      -------------- ----------
LoginFailed            prod-app-01   admin          342
PrivilegeLogon         prod-web-01   SYSTEM         128
LoginFailed            prod-db-01    sa             87
MemberAddedToGroup     prod-app-01   svc_deploy     5

--- 汇总 ---
CPU 高负载主机: 3 台
错误事件类型: 5 种
安全事件总数: 562 条
```

运维报告揭示了几个值得关注的信号：prod-app-01 的 CPU 平均使用率 87.3% 且伴有大量登录失败事件（342 次 admin 账户登录失败），这很可能是暴力破解攻击与资源争用的组合；prod-db-01 出现 89 次 MSSQL 18456 错误（登录认证失败）也印证了这一点。安全事件中的 MemberAddedToGroup 记录表明有 5 次 svc_deploy 账户被加入特权组的操作，需要确认是否为授权变更。

## 自动化报告与告警

将查询结果导出为报告和设置阈值告警是实现运维闭环的关键步骤。下面的脚本实现了定时查询、阈值判断、多渠道通知（邮件 + Webhook）以及 HTML 报告生成，可以直接集成到 Azure Automation Runbook 中作为每日巡检任务运行。

```powershell
function Send-LogAnalyticsAlert {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$WorkspaceId,

        [Parameter(Mandatory = $false)]
        [string]$ReportOutputPath = "$HOME/LogAnalyticsReport_$(Get-Date -Format 'yyyyMMdd').html",

        [Parameter(Mandatory = $false)]
        [string[]]$NotifyEmails = @("ops-team@contoso.com"),

        [Parameter(Mandatory = $false)]
        [string]$WebhookUrl,

        [Parameter(Mandatory = $false)]
        [double]$CpuThreshold = 85,

        [Parameter(Mandatory = $false)]
        [int]$LoginFailThreshold = 50
    )

    $alerts = @()
    $now = Get-Date

    # 查询 CPU 使用率
    $cpuQuery = @"
Perf
| where TimeGenerated > ago(1h)
| where ObjectName == 'Processor' and CounterName == '% Processor Time'
| where InstanceName == '_Total'
| summarize AvgCPU=avg(CounterValue) by Computer
| where AvgCPU > $CpuThreshold
| project Computer, AvgCPU=round(AvgCPU, 1)
"@
    $cpuAlerts = Invoke-LogAnalyticsQuery -WorkspaceId $WorkspaceId -Query $cpuQuery
    foreach ($item in $cpuAlerts) {
        $alerts += [ordered]@{
            Severity    = "Warning"
            Category    = "CPU"
            Computer    = $item.Computer
            Value       = "$($item.AvgCPU)%"
            Threshold   = "$CpuThreshold%"
            Timestamp   = $now.ToString("yyyy-MM-dd HH:mm:ss")
            Description = "CPU 使用率持续超过阈值"
        }
    }

    # 查询登录失败次数
    $loginQuery = @"
SecurityEvent
| where TimeGenerated > ago(1h)
| where EventID == 4625
| summarize FailCount=count() by Computer, TargetUserName
| where FailCount > $LoginFailThreshold
| project Computer, TargetUserName, FailCount
"@
    $loginAlerts = Invoke-LogAnalyticsQuery -WorkspaceId $WorkspaceId -Query $loginQuery
    foreach ($item in $loginAlerts) {
        $alerts += [ordered]@{
            Severity    = "Critical"
            Category    = "Security"
            Computer    = $item.Computer
            Value       = "$($item.FailCount) 次"
            Threshold   = "$LoginFailThreshold 次"
            Timestamp   = $now.ToString("yyyy-MM-dd HH:mm:ss")
            Description = "账户 $($item.TargetUserName) 登录失败次数异常"
        }
    }

    # 生成 HTML 报告
    $htmlBody = @"
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>Log Analytics 告警报告</title>
<style>
body { font-family: 'Segoe UI', sans-serif; margin: 20px; background: #f5f5f5; }
h1 { color: #0078d4; }
table { border-collapse: collapse; width: 100%; background: white; }
th { background: #0078d4; color: white; padding: 10px; text-align: left; }
td { padding: 8px 10px; border-bottom: 1px solid #eee; }
.Warning { color: #ff8c00; font-weight: bold; }
.Critical { color: #d13438; font-weight: bold; }
</style>
</head>
<body>
<h1>Log Analytics 告警报告</h1>
<p>生成时间: $($now.ToString('yyyy-MM-dd HH:mm:ss'))</p>
<p>告警总数: $($alerts.Count)</p>
<table>
<tr><th>级别</th><th>类别</th><th>计算机</th><th>当前值</th><th>阈值</th><th>描述</th><th>时间</th></tr>
"@

    foreach ($alert in $alerts) {
        $cssClass = $alert.Severity
        $htmlBody += "<tr><td class='$cssClass'>$($alert.Severity)</td><td>$($alert.Category)</td><td>$($alert.Computer)</td><td>$($alert.Value)</td><td>$($alert.Threshold)</td><td>$($alert.Description)</td><td>$($alert.Timestamp)</td></tr>"
    }

    $htmlBody += "</table></body></html>"
    $htmlBody | Out-File -FilePath $ReportOutputPath -Encoding utf8
    Write-Host "HTML 报告已保存: $ReportOutputPath" -ForegroundColor Green

    # 发送 Webhook 通知（如 Teams/Slack）
    if ($WebhookUrl -and $alerts.Count -gt 0) {
        $webhookBody = @{
            text = "[Log Analytics 告警] 检测到 $($alerts.Count) 个异常项，请查看报告: $ReportOutputPath"
        } | ConvertTo-Json
        try {
            Invoke-RestMethod -Uri $WebhookUrl -Method POST -Body $webhookBody -ContentType "application/json"
            Write-Host "Webhook 通知已发送" -ForegroundColor Green
        }
        catch {
            Write-Warning "Webhook 发送失败: $($_.Exception.Message)"
        }
    }

    # 输出告警摘要
    if ($alerts.Count -gt 0) {
        Write-Host "`n触发告警 $($alerts.Count) 项:" -ForegroundColor Red
        foreach ($alert in $alerts) {
            $color = if ($alert.Severity -eq "Critical") { "Red" } else { "Yellow" }
            Write-Host ("  [{0}] {1} - {2} ({3})" -f $alert.Severity, $alert.Category, $alert.Computer, $alert.Value) -ForegroundColor $color
        }
    }
    else {
        Write-Host "`n所有指标正常，无告警触发" -ForegroundColor Green
    }

    return $alerts
}

# 执行告警检查并生成报告
$alertResult = Send-LogAnalyticsAlert `
    -WorkspaceId "law-production-01" `
    -ReportOutputPath "$HOME/LogAnalyticsReport_$(Get-Date -Format 'yyyyMMdd').html" `
    -NotifyEmails @("ops-team@contoso.com", "security@contoso.com") `
    -WebhookUrl "https://contoso.webhook.office.com/webhookb2/xxx" `
    -CpuThreshold 85 `
    -LoginFailThreshold 50

# 在 Azure Automation Runbook 中可以配合定时触发使用：
# 每小时运行一次，自动检测 CPU 和安全异常
```

执行结果示例：

```
查询完成，返回 2 行数据（耗时 987ms）
查询语句: Perf | where TimeGenerated > ago(1h) ...
查询完成，返回 1 行数据（耗时 1102ms）
查询语句: SecurityEvent | where TimeGenerated > ago(1h) ...
HTML 报告已保存: /home/admin/LogAnalyticsReport_20260324.html
Webhook 通知已发送

触发告警 3 项:
  [Warning] CPU - prod-app-01 (87.3%)
  [Warning] CPU - prod-web-02 (86.1%)
  [Critical] Security - prod-app-01 (342 次)
```

告警脚本将查询、判断、通知和报告融为一体。CPU 超标的 Warning 告警提示运维团队关注资源瓶颈，而 Security 类别的 Critical 告警（342 次登录失败）则需要立即响应。HTML 报告以表格形式清晰呈现所有异常项，适合通过邮件分发或存档。Webhook 通知则确保 Teams 或 Slack 频道中的值班人员第一时间收到告警推送。

## 注意事项

1. **API 版本兼容性**：本文使用 Azure Monitor Query API 版本 `2024-02-01`，Azure 团队会定期发布新版本。如果脚本返回 400 错误，请查阅 Azure REST API 文档确认当前可用的最新稳定版本，更新 `api-version` 参数即可。

2. **查询性能优化**：KQL 查询应始终在语句开头使用 `TimeGenerated` 过滤条件缩小数据范围。避免对大表做全表扫描，善用 `summarize` 和 `project` 减少Returned列数。对于高频查询场景，建议将结果缓存到本地变量中复用。

3. **权限与认证**：查询 Log Analytics 数据至少需要工作区级别的 `Reader` 角色。如果在 Azure Automation Runbook 中运行，推荐使用 Managed Identity 而非服务主体密钥，避免凭据泄露风险。Runbook 托管身份只需分配 `Log Analytics Reader` 角色即可。

4. **数据保留与成本**：Log Analytics 工作区的默认数据保留期为 30 天，最长可配置 730 天。保留期越长存储成本越高，查询大时间范围数据也会消耗更多计算资源。建议根据合规要求合理设置保留策略，历史数据可导出到 Storage Account 做冷存储。

5. **告警阈值调优**：初始阈值不宜设置过严，否则会产生大量误报导致告警疲劳。建议先以宽松阈值运行一周，收集基线数据后再逐步收紧。对于不同环境（生产/测试/开发）应设置不同的阈值，避免开发环境的正常波动触发生产级别的告警。

6. **敏感数据脱敏**：查询结果中可能包含用户名、IP 地址、SQL 语句等敏感信息。在生成 HTML 报告或发送 Webhook 通知时，务必对敏感字段做脱敏处理。报告文件也应存储在受限访问的路径下，避免未授权人员查看。
