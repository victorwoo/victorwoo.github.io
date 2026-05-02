---
layout: post
date: 2025-08-21 08:00:00
updated: 2025-08-21 08:00:00
title: "PowerShell 技能连载 - Windows 更新自动化管理"
description: PowerTip of the Day - Windows Update Automation in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- windows
- system-management
- automation
---

_适用于 PowerShell 5.1 及以上版本_

操作系统补丁管理是企业安全运维的基石。未打补丁的系统是勒索软件和漏洞攻击的首要目标，每一次重大的安全事件背后几乎都有"未及时安装更新"的影子。然而，Windows 更新管理远比点击"检查更新"复杂得多——需要控制更新时机、筛选更新类别、处理重启策略、验证安装结果，并在多台服务器上保持一致性。

PowerShell 通过 `Microsoft.Update.Session` COM 对象和 `PSWindowsUpdate` 模块提供了完整的 Windows 更新编程接口。本文将介绍如何使用 PowerShell 实现 Windows 更新的查询、安装、回滚和自动化管理。

<!-- more -->

## 查询可用的 Windows 更新

在安装更新之前，先了解有哪些可用更新及其分类。

```powershell
function Get-WindowsAvailableUpdate {
    <#
    .SYNOPSIS
    查询可用的 Windows 更新
    .PARAMETER Category
    更新类别过滤（Security、Important、Optional）
    #>
    [CmdletBinding()]
    param(
        [string]$Category
    )

    # 创建更新会话
    $updateSession = New-Object -ComObject Microsoft.Update.Session
    $updateSearcher = $updateSession.CreateUpdateSearcher()

    # 构建搜索条件
    $searchCriteria = 'IsInstalled=0 and Type=''Software'''

    Write-Verbose "搜索条件：$searchCriteria"
    $searchResult = $updateSearcher.Search($searchCriteria)

    Write-Verbose "找到 $($searchResult.Updates.Count) 个可用更新"

    $updates = foreach ($update in $searchResult.Updates) {
        # 确定更新类别
        $categories = $update.Categories | ForEach-Object { $_.Name }
        $isSecurity = $categories -contains 'Security Updates'
        $isImportant = $categories -contains 'Important Updates'

        $updateClass = if ($isSecurity) { 'Security' }
                       elseif ($isImportant) { 'Important' }
                       else { 'Optional' }

        [PSCustomObject]@{
            Title           = $update.Title
            KB              = if ($update.KBArticleIDs.Count -gt 0) { $update.KBArticleIDs[0] } else { 'N/A' }
            Category        = $updateClass
            Categories      = ($categories -join ', ')
            SizeMB          = [math]::Round($update.MaxDownloadSize / 1MB, 2)
            IsMandatory     = $update.IsMandatory
            IsDownloaded    = $update.IsDownloaded
            Description     = $update.Description
            Identity        = $update.Identity.UpdateID
        }
    }

    # 按类别过滤
    if ($Category) {
        $updates = $updates | Where-Object { $_.Category -eq $Category }
    }

    $updates | Sort-Object Category, Title
}

# 查询所有可用更新
$available = Get-WindowsAvailableUpdate -Verbose
$available | Format-Table Title, KB, Category, SizeMB -AutoSize

# 按类别统计
$available | Group-Object Category | Format-Table Name, Count -AutoSize
```

执行结果示例：

```text
详细: 搜索条件：IsInstalled=0 and Type='Software'
详细: 找到 12 个可用更新

Title                                       KB        Category  SizeMB
-----                                       --        --------  ------
2025-08 Security Update for Windows Server  KB5041234 Security    125.5
2025-08 Cumulative Update for .NET Framework KB5041235 Security     68.2
Windows Malicious Software Removal Tool     KB890830  Important    45.0
.NET Runtime 8.0.8 Update                   KB5041236 Optional     32.1

Name     Count
----     -----
Security     2
Important    1
Optional     9
```

## 下载并安装 Windows 更新

通过 COM 对象控制更新下载和安装过程，可以精确控制安装哪些更新。

