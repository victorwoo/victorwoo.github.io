---
layout: post
date: 2026-02-27 08:00:00
updated: 2026-02-27 08:00:00
title: "PowerShell 技能连载 - 懒人运维工具集"
description: PowerTip of the Day - Lazy Admin Toolkit in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- productivity
- toolkit
- automation
- tips
---

_适用于 PowerShell 5.1 及以上版本_

每个系统管理员都有一套自己的"小抄"——那些在日常工作中反复使用的命令和脚本片段。你可能在记事本里存着几十条命令，也可能在浏览器书签栏里堆满了技术博客链接。这些零散的知识虽然有用，但真正遇到问题时，往往要花不少时间才能找到那条"正好管用"的命令。

PowerShell 的强大之处在于，几乎所有的系统管理操作都可以用一行命令或短脚本完成。与其每次都去搜索引擎翻找答案，不如把这些高频操作整理成一个"懒人工具集"——需要什么直接拿来用，省下的时间可以用来喝咖啡或者研究更有趣的技术。

本文收集了系统信息速查、文件管理快捷操作、日常运维一键脚本三大类实用代码片段。每个片段都可以独立运行，也可以根据你的实际需求自由组合。准备好你的终端，让我们开始吧。

<!-- more -->

## 系统信息速查

当你接手一台新服务器或者需要快速排查问题时，第一时间掌握系统全貌至关重要。下面的脚本将硬件信息、系统概况、网络配置和已安装软件汇总到一个报告中，一条命令搞定所有信息采集。

```powershell
function Get-SystemQuickReport {
    <#
    .SYNOPSIS
    一键获取系统综合信息报告
    #>

    $report = @{}

    # 硬件信息
    $report.Hardware = [PSCustomObject]@{
        ComputerName = $env:COMPUTERNAME
        Manufacturer = (Get-CimInstance Win32_ComputerSystem).Manufacturer
        Model        = (Get-CimInstance Win32_ComputerSystem).Model
        TotalRAM_GB  = [math]::Round(
            (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2
        )
        CPU          = (Get-CimInstance Win32_Processor).Name
        CPUCoreCount = (Get-CimInstance Win32_Processor).NumberOfLogicalProcessors
    }

    # 系统概况
    $os = Get-CimInstance Win32_OperatingSystem
    $report.OS = [PSCustomObject]@{
        Caption         = $os.Caption
        Version         = $os.Version
        BuildNumber     = $os.BuildNumber
        LastBootTime    = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
        UptimeDays      = [math]::Round(
            ((Get-Date) - $os.LastBootUpTime).TotalDays, 1
        )
        FreeDiskSpaceGB = [math]::Round(
            (Get-PSDrive -Name C).Free / 1GB, 2
        )
    }

    # 网络配置
    $report.Network = Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object { $_.InterfaceAlias -notmatch 'Loopback' } |
        Select-Object InterfaceAlias, IPAddress, PrefixLength |
        Sort-Object InterfaceAlias

    # 已安装软件（按安装日期倒序取前 10 条）
    $report.RecentSoftware = Get-ItemProperty
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName } |
        Sort-Object InstallDate -Descending |
        Select-Object -First 10 DisplayName, DisplayVersion, InstallDate

    # 输出报告
    Write-Host "`n=== 硬件信息 ===" -ForegroundColor Cyan
    $report.Hardware | Format-List
    Write-Host "=== 系统概况 ===" -ForegroundColor Cyan
    $report.OS | Format-List
    Write-Host "=== 网络配置 ===" -ForegroundColor Cyan
    $report.Network | Format-Table -AutoSize
    Write-Host "=== 最近安装的软件 ===" -ForegroundColor Cyan
    $report.RecentSoftware | Format-Table -AutoSize
}

Get-SystemQuickReport
```

执行后你会看到类似以下输出：

```
=== 硬件信息 ===

ComputerName : WIN-SERVER01
Manufacturer : Dell Inc.
Model        : PowerEdge R740
TotalRAM_GB  : 64
CPU          : Intel(R) Xeon(R) Silver 4210R CPU @ 2.40GHz
CPUCoreCount : 20

=== 系统概况 ===

Caption         : Microsoft Windows Server 2022 Standard
Version         : 10.0.20348
BuildNumber     : 20348
LastBootTime    : 2026/2/20 08:15:32
UptimeDays      : 7.1
FreeDiskSpaceGB : 238.45

=== 网络配置 ===

InterfaceAlias IPAddress       PrefixLength
-------------- ---------        ------------
Ethernet0      192.168.1.100   24
Ethernet1      10.0.0.50       16

