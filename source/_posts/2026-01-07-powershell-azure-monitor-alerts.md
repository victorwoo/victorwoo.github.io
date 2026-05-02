---
layout: post
date: 2026-01-07 08:00:00
updated: 2026-01-07 08:00:00
title: "PowerShell 技能连载 - Azure Monitor 告警自动化"
description: PowerTip of the Day - Azure Monitor Alert Automation
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure
- monitoring
---

_适用于 PowerShell 7.0 及以上版本_

Azure Monitor 是 Azure 的统一监控平台，负责收集、分析和处理来自云资源与应用的指标和日志数据。随着云基础设施规模的不断增长，运维团队需要面对成百上千个资源的健康状态监控需求，手动在门户中逐个配置告警规则既繁琐又容易遗漏关键阈值。

通过 PowerShell 与 Az 模块的结合，我们可以将告警规则的创建、通知动作组的配置以及告警历史查询全部脚本化。这不仅大幅提升了部署效率，还让告警策略成为代码的一部分，可以纳入版本控制和 CI/CD 流水线进行审计与回滚。

本文将围绕三个核心场景展开：指标告警规则的批量创建、基于 Log Analytics 日志查询的告警与通知配置、以及告警生命周期管理与健康合规审计。掌握这些技巧后，你可以轻松实现可观测性即代码（Observability as Code）的实践。

<!-- more -->

## 创建指标告警规则

在 Azure Monitor 中，指标告警（Metric Alert）是最常用的监控手段之一。当某个资源的性能指标（如 CPU 使用率、内存占用、磁盘 I/O）超过预设阈值时，系统会自动触发告警。下面我们通过 PowerShell 批量创建标准化的指标告警规则。

```powershell
function New-AzMetricAlertRule {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory)]
        [string]$TargetResourceId,

        [Parameter(Mandatory)]
        [string]$AlertName,

        [Parameter(Mandatory)]
        [string]$MetricName,

        [Parameter(Mandatory)]
        [double]$Threshold,

        [Parameter()]
        [string]$Operator = 'GreaterThan',

        [Parameter()]
        [string]$TimeAggregation = 'Average',

        [Parameter()]
        [string]$WindowSize = 'PT5M',

        [Parameter()]
        [string]$EvaluationFrequency = 'PT1M',

        [Parameter()]
        [string]$Severity = '2'
    )

    $condition = New-AzMetricAlertRuleV2Criteria `
        -MetricName $MetricName `
        -TimeAggregation $TimeAggregation `
        -Operator $Operator `
        -Threshold $Threshold

    $params = @{
        ResourceGroupName     = $ResourceGroupName
        Name                  = $AlertName
        TargetResourceId      = $TargetResourceId
        Criterion             = $condition
        WindowSize            = $WindowSize
        EvaluationFrequency   = $EvaluationFrequency
        Severity              = $Severity
        AutoMitigate          = $true
    }

    if ($PSCmdlet.ShouldProcess($AlertName, '创建指标告警规则')) {
        Add-AzMetricAlertRuleV2 @params
    }
}

# 定义标准告警模板
$alertTemplates = @(
    @{
        Name       = 'cpu-high'
        Metric     = 'Percentage CPU'
        Threshold  = 85
        Window     = 'PT5M'
        Severity   = '2'
    }
    @{
        Name       = 'memory-high'
        Metric     = 'Available Memory Bytes'
        Threshold  = 1073741824  # 1 GB
        Window     = 'PT5M'
        Severity   = '2'
    }
    @{
        Name       = 'disk-read-latency'
        Metric     = 'Average Read Latency'
        Threshold  = 30  # 毫秒
        Window     = 'PT10M'
        Severity   = '3'
    }
)

# 获取目标资源并批量创建告警
$vms = Get-AzVM -ResourceGroupName 'prod-rg'
foreach ($vm in $vms) {
    $resourceId = $vm.Id
    foreach ($template in $alertTemplates) {
        New-AzMetricAlertRule `
            -ResourceGroupName 'prod-rg' `
            -TargetResourceId $resourceId `
            -AlertName "$($vm.Name)-$($template.Name)" `
            -MetricName $template.Metric `
            -Threshold $template.Threshold `
            -WindowSize $template.Window `
            -Severity $template.Severity
    }
    Write-Host "已为 VM [$($vm.Name)] 创建 $($alertTemplates.Count) 条告警规则"
}
```

执行结果示例：

```
已为 VM [web-frontend-01] 创建 3 条告警规则
已为 VM [web-frontend-02] 创建 3 条告警规则
已为 VM [api-backend-01] 创建 3 条告警规则
已为 VM [db-primary-01] 创建 3 条告警规则

