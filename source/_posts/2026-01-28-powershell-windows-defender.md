---
layout: post
date: 2026-01-28 08:00:00
updated: 2026-01-28 08:00:00
title: "PowerShell 技能连载 - Windows Defender 管理"
description: PowerTip of the Day - Windows Defender Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- security
---

_适用于 PowerShell 5.1 及以上版本_

在企业终端安全管理中，Windows Defender 已从简单的防病毒工具演变为完整的端点保护平台（EPP）。随着 Microsoft Defender for Endpoint 的持续升级，管理员需要一种可重复、可自动化的方式来统一部署安全策略。PowerShell 的 `Defender` 模块为此提供了全面的命令行支持。

传统上，管理员依赖组策略（GPO）或 Microsoft Endpoint Manager（Intune）来配置 Defender。但在混合环境中——尤其是需要快速响应安全事件、批量修复配置偏移或在新上线设备上应用基线时——PowerShell 脚本的灵活性和即时执行能力是 GUI 工具无法替代的。结合 DSC（Desired State Configuration）或 Ansible 等配置管理工具，还能实现持续合规。

本文将从三个维度介绍如何通过 PowerShell 管理 Windows Defender：基础配置与扫描管理、排除规则与高级策略、威胁响应与合规报告。每个部分都包含可直接用于生产环境的脚本示例。

<!-- more -->

## Defender 配置与扫描管理

通过 `Set-MpPreference` 和 `Get-MpPreference` 可以查看和修改 Defender 的核心配置。以下脚本展示了如何读取当前偏好设置、应用安全基线配置，以及触发不同类型的扫描。

```powershell
# 获取当前 Defender 偏好配置
$pref = Get-MpPreference
Write-Host "当前实时保护状态: $(Get-MpComputerStatus | Select-Object -ExpandProperty RealTimeProtectionEnabled)"
Write-Host "扫描计划: $($pref.ScanScheduleDay)"
Write-Host "快速扫描时间: $($pref.ScanScheduleTime)"

# 应用安全基线配置
$baselineParams = @{
    DisableRealtimeMonitoring          = $false
    DisableBehaviorMonitoring          = $false
    DisableBlockAtFirstSeen            = $false
    DisableIOAVProtection             = $false
    DisableScriptScanning             = $false
    EnableNetworkProtection           = 'Enabled'
    EnableFileHashComputation         = $true
    PUAProtection                     = 'Enabled'
    ScanScheduleDay                   = 0   # 每天扫描
    ScanScheduleTime                  = 120 # 凌晨 02:00
    ScanScheduleQuickScanTime         = 720 # 中午 12:00
    CheckForSignaturesBeforeRunningScan = $true
    SignatureUpdateInterval           = 4   # 每 4 小时更新一次
}
Set-MpPreference @baselineParams
Write-Host "安全基线配置已应用"

# 触发快速扫描
Write-Host "`n开始快速扫描..."
Start-MpScan -ScanType QuickScan

# 触发自定义路径扫描（针对高风险目录）
$highRiskPaths = @(
    "$env:USERPROFILE\Downloads",
    "$env:TEMP",
    "$env:PUBLIC"
)
foreach ($path in $highRiskPaths) {
    if (Test-Path $path) {
        Write-Host "扫描目录: $path"
        Start-MpScan -ScanType CustomScan -ScanPath $path
    }
}

# 查看扫描历史记录
$scanHistory = Get-MpThreatDetection | Select-Object -First 10
$scanHistory | Format-Table -Property `
    @{N='检测时间';E={$_.InitialDetectionTime}},
    @{N='威胁名称';E={$_.ThreatName}},
    @{N='资源';E={$_.Resources -join ', '}},
    @{N='操作';E={$_.ActionSuccess}} -AutoSize
```

执行结果示例：

```
当前实时保护状态: True
扫描计划: 0
快速扫描时间: 720

安全基线配置已应用

开始快速扫描...

扫描目录: C:\Users\admin\Downloads
扫描目录: C:\Users\admin\AppData\Local\Temp
扫描目录: C:\Users\Public

检测时间            威胁名称                              资源                                 操作
----------          ----------                            ----                                 ----
2026/01/27 14:23:01 Trojan:Win32/Emotet.RPX!MTB       C:\Users\admin\Downloads\report.exe  True
2026/01/27 03:12:45 Adware:Win32/InstallCore          C:\Temp\setup.exe                    True
2026/01/26 18:45:20 PUA:Win32/ByteFence               C:\Program Files\ByteFence\...       True
```

