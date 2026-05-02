---
layout: post
date: 2025-11-06 08:00:00
updated: 2025-11-06 08:00:00
title: "PowerShell 技能连载 - Azure Monitor 告警"
description: PowerTip of the Day - Azure Monitor Alerts in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure-monitor
- alerting
- cloud
- observability
---

_适用于 PowerShell 5.1 及以上版本_

Azure Monitor 是微软 Azure 平台的核心可观测性服务，提供指标采集、日志分析、告警通知等一站式监控能力。在云原生架构日益复杂的今天，运维团队往往需要管理数十甚至上百个 Azure 资源的监控策略。手动在 Azure 门户中逐一配置告警规则既耗时又容易遗漏，而通过 PowerShell 自动化管理告警，可以实现告警策略的标准化、版本化和批量部署。

本文将介绍如何使用 PowerShell 和 Az 模块操作 Azure Monitor 告警，包括查看现有告警规则、创建指标告警、配置操作组（Action Group）实现通知推送，以及批量管理告警规则。这些方法适用于日常运维自动化，也能与基础设施即代码（IaC）流程相结合，确保监控策略随应用部署同步更新。

在开始之前，请确保已安装 Az PowerShell 模块并完成 Azure 身份认证。所有示例基于 Azure 资源管理器（ARM）REST API，需要拥有目标资源组或订阅级别的 Monitoring Contributor 权限。

<!-- more -->

## 连接 Azure 并获取监控资源

第一步是连接 Azure 账户并获取目标资源的信息。告警规则需要绑定到具体的 Azure 资源（如虚拟机、App Service、SQL 数据库等），因此我们先确认订阅上下文并查询需要监控的资源列表。

```powershell
# 安装 Az 监控相关模块
Install-Module -Name Az.Accounts, Az.Monitor, Az.Resources -Force -Scope CurrentUser

# 连接 Azure 账户
Connect-AzAccount

# 获取当前订阅信息
$context = Get-AzContext
$subscriptionId = $context.Subscription.Id
Write-Host ("当前订阅: {0} ({1})" -f $context.Subscription.Name, $subscriptionId)

# 查询目标资源组中的虚拟机
$resourceGroupName = "rg-production"
$vms = Get-AzVM -ResourceGroupName $resourceGroupName

Write-Host "`n===== 资源组中的虚拟机 =====" -ForegroundColor Cyan
foreach ($vm in $vms) {
    $status = (Get-AzVM -ResourceGroupName $resourceGroupName -Name $vm.Name -Status).Statuses[1].DisplayStatus
    Write-Host ("  {0,-30} {1}" -f $vm.Name, $status)
}

# 选取第一台虚拟机的资源 ID 作为后续示例
$targetResourceId = $vms[0].Id
Write-Host ("`n目标资源 ID: {0}" -f $targetResourceId)
```

执行结果示例：

```text
当前订阅: Production-Subscription (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)

===== 资源组中的虚拟机 =====
  vm-web-01                      VM running
  vm-web-02                      VM running
  vm-db-01                       VM running
  vm-api-01                      VM deallocated

目标资源 ID: /subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/rg-production/providers/Microsoft.Compute/virtualMachines/vm-web-01
```

连接成功后，我们得到了目标资源的完整 ID。后续创建告警规则时，需要将这个资源 ID 作为监控的目标范围（Scope）。如果需要监控整个资源组或订阅级别的指标，可以使用资源组 ID 或订阅 ID 作为范围。

## 创建指标告警规则

Azure Monitor 的指标告警（Metric Alert）是最常用的告警类型，它基于资源发出的性能指标数据进行评估。以下代码演示如何为虚拟机创建 CPU 使用率告警，当 CPU 平均使用率连续 5 分钟超过 85% 时触发告警。

```powershell
# 定义告警规则参数
$alertRuleName = "cpu-high-vm-web-01"
$alertDescription = "虚拟机 CPU 使用率连续 5 分钟超过 85%，可能影响应用性能"
$windowSize = "PT5M"
$evaluationFrequency = "PT1M"
$threshold = 85
$operator = "GreaterThan"
$aggregation = "Average"
$severity = 2

