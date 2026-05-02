---
layout: post
date: 2025-08-20 08:00:00
updated: 2025-08-20 08:00:00
title: "PowerShell 技能连载 - 磁盘清理自动化"
description: PowerTip of the Day - Automated Disk Cleanup in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- disk-cleanup
- storage
- automation
- system-maintenance
---

_适用于 PowerShell 5.1 及以上版本_

磁盘空间不足是运维中最常见的问题之一。日志文件堆积、临时文件未清理、回收站膨胀、Windows 更新缓存占用等问题，如果不加以管理，迟早会导致系统异常甚至服务中断。在容器化和虚拟化环境中，磁盘资源更是需要精打细算，自动化的磁盘清理机制必不可少。

手动清理磁盘既低效又容易遗漏，而且无法做到定期执行。通过 PowerShell 脚本可以精确定位各类可清理的目标，量化空间占用，并在安全的前提下自动执行清理操作。本文将介绍如何构建一个全面的磁盘清理自动化方案。

## 磁盘空间分析

在执行清理之前，需要先了解磁盘空间的使用情况以及哪些目录占用最多。

```powershell
function Get-DiskSpaceInfo {
    <#
    .SYNOPSIS
    获取磁盘空间使用情况
    .PARAMETER DriveLetter
    盘符（默认获取所有驱动器）
    #>
    [CmdletBinding()]
    param(
        [string]$DriveLetter
    )

    $drives = Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType = 3'

    if ($DriveLetter) {
        $drives = $drives | Where-Object { $_.DeviceID -eq "$($DriveLetter):" }
    }

    foreach ($drive in $drives) {
        $totalGB = [math]::Round($drive.Size / 1GB, 2)
        $freeGB = [math]::Round($drive.FreeSpace / 1GB, 2)
        $usedGB = [math]::Round(($drive.Size - $drive.FreeSpace) / 1GB, 2)
        $usedPercent = [math]::Round(($drive.Size - $drive.FreeSpace) / $drive.Size * 100, 1)

        [PSCustomObject]@{
            Drive       = $drive.DeviceID
            TotalGB     = $totalGB
            UsedGB      = $usedGB
            FreeGB      = $freeGB
            UsedPercent = $usedPercent
            Status      = if ($usedPercent -gt 90) { 'Critical' }
                          elseif ($usedPercent -gt 80) { 'Warning' }
                          else { 'OK' }
        }
    }
}

# 查看所有驱动器空间
Get-DiskSpaceInfo | Format-Table -AutoSize
```

执行结果示例：

```text
Drive TotalGB UsedGB FreeGB UsedPercent Status
----- ------- ------ ------ ----------- ------
C:       100   78.5  21.5        78.5 Warning
D:       500  210.3 289.7        42.1 OK
```

## 分析目录空间占用

找出哪些目录占用空间最多，为清理提供依据。

```powershell
function Get-FolderSize {
    <#
    .SYNOPSIS
    计算指定目录的大小
    .PARAMETER Path
    目录路径
    .PARAMETER Depth
    遍历深度（默认 1）
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [int]$Depth = 1
    )

    if (-not (Test-Path $Path)) {
        Write-Warning "路径不存在：$Path"
        return
    }

    $results = [System.Collections.Generic.List[PSObject]]::new()

    # 计算根目录总大小
    $rootFiles = Get-ChildItem -Path $Path -File -Recurse -Force -ErrorAction SilentlyContinue
    $rootSize = ($rootFiles | Measure-Object -Property Length -Sum).Sum

    # 计算各子目录大小
    $subDirs = Get-ChildItem -Path $Path -Directory -Force -ErrorAction SilentlyContinue

    foreach ($dir in $subDirs) {
        $files = Get-ChildItem -Path $dir.FullName -File -Recurse -Force -ErrorAction SilentlyContinue
        $size = ($files | Measure-Object -Property Length -Sum).Sum
        $fileCount = ($files | Measure-Object).Count

        $results.Add([PSCustomObject]@{
            Folder     = $dir.Name
            SizeMB     = [math]::Round($size / 1MB, 2)
            FileCount  = $fileCount
            FullPath   = $dir.FullName
        })
    }

    # 按大小降序排列
    $results | Sort-Object SizeMB -Descending
}

# 分析常见空间占用目录
$commonPaths = @(
    @{ Name = '临时文件'; Path = $env:TEMP }
    @{ Name = 'Windows 临时'; Path = 'C:\Windows\Temp' }
    @{ Name = '回收站'; Path = 'C:\`$Recycle.Bin' }
    @{ Name = 'Windows 更新'; Path = 'C:\Windows\SoftwareDistribution' }
)

foreach ($item in $commonPaths) {
    Write-Host "`n--- $($item.Name) ---" -ForegroundColor Cyan
    Get-FolderSize -Path $item.Path | Select-Object -First 5 | Format-Table -AutoSize
}
```

执行结果示例：

```text
--- 临时文件 ---