## 排除规则与高级策略

在企业环境中，某些业务应用程序会触发误报，需要配置排除规则。同时，攻击面减少（ASR）规则是现代 Defender 防御体系的重要组成部分。以下脚本展示了如何管理排除项和 ASR 规则。

```powershell
# 查看当前排除规则
$currentExclusions = Get-MpPreference
Write-Host "当前路径排除:"
$currentExclusions.ExclusionPath | ForEach-Object { Write-Host "  - $_" }
Write-Host "当前进程排除:"
$currentExclusions.ExclusionProcess | ForEach-Object { Write-Host "  - $_" }

# 配置路径排除（仅对已验证可信的业务目录）
$exclusionPaths = @(
    'D:\BusinessApps\CoreERP',
    'E:\DataWarehouse\Bin'
)
foreach ($path in $exclusionPaths) {
    if (Test-Path $path) {
        Add-MpPreference -ExclusionPath $path
        Write-Host "已添加路径排除: $path"
    } else {
        Write-Warning "路径不存在，跳过排除: $path"
    }
}

# 配置进程排除
$exclusionProcesses = @(
    'erpservice.exe',
    'dataworker.exe'
)
foreach ($proc in $exclusionProcesses) {
    Add-MpPreference -ExclusionProcess $proc
    Write-Host "已添加进程排除: $proc"
}

# 配置攻击面减少（ASR）规则
$asrRules = @{
    # 阻止从 Windows 本地安全机构子系统 (lsass.exe) 窃取凭据
    '9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2' = 'Enabled'
    # 阻止 Office 应用程序创建可执行内容
    '3b576869-a4ec-4529-8536-b80a7769e899' = 'Enabled'
    # 阻止 JavaScript/VBScript 启动下载的可执行内容
    'd3e037e1-3eb8-44c8-a917-57927947596d' = 'Enabled'
    # 阻止通过 WMI 事件订阅进行持久化
    'e6db77e5-3df2-4cf1-b95a-636979351e5b' = 'AuditMode'
    # 配置针对勒索软件的高级保护
    'c1db55ab-c21a-4637-bb3f-a8683d4c58c4' = 'Enabled'
}
foreach ($ruleId in $asrRules.Keys) {
    Add-MpPreference -AttackSurfaceReductionRules_Ids $ruleId `
                     -AttackSurfaceReductionRules_Actions $asrRules[$ruleId]
    $actionLabel = if ($asrRules[$ruleId] -eq 'AuditMode') { '审计模式' } else { '启用' }
    Write-Host "ASR 规则 $ruleId -> $actionLabel"
}

# 验证 ASR 规则配置
$pref = Get-MpPreference
Write-Host "`n已配置 $(($pref.AttackSurfaceReductionRules_Ids).Count) 条 ASR 规则"
```

执行结果示例：

```
当前路径排除:
  - D:\BusinessApps\CoreERP
  - E:\DataWarehouse\Bin
当前进程排除:
  - erpservice.exe
  - dataworker.exe
已添加路径排除: D:\BusinessApps\CoreERP
已添加路径排除: E:\DataWarehouse\Bin
已添加进程排除: erpservice.exe
已添加进程排除: dataworker.exe
ASR 规则 9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2 -> 启用
ASR 规则 3b576869-a4ec-4529-8536-b80a7769e899 -> 启用
ASR 规则 d3e037e1-3eb8-44c8-a917-57927947596d -> 启用
ASR 规则 e6db77e5-3df2-4cf1-b95a-636979351e5b -> 审计模式
ASR 规则 c1db55ab-c21a-4637-bb3f-a8683d4c58c4 -> 启用