# 获取目标虚拟机的资源 ID
$targetVm = Get-AzVM -ResourceGroupName $resourceGroupName -Name "vm-web-01"

# 创建告警条件
$condition = New-AzMetricAlertRuleV2Criteria `
    -MetricName "Percentage CPU" `
    -TimeAggregation $aggregation `
    -Operator $operator `
    -Threshold $threshold

# 创建告警规则
$alertRule = New-AzMetricAlertRuleV2 `
    -Name $alertRuleName `
    -ResourceGroupName $resourceGroupName `
    -WindowSize $windowSize `
    -Frequency $evaluationFrequency `
    -TargetResourceId $targetVm.Id `
    -Condition $condition `
    -Severity $severity `
    -Description $alertDescription `
    -Enabled

if ($alertRule) {
    Write-Host "指标告警规则创建成功!" -ForegroundColor Green
    Write-Host ("  规则名称: {0}" -f $alertRule.Name)
    Write-Host ("  目标资源: {0}" -f $targetVm.Name)
    Write-Host ("  监控指标: Percentage CPU")
    Write-Host ("  聚合方式: {0}" -f $aggregation)
    Write-Host ("  阈值: {0} {1}" -f $operator, $threshold)
    Write-Host ("  检测窗口: {0}" -f $windowSize)
    Write-Host ("  评估频率: {0}" -f $evaluationFrequency)
    Write-Host ("  严重级别: Sev{0}" -f $severity)
}
```

执行结果示例：

```text
指标告警规则创建成功!
  规则名称: cpu-high-vm-web-01
  目标资源: vm-web-01
  监控指标: Percentage CPU
  聚合方式: Average
  阈值: GreaterThan 85
  检测窗口: PT5M
  评估频率: PT1M
  严重级别: Sev2
```

指标告警规则的几个关键参数需要根据实际场景调优。`WindowSize`（检测窗口）决定了评估指标的时间跨度，`Frequency`（评估频率）决定了多久检查一次条件。窗口越大越不容易产生误报，但响应时间也会变长。对于关键业务系统，建议采用较短的窗口（如 PT1M 到 PT5M），配合适度的阈值，在灵敏度和稳定性之间取得平衡。

## 配置操作组实现告警通知

告警规则触发后，需要有渠道将通知送达运维人员。Azure Monitor 的操作组（Action Group）定义了告警触发时的响应动作，包括发送邮件、短信、Webhook、调用 Azure Function 等。以下代码展示如何创建一个操作组，包含邮件通知和 Webhook 两种动作。

```powershell
# 创建邮件接收人
$emailReceiver = New-AzActionGroupReceiver `
    -Name "ops-team-email" `
    -EmailAddress "ops-team@example.com"

# 创建 Webhook 接收（可对接企业 IM、事件管理平台）
$webhookReceiver = New-AzActionGroupReceiver `
    -Name "incident-webhook" `
    -WebhookUri "https://hooks.example.com/azure-alerts/incident"

# 创建操作组
$actionGroupName = "ag-production-critical"
$actionGroupShortName = "prod-crit"

$actionGroup = Set-AzActionGroup `
    -Name $actionGroupName `
    -ResourceGroupName $resourceGroupName `
    -ShortName $actionGroupShortName `
    -Receiver $emailReceiver, $webhookReceiver

if ($actionGroup) {
    Write-Host "操作组创建成功!" -ForegroundColor Green
    Write-Host ("  操作组名称: {0}" -f $actionGroup.Name)
    Write-Host ("  短名称: {0}" -f $actionGroup.ShortName)
    Write-Host ("  接收人数量: {0}" -f $actionGroup.Receivers.Count)
    Write-Host "`n  接收人详情:" -ForegroundColor Cyan
    foreach ($receiver in $actionGroup.Receivers) {
        Write-Host ("    - {0}: {1}" -f $receiver.Name, $receiver.EmailAddress)
    }
}

