---
layout: post
date: 2024-09-30 08:00:00
title: "PowerShell 技能连载 - 多云成本优化自动化系统"
description: "实现跨云平台资源使用分析与智能费用优化建议"
categories:
- powershell
- cloud
tags:
- cost-optimization
- multi-cloud
- automation
---

```powershell
function Get-CloudCostReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$SubscriptionIds,
        
        [ValidateSet('Daily','Monthly')]
        [string]$Granularity = 'Monthly'
    )

    $costReport = [PSCustomObject]@{
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        TotalCost = 0
        ServiceBreakdown = @{}
        OptimizationSuggestions = @()
    }

    try {
        # 获取跨云成本数据
        $costData = $SubscriptionIds | ForEach-Object {
            Invoke-RestMethod -Uri "https://management.azure.com/subscriptions/$_/providers/Microsoft.CostManagement/query?api-version=2023-03-01" \
                -Headers @{ Authorization = "Bearer $env:AZURE_TOKEN" } \
                -Body (@{
                    type = "ActualCost"
                    timeframe = "MonthToDate"
                    dataset = @{
                        aggregation = @{
                            totalCost = @{
                                name = "Cost"
                                function = "Sum"
                            }
                        }
                        grouping = @(
                            @{
                                type = "Dimension"
                                name = "ServiceName"
                            }
                        )
                    }
                } | ConvertTo-Json)
        }

        # 分析成本结构
        $costReport.TotalCost = ($costData.properties.rows | Measure-Object -Property [0] -Sum).Sum
        $costReport.ServiceBreakdown = $costData.properties.rows | 
            Group-Object { $_[1] } -AsHashTable | 
            ForEach-Object { @{$_.Key = [math]::Round($_.Value[0],2)} }

        # 生成优化建议
        $costData.properties.rows | Where-Object { $_[0] -gt 1000 } | ForEach-Object {
            $costReport.OptimizationSuggestions += [PSCustomObject]@{
                Service = $_[1]
                Cost = $_[0]
                Recommendation = "考虑预留实例或自动缩放配置"
            }
        }
    }
    catch {
        Write-Error "成本数据获取失败: $_"
    }

    # 生成Excel格式报告
    $costReport | Export-Excel -Path "$env:TEMP/CloudCostReport_$(Get-Date -Format yyyyMMdd).xlsx"
    return $costReport
}
```

**核心功能**：
1. 跨云成本数据聚合分析
2. 服务维度费用结构分解
3. 智能优化建议生成
4. Excel格式报告输出

**应用场景**：
- 多云环境成本监控
- 预算超支预警
- 资源使用效率优化
- 财务部门合规报告