已配置 5 条 ASR 规则
```

## 威胁响应与合规报告

当安全事件发生时，快速查询威胁状态、执行隔离或恢复操作至关重要。以下脚本展示了如何构建一套威胁响应与合规检查的工作流。

```powershell
# 查询当前活跃威胁
$activeThreats = Get-MpThreat
if ($activeThreats) {
    Write-Host "发现 $($activeThreats.Count) 个活跃威胁:" -ForegroundColor Red
    $activeThreats | Format-Table -Property `
        @{N='威胁ID';E={$_.ThreatID}},
        @{N='名称';E={$_.ThreatName}},
        @{N='严重级别';E={$_.SeverityID}},
        @{N='类别';E={$_.CategoryID}},
        @{N='状态';E={$_.ThreatStatus}} -AutoSize
} else {
    Write-Host "未发现活跃威胁，系统安全。" -ForegroundColor Green
}

# 查看最近 7 天的威胁检测记录
$cutoffDate = (Get-Date).AddDays(-7)
$recentDetections = Get-MpThreatDetection | Where-Object {
    [datetime]$_.InitialDetectionTime -ge $cutoffDate
}
Write-Host "`n最近 7 天检测到 $($recentDetections.Count) 个威胁"

# 获取已隔离威胁列表
$quarantined = Get-MpThreat | Where-Object { $_.ThreatStatus -eq 3 }
Write-Host "已隔离威胁数量: $($quarantined.Count)"

# 如需恢复误报的隔离文件（谨慎操作）
# $falsePositiveId = 'THREAT-ID-HERE'
# Remove-MpThreat -ThreatID $falsePositiveId

# 生成安全态势报告
$computerStatus = Get-MpComputerStatus
$signatureStatus = Get-MpPreference

$report = [PSCustomObject]@{
    计算机名称        = $env:COMPUTERNAME
    报告时间          = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Defender版本      = $computerStatus.AMServiceVersion
    病毒库版本        = $computerStatus.AntivirusSignatureVersion
    病毒库更新时间    = $computerStatus.AntivirusSignatureLastUpdated
    实时保护          = $computerStatus.RealTimeProtectionEnabled
    行为监控          = $computerStatus.BehaviorMonitorEnabled
    网络保护          = $computerStatus.EnableNetworkProtection
    IOAV保护          = $computerStatus.IoavProtectionEnabled
    反间谍软件        = $computerStatus.AntispywareSignatureVersion
    最近扫描时间      = $computerStatus.LastQuickScanEndTime
    最近完整扫描      = $computerStatus.LastFullScanEndTime
}

Write-Host "`n========== 安全态势报告 =========="
$report | Format-List

# 导出报告为 CSV（适用于批量采集）
$report | Export-Csv -Path "C:\Reports\DefenderReport_$($env:COMPUTERNAME)_$(Get-Date -Format 'yyyyMMdd').csv" `
    -NoTypeInformation -Encoding UTF8
Write-Host "报告已导出到 CSV 文件"
```

执行结果示例：

```
未发现活跃威胁，系统安全。

最近 7 天检测到 3 个威胁
已隔离威胁数量: 0

========== 安全态势报告 ==========

计算机名称      : WKS-ADMIN-01
报告时间        : 2026-01-28 10:30:00
Defender版本    : 4.18.25010.9
病毒库版本      : 1.423.58.0
病毒库更新时间  : 2026/01/28 06:15:00
实时保护        : True
行为监控        : True
网络保护        : Enabled
IOAV保护        : True
反间谍软件      : 1.423.58.0
最近扫描时间    : 2026/01/28 02:00:15
最近完整扫描    : 2026/01/25 02:45:30

报告已导出到 CSV 文件
```

## 注意事项

1. **管理员权限**：所有 Defender 管理 cmdlet 都需要以管理员身份运行 PowerShell。普通用户只能执行 `Get-MpPreference` 等查询命令，无法修改配置。

2. **排除规则最小化**：每添加一条排除规则都会降低保护力度。建议定期审计排除列表，移除不再需要的排除项，并通过 `Get-MpPreference` 验证排除项的合理性。

3. **ASR 规则分阶段部署**：新上线的 ASR 规则应先以 `AuditMode` 运行 1-2 周，收集日志确认无误报后，再切换为 `Enabled` 阻断模式，避免影响业务连续性。

4. **病毒库更新频率**：企业环境中建议将 `SignatureUpdateInterval` 设为 1-4 小时。零日威胁的签名通常在数小时内发布，过长的更新间隔会留下安全窗口。

5. **兼容性检查**：`Set-MpPreference` 的部分参数在不同 Windows 版本上可用性不同。例如 `EnableFileHashComputation` 需要 Windows 10 1903+，`PUAProtection` 需要 Windows 10 1709+。部署前应在目标系统上验证参数是否生效。

6. **与 Intune/GPO 的冲突**：当 Intune 或组策略同时管理 Defender 设置时，PowerShell 的手动修改可能在下次策略刷新时被覆盖。建议在 DSC 或配置管理框架中统一管理，避免策略来源冲突导致配置偏移。