# 将操作组关联到告警规则
$actionGroupId = (Get-AzActionGroup -ResourceGroupName $resourceGroupName -Name $actionGroupName).Id

# 创建动作引用
$action = New-AzAlertRuleAction -ActionGroupId $actionGroupId

Write-Host "`n操作组已就绪，可关联到告警规则。" -ForegroundColor Green
Write-Host ("  Action Group ID: {0}" -f $actionGroupId)
```

执行结果示例：

```text
操作组创建成功!
  操作组名称: ag-production-critical
  短名称: prod-crit
  接收人数量: 2

  接收人详情:
    - ops-team-email: ops-team@example.com
    - incident-webhook:

操作组已就绪，可关联到告警规则。
  Action Group ID: /subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/rg-production/providers/microsoft.insights/actionGroups/ag-production-critical
```

操作组设计为独立于告警规则的资源，这意味着一个操作组可以被多条告警规则复用。建议按照团队或响应级别来组织操作组，例如"生产环境-紧急"、"生产环境-警告"、"测试环境-通知"等。当团队成员变动时，只需修改操作组即可，无需逐条更新告警规则。

## 批量查询和管理告警规则

在大型 Azure 环境中，告警规则可能多达数十甚至上百条。手动逐条检查既不现实也容易遗漏。以下代码展示如何批量查询告警规则的状态，并生成一份告警规则清单报告。

```powershell
# 查询资源组中所有指标告警规则
$alertRules = Get-AzMetricAlertRuleV2 -ResourceGroupName $resourceGroupName

Write-Host "===== 告警规则清单 =====" -ForegroundColor Cyan
Write-Host ("资源组: {0}" -f $resourceGroupName)
Write-Host ("规则总数: {0}" -f $alertRules.Count)
Write-Host ""

# 构建告警规则报告
$reportData = foreach ($rule in $alertRules) {
    $targetResources = @()
    foreach ($scope in $rule.Scopes) {
        $parts = $scope -split "/"
        $resourceName = $parts[-1]
        $targetResources += $resourceName
    }

    $criteria = $rule.Criteria
    $metricName = if ($criteria.AllOf) { $criteria.AllOf[0].MetricName } else { "N/A" }
    $thresholdValue = if ($criteria.AllOf) { $criteria.AllOf[0].Threshold } else { "N/A" }
    $operatorValue = if ($criteria.AllOf) { $criteria.AllOf[0].OperatorProperty } else { "N/A" }

    [PSCustomObject]@{
        规则名称   = $rule.Name
        严重级别   = "Sev{0}" -f $rule.Severity
        启用状态   = if ($rule.Enabled) { "已启用" } else { "已禁用" }
        监控指标   = $metricName
        阈值条件   = "{0} {1}" -f $operatorValue, $thresholdValue
        检测窗口   = $rule.WindowSize
        目标资源   = ($targetResources -join ", ")
        操作组     = if ($rule.Actions.Count -gt 0) { "已配置 ({0} 个)" -f $rule.Actions.Count } else { "未配置" }
    }
}

# 按严重级别排序并输出
$sortedReport = $reportData | Sort-Object 严重级别, 规则名称

foreach ($item in $sortedReport) {
    Write-Host "---" -ForegroundColor Gray
    Write-Host ("  规则名称: {0}" -f $item.规则名称)
    Write-Host ("  严重级别: {0}" -f $item.严重级别)
    Write-Host ("  启用状态: {0}" -f $item.启用状态)
    Write-Host ("  监控指标: {0}" -f $item.监控指标)
    Write-Host ("  阈值条件: {0}" -f $item.阈值条件)
    Write-Host ("  检测窗口: {0}" -f $item.检测窗口)
    Write-Host ("  目标资源: {0}" -f $item.目标资源)
    Write-Host ("  操作组:   {0}" -f $item.操作组)
}

