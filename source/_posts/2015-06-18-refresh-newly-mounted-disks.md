layout: post
date: 2015-06-18 11:00:00
title: "PowerShell 技能连载 - 刷新新挂载的磁盘"
description: PowerTip of the Day - Refresh Newly Mounted Disks
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
如果您的脚本刚刚挂载了一个新的驱动器，PowerShell 可能无法立即存取它（例如通过 `Get-ChildItem`），因为 Powerell 尚未更新它的驱动器列表。

要更新 PowerShell 驱动器列表，请用这行代码：

    $null = Get-PSDrive

<!--more-->
本文国际来源：[Refresh Newly Mounted Disks](http://powershell.com/cs/blogs/tips/archive/2015/06/18/refresh-newly-mounted-disks.aspx)
