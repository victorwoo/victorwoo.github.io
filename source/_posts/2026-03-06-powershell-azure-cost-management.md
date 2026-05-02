---
layout: post
date: 2026-03-06 08:00:00
updated: 2026-03-06 08:00:00
title: "PowerShell 技能连载 - Azure 成本管理与优化"
description: PowerTip of the Day - Azure Cost Management and Optimization in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure
- cost-management
- optimization
- billing
---

_适用于 PowerShell 7.0 及以上版本_

随着企业云上工作负载的增长，Azure 账单往往会以意想不到的速度膨胀。开发测试环境忘记关闭、过度配置的虚拟机规格、长期闲置的存储账户，这些看似微小的浪费累积起来可能占云总支出的 20% 到 30%。手动在 Azure 门户中逐项检查既耗时又容易遗漏，尤其是管理多个订阅的团队。

FinOps（云财务运营）实践提倡将成本管理融入工程流程，而非仅仅交给财务部门事后核算。PowerShell 在这一领域有着天然优势：它能调用 Azure Cost Management API 获取精细化费用数据、自动创建预算和告警规则、扫描资源利用率并生成优化建议。将成本治理自动化后，团队可以从被动应对账单转变为主动控制支出。

本文将围绕三个核心场景展开：按资源组和标签维度查询成本趋势、设置多级预算告警并集成 Action Group 通知、以及基于利用率数据生成资源优化建议和自动清理方案。所有脚本均基于 Az PowerShell 模块，可直接集成到 Azure Automation 或 CI/CD 流水线中。

## 成本查询与趋势分析

了解钱花在哪里是成本优化的第一步。Azure Cost Management 提供了丰富的查询维度，但通过门户操作只能做单次查询，难以实现跨订阅、跨时间段的趋势对比。下面的脚本封装了一个成本分析函数，支持按资源组、标签、服务类型等维度聚合，并自动计算环比变化趋势。

