---
layout: post
date: 2025-09-17 08:00:00
title: "PowerShell 技能连载 - 跨平台文件同步"
description: PowerTip of the Day - Cross-Platform File Synchronization in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- file-sync
- robocopy
- rsync
---

_适用于 PowerShell 7.0 及以上版本（跨平台）_

在现代运维和开发场景中，文件同步是一项极为常见的需求。无论你是要在开发机和服务器之间同步配置文件，还是需要将日志目录定期备份到远程存储，一个可靠的同步脚本都能大幅提升工作效率。传统方案中，Windows 用户习惯使用 Robocopy，而 Linux/macOS 用户则依赖 rsync，两者各有优势但互不兼容。

PowerShell 7 的跨平台特性为统一文件同步方案提供了可能。通过编写一次脚本，我们可以在 Windows、Linux 和 macOS 上使用相同的逻辑完成文件同步任务。本文将介绍如何利用 PowerShell 构建一套跨平台的文件同步工具，涵盖本地目录镜像、增量同步以及基于校验和的完整性验证等核心场景。

## 基础目录镜像同步

首先实现一个基础的目录镜像同步函数。该函数会比较源目录和目标目录中的文件，将源目录中新增或修改过的文件复制到目标目录。我们通过比较文件的 `LastWriteTime` 属性来判断是否需要更新。

```powershell
function Invoke-DirectoryMirror {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SourcePath,

        [Parameter(Mandatory)]
        [string]$DestinationPath,

        [switch]$WhatIf
    )

    if (-not (Test-Path -Path $SourcePath)) {
        throw "源目录不存在: $SourcePath"
    }

    if (-not (Test-Path -Path $DestinationPath)) {
        New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null
        Write-Host "已创建目标目录: $DestinationPath"
    }

    $sourceFiles = Get-ChildItem -Path $SourcePath -Recurse -File
    $copiedCount = 0
    $skippedCount = 0

    foreach ($file in $sourceFiles) {
        $relativePath = $file.FullName.Substring($SourcePath.Length).TrimStart([System.IO.Path]::DirectorySeparatorChar)
        $destFile = Join-Path -Path $DestinationPath -ChildPath $relativePath
        $destDir = Split-Path -Path $destFile -Parent

        if (-not (Test-Path -Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }

        $needCopy = $false
        if (-not (Test-Path -Path $destFile)) {
            $needCopy = $true
        } else {
            $destInfo = Get-Item -Path $destFile
            if ($file.LastWriteTimeUtc -gt $destInfo.LastWriteTimeUtc) {
                $needCopy = $true
            }
        }

        if ($needCopy) {
            if ($WhatIf) {
                Write-Host "[WhatIf] 将复制: $relativePath"
            } else {
                Copy-Item -Path $file.FullName -Destination $destFile -Force
                Write-Host "已复制: $relativePath"
            }
            $copiedCount++
        } else {
            $skippedCount++
        }
    }

    Write-Host "`n同步完成: 复制 $copiedCount 个文件, 跳过 $skippedCount 个文件"
}
```

执行结果示例：

```
已创建目标目录: /home/user/backup/project
已复制: config/appsettings.json
已复制: src/main.ps1
已复制: modules/utils.psm1

