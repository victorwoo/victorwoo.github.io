---
layout: post
date: 2014-09-01 11:00:00
title: "PowerShell 技能连载 - 播放 WAV 声音"
description: PowerTip of the Day - Playing WAV Sounds
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
_适用于 PowerShell 3.0 或以上版本_

PowerShell 可以用内置的 `SoundPlayer` 类播放 WAV 背景声音。它可以接受一个 WAV 文件的路径参数，然后可以指定只播放一次还是循环播放。

以下代码将循环播放一段声音：

    $player = New-Object -TypeName System.Media.SoundPlayer
    $player.SoundLocation = 'C:\Windows\Media\chimes.wav'
    $player.Load()
    $player.PlayLooping()

当您的脚本执行完以后，可以通过这行代码停止播放：

    $player.Stop()

如果您想将自定义的声音文件和您的 PowerShell 脚本一块分发，只需要将它存放在脚本的同一个文件夹下，然后用 `$PSScriptRoot` 来引用脚本所在的文件夹。

这个例子将播放脚本目录下的 _mySound.wav_：

    $player = New-Object -TypeName System.Media.SoundPlayer
    $player.SoundLocation = "$PSScriptRoot\mySound.wav"
    $player.Load()
    $player.PlayLooping()
    
    # do something...
    Start-Sleep -Seconds 5
    
    $player.Stop() 

请注意 `$PSScriptRoot` 需要 PowerShell 3.0 或以上版本。当然，它也需要您先将脚本保存到文件。

<!--more-->
本文国际来源：[Playing WAV Sounds](http://community.idera.com/powershell/powertips/b/tips/posts/playing-wav-sounds)