Folder         SizeMB FileCount FullPath
------         ------ --------- --------
Logs            512.3      1245 C:\Users\admin\AppData\Local\Temp\Logs
Cache           256.8       890 C:\Users\admin\AppData\Local\Temp\Cache
Extraction      128.1        45 C:\Users\admin\AppData\Local\Temp\Extraction

--- Windows 临时 ---

Folder         SizeMB FileCount FullPath
------         ------ --------- --------
UpdateStaging   890.5      3200 C:\Windows\Temp\UpdateStaging
InstallCache    345.2       678 C:\Windows\Temp\InstallCache
```

## 清理临时文件

临时文件是最常见的空间占用来源。以下函数可以安全清理各类临时文件。

```powershell
function Remove-TempFiles {
    <#
    .SYNOPSIS
    清理临时文件
    .PARAMETER Path
    要清理的目录路径
    .PARAMETER MaxAge
    文件最大保留天数（默认 7 天）
    .PARAMETER Extensions
    只清理指定扩展名的文件
    .PARAMETER WhatIf
    仅显示将删除的文件，不实际删除
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string[]]$Path,

        [int]$MaxAge = 7,

        [string[]]$Extensions,

        [switch]$Force
    )

    $cutoffDate = (Get-Date).AddDays(-$MaxAge)
    $totalSize = 0
    $totalFiles = 0

    foreach ($targetPath in $Path) {
        if (-not (Test-Path $targetPath)) {
            Write-Verbose "路径不存在，跳过：$targetPath"
            continue
        }

        Write-Verbose "扫描目录：$targetPath"

        $files = Get-ChildItem -Path $targetPath -File -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -lt $cutoffDate }

        if ($Extensions) {
            $files = $files | Where-Object {
                $Extensions -contains $_.Extension.ToLower()
            }
        }

        foreach ($file in $files) {
            $totalSize += $file.Length
            $totalFiles++

            if ($PSCmdlet.ShouldProcess($file.FullName, '删除文件')) {
                try {
                    Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                    Write-Verbose "已删除：$($file.FullName)"
                } catch {
                    Write-Warning "删除失败：$($file.FullName) - $($_.Exception.Message)"
                }
            }
        }
    }

    [PSCustomObject]@{
        FilesDeleted = $totalFiles
        SpaceFreedMB = [math]::Round($totalSize / 1MB, 2)
        SpaceFreedGB = [math]::Round($totalSize / 1GB, 2)
        CutoffDate   = $cutoffDate
    }
}

# 清理 7 天前的临时文件
$result = Remove-TempFiles -Path @(
    $env:TEMP
    'C:\Windows\Temp'
) -MaxAge 7 -Verbose

Write-Host "`n清理结果："
$result | Format-List
```

执行结果示例：

```text
详细: 扫描目录：C:\Users\admin\AppData\Local\Temp
详细: 已删除：C:\Users\admin\AppData\Local\Temp\Logs\app-20250810.log
详细: 已删除：C:\Users\admin\AppData\Local\Temp\Cache\data-20250809.tmp
详细: 扫描目录：C:\Windows\Temp
详细: 已删除：C:\Windows\Temp\UpdateStaging\patch-20250811.cab

