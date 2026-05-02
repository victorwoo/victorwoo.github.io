---
layout: post
date: 2025-07-17 08:00:00
updated: 2025-07-17 08:00:00
title: "PowerShell 技能连载 - 压缩与归档操作"
description: PowerTip of the Day - Compression and Archive Operations in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- compression
- archive
- zip
- backup
---

_适用于 PowerShell 5.1 及以上版本_

压缩和归档是运维中的高频操作——日志归档、配置备份、发布包分发、数据迁移。PowerShell 5.0 引入了 `Compress-Archive` 和 `Expand-Archive` 命令，让压缩操作无需依赖第三方工具。对于更高级的需求（如加密压缩、分卷压缩、tar.gz），可以通过 .NET 类实现。

本文将讲解 PowerShell 中的压缩与归档操作，涵盖日常备份和高级场景。

## ZIP 基础操作

```powershell
# 创建 ZIP 压缩包
$logFiles = Get-ChildItem "C:\Logs" -Filter "*.log" -Recurse |
    Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-7) }

Compress-Archive -Path $logFiles.FullName -DestinationPath "C:\Backup\logs-$(Get-Date -Format 'yyyyMMdd').zip" -Force
Write-Host "已压缩 $($logFiles.Count) 个日志文件" -ForegroundColor Green

# 解压 ZIP 文件
Expand-Archive -Path "C:\Backup\logs-20250717.zip" -DestinationPath "C:\Temp\extracted-logs" -Force
Write-Host "已解压到 C:\Temp\extracted-logs" -ForegroundColor Green

# 追加文件到现有 ZIP
Compress-Archive -Path "C:\Logs\today.log" -Update -DestinationPath "C:\Backup\logs-20250717.zip"
Write-Host "已追加文件到压缩包" -ForegroundColor Green

# 列出 ZIP 内容
$zip = [System.IO.Compression.ZipFile]::OpenRead("C:\Backup\logs-20250717.zip")
Write-Host "ZIP 内容（$($zip.Entries.Count) 个文件）：" -ForegroundColor Cyan
$zip.Entries | Select-Object FullName, Length, LastWriteTime |
    Format-Table -AutoSize
$zip.Dispose()

# 批量压缩
$dirs = Get-ChildItem "C:\Projects" -Directory
foreach ($dir in $dirs) {
    $zipPath = "C:\Backup\projects\$($dir.Name).zip"
    Compress-Archive -Path $dir.FullName -DestinationPath $zipPath -Force
    $size = [math]::Round((Get-Item $zipPath).Length / 1MB, 2)
    Write-Host "已压缩：$($dir.Name) => $size MB" -ForegroundColor Green
}
```

执行结果示例：

```
已压缩 15 个日志文件
已解压到 C:\Temp\extracted-logs
已追加文件到压缩包
ZIP 内容（16 个文件）：
FullName                             Length        LastWriteTime
--------                             ------        -------------
app-20250711.log                     125678 2025-07-11 23:59:00
app-20250712.log                     234567 2025-07-12 23:59:00
app-20250717.log                      45678 2025-07-17 08:30:00

已压缩：ProjectA => 12.35 MB
已压缩：ProjectB => 8.72 MB
已压缩：ProjectC => 25.18 MB
```

## 高级 ZIP 操作

```powershell
# 使用 .NET 类实现更精细的控制
Add-Type -AssemblyName System.IO.Compression.FileSystem

function New-ZipFromDirectory {
    param(
        [Parameter(Mandatory)][string]$SourcePath,
        [Parameter(Mandatory)][string]$ZipPath,
        [string[]]$ExcludePatterns = @("*.log", "*.tmp", ".git"),
        [int]$CompressionLevel = 0  # 0=Fastest, 1=Optimal
    )

    $level = [System.IO.Compression.CompressionLevel]::Optimal

    if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }

    $zip = [System.IO.Compression.ZipFile]::Open($ZipPath, 'Create')

    try {
        $files = Get-ChildItem $SourcePath -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object {
                $file = $_
                $exclude = $false
                foreach ($pattern in $ExcludePatterns) {
                    if ($file.FullName -like "*$pattern*") {
                        $exclude = $true
                        break
                    }
                }
                -not $exclude
            }

        foreach ($file in $files) {
            $relativePath = $file.FullName.Substring($SourcePath.Length).TrimStart('\', '/')
            $entry = $zip.CreateEntry($relativePath, $level)

            $writer = $entry.Open()
            $reader = [System.IO.File]::OpenRead($file.FullName)
            $reader.CopyTo($writer)
            $reader.Close()
            $writer.Close()
        }

        Write-Host "已创建 ZIP：$ZipPath ($($files.Count) 个文件)" -ForegroundColor Green
    } finally {
        $zip.Dispose()
    }
}

New-ZipFromDirectory -SourcePath "C:\MyApp" -ZipPath "C:\Releases\MyApp-v2.5.zip" `
    -ExcludePatterns @(".git", "node_modules", "*.log", "*.tmp")

# 从 ZIP 中读取单个文件（不解压全部）
function Get-ZipFileContent {
    param(
        [Parameter(Mandatory)][string]$ZipPath,
        [Parameter(Mandatory)][string]$FileName
    )

    $zip = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
    try {
        $entry = $zip.Entries | Where-Object { $_.FullName -eq $FileName -or $_.Name -eq $FileName }
        if ($entry) {
            $reader = [System.IO.StreamReader]::new($entry.Open())
            $content = $reader.ReadToEnd()
            $reader.Close()
            return $content
        } else {
            Write-Host "文件未找到：$FileName" -ForegroundColor Yellow
            return $null
        }
    } finally {
        $zip.Dispose()
    }
}

