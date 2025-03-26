---
layout: post
date: 2025-01-01 08:00:00
title: "PowerShell 技能连载 - 视频处理技巧"
description: PowerTip of the Day - PowerShell Video Processing Tips
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerShell 中处理视频文件可能不是最常见的任务，但在某些场景下非常有用。本文将介绍一些实用的视频处理技巧。

首先，让我们看看基本的视频操作：

```powershell
# 创建视频信息获取函数
function Get-VideoInfo {
    param(
        [string]$VideoPath
    )
    
    try {
        # 使用 FFmpeg 获取视频信息
        $ffmpeg = "C:\ffmpeg\bin\ffmpeg.exe"
        $info = & $ffmpeg -i $VideoPath 2>&1
        
        $duration = [regex]::Match($info, "Duration: (\d{2}):(\d{2}):(\d{2})")
        $size = (Get-Item $VideoPath).Length
        
        return [PSCustomObject]@{
            FileName = Split-Path $VideoPath -Leaf
            Duration = [TimeSpan]::new(
                [int]$duration.Groups[1].Value,
                [int]$duration.Groups[2].Value,
                [int]$duration.Groups[3].Value
            )
            FileSize = $size
            Info = $info
        }
    }
    catch {
        Write-Host "获取视频信息失败：$_"
    }
}
```

视频格式转换：

```powershell
# 创建视频格式转换函数
function Convert-VideoFormat {
    param(
        [string]$InputPath,
        [string]$OutputPath,
        [ValidateSet("mp4", "avi", "mkv", "mov")]
        [string]$TargetFormat
    )
    
    try {
        $ffmpeg = "C:\ffmpeg\bin\ffmpeg.exe"
        
        switch ($TargetFormat) {
            "mp4" {
                & $ffmpeg -i $InputPath -c:v libx264 -c:a aac -preset medium $OutputPath
            }
            "avi" {
                & $ffmpeg -i $InputPath -c:v libxvid -c:a libmp3lame $OutputPath
            }
            "mkv" {
                & $ffmpeg -i $InputPath -c copy $OutputPath
            }
            "mov" {
                & $ffmpeg -i $InputPath -c:v libx264 -c:a aac -f mov $OutputPath
            }
        }
        
        Write-Host "视频转换完成：$OutputPath"
    }
    catch {
        Write-Host "转换失败：$_"
    }
}
```

视频剪辑：

```powershell
# 创建视频剪辑函数
function Split-Video {
    param(
        [string]$InputPath,
        [string]$OutputPath,
        [TimeSpan]$StartTime,
        [TimeSpan]$Duration
    )
    
    try {
        $ffmpeg = "C:\ffmpeg\bin\ffmpeg.exe"
        $start = $StartTime.ToString("hh\:mm\:ss")
        $duration = $Duration.ToString("hh\:mm\:ss")
        
        & $ffmpeg -i $InputPath -ss $start -t $duration -c copy $OutputPath
        Write-Host "视频剪辑完成：$OutputPath"
    }
    catch {
        Write-Host "剪辑失败：$_"
    }
}
```

视频压缩：

```powershell
# 创建视频压缩函数
function Compress-Video {
    param(
        [string]$InputPath,
        [string]$OutputPath,
        [ValidateSet("high", "medium", "low")]
        [string]$Quality = "medium"
    )
    
    try {
        $ffmpeg = "C:\ffmpeg\bin\ffmpeg.exe"
        
        $crf = switch ($Quality) {
            "high" { "23" }
            "medium" { "28" }
            "low" { "33" }
        }
        
        & $ffmpeg -i $InputPath -c:v libx264 -crf $crf -preset medium -c:a aac -b:a 128k $OutputPath
        Write-Host "视频压缩完成：$OutputPath"
    }
    catch {
        Write-Host "压缩失败：$_"
    }
}
```

这些技巧将帮助您更有效地处理视频文件。记住，在处理视频时，始终要注意文件大小和编码质量。同时，建议在处理大型视频文件时使用流式处理方式，以提高性能。 