同步完成: 复制 3 个文件, 跳过 12 个文件
```

## 带校验和验证的增量同步

基础的 `LastWriteTime` 比较在大多数情况下工作良好，但如果文件在传输过程中被意外修改，或者文件的修改时间被人为篡改，单纯依赖时间戳就不够可靠了。下面的函数引入了 SHA256 校验和比对，确保同步后的文件与源文件在内容上完全一致。

```powershell
function Invoke-ChecksumSync {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SourcePath,

        [Parameter(Mandatory)]
        [string]$DestinationPath,

        [switch]$VerifyOnly,

        [switch]$DeleteOrphans
    )

    $sourceFiles = Get-ChildItem -Path $SourcePath -Recurse -File
    $results = [System.Collections.Generic.List[PSObject]]::new()

    foreach ($file in $sourceFiles) {
        $relativePath = $file.FullName.Substring($SourcePath.Length).TrimStart([System.IO.Path]::DirectorySeparatorChar)
        $destFile = Join-Path -Path $DestinationPath -ChildPath $relativePath

        $sourceHash = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash

        if (Test-Path -Path $destFile) {
            $destHash = (Get-FileHash -Path $destFile -Algorithm SHA256).Hash

            if ($sourceHash -eq $destHash) {
                $status = "Match"
            } else {
                $status = "Mismatch"
                if (-not $VerifyOnly) {
                    Copy-Item -Path $file.FullName -Destination $destFile -Force
                    $status = "Updated"
                }
            }
        } else {
            $status = "Missing"
            if (-not $VerifyOnly) {
                $destDir = Split-Path -Path $destFile -Parent
                if (-not (Test-Path -Path $destDir)) {
                    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                }
                Copy-Item -Path $file.FullName -Destination $destFile -Force
                $status = "Created"
            }
        }

        $results.Add([PSCustomObject]@{
            File   = $relativePath
            Status = $status
            Size   = $file.Length
        })
    }

    if ($DeleteOrphans) {
        $destFiles = Get-ChildItem -Path $DestinationPath -Recurse -File
        foreach ($dFile in $destFiles) {
            $relativePath = $dFile.FullName.Substring($DestinationPath.Length).TrimStart([System.IO.Path]::DirectorySeparatorChar)
            $sourceFile = Join-Path -Path $SourcePath -ChildPath $relativePath
            if (-not (Test-Path -Path $sourceFile)) {
                Remove-Item -Path $dFile.FullName -Force
                Write-Host "已删除孤立文件: $relativePath"
            }
        }
    }

    $results | Format-Table -AutoSize
    return $results
}
```

执行结果示例：

```
File                  Status    Size
----                  ------    ----
config/settings.json  Match      2048
data/cache.dat        Updated  524288
logs/app.log          Created   10240
scripts/deploy.ps1    Match       512
README.md             Mismatch  4096
```

## 平台自适应的同步调度器

在实际运维中，我们往往需要定时执行同步任务。下面的脚本展示了如何创建一个跨平台的同步调度器，它会根据当前操作系统选择最适合的底层工具：在 Windows 上调用 Robocopy 以获得最优性能，在 Linux/macOS 上则使用原生 PowerShell 文件操作。

```powershell
function Start-SyncScheduler {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SourcePath,

        [Parameter(Mandatory)]
        [string]$DestinationPath,

        [ValidateRange(1, 1440)]
        [int]$IntervalMinutes = 30,

        [int]$MaxRetries = 3,

        [int]$RetryDelaySeconds = 10
    )

    $syncCount = 0

    Write-Host "同步调度器已启动"
    Write-Host "源目录: $SourcePath"
    Write-Host "目标目录: $DestinationPath"
    Write-Host "同步间隔: $IntervalMinutes 分钟"
    Write-Host "平台: $($PSVersionTable.OS)"
    Write-Host ("按 Ctrl+C 停止`n")

    try {
        while ($true) {
            $syncCount++
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Write-Host "[$timestamp] 第 $syncCount 次同步开始..."

            $attempt = 0
            $success = $false

            while ($attempt -lt $MaxRetries -and -not $success) {
                $attempt++

                try {
                    if ($IsWindows -or $env:OS -eq "Windows_NT") {
                        # Windows 平台使用 Robocopy
                        $robocopyArgs = @(
                            $SourcePath,
                            $DestinationPath,
                            "/MIR",
                            "/Z",
                            "/NP",
                            "/R:1",
                            "/W:1"
                        )
                        $proc = Start-Process -FilePath "robocopy.exe" -ArgumentList $robocopyArgs -NoNewWindow -PassThru
                        $proc.WaitForExit()

                        # Robocopy 返回码 0-7 均视为成功
                        if ($proc.ExitCode -le 7) {
                            $success = $true
                            Write-Host "  Robocopy 同步成功 (退出码: $($proc.ExitCode))"
                        } else {
                            Write-Host "  Robocopy 返回异常退出码: $($proc.ExitCode)"
                        }
                    } else {
                        # Linux/macOS 使用 PowerShell 原生操作
                        Invoke-DirectoryMirror -SourcePath $SourcePath -DestinationPath $DestinationPath
                        $success = $true
                        Write-Host "  PowerShell 原生同步成功"
                    }
                } catch {
                    Write-Host "  第 $attempt 次尝试失败: $($_.Exception.Message)"
                    if ($attempt -lt $MaxRetries) {
                        Write-Host "  等待 $RetryDelaySeconds 秒后重试..."
                        Start-Sleep -Seconds $RetryDelaySeconds
                    }
                }
            }

            if ($success) {
                Write-Host "[$timestamp] 同步完成`n"
            } else {
                Write-Host "[$timestamp] 同步失败，已达最大重试次数`n"
            }

            Start-Sleep -Seconds ($IntervalMinutes * 60)
        }
    } finally {
        Write-Host "同步调度器已停止，共执行 $syncCount 次同步"
    }
}
```

执行结果示例：

```
同步调度器已启动
源目录: C:\Projects\myapp
目标目录: D:\Backup\myapp
同步间隔: 30 分钟
平台: Microsoft Windows 10.0.22631
按 Ctrl+C 停止

[2025-09-17 10:00:00] 第 1 次同步开始...
  Robocopy 同步成功 (退出码: 1)
[2025-09-17 10:00:00] 同步完成

[2025-09-17 10:30:00] 第 2 次同步开始...
  Robocopy 同步成功 (退出码: 0)