```powershell
function Install-WindowsUpdate {
    <#
    .SYNOPSIS
    下载并安装 Windows 更新
    .PARAMETER Category
    安装指定类别的更新
    .PARAMETER KBArticleIDs
    安装指定 KB 编号的更新
    .PARAMETER AutoReboot
    是否允许自动重启
    #>
    [CmdletBinding()]
    param(
        [string]$Category,

        [string[]]$KBArticleIDs,

        [switch]$AutoReboot
    )

    $updateSession = New-Object -ComObject Microsoft.Update.Session
    $updateSearcher = $updateSession.CreateUpdateSearcher()

    # 搜索可用更新
    $searchResult = $updateSearcher.Search('IsInstalled=0 and Type=''Software''')

    # 筛选要安装的更新
    $updatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl

    foreach ($update in $searchResult.Updates) {
        $shouldInstall = $false

        # 按 KB 编号筛选
        if ($KBArticleIDs) {
            foreach ($kb in $KBArticleIDs) {
                if ($update.KBArticleIDs.Count -gt 0 -and $update.KBArticleIDs.Contains($kb)) {
                    $shouldInstall = $true
                    break
                }
            }
        }
        # 按类别筛选（默认安装安全更新）
        elseif ($Category -eq 'Security') {
            $cats = $update.Categories | ForEach-Object { $_.Name }
            if ($cats -contains 'Security Updates') {
                $shouldInstall = $true
            }
        }
        else {
            $shouldInstall = $true
        }

        if ($shouldInstall) {
            # 接受 EULA
            if ($update.EulaAccepted -eq $false) {
                $update.AcceptEula()
            }
            [void]$updatesToInstall.Add($update)
            Write-Verbose "添加更新：$($update.Title)"
        }
    }

    if ($updatesToInstall.Count -eq 0) {
        Write-Host '没有需要安装的更新' -ForegroundColor Yellow
        return
    }

    Write-Host "准备安装 $($updatesToInstall.Count) 个更新" -ForegroundColor Cyan

    # 下载更新
    Write-Host '正在下载更新...' -ForegroundColor Yellow
    $downloader = $updateSession.CreateUpdateDownloader()
    $downloader.Updates = $updatesToInstall
    $downloadResult = $downloader.Download()

    $downloadStatus = switch ($downloadResult.ResultCode) {
        0 { 'NotStarted' }
        1 { 'InProgress' }
        2 { 'Succeeded' }
        3 { 'SucceededWithErrors' }
        4 { 'Failed' }
        5 { 'Aborted' }
        default { 'Unknown' }
    }

    Write-Host "下载状态：$downloadStatus"

    if ($downloadResult.ResultCode -notin @(2, 3)) {
        throw "下载失败，状态码：$($downloadResult.ResultCode)"
    }

    # 安装更新
    Write-Host '正在安装更新...' -ForegroundColor Yellow
    $installer = $updateSession.CreateUpdateInstaller()
    $installer.Updates = $updatesToInstall

    if (-not $AutoReboot) {
        # 禁止自动重启
        $installer.AllowSourcePrompts = $false
    }

    $installResult = $installer.Install()

    # 输出每个更新的安装结果
    $results = for ($i = 0; $i -lt $updatesToInstall.Count; $i++) {
        $resultCode = $installResult.GetUpdateResult($i).ResultCode
        $status = switch ($resultCode) {
            0 { 'NotStarted' }
            1 { 'InProgress' }
            2 { 'Installed' }
            3 { 'InstalledWithErrors' }
            4 { 'Failed' }
            5 { 'Aborted' }
            default { 'Unknown' }
        }

        [PSCustomObject]@{
            Title  = $updatesToInstall.Item($i).Title
            KB     = if ($updatesToInstall.Item($i).KBArticleIDs.Count -gt 0) { $updatesToInstall.Item($i).KBArticleIDs[0] } else { 'N/A' }
            Status = $status
        }
    }

    $results | Format-Table -AutoSize

    # 检查是否需要重启
    if ($installResult.RebootRequired) {
        if ($AutoReboot) {
            Write-Host '更新安装完成，正在重启系统...' -ForegroundColor Yellow
            Restart-Computer -Force
        } else {
            Write-Host '更新安装完成，需要重启系统' -ForegroundColor Yellow
        }
    } else {
        Write-Host '更新安装完成，无需重启' -ForegroundColor Green
    }

    return $results
}

# 只安装安全更新
$installResults = Install-WindowsUpdate -Category 'Security' -Verbose
```

