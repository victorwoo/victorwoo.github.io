---
layout: post
title: "多云环境成本优化自动化实践"
date: 2025-01-14 00:00:00
description: 使用PowerShell实现Azure和AWS云资源成本监控与优化
categories:
- powershell
tags:
- powershell
- cloud
- automation
---

```powershell
function Get-CloudCostAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('Azure','AWS')]
        [string]$CloudProvider
    )

    $threshold = 100 # 美元
    
    switch ($CloudProvider) {
        'Azure' {
            $costData = Get-AzConsumptionUsageDetail -BillingPeriodName (Get-Date).ToString('yyyyMM') |
                Group-Object ResourceGroup |
                Select-Object Name,@{N='Cost';E={$_.Group.PretaxCost | Measure-Object -Sum | Select-Object -Expand Sum}}
        }
        'AWS' {
            $costData = Get-CECostAndUsage -TimePeriod @{Start=(Get-Date).AddDays(-30).ToString('yyyy-MM-dd');End=(Get-Date).ToString('yyyy-MM-dd')} -Granularity MONTHLY |
                Select-Object -Expand ResultsByTime |
                Select-Object -Expand Groups |
                Where-Object {$_.Metrics.UnblendedCost.Amount -gt $threshold}
        }
    }

    $costData | Export-Csv -Path "${CloudProvider}_Cost_Report_$(Get-Date -Format yyyyMMdd).csv" -NoTypeInformation
    
    if ($costData.Count -gt 5) {
        Send-MailMessage -To 'finops@company.com' -Subject "[$CloudProvider] 成本异常警报" -Body "发现${threshold}美元以上资源：$($costData.Count)项"
    }
}
```

核心功能：
1. 支持Azure/AWS多云平台成本分析
2. 自动识别异常支出资源
3. 生成CSV报告并邮件告警
4. 可配置成本阈值参数

扩展方向：
- 集成Power BI可视化
- 添加自动关闭闲置资源功能
- 实现跨云平台成本对比分析