=== 最近安装的软件 ===

DisplayName           DisplayVersion InstallDate
-----------           -------------- -----------
PowerShell 7-x64      7.5.0          20260225
Git for Windows       2.48.1         20260220
7-Zip 24.09 (x64)    24.09          20260215
```

这个函数把 `Get-CimInstance`、`Get-NetIPAddress` 和注册表查询组合在一起，省去了你逐条敲命令的麻烦。你也可以把它加入 PowerShell Profile 文件，开机即可使用。

## 文件管理快捷操作

文件管理是运维工作中最频繁的操作之一。无论是磁盘空间告急时查找大文件，还是整理下载目录时批量重命名，掌握几个快捷命令能让你事半功倍。下面的脚本集合了四个常用场景：大文件查找、重复文件检测、批量重命名和目录对比。

```powershell
# --- 场景一：查找占用空间最大的前 20 个文件 ---
function Find-LargeFile {
    param(
        [string]$Path = "C:\",
        [int]$Top = 20,
        [long]$MinSizeMB = 100
    )
    Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Length -ge $MinSizeMB * 1MB } |
        Sort-Object Length -Descending |
        Select-Object -First $Top |
        ForEach-Object {
            [PSCustomObject]@{
                SizeMB    = [math]::Round($_.Length / 1MB, 2)
                FullName  = $_.FullName
                LastWrite = $_.LastWriteTime
            }
        } | Format-Table -AutoSize
}

# --- 场景二：按文件大小检测可能的重复文件 ---
function Find-DuplicateFile {
    param([string]$Path = ".")
    Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue |
        Group-Object Length |
        Where-Object { $_.Count -gt 1 } |
        ForEach-Object {
            $hashes = $_.Group | Get-FileHash -Algorithm MD5 |
                Group-Object Hash |
                Where-Object { $_.Count -gt 1 }
            foreach ($h in $hashes) {
                $h.Group | Select-Object Path,
                    @{ N = 'SizeMB'; E = { [math]::Round(
                        (Get-Item $_.Path).Length / 1MB, 2
                    ) } }
            }
        } | Format-Table -AutoSize
}

# --- 场景三：批量重命名（示例：给文件名加日期前缀） ---
function Rename-AddDatePrefix {
    param(
        [string]$Path = ".",
        [string]$Filter = "*.*"
    )
    $dateStr = Get-Date -Format "yyyyMMdd"
    $files = Get-ChildItem -Path $Path -Filter $Filter -File
    foreach ($f in $files) {
        if ($f.Name -notmatch "^\d{8}-") {
            $newName = "${dateStr}-$($f.Name)"
            Rename-Item -Path $f.FullName -NewName $newName -WhatIf
        }
    }
    Write-Host "共找到 $($files.Count) 个文件，以上为预览结果（-WhatIf）。"
    Write-Host "确认无误后去掉 -WhatIf 参数重新执行。"
}

# --- 场景四：对比两个目录的差异 ---
function Compare-Folder {
    param(
        [Parameter(Mandatory)]
        [string]$Left,
        [Parameter(Mandatory)]
        [string]$Right
    )
    $leftFiles  = Get-ChildItem $Left  -Recurse -File |
        ForEach-Object { $_.FullName.Replace($Left, "") }
    $rightFiles = Get-ChildItem $Right -Recurse -File |
        ForEach-Object { $_.FullName.Replace($Right, "") }

    $onlyInLeft  = Compare-Object $leftFiles $rightFiles |
        Where-Object SideIndicator -eq "<=" |
        ForEach-Object { [PSCustomObject]@{ Location = "仅左目录"; File = $_.InputObject } }
    $onlyInRight = Compare-Object $leftFiles $rightFiles |
        Where-Object SideIndicator -eq "=>" |
        ForEach-Object { [PSCustomObject]@{ Location = "仅右目录"; File = $_.InputObject } }

    $onlyInLeft + $onlyInRight | Format-Table -AutoSize
}

# 使用示例
Find-LargeFile -Path "D:\" -Top 10 -MinSizeMB 200
```

以下是各场景的执行结果示例：

```
SizeMB   FullName                                   LastWrite
------   --------                                   ---------
4096.00  D:\VM\Ubuntu-24.04.vhdx                    2026/2/26 14:30:00
2048.00  D:\Backup\db-full-20260225.bak              2026/2/25 03:00:00
 812.50  D:\Logs\iis-access-202602.log               2026/2/27 09:15:00
 512.00  D:\ISO\windows-server-2022.iso              2025/12/10 10:00:00
 300.75  D:\Temp\update-package-large.cab            2026/2/20 16:45:00