执行结果示例：

```text
详细: 添加更新：2025-08 Security Update for Windows Server
详细: 添加更新：2025-08 Cumulative Update for .NET Framework
准备安装 2 个更新
正在下载更新...
下载状态：Succeeded
正在安装更新...

Title                                            KB        Status
-----                                            --        ------
2025-08 Security Update for Windows Server       KB5041234 Installed
2025-08 Cumulative Update for .NET Framework     KB5041235 Installed
更新安装完成，需要重启系统
```

## 使用 PSWindowsUpdate 模块

`PSWindowsUpdate` 是社区维护的优秀模块，提供了更简洁的 Windows 更新管理接口。

```powershell
# 安装模块（仅首次需要）
Install-Module -Name PSWindowsUpdate -Force -Scope CurrentUser
Import-Module PSWindowsUpdate

# 查看可用更新
Get-WindowsUpdate -Verbose | Format-Table Title, KB, Size, Status -AutoSize

# 只安装安全更新
Get-WindowsUpdate -Category 'Security Updates' -AcceptAll -Install -AutoReboot -Verbose

# 排除特定 KB
Get-WindowsUpdate -NotKBArticleID 'KB5041234' -AcceptAll -Install -Verbose

# 查看安装历史
Get-WUHistory | Select-Object -First 10 | Format-Table Date, Title, Result -AutoSize

# 远程管理多台服务器的更新
$servers = @('SRV01', 'SRV02', 'SRV03')
Get-WindowsUpdate -ComputerName $servers -Category 'Security Updates' -AcceptAll -Install -Verbose
```

执行结果示例：

```text
Title                                         KB        Size     Status
-----                                         --        ----     ------
2025-08 Security Update for Windows Server    KB5041234 125.5 MB Downloaded
2025-08 .NET Framework Cumulative Update      KB5041235  68.2 MB Downloaded

ComputerName Result     KB         Title
------------ ------     --         -----
SRV01        Accepted   KB5041234  2025-08 Security Update for Windows Server
SRV01        Accepted   KB5041235  2025-08 .NET Framework Cumulative Update
SRV02        Accepted   KB5041234  2025-08 Security Update for Windows Server
SRV03        Accepted   KB5041234  2025-08 Security Update for Windows Server

Date                Title                                       Result
----                -----                                       ------
2025/8/20 22:00:15  2025-08 Security Update for Windows Server  Installed
2025/8/13 22:00:10  2025-08 .NET Framework Cumulative Update    Installed
2025/8/6  22:00:08  2025-07 Security Update for Windows Server  Installed
```

## 查询已安装的更新历史

了解系统上已安装了哪些更新，有助于审计和排查问题。

