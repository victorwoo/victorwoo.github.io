---
layout: post
date: 2025-02-25 08:00:00
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
在 PowerShell 中处理视频文件是一项有趣的任务，本文将介绍一些实用的视频处理技巧。

首先，让我们看看基本的视频操作：

```powershell
# 创建视频信息获取函数
function Get-VideoInfo {
    param(
        [string]$VideoPath
    )
    
    try {
        # 使用 ffprobe 获取视频信息
        $ffprobe = "ffprobe"
        $info = & $ffprobe -v quiet -print_format json -show_format -show_streams $VideoPath | ConvertFrom-Json
        
        $videoStream = $info.streams | Where-Object { $_.codec_type -eq "video" }
        $audioStream = $info.streams | Where-Object { $_.codec_type -eq "audio" }
        
        return [PSCustomObject]@{
            FileName = Split-Path $VideoPath -Leaf
            Duration = [math]::Round([double]$info.format.duration, 2)
            Size = [math]::Round([double]$info.format.size / 1MB, 2)
            Bitrate = [math]::Round([double]$info.format.bit_rate / 1000, 2)
            Format = $info.format.format_name
            VideoCodec = $videoStream.codec_name
            VideoResolution = "$($videoStream.width)x$($videoStream.height)"
            AudioCodec = $audioStream.codec_name
            AudioChannels = $audioStream.channels
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
        [string]$TargetFormat,
        [ValidateSet("high", "medium", "low")]
        [string]$Quality = "medium"
    )
    
    try {
        $ffmpeg = "ffmpeg"
        $qualitySettings = @{
            "high" = "-crf 17"
            "medium" = "-crf 23"
            "low" = "-crf 28"
        }
        
        $command = "$ffmpeg -i `"$InputPath`" $($qualitySettings[$Quality]) `"$OutputPath`""
        Invoke-Expression $command
        
        Write-Host "格式转换完成：$OutputPath"
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
        [string]$OutputFolder,
        [double]$StartTime,
        [double]$Duration
    )
    
    try {
        $ffmpeg = "ffmpeg"
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($InputPath)
        $extension = [System.IO.Path]::GetExtension($InputPath)
        $outputPath = Join-Path $OutputFolder "$fileName`_split$extension"
        
        $command = "$ffmpeg -i `"$InputPath`" -ss $StartTime -t $Duration `"$outputPath`""
        Invoke-Expression $command
        
        Write-Host "视频剪辑完成：$outputPath"
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
        [string]$Quality = "medium",
        [int]$MaxWidth = 1920
    )
    
    try {
        $ffmpeg = "ffmpeg"
        $qualitySettings = @{
            "high" = "-crf 23"
            "medium" = "-crf 28"
            "low" = "-crf 33"
        }
        
        $command = "$ffmpeg -i `"$InputPath`" -vf scale=$MaxWidth`:-1 $($qualitySettings[$Quality]) `"$OutputPath`""
        Invoke-Expression $command
        
        Write-Host "视频压缩完成：$OutputPath"
    }
    catch {
        Write-Host "压缩失败：$_"
    }
}
```

视频帧提取：

```powershell
# 创建视频帧提取函数
function Extract-VideoFrames {
    param(
        [string]$InputPath,
        [string]$OutputFolder,
        [double]$Interval = 1.0,
        [ValidateSet("jpg", "png")]
        [string]$Format = "jpg"
    )
    
    try {
        $ffmpeg = "ffmpeg"
        if (-not (Test-Path $OutputFolder)) {
            New-Item -ItemType Directory -Path $OutputFolder | Out-Null
        }
        
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($InputPath)
        $outputPattern = Join-Path $OutputFolder "$fileName`_%d.$Format"
        
        $command = "$ffmpeg -i `"$InputPath`" -vf fps=1/$Interval `"$outputPattern`""
        Invoke-Expression $command
        
        Write-Host "帧提取完成：$OutputFolder"
    }
    catch {
        Write-Host "帧提取失败：$_"
    }
}
```

这些技巧将帮助您更有效地处理视频文件。记住，在处理视频时，始终要注意文件格式的兼容性和视频质量。同时，建议在处理大型视频文件时使用流式处理方式，以提高性能。 