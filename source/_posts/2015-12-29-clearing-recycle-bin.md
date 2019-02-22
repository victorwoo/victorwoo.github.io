---
layout: post
date: 2015-12-29 12:00:00
title: "PowerShell 技能连载 - 清除回收站"
description: PowerTip of the Day - Clearing Recycle Bin
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerShell 5.0 之前，要清除回收站得手工删除每个驱动器根目录下隐藏的 $Recycle.Bin 文件夹里的内容。

有一些作者推荐使用名为 `Shell.Application` 的 COM 对象。它不一定可靠，因为回收站不一定可见，取决于资源管理器的设置。

幸运的事，PowerShell 5.0 终于提供了 `Clear-RecycleBin` Cmdlet。

<!--本文国际来源：[Clearing Recycle Bin](http://community.idera.com/powershell/powertips/b/tips/posts/clearing-recycle-bin)-->
