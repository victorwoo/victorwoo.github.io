layout: post
date: 2015-07-31 11:00:00
title: "PowerShell 技能连载 - 改变 ISE 缩放比例"
description: PowerTip of the Day - Change ISE Zoom Level
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
PowerShell ISE 的右下角有一个缩放滑竿，您也可以用 PowerShell 代码来控制它。

所以，您可以在 `$profile` 脚本中设置缺省值：

    $psise.Options.Zoom = 120

或者，可以写一些代码来戏弄您的同事：

    #requires -Version 2
    
    $zoom = $psise.Options.Zoom
    
    # slide in
    for ($i = 20; $i -lt 200; $i++)
    {
      $psise.Options.Zoom = $i
    }
    
    # slide out
    for ($i = 199; $i -gt 20; $i--)
    {
      $psise.Options.Zoom = $i
    }
    
    # random whacky
    1..10 |
    ForEach-Object {
      $psise.Options.Zoom = (Get-Random -Minimum 30 -Maximum 400)
      Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 400)
    }
    
    $psise.Options.Zoom = $zoom

<!--more-->
本文国际来源：[Change ISE Zoom Level](http://community.idera.com/powershell/powertips/b/tips/posts/change-ise-zoom-level)