# 导出 CSV 报告
$reportPath = Join-Path $env:TEMP "AlertRules-Report-{0:yyyyMMdd}.csv" -f (Get-Date)
$sortedReport | Export-Csv -Path $reportPath -NoTypeInformation -Encoding UTF8
Write-Host ("`n报告已导出: {0}" -f $reportPath) -ForegroundColor Green

# 检查未配置操作组的规则
$noActionRules = $reportData | Where-Object { $_.操作组 -eq "未配置" }
if ($noActionRules) {
    Write-Host "`n[警告] 以下告警规则未配置操作组，触发后不会发送通知:" -ForegroundColor Yellow
    foreach ($rule in $noActionRules) {
        Write-Host ("  - {0}" -f $rule.规则名称) -ForegroundColor Yellow
    }
}
```

执行结果示例：

```text
===== 告警规则清单 =====
资源组: rg-production
规则总数: 8

---
  规则名称: cpu-high-vm-api-01
  严重级别: Sev2
  启用状态: 已启用
  监控指标: Percentage CPU
  阈值条件: GreaterThan 90
  检测窗口: 00:05:00
  目标资源: vm-api-01
  操作组:   已配置 (1 个)
---
  规则名称: cpu-high-vm-web-01
  严重级别: Sev2
  启用状态: 已启用
  监控指标: Percentage CPU
  阈值条件: GreaterThan 85
  检测窗口: 00:05:00
  目标资源: vm-web-01
  操作组:   已配置 (2 个)
---
  规则名称: disk-space-vm-db-01
  严重级别: Sev3
  启用状态: 已启用
  监控指标: OsDisk.Used
  阈值条件: GreaterThan 80
  检测窗口: 00:10:00
  目标资源: vm-db-01
  操作组:   未配置

报告已导出: /tmp/AlertRules-Report-20251106.csv

[警告] 以下告警规则未配置操作组，触发后不会发送通知:
  - disk-space-vm-db-01
```

批量审查告警规则是运维巡检的重要环节。脚本中特别加入了"未配置操作组"的检测逻辑——一条没有操作组的告警规则即使被触发，也不会通知任何人，形同虚设。建议将此脚本纳入定期巡检流程，确保所有告警规则都处于有效工作状态。

## 使用日志查询告警

除了指标告警，Azure Monitor 还支持基于 Log Analytics 日志查询的告警。日志告警使用 KQL（Kusto Query Language）编写查询条件，能够对结构化日志数据进行复杂的关联分析。以下示例展示如何通过 PowerShell 创建一条日志告警，检测异常登录行为。

```powershell
# 定义日志告警参数
$logAlertName = "anomalous-signin-detection"
$logAlertDescription = "检测 1 小时内同一账户从不同地区登录的行为，可能表示凭据泄露"
$workspaceResourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.OperationalInsights/workspaces/law-production"

# 构建 KQL 查询
$kqlQuery = @"
SigninLogs
| where TimeGenerated > ago(1h)
| where ResultType == 0
| summarize LoginCount = count(), DistinctLocations = dcount(Location),
    Locations = make_set(Location, 10) by UserPrincipalName
| where DistinctLocations > 2
| project TimeGenerated = now(), UserPrincipalName, LoginCount, DistinctLocations, Locations
| order by DistinctLocations desc
"@

# 创建日志查询告警的条件
$schedule = New-AzScheduledQueryRuleScheduleObject `
    -FrequencyInMinutes 15 `
    -TimeWindowInMinutes 60

$conditionObject = New-AzScheduledQueryRuleConditionObject `
    -Query $kqlQuery `
    -TimeWindow (New-TimeSpan -Minutes 60)