```

每个函数都设计为可以独立使用。`Find-LargeFile` 用于快速定位空间杀手，`Find-DuplicateFile` 通过文件大小和哈希值双重比对来发现重复文件，`Rename-AddDatePrefix` 默认带 `-WhatIf` 参数以防止误操作，`Compare-Folder` 则用 `Compare-Object` 一行搞定目录差异对比。

## 日常运维一键脚本

日常运维中最常见的操作莫过于磁盘清理、服务状态检查、日志分析和快速诊断。这些操作单独来看都不复杂，但每天重复执行就很繁琐。下面的脚本把四类常见操作封装成可复用的函数，你可以按需调用或组合使用。

```powershell
# --- 操作一：磁盘空间清理 ---
function Invoke-DiskCleanup {
    $before = [math]::Round((Get-PSDrive C).Free / 1GB, 2)
    Write-Host "清理前 C 盘剩余空间: ${before} GB" -ForegroundColor Yellow

    # 清理临时文件
    $tempPaths = @(
        $env:TEMP
        "$env:WINDIR\Temp"
        "$env:WINDIR\SoftwareDistribution\Download"
    )
    $cleanedCount = 0
    foreach ($p in $tempPaths) {
        if (Test-Path $p) {
            Get-ChildItem $p -Recurse -ErrorAction SilentlyContinue |
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            $cleanedCount++
        }
    }

    # 清理事件日志中超过 30 天的存档
    $cutoff = (Get-Date).AddDays(-30)
    Get-ChildItem "$env:WINDIR\System32\winevt\Logs\Archive" -Filter "*.evtx" `
        -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt $cutoff } |
        Remove-Item -Force -ErrorAction SilentlyContinue

    $after = [math]::Round((Get-PSDrive C).Free / 1GB, 2)
    $freed = [math]::Round($after - $before, 2)
    Write-Host "清理后 C 盘剩余空间: ${after} GB" -ForegroundColor Green
    Write-Host "本次释放空间: ${freed} GB" -ForegroundColor Cyan
}

# --- 操作二：关键服务状态巡检 ---
function Test-CriticalServices {
    param(
        [string[]]$ServiceNames = @(
            "WinRM", "EventLog", "DHCP", "DNS",
            "LanmanServer", "LanmanWorkstation"
        )
    )
    $results = foreach ($svc in $ServiceNames) {
        $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if ($s) {
            [PSCustomObject]@{
                Service = $s.Name
                Status  = $s.Status
                StartType = $s.StartType
                OK      = if ($s.Status -eq 'Running') { "OK" } else { "WARN" }
            }
        } else {
            [PSCustomObject]@{
                Service = $svc; Status = "NOT_FOUND"
                StartType = "-"; OK = "ERROR"
            }
        }
    }
    $results | Format-Table -AutoSize
    $warnCount = ($results | Where-Object { $_.OK -ne "OK" }).Count
    if ($warnCount -gt 0) {
        Write-Host "发现 $warnCount 个异常服务!" -ForegroundColor Red
    } else {
        Write-Host "所有关键服务运行正常。" -ForegroundColor Green
    }
}

# --- 操作三：日志关键词搜索 ---
function Search-EventLogFast {
    param(
        [string]$LogName = "System",
        [string]$Keyword = "error",
        [int]$Hours = 24
    )
    $startTime = (Get-Date).AddHours(-$Hours)
    Get-WinEvent -LogName $LogName -ErrorAction SilentlyContinue |
        Where-Object {
            $_.TimeCreated -ge $startTime -and
            $_.Message -match $Keyword
        } |
        Select-Object -First 20 TimeCreated, Id, LevelDisplayName,
            @{ N = 'Message'; E = { $_.Message.Substring(0,
                [math]::Min($_.Message.Length, 120)) } } |
        Format-Table -AutoSize -Wrap
}

# --- 操作四：快速系统诊断 ---
function Get-QuickDiagnosis {
    Write-Host "`n[CPU 使用率]" -ForegroundColor Cyan
    $cpu = (Get-CimInstance Win32_Processor).LoadPercentage
    Write-Host "  当前 CPU: ${cpu}%"
    if ($cpu -gt 80) {
        Write-Host "  警告: CPU 使用率过高!" -ForegroundColor Red
    }

    Write-Host "`n[内存使用]" -ForegroundColor Cyan
    $os = Get-CimInstance Win32_OperatingSystem
    $totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $freeGB  = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $usedPct = [math]::Round(($totalGB - $freeGB) / $totalGB * 100, 1)
    Write-Host "  总内存: ${totalGB} GB | 可用: ${freeGB} GB | 使用率: ${usedPct}%"
    if ($usedPct -gt 90) {
        Write-Host "  警告: 内存使用率过高!" -ForegroundColor Red
    }

    Write-Host "`n[磁盘空间]" -ForegroundColor Cyan
    Get-PSDrive -PSProvider FileSystem |
        ForEach-Object {
            $freeGB  = [math]::Round($_.Free / 1GB, 2)
            $usedGB  = [math]::Round(($_.Used) / 1GB, 2)
            $totalGB = [math]::Round(($_.Used + $_.Free) / 1GB, 2)
            $pct     = [math]::Round($_.Used / ($_.Used + $_.Free) * 100, 1)
            Write-Host "  盘符 $($_.Name): 已用 ${usedGB}/${totalGB} GB (${pct}%)"
            if ($pct -gt 90) {
                Write-Host "    警告: 磁盘空间不足!" -ForegroundColor Red
            }
        }

    Write-Host "`n[Top 5 进程 (按内存)]" -ForegroundColor Cyan
    Get-Process | Sort-Object WorkingSet64 -Descending |
        Select-Object -First 5 |
        ForEach-Object {
            $memMB = [math]::Round($_.WorkingSet64 / 1MB, 1)
            Write-Host "  $($_.Name) (PID: $($_.Id)): ${memMB} MB"
        }
}

