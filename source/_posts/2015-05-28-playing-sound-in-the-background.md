layout: post
date: 2015-05-28 11:00:00
title: "PowerShell 技能连载 - 在后台播放声音"
description: PowerTip of the Day - Playing Sound in the Background
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
如果您的脚本执行起来需要较长时间，您可能会希望播放一段系统声音文件。以下是一个实现该功能的示例代码：

    # find first available WAV file in Windows
    $WAVPath = Get-ChildItem -Path $env:windir -Filter *.wav -Recurse -ErrorAction SilentlyContinue |
    Select-Object -First 1 -ExpandProperty FullName
    
    # load file and play it
    $player = New-Object Media.SoundPlayer $WAVPath
    
    try
    {
      $player.PlayLooping()
      'Doing something...'
    
      1..100 | ForEach-Object { 
        Write-Progress -Activity 'Doing Something. Hang in' -Status $_ -PercentComplete $_
        Start-Sleep -MilliSeconds (Get-Random -Minimum 300 -Maximum 1300)
      }
    }
    
    finally
    {
      $player.Stop()
    }

这段示例代码使用 Windows 文件夹中找到的第一个 WAV 文件，然后在脚本的执行期间播放它。您当然也可以指定其它 WAV 文件的路径。

<!--more-->
本文国际来源：[Playing Sound in the Background](http://community.idera.com/powershell/powertips/b/tips/posts/playing-sound-in-the-background)