# 创建日志告警规则
$logAlert = New-AzScheduledQueryRule `
    -Name $logAlertName `
    -ResourceGroupName $resourceGroupName `
    -Location "eastus" `
    -DisplayName "异常登录行为检测" `
    -Description $logAlertDescription `
    -Severity 2 `
    -Enabled `
    -Schedule $schedule `
    -Condition $conditionObject `
    -Scope $workspaceResourceId

if ($logAlert) {
    Write-Host "日志查询告警规则创建成功!" -ForegroundColor Green
    Write-Host ("  规则名称: {0}" -f $logAlert.Name)
    Write-Host ("  显示名称: {0}" -f $logAlert.DisplayName)
    Write-Host ("  严重级别: Sev{0}" -f $logAlert.Severity)
    Write-Host ("  查询频率: 每 {0} 分钟" -f $schedule.FrequencyInMinutes)
    Write-Host ("  查询窗口: {0} 分钟" -f $schedule.TimeWindowInMinutes)
    Write-Host ("  目标工作区: {0}" -f ($workspaceResourceId -split "/")[-1])
}
```

执行结果示例：

```text
日志查询告警规则创建成功!
  规则名称: anomalous-signin-detection
  显示名称: 异常登录行为检测
  严重级别: Sev2
  查询频率: 每 15 分钟
  查询窗口: 60 分钟
  目标工作区: law-production
```

日志告警的灵活性远高于指标告警，但代价是更高的 Log Analytics 查询成本。编写 KQL 查询时，务必使用 `where` 子句尽早过滤数据，减少扫描的数据量。`TimeWindow` 参数决定查询回溯的时间范围，`Frequency` 参数决定查询的执行间隔，两者的设置需要平衡检测时效性和运行成本。

## 注意事项

1. **权限配置**：操作 Azure Monitor 告警需要 `Microsoft.Insights/metricAlerts/*` 和 `Microsoft.Insights/actionGroups/*` 等权限。建议创建 Azure 自定义角色，仅授予 Monitoring Contributor 级别的权限，避免使用 Owner 或 Contributor 等过宽的角色。在多团队协作环境中，通过角色划分明确告警管理的责任边界。

2. **告警疲劳治理**：阈值设置不当会导致大量无效告警（Alert Fatigue），使运维人员逐渐忽视告警通知。建议先以较宽松的阈值试运行一周，观察触发频率后再逐步收紧。对于非关键指标，可以设置较高的严重级别（Sev3 或 Sev4），减少高频告警的干扰。

3. **API 版本管理**：`Az.Monitor` 模块中的 cmdlet 对应不同版本的 ARM API，行为可能随模块更新而变化。生产脚本中应固定 Az 模块版本（如 `RequiredVersion`），并在升级前在测试环境中验证兼容性。同时关注 Azure 更新公告，了解 Breaking Change。

4. **操作组测试**：创建操作组后，务必使用 Azure 门户的"测试操作组"功能或手动触发一条测试告警，确认邮件和 Webhook 通知能够正常送达。Webhook 端点可能存在防火墙规则或认证配置问题，仅靠创建成功的返回值无法验证端到端的可达性。

5. **成本控制**：日志告警基于 Log Analytics 查询，每次执行都会消耗数据扫描量。高频的日志告警（如每分钟执行一次复杂查询）可能产生显著的额外费用。建议在 Azure Cost Management 中设置预算告警，监控 Monitor 服务的月度开支，并对查询频率和复杂度进行成本效益评估。

6. **告警规则即代码**：将告警规则的定义保存在 JSON 或 PowerShell 脚本文件中，通过 Git 进行版本管理。这样不仅能追踪每次阈值调整的历史，还能在灾难恢复场景中快速重建完整的监控体系。结合 Azure DevOps Pipeline 或 GitHub Actions，可以实现告警规则的自动部署和审批流程。