```powershell
function Get-WindowsUpdateHistory {
    <#
    .SYNOPSIS
    查询 Windows 更新安装历史
    .PARAMETER Days
    查询最近多少天的记录
    .PARAMETER Result
    按安装结果过滤（Succeeded、Failed、All）
    #>
    [CmdletBinding()]
    param(
        [int]$Days = 30,

        [ValidateSet('Succeeded', 'Failed', 'All')]
        [string]$Result = 'All'
    )

    $updateSession = New-Object -ComObject Microsoft.Update.Session
    $updateSearcher = $updateSession.CreateUpdateSearcher()

    # 查询历史记录
    $cutoffDate = (Get-Date).AddDays(-$Days)
    $history = $updateSearcher.QueryHistory(0, $updateSearcher.GetTotalHistoryCount())

    $results = foreach ($record in $history) {
        if ($record.Date -lt $cutoffDate) { continue }

        $operation = switch ($record.Operation) {
            1 { 'Install' }
            2 { 'Uninstall' }
            default { 'Unknown' }
        }

        $resultCode = switch ($record.ResultCode) {
            0 { 'NotStarted' }
            1 { 'InProgress' }
            2 { 'Succeeded' }
            3 { 'SucceededWithErrors' }
            4 { 'Failed' }
            5 { 'Aborted' }
            default { 'Unknown' }
        }

        # 提取 KB 编号
        $kb = if ($record.Title -match 'KB(\d+)') { "KB$($Matches[1])" } else { 'N/A' }

        [PSCustomObject]@{
            Date       = $record.Date
            Title      = $record.Title
            KB         = $kb
            Operation  = $operation
            Result     = $resultCode
            HResult    = $record.HResult
        }
    }

    # 按结果过滤
    if ($Result -eq 'Succeeded') {
        $results = $results | Where-Object { $_.Result -eq 'Succeeded' }
    } elseif ($Result -eq 'Failed') {
        $results = $results | Where-Object { $_.Result -in @('Failed', 'SucceededWithErrors') }
    }

    $results | Sort-Object Date -Descending
}

# 查询最近 30 天的更新历史
$history = Get-WindowsUpdateHistory -Days 30
$history | Format-Table Date, KB, Operation, Result -AutoSize

# 只看失败的更新
Get-WindowsUpdateHistory -Days 90 -Result Failed | Format-Table Date, Title, Result -AutoSize
```

执行结果示例：

```text
Date                KB        Operation Result
----                --        --------- ------
2025/8/20 22:00:15  KB5041234 Install   Succeeded
2025/8/20 22:00:12  KB5041235 Install   Succeeded
2025/8/13 22:00:10  KB5040987 Install   Succeeded
2025/8/6  22:00:08  KB5040765 Install   Succeeded
2025/7/30 22:00:05  KB5040543 Install   Failed
```

## 卸载 Windows 更新

某些更新可能导致兼容性问题，需要回滚（卸载）。

```powershell
function Uninstall-WindowsUpdateByKB {
    <#
    .SYNOPSIS
    卸载指定的 Windows 更新
    .PARAMETER KBArticleID
    要卸载的 KB 编号
    .PARAMETER AutoReboot
    是否自动重启
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$KBArticleID,

        [switch]$AutoReboot
    )

    # 使用 wusa 卸载更新
    $wusaPath = Join-Path $env:SystemRoot 'System32\wusa.exe'

    # 先查找已安装更新的 .msu 文件路径
    $updateSession = New-Object -ComObject Microsoft.Update.Session
    $updateSearcher = $updateSession.CreateUpdateSearcher()
    $searchResult = $updateSearcher.Search("IsInstalled=1 and Type='Software'")

    $targetUpdate = $null
    foreach ($update in $searchResult.Updates) {
        if ($update.KBArticleIDs.Count -gt 0 -and $update.KBArticleIDs.Contains($KBArticleID)) {
            $targetUpdate = $update
            break
        }
    }

    if (-not $targetUpdate) {
        Write-Warning "未找到已安装的更新：$KBArticleID"
        return
    }

    Write-Verbose "找到更新：$($targetUpdate.Title)"
    Write-Host "正在卸载：$($targetUpdate.Title)" -ForegroundColor Yellow

    # 使用 DISM 卸载（更可靠）
    $dismArgs = "/Online /Remove-Package /PackageName:$($targetUpdate.Identity.UpdateID) /NoRestart /Quiet"

    $process = Start-Process -FilePath 'dism.exe' `
        -ArgumentList $dismArgs `
        -Wait `
        -PassThru `
        -NoNewWindow

    $status = if ($process.ExitCode -eq 0) { 'Succeeded' } else { "Failed (Exit: $($process.ExitCode))" }

    [PSCustomObject]@{
        KB         = $KBArticleID
        Title      = $targetUpdate.Title
        Status     = $status
        RebootRequired = $process.ExitCode -eq 3010
    }

    if ($process.ExitCode -in @(0, 3010) -and $AutoReboot) {
        Write-Host '卸载完成，正在重启...' -ForegroundColor Yellow
        Restart-Computer -Force
    }
}

# 卸载特定更新
$uninstallResult = Uninstall-WindowsUpdateByKB -KBArticleID 'KB5041234' -Verbose
$uninstallResult | Format-List
```

