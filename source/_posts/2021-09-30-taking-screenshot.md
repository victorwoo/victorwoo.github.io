---
layout: post
date: 2021-09-30 00:00:00
title: "PowerShell 技能连载 - 截屏"
description: PowerTip of the Day - Taking Screenshot
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
借助 `System.Windows.Forms` 中的类型，PowerShell 可以轻松捕获屏幕并将屏幕截图保存到文件中。下面的代码捕获整个虚拟屏幕，将屏幕截图保存到文件中，然后在相关程序中打开位图文件（如果有）：

```powershell
    $Path = "$Env:temp\screenshot.bmp"
    Add-Type -AssemblyName System.Windows.Forms

    $screen = [System.Windows.Forms.SystemInformation]::VirtualScreen
    $width = $screen.Width
    $height = $screen.Height
    $left = $screen.Left
    $top = $screen.Top
    $bitmap = [System.Drawing.Bitmap]::new($width, $height)
    $MyDrawing = [System.Drawing.Graphics]::FromImage($bitmap)
    $MyDrawing.CopyFromScreen($left, $top, 0, 0, $bitmap.Size)

    $bitmap.Save($Path)
    Start-Process -FilePath $Path
```

<!--本文国际来源：[Taking Screenshot](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/taking-screenshot)-->

