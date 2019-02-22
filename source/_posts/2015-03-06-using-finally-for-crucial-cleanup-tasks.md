---
layout: post
date: 2015-03-06 12:00:00
title: "PowerShell 技能连载 - 用 Finally 来处理关键的清理任务"
description: PowerTip of the Day - Using Finally for Crucial Cleanup Tasks
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell 2.0 及以上版本_

在前一个技能中我们介绍了一个“有声的进度条”，它能令 PowerShell 在忙时播放一段声音。以下还是那段代码：

    # find first available WAV file in Windows folder
    $WAVPath = Get-ChildItem -Path $env:windir -Filter *.wav -Recurse -ErrorAction SilentlyContinue |
      Select-Object -First 1 -ExpandProperty FullName
    
    
    # load file and play it
    
    $player = New-Object Media.SoundPlayer $WAVPath
    $player.PlayLooping()
    
    1..100 | ForEach-Object { 
      Write-Progress -Activity 'Doing Something. Hang in' -Status $_ -PercentComplete $_
      Start-Sleep -MilliSeconds (Get-Random -Minimum 300 -Maximum 1300)
      }
    $player.Stop()
    

这个脚本工作是正常的——除非您把它中断，例如按下 `CTRL+C`。如果按下这个组合键，脚本立即停止执行，并且 `$player.Stop()` 没有机会执行所以没有机会停止声音。

这就使用 PowerShell 中的 `finally()` 最为合适。它确保一个脚本退出前执行清理代码：

    # find first available WAV file in Windows folder
    $WAVPath = Get-ChildItem -Path $env:windir -Filter *.wav -Recurse -ErrorAction SilentlyContinue |
    Select-Object -First 1 -ExpandProperty FullName
    
    
    # load file and play it
    
    $player = New-Object Media.SoundPlayer $WAVPath
    
    try
    {
    
      $player.PlayLooping()
      
      1..100 | ForEach-Object { 
        Write-Progress -Activity 'Doing Something' -Status $_ -PercentComplete $_
        Start-Sleep -MilliSeconds (Get-Random -Minimum 300 -Maximum 1300)
      }
    }
    
    finally
    {
      $player.Stop()
    }

<!--本文国际来源：[Using Finally for Crucial Cleanup Tasks](http://community.idera.com/powershell/powertips/b/tips/posts/using-finally-for-crucial-cleanup-tasks)-->
