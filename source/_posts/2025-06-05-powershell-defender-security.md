---
layout: post
date: 2025-06-05 08:00:00
updated: 2025-06-05 08:00:00
title: "PowerShell 技能连载 - Windows Defender 安全管理"
description: PowerTip of the Day - Windows Defender Security Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- security
- defender
- antivirus
- malware
---

_适用于 Windows 10/11 和 Windows Server 2016 及以上版本_

Windows Defender（现称 Microsoft Defender for Endpoint）是 Windows 内置的端点安全解决方案，提供实时保护、漏洞扫描、攻击面减少等多层防护。对于运维人员来说，通过 PowerShell 管理 Defender 比通过 Windows 安全中心 GUI 更高效——可以批量部署策略、自动化扫描、导出安全报告，并将安全操作集成到运维自动化流程中。

本文将讲解 Defender 的配置管理、扫描自动化、威胁响应和攻击面减少（ASR）规则配置。

<!-- more -->

## Defender 状态查询

```powershell
# 查看 Defender 服务状态
Get-MpComputerStatus | Select-Object `
    AMServiceVersion, AntispywareSignatureLastUpdated, AntivirusEnabled,
    RealTimeProtectionEnabled, NISEnabled, `
    @{N='上次快速扫描'; E={$_.QuickScanEndTime.ToString('yyyy-MM-dd HH:mm:ss')}}, `
    @{N='上次全盘扫描'; E={$_.FullScanEndTime.ToString('yyyy-MM-dd HH:mm:ss')}} |
    Format-List

# 查看签名版本和更新时间
Get-MpComputerStatus | Select-Object `
    AntivirusSignatureVersion, AntispywareSignatureVersion,
    AntivirusSignatureLastUpdated, AntispywareSignatureLastUpdated |
    Format-List

# 查看检测到的威胁
Get-MpThreatDetection | Select-Object -First 10 `
    @{N='检测时间'; E={$_.InitialDetectionTime.ToString('yyyy-MM-dd HH:mm:ss')}}, `
    @{N='威胁名'; E={$_.ThreatName}}, `
    @{N='资源'; E={$_.Resources}}, `
    @{N='操作'; E={$_.ActionSuccess}} |
    Format-Table -AutoSize

# 查看当前排除项
$preferences = Get-MpPreference
Write-Host "排除路径："
$preferences.ExclusionPath | ForEach-Object { Write-Host "  $_" }
Write-Host "排除扩展名："
$preferences.ExclusionExtension | ForEach-Object { Write-Host "  $_" }
```

执行结果示例：

```
AMServiceVersion            : 4.18.24050.5
AntispywareSignatureLastUpdated : 2025-06-05 07:30:00
AntivirusEnabled            : True
RealTimeProtectionEnabled   : True
NISEnabled                  : True
上次快速扫描                  : 2025-06-05 06:00:00
上次全盘扫描                  : 2025-06-01 02:00:00

AntivirusSignatureVersion     : 1.423.42.0
AntispywareSignatureLastUpdated : 2025-06-05 07:30:00

检测时间              威胁名                    资源             操作
--------              ------                    ----             ----
2025-06-04 15:30:22   Trojan:Win32/Emotet      C:\Temp\doc.exe  True
2025-06-03 08:12:45   Adware:Win32/BrowseFox   C:\Users\...     True

排除路径：
  C:\Projects\test
  D:\VirtualMachines
排除扩展名：
  .vmdk
  .vhd
```

## 签名更新管理

