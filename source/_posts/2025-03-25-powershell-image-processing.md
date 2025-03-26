---
layout: post
date: 2025-03-25 08:00:00
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
在 PowerShell 中处理图像文件可能不是最常见的任务，但在某些场景下非常有用。本文将介绍一些实用的图像处理技巧。

首先，让我们看看基本的图像操作：

```powershell
# 创建图像处理函数
function Get-ImageInfo {
    param(
        [string]$ImagePath
    )
    
    # 使用 System.Drawing 获取图像信息
    Add-Type -AssemblyName System.Drawing
    $image = [System.Drawing.Image]::FromFile($ImagePath)
    
    $info = [PSCustomObject]@{
        FileName = Split-Path $ImagePath -Leaf
        Width = $image.Width
        Height = $image.Height
        PixelFormat = $image.PixelFormat
        Resolution = $image.HorizontalResolution
        FileSize = (Get-Item $ImagePath).Length
    }
    
    $image.Dispose()
    return $info
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
        [string]$TargetFormat
    )
    
    try {
        Add-Type -AssemblyName System.Drawing
        $image = [System.Drawing.Image]::FromFile($InputPath)
        
        switch ($TargetFormat) {
            "jpg" { $image.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Jpeg) }
            "png" { $image.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png) }
            "bmp" { $image.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Bmp) }
            "gif" { $image.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Gif) }
        }
        
        $image.Dispose()
        Write-Host "图像转换完成：$OutputPath"
    }
    catch {
        Write-Host "转换失败：$_"
    }
}
```

图像调整：

```powershell
# 创建图像调整函数
function Resize-Image {
    param(
        [string]$InputPath,
        [string]$OutputPath,
        [int]$Width,
        [int]$Height
    )
    
    try {
        Add-Type -AssemblyName System.Drawing
        $image = [System.Drawing.Image]::FromFile($InputPath)
        
        # 创建新的位图
        $newImage = New-Object System.Drawing.Bitmap($Width, $Height)
        $graphics = [System.Drawing.Graphics]::FromImage($newImage)
        
        # 设置高质量插值模式
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        
        # 绘制调整后的图像
        $graphics.DrawImage($image, 0, 0, $Width, $Height)
        
        # 保存结果
        $newImage.Save($OutputPath)
        
        # 清理资源
        $graphics.Dispose()
        $newImage.Dispose()
        $image.Dispose()
        
        Write-Host "图像调整完成：$OutputPath"
    }
    catch {
        Write-Host "调整失败：$_"
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
        [string]$Effect
    )
    
    try {
        Add-Type -AssemblyName System.Drawing
        $image = [System.Drawing.Image]::FromFile($InputPath)
        $bitmap = New-Object System.Drawing.Bitmap($image)
        
        switch ($Effect) {
            "grayscale" {
                for ($x = 0; $x -lt $bitmap.Width; $x++) {
                    for ($y = 0; $y -lt $bitmap.Height; $y++) {
                        $pixel = $bitmap.GetPixel($x, $y)
                        $gray = [int](($pixel.R * 0.3) + ($pixel.G * 0.59) + ($pixel.B * 0.11))
                        $bitmap.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($gray, $gray, $gray))
                    }
                }
            }
            "sepia" {
                for ($x = 0; $x -lt $bitmap.Width; $x++) {
                    for ($y = 0; $y -lt $bitmap.Height; $y++) {
                        $pixel = $bitmap.GetPixel($x, $y)
                        $r = [int](($pixel.R * 0.393) + ($pixel.G * 0.769) + ($pixel.B * 0.189))
                        $g = [int](($pixel.R * 0.349) + ($pixel.G * 0.686) + ($pixel.B * 0.168))
                        $b = [int](($pixel.R * 0.272) + ($pixel.G * 0.534) + ($pixel.B * 0.131))
                        $bitmap.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($r, $g, $b))
                    }
                }
            }
        }
        
        $bitmap.Save($OutputPath)
        
        # 清理资源
        $bitmap.Dispose()
        $image.Dispose()
        
        Write-Host "已应用效果：$Effect"
    }
    catch {
        Write-Host "效果处理失败：$_"
    }
}
```

这些技巧将帮助您更有效地处理图像文件。记住，在处理图像时，始终要注意内存使用和资源释放。同时，建议在处理大型图像文件时使用流式处理方式，以提高性能。 