---
layout: post
date: 2026-02-24 08:00:00
updated: 2026-02-24 08:00:00
title: "PowerShell 技能连载 - 组策略自动化管理"
description: PowerTip of the Day - Group Policy Automation Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- group-policy
- gpo
- active-directory
- windows
---

_适用于 PowerShell 5.1 及以上版本，需要 GroupPolicy 模块_

组策略（Group Policy）是 Windows 域环境中管理配置和安全设置的核心机制。通过 GPO，管理员可以集中控制数千台计算机的注册表设置、安全策略、软件部署和脚本执行。在大型企业环境中，GPO 数量往往达到数百甚至上千个，涵盖安全基线、合规要求、桌面标准化等多个维度。

手动管理这些 GPO 不仅耗时，而且极易出错——一个配置遗漏可能导致全公司的安全防线出现缺口。传统的图形界面操作（GPMC）在面对批量创建、迁移、审计等场景时显得力不从心，尤其当组织需要在不同域或林之间迁移策略时，手动操作几乎不可行。

PowerShell 的 GroupPolicy 模块提供了完整的 GPO 生命周期管理能力，从创建、编辑、备份、还原到合规报告，全部可以通过脚本自动化完成。结合 ActiveDirectory 模块，还能实现基于组织单元（OU）结构的智能策略分配和变更追踪，让组策略管理变得可重复、可审计、可回溯。

<!-- more -->

## GPO 基础管理

以下脚本展示了 GPO 的创建、链接、备份和还原等基础操作，这些是日常管理中最常用的功能。

```powershell
# 导入 GroupPolicy 模块
Import-Module GroupPolicy

# 定义常用变量
$Domain = "contoso.com"
$BackupPath = "C:\GPOBackup\$(Get-Date -Format 'yyyyMMdd')"

# 创建新的 GPO
$GPO = New-GPO -Name "Security Baseline 2026" -Comment "年度安全基线策略"

# 将 GPO 链接到指定的 OU，并设置优先级
New-GPLink -Name "Security Baseline 2026" -Target "OU=Servers,DC=contoso,DC=com" -LinkEnabled Yes -Order 1

# 禁用 GPO 的用户配置部分（仅保留计算机配置）
$GPO | Set-GPO -GpoStatus UserSettingsDisabled

# 创建备份目录并备份所有 GPO
if (-not (Test-Path $BackupPath)) {
    New-Item -Path $BackupPath -ItemType Directory -Force | Out-Null
}

$BackupReport = Backup-GPO -All -Path $BackupPath
$BackupReport | Select-Object DisplayName, GpoId, BackupId, Timestamp |
    Format-Table -AutoSize

# 导出备份清单为 CSV，便于后续还原时查找
$BackupReport | Export-Csv -Path "$BackupPath\BackupInventory.csv" -NoTypeInformation -Encoding UTF8

# 从备份还原单个 GPO（模拟灾难恢复场景）
$LatestBackup = $BackupReport | Where-Object { $_.DisplayName -eq "Security Baseline 2026" }
Restore-GPO -Name "Security Baseline 2026" -Path $BackupPath -BackupId $LatestBackup.BackupId

# 查看域中所有 GPO 的概览
Get-GPO -All | Select-Object DisplayName, GpoStatus, CreationTime, ModificationTime |
    Sort-Object ModificationTime -Descending |
    Format-Table -AutoSize
```

执行结果示例：

```
DisplayName           GpoId                                 BackupId                             Timestamp
------------           -----                                 --------                             ---------
Security Baseline 2026 3a1b2c4d-5e6f-...                    a7b8c9d0-e1f2-...                    2026/2/24 10:30:15
Domain Controllers     f3e2d1c0-b9a8-...                    1a2b3c4d-5e6f-...                    2026/2/20 14:22:10
Default Domain Policy  7f8e9d0a-1b2c-...                    3c4d5e6f-7a8b-...                    2026/1/15 09:12:00

DisplayName           GpoStatus             CreationTime         ModificationTime
------------          ---------             ------------         ----------------
Security Baseline 2026 UserSettingsDisabled  2026/2/24 10:30:00   2026/2/24 10:32:00
Default Domain Policy  AllSettingsEnabled    2024/3/1 08:00:00    2026/1/15 09:12:00
Domain Controllers     AllSettingsEnabled    2024/3/1 08:00:00    2026/2/20 14:22:10
```

## 策略设置编辑

创建 GPO 只是第一步，实际管理工作中有大量策略项需要配置。以下脚本演示了如何通过注册表首选项、安全设置和脚本部署来编辑 GPO 内容。

