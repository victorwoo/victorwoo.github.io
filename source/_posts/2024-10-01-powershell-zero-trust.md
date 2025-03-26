---
layout: post
date: 2024-10-01 08:00:00
title: "PowerShell 技能连载 - 零信任架构下的设备健康检查"
description: PowerTip of the Day - Zero Trust Device Health Validation
categories:
- powershell
- security
tags:
- powershell
- zero-trust
- compliance
---

```powershell
function Invoke-DeviceHealthCheck {
    param(
        [string[]]$ComputerNames = $env:COMPUTERNAME
    )

    $securityBaseline = @{
        SecureBootEnabled = $true
        TPMPresent = $true
        BitLockerStatus = 'FullyEncrypted'
        AntivirusStatus = 'Enabled'
        FirewallProfile = 'Domain'
    }

    $results = @()

    foreach ($computer in $ComputerNames) {
        try {
            $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $computer
            $tpm = Get-CimInstance -ClassName Win32_Tpm -ComputerName $computer -ErrorAction Stop
            $bitlocker = Get-BitLockerVolume -MountPoint $osInfo.SystemDrive -ErrorAction Stop
            
            $healthStatus = [PSCustomObject]@{
                ComputerName = $computer
                LastBootTime = $osInfo.LastBootUpTime
                SecureBoot = [bool](Confirm-SecureBootUEFI)
                TPMVersion = $tpm.SpecVersion
                BitLockerProtection = $bitlocker.ProtectionStatus
                DefenderStatus = (Get-MpComputerStatus).AntivirusEnabled
                FirewallStatus = (Get-NetFirewallProfile -Name Domain).Enabled
                ComplianceScore = 0
            }

            # 计算合规分数
            $healthStatus.ComplianceScore = [math]::Round((
                ($healthStatus.SecureBoot -eq $securityBaseline.SecureBootEnabled) + 
                ($healthStatus.TPMVersion -match '2.0') + 
                ($healthStatus.BitLockerProtection -eq 'On') + 
                ($healthStatus.DefenderStatus -eq $true) + 
                ($healthStatus.FirewallStatus -eq $true)
            ) / 5 * 100, 2)

            $results += $healthStatus
        }
        catch {
            Write-Warning "$computer 健康检查失败: $_"
        }
    }

    $results | Format-Table -AutoSize
}
```

核心功能：
1. 自动化验证设备安全基线配置
2. 检测TPM 2.0和SecureBoot状态
3. 评估BitLocker加密状态
4. 生成设备合规性评分

应用场景：
- 零信任网络接入前检查
- 远程办公设备安全审计
- 合规性自动化报告生成