---
layout: post
date: 2024-08-20 08:00:00
title: "PowerShell 技能连载 - 零信任架构下的设备健康检查自动化"
description: "实现终端设备安全基线的自动化验证与合规报告生成"
categories:
- powershell
- security
tags:
- zero-trust
- device-compliance
- automation
---

```powershell
function Invoke-DeviceHealthCheck {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$DeviceName,
        
        [ValidateSet('Basic','Full')]
        [string]$ScanMode = 'Basic'
    )

    $complianceReport = [PSCustomObject]@{
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        DeviceName = $DeviceName
        EncryptionStatus = $null
        PatchLevel = $null
        FirewallRules = @()
        ComplianceScore = 0
    }

    try {
        # 验证BitLocker加密状态
        $encryptionStatus = Get-BitLockerVolume -MountPoint C: | 
            Select-Object -ExpandProperty EncryptionPercentage
        $complianceReport.EncryptionStatus = $encryptionStatus -ge 100 ? 'Compliant' : 'Non-Compliant'

        # 检查系统更新状态
        $updates = Get-HotFix | 
            Where-Object InstalledOn -lt (Get-Date).AddDays(-30)
        $complianceReport.PatchLevel = $updates.Count -eq 0 ? 'Current' : 'Outdated'

        # 审计防火墙规则（完整扫描模式）
        if ($ScanMode -eq 'Full') {
            $firewallRules = Get-NetFirewallRule |
                Where-Object Enabled -eq True |
                Select-Object DisplayName, Direction, Action
            $complianceReport.FirewallRules = $firewallRules
        }

        # 计算合规分数
        $score = 0
        if ($complianceReport.EncryptionStatus -eq 'Compliant') { $score += 40 }
        if ($complianceReport.PatchLevel -eq 'Current') { $score += 30 }
        if ($complianceReport.FirewallRules.Count -eq 0) { $score += 30 }
        $complianceReport.ComplianceScore = $score
    }
    catch {
        Write-Error "设备健康检查失败: $_"
    }

    # 生成零信任合规报告
    $complianceReport | Export-Clixml -Path "$env:TEMP/${DeviceName}_ComplianceReport_$(Get-Date -Format yyyyMMdd).xml"
    return $complianceReport
}
```

**核心功能**：
1. 自动化BitLocker加密状态验证
2. 系统补丁级别智能评估
3. 防火墙规则深度审计（完整扫描模式）
4. 动态合规评分系统

**应用场景**：
- 零信任安全架构实施
- 终端设备合规自动化审计
- 安全基线动态验证
- 监管合规报告生成