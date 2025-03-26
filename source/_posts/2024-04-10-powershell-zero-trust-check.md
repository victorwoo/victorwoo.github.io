---
layout: post
date: 2024-04-10 08:00:00
title: "PowerShell 技能连载 - 零信任设备合规检查"
description: PowerTip of the Day - Zero-Trust Device Compliance Check
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在零信任安全架构中，设备合规性验证是重要环节。以下脚本实现自动化设备安全检查：

```powershell
function Get-DeviceCompliance {
    [CmdletBinding()]
    param(
        [ValidateSet('Basic','Advanced')]
        [string]$CheckLevel = 'Basic'
    )

    $report = [PSCustomObject]@{
        TPMEnabled     = $false
        BitLockerStatus = 'NotEncrypted'
        FirewallActive = $false
        LastUpdateDays = 999
        Compliant      = $false
    }

    try {
        # TPM状态检查
        $tpm = Get-CimInstance -ClassName Win32_Tpm -Namespace root/cimv2/Security/MicrosoftTpm
        $report.TPMEnabled = $tpm.IsEnabled_InitialValue

        # BitLocker检查
        $blv = Get-BitLockerVolume -MountPoint $env:SystemDrive 2>$null
        $report.BitLockerStatus = if($blv.ProtectionStatus -eq 'On') {'Encrypted'} else {'NotEncrypted'}

        # 防火墙状态
        $fw = Get-NetFirewallProfile | Where-Object {$_.Enabled -eq 'True'}
        $report.FirewallActive = [bool]($fw | Measure-Object).Count

        # 系统更新检查
        $lastUpdate = (Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 1).InstalledOn
        $report.LastUpdateDays = (New-TimeSpan -Start $lastUpdate -End (Get-Date)).Days

        # 高级检查
        if($CheckLevel -eq 'Advanced') {
            $report | Add-Member -NotePropertyName SecureBoot -NotePropertyValue (Confirm-SecureBootUEFI)
            $report | Add-Member -NotePropertyName HyperVEnabled -NotePropertyValue (Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V).State
        }

        # 合规判定
        $report.Compliant = $report.TPMEnabled -and
                          ($report.BitLockerStatus -eq 'Encrypted') -and
                          $report.FirewallActive -and
                          ($report.LastUpdateDays -lt 30)
    }
    catch {
        Write-Warning "设备检查异常: $_"
    }

    return $report
}
```

实现原理：
1. 通过WMI/CIM接口获取TPM芯片状态，验证硬件安全基础
2. 检查BitLocker加密状态，确保数据存储安全
3. 扫描防火墙配置，确认至少有一个激活的防护配置文件
4. 计算系统最后更新天数，确保漏洞及时修补
5. 高级模式增加UEFI安全启动和虚拟化安全检查

使用示例：
```powershell
# 基本检查
Get-DeviceCompliance

# 高级检查
Get-DeviceCompliance -CheckLevel Advanced
```

最佳实践：
1. 与Intune等MDM解决方案集成
2. 定期通过任务计划执行检查
3. 对不合规设备启动修复流程
4. 记录检查结果到中央日志服务器

注意事项：
• 需要本地管理员权限执行
• 部分检查仅支持Windows 10/11企业版
• 建议配合组策略共同使用