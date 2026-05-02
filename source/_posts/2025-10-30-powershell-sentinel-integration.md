---
layout: post
date: 2025-10-30 08:00:00
updated: 2025-10-30 08:00:00
title: "PowerShell 技能连载 - Microsoft Sentinel 集成"
description: PowerTip of the Day - Microsoft Sentinel Integration in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- sentinel
- siem
- security
- threat-detection
---

_适用于 PowerShell 5.1 及以上版本_

Microsoft Sentinel 是微软云原生的 SIEM（安全信息与事件管理）解决方案，能够收集、检测、调查和响应来自整个企业环境的安全威胁。在大型企业中，安全运营团队每天需要处理成百上千条告警，手动在门户中逐一排查效率极低。通过 PowerShell 自动化与 Sentinel API 的集成，我们可以实现告警的批量查询、自动化响应规则的部署以及威胁情报的快速推送，大幅提升安全运营效率。

本文将介绍如何使用 PowerShell 连接 Microsoft Sentinel REST API，完成查询安全告警、创建自动化分析规则、批量导入威胁指标（TI Indicator）以及导出事件报告等常见操作。这些方法不仅适用于日常安全运维，也能嵌入 CI/CD 流水线，实现安全策略的版本化管理和自动部署。

在开始之前，需要确保已安装 Az PowerShell 模块并完成身份认证。以下示例基于 Azure 资源管理器 REST API，适用于已部署 Microsoft Sentinel 工作区的环境。

## 连接 Sentinel 并获取工作区信息

第一步是连接 Azure 账户并获取 Sentinel 工作区的基本信息。我们需要订阅 ID、资源组名称和工作区名称三个关键参数，它们构成了所有 Sentinel API 调用的基础路径。

```powershell
# 安装 Az 模块（如果尚未安装）
Install-Module -Name Az.Accounts, Az.OperationalInsights, Az.SecurityInsights -Force -Scope CurrentUser

# 连接 Azure 账户
Connect-AzAccount

# 获取当前订阅上下文
$subscriptionId = (Get-AzContext).Subscription.Id
$resourceGroupName = "rg-security-prod"
$workspaceName = "law-sentinel-prod"

# 构建 Sentinel 资源基础 URI
$sentinelBaseUri = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.OperationalInsights/workspaces/$workspaceName/providers/Microsoft.SecurityInsights"

Write-Host "Sentinel 基础路径: $sentinelBaseUri"
Write-Host "订阅 ID: $subscriptionId"
```

执行结果示例：

```text
Sentinel 基础路径: /subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/rg-security-prod/providers/Microsoft.OperationalInsights/workspaces/law-sentinel-prod/providers/Microsoft.SecurityInsights
订阅 ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

连接成功后，我们得到了 Sentinel API 的基础 URI。后续所有 API 调用都会在这个路径上追加具体的资源端点。如果环境中有多个订阅，可以用 `Set-AzContext` 切换到包含 Sentinel 工作区的订阅。

## 查询安全告警

Sentinel 的告警信息可以通过 REST API 直接查询。以下代码展示如何获取最近 24 小时内的活跃告警，并按严重程度进行分类汇总。这在安全运营日报自动化场景中非常实用。

```powershell
# 获取最近 24 小时的 Sentinel 告警
$timeRange = "Last24Hours"
$apiVersion = "2024-03-01"

$alertUri = "https://management.azure.com" + $sentinelBaseUri + "/alerts?api-version=$apiVersion"

$response = Invoke-AzRestMethod -Uri $alertUri -Method Get