# 读取 ZIP 中的配置文件
$config = Get-ZipFileContent -ZipPath "C:\Releases\MyApp-v2.5.zip" -FileName "appsettings.json"
if ($config) {
    Write-Host "配置文件内容：" -ForegroundColor Cyan
    Write-Host $config
}
```

执行结果示例：

```
已创建 ZIP：C:\Releases\MyApp-v2.5.zip (245 个文件)
配置文件内容：
{
  "AppName": "MyApp",
  "Version": "2.5.0",
  "Port": 8080
}
```

## 日志自动归档

```powershell
function Archive-OldLogs {
    <#
    .SYNOPSIS
    自动归档旧日志文件
    #>
    param(
        [string]$LogPath = "C:\Logs",
        [string]$ArchivePath = "C:\Logs\Archive",
        [int]$ArchiveAfterDays = 30,
        [int]$DeleteAfterDays = 180,
        [switch]$WhatIf
    )

    $archiveDate = (Get-Date).AddDays(-$ArchiveAfterDays)
    $deleteDate = (Get-Date).AddDays(-$DeleteAfterDays)

    New-Item $ArchivePath -ItemType Directory -Force | Out-Null

    # 查找需要归档的日志文件
    $oldLogs = Get-ChildItem $LogPath -Filter "*.log" -File |
        Where-Object { $_.LastWriteTime -lt $archiveDate }

    if (-not $oldLogs) {
        Write-Host "没有需要归档的日志文件" -ForegroundColor Green
        return
    }

    Write-Host "找到 $($oldLogs.Count) 个需要归档的日志文件" -ForegroundColor Cyan

    # 按月份分组归档
    $grouped = $oldLogs | Group-Object { $_.LastWriteTime.ToString("yyyy-MM") }

    foreach ($group in $grouped) {
        $month = $group.Name
        $zipFile = Join-Path $ArchivePath "logs-$month.zip"

        $totalSize = ($group.Group | Measure-Object Length -Sum).Sum
        $sizeMB = [math]::Round($totalSize / 1MB, 2)

        if ($WhatIf) {
            Write-Host "[WhatIf] 归档 $($group.Count) 个文件 ($sizeMB MB) => $zipFile" -ForegroundColor Yellow
        } else {
            if (Test-Path $zipFile) {
                Compress-Archive -Path $group.Group.FullName -Update -DestinationPath $zipFile
            } else {
                Compress-Archive -Path $group.Group.FullName -DestinationPath $zipFile
            }
            Write-Host "已归档 $month ：$($group.Count) 个文件 ($sizeMB MB)" -ForegroundColor Green

            # 归档成功后删除原文件
            $group.Group | Remove-Item -Force
        }
    }

    # 清理过期的归档文件
    $expiredArchives = Get-ChildItem $ArchivePath -Filter "*.zip" |
        Where-Object { $_.LastWriteTime -lt $deleteDate }

    if ($expiredArchives) {
        Write-Host "发现 $($expiredArchives.Count) 个过期归档（>$DeleteAfterDays 天）" -ForegroundColor Yellow

        foreach ($archive in $expiredArchives) {
            if ($WhatIf) {
                Write-Host "[WhatIf] 删除过期归档：$($archive.Name)" -ForegroundColor Yellow
            } else {
                Remove-Item $archive.FullName -Force
                Write-Host "已删除过期归档：$($archive.Name)" -ForegroundColor DarkGray
            }
        }
    }

    Write-Host "`n归档统计：" -ForegroundColor Cyan
    $archiveSize = [math]::Round((Get-ChildItem $ArchivePath -Filter "*.zip" | Measure-Object Length -Sum).Sum / 1MB, 2)
    Write-Host "  归档目录大小：$archiveSize MB"
    Write-Host "  归档文件数：$((Get-ChildItem $ArchivePath -Filter '*.zip').Count)"
}

Archive-OldLogs -LogPath "C:\Logs" -ArchiveAfterDays 30 -DeleteAfterDays 180
```

执行结果示例：

```
找到 45 个需要归档的日志文件
已归档 2025-05 ：18 个文件 (156.32 MB)
已归档 2025-06 ：27 个文件 (234.56 MB)
已删除过期归档：logs-2024-12.zip

归档统计：
  归档目录大小：890.45 MB
  归档文件数：7
```

## 注意事项

1. **路径长度**：ZIP 格式限制路径为 260 字符（除非使用 UTF-8 编码），深目录结构可能导致问题
2. **文件锁定**：被占用的文件无法压缩，使用 `try/catch` 跳过或等待
3. **压缩级别**：`Fastest` 速度快但压缩率低，`Optimal` 反之。备份场景建议 `Optimal`
4. **大文件**：`Compress-Archive` 处理超大文件（>2GB）时可能内存不足，使用 .NET 类的流式处理
5. **编码**：中文文件名在 ZIP 中可能出现乱码，使用 UTF-8 编码的 ZIP 工具
6. **增量备份**：`Compress-Archive -Update` 不是真正的增量备份，只是追加新文件。需要增量备份请使用专业工具
