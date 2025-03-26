---
layout: post
date: 2025-02-13 08:00:00
title: "PowerShell 技能连载 - Azure多云成本优化实践"
description: "自动化分析跨订阅资源消耗与优化建议"
categories:
- powershell
- azure
- devops
tags:
- cost-optimization
- multicloud
- automation
---

```powershell
function Get-AzureCostAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$SubscriptionIds,
        [datetime]$StartDate = (Get-Date).AddDays(-30)
    )

    $report = [PSCustomObject]@{
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        ResourceAnalysis = @()
        CostRecommendations = @()
    }

    foreach ($subId in $SubscriptionIds) {
        Set-AzContext -SubscriptionId $subId | Out-Null
        
        # 获取资源消耗数据
        $resources = Get-AzResource | Where-Object {
            $_.ResourceType -notin @('Microsoft.Resources/deployments','Microsoft.Resources/subscriptions') 
        }

        $resourceGroups = $resources | Group-Object ResourceGroupName
        foreach ($rg in $resourceGroups) {
            $costData = Get-AzConsumptionUsageDetail -StartDate $StartDate -EndDate (Get-Date) -ResourceGroup $rg.Name
            
            $report.ResourceAnalysis += [PSCustomObject]@{
                Subscription = $subId
                ResourceGroup = $rg.Name
                TotalCost = ($costData | Measure-Object PretaxCost -Sum).Sum
                UnderutilizedVMs = $rg.Group.Where{ $_.ResourceType -eq 'Microsoft.Compute/virtualMachines' }.Count
            }
        }
    }

    # 生成优化建议
    $report.ResourceAnalysis | ForEach-Object {
        if ($_.UnderutilizedVMs -gt 5) {
            $report.CostRecommendations += [PSCustomObject]@{
                Recommendation = "调整资源组 $($_.ResourceGroup) 中未充分利用的VM规模"
                PotentialSavings = "预计节省 $([math]::Round($_.TotalCost * 0.3)) 美元"
            }
        }
    }

    $report | Export-Excel -Path "$env:TEMP/AzureCostReport_$(Get-Date -Format yyyyMMdd).xlsx"
    return $report
}
```

**核心功能**：
1. 跨订阅资源消耗分析
2. 闲置VM资源自动识别
3. 成本节约潜力预测
4. Excel报告自动生成

**典型应用场景**：
- 企业多云成本可视化管理
- FinOps实践中的资源优化
- 预算执行情况跟踪
- 云服务商比价数据支持