清理结果：
FilesDeleted : 2456
SpaceFreedMB : 1024.5
SpaceFreedGB : 1.0
CutoffDate   : 2025/8/13 8:00:00
```

## 清理日志文件

日志文件是另一个重要的空间占用来源，需要按策略进行归档和清理。

```powershell
function Remove-OldLogFiles {
    <#
    .SYNOPSIS
    清理过期的日志文件，可选压缩归档
    .PARAMETER LogPath
    日志目录路径
    .PARAMETER MaxAge
    日志保留天数
    .PARAMETER ArchivePath
    归档目录（设置后将压缩旧日志移至此处而非直接删除）
    .PARAMETER Pattern
    文件匹配模式（默认 *.log）
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$LogPath,

        [int]$MaxAge = 30,

        [string]$ArchivePath,

        [string]$Pattern = '*.log'
    )

    if (-not (Test-Path $LogPath)) {
        throw "日志目录不存在：$LogPath"
    }

    $cutoffDate = (Get-Date).AddDays(-$MaxAge)
    $files = Get-ChildItem -Path $LogPath -Filter $Pattern -File -Force |
        Where-Object { $_.LastWriteTime -lt $cutoffDate }

    $stats = @{
        Archived = 0
        Deleted  = 0
        TotalSizeMB = 0
    }

    foreach ($file in $files) {
        $stats['TotalSizeMB'] += $file.Length / 1MB

        if ($ArchivePath) {
            # 归档模式：压缩后移动
            if (-not (Test-Path $ArchivePath)) {
                New-Item -Path $ArchivePath -ItemType Directory -Force | Out-Null
            }

            $zipName = "$($file.BaseName)-$(Get-Date -Format 'yyyyMMdd').zip"
            $zipPath = Join-Path $ArchivePath $zipName

            if ($PSCmdlet.ShouldProcess($file.FullName, "归档到 $zipPath")) {
                Compress-Archive -Path $file.FullName -DestinationPath $zipPath -Force
                Remove-Item -Path $file.FullName -Force
                $stats['Archived']++
                Write-Verbose "已归档：$($file.Name) -> $zipName"
            }
        } else {
            # 直接删除模式
            if ($PSCmdlet.ShouldProcess($file.FullName, '删除')) {
                Remove-Item -Path $file.FullName -Force
                $stats['Deleted']++
                Write-Verbose "已删除：$($file.Name)"
            }
        }
    }

    [PSCustomObject]@{
        LogPath     = $LogPath
        MaxAge      = $MaxAge
        CutoffDate  = $cutoffDate
        FilesCount  = $files.Count
        Archived    = $stats['Archived']
        Deleted     = $stats['Deleted']
        SizeMB      = [math]::Round($stats['TotalSizeMB'], 2)
    }
}

# 清理 30 天前的 IIS 日志（归档模式）
$logResult = Remove-OldLogFiles `
    -LogPath 'C:\inetpub\logs\LogFiles\W3SVC1' `
    -MaxAge 30 `
    -ArchivePath 'D:\Archive\IISLogs' `
    -Verbose

$logResult | Format-List
```

执行结果示例：

```text
详细: 已归档：u_ex250715.log -> u_ex250715-20250820.zip
详细: 已归档：u_ex250716.log -> u_ex250716-20250820.zip
详细: 已归档：u_ex250717.log -> u_ex250717-20250820.zip