```powershell
# 手动更新 Defender 签名
Update-MpSignature
Write-Host "签名更新已触发" -ForegroundColor Green

# 检查签名是否是最新的
$status = Get-MpComputerStatus
$signatureAge = [math]::Floor((Get-Date) - $status.AntivirusSignatureLastUpdated).TotalDays)

if ($signatureAge -gt 3) {
    Write-Warning "签名已过期 $signatureAge 天，正在强制更新"
    Update-MpSignature -UpdateSource MicrosoftUpdateServer
}

# 配置自动签名更新源
Set-MpPreference -SignatureUpdateInterval 6  # 每 6 小时检查更新
Set-MpPreference -SignatureUpdateCatchupInterval 2  # 如果错过，2 天内补更新

# 查看更新历史
Get-MpComputerStatus | Select-Object `
    AntivirusSignatureVersion, `
    @{N='签名年龄(天)'; E={$signatureAge}}, `
    AntivirusSignatureLastUpdated
```

执行结果示例：

```
签名更新已触发

AntivirusSignatureVersion : 1.423.42.0
签名年龄(天) : 0
AntivirusSignatureLastUpdated : 2025-06-05 08:00:15
```

## 扫描自动化

```powershell
# 快速扫描
Start-MpScan -ScanType QuickScan
Write-Host "快速扫描完成" -ForegroundColor Green

# 全盘扫描（耗时较长）
Start-MpScan -ScanType FullScan -AsJob
Write-Host "全盘扫描已在后台启动" -ForegroundColor Cyan

# 自定义路径扫描
Start-MpScan -ScanType CustomScan -ScanPath "C:\Downloads"

# 定期扫描任务（结合计划任务）
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-NoProfile -Command Start-MpScan -ScanType QuickScan"

$trigger = New-ScheduledTaskTrigger -Daily -At "12:00PM"
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable

Register-ScheduledTask -TaskName "Defender-DailyQuickScan" `
    -Action $action -Trigger $trigger -Settings $settings `
    -User "SYSTEM" -RunLevel Highest -Force

Write-Host "每日快速扫描计划任务已创建" -ForegroundColor Green

# 查看扫描历史
Get-MpThreatDetection | Group-Object @{E={$_.InitialDetectionTime.ToString('yyyy-MM-dd')}} |
    Select-Object Name, Count |
    Sort-Object Name -Descending |
    Format-Table -AutoSize
```

执行结果示例：

```
快速扫描完成
全盘扫描已在后台启动
每日快速扫描计划任务已创建

Name       Count
----       -----
2025-06-05     0
2025-06-04     1
2025-06-03     2
2025-06-02     0
```

## 攻击面减少（ASR）规则

ASR 规则是 Defender 高级防护功能，可以阻止常见的攻击行为：

```powershell
# 查看所有 ASR 规则及其状态
$asrRules = @{
    '56a863a9-875e-4185-98a7-b882c64b5ce5' = '阻止滥用漏洞的已签名驱动程序'
    '7674ba52-37eb-4a4f-a9a1-f0f9a1619a2c' = '阻止 Office 应用程序创建可执行内容'
    'd4f940ab-401b-4efc-aadc-ad5f3c50688a' = '阻止 Office 应用程序将代码注入其他进程'
    '9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2' = '阻止从电子邮件中下载的可执行内容'
    'be9ba2d9-53ea-4cd1-8069-5e3661101962' = '阻止凭据窃取'
    'b2b3f03d-6a65-4f7b-a9c7-1c7ef74a9ba4' = '阻止 WMI 事件订阅持久化'
}

Get-MpPreference | Select-Object -ExpandProperty AttackSurfaceReductionRules_Ids |
    ForEach-Object {
        $id = $_
        $state = (Get-MpPreference).AttackSurfaceReductionRules_Actions |
            Select-Object -Index ((Get-MpPreference).AttackSurfaceReductionRules_Ids.IndexOf($id))

        [PSCustomObject]@{
            ID     = $id
            规则   = $asrRules[$id] ?? '未知规则'
            状态   = switch ($state) { 0 { '禁用' } 1 { '阻止' } 2 { '审计' } 6 { '警告' } }
        }
    } | Format-Table -AutoSize