```powershell
# --- 注册表首选项：通过 GPO 推送注册表项 ---
$GPOName = "Security Baseline 2026"
$Domain = "contoso.com"

# 设置注册表项：禁用 SMBv1（安全加固）
Set-GPPrefRegistryValue -Name $GPOName -Context Computer -Action Create `
    -Key "SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" `
    -ValueName "SMB1" -Value 0 -Type DWord -Order 1

# 设置注册表项：启用 PowerShell 脚本块日志记录
Set-GPPrefRegistryValue -Name $GPOName -Context Computer -Action Create `
    -Key "SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" `
    -ValueName "EnableScriptBlockLogging" -Value 1 -Type DWord -Order 2

# 设置注册表项：配置 Windows Defender 实时保护
Set-GPPrefRegistryValue -Name $GPOName -Context Computer -Action Create `
    -Key "SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" `
    -ValueName "DisableRealtimeMonitoring" -Value 0 -Type DWord -Order 3

# --- 安全设置：通过 ini 文件方式配置账户策略 ---
# 生成安全模板 INF 文件
$SecTemplatePath = "C:\Temp\SecurityTemplate.inf"
$InfContent = @"
[Unicode]
Unicode=yes
[Version]
signature=`"`$CHICAGO`$`"
Revision=1
[Account Policies]
[Password History]
MaximumPasswordAge = 90
MinimumPasswordAge = 1
MinimumPasswordLength = 14
PasswordComplexity = 1
[Lockout]
LockoutDuration = 30
LockoutBadCount = 5
ResetLockoutCount = 30
"@

Set-Content -Path $SecTemplatePath -Value $InfContent -Encoding Unicode

# --- 脚本部署：配置启动脚本 ---
$ScriptName = "Install-EndpointAgent.ps1"
$ScriptContent = @'
# 端点代理安装脚本 - 由组策略推送执行
$AgentPath = "\\contoso.com\SYSVOL\contoso.com\scripts\EndpointAgent.msi"
$LogPath = "C:\Logs\AgentInstall.log"

if (-not (Get-Service -Name "EndpointAgent" -ErrorAction SilentlyContinue)) {
    Start-Process msiexec.exe -ArgumentList "/i `"$AgentPath`" /qn /l*v `"$LogPath`"" -Wait
    Write-Output "$(Get-Date) - Endpoint Agent installed successfully" | Out-File $LogPath -Append
}
'@

# 将脚本保存到 GPO 的启动脚本目录
$GPO = Get-GPO -Name $GPOName
$StartupScriptFolder = "\\$Domain\SYSVOL\$Domain\Policies\{$($GPO.Id)}\Machine\Scripts\Startup"
if (-not (Test-Path $StartupScriptFolder)) {
    New-Item -Path $StartupScriptFolder -ItemType Directory -Force | Out-Null
}
Set-Content -Path "$StartupScriptFolder\$ScriptName" -Value $ScriptContent -Encoding UTF8

Write-Host "策略设置编辑完成：注册表首选项 3 项、安全模板 1 份、启动脚本 1 个"
```

执行结果示例：

```
策略设置编辑完成：注册表首选项 3 项、安全模板 1 份、启动脚本 1 个
```

## 合规审计与报告

策略配置完成后，持续的合规审计至关重要。以下脚本实现了 RSOP（策略结果集）分析、基线对比和变更追踪功能，帮助管理员及时发现策略漂移。

```powershell
# --- RSOP 分析：获取目标计算机的实际策略应用结果 ---
$ComputerName = "SRV-DC01.contoso.com"

# 生成 GPO 报告（HTML 格式）
$ReportPath = "C:\Reports\GPOReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
Get-GPOReport -All -ReportType Html -Path $ReportPath
Write-Host "GPO 报告已生成: $ReportPath"

# 获取指定计算机的 RSOP 报告
$RsopReport = "C:\Reports\RSOP_$ComputerName`_$(Get-Date -Format 'yyyyMMdd').html"
gpresult /s $ComputerName /h $RsopReport /f 2>$null
Write-Host "RSOP 报告已生成: $RsopReport"

# --- 基线对比：检测 GPO 是否偏离已知良好配置 ---
$BaselinePath = "C:\GPOBaseline"
$CurrentBackupPath = "C:\GPOBackup\$(Get-Date -Format 'yyyyMMdd')"

# 比较基线和当前备份中的 GPO 数量
$BaselineGPOs = Get-ChildItem -Path $BaselinePath -Directory
$CurrentGPOs = Get-ChildItem -Path $CurrentBackupPath -Directory