LogPath    : C:\inetpub\logs\LogFiles\W3SVC1
MaxAge     : 30
CutoffDate : 2025/7/21 8:00:00
FilesCount : 15
Archived   : 15
Deleted    : 0
SizeMB     : 2048.5
```

## 清理 Windows 更新缓存和系统文件

Windows 更新下载的文件和系统组件缓存往往占用大量空间。

```powershell
function Remove-WindowsUpdateCache {
    <#
    .SYNOPSIS
    清理 Windows 更新下载缓存
    .PARAMETER WhatIf
    仅显示将执行的操作
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    # 需要停止 Windows Update 服务才能清理
    $wuService = 'wuauserv'

    Write-Verbose "停止 Windows Update 服务..."
    Stop-Service -Name $wuService -Force -ErrorAction SilentlyContinue

    $cachePaths = @(
        'C:\Windows\SoftwareDistribution\Download'
        'C:\Windows\SoftwareDistribution\DataStore'
    )

    $totalFreed = 0

    foreach ($path in $cachePaths) {
        if (Test-Path $path) {
            $files = Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            $size = ($files | Measure-Object -Property Length -Sum).Sum
            $totalFreed += $size

            if ($PSCmdlet.ShouldProcess($path, '清理目录内容')) {
                Get-ChildItem -Path $path -Force |
                    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                Write-Verbose "已清理：$path ($([math]::Round($size / 1MB, 2)) MB)"
            }
        }
    }

    # 重新启动服务
    Write-Verbose "启动 Windows Update 服务..."
    Start-Service -Name $wuService -ErrorAction SilentlyContinue

    [PSCustomObject]@{
        CacheCleaned = $cachePaths
        SpaceFreedMB = [math]::Round($totalFreed / 1MB, 2)
        ServiceState = (Get-Service -Name $wuService).Status
    }
}

# 清理 Windows 更新缓存
$updateResult = Remove-WindowsUpdateCache -Verbose
$updateResult | Format-List
```

执行结果示例：

```text
详细: 停止 Windows Update 服务...
详细: 已清理：C:\Windows\SoftwareDistribution\Download (3456.78 MB)
详细: 已清理：C:\Windows\SoftwareDistribution\DataStore (234.5 MB)
详细: 启动 Windows Update 服务...

CacheCleaned : {C:\Windows\SoftwareDistribution\Download, C:\Windows\SoftwareDistribution\DataStore}
SpaceFreedMB : 3691.28
ServiceState : Running
```

## 综合清理工作流

将各类清理操作整合为一个可定期执行的综合脚本。

```powershell
function Invoke-DiskCleanup {
    <#
    .SYNOPSIS
    执行综合磁盘清理
    .PARAMETER DriveLetter
    目标驱动器盘符
    .PARAMETER TempFileMaxAge
    临时文件保留天数
    .PARAMETER LogFileMaxAge
    日志文件保留天数
    .PARAMETER CleanUpdateCache
    是否清理 Windows 更新缓存
    #>
    [CmdletBinding()]
    param(
        [string]$DriveLetter = 'C',

        [int]$TempFileMaxAge = 7,

        [int]$LogFileMaxAge = 30,

        [switch]$CleanUpdateCache
    )

    Write-Host "===== 磁盘清理开始 =====" -ForegroundColor Cyan
    Write-Host "目标驱动器：$($DriveLetter):"
    Write-Host "执行时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

    # 清理前空间
    $before = Get-DiskSpaceInfo -DriveLetter $DriveLetter
    Write-Host "`n清理前可用空间：$($before.FreeGB) GB" -ForegroundColor Yellow

    $results = [System.Collections.Generic.List[PSObject]]::new()

    # 1. 清理临时文件
    Write-Host "`n[1/4] 清理临时文件..." -ForegroundColor Cyan
    $tempResult = Remove-TempFiles -Path @(
        $env:TEMP
        'C:\Windows\Temp'
    ) -MaxAge $TempFileMaxAge
    $results.Add($tempResult)
    Write-Host "  已删除 $($tempResult.FilesDeleted) 个文件，释放 $($tempResult.SpaceFreedMB) MB"

    # 2. 清理日志文件
    Write-Host "`n[2/4] 清理日志文件..." -ForegroundColor Cyan
    $logPaths = @(
        'C:\inetpub\logs\LogFiles'
        'C:\Windows\Logs'
    )
    foreach ($logPath in $logPaths) {
        if (Test-Path $logPath) {
            $logResult = Remove-OldLogFiles -LogPath $logPath -MaxAge $LogFileMaxAge
            $results.Add($logResult)
            Write-Host "  清理 $logPath - $($logResult.SizeMB) MB"
        }
    }

    # 3. 清空回收站
    Write-Host "`n[3/4] 清空回收站..." -ForegroundColor Cyan
    try {
        Clear-RecycleBin -DriveLetter $DriveLetter -Force -ErrorAction Stop
        Write-Host "  回收站已清空"
    } catch {
        Write-Warning "清空回收站失败：$_"
    }

    # 4. 清理 Windows 更新缓存
    if ($CleanUpdateCache) {
        Write-Host "`n[4/4] 清理 Windows 更新缓存..." -ForegroundColor Cyan
        $wuResult = Remove-WindowsUpdateCache
        $results.Add($wuResult)
        Write-Host "  释放 $($wuResult.SpaceFreedMB) MB"
    } else {
        Write-Host "`n[4/4] 跳过 Windows 更新缓存清理" -ForegroundColor Gray
    }

    # 清理后空间
    $after = Get-DiskSpaceInfo -DriveLetter $DriveLetter
    $freedGB = [math]::Round($after.FreeGB - $before.FreeGB, 2)

    Write-Host "`n===== 清理完成 =====" -ForegroundColor Green
    Write-Host "清理前可用空间：$($before.FreeGB) GB"
    Write-Host "清理后可用空间：$($after.FreeGB) GB"
    Write-Host "释放空间：$freedGB GB" -ForegroundColor Green

    [PSCustomObject]@{
        Drive       = "$($DriveLetter):"
        BeforeGB    = $before.FreeGB
        AfterGB     = $after.FreeGB
        FreedGB     = $freedGB
        Results     = $results
        ExecutedAt  = Get-Date
    }
}

