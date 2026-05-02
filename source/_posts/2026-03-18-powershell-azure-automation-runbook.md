---
layout: post
date: 2026-03-18 08:00:00
updated: 2026-03-18 08:00:00
title: "PowerShell 技能连载 - Azure Automation Runbook"
description: PowerTip of the Day - Azure Automation Runbook in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure
- automation
- runbook
- scheduling
---

_适用于 PowerShell 7.0 及以上版本_

在日常运维中，许多任务需要定时执行：清理过期资源、轮转证书、检查合规状态、生成日报。如果依赖人工操作，不仅效率低下，还容易遗漏。Azure Automation 提供了一个托管的 PowerShell 执行环境，让脚本可以在云端按计划自动运行，无需维护本地服务器。

Azure Automation 的核心概念是 **Runbook**——一段托管在云端的 PowerShell 脚本。Runbook 支持多种触发方式：定时计划（Schedule）、Webhook 回调、事件驱动（Event Grid），甚至可以手动启动。它内置了凭据管理、变量存储和模块缓存，使脚本能安全地访问 Azure 资源而不暴露密钥。

本文将围绕三个核心场景展开：创建和管理 Runbook、配置定时计划与 Webhook 触发、以及监控作业状态与日志输出。通过这些实践，你可以构建一个完整的无人值守运维体系。

## 创建 Automation Account 与发布 Runbook

首先需要创建 Automation Account，然后在其中编写和发布 Runbook。以下脚本演示了完整的创建流程，包括模块导入、Runbook 编写、参数配置和发布。

```powershell
# 连接到 Azure
Connect-AzAccount -Subscription 'production-sub'

# 定义变量
$ResourceGroup = 'rg-automation'
$AutomationAccount = 'aa-ops'
$Location = 'eastasia'

# 创建资源组和 Automation Account
New-AzResourceGroup -Name $ResourceGroup -Location $Location -Force

New-AzAutomationAccount `
    -ResourceGroupName $ResourceGroup `
    -Name $AutomationAccount `
    -Location $Location `
    -Plan Basic

# 导入常用模块（确保 Az 模块可用）
$ModuleVersions = @{
    'Az.Accounts'  = '3.0.0'
    'Az.Resources' = '7.0.0'
    'Az.Storage'   = '6.0.0'
}

foreach ($Module in $ModuleVersions.GetEnumerator()) {
    $ModuleUrl = "https://www.powershellgallery.com/api/v2/package/$($Module.Key)/$($Module.Value)"
    New-AzAutomationModule `
        -ResourceGroupName $ResourceGroup `
        -AutomationAccountName $AutomationAccount `
        -Name $Module.Key `
        -ContentLinkUri $ModuleUrl
}

Write-Host "模块导入已提交， provisioning 需要几分钟..."
```

执行结果示例：

```
ResourceGroupName : rg-automation
Location          : eastasia
AutomationAccountName : aa-ops
Plan              : Basic
Status            : Ok

Name              ContentLinkUri
----              ---------------
Az.Accounts       https://www.powershellgallery.com/api/v2/package/Az.Accounts/3.0.0
Az.Resources      https://www.powershellgallery.com/api/v2/package/Az.Resources/7.0.0
Az.Storage        https://www.powershellgallery.com/api/v2/package/Az.Storage/6.0.0
模块导入已提交，provisioning 需要几分钟...
```

接下来编写 Runbook 内容并发布。Runbook 的脚本内容可以通过字符串定义并上传。

```powershell
# Runbook 脚本内容
$RunbookContent = @'
param(
    [string]$ResourceGroupName = 'rg-production',
    [int]$OlderThanDays = 30,
    [bool]$WhatIf = $true
)

$Conn = Get-AutomationConnection -Name 'AzureRunAsConnection'
Connect-AzAccount -ServicePrincipal `
    -Tenant $Conn.TenantId `
    -ApplicationId $Conn.ApplicationId `
    -CertificateThumbprint $Conn.CertificateThumbprint