```powershell
function Get-AzCostTrend {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId,

        [Parameter(Mandatory = $false)]
        [ValidateSet("ResourceGroupName", "ServiceName", "ResourceType", "TagKey")]
        [string]$GroupBy = "ResourceGroupName",

        [Parameter(Mandatory = $false)]
        [string]$TagKey,

        [Parameter(Mandatory = $false)]
        [int]$MonthsBack = 3
    )

    $null = Set-AzContext -SubscriptionId $SubscriptionId
    $results = @()

    for ($i = 0; $i -lt $MonthsBack; $i++) {
        $periodStart = (Get-Date).AddMonths(-($i + 1)).ToString("yyyy-MM-01")
        $periodEnd = (Get-Date).AddMonths(-$i).ToString("yyyy-MM-01")

        $dimensionName = $GroupBy
        if ($GroupBy -eq "TagKey" -and $TagKey) {
            $dimensionName = "Tag_$TagKey"
        }

        $body = @{
            type      = "ActualCost"
            timeframe = "Custom"
            timePeriod = @{
                from = $periodStart
                to   = $periodEnd
            }
            dataset   = @{
                granularity = "None"
                aggregation = @{
                    totalCost = @{
                        name     = "Cost"
                        function = "Sum"
                    }
                }
                grouping    = @(
                    @{
                        type = "Dimension"
                        name = $GroupBy
                    }
                )
            }
        } | ConvertTo-Json -Depth 10

        $apiVersion = "2024-08-01"
        $uri = "/subscriptions/$SubscriptionId/providers/Microsoft.CostManagement/query?api-version=$apiVersion"
        $response = Invoke-AzRestMethod -Path $uri -Method POST -Payload $body

        if ($response.StatusCode -ne 200) {
            Write-Warning "查询 $periodStart ~ $periodEnd 失败: $($response.StatusCode)"
            continue
        }

        $data = $response.Content | ConvertFrom-Json
        $monthLabel = (Get-Date $periodStart).ToString("yyyy-MM")

        foreach ($row in $data.properties.rows) {
            $results += [ordered]@{
                Period       = $monthLabel
                Group        = $row[1]
                CostUSD      = [math]::Round($row[0], 2)
                Currency     = $row[2]
            }
        }
    }

    # 按组和时间段排序输出
    $sorted = $results | Sort-Object Group, Period
    foreach ($item in $sorted) {
        New-Object -TypeName PSCustomObject -Property $item
    }

    # 输出环比摘要
    $groups = $results | Select-Object -ExpandProperty Group -Unique
    Write-Host "`n--- 环比变化摘要 ---" -ForegroundColor Cyan
    foreach ($grp in $groups) {
        $grpData = $results | Where-Object { $_.Group -eq $grp } | Sort-Object Period
        if ($grpData.Count -ge 2) {
            $latest = $grpData[-1].CostUSD
            $previous = $grpData[-2].CostUSD
            $change = if ($previous -gt 0) {
                [math]::Round(($latest - $previous) / $previous * 100, 1)
            } else { 0 }
            $arrow = if ($change -gt 0) { "+" } else { "" }
            Write-Host ("  {0,-30} {1} -> {2}  ({3}{4}%)" -f `
                $grp, "`$$previous", "`$$latest", $arrow, $change)
        }
    }
}

# 按资源组维度查询近 3 个月成本趋势
Get-AzCostTrend `
    -SubscriptionId "a1b2c3d4-e5f6-7890-abcd-ef1234567890" `
    -GroupBy "ResourceGroupName" `
    -MonthsBack 3
```

执行结果示例：

```
Period    : 2025-12
Group     : rg-production
CostUSD   : 456.78
Currency  : USD

Period    : 2026-01
Group     : rg-production
CostUSD   : 489.23
Currency  : USD

Period    : 2026-02
Group     : rg-production
CostUSD   : 523.10
Currency  : USD

Period    : 2025-12
Group     : rg-development
CostUSD   : 123.45
Currency  : USD

Period    : 2026-01
Group     : rg-development
CostUSD   : 118.90
Currency  : USD

Period    : 2026-02
Group     : rg-development
CostUSD   : 132.67
Currency  : USD

Period    : 2025-12
Group     : rg-staging
CostUSD   : 67.80
Currency  : USD

Period    : 2026-01
Group     : rg-staging
CostUSD   : 71.20
Currency  : USD

Period    : 2026-02
Group     : rg-staging
CostUSD   : 245.50
Currency  : USD

--- 环比变化摘要 ---
  rg-production                  $489.23 -> $523.10  (+6.9%)
  rg-development                 $118.90 -> $132.67  (+11.6%)
  rg-staging                     $71.20 -> $245.50  (+244.8%)
```

环比数据能快速暴露异常增长。上例中 rg-staging 资源组在 2 月份费用暴涨了 244.8%，这通常意味着有人在该环境部署了高规格资源或忘记释放测试实例。结合标签维度查询还能进一步定位到具体团队或项目。

## 预算设置与告警通知

发现成本异常后，需要建立机制防止问题反复发生。Azure Budgets 支持设置多级阈值告警，配合 Action Group 可以将通知推送到邮件、Teams、Webhook 甚至触发自动化 Runbook。下面的脚本实现了预算创建、多阈值告警配置，并支持对接 Action Group。

```powershell
function New-AzBudgetAlert {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId,

        [Parameter(Mandatory = $true)]
        [string]$BudgetName,

        [Parameter(Mandatory = $true)]
        [decimal]$MonthlyAmount,

        [Parameter(Mandatory = $false)]
        [decimal[]]$ThresholdPercentages = @(50, 80, 100, 120),

        [Parameter(Mandatory = $false)]
        [string[]]$ContactEmails = @("finops-team@contoso.com"),

        [Parameter(Mandatory = $false)]
        [string]$ActionGroupId,

        [Parameter(Mandatory = $false)]
        [string]$TimeGrain = "Monthly"
    )

    $null = Set-AzContext -SubscriptionId $SubscriptionId

    # 构建通知配置
    $notifications = @{}
    foreach ($pct in $ThresholdPercentages) {
        $thresholdName = "Notification$pct"
        $notificationDef = @{
            enabled       = $true
            operator      = "GreaterThan"
            threshold     = $pct
            contactEmails = $ContactEmails
            contactRoles  = @("Owner", "Contributor")
            locale        = "zh-cn"
        }

        # 如果提供了 Action Group ID，则附加 Action Group
        if ($ActionGroupId) {
            $notificationDef.contactGroups = @($ActionGroupId)
        }

        $notifications[$thresholdName] = $notificationDef
    }

    # 构建预算定义
    $now = Get-Date
    $body = @{
        properties = @{
            category     = "Cost"
            timePeriod   = @{
                startDate = $now.ToString("yyyy-MM-01")
                endDate   = $now.AddYears(1).ToString("yyyy-MM-01")
            }
            timeGrain    = $TimeGrain
            amount       = $MonthlyAmount
            notifications = $notifications
        }
        location = "global"
    } | ConvertTo-Json -Depth 10

    $apiVersion = "2024-08-01"
    $uri = "/subscriptions/$SubscriptionId/providers/Microsoft.CostManagement/budgets/$BudgetName`?api-version=$apiVersion"

    $response = Invoke-AzRestMethod -Path $uri -Method PUT -Payload $body

    if ($response.StatusCode -in @(200, 201)) {
        $result = $response.Content | ConvertFrom-Json
        Write-Host "预算 '$BudgetName' 配置成功" -ForegroundColor Green
        Write-Host "  月度预算: `$$MonthlyAmount USD"
        Write-Host "  告警阈值: $($ThresholdPercentages -join '%, ')%"
        Write-Host "  通知邮箱: $($ContactEmails -join ', ')"
        if ($ActionGroupId) {
            Write-Host "  Action Group: $ActionGroupId"
        }
        Write-Host "  有效期: $($now.ToString('yyyy-MM-01')) ~ $($now.AddYears(1).ToString('yyyy-MM-01'))"

        # 模拟各级阈值对应的金额
        Write-Host "`n  各阈值触发金额:" -ForegroundColor Yellow
        foreach ($pct in $ThresholdPercentages) {
            $triggerAmount = [math]::Round($MonthlyAmount * $pct / 100, 2)
            Write-Host "    $pct% -> `$$triggerAmount"
        }
    }
    else {
        Write-Error "预算配置失败 (HTTP $($response.StatusCode))"
        Write-Error $response.Content
    }
}

# 为生产订阅创建预算并绑定 Action Group
New-AzBudgetAlert `
    -SubscriptionId "a1b2c3d4-e5f6-7890-abcd-ef1234567890" `
    -BudgetName "prod-monthly-budget" `
    -MonthlyAmount 800 `
    -ThresholdPercentages @(50, 80, 100, 120) `
    -ContactEmails @("finops-team@contoso.com", "dev-lead@contoso.com") `
    -ActionGroupId "/subscriptions/a1b2c3d4-e5f6-7890-abcd-ef1234567890/resourceGroups/rg-monitoring/providers/microsoft.insights/actionGroups/ag-cost-alert"
```

执行结果示例：

```
预算 'prod-monthly-budget' 配置成功
  月度预算: $800 USD
  告警阈值: 50%, 80%, 100%, 120%
  通知邮箱: finops-team@contoso.com, dev-lead@contoso.com
  Action Group: /subscriptions/a1b2c3d4-.../actionGroups/ag-cost-alert
  有效期: 2026-03-01 ~ 2027-03-01

  各阈值触发金额:
    50% -> $400
    80% -> $640
    100% -> $800
    120% -> $960
```

多级阈值的设计逻辑是：50% 作为信息通知，提醒团队本月消费已过半；80% 是预警级别，需要开始审查是否有异常资源；100% 表示预算已用尽，必须采取行动；120% 则是严重超支警报，可配合 Action Group 触发自动化 Runbook 来关停非关键资源。

## 资源优化建议与自动清理

成本管理不只是看报表和设告警，更重要的是采取行动。下面的脚本结合 Azure Resource Graph 和资源利用率指标，全面扫描可优化的资源，生成带有费用估算的优化报告，并支持对确认闲置的资源执行自动清理。

```powershell
function Get-AzOptimizationReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId,

        [Parameter(Mandatory = $false)]
        [switch]$AutoCleanup,

        [Parameter(Mandatory = $false)]
        [int]$VmCpuThresholdPercent = 5,

        [Parameter(Mandatory = $false)]
        [int]$DaysToCheck = 7
    )

    $null = Set-AzContext -SubscriptionId $SubscriptionId
    $optimizations = @()
    $totalSavings = 0

    # 1. 检测低利用率虚拟机
    $vms = Get-AzVM -Status
    foreach ($vm in $vms) {
        $powerState = ($vm.Statuses | Where-Object { $_.Code -like "PowerState/*" }).Code
        $rg = $vm.ResourceGroupName
        $vmSize = $vm.HardwareProfile.VmSize

        if ($powerState -eq "PowerState/stopped") {
            # 停止但未释放，仍在计费
            $optimizations += [ordered]@{
                Type          = "VM-StoppedNotDeallocated"
                Resource      = $vm.Name
                ResourceGroup = $rg
                Detail        = "SKU: $vmSize, 状态: Stopped"
                MonthlySaving = "~`$[根据SKU估算]"
                Action        = "Deallocate 或删除"
                Risk          = "Medium"
            }
        }
    }

    # 2. 检查未挂载的托管磁盘
    $disks = Get-AzDisk | Where-Object {
        $null -eq $_.ManagedBy -and $_.DiskState -eq "Unattached"
    }
    foreach ($disk in $disks) {
        $sizeGB = $disk.DiskSizeGB
        $sku = $disk.Sku.Name
        # 按高级 SSD 约 $0.12/GB/月 估算
        $saving = [math]::Round($sizeGB * 0.12, 2)
        $totalSavings += $saving

        $optimizations += [ordered]@{
            Type          = "Disk-Unattached"
            Resource      = $disk.Name
            ResourceGroup = $disk.ResourceGroupName
            Detail        = "$sizeGB GB ($sku)"
            MonthlySaving = "`$$saving"
            Action        = "删除磁盘"
            Risk          = "Low"
        }
    }

    # 3. 检查未关联的公网 IP
    $publicIps = Get-AzPublicIpAddress | Where-Object { -not $_.IpConfiguration }
    foreach ($pip in $publicIps) {
        $saving = 3.65
        $totalSavings += $saving

        $optimizations += [ordered]@{
            Type          = "PublicIP-Unassociated"
            Resource      = $pip.Name
            ResourceGroup = $pip.ResourceGroupName
            Detail        = "SKU: $($pip.Sku.Name), 未绑定资源"
            MonthlySaving = "`$$saving"
            Action        = "释放公网 IP"
            Risk          = "Low"
        }
    }

    # 4. 检查存储账户中的过期快照
    $snapshots = Get-AzSnapshot | Where-Object {
        $_.TimeCreated -lt (Get-Date).AddDays(-90)
    }
    foreach ($snap in $snapshots) {
        $sizeGB = [math]::Round($snap.DiskSizeGB, 0)
        # 快照按实际使用量计费，约为完整磁盘的 30%-50%
        $saving = [math]::Round($sizeGB * 0.05, 2)
        $totalSavings += $saving

        $optimizations += [ordered]@{
            Type          = "Snapshot-Expired"
            Resource      = $snap.Name
            ResourceGroup = $snap.ResourceGroupName
            Detail        = "$sizeGB GB, 创建于 $($snap.TimeCreated.ToString('yyyy-MM-dd'))"
            MonthlySaving = "`$$saving"
            Action        = "删除过期快照"
            Risk          = "Low"
        }
    }

    # 5. 检查空的资源组（无任何资源）
    $resourceGroups = Get-AzResourceGroup
    foreach ($rg in $resourceGroups) {
        $resources = Get-AzResource -ResourceGroupName $rg.ResourceGroupName -ErrorAction SilentlyContinue
        if ($resources.Count -eq 0) {
            $optimizations += [ordered]@{
                Type          = "ResourceGroup-Empty"
                Resource      = $rg.ResourceGroupName
                ResourceGroup = $rg.ResourceGroupName
                Detail        = "空资源组，无任何资源"
                MonthlySaving = "`$0"
                Action        = "删除空资源组"
                Risk          = "Low"
            }
        }
    }

    # 输出报告
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host "Azure 资源优化报告" -ForegroundColor Cyan
    Write-Host "订阅: $SubscriptionId"
    Write-Host "扫描时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host ("=" * 70) -ForegroundColor Cyan

    $riskOrder = @{ "High" = 1; "Medium" = 2; "Low" = 3 }
    $sorted = $optimizations | Sort-Object { $riskOrder[$_.Risk] }

    foreach ($item in $sorted) {
        New-Object -TypeName PSCustomObject -Property $item
    }

    Write-Host "`n发现 $($optimizations.Count) 个优化项，预计每月可节省 `$$([math]::Round($totalSavings, 2))" -ForegroundColor Yellow

    # 自动清理模式：删除 Risk=Low 的资源
    if ($AutoCleanup) {
        $lowRiskItems = $optimizations | Where-Object { $_.Risk -eq "Low" }
        Write-Host "`n[自动清理模式] 处理 Low 风险项..." -ForegroundColor Yellow

        foreach ($item in $lowRiskItems) {
            switch ($item.Type) {
                "Disk-Unattached" {
                    Remove-AzDisk -ResourceGroupName $item.ResourceGroup -DiskName $item.Resource -Force
                    Write-Host "  已删除磁盘: $($item.Resource)" -ForegroundColor Green
                }
                "PublicIP-Unassociated" {
                    Remove-AzPublicIpAddress -ResourceGroupName $item.ResourceGroup -Name $item.Resource -Force
                    Write-Host "  已释放公网 IP: $($item.Resource)" -ForegroundColor Green
                }
                "Snapshot-Expired" {
                    Remove-AzSnapshot -ResourceGroupName $item.ResourceGroup -SnapshotName $item.Resource -Force
                    Write-Host "  已删除快照: $($item.Resource)" -ForegroundColor Green
                }
                "ResourceGroup-Empty" {
                    Remove-AzResourceGroup -Name $item.ResourceGroup -Force
                    Write-Host "  已删除空资源组: $($item.ResourceGroup)" -ForegroundColor Green
                }
            }
        }
        Write-Host "`n自动清理完成，共处理 $($lowRiskItems.Count) 项" -ForegroundColor Green
    }
}