# 执行综合清理
$cleanupReport = Invoke-DiskCleanup -DriveLetter 'C' -TempFileMaxAge 7 -LogFileMaxAge 30 -CleanUpdateCache
```

执行结果示例：

```text
===== 磁盘清理开始 =====
目标驱动器：C:
执行时间：2025-08-20 08:00:00

清理前可用空间：21.5 GB

[1/4] 清理临时文件...
  已删除 2456 个文件，释放 1024.5 MB

[2/4] 清理日志文件...
  清理 C:\inetpub\logs\LogFiles - 2048.5 MB
  清理 C:\Windows\Logs - 128.3 MB

[3/4] 清空回收站...
  回收站已清空

[4/4] 清理 Windows 更新缓存...
  释放 3691.28 MB

===== 清理完成 =====
清理前可用空间：21.5 GB
清理后可用空间：27.27 GB
释放空间：5.77 GB
```

## 注意事项

- **备份优先**：清理前务必备份重要的日志和配置文件，特别是生产环境的 IIS 日志、应用程序日志等，确认不再需要后再清理。
- **文件锁定**：正在使用的文件无法删除，脚本中应使用 `-ErrorAction SilentlyContinue` 跳过这些文件，避免因个别文件锁定导致整个脚本中断。
- **服务依赖**：清理 Windows 更新缓存需要停止 `wuauserv` 服务，如果组织有补丁管理窗口，应在窗口外执行此操作，避免影响正常更新流程。
- **测试先行**：在生产环境运行清理脚本前，先使用 `-WhatIf` 参数进行干运行（dry run），确认清理范围符合预期后再实际执行。
- **定期执行**：建议将清理脚本配置为计划任务，每周或每月自动执行，避免一次性积累过多文件导致清理时间过长。
- **监控告警**：配合磁盘空间监控（如当可用空间低于 20% 时告警），形成"监控-告警-清理"的闭环管理，避免磁盘空间耗尽导致的系统故障。
