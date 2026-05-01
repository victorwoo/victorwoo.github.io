---
layout: post
date: 2026-04-07 08:00:00
title: "PowerShell 技能连载 - Azure Monitor 仪表板自动化"
description: PowerTip of the Day - Azure Monitor Dashboard Automation in PowerShell
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
- dashboard
- observability
---

_适用于 PowerShell 7.0 及以上版本，需要 Az.Monitor 模块_

在云原生运维中，Azure Monitor 仪表板是将海量监控数据转化为可视化洞察的核心工具。通过仪表板，运维团队可以一目了然地掌握虚拟机 CPU 利用率、存储账户延迟、应用网关吞吐量等关键指标，从而快速定位性能瓶颈和潜在故障。然而，当企业规模扩展到数十个订阅、上百个资源时，手动在 Azure 门户中拖拽创建仪表板不仅耗时，而且难以保证一致性。

PowerShell 提供了完整的 Azure Dashboard JSON 模板操控能力，结合 Az.Monitor 模块，我们可以将仪表板的创建、修改和部署完全纳入基础设施即代码（IaC）流程。这意味着每套环境都能拥有标准化的监控视图，变更可追溯、可审计、可回滚，大幅降低人为失误风险。

本文将围绕三个核心场景展开：动态构建仪表板 JSON 模板、配置指标告警与自动通知、以及跨订阅批量部署标准化仪表板，帮助你建立一套完整的 Azure Monitor 仪表板自动化工作流。

## 仪表板 JSON 模板构建

Azure Dashboard 的底层是一个 JSON 文档，定义了每个磁贴（tile）的类型、位置、大小和数据源。我们可以用 PowerShell 哈希表和 `ConvertTo-Json` 动态生成这个结构，实现参数化的仪表板模板。

以下函数封装了仪表板 JSON 的构建逻辑，支持自定义标题、订阅 ID 和资源组参数，并预置了 CPU 和内存两个监控磁贴：

```powershell
function New-AzDashboardTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DashboardName,

        [Parameter(Mandatory)]
        [string]$SubscriptionId,

        [Parameter(Mandatory)]
        [string]$ResourceGroupName,

        [int]$RefreshIntervalSeconds = 300
    )

    $cpuTile = @{
        position = @{ x = 0; y = 0; colSpan = 6; rowSpan = 4 }
        metadata = @{
            type = 'Extension/Microsoft_Azure_Monitoring/PartType/MetricsChartPart'
            inputs = @(
                @{
                    name = 'query'
                    value = @{
                        id = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Compute/virtualMachines"
                        chartType = 0
                        metrics = @(
                            @{ name = 'Percentage CPU'; resourceId = "/subscriptions/$SubscriptionId" }
                        )
                        timespan = @{ duration = 'PT1H' }
                        interval = 'PT5M'
                    }
                }
            )
            settings = @{
                content = @{
                    options = @{
                        chart = @{
                            groupBy = $null
                            topRows = 10
                        }
                    }
                }
            }
        }
    }

    $memTile = @{
        position = @{ x = 6; y = 0; colSpan = 6; rowSpan = 4 }
        metadata = @{
            type = 'Extension/Microsoft_Azure_Monitoring/PartType/MetricsChartPart'
            inputs = @(
                @{
                    name = 'query'
                    value = @{
                        id = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Compute/virtualMachines"
                        chartType = 0
                        metrics = @(
                            @{ name = 'Available Memory Bytes'; resourceId = "/subscriptions/$SubscriptionId" }
                        )
                        timespan = @{ duration = 'PT1H' }
                        interval = 'PT5M'
                    }
                }
            )
        }
    }

    $dashboard = @{
        id       = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Portal/dashboards/$DashboardName"
        name     = $DashboardName
        type     = 'Microsoft.Portal/dashboards'
        location = 'global'
        tags     = @{ createdBy = 'PowerShell-Automation'; createdAt = (Get-Date -Format 'yyyy-MM-dd') }
        properties = @{
            lenses = @{
                '0' = @{
                    order = 0
                    parts = @($cpuTile, $memTile)
                }
            }
            metadata = @{
                model = @{
                    editable = $true
                    timeRange = @{
                        value = @{ relative = @{ duration = 24; timeUnit = 1 } }
                        type = 'MsPortalFx.Composition.Configuration.ValueTypes.TimeRangeType.Relative'
                    }
                    filter = @{
                        value = $null
                        type = 'MsPortalFx.Composition.Configuration.ValueTypes.FilterType.Callout'
                    }
                }
            }
        }
    }

    # 深度设置为 10 层，确保嵌套结构完整输出
    $dashboard | ConvertTo-Json -Depth 10
}

# 生成仪表板 JSON
$json = New-AzDashboardTemplate `
    -DashboardName 'prod-vm-monitor' `
    -SubscriptionId 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' `
    -ResourceGroupName 'rg-production'

