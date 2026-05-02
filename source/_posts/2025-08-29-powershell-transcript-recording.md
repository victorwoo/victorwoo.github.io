---
layout: post
date: 2025-08-29 08:00:00
updated: 2025-08-29 08:00:00
title: "PowerShell 技能连载 - 会话录制与回放"
description: PowerTip of the Day - Session Recording and Replay in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- monitoring
- security
---

_适用于 PowerShell 5.1 及以上版本_

在安全审计、故障排查、培训演示等场景中，记录操作过程至关重要。PowerShell 的 `Start-Transcript` 可以记录控制台的完整输入输出，包括命令、结果、错误信息。结合日志轮转和自动化脚本，可以构建完整的操作审计系统，确保所有关键操作可追溯、可回放。

本文将讲解 PowerShell 会话录制的技术和实用方案。

<!-- more -->

## 基础会话录制

```powershell
# 开始录制
Start-Transcript -Path "C:\Transcripts\session-$(Get-Date -Format 'yyyyMMdd_HHmmss').txt" -Append
Write-Host "会话录制已开始" -ForegroundColor Green

# 正常操作...
Get-Process | Select-Object -First 3 Name, Id, CPU
Write-Host "当前时间：$(Get-Date)" -ForegroundColor Cyan

# 停止录制
Stop-Transcript
Write-Host "会话录制已停止" -ForegroundColor Yellow

# 查看录制内容
$latestTranscript = Get-ChildItem "C:\Transcripts" -Filter "*.txt" |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1

Write-Host "`n最新录制文件：$($latestTranscript.Name) ($([math]::Round($latestTranscript.Length / 1KB, 1)) KB)"
```

执行结果示例：

```
会话录制已开始
**********************
Windows PowerShell transcript start
Start time: 20250829103015
Username: CONTOSO\admin
Runspace Id: a1b2c3d4-e5f6-7890-abcd-ef1234567890

Name     Id    CPU
----     --    ---
chrome 12345 1250.3
node   12346  456.7
pwsh   12347  123.4

当前时间：2025-08-29 10:30:20
Windows PowerShell transcript end
End time: 20250829103021
**********************
会话录制已停止