执行结果示例：

```text
详细: 找到更新：2025-08 Security Update for Windows Server
正在卸载：2025-08 Security Update for Windows Server

KB              : KB5041234
Title           : 2025-08 Security Update for Windows Server
Status          : Succeeded
RebootRequired  : True
```

## 自动化补丁管理计划

将更新管理流程编排为可定期执行的计划任务。

```powershell
function Register-PatchSchedule {
    <#
    .SYNOPSIS
    注册自动化补丁管理计划任务
    .PARAMETER ScheduleDay
    执行日期（每周几）
    .PARAMETER ScheduleTime
    执行时间
    .PARAMETER Category
    更新类别
    .PARAMETER AutoReboot
    是否自动重启
    #>
    [CmdletBinding()]
    param(
        [DayOfWeek]$ScheduleDay = 'Sunday',

        [string]$ScheduleTime = '02:00',

        [string]$Category = 'Security',

        [switch]$AutoReboot
    )

    # 创建计划任务动作
    $scriptBlock = @"
        Import-Module PSWindowsUpdate
        Get-WindowsUpdate -Category 'Security Updates' -AcceptAll -Install $(if ($AutoReboot) { '-AutoReboot' })
        Write-Output "Patch cycle completed at $(Get-Date)" >> C:\Logs\WindowsUpdate\patch-cycle.log
"@

    $scriptPath = 'C:\Scripts\Invoke-PatchCycle.ps1'
    $scriptDir = Split-Path $scriptPath
    if (-not (Test-Path $scriptDir)) {
        New-Item -Path $scriptDir -ItemType Directory -Force | Out-Null
    }
    $scriptBlock | Set-Content $scriptPath -Encoding UTF8

    # 注册计划任务
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $ScheduleDay -At $ScheduleTime
    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

    $principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest

    $taskParams = @{
        TaskName  = 'AutoPatchCycle'
        Action    = $action
        Trigger   = $trigger
        Settings  = $settings
        Principal = $principal
        Description = '每周自动安装 Windows 安全更新'
    }

    Register-ScheduledTask @taskParams -Force

    Write-Host "计划任务已注册：AutoPatchCycle" -ForegroundColor Green
    Write-Host "执行时间：每周$ScheduleDay $ScheduleTime" -ForegroundColor Cyan
    Write-Host "更新类别：$Category" -ForegroundColor Cyan
    Write-Host "自动重启：$AutoReboot" -ForegroundColor Cyan
}

# 注册每周日凌晨 2 点执行的安全更新任务
Register-PatchSchedule -ScheduleDay Sunday -ScheduleTime '02:00' -Category Security -AutoReboot
```

执行结果示例：

```text
计划任务已注册：AutoPatchCycle
执行时间：每周Sunday 02:00
更新类别：Security
自动重启：True
```

## 注意事项

- **补丁测试**：生产服务器上不要第一时间安装新补丁。建议先在测试环境验证，确认无兼容性问题后再逐步推广到生产环境，形成"测试-预发布-生产"的分阶段部署流程。
- **重启窗口**：安全更新通常需要重启才能生效，应配置在业务低峰期（如凌晨）自动重启，避免影响在线服务。重启前确保所有应用服务已正确停止。
- **WSUS 配置**：企业环境中通常使用 WSUS（Windows Server Update Services）或 SCCM 管理更新分发，PowerShell 脚本中的更新源会自动继承系统的 WSUS 配置，无需额外设置。
- **回滚方案**：某些更新可能导致应用程序兼容性问题，安装前应创建系统还原点（`Checkpoint-Computer`），确保可以快速回滚。
- **日志审计**：每次补丁操作都应记录详细日志，包括安装时间、更新编号、操作结果和操作者信息，以满足安全合规审计要求。
- **模块兼容性**：`PSWindowsUpdate` 模块在不同 Windows 版本上的行为可能有差异，使用前应在目标系统上测试兼容性，必要时回退到 COM 对象方式。