$CutoffDate = (Get-Date).AddDays(-$OlderThanDays)

$Snapshots = Get-AzSnapshot -ResourceGroupName $ResourceGroupName |
    Where-Object { $_.TimeCreated -lt $CutoffDate }

Write-Output "找到 $($Snapshots.Count) 个超过 $OlderThanDays 天的快照"

foreach ($Snap in $Snapshots) {
    if ($WhatIf) {
        Write-Output "[WhatIf] 将删除快照: $($Snap.Name) (创建于 $($Snap.TimeCreated))"
    } else {
        Remove-AzSnapshot -ResourceGroupName $ResourceGroupName `
            -SnapshotName $Snap.Name -Force
        Write-Output "已删除快照: $($Snap.Name)"
    }
}
'@

# 创建并发布 Runbook
$RunbookName = 'Clean-OldSnapshots'

New-AzAutomationRunbook `
    -ResourceGroupName $ResourceGroup `
    -AutomationAccountName $AutomationAccount `
    -Name $RunbookName `
    -Type PowerShell `
    -Description '清理超过指定天数的磁盘快照'

Set-AzAutomationRunbookContent `
    -ResourceGroupName $ResourceGroup `
    -AutomationAccountName $AutomationAccount `
    -Name $RunbookName `
    -Content $RunbookContent

Publish-AzAutomationRunbook `
    -ResourceGroupName $ResourceGroup `
    -AutomationAccountName $AutomationAccount `
    -Name $RunbookName

Write-Host "Runbook '$RunbookName' 已发布"
```

执行结果示例：

```
RunbookType     : PowerShell
Name            : Clean-OldSnapshots
Description     : 清理超过指定天数的磁盘快照
State           : Published
CreationTime    : 2026-03-18 02:15:00
LastModifiedTime: 2026-03-18 02:15:32

Runbook 'Clean-OldSnapshots' 已发布
```

## 配置定时计划与 Webhook 触发

Runbook 发布后，需要配置触发方式。最常见的两种是定时计划和 Webhook。定时计划适合周期性任务，Webhook 则适合外部系统回调的场景。

```powershell
# --- 定时计划 ---
# 创建每天凌晨 2 点执行的日程
$ScheduleName = 'daily-snapshot-cleanup'

New-AzAutomationSchedule `
    -ResourceGroupName $ResourceGroup `
    -AutomationAccountName $AutomationAccount `
    -Name $ScheduleName `
    -StartTime '2026-03-19T02:00:00+08:00' `
    -DayInterval 1 `
    -Description '每天凌晨清理过期快照'

# 将日程绑定到 Runbook 并传入参数
Register-AzAutomationScheduledRunbook `
    -ResourceGroupName $ResourceGroup `
    -AutomationAccountName $AutomationAccount `
    -RunbookName $RunbookName `
    -ScheduleName $ScheduleName `
    -Parameters @{
        ResourceGroupName = 'rg-production'
        OlderThanDays     = 30
        WhatIf            = $false
    }

Write-Host "定时计划 '$ScheduleName' 已绑定到 Runbook '$RunbookName'"

# --- Webhook 触发 ---
$WebhookName = 'cleanup-trigger'
$ExpiryTime = (Get-Date).AddYears(1)

$Webhook = New-AzAutomationWebhook `
    -ResourceGroupName $ResourceGroup `
    -AutomationAccountName $AutomationAccount `
    -RunbookName $RunbookName `
    -Name $WebhookName `
    -IsEnabled $true `
    -ExpiryTime $ExpiryTime

Write-Host "Webhook URL（仅显示一次，请妥善保存）:"
Write-Host $Webhook.WebhookURI

# --- 关联凭据（使用 Automation 凭据代替明文密码）#
$Cred = Get-Credential -Message '输入服务主体凭据'
New-AzAutomationCredential `
    -ResourceGroupName $ResourceGroup `
    -AutomationAccountName $AutomationAccount `
    -Name 'ServicePrincipalCred' `
    -Value $Cred

Write-Host "凭据已添加到 Automation Account"
```

执行结果示例：

```
ScheduleName    : daily-snapshot-cleanup
StartTime       : 2026-03-19 02:00:00 +08:00
ExpiryTime      : 9999-12-31 23:59:59
Interval        : 1
Frequency       : Day
IsEnabled       : True

定时计划 'daily-snapshot-cleanup' 已绑定到 Runbook 'Clean-OldSnapshots'

WebhookName     : cleanup-trigger
IsEnabled       : True
ExpiryTime      : 2027-03-18 02:30:00
RunbookName     : Clean-OldSnapshots

Webhook URL（仅显示一次，请妥善保存）:
https://s15events.azure-automation.net/webhooks?token=Jvq%2BdGGYaC%2F...masked...
凭据已添加到 Automation Account
```

通过 Webhook 触发 Runbook 的方式很简单，只需发送一个 HTTP POST 请求：

```powershell
# 外部系统通过 Webhook 触发 Runbook
$WebhookUri = 'https://s15events.azure-automation.net/webhooks?token=...'

$Body = @{
    ResourceGroupName = 'rg-staging'
    OlderThanDays     = 14
    WhatIf            = $true
} | ConvertTo-Json

$Response = Invoke-RestMethod -Uri $WebhookUri -Method Post `
    -Body $Body -ContentType 'application/json'

Write-Host "作业已触发，Job ID: $($Response.jobIds[0])"
```

执行结果示例：

```
作业已触发，Job ID: 7a3f9c2e-4b12-4d8a-9e1f-5c6d7b8a1234
```

## 监控作业状态与日志输出

Runbook 每次执行都会产生一个 Job。监控 Job 状态、查看输出日志和配置告警是确保自动化可靠运行的关键。

```powershell
# --- 查询作业状态 ---
# 获取最近 10 个 Job
$Jobs = Get-AzAutomationJob `
    -ResourceGroupName $ResourceGroup `
    -AutomationAccountName $AutomationAccount `
    -RunbookName $RunbookName |
    Sort-Object CreationTime -Descending |
    Select-Object -First 10

$Jobs | Format-Table JobId, Status, CreationTime, StartTime, EndTime -AutoSize

# --- 获取特定 Job 的输出 ---
$LatestJob = $Jobs | Select-Object -First 1

$Output = Get-AzAutomationJobOutput `
    -ResourceGroupName $ResourceGroup `
    -AutomationAccountName $AutomationAccount `
    -Id $LatestJob.JobId

foreach ($Record in $Output) {
    $FullRecord = Get-AzAutomationJobOutputRecord `
        -ResourceGroupName $ResourceGroup `
        -AutomationAccountName $AutomationAccount `
        -JobId $LatestJob.JobId `
        -Id $Record.StreamRecordId
    Write-Host "[$($Record.Type)] $($FullRecord.Value)"
}

# --- 错误处理与告警 ---
$FailedJobs = $Jobs | Where-Object { $_.Status -eq 'Failed' }

if ($FailedJobs) {
    $AlertBody = @{
        text = "Runbook '$RunbookName' 有 $($FailedJobs.Count) 个失败作业"
        details = ($FailedJobs | ForEach-Object {
            "JobId: $($_.JobId), Time: $($_.CreationTime)"
        }) -join '; '
    } | ConvertTo-Json -Depth 3

    # 发送到 Microsoft Teams 或 Slack（示例用 Teams Webhook）
    $TeamsWebhook = 'https://outlook.office.com/webhook/...'

    Invoke-RestMethod -Uri $TeamsWebhook -Method Post `
        -Body $AlertBody -ContentType 'application/json'

    Write-Host "告警已发送，共 $($FailedJobs.Count) 个失败作业"
} else {
    Write-Host "所有作业状态正常"
}

# --- Runbook 内部的结构化日志 ---
# 在 Runbook 脚本中推荐使用 Write-Output 和 Write-Warning
# 配合 $PSItem.ErrorRecord 做异常捕获
$RunbookWithLogging = @'
try {
    $Conn = Get-AutomationConnection -Name 'AzureRunAsConnection'
    Connect-AzAccount -ServicePrincipal `
        -Tenant $Conn.TenantId `
        -ApplicationId $Conn.ApplicationId `
        -CertificateThumbprint $Conn.CertificateThumbprint |
        Out-Null

    Write-Output "[$(Get-Date -Format 'HH:mm:ss')] 连接 Azure 成功"
    Write-Output "[$(Get-Date -Format 'HH:mm:ss')] 开始执行清理任务"

    # ... 主要逻辑 ...

    Write-Output "[$(Get-Date -Format 'HH:mm:ss')] 任务完成"
}
catch {
    $ErrorMsg = "[$(Get-Date -Format 'HH:mm:ss')] 错误: $($_.Exception.Message)"
    Write-Error $ErrorMsg
    throw $ErrorMsg
}
'@

Write-Host "带日志的 Runbook 模板已准备就绪"
```

执行结果示例：

```
JobId                                  Status   CreationTime         StartTime            EndTime
-----                                  ------   ------------         ----------            -------
7a3f9c2e-4b12-4d8a-9e1f-5c6d7b8a1234 Completed 2026-03-18 02:00:12  2026-03-18 02:00:15  2026-03-18 02:01:03
b1e8d3a5-7c09-4f2e-b3d4-8e9f0a1b2c3d Completed 2026-03-17 02:00:08  2026-03-17 02:00:11  2026-03-17 02:00:58
c4f0e2b6-9d21-4a3c-b5e7-1f2a3b4c5d6e Failed    2026-03-16 02:00:05  2026-03-16 02:00:09  2026-03-16 02:00:12

[Output] [02:00:16] 连接 Azure 成功
[Output] [02:00:17] 找到 12 个超过 30 天的快照
[Output] [02:00:18] [WhatIf] 将删除快照: disk-snap-20260115 (创建于 2026-01-15)
[Output] [02:01:03] 任务完成

告警已发送，共 1 个失败作业
带日志的 Runbook 模板已准备就绪
```

## 注意事项

1. **模块版本管理**：Automation Account 中 Az 模块的版本可能与本地不同。发布 Runbook 前务必确认云端模块版本支持你使用的 cmdlet，否则运行时会报"找不到命令"错误。

2. **凭据安全**：不要在 Runbook 中硬编码密码或密钥。使用 `Get-AutomationConnection`、`Get-AutomationCredential` 或 `Get-AutomationVariable` 从 Automation Account 的安全存储中获取敏感信息。

3. **执行时间限制**：Azure Automation 的 Free/Basic 计划中，单个 Job 的最长运行时间为 3 小时。超时后 Job 会被强制挂起（Suspended）。长时间运行的任务应拆分为多个 Runbook 或使用检查点（Checkpoint）。

4. **Webhook URL 安全**：Webhook URL 包含认证令牌，创建后只显示一次。务必妥善保存，泄露后任何人都可触发你的 Runbook。如果怀疑泄露，应立即删除并重建 Webhook。

5. **日志级别选择**：Runbook 中 `Write-Output` 写入的信息会出现在 Job 的 Output 流中，`Write-Warning` 进入 Warning 流，`Write-Error` 进入 Error 流。根据需要选择合适的级别，避免关键信息被大量调试输出淹没。

6. **计划时区注意**：`New-AzAutomationSchedule` 的 `-StartTime` 参数使用 UTC 时间（除非显式指定时区偏移）。如果你的运维窗口是北京时间凌晨 2 点，需要写成 `18:00:00Z` 或 `02:00:00+08:00`。
