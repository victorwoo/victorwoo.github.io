layout: post
title: "PowerShell 技能连载 - 当发生错误时播放一段声音"
date: 2014-01-29 00:00:00
description: PowerTip of the Day - Playing a Sound on Error
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
为了吸引用户的注意力，您的脚本可以很容易地播放 WAV 声音文件。以下是一个简单的函数：

	function Play-Alarm {
	    $path = "$PSScriptRoot\Alarm06.wav"
	    $playerStart = New-Object Media.SoundPlayer $path
	    $playerStart.Load()
	    $playerStart.PlaySync()
	}

这段脚本假设 WAV 文件存放在和脚本相同的目录。请注意 PowerShell 2.0 并不支持 `$PSScriptRoot`。

您只需要确保设置了 $path 变量并指向一个您希望的合法的 WAV 文件即可。

缺省情况下，PowerShell 将会等待直到声音播放完。如果您希望 PowerShell 继续执行而不是等待，请将 `PlaySync()` 替换成 `Play()`。

<!--more-->
本文国际来源：[Playing a Sound on Error](http://community.idera.com/powershell/powertips/b/tips/posts/playing-a-sound-on-error)