最新录制文件：session-20250829_103015.txt (2.3 KB)
```

## 自动录制配置

```powershell
# 在 $PROFILE 中自动开始录制
function Install-AutoTranscript {
    $profileDir = Split-Path $PROFILE -Parent
    if (-not (Test-Path $profileDir)) {
        New-Item $profileDir -ItemType Directory -Force | Out-Null
    }

    $transcriptBlock = @"

# ===== 自动会话录制 =====
`$transcriptDir = "`$env:USERPROFILE\Transcripts"
if (-not (Test-Path `$transcriptDir)) {
    New-Item `$transcriptDir -ItemType Directory -Force | Out-Null
}
`$dateStamp = Get-Date -Format 'yyyyMMdd_HHmmss'
`$transcriptFile = Join-Path `$transcriptDir "transcript-`$dateStamp.txt"
Start-Transcript -Path `$transcriptFile -Append
# ===== 自动会话录制结束 =====
"@

    if (-not (Test-Path $PROFILE)) {
        Set-Content -Path $PROFILE -Value $transcriptBlock -Encoding UTF8
    } else {
        $content = Get-Content $PROFILE -Raw
        if ($content -notmatch 'Start-Transcript') {
            Add-Content -Path $PROFILE -Value $transcriptBlock -Encoding UTF8
        }
    }

    Write-Host "自动录制已配置到 $PROFILE" -ForegroundColor Green
    Write-Host "下次启动 PowerShell 时自动开始录制" -ForegroundColor Yellow
}

Install-AutoTranscript

# 管理录制文件
function Get-TranscriptSummary {
    param([string]$Path = "$env:USERPROFILE\Transcripts")

    $transcripts = Get-ChildItem $Path -Filter "transcript-*.txt" -ErrorAction SilentlyContinue

    if (-not $transcripts) {
        Write-Host "未找到录制文件" -ForegroundColor Yellow
        return
    }

    Write-Host "录制文件概览：" -ForegroundColor Cyan
    Write-Host "  总文件数：$($transcripts.Count)"
    $totalSize = [math]::Round(($transcripts | Measure-Object Length -Sum).Sum / 1MB, 2)
    Write-Host "  总大小：$totalSize MB"

    $transcripts | Sort-Object LastWriteTime -Descending | Select-Object -First 5 |
        ForEach-Object {
            $sizeKB = [math]::Round($_.Length / 1KB, 1)
            Write-Host "  $($_.Name) ($sizeKB KB) - $($_.LastWriteTime.ToString('yyyy-MM-dd HH:mm'))" -ForegroundColor DarkGray
        }
}

Get-TranscriptSummary
```

执行结果示例：

```
自动录制已配置到 C:\Users\admin\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
下次启动 PowerShell 时自动开始录制

录制文件概览：
  总文件数：45
  总大小：12.5 MB
  transcript-20250829_103015.txt (2.3 KB) - 2025-08-29 10:30
  transcript-20250829_090000.txt (5.6 KB) - 2025-08-29 09:00
  transcript-20250828_140530.txt (8.2 KB) - 2025-08-28 14:05
```

## 录制文件清理

```powershell
function Clear-OldTranscripts {
    param(
        [string]$Path = "$env:USERPROFILE\Transcripts",
        [int]$KeepDays = 90,
        [switch]$WhatIf
    )

    $cutoff = (Get-Date).AddDays(-$KeepDays)

    $oldFiles = Get-ChildItem $Path -Filter "transcript-*.txt" |
        Where-Object { $_.LastWriteTime -lt $cutoff }

    if (-not $oldFiles) {
        Write-Host "没有需要清理的录制文件" -ForegroundColor Green
        return
    }

    $totalSize = [math]::Round(($oldFiles | Measure-Object Length -Sum).Sum / 1MB, 2)

    Write-Host "找到 $($oldFiles.Count) 个超过 $KeepDays 天的录制文件（$totalSize MB）" -ForegroundColor Yellow

    if ($WhatIf) {
        Write-Host "[WhatIf] 将删除以上文件" -ForegroundColor Yellow
        return
    }

    $oldFiles | Remove-Item -Force
    Write-Host "已清理 $($oldFiles.Count) 个文件，释放 $totalSize MB" -ForegroundColor Green
}

Clear-OldTranscripts -KeepDays 90 -WhatIf
```

执行结果示例：

```
找到 12 个超过 90 天的录制文件（3.45 MB）
[WhatIf] 将删除以上文件
```

## 结构化操作日志

```powershell
# 组合 Transcript 和结构化日志
function Invoke-LoggedOperation {
    param(
        [Parameter(Mandatory)]
        [string]$OperationName,

        [Parameter(Mandatory)]
        [scriptblock]$Operation,

        [string]$LogDir = "C:\Logs\Operations"
    )

    New-Item $LogDir -ItemType Directory -Force | Out-Null

    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $transcriptPath = Join-Path $LogDir "$OperationName-$timestamp.txt"

    $result = [PSCustomObject]@{
        Operation   = $OperationName
        StartTime   = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Status      = "Unknown"
        Duration    = ""
        Transcript  = $transcriptPath
        Error       = ""
    }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        Start-Transcript -Path $transcriptPath -Force | Out-Null
        & $Operation
        Stop-Transcript | Out-Null

        $result.Status = "Success"
    } catch {
        Stop-Transcript | Out-Null
        $result.Status = "Failed"
        $result.Error = $_.Exception.Message
    } finally {
        $sw.Stop()
        $result.Duration = "$($sw.Elapsed.ToString('mm\:ss'))"
    }

    # 写入结构化日志
    $logEntry = "[$($result.StartTime)] [$($result.Status)] $($result.Operation) ($($result.Duration))"
    Add-Content (Join-Path $LogDir "operations.log") -Value $logEntry -Encoding UTF8

    $color = if ($result.Status -eq "Success") { "Green" } else { "Red" }
    Write-Host $logEntry -ForegroundColor $color

    return $result
}

# 使用示例
Invoke-LoggedOperation -OperationName "Deploy-MyApp" -Operation {
    Write-Host "停止服务..." -ForegroundColor Cyan
    Stop-Service "MyApp" -ErrorAction SilentlyContinue

    Write-Host "复制文件..." -ForegroundColor Cyan
    Copy-Item "C:\Releases\MyApp\*" "D:\Apps\MyApp\" -Recurse -Force

    Write-Host "启动服务..." -ForegroundColor Cyan
    Start-Service "MyApp"

    Write-Host "验证..." -ForegroundColor Cyan
    $svc = Get-Service "MyApp"
    Write-Host "服务状态：$($svc.Status)"
}
```

执行结果示例：

```
停止服务...
复制文件...
启动服务...
验证...
服务状态：Running
[2025-08-29 10:35:20] [Success] Deploy-MyApp (01:23)
```

## 注意事项

1. **敏感信息**：Transcript 会记录所有控制台输出，包括密码输入。敏感操作后及时清理或加密存储
2. **磁盘空间**：长期开启自动录制会积累大量文件，配置定期清理策略
3. **性能影响**：Transcript 的性能开销很小，但在极端高频输出场景中可能有影响
4. **编码问题**：Transcript 文件使用系统默认编码，中文内容可能需要 UTF-8 转换
5. **嵌套限制**：已经在一个 Transcript 中时不能再次 `Start-Transcript`（除非加 `-Append`）
6. **远程会话**：通过 Enter-PSSession 进入的远程会话需要单独配置 Transcript