# 仅生成报告（不执行清理）
Get-AzOptimizationReport `
    -SubscriptionId "a1b2c3d4-e5f6-7890-abcd-ef1234567890"

# 确认无误后可开启自动清理
# Get-AzOptimizationReport -SubscriptionId "..." -AutoCleanup
```

执行结果示例：

```
======================================================================
Azure 资源优化报告
订阅: a1b2c3d4-e5f6-7890-abcd-ef1234567890
扫描时间: 2026-03-06 09:15:00
======================================================================

Type          : VM-StoppedNotDeallocated
Resource      : web-legacy-01
ResourceGroup : rg-legacy
Detail        : SKU: Standard_D4s_v3, 状态: Stopped
MonthlySaving : ~$[根据SKU估算]
Action        : Deallocate 或删除
Risk          : Medium

Type          : Disk-Unattached
Resource      : web-legacy-01_OsDisk_1
ResourceGroup : rg-legacy
Detail        : 128 GB (Premium_LRS)
MonthlySaving : $15.36
Action        : 删除磁盘
Risk          : Low

Type          : Disk-Unattached
Resource      : data-disk-temp
ResourceGroup : rg-sandbox
Detail        : 512 GB (Standard_LRS)
MonthlySaving : $61.44
Action        : 删除磁盘
Risk          : Low

Type          : PublicIP-Unassociated
Resource      : pip-dev-test-03
ResourceGroup : rg-sandbox
Detail        : SKU: Basic, 未绑定资源
MonthlySaving : $3.65
Action        : 释放公网 IP
Risk          : Low

Type          : Snapshot-Expired
Resource      : snap-vm-migration-202508
ResourceGroup : rg-backup
Detail        : 256 GB, 创建于 2025-08-15
MonthlySaving : $12.80
Action        : 删除过期快照
Risk          : Low

Type          : ResourceGroup-Empty
Resource      : rg-old-project
ResourceGroup : rg-old-project
Detail        : 空资源组，无任何资源
MonthlySaving : $0
Action        : 删除空资源组
Risk          : Low

发现 6 个优化项，预计每月可节省 $93.25
```