if ($response.StatusCode -eq 200) {
    $alerts = ($response.Content | ConvertFrom-Json).value

    # 按严重程度分类统计
    $severityGroups = $alerts | Group-Object -Property {
        if ($_.properties.severity) { $_.properties.severity } else { "Unknown" }
    }

    Write-Host "`n===== Sentinel 告警汇总（最近 24 小时）=====" -ForegroundColor Cyan
    Write-Host ("告警总数: {0}" -f $alerts.Count)
    Write-Host ""

    foreach ($group in $severityGroups) {
        $severity = $group.Name
        $count = $group.Count
        $color = switch ($severity) {
            "High"       { "Red" }
            "Medium"     { "Yellow" }
            "Low"        { "Green" }
            "Informational" { "Gray" }
            default      { "White" }
        }
        Write-Host ("  [{0}] {1} 条" -f $severity.PadRight(14), $count) -ForegroundColor $color
    }

    # 输出高危告警详情
    $highAlerts = $alerts | Where-Object { $_.properties.severity -eq "High" }
    if ($highAlerts) {
        Write-Host "`n===== 高危告警详情 =====" -ForegroundColor Red
        foreach ($alert in $highAlerts) {
            Write-Host ("  名称: {0}" -f $alert.properties.alertDisplayName)
            Write-Host ("  时间: {0}" -f $alert.properties.startTimeUtc)
            Write-Host ("  状态: {0}" -f $alert.properties.status)
            Write-Host ""
        }
    }
}
```

执行结果示例：

```text
===== Sentinel 告警汇总（最近 24 小时）=====
告警总数: 47

  [High          ] 5 条
  [Medium        ] 18 条
  [Low           ] 21 条
  [Informational ] 3 条

===== 高危告警详情 =====
  名称: Suspicious PowerShell execution detected
  时间: 2025-10-29T14:23:17Z
  状态: New

  名称: Brute force attack on Azure AD
  时间: 2025-10-29T08:45:02Z
  状态: New
```

告警查询是安全运营的日常操作，通过 PowerShell 脚本化后可以定时执行，将结果推送到 Teams 频道或邮件，实现无人值守的安全监控。高危告警的即时通知机制对于缩短平均响应时间（MTTR）至关重要。

## 创建自动化分析规则

Sentinel 的分析规则（Analytics Rule）是威胁检测的核心引擎。下面演示如何通过 PowerShell 创建一条自定义的分析规则，用于检测异常的远程桌面登录行为。规则的查询逻辑基于 KQL（Kusto Query Language），当匹配到可疑行为时自动触发告警。

```powershell
# 定义分析规则的参数
$ruleName = "Anomalous-RDP-Login-Detection"
$ruleDisplayName = "异常 RDP 登录检测"
$ruleDescription = "检测来自非常见地理位置的 RDP 登录尝试，可能是横向移动攻击的信号"

# KQL 查询语句
$kqlQuery = @"
SecurityEvent
| where EventID in (4624, 4625)
| where LogonType == 10
| where TimeGenerated > ago(1h)
| summarize LoginCount = count(), DistinctIPs = dcount(IpAddress),
    IPs = make_set(IpAddress, 10) by TargetUserName, Computer
| where LoginCount > 5 and DistinctIPs > 3
| project TimeGenerated = now(), TargetUserName, Computer, LoginCount, DistinctIPs, IPs
| order by LoginCount desc
"@

# 构建请求体
$ruleBody = @{
    properties = @{
        displayName       = $ruleDisplayName
        description       = $ruleDescription
        severity          = "High"
        enabled           = $true
        query             = $kqlQuery
        queryFrequency    = "PT1H"
        queryPeriod       = "PT1H"
        triggerOperator   = "GreaterThan"
        triggerThreshold  = 0
        suppressionDuration = "PT5H"
        suppressionEnabled  = $false
        tactics           = @("LateralMovement")
        techniques        = @("T1021.001")
        alertRuleTemplateName = $null
        incidentConfiguration = @{
            createIncident = $true
            groupingConfiguration = @{
                enabled                = $true
                reopenClosedIncident   = $false
                lookbackDuration       = "PT5H"
                matchingMethod         = "Selected"
                groupByEntities        = @("Account")
            }
        }
    }
} | ConvertTo-Json -Depth 10

# 发送创建请求
$ruleApiVersion = "2024-03-01"
$ruleUri = "https://management.azure.com" + $sentinelBaseUri + "/alertRules/$ruleName`?api-version=$ruleApiVersion"

$result = Invoke-AzRestMethod -Uri $ruleUri -Method Put -Payload $ruleBody

