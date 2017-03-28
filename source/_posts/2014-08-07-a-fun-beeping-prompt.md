layout: post
date: 2014-08-07 11:00:00
title: "PowerShell 技能连载 - 有趣的声音提示"
description: PowerTip of the Day - A Fun Beeping Prompt
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
_适用于所有 PowerShell 版本_

如果您的计算机装有声卡，那么这段代码可以让您的同事们吓一跳：

    function prompt
    {
      1..3 | ForEach-Object {
        $frequency = Get-Random -Minimum 400 -Maximum 10000
        $duration = Get-Random -Minimum 100 -Maximum 400
        [Console]::Beep($frequency, $duration)
      }
      'PS> '
      $host.ui.RawUI.WindowTitle = Get-Location
    }

这段代码将会缩短您的 PowerShell 提示符，并且在标题栏上显示当前的路径。这还算是有益的功能。搞破坏的部分是每次执行一条命令，都会发出随机频率的刺耳的三连音:)。

<!--more-->
本文国际来源：[A Fun Beeping Prompt](http://community.idera.com/powershell/powertips/b/tips/posts/a-fun-beeping-prompt)