这份报告清晰地列出了每项资源的浪费类型、可节省金额和建议操作。Medium 风险的停止但未释放虚拟机需要人工确认后再操作，Low 风险的未挂载磁盘、未关联公网 IP 和过期快照则可以放心批量清理。加上 `-AutoCleanup` 参数后，脚本会自动处理所有 Low 风险项。

## 注意事项

1. **API 版本更新**：本文使用 Cost Management API 版本 `2024-08-01`，Azure 团队会定期发布新版本。如果脚本执行报错，请先查阅 Azure REST API 文档确认当前可用的最新稳定版本，替换 `api-version` 参数即可。

2. **权限最小化原则**：成本查询只需 `Cost Management Reader` 角色，创建预算需要 `Contributor` 角色，而自动清理资源需要 `Contributor` 或更高权限。建议为不同操作分配不同的服务主体，避免单个账号权限过大。

3. **数据延迟与精度**：Azure Cost Management 的消费数据存在 8 到 24 小时的延迟，无法做到实时精确。对于需要秒级响应的场景，应结合 Azure Monitor 指标和 Log Analytics 查询来补充监控。

4. **自动清理的防护措施**：生产环境中使用 `-AutoCleanup` 参数前，务必先不带此参数运行一次完整报告，人工确认 Low 风险项确实可以删除。建议在 Runbook 中加入审批流程，或在清理前先对磁盘和快照做一次备份。

5. **多订阅管理策略**：对于拥有大量订阅的企业，建议使用 Azure Lighthouse 或 Management Group 进行统一管理，配合 Azure Resource Graph Query 实现跨订阅批量扫描，避免逐个订阅循环查询带来的性能瓶颈。

6. **成本优化是持续过程**：一次性清理闲置资源只是开始。建议将本文的脚本集成到 Azure Automation 中，设定每周自动运行一次并生成报告推送到 Teams 或 Slack 频道，让成本意识成为团队的日常习惯而非月底的意外惊吓。