$Missing = $BaselineGPOs.Name | Where-Object { $_ -notin $CurrentGPOs.Name }
$New = $CurrentGPOs.Name | Where-Object { $_ -notin $BaselineGPOs.Name }

if ($Missing) {
    Write-Warning "以下基线 GPO 在当前备份中缺失: $($Missing -join ', ')"
}
if ($New) {
    Write-Host "发现新增 GPO: $($New -join ', ')" -ForegroundColor Yellow
}

# --- 变更追踪：监控 GPO 的修改时间和设置变更 ---
$AuditLog = "C:\Reports\GPO_AuditLog_$(Get-Date -Format 'yyyyMMdd').csv"

# 获取所有 GPO 的当前状态快照
$Snapshot = Get-GPO -All | ForEach-Object {
    $Links = (Get-GPOReport -Name $_.DisplayName -ReportType Xml)
    $LinkCount = ([xml]$Links).GPO.LinksTo | Measure-Object | Select-Object -ExpandProperty Count

    [PSCustomObject]@{
        GPOName         = $_.DisplayName
        GpoId           = $_.Id
        Status          = $_.GpoStatus
        LinkCount       = $LinkCount
        ComputerEnabled = ($_.GpoStatus -ne 'ComputerSettingsDisabled' -and $_.GpoStatus -ne 'AllSettingsDisabled')
        UserEnabled     = ($_.GpoStatus -ne 'UserSettingsDisabled' -and $_.GpoStatus -ne 'AllSettingsDisabled')
        ModifiedTime    = $_.ModificationTime
        AuditTime       = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    }
}

$Snapshot | Export-Csv -Path $AuditLog -NoTypeInformation -Encoding UTF8

# 标记最近 7 天内修改过的 GPO
$RecentChanges = $Snapshot | Where-Object { $_.ModifiedTime -gt (Get-Date).AddDays(-7) }
if ($RecentChanges) {
    Write-Host "`n最近 7 天内修改的 GPO:" -ForegroundColor Cyan
    $RecentChanges | Format-Table GPOName, ModifiedTime, LinkCount, Status -AutoSize
} else {
    Write-Host "`n最近 7 天内无 GPO 变更" -ForegroundColor Green
}

Write-Host "`n审计快照已保存: $AuditLog"
```

执行结果示例：

```
GPO 报告已生成: C:\Reports\GPOReport_20260224_103500.html
RSOP 报告已生成: C:\Reports\RSOP_SRV-DC01.contoso.com_20260224.html
发现新增 GPO: Security Baseline 2026

最近 7 天内修改的 GPO:

GPOName               ModifiedTime         LinkCount Status
-------               -------------         --------- ------
Security Baseline 2026 2026/2/24 10:32:00          1 UserSettingsDisabled
Domain Controllers     2026/2/20 14:22:10          1 AllSettingsEnabled

审计快照已保存: C:\Reports\GPO_AuditLog_20260224.csv
```

## 注意事项

1. **权限要求**：管理 GPO 需要域管理员或 Group Policy Creator Owners 组的成员权限。在生产环境中建议使用最小特权原则，为 GPO 管理员分配专门的委派权限，而非直接使用 Domain Admins 账户。

2. **备份策略**：建议建立定期自动备份机制，每次变更 GPO 前都执行 `Backup-GPO`。备份文件应存储在独立的文件服务器上，并纳入常规数据保护方案。备份 ID（BackupId）是还原时的关键标识，务必通过 CSV 清单妥善保管。

3. **测试先行**：新 GPO 或重大变更应先在测试 OU 上验证效果，确认无误后再推广到生产 OU。可以使用 `New-GPLink` 的 `-WhatIf` 参数预览链接操作，或者先将 GPO 链接设置为禁用状态（`-LinkEnabled No`），验证后再启用。

4. **WMI 筛选器**：复杂的策略分发场景可以结合 WMI 筛选器实现条件化应用，例如只对特定操作系统版本或硬件类型的计算机生效。但过多的 WMI 筛选器会影响组策略处理性能，建议控制在合理范围内。

5. **脚本块日志安全**：通过 GPO 启用 PowerShell 脚本块日志记录时，会产生大量日志数据。需要提前规划日志收集和存储方案（如 Windows Event Forwarding 或 SIEM 集成），避免本地日志溢出导致关键审计数据丢失。

6. **跨域迁移**：使用 `Backup-GPO` 和 `Import-GPO` 进行跨域迁移时，需要注意安全主体（用户、组）的 SID 映射问题。迁移表格（Migration Table）是解决这一问题的关键工具，建议在迁移前使用 `New-MigrationTable` 生成并仔细校验映射关系。