# 启用 ASR 规则（审计模式，仅记录不阻止）
Set-MpPreference -AttackSurfaceReductionRules_Ids @(
    '56a863a9-875e-4185-98a7-b882c64b5ce5',
    '7674ba52-37eb-4a4f-a9a1-f0f9a1619a2c',
    'be9ba2d9-53ea-4cd1-8069-5e3661101962'
) -AttackSurfaceReductionRules_Actions @(2, 2, 2)  # 2 = 审计模式

Write-Host "ASR 规则已设置为审计模式" -ForegroundColor Yellow

# 切换为阻止模式
Set-MpPreference -AttackSurfaceReductionRules_Actions @(1, 1, 1)  # 1 = 阻止
Write-Host "ASR 规则已切换为阻止模式" -ForegroundColor Red
```

执行结果示例：

```
ID                                   规则                              状态
--                                   ----                              ----
56a863a9-875e-4185-98a7-b882c64b5ce5 阻止滥用漏洞的已签名驱动程序        审计
7674ba52-37eb-4a4f-a9a1-f0f9a1619a2c 阻止 Office 应用程序创建可执行内容  阻止
be9ba2d9-53ea-4cd1-8069-5e3661101962 阻止凭据窃取                      阻止

ASR 规则已设置为审计模式
```

## 威胁响应

```powershell
function Get-DefenderThreatReport {
    <#
    .SYNOPSIS
    生成 Defender 威胁报告
    #>
    param([int]$Days = 7)

    $startDate = (Get-Date).AddDays(-$Days)

    $detections = Get-MpThreatDetection |
        Where-Object { $_.InitialDetectionTime -ge $startDate }

    $report = [PSCustomObject]@{
        检测总数   = $detections.Count
        活跃威胁   = (Get-MpThreat).Count
        报告周期   = "$Days 天"
        时间范围   = "$startDate ~ $(Get-Date -Format 'yyyy-MM-dd')"
    }

    # 按威胁类型分组
    $byThreat = $detections | Group-Object ThreatName |
        Sort-Object Count -Descending |
        Select-Object -First 10 Count, Name

    # 按天分组
    $byDay = $detections | Group-Object @{E={$_.InitialDetectionTime.ToString('yyyy-MM-dd')}} |
        Sort-Object Name |
        Select-Object Name, Count

    Write-Host "========== Defender 威胁报告 ($Days 天) ==========" -ForegroundColor Cyan
    Write-Host "检测总数：$($report.检测总数)"
    Write-Host "当前活跃威胁：$($report.活跃威胁)"

    Write-Host "`nTop 威胁：" -ForegroundColor Yellow
    $byThreat | Format-Table -AutoSize

    Write-Host "每日检测数：" -ForegroundColor Yellow
    $byDay | Format-Table -AutoSize
}

# 生成 30 天威胁报告
Get-DefenderThreatReport -Days 30
```

执行结果示例：

```
========== Defender 威胁报告 (30 天) ==========
检测总数：12
当前活跃威胁：0

Top 威胁：
Count Name
----- ----
    3 Trojan:Win32/Emotet
    2 Adware:Win32/BrowseFox
    1 PUA:Win32/MyWebSearch

每日检测数：
Name       Count
----       -----
2025-05-15     2
2025-05-20     1
2025-06-01     3
2025-06-04     6
```

## 注意事项

1. **管理员权限**：Defender 管理命令需要以管理员身份运行 PowerShell
2. **排除项最小化**：排除路径和扩展名会降低防护能力，仅排除确有误报风险的路径
3. **ASR 规则部署**：生产环境建议先在审计模式下运行 ASR 规则，确认无误报后再切换为阻止模式
4. **签名更新**：确保签名自动更新正常工作，离线环境需配置 WSUS 或本地更新源
5. **扫描性能影响**：全盘扫描会消耗大量 I/O 资源，应安排在业务低峰期执行
6. **与第三方杀软共存**：如果安装了第三方杀毒软件，Defender 会自动进入被动模式，仅提供有限功能
