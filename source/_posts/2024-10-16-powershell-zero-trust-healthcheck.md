---
layout: post
date: 2024-10-16 08:00:00
title: "PowerShell 技能连载 - 零信任架构下的设备健康检查"
description: "实现自动化设备安全状态验证与合规报告生成"
categories:
- powershell
- security
- automation
tags:
- zero-trust
- device-health
- compliance
---

```powershell
function Invoke-DeviceHealthCheck {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$DeviceName
    )

    $healthReport = [PSCustomObject]@{
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Device = $DeviceName
        TPMEnabled = $false
        SecureBoot = $false
        AntivirusStatus = 'Unknown'
        ComplianceScore = 0
    }

    try {
        # 检查TPM状态
        $tpm = Get-Tpm -ErrorAction Stop
        $healthReport.TPMEnabled = $tpm.TpmPresent

        # 验证安全启动状态
        $healthReport.SecureBoot = Confirm-SecureBootUEFI

        # 获取反病毒状态
        $avStatus = Get-MpComputerStatus
        $healthReport.AntivirusStatus = $avStatus.AMServiceEnabled ? 'Active' : 'Inactive'

        # 计算合规分数
        $compliance = 0
        if($healthReport.TPMEnabled) { $compliance += 30 }
        if($healthReport.SecureBoot) { $compliance += 30 }
        if($healthReport.AntivirusStatus -eq 'Active') { $compliance += 40 }
        $healthReport.ComplianceScore = $compliance
    }
    catch {
        Write-Warning "设备健康检查失败: $_"
    }

    $healthReport | Export-Clixml -Path "$env:TEMP/DeviceHealth_$DeviceName.xml"
    return $healthReport
}
```

**核心功能**：
1. TPM芯片状态验证
2. 安全启动模式检测
3. 反病毒服务状态监控
4. 自动化合规评分

**应用场景**：
- 零信任架构准入控制
- 远程办公设备安全审计
- 合规性基线验证
- 安全事件响应前置检查