# 执行诊断
Get-QuickDiagnosis
```

执行结果示例如下：

```
[CPU 使用率]
  当前 CPU: 23%

[内存使用]
  总内存: 64 GB | 可用: 28.5 GB | 使用率: 55.5%

[磁盘空间]
  盘符 C: 已用 261.55/500 GB (52.3%)
  盘符 D: 已用 1200.8/2000 GB (60.0%)

[Top 5 进程 (按内存)]
  sqlservr (PID: 1842): 8192.0 MB
  java (PID: 3201): 4096.0 MB
  MsMpEng (PID: 882): 512.3 MB
  powershell (PID: 9156): 256.8 MB
  svchost (PID: 1044): 198.4 MB
```

这组函数覆盖了运维中最常见的四类操作。`Invoke-DiskCleanup` 在清理前后显示释放的空间大小，让你对清理效果一目了然；`Test-CriticalServices` 支持自定义服务列表，默认检查六个核心 Windows 服务；`Search-EventLogFast` 使用管道快速过滤事件日志，避免全量加载导致内存占用过大；`Get-QuickDiagnosis` 将 CPU、内存、磁盘和进程信息汇总输出，超过阈值时会自动标红警告。

## 注意事项

- **谨慎使用清理脚本**：`Invoke-DiskCleanup` 会删除临时文件和旧日志，生产环境执行前建议先注释掉 `Remove-Item` 语句，用 `-WhatIf` 模式预览清理范围，确认无误后再实际执行。

- **服务巡检可扩展**：`Test-CriticalServices` 的默认服务列表针对 Windows 服务器场景。如果你管理的是 Web 服务器，可以将 `W3SVC`、`WAS` 加入列表；数据库服务器则加入 `MSSQLSERVER`、`SQLSERVERAGENT` 等服务。

- **大文件搜索性能优化**：在搜索超大目录（如整个 C 盘）时，`Find-LargeFile` 可能需要较长时间。建议通过 `-MinSizeMB` 参数过滤掉小文件以提升速度，或者限定搜索路径范围而非搜索整个磁盘。

- **重复文件检测的边界**：`Find-DuplicateFile` 使用 MD5 哈希进行比对。对于非常大的文件集合，哈希计算可能耗时较长。在实际使用中，可以先按文件大小分组（脚本已实现），再仅对大小相同的文件计算哈希，可以大幅减少计算量。

- **目录对比的路径处理**：`Compare-Folder` 使用字符串替换来计算相对路径。如果左右目录路径中包含特殊字符或符号链接，可能导致比对结果不准确。对于复杂的目录结构，建议使用专业的文件同步工具如 `robocopy` 的对比模式。

- **函数加入 Profile 实现开机可用**：本文所有函数都可以复制到你的 PowerShell Profile 文件（路径为 `$PROFILE`，通常在 `Documents\PowerShell\Microsoft.PowerShell_profile.ps1`）中，这样每次打开终端就能直接调用，真正实现"一次编写，到处偷懒"。