[2025-09-17 10:30:00] 同步完成
```

## 同步结果报告生成

完成同步后，生成一份结构化的报告可以帮助运维人员快速了解同步状态。下面的函数将同步过程中的文件变更信息汇总为报告，支持输出到控制台或保存为文件。

```powershell
function New-SyncReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SourcePath,

        [Parameter(Mandatory)]
        [string]$DestinationPath,

        [string]$OutputPath
    )

    $reportTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $sourceInfo = Get-ChildItem -Path $SourcePath -Recurse -File
    $destInfo = Get-ChildItem -Path $DestinationPath -Recurse -File -ErrorAction SilentlyContinue

    $totalSourceFiles = $sourceInfo.Count
    $totalSourceSize = ($sourceInfo | Measure-Object -Property Length -Sum).Sum
    $totalDestFiles = if ($destInfo) { $destInfo.Count } else { 0 }

    $missingFiles = [System.Collections.Generic.List[string]]::new()
    $sizeMismatch = [System.Collections.Generic.List[string]]::new()

    foreach ($sFile in $sourceInfo) {
        $relativePath = $sFile.FullName.Substring($SourcePath.Length).TrimStart([System.IO.Path]::DirectorySeparatorChar)
        $destFile = Join-Path -Path $DestinationPath -ChildPath $relativePath

        if (-not (Test-Path -Path $destFile)) {
            $missingFiles.Add($relativePath)
        } else {
            $dFile = Get-Item -Path $destFile
            if ($sFile.Length -ne $dFile.Length) {
                $sizeMismatch.Add($relativePath)
            }
        }
    }

    $report = @(
        "=== 文件同步报告 ==="
        "报告时间: $reportTime"
        ""
        "源目录: $SourcePath"
        "目标目录: $DestinationPath"
        ""
        "--- 文件统计 ---"
        "源目录文件数: $totalSourceFiles"
        "源目录总大小: $([math]::Round($totalSourceSize / 1MB, 2)) MB"
        "目标目录文件数: $totalDestFiles"
        ""
        "--- 同步状态 ---"
        "缺失文件数: $($missingFiles.Count)"
        "大小不一致数: $($sizeMismatch.Count)"
        "同步覆盖率: $([math]::Round(($totalSourceFiles - $missingFiles.Count) / $totalSourceFiles * 100, 1))%"
    )

    if ($missingFiles.Count -gt 0) {
        $report += ""
        $report += "--- 缺失文件列表 ---"
        foreach ($mf in $missingFiles) {
            $report += "  [缺失] $mf"
        }
    }

    if ($sizeMismatch.Count -gt 0) {
        $report += ""
        $report += "--- 大小不一致文件 ---"
        foreach ($sm in $sizeMismatch) {
            $report += "  [不一致] $sm"
        }
    }

    $reportLine = $report -join "`n"

    if ($OutputPath) {
        $report | Out-File -FilePath $OutputPath -Encoding utf8 -Force
        Write-Host "报告已保存到: $OutputPath"
    }

    Write-Host $reportLine
}
```

执行结果示例：

```
=== 文件同步报告 ===
报告时间: 2025-09-17 14:30:00

源目录: C:\Projects\myapp
目标目录: D:\Backup\myapp

--- 文件统计 ---
源目录文件数: 156
源目录总大小: 42.37 MB
目标目录文件数: 154

--- 同步状态 ---
缺失文件数: 2
大小不一致数: 1
同步覆盖率: 98.7%

--- 缺失文件列表 ---
  [缺失] logs/error-2025-09-17.log
  [缺失] temp/cache.tmp

--- 大小不一致文件 ---
  [不一致] config/appsettings.json
```

## 注意事项

1. **路径分隔符兼容性**：PowerShell 7 在不同操作系统上使用不同的路径分隔符。编写跨平台脚本时，应始终使用 `Join-Path` 和 `Split-Path` 代替硬编码的 `\` 或 `/`，确保路径在 Windows、Linux 和 macOS 上都能正确解析。

2. **Robocopy 退出码语义**：Robocopy 的退出码并非标准意义上的 0 表示成功。返回码 0 到 7 均为正常（0 表示无变化，1 表示文件已复制，2 表示存在额外文件等），只有 8 及以上才表示错误。在脚本中务必正确处理这一特性，避免误判同步失败。

3. **大文件同步的性能考量**：对大文件进行 SHA256 校验和计算可能非常耗时。对于 GB 级别的文件，建议先比较文件大小和修改时间，只有在两者不一致时才计算校验和，这样可以显著减少不必要的哈希计算开销。

4. **文件锁定与并发访问**：同步过程中如果源文件正被其他进程写入，可能导致复制不完整或校验失败。建议在同步关键数据时先检查文件是否被锁定，或使用文件系统的卷影复制（VSS）功能（仅 Windows）来获取一致性的文件快照。

5. **符号链接处理**：`Get-ChildItem` 默认不会跟随符号链接。如果同步目录中包含符号链接，需要根据场景决定是复制链接本身还是复制链接指向的实际文件。可以结合 `-FollowSymlink` 参数（PowerShell 7.4+）来控制这一行为。

6. **定时任务的跨平台实现**：在 Windows 上可以通过 `Register-ScheduledTask` 创建计划任务，在 Linux 上可以使用 cron，macOS 则使用 launchd。建议将同步调度器封装为脚本文件，然后通过各平台原生的定时机制来调用，而不是依赖脚本内部的 `Start-Sleep` 循环，这样更稳定也更易于管理。
