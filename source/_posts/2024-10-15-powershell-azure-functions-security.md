---
layout: post
date: 2024-10-15 08:00:00
title: "PowerShell 技能连载 - 基于Azure Functions的无服务器安全检测"
description: "使用PowerShell在无服务器架构中实现实时安全事件响应"
categories:
- powershell
- security
- azure
tags:
- serverless
- security-monitoring
- azure-functions
---

```powershell
function Invoke-SecurityScan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ResourceGroup,

        [ValidateSet('Critical','High','Medium')]
        [string]$SeverityLevel = 'High'
    )

    $securityReport = [PSCustomObject]@{
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        ScannedResources = @()
        SecurityFindings = @()
    }

    # 获取Azure安全中心警报
    $alerts = Get-AzSecurityAlert -ResourceGroupName $ResourceGroup | 
        Where-Object { $_.Severity -eq $SeverityLevel }

    # 自动化响应流程
    $alerts | ForEach-Object {
        $securityReport.ScannedResources += [PSCustomObject]@{
            ResourceID = $_.ResourceId
            AlertType = $_.AlertType
            CompromiseEntity = $_.CompromisedEntity
        }

        # 触发自动化修复动作
        if($_.AlertType -eq 'UnusualResourceDeployment') {
            Start-AzResourceDelete -ResourceId $_.ResourceId -Force
            $securityReport.SecurityFindings += [PSCustomObject]@{
                Action = 'DeletedSuspiciousResource'
                ResourceID = $_.ResourceId
                Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            }
        }
    }

    # 生成安全态势报告
    $securityReport | ConvertTo-Json -Depth 3 | 
        Out-File -FilePath "$env:TEMP/AzureSecReport_$(Get-Date -Format yyyyMMdd).json"
    return $securityReport
}
```

**核心功能**：
1. 实时获取Azure安全中心高等级警报
2. 异常资源部署自动隔离机制
3. JSON格式安全态势报告生成
4. 多严重级别安全事件过滤

**典型应用场景**：
- 云环境异常操作实时响应
- 自动化安全基线维护
- 多云订阅安全状态聚合
- 合规审计日志自动生成