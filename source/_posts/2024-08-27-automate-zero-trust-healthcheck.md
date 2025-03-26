---
layout: post
title: "自动化零信任设备健康检查"
date: 2024-08-27 00:00:00
description: 使用PowerShell实现零信任架构下的终端设备合规性验证
categories:
- powershell
tags:
- powershell
- security
- zerotrust
---

```powershell
function Get-DeviceCompliance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ComputerName
    )

    # 验证TPM状态
    $tpmStatus = Get-Tpm -ComputerName $ComputerName -ErrorAction SilentlyContinue
    # 检查BitLocker加密状态
    $bitlocker = Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction SilentlyContinue
    # 获取防病毒状态
    $avStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue

    [PSCustomObject]@{
        ComputerName = $ComputerName
        TPMEnabled = $tpmStatus.TpmPresent
        SecureBoot = (Confirm-SecureBootUEFI).SecureBootEnabled
        BitLockerStatus = $bitlocker.VolumeStatus
        AntivirusEnabled = $avStatus.AMServiceEnabled
        LastUpdate = (Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 1).InstalledOn
    }
}

# 执行企业终端健康检查
$devices = 'PC001','PC002','PC003'
$report = $devices | ForEach-Object {
    Get-DeviceCompliance -ComputerName $_ -Verbose
}

# 生成合规性报告
$report | Export-Csv -Path "ZeroTrust_Compliance_Report_$(Get-Date -Format yyyyMMdd).csv" -NoTypeInformation
```

本脚本实现以下零信任核心检查项：
1. TPM芯片启用状态验证
2. Secure Boot安全启动配置
3. 系统盘BitLocker加密状态
4. 防病毒实时监控状态
5. 系统最后更新日期

扩展建议：
- 与Azure AD条件访问策略集成
- 添加自动修复功能
- 实现实时监控告警机制