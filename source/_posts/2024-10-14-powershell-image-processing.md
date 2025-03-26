---
layout: post
date: 2024-10-14 08:00:00
title: "PowerShell 技能连载 - 图像处理技巧"
description: PowerTip of the Day - PowerShell Image Processing Tips
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerShell 中处理图像文件是一项有趣的任务，本文将介绍一些实用的图像处理技巧。

首先，让我们看看基本的图像操作：

```powershell
# 创建图像信息获取函数
function Get-ImageInfo {
    param(
        [string]$ImagePath
    )
    
    try {
        # 使用 ImageMagick 获取图像信息
        $magick = "magick"
        $info = & $magick identify -format "%wx%h,%b,%m" $ImagePath
        
        $dimensions, $size, $format = $info -split ","
        $width, $height = $dimensions -split "x"
        
        return [PSCustomObject]@{
            FileName = Split-Path $ImagePath -Leaf
            Width = [int]$width
            Height = [int]$height
            Size = [math]::Round([double]$size / 1KB, 2)
            Format = $format
        }
    }
    catch {
        Write-Host "获取图像信息失败：$_"
    }
}
```

图像格式转换：

```powershell
# 创建图像格式转换函数
function Convert-ImageFormat {
    param(
        [string]$InputPath,
        [string]$OutputPath,
        [ValidateSet("jpg", "png", "bmp", "gif")]
        [string]$TargetFormat,
        [ValidateSet("high", "medium", "low")]
        [string]$Quality = "medium"
    )
    
    try {
        $magick = "magick"
        $qualitySettings = @{
            "high" = "-quality 100"
            "medium" = "-quality 80"
            "low" = "-quality 60"
        }
        
        $command = "$magick `"$InputPath`" $($qualitySettings[$Quality]) `"$OutputPath`""
        Invoke-Expression $command
        
        Write-Host "格式转换完成：$OutputPath"
    }
    catch {
        Write-Host "转换失败：$_"
    }
}
```

图像缩放：

```powershell
# 创建图像缩放函数
function Resize-Image {
    param(
        [string]$InputPath,
        [string]$OutputPath,
        [int]$Width,
        [int]$Height,
        [ValidateSet("fit", "fill", "crop")]
        [string]$Mode = "fit"
    )
    
    try {
        $magick = "magick"
        $resizeSettings = @{
            "fit" = "-resize ${Width}x${Height}>"
            "fill" = "-resize ${Width}x${Height}!"
            "crop" = "-resize ${Width}x${Height}^ -gravity center -extent ${Width}x${Height}"
        }
        
        $command = "$magick `"$InputPath`" $($resizeSettings[$Mode]) `"$OutputPath`""
        Invoke-Expression $command
        
        Write-Host "图像缩放完成：$OutputPath"
    }
    catch {
        Write-Host "缩放失败：$_"
    }
}
```

图像效果处理：

```powershell
# 创建图像效果处理函数
function Apply-ImageEffect {
    param(
        [string]$InputPath,
        [string]$OutputPath,
        [ValidateSet("grayscale", "sepia", "blur", "sharpen")]
        [string]$Effect,
        [hashtable]$Parameters
    )
    
    try {
        $magick = "magick"
        $effectSettings = @{
            "grayscale" = "-colorspace gray"
            "sepia" = "-sepia-tone 80%"
            "blur" = "-blur 0x$($Parameters.Radius)"
            "sharpen" = "-sharpen 0x$($Parameters.Amount)"
        }
        
        $command = "$magick `"$InputPath`" $($effectSettings[$Effect]) `"$OutputPath`""
        Invoke-Expression $command
        
        Write-Host "效果处理完成：$OutputPath"
    }
    catch {
        Write-Host "效果处理失败：$_"
    }
}
```

图像批量处理：

```powershell
# 创建图像批量处理函数
function Process-ImageBatch {
    param(
        [string]$InputFolder,
        [string]$OutputFolder,
        [scriptblock]$ProcessScript
    )
    
    try {
        if (-not (Test-Path $OutputFolder)) {
            New-Item -ItemType Directory -Path $OutputFolder | Out-Null
        }
        
        Get-ChildItem -Path $InputFolder -Include *.jpg,*.png,*.bmp,*.gif -Recurse | ForEach-Object {
            $outputPath = Join-Path $OutputFolder $_.Name
            & $ProcessScript $_.FullName $outputPath
        }
        
        Write-Host "批量处理完成"
    }
    catch {
        Write-Host "批量处理失败：$_"
    }
}
```

这些技巧将帮助您更有效地处理图像文件。记住，在处理图像时，始终要注意文件格式的兼容性和图像质量。同时，建议在处理大型图像文件时使用流式处理方式，以提高性能。 