Location   Name                                Severity IsEnabled
--------   ----                                -------- ---------
eastasia   web-frontend-01-cpu-high            2        True
eastasia   web-frontend-01-memory-high         2        True
eastasia   web-frontend-01-disk-read-latency   3        True
```

通过模板化的方式，我们为每个虚拟机统一创建了 CPU、内存和磁盘延迟三个维度的告警。`AutoMitigate` 参数设为 `$true` 表示当指标恢复到阈值以下时告警会自动解除，避免告警堆积。

## 日志查询告警与动作组配置

指标告警关注的是实时数值，而日志查询告警（Log Alert）则更适合检测复杂模式和趋势。结合 Log Analytics 的 Kusto 查询语言（KQL），我们可以编写更灵活的检测逻辑。同时，动作组（Action Group）定义了告警触发后的通知方式，包括邮件、短信、Webhook 等。

```powershell
function New-AzLogAlertWithActionGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory)]
        [string]$AlertName,

        [Parameter(Mandatory)]
        [string]$Query,

        [Parameter(Mandatory)]
        [string]$WorkspaceId,

        [Parameter(Mandatory)]
        [string]$ActionGroupId,

        [Parameter()]
        [int]$ThresholdValue = 0,

        [Parameter()]
        [string]$Operator = 'GreaterThan',

        [Parameter()]
        [string]$TimeRange = 'PT1H',

        [Parameter()]
        [string]$EvaluationFrequency = 'PT30M',

        [Parameter()]
        [string]$Severity = '2'
    )

    # 创建日志查询计划
    $schedule = New-AzScheduledQueryRuleScheduleObject `
        -FrequencyInMinutes ([int]$EvaluationFrequency.TrimStart('PT','M')) `
        -TimeWindowInMinutes ([int]$TimeRange.TrimStart('PT','H') * 60)

    # 创建评估条件
    $condition = New-AzScheduledQueryRuleConditionObject `
        -Query $Query `
        -TimeAggregationMethod 'Count' `
        -Operator $Operator `
        -Threshold $ThresholdValue

    # 创建告警规则并关联动作组
    $params = @{
        ResourceGroupName = $ResourceGroupName
        Name              = $AlertName
        Scopes            = @($WorkspaceId)
        Severity          = $Severity
        Enabled           = $true
        EvaluationSchedule = $schedule
        ConditionAllOf     = $condition
        ActionGroupId      = $ActionGroupId
    }

    New-AzScheduledQueryRule @params
}

# 创建动作组（邮件 + Webhook 通知）
$actionEmail = @{
    Name         = 'notify-ops-team'
    EmailAddress = 'ops-team@contoso.com'
}
$actionWebhook = @{
    Name       = 'trigger-incident-system'
    ServiceUri = 'https://hooks.incident.contoso.com/api/alert'
}

$actionGroup = Set-AzActionGroup `
    -ResourceGroupName 'monitoring-rg' `
    -Name 'ops-oncall-action-group' `
    -EmailReceiver $actionEmail `
    -WebhookReceiver $actionWebhook

# 检测 HTTP 5xx 错误激增的日志告警
$errorQuery = @"
let threshold = 50;
AppRequests
| where TimeGenerated > ago(1h)
| where ResultCode startswith '5'
| summarize ErrorCount = count() by bin(TimeGenerated, 5m)
| where ErrorCount > threshold
| order by TimeGenerated desc
"@

New-AzLogAlertWithActionGroup `
    -ResourceGroupName 'monitoring-rg' `
    -AlertName 'http-5xx-spike-detection' `
    -Query $errorQuery `
    -WorkspaceId '/subscriptions/xxxx/resourceGroups/monitoring-rg/providers/Microsoft.OperationalInsights/workspaces/prod-la' `
    -ActionGroupId $actionGroup.Id `
    -ThresholdValue 0 `
    -Operator 'GreaterThan' `
    -TimeRange 'PT1H' `
    -EvaluationFrequency 'PT15M' `
    -Severity '1'

Write-Host "日志告警规则已创建，动作组 ID: $($actionGroup.Id)"
```

执行结果示例：

```
Name                 : http-5xx-spike-detection
Enabled              : True
Severity             : 1
Query                : let threshold = 50;AppRequests| where ...
EvaluationFrequency  : PT15M
WindowSize           : PT1H
ActionGroup          : /subscriptions/xxxx/resourceGroups/monitoring-rg/providers/microsoft.insights/actionGroups/ops-oncall-action-group

日志告警规则已创建，动作组 ID: /subscriptions/xxxx/resourceGroups/monitoring-rg/providers/microsoft.insights/actionGroups/ops-oncall-action-group
```

日志告警与动作组的组合使得告警触发后能同时发送邮件通知运维团队，并通过 Webhook 自动触发事件管理系统创建工单。`Severity = '1'` 表示这是高严重级别告警，确保在通知策略中获得最高优先级处理。

## 告警管理与健康检查

告警规则创建完成后，持续的运维管理同样重要。我们需要定期审查告警历史、在计划维护期间临时静默告警、以及审计告警规则是否符合组织的安全合规要求。以下脚本提供了一套完整的告警生命周期管理工具集。

```powershell
function Get-AzAlertHealthReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ResourceGroupName,

        [Parameter()]
        [datetime]$Since = (Get-Date).AddDays(-7)
    )

    # 查询近期的告警历史
    $alerts = Get-AzAlert -ResourceGroupName $ResourceGroupName `
        -TimeRange "Custom" `
        -StartTime $Since `
        -EndTime (Get-Date)

    $summary = $alerts | Group-Object Severity | ForEach-Object {
        [PSCustomObject]@{
            Severity = switch ($_.Name) {
                'Sev0' { 'Critical'; break }
                'Sev1' { 'Error'; break }
                'Sev2' { 'Warning'; break }
                'Sev3' { 'Informational'; break }
                default { $_.Name }
            }
            Count    = $_.Count
        }
    }

    # 获取所有告警规则并检查合规性
    $rules = Get-AzMetricAlertRuleV2 -ResourceGroupName $ResourceGroupName
    $compliantRules = $rules | Where-Object {
        $_.Criteria.AllOf.Count -gt 0 -and
        $_.WindowSize -match '^PT[0-9]+M$' -and
        $_.Actions.Count -gt 0
    }

    [PSCustomObject]@{
        Period              = "$($Since.ToString('yyyy-MM-dd')) ~ $((Get-Date).ToString('yyyy-MM-dd'))"
        TotalAlerts         = $alerts.Count
        SeverityBreakdown   = $summary
        TotalRules          = $rules.Count
        CompliantRules      = $compliantRules.Count
        ComplianceRate      = if ($rules.Count -gt 0) {
            [math]::Round($compliantRules.Count / $rules.Count * 100, 1)
        } else { 0 }
    }
}

# 批量静默告警（用于计划维护窗口）
function Disable-AzAlertRulesForMaintenance {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string[]]$ResourceGroupNames,

        [Parameter()]
        [string]$Reason = '计划维护窗口'
    )

    $disabledRules = @()

    foreach ($rg in $ResourceGroupNames) {
        $rules = Get-AzMetricAlertRuleV2 -ResourceGroupName $rg
        foreach ($rule in $rules) {
            if ($PSCmdlet.ShouldProcess($rule.Name, "禁用告警规则（$Reason）")) {
                Update-AzMetricAlertRuleV2 `
                    -ResourceGroupName $rg `
                    -Name $rule.Name `
                    -Enabled $false
                $disabledRules += $rule.Name
            }
        }
    }

    Write-Host "已禁用 $($disabledRules.Count) 条告警规则。原因：$Reason"
    Write-Host "维护完成后请运行 Enable-AzAlertRulesForMaintenance 重新启用。"

    return $disabledRules
}

# 生成健康报告
$report = Get-AzAlertHealthReport -ResourceGroupName 'prod-rg'
$report | Format-List

Write-Host "`n--- 告警严重级别分布 ---"
$report.SeverityBreakdown | Format-Table -AutoSize
```

执行结果示例：

```
Period            : 2025-12-31 ~ 2026-01-07
TotalAlerts       : 47
SeverityBreakdown : {@{Severity=Critical; Count=3}, @{Severity=Error; Count=12}, @{Severity=Warning; Count=28}, @{Severity=Informational; Count=4}}
TotalRules        : 24
CompliantRules    : 21
ComplianceRate    : 87.5

--- 告警严重级别分布 ---
Severity       Count
--------       -----
Critical           3
Error             12
Warning           28
Informational      4
```

健康报告展示了过去一周的告警概况，包括各级别的告警数量和告警规则的合规率。合规检查验证了每条规则是否配置了有效的检测条件、合理的时间窗口和关联的动作组。合规率低于 100% 的规则需要人工审查并补充缺失的配置项。

## 注意事项

1. **Az 模块版本要求**：本文使用的 `Az.Monitor` 和 `Az.ScheduledQueryRule` 模块需要 4.0 以上版本。建议运行 `Update-Module Az.Monitor` 确保使用最新版本，旧版本的部分参数名和 API 行为存在差异。

2. **权限配置**：执行告警规则管理操作需要订阅级别的 `Monitoring Contributor` 角色权限。如果仅需要查询告警历史，`Monitoring Reader` 角色即可满足。生产环境中应遵循最小权限原则分配角色。

3. **告警阈值调优**：初次部署告警规则后，建议先设置较宽的阈值并配合低严重级别运行一周，收集实际触发数据后再逐步收紧阈值。过于敏感的阈值会导致告警疲劳，降低团队对真实问题的响应速度。

4. **动作组测试**：创建动作组后务必使用 `Test-AzActionGroup` 或手动触发测试告警，验证邮件和 Webhook 通知链路是否畅通。很多告警沉默事故的根因都是动作组配置错误导致通知未能送达。

5. **维护窗口静默**：批量禁用告警规则时，建议将禁用操作记录到变更管理系统中，并设置自动提醒在维护结束后重新启用。也可以利用告警处理规则（Alert Processing Rule）的静默功能替代直接禁用，这样不需要修改原始规则配置。

6. **日志查询性能**：Log Analytics 查询的执行成本与扫描的数据量成正比。在高频评估（如每 5 分钟一次）的场景下，查询中应尽量添加时间过滤条件和索引列过滤，避免全表扫描导致额外的计费开销和延迟。