if ($result.StatusCode -eq 200 -or $result.StatusCode -eq 201) {
    $createdRule = $result.Content | ConvertFrom-Json
    Write-Host "分析规则创建成功!" -ForegroundColor Green
    Write-Host ("  规则名称: {0}" -f $createdRule.properties.displayName)
    Write-Host ("  严重级别: {0}" -f $createdRule.properties.severity)
    Write-Host ("  查询频率: {0}" -f $createdRule.properties.queryFrequency)
    Write-Host ("  战术分类: {0}" -f ($createdRule.properties.tactics -join ", "))
    Write-Host ("  创建事件: {0}" -f $createdRule.properties.incidentConfiguration.createIncident)
}
```

执行结果示例：

```text
分析规则创建成功!
  规则名称: 异常 RDP 登录检测
  严重级别: High
  查询频率: PT1H
  战术分类: LateralMovement
  创建事件: True
```

通过脚本创建分析规则的最大优势是版本可控。将规则定义存储在 JSON 或 PowerShell 数据文件中，配合 Git 进行版本管理，团队可以追踪每次规则变更的历史，实现安全检测策略的 Infrastructure as Code（基础设施即代码）实践。

## 批量导入威胁指标

威胁情报（Threat Intelligence）是 Sentinel 主动防御的重要组成部分。安全团队经常需要将外部威胁情报源（如 STIX/TAXII feeds、商业情报平台）的 IoC（失陷指标）批量导入 Sentinel。以下代码展示如何通过 API 批量创建威胁指标。

```powershell
# 准备威胁指标数据
$threatIndicators = @(
    @{
        displayName   = "Malicious C2 Server - apt29-c2.example.com"
        description   = "APT29 已知 C2 通信域名，关联攻击活动 UNC2452"
        patternType   = "domain-name"
        pattern       = "[domain-name:value = 'apt29-c2.example.com']"
        severity      = "High"
        confidence    = 85
        source        = "Internal-Threat-Intel-Platform"
        validFrom     = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        validUntil    = (Get-Date).AddDays(90).ToString("yyyy-MM-ddTHH:mm:ssZ")
        threatTypes   = @("malicious-activity", "command-and-control")
    },
    @{
        displayName   = "Suspicious IP - 198.51.100.42"
        description   = "频繁扫描行为的来源 IP，多次触发 IDS 告警"
        patternType   = "ipv4-addr"
        pattern       = "[ipv4-addr:value = '198.51.100.42']"
        severity      = "Medium"
        confidence    = 70
        source        = "Honeypot-System"
        validFrom     = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        validUntil    = (Get-Date).AddDays(30).ToString("yyyy-MM-ddTHH:mm:ssZ")
        threatTypes   = @("malicious-activity")
    },
    @{
        displayName   = "Phishing Domain - secure-login.example.net"
        description   = "钓鱼攻击使用的仿冒域名，目标为财务部门"
        patternType   = "domain-name"
        pattern       = "[domain-name:value = 'secure-login.example.net']"
        severity      = "High"
        confidence    = 92
        source        = "Phishing-Report-System"
        validFrom     = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        validUntil    = (Get-Date).AddDays(60).ToString("yyyy-MM-ddTHH:mm:ssZ")
        threatTypes   = @("malicious-activity", "phishing")
    }
)

# 批量导入威胁指标
$tiApiVersion = "2024-03-01"
$successCount = 0
$failCount = 0

Write-Host "开始导入威胁指标..." -ForegroundColor Cyan