$json | Out-File -FilePath './prod-vm-monitor-dashboard.json' -Encoding utf8
Write-Host "仪表板 JSON 已生成，文件大小：$((Get-Item './prod-vm-monitor-dashboard.json').Length) 字节"
```

执行结果示例：

```
仪表板 JSON 已生成，文件大小：2847 字节
```

生成的 JSON 文件可以直接通过 Azure 门户导入，也可以用 `New-AzPortalDashboard` 或 REST API 部署到指定资源组。通过修改 `$cpuTile` 和 `$memTile` 中的指标名称，你可以快速扩展出网络吞吐量、磁盘 I/O 等更多监控视图。

## 指标告警与自动通知

仪表板负责展示，告警负责驱动行动。在 Azure Monitor 体系中，指标告警规则（Metric Alert Rule）配合操作组（Action Group），可以在指标突破阈值时自动触发邮件、Webhook、短信等通知渠道。以下脚本演示了完整的告警链路创建流程：

```powershell
# 先确保已登录并选择正确的订阅
# Connect-AzAccount
# Set-AzContext -SubscriptionId 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'

$ResourceGroup  = 'rg-production'
$ActionGroupName = 'ag-ops-team'
$AlertRuleName   = 'alert-vm-cpu-high'

# 创建操作组：邮件通知 + Webhook
$emailReceiver = New-AzActionGroupReceiver `
    -Name 'ops-email' `
    -EmailAddress 'ops-team@contoso.com'

$webhookReceiver = New-AzActionGroupReceiver `
    -Name 'incident-webhook' `
    -WebhookUri 'https://hooks.example.com/azure-alerts'

$actionGroup = Set-AzActionGroup `
    -ResourceGroupName $ResourceGroup `
    -Name $ActionGroupName `
    -ShortName 'OpsTeam' `
    -Receiver $emailReceiver, $webhookReceiver

Write-Host "操作组已创建：$($actionGroup.Name)"

# 获取操作组的 ARM ID，告警规则需要引用
$actionGroupId = $actionGroup.Id

# 创建指标告警规则：CPU 使用率超过 85% 持续 5 分钟触发
$targetVm = Get-AzVM -ResourceGroupName $ResourceGroup -Name 'vm-web-01'
$vmResourceId = $targetVm.Id

$criteria = New-AzMetricAlertRuleV2Criteria `
    -MetricName 'Percentage CPU' `
    -TimeAggregation 'Average' `
    -Operator 'GreaterThan' `
    -Threshold 85

