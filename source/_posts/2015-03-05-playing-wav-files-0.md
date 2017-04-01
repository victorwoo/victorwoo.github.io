layout: post
date: 2015-03-05 12:00:00
title: "PowerShell 技能连载 - 播放 WAV 文件"
description: PowerTip of the Day - Playing WAV Files
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
_适用于 PowerShell 所有版本_

以下是一个简单的用 PowerShell 播放 WAV 声音文件的方法：

    # find first available WAV file in Windows folder
    $WAVPath = Get-ChildItem -Path $env:windir -Filter *.wav -Recurse -ErrorAction SilentlyContinue |
      Select-Object -First 1 -ExpandProperty FullName
    
    
    # load file and play it
    "Playing $WAVPath..."
    
    $player = New-Object Media.SoundPlayer $WAVPath
    $player.Play()
    
    "Done!" 

这段脚本的第一部分在 Windows 文件夹中查找第一个 WAV 文件。当然，您可以将您喜欢的 WAV 文件路径赋给 `$WAVFile`。

下一步， `Media.SoundPlayer` 读取并播放 WAV 文件。请注意 `Play()` 如何播放声音：它在一个单独的线程中播放，而 PowerShell 将会立即继续运行。

您可以用这种方法来创建一个有声的进度条：当 PowerShell 在做某件事的时候持续播放声音：

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

现在，`PlayLooping()` 用于循环播放声音。该声音会一直播放下去，所以您需要手动调用 `Stop()`。这是脚本结束的时候需要做的事情。

<!--more-->
本文国际来源：[Playing WAV Files](http://community.idera.com/powershell/powertips/b/tips/posts/playing-wav-files-0)