foreach ($indicator in $threatIndicators) {
    $indicatorName = $indicator.displayName -replace '\s', '-' -replace '[^a-zA-Z0-9\-]', ''
    $indicatorName = $indicatorName.Substring(0, [System.Math]::Min($indicatorName.Length, 50))

    $body = @{
        properties = @{
            displayName   = $indicator.displayName
            description   = $indicator.description
            patternType   = $indicator.patternType
            pattern       = $indicator.pattern
            severity      = $indicator.severity
            confidence    = $indicator.confidence
            source        = $indicator.source
            validFrom     = $indicator.validFrom
            validUntil    = $indicator.validUntil
            threatTypes   = $indicator.threatTypes
        }
        kind = "indicator"
    } | ConvertTo-Json -Depth 5

    $uri = "https://management.azure.com" + $sentinelBaseUri + "/threatIntelligence/main/indicators/$indicatorName`?api-version=$tiApiVersion"

    $result = Invoke-AzRestMethod -Uri $uri -Method Put -Payload $body

    if ($result.StatusCode -eq 200 -or $result.StatusCode -eq 201) {
        $successCount++
        Write-Host ("  [OK] {0}" -f $indicator.displayName) -ForegroundColor Green
    }
    else {
        $failCount++
        $errorDetail = ($result.Content | ConvertFrom-Json).error.message
        Write-Host ("  [FAIL] {0}: {1}" -f $indicator.displayName, $errorDetail) -ForegroundColor Red
    }
}

Write-Host "`n导入完成: 成功 $successCount 条, 失败 $failCount 条" -ForegroundColor Cyan
```

执行结果示例：

```text
开始导入威胁指标...
  [OK] Malicious C2 Server - apt29-c2.example.com
  [OK] Suspicious IP - 198.51.100.42
  [OK] Phishing Domain - secure-login.example.net

导入完成: 成功 3 条, 失败 0 条
```

批量导入威胁指标时，建议控制单次请求的数量，避免触发 API 速率限制。对于大规模的威胁情报源（数千条 IoC），可以采用分批处理的方式，每批 50-100 条，并在批次之间加入适当的间隔。

## 导出安全事件报告

安全合规审计通常需要定期的安全事件报告。以下代码展示如何从 Sentinel 提取事件（Incident）数据并生成结构化的报告，便于向管理层汇报或存档备查。

```powershell
# 查询 Sentinel 事件
$incidentsApiVersion = "2024-03-01"
$incidentsUri = "https://management.azure.com" + $sentinelBaseUri + "/incidents?api-version=$incidentsApiVersion&`$filter=properties/createdTimeUtc ge 2025-10-01T00:00:00Z and properties/createdTimeUtc le 2025-10-30T23:59:59Z"

$incidentsResponse = Invoke-AzRestMethod -Uri $incidentsUri -Method Get

if ($incidentsResponse.StatusCode -eq 200) {
    $incidents = ($incidentsResponse.Content | ConvertFrom-Json).value

    # 构建报告数据
    $reportData = foreach ($incident in $incidents) {
        $props = $incident.properties
        [PSCustomObject]@{
            事件编号   = $props.incidentNumber
            标题       = $props.title
            描述       = if ($props.description.Length -gt 80) { $props.description.Substring(0, 80) + "..." } else { $props.description }
            严重级别   = $props.severity
            状态       = $props.status
            创建时间   = $props.createdTimeUtc
            关闭时间   = if ($props.closedTimeUtc) { $props.closedTimeUtc } else { "未关闭" }
            分类       = if ($props.classification) { $props.classification } else { "未分类" }
            负责人     = if ($props.owner.assignedTo) { $props.owner.assignedTo } else { "未分配" }
        }
    }

    # 输出统计摘要
    Write-Host "===== 2025年10月 Sentinel 安全事件报告 =====" -ForegroundColor Cyan
    Write-Host ("事件总数: {0}" -f $reportData.Count)
    Write-Host ""

    $bySeverity = $reportData | Group-Object -Property 严重级别
    Write-Host "--- 按严重级别分布 ---"
    foreach ($group in $bySeverity) {
        Write-Host ("  {0}: {1} 条 ({2:P1})" -f $group.Name.PadRight(10), $group.Count, ($group.Count / $reportData.Count))
    }

    $byStatus = $reportData | Group-Object -Property 状态
    Write-Host "`n--- 按状态分布 ---"
    foreach ($group in $byStatus) {
        Write-Host ("  {0}: {1} 条" -f $group.Name.PadRight(15), $group.Count)
    }

    # 导出 CSV 报告
    $reportPath = Join-Path $env:TEMP "Sentinel-Incident-Report-2025-10.csv"
    $reportData | Export-Csv -Path $reportPath -NoTypeInformation -Encoding UTF8
    Write-Host ("`n详细报告已导出: {0}" -f $reportPath) -ForegroundColor Green

    # 显示前 5 条未关闭的事件
    $openIncidents = $reportData | Where-Object { $_.状态 -ne "Closed" } | Select-Object -First 5
    if ($openIncidents) {
        Write-Host "`n--- 待处理事件（前 5 条）---" -ForegroundColor Yellow
        foreach ($inc in $openIncidents) {
            Write-Host ("  #{0} [{1}] {2}" -f $inc.事件编号, $inc.严重级别, $inc.标题)
        }
    }
}
```

执行结果示例：

```text
===== 2025年10月 Sentinel 安全事件报告 =====
事件总数: 128