$actionGroupObject = New-AzMetricAlertRuleV2ActionGroup `
    -ActionGroupId $actionGroupId

# 设置告警规则的维度过滤（可选）
$dimension = New-AzMetricAlertRuleV2DimensionSelection `
    -DimensionName 'VMName' `
    -ValuesToInclude '*'

$alert = Add-AzMetricAlertRuleV2 `
    -Name $AlertRuleName `
    -ResourceGroupName $ResourceGroup `
    -WindowSize 'PT5M' `
    -Frequency 'PT1M' `
    -TargetResourceId $vmResourceId `
    -Condition $criteria `
    -ActionGroup $actionGroupObject `
    -Severity 2 `
    -Description "VM $($targetVm.Name) CPU 使用率超过 85% 持续 5 分钟"

Write-Host "告警规则已创建：$($alert.Name)"
Write-Host "目标资源：$vmResourceId"
Write-Host "阈值条件：Average Percentage CPU > 85%"
Write-Host "评估窗口：5 分钟，评估频率：1 分钟"
```

执行结果示例：

```
操作组已创建：ag-ops-team
告警规则已创建：alert-vm-cpu-high
目标资源：/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/rg-production/providers/Microsoft.Compute/virtualMachines/vm-web-01
阈值条件：Average Percentage CPU > 85%
评估窗口：5 分钟，评估频率：1 分钟
```

告警触发后，Azure 会同时向 `ops-team@contoso.com` 发送告警邮件，并向 `https://hooks.example.com/azure-alerts` 推送 Webhook 请求。你可以将 Webhook 对接到企业微信、飞书、Slack 等即时通讯平台，实现秒级告警触达。

## 多订阅仪表板批量部署

在企业级场景中，运维团队通常需要管理多个订阅（开发、测试、预生产、生产），每个订阅都应部署一套标准化的监控仪表板。手动逐个部署显然不现实，下面通过参数化模板和循环部署来解决这个问题：

```powershell
# 定义目标订阅列表和对应的资源配置
$subscriptions = @(
    @{
        SubscriptionId = 'aaaa1111-bbbb-2222-cccc-3333dddd4444'
        Name           = 'production'
        ResourceGroup  = 'rg-production'
        VmPrefix       = 'vm-prod'
        AlertEmail     = 'prod-ops@contoso.com'
    }
    @{
        SubscriptionId = 'eeee5555-ffff-6666-gggg-7777hhhh8888'
        Name           = 'staging'
        ResourceGroup  = 'rg-staging'
        VmPrefix       = 'vm-stg'
        AlertEmail     = 'staging-ops@contoso.com'
    }
    @{
        SubscriptionId = 'iiii9999-jjjj-0000-kkkk-1111llll2222'
        Name           = 'development'
        ResourceGroup  = 'rg-dev'
        VmPrefix       = 'vm-dev'
        AlertEmail     = 'dev-ops@contoso.com'
    }
)

$deployResults = [System.Collections.Generic.List[PSObject]]::new()

foreach ($sub in $subscriptions) {
    Write-Host "`n--- 正在处理订阅：$($sub.Name) ---" -ForegroundColor Cyan

    # 切换到目标订阅
    $context = Set-AzContext -SubscriptionId $sub.SubscriptionId
    Write-Host "  已切换到订阅：$($context.Subscription.Name)"

    # 生成仪表板 JSON
    $dashboardName = "$($sub.Name)-standard-dashboard"
    $dashboardJson = New-AzDashboardTemplate `
        -DashboardName $dashboardName `
        -SubscriptionId $sub.SubscriptionId `
        -ResourceGroupName $sub.ResourceGroup

    # 将 JSON 部署为 Azure 仪表板
    $tempFile = New-TemporaryFile
    $dashboardJson | Out-File -FilePath $tempFile.FullName -Encoding utf8

    # 使用 REST API 部署仪表板
    $token = (Get-AzAccessToken).Token
    $uri = "https://management.azure.com/subscriptions/$($sub.SubscriptionId)/resourceGroups/$($sub.ResourceGroup)/providers/Microsoft.Portal/dashboards/$dashboardName`?api-version=2020-09-01-preview"

    $headers = @{
        Authorization = "Bearer $token"
        'Content-Type' = 'application/json'
    }

    $response = Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $dashboardJson
    Write-Host "  仪表板已部署：$dashboardName"

    # 为该订阅创建操作组和告警规则
    $agName = "ag-$($sub.Name)-ops"
    $emailReceiver = New-AzActionGroupReceiver -Name 'team-email' -EmailAddress $sub.AlertEmail
    $actionGroup = Set-AzActionGroup `
        -ResourceGroupName $sub.ResourceGroup `
        -Name $agName `
        -ShortName "$($sub.Name)Ops" `
        -Receiver $emailReceiver

    Write-Host "  操作组已创建：$agName"

    # 记录部署结果
    $deployResults.Add([PSCustomObject]@{
        Subscription = $sub.Name
        Dashboard    = $dashboardName
        ActionGroup  = $agName
        Status       = 'Deployed'
        DeployTime   = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    })
}

