---
layout: post
date: 2021-09-30 00:00:00
title: "PowerShell 技能连载 - Taking Screenshot"
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
With types found in System.Windows.Forms, PowerShell can easily capture your screen and save the screenshot to a file. The code below captures your entire virtual screen, saves the screenshot to file, then opens the bitmap file in the associated program (if any):

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





<!--本文国际来源：[Taking Screenshot](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/taking-screenshot)-->