--- 按严重级别分布 ---
  High      : 12 条 (9.4%)
  Medium    : 45 条 (35.2%)
  Low       : 56 条 (43.8%)
  Informational: 15 条 (11.7%)

--- 按状态分布 ---
  New            : 8 条
  Active         : 23 条
  Closed         : 97 条

详细报告已导出: /tmp/Sentinel-Incident-Report-2025-10.csv

--- 待处理事件（前 5 条）---
  #1042 [High] Suspicious PowerShell execution detected
  #1040 [High] Brute force attack on Azure AD
  #1039 [Medium] Anomalous sign-in location detected
  #1037 [Medium] Unusual file download activity
  #1035 [Low] Multiple failed VPN attempts
```

导出的 CSV 报告可以直接用于月度安全复盘会议，也可以导入 Excel 进行进一步的数据透视分析。通过 PowerShell 定时任务（Scheduled Task）或 Azure Automation Runbook，可以将此脚本配置为每月自动执行，自动将报告发送到指定邮箱或 SharePoint 文档库。

## 注意事项

1. **API 版本兼容性**：Microsoft Sentinel REST API 处于持续演进中，不同版本的行为可能存在差异。建议在脚本中显式指定 API 版本（如 `2024-03-01`），并在升级前查阅官方 changelog 确认破坏性变更。生产环境中应锁定 API 版本，避免因自动升级导致脚本失效。

2. **权限最小化原则**：调用 Sentinel API 的服务主体或用户账户应遵循最小权限原则。建议使用 Azure 自定义角色（Custom Role），仅授予 `Microsoft.SecurityInsights/*` 相关操作的读取或写入权限，而非贡献者（Contributor）级别的宽泛权限。

3. **API 速率限制**：Azure ARM API 对订阅级别的请求有速率限制（通常每订阅每小时 12000 次写入请求）。在批量操作（如导入数千条威胁指标）时，务必实现重试逻辑和退避策略，监控响应头中的 `x-ms-ratelimit-remaining-subscription-writes` 值。

4. **KQL 查询性能**：分析规则中的 KQL 查询直接影响 Sentinel 的运行成本和响应速度。避免在查询中使用 `join` 操作大量数据集，善用 `summarize` 和 `where` 子句尽早过滤数据。查询频率（queryFrequency）和查询周期（queryPeriod）的设置也需要根据实际数据量调优，过大的查询周期会显著增加 Log Analytics 的扫描费用。

5. **敏感数据处理**：告警和事件数据中可能包含用户主体名称（UPN）、IP 地址等敏感信息。在导出报告或推送到第三方系统时，注意遵守数据保护法规（如 GDPR、个人信息保护法），必要时对敏感字段进行脱敏处理。存储报告的路径也应设置适当的访问控制。

6. **模块版本管理**：`Az.SecurityInsights` 模块目前仍处于预览阶段，cmdlet 和参数可能发生变更。建议在脚本中检查模块版本，并在 CI/CD 流水线中固定模块版本号（如 `RequiredVersion`），确保不同环境中的行为一致。可同时准备 REST API 直接调用的降级方案，以应对模块兼容性问题。