# 输出部署汇总
Write-Host "`n========== 部署汇总 ==========" -ForegroundColor Yellow
$deployResults | Format-Table -AutoSize
```

执行结果示例：

```
--- 正在处理订阅：production ---
  已切换到订阅：production-subscription
  仪表板已部署：production-standard-dashboard
  操作组已创建：ag-production-ops

--- 正在处理订阅：staging ---
  已切换到订阅：staging-subscription
  仪表板已部署：staging-standard-dashboard
  操作组已创建：ag-staging-ops

--- 正在处理订阅：development ---
  已切换到订阅：development-subscription
  仪表板已部署：development-standard-dashboard
  操作组已创建：ag-dev-ops

========== 部署汇总 ==========
Subscription Dashboard                       ActionGroup        Status   DeployTime
------------ ---------                       -----------        ------   ----------
production   production-standard-dashboard    ag-production-ops  Deployed 2026-04-07 10:30:15
staging      staging-standard-dashboard       ag-staging-ops     Deployed 2026-04-07 10:30:42
development  development-standard-dashboard   ag-dev-ops         Deployed 2026-04-07 10:31:08
```

这个脚本的核心思路是将订阅特定的参数（资源组名、VM 前缀、告警邮箱）外置到配置数组中，然后通过循环统一调用前面定义的模板生成函数。你可以进一步将 `$subscriptions` 数组替换为从 CSV 或 Azure Key Vault 读取的配置，实现真正的配置与代码分离。

## 注意事项

1. **Az.Monitor 模块版本**：建议使用 Az.Monitor 4.0 以上版本，旧版本的 `Add-AzMetricAlertRuleV2` 参数名和行为有差异。安装前先执行 `Get-InstalledModule Az.Monitor` 确认当前版本。

2. **仪表板 JSON 深度问题**：Azure Dashboard 的 JSON 嵌套层级较深（通常 8-10 层），使用 `ConvertTo-Json` 时必须指定 `-Depth 10`，否则内层数据会被截断为字符串。

3. **REST API Token 有效期**：通过 `Get-AzAccessToken` 获取的 Bearer Token 默认有效期 1 小时。如果批量部署涉及大量订阅，建议在循环内每次都重新获取 Token，避免中途过期导致 401 错误。

4. **告警规则配额限制**：每个 Azure 订阅的指标告警规则数量有上限（默认 5000 条），跨订阅批量创建前应检查 `Get-AzMetricAlertRuleV2` 的返回数量，避免超出配额。

5. **操作组的 Webhook 超时**：Azure Action Group 发送 Webhook 时，超时时间为 10 秒。如果你的下游服务响应较慢，建议在中间加一个队列服务（如 Azure Functions + Service Bus），避免 Webhook 调用失败。

6. **仪表板权限控制**：通过 PowerShell 创建的仪表板默认只有创建者有编辑权限。如果需要团队成员共同维护，应通过 Azure RBAC 为资源组级别的 `Microsoft.Portal/dashboards` 资源分配 `Contributor` 或 `Reader